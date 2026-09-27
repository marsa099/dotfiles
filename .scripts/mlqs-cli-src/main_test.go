package main

import (
	"encoding/json"
	"io"
	"net"
	"path/filepath"
	"strings"
	"testing"
)

func fakeDaemon(t *testing.T, serve func(*json.Decoder, *json.Encoder)) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "mlqs.sock")
	ln, err := net.Listen("unix", path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = ln.Close() })
	go func() {
		conn, err := ln.Accept()
		if err != nil {
			return
		}
		defer conn.Close()
		serve(json.NewDecoder(conn), json.NewEncoder(conn))
	}()
	return path
}

func decodeCommand(t *testing.T, dec *json.Decoder) map[string]any {
	t.Helper()
	var cmd map[string]any
	if err := dec.Decode(&cmd); err != nil {
		t.Errorf("decode command: %v", err)
	}
	return cmd
}

func TestAccounts(t *testing.T) {
	path := fakeDaemon(t, func(_ *json.Decoder, enc *json.Encoder) {
		_ = enc.Encode(map[string]any{"type": "workspaces", "workspaces": []map[string]any{
			{"id": "work", "vendor": "outlook", "email": "me@example.com"},
		}})
	})
	var out strings.Builder
	if err := run([]string{"--socket", path, "accounts"}, &out, io.Discard); err != nil {
		t.Fatal(err)
	}
	if got := out.String(); !strings.Contains(got, "work") || !strings.Contains(got, "outlook") || !strings.Contains(got, "me@example.com") {
		t.Fatalf("unexpected output: %q", got)
	}
}

func TestInboxWaitsForLiveResponses(t *testing.T) {
	path := fakeDaemon(t, func(dec *json.Decoder, enc *json.Encoder) {
		cmd := decodeCommand(t, dec)
		if cmd["type"] != "folders" || cmd["account"] != "personal" {
			t.Errorf("unexpected folders command: %#v", cmd)
		}
		folders := []map[string]any{{"id": "INBOX", "name": "Inbox", "role": "inbox", "unread": 2}}
		_ = enc.Encode(map[string]any{"type": "folders", "cached": true, "folders": folders})
		_ = enc.Encode(map[string]any{"type": "folders", "folders": folders})
		cmd = decodeCommand(t, dec)
		if cmd["type"] != "conversations" || cmd["folder"] != "INBOX" {
			t.Errorf("unexpected conversations command: %#v", cmd)
		}
		_ = enc.Encode(map[string]any{"type": "conversations", "cached": true, "items": []any{}})
		_ = enc.Encode(map[string]any{"type": "conversations", "items": []map[string]any{
			{"id": "thread-1", "unread": true, "subject": "Status", "senders": []map[string]any{{"name": "Ada", "email": "ada@example.com"}}},
		}})
	})
	var out strings.Builder
	if err := run([]string{"--socket", path, "inbox", "personal"}, &out, io.Discard); err != nil {
		t.Fatal(err)
	}
	if got := out.String(); !strings.Contains(got, "thread-1") || !strings.Contains(got, "Status") || !strings.HasPrefix(got, "*") {
		t.Fatalf("unexpected output: %q", got)
	}
}

func TestReplyInfersRecipientAndThreadMetadata(t *testing.T) {
	path := fakeDaemon(t, func(dec *json.Decoder, enc *json.Encoder) {
		cmd := decodeCommand(t, dec)
		if cmd["type"] != "conversation" || cmd["id"] != "thread-7" {
			t.Errorf("unexpected conversation command: %#v", cmd)
		}
		_ = enc.Encode(map[string]any{"type": "conversation", "messages": []map[string]any{
			{"id": "message-9", "subject": "Question", "from": map[string]any{"name": "Sam", "email": "sam@example.com"},
				"replyTo": []map[string]any{{"email": "reply@example.com"}}},
		}})
		cmd = decodeCommand(t, dec)
		if cmd["type"] != "send" || cmd["to"] != "reply@example.com" || cmd["subject"] != "Re: Question" || cmd["replyTo"] != "message-9" || cmd["conv"] != "thread-7" || cmd["body"] != "On it" {
			t.Errorf("unexpected send command: %#v", cmd)
		}
		_ = enc.Encode(map[string]any{"type": "sent", "account": "work", "conv": "thread-7"})
	})
	var out strings.Builder
	if err := run([]string{"--socket", path, "reply", "work", "thread-7", "--body", "On it"}, &out, io.Discard); err != nil {
		t.Fatal(err)
	}
	if got := out.String(); got != "sent\n" {
		t.Fatalf("unexpected output: %q", got)
	}
}

func TestReplyMetadataSkipsOwnLatestMessage(t *testing.T) {
	event := map[string]any{"messages": []any{
		map[string]any{"id": "incoming", "subject": "Topic", "from": map[string]any{"email": "them@example.com"}},
		map[string]any{"id": "outgoing", "subject": "Re: Topic", "from": map[string]any{"email": "me@example.com"}},
	}}
	meta, err := replyMetadata(event, "me@example.com")
	if err != nil {
		t.Fatal(err)
	}
	if meta.to != "them@example.com" || meta.messageID != "incoming" {
		t.Fatalf("unexpected reply metadata: %#v", meta)
	}
}

func TestReadUpstreamBodyRich(t *testing.T) {
	path := fakeDaemon(t, func(dec *json.Decoder, enc *json.Encoder) {
		cmd := decodeCommand(t, dec)
		if cmd["type"] != "conversation" || cmd["id"] != "thread-1" {
			t.Errorf("unexpected command: %#v", cmd)
		}
		_ = enc.Encode(map[string]any{"type": "conversation", "messages": []map[string]any{
			{"id": "msg-1", "subject": "Upstream", "bodyRich": "<p>Hello &amp; welcome</p>"},
		}})
	})
	var out strings.Builder
	if err := run([]string{"--socket", path, "read", "work", "thread-1"}, &out, io.Discard); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "Hello & welcome") || strings.Contains(out.String(), "<p>") {
		t.Fatalf("unexpected body: %q", out.String())
	}
}

func TestReplySubjectDoesNotDuplicatePrefix(t *testing.T) {
	if got := replySubject("RE: Existing"); got != "RE: Existing" {
		t.Fatalf("replySubject = %q", got)
	}
}
