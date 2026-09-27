// mlqs-cli is a headless command-line client for the mlqs daemon.
package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"html"
	"io"
	"net"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

const usageText = `usage: mlqs-cli [--json] [--socket PATH] COMMAND [ARGS]

Commands:
  ping
  accounts
  folders ACCOUNT
  inbox ACCOUNT
  read ACCOUNT CONVERSATION_ID
  search ACCOUNT QUERY
  send ACCOUNT --to ADDRESS --subject TEXT (--body TEXT | --body-file PATH)
  reply ACCOUNT CONVERSATION_ID (--body TEXT | --body-file PATH)

send/reply options:
  --to, --cc, --bcc ADDRESS   comma-separated recipients
  --subject TEXT              required for send; inferred for reply
  --body TEXT                 plain-text message body
  --body-file PATH            read body from PATH, or - for stdin
  --attach PATH               attachment path (repeatable)
`

type command map[string]any

type client struct {
	conn     net.Conn
	dec      *json.Decoder
	enc      *json.Encoder
	accounts map[string]string
}

func socketPath() string {
	if p := os.Getenv("MLQS_SOCKET"); p != "" {
		return p
	}
	if d := os.Getenv("XDG_RUNTIME_DIR"); d != "" {
		return filepath.Join(d, "mlqs.sock")
	}
	return "/tmp/mlqs.sock"
}

func dial(path string) (*client, error) {
	conn, err := net.DialTimeout("unix", path, 3*time.Second)
	if err != nil {
		return nil, fmt.Errorf("connect %s: %w (is the mlqs daemon running?)", path, err)
	}
	return &client{conn: conn, dec: json.NewDecoder(conn), enc: json.NewEncoder(conn), accounts: map[string]string{}}, nil
}

func (c *client) close() { _ = c.conn.Close() }

func (c *client) request(cmd command, want string) (map[string]any, error) {
	if cmd != nil {
		if err := c.enc.Encode(cmd); err != nil {
			return nil, fmt.Errorf("send command: %w", err)
		}
	}
	if err := c.conn.SetReadDeadline(time.Now().Add(65 * time.Second)); err != nil {
		return nil, err
	}
	for {
		var event map[string]any
		if err := c.dec.Decode(&event); err != nil {
			return nil, fmt.Errorf("waiting for %s: %w", want, err)
		}
		typ, _ := event["type"].(string)
		if typ == "workspaces" {
			for _, account := range sliceOfMaps(event["workspaces"]) {
				c.accounts[stringValue(account["id"])] = stringValue(account["email"])
			}
		}
		if typ == "toast" {
			text, _ := event["text"].(string)
			if strings.HasPrefix(text, "mlqs ") || strings.Contains(text, "not authorized") {
				return nil, errors.New(text)
			}
		}
		if typ != want {
			continue
		}
		// Reads can emit a cached response immediately followed by a live one.
		if cached, _ := event["cached"].(bool); cached {
			continue
		}
		return event, nil
	}
}

type options struct {
	json   bool
	socket string
}

type attachments []string

func (a *attachments) String() string { return strings.Join(*a, ",") }
func (a *attachments) Set(v string) error {
	*a = append(*a, v)
	return nil
}

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "mlqs-cli:", err)
		os.Exit(1)
	}
}

func run(args []string, stdout, stderr io.Writer) error {
	global := flag.NewFlagSet("mlqs-cli", flag.ContinueOnError)
	global.SetOutput(stderr)
	jsonOut := global.Bool("json", false, "print the complete JSON response")
	sock := global.String("socket", socketPath(), "daemon Unix socket")
	global.Usage = func() { fmt.Fprint(stderr, usageText) }
	if err := global.Parse(args); err != nil {
		return err
	}
	args = global.Args()
	if len(args) == 0 || args[0] == "help" || args[0] == "--help" {
		fmt.Fprint(stdout, usageText)
		return nil
	}

	c, err := dial(*sock)
	if err != nil {
		return err
	}
	defer c.close()
	opts := options{json: *jsonOut, socket: *sock}

	switch args[0] {
	case "ping":
		return simple(c, command{"type": "ping"}, "pong", opts, stdout)
	case "accounts":
		event, err := c.request(nil, "workspaces")
		if err != nil {
			return err
		}
		return printAccounts(event, opts, stdout)
	case "folders":
		if len(args) != 2 {
			return errors.New("usage: mlqs-cli folders ACCOUNT")
		}
		event, err := c.request(command{"type": "folders", "account": args[1]}, "folders")
		if err != nil {
			return err
		}
		return printFolders(event, opts, stdout)
	case "inbox":
		if len(args) != 2 {
			return errors.New("usage: mlqs-cli inbox ACCOUNT")
		}
		return inbox(c, args[1], opts, stdout)
	case "read":
		if len(args) != 3 {
			return errors.New("usage: mlqs-cli read ACCOUNT CONVERSATION_ID")
		}
		event, err := c.request(command{"type": "conversation", "account": args[1], "id": args[2]}, "conversation")
		if err != nil {
			return err
		}
		return printConversation(event, opts, stdout)
	case "search":
		if len(args) < 3 {
			return errors.New("usage: mlqs-cli search ACCOUNT QUERY")
		}
		event, err := c.request(command{"type": "search", "account": args[1], "query": strings.Join(args[2:], " ")}, "conversations")
		if err != nil {
			return err
		}
		return printConversations(event, opts, stdout)
	case "send":
		return sendMail(c, args[1:], false, opts, stdout, stderr)
	case "reply":
		return sendMail(c, args[1:], true, opts, stdout, stderr)
	default:
		return fmt.Errorf("unknown command %q\n%s", args[0], usageText)
	}
}

func simple(c *client, cmd command, want string, opts options, out io.Writer) error {
	event, err := c.request(cmd, want)
	if err != nil {
		return err
	}
	if opts.json {
		return printJSON(out, event)
	}
	fmt.Fprintln(out, want)
	return nil
}

func inbox(c *client, account string, opts options, out io.Writer) error {
	folders, err := c.request(command{"type": "folders", "account": account}, "folders")
	if err != nil {
		return err
	}
	var folderID string
	for _, raw := range sliceOfMaps(folders["folders"]) {
		if stringValue(raw["role"]) == "inbox" {
			folderID = stringValue(raw["id"])
			break
		}
	}
	if folderID == "" {
		return fmt.Errorf("account %q has no inbox folder", account)
	}
	event, err := c.request(command{"type": "conversations", "account": account, "folder": folderID}, "conversations")
	if err != nil {
		return err
	}
	return printConversations(event, opts, out)
}

func sendMail(c *client, args []string, reply bool, opts options, out, errOut io.Writer) error {
	min := 1
	usage := "mlqs-cli send ACCOUNT [options]"
	if reply {
		min = 2
		usage = "mlqs-cli reply ACCOUNT CONVERSATION_ID [options]"
	}
	if len(args) < min {
		return errors.New("usage: " + usage)
	}
	account := args[0]
	convID := ""
	flagArgs := args[1:]
	if reply {
		convID = args[1]
		flagArgs = args[2:]
	}
	fs := flag.NewFlagSet("mail", flag.ContinueOnError)
	fs.SetOutput(errOut)
	to := fs.String("to", "", "comma-separated recipients")
	cc := fs.String("cc", "", "comma-separated CC recipients")
	bcc := fs.String("bcc", "", "comma-separated BCC recipients")
	subject := fs.String("subject", "", "message subject")
	body := fs.String("body", "", "plain-text body")
	bodyFile := fs.String("body-file", "", "body file, or - for stdin")
	var paths attachments
	fs.Var(&paths, "attach", "attachment path (repeatable)")
	if err := fs.Parse(flagArgs); err != nil {
		return err
	}
	if fs.NArg() != 0 {
		return fmt.Errorf("unexpected argument %q", fs.Arg(0))
	}
	messageBody, err := resolveBody(*body, *bodyFile)
	if err != nil {
		return err
	}

	cmd := command{"type": "send", "account": account, "to": *to, "cc": *cc, "bcc": *bcc,
		"subject": *subject, "body": messageBody, "paths": []string(paths)}
	if reply {
		conversation, err := c.request(command{"type": "conversation", "account": account, "id": convID}, "conversation")
		if err != nil {
			return err
		}
		meta, err := replyMetadata(conversation, c.accounts[account])
		if err != nil {
			return err
		}
		if *to == "" {
			cmd["to"] = meta.to
		}
		if *subject == "" {
			cmd["subject"] = replySubject(meta.subject)
		}
		cmd["replyTo"] = meta.messageID
		cmd["conv"] = convID
	} else {
		if *to == "" {
			return errors.New("send requires --to")
		}
		if *subject == "" {
			return errors.New("send requires --subject")
		}
	}
	event, err := c.request(cmd, "sent")
	if err != nil {
		return err
	}
	if opts.json {
		return printJSON(out, event)
	}
	fmt.Fprintln(out, "sent")
	return nil
}

func resolveBody(body, file string) (string, error) {
	if body != "" && file != "" {
		return "", errors.New("use only one of --body and --body-file")
	}
	if file == "-" {
		b, err := io.ReadAll(os.Stdin)
		return string(b), err
	}
	if file != "" {
		b, err := os.ReadFile(file)
		if err != nil {
			return "", fmt.Errorf("read body file: %w", err)
		}
		return string(b), nil
	}
	if body == "" {
		return "", errors.New("provide --body or --body-file")
	}
	return body, nil
}

type replyMeta struct {
	to        string
	subject   string
	messageID string
}

func replyMetadata(event map[string]any, ownEmail string) (replyMeta, error) {
	messages := sliceOfMaps(event["messages"])
	if len(messages) == 0 {
		return replyMeta{}, errors.New("conversation contains no messages")
	}
	// Reply to the newest incoming message. A thread may end with our own sent
	// message, in which case blindly using the last sender would address ourself.
	last := messages[len(messages)-1]
	if ownEmail != "" {
		for i := len(messages) - 1; i >= 0; i-- {
			from, _ := messages[i]["from"].(map[string]any)
			if !strings.EqualFold(stringValue(from["email"]), ownEmail) {
				last = messages[i]
				break
			}
		}
	}
	to := firstAddress(last["replyTo"])
	if to == "" {
		if from, ok := last["from"].(map[string]any); ok {
			to = formatAddress(from)
		}
	}
	if to == "" {
		return replyMeta{}, errors.New("conversation has no reply address")
	}
	return replyMeta{to: to, subject: stringValue(last["subject"]), messageID: stringValue(last["id"])}, nil
}

func replySubject(subject string) string {
	if strings.HasPrefix(strings.ToLower(strings.TrimSpace(subject)), "re:") {
		return subject
	}
	return "Re: " + subject
}

func printAccounts(event map[string]any, opts options, out io.Writer) error {
	if opts.json {
		return printJSON(out, event)
	}
	for _, a := range sliceOfMaps(event["workspaces"]) {
		fmt.Fprintf(out, "%-16s %-8s %s\n", stringValue(a["id"]), stringValue(a["vendor"]), stringValue(a["email"]))
	}
	return nil
}

func printFolders(event map[string]any, opts options, out io.Writer) error {
	if opts.json {
		return printJSON(out, event)
	}
	for _, f := range sliceOfMaps(event["folders"]) {
		fmt.Fprintf(out, "%-12s %6.0f unread  %-24s %s\n", stringValue(f["role"]), numberValue(f["unread"]), stringValue(f["name"]), stringValue(f["id"]))
	}
	return nil
}

func printConversations(event map[string]any, opts options, out io.Writer) error {
	if opts.json {
		return printJSON(out, event)
	}
	for _, item := range sliceOfMaps(event["items"]) {
		mark := " "
		if unread, _ := item["unread"].(bool); unread {
			mark = "*"
		}
		from := firstAddress(item["senders"])
		fmt.Fprintf(out, "%s %-25.25s %-30.30s  %s\n", mark, stringValue(item["id"]), from, stringValue(item["subject"]))
	}
	if next := stringValue(event["next"]); next != "" {
		fmt.Fprintf(out, "\nMore results available (cursor %s; use --json to retrieve it).\n", next)
	}
	return nil
}

var tagRE = regexp.MustCompile(`(?s)<[^>]*>`)

func printConversation(event map[string]any, opts options, out io.Writer) error {
	if opts.json {
		return printJSON(out, event)
	}
	for i, m := range sliceOfMaps(event["messages"]) {
		if i > 0 {
			fmt.Fprintln(out, "\n----------------------------------------")
		}
		fmt.Fprintf(out, "From: %s\n", formatAddressMap(m["from"]))
		fmt.Fprintf(out, "To: %s\n", addresses(m["to"]))
		fmt.Fprintf(out, "Subject: %s\nDate: %s\nMessage-ID: %s\n\n", stringValue(m["subject"]), stringValue(m["date"]), stringValue(m["id"]))
		body := stringValue(m["bodyText"])
		if body == "" {
			body = html.UnescapeString(tagRE.ReplaceAllString(stringValue(m["bodyRich"]), ""))
		}
		fmt.Fprintln(out, strings.TrimSpace(body))
	}
	return nil
}

func printJSON(out io.Writer, v any) error {
	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

func sliceOfMaps(v any) []map[string]any {
	raw, _ := v.([]any)
	out := make([]map[string]any, 0, len(raw))
	for _, item := range raw {
		if m, ok := item.(map[string]any); ok {
			out = append(out, m)
		}
	}
	return out
}

func stringValue(v any) string {
	s, _ := v.(string)
	return s
}

func numberValue(v any) float64 {
	n, _ := v.(float64)
	return n
}

func formatAddressMap(v any) string {
	m, _ := v.(map[string]any)
	return formatAddress(m)
}

func formatAddress(m map[string]any) string {
	email := stringValue(m["email"])
	name := stringValue(m["name"])
	if name == "" {
		return email
	}
	return fmt.Sprintf("%s <%s>", name, email)
}

func firstAddress(v any) string {
	items := sliceOfMaps(v)
	if len(items) == 0 {
		return ""
	}
	return formatAddress(items[0])
}

func addresses(v any) string {
	items := sliceOfMaps(v)
	out := make([]string, 0, len(items))
	for _, a := range items {
		out = append(out, formatAddress(a))
	}
	return strings.Join(out, ", ")
}
