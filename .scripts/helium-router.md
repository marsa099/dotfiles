# Helium URL router

The router sends links through the qs-picker profile rules. Teams links matching
one locally configured work tenant are handed to `teams-for-linux` instead.

## Local tenant configuration

Store the tenant UUID as the only line of:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/helium-router/tenant-id
```

The default `~/.config/helium-router/tenant-id` path is Git-ignored. Never
force-add it. If you use a custom XDG configuration directory inside a repository,
make sure that directory is ignored as well. A tenant ID is an organization
identifier, not an authentication credential, but is kept local for privacy.

The router reads this as plain data, not executable shell configuration. Uppercase
UUIDs and a missing trailing newline are accepted. Missing, empty, or malformed
values disable the Teams-specific override; normal profile routing still works.

## Tests

```bash
python3 ~/.scripts/test-helium-router.py
```

Tests use temporary homes, fake tenant UUIDs, and stub applications. They do not
open browsers or contact Teams.
