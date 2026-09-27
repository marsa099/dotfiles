# Standalone mlqs CLI

`~/.scripts/mlqs-cli` connects to the running mlqs daemon, independently of
its Nix package. Works with the fork and upstream's socket protocol; when
`bodyText` is absent it renders `bodyRich` as plain text. Upstream may return
cached folder information before refreshing it.

The launcher builds this standard-library-only Go source on first use and
after source changes, caching the executable under
`${XDG_CACHE_HOME:-$HOME/.cache}/mlqs-cli`. Requires Go or Nix (first Nix build
may download Go). No compiler is needed for subsequent cached launches.
Keep `mlqs-cli` and `mlqs-cli-src/` together, and put `~/.scripts` before system
packages in PATH.

Start mlqs, then:

```sh
mlqs-cli accounts
mlqs-cli folders work
mlqs-cli inbox work
mlqs-cli read work CONVERSATION_ID
mlqs-cli search work 'from:person@example.com'
mlqs-cli send work --to person@example.com --subject Hello --body Message
mlqs-cli reply work CONVERSATION_ID --body-file reply.txt
```

Send/reply accept repeated `--attach PATH`. `--body-file -` reads stdin.
Global `--json` precedes the command. Override the socket with `--socket PATH`
or `MLQS_SOCKET`; default is `$XDG_RUNTIME_DIR/mlqs.sock`, or `/tmp/mlqs.sock`.
Sending and replying send real mail; read commands do not mark mail as read.

Tests (no daemon required):

```sh
cd ~/.scripts/mlqs-cli-src
nix shell nixpkgs#go --command go test main.go main_test.go
```

Source and original tests extracted from marsa099/mlqs at 4125c3d,
`cmd/mlqs-cli/`.
