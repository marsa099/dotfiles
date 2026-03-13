# Wipe personal data

## 1. Export keys
- [ ] Export GPG keys to USB/safe location
- [ ] Verify GPG export works by listing contents
- [ ] Export `~/.ssh/` (keys + config) to USB/safe location
- [ ] Export `~/.claude/` to USB/safe location
- [ ] Export `~/.openclaw/` to USB/safe location
- [ ] Export `~/repos/` to USB/safe location

## 2. Remove sensitive data in home dir
- [ ] `~/.ssh/` — SSH keys
- [ ] `~/.gnupg/` — GPG keyring
- [ ] `~/.password-store/` — pass store (backed up remote)
- [ ] `~/.gitconfig` — may contain credentials/tokens
- [ ] `~/.claude/` — Claude config, jira/devops credentials
- [ ] `~/.claude.json` — Claude session
- [ ] `~/.openclaw/` — openclaw data
- [ ] `~/.config/` — app configs (may contain tokens)
- [ ] `~/.local/` — local app data
- [ ] `~/.bash_history` — command history
- [ ] `~/repos/` — source code
- [ ] `~/tools/` — custom tools (if exists)
- [ ] `~/notes/` — personal notes
- [ ] `~/.npm/` — npm cache/tokens
- [ ] `~/.pki/` — certificates

## 3. Remove browsers and browser data
- [ ] Firefox — history, saved passwords, cookies, credit cards, autofill
- [ ] Zen — history, saved passwords, cookies, credit cards, autofill
- [ ] Chrome — history, saved passwords, cookies, credit cards, autofill
- [ ] Check `~/.mozilla/`, `~/.zen/`, `~/.config/google-chrome/` if uninstall doesn't clean up

## 4. Remove chat apps
- [ ] Vesktop (Discord)
- [ ] Teams
- [ ] Discord

## 5. Check outside home dir (needs sudo)
- [ ] `/etc/NetworkManager/system-connections/` — saved WiFi passwords
- [ ] `/tmp` and `/var/tmp` — temp files
- [ ] `/root/` — anything from sudo usage
- [ ] `/var/log/` and journalctl — may contain sensitive info

## 6. Revoke/rotate sessions
- [ ] GitHub sessions
- [ ] Azure DevOps PAT
- [ ] Any other logged-in services

## 7. Wipe free space (optional but recommended)
- [ ] `sudo fstrim -v /` and `sudo fstrim -v /home`
- [ ] Consider `sfill` or `shred` on sensitive files before deleting
