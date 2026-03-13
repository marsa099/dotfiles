# Wipe personal data — detailed task log

## Step 1: Export keys and data to USB

### 1.1 Format USB drive
- [x] Wiped `/dev/sda` with `wipefs -a`
- [x] Created GPT partition table with `parted`
- [x] Formatted as ext4 with label BACKUP
- [x] Mounted at `/mnt/usb`, chowned to martin

### 1.2 Export GPG keys
- [x] Listed secret keys: `ed25519/1CD481D6D6BB4173` (martin@koderiet.dev, expires 2027-08-22)
- [x] Exported public key → `/mnt/usb/gpg-keys/public.asc`
- [x] Exported secret key → `/mnt/usb/gpg-keys/secret.asc`
- [x] Exported trust → `/mnt/usb/gpg-keys/trust.txt`

### 1.3 Export SSH keys
- [x] Copied `~/.ssh/` → `/mnt/usb/ssh-keys/`

### 1.4 Export .claude folder
- [x] Copied `~/.claude/` → `/mnt/usb/claude/` (174M)

### 1.5 Export .openclaw folder
- [x] Copied `~/.openclaw/` → `/mnt/usb/openclaw/` (243M)

### 1.6 Export repos folder
- [x] Cleaned repos first: removed bin, obj, nuget, npm/pnpm folders (11G → 3.5G)
- [x] Copied `~/repos/` → `/mnt/usb/repos/` (3.5G)

## Step 2: Remove sensitive data in home dir
- [ ] `rm -rf ~/.ssh/`
- [ ] `rm -rf ~/.gnupg/`
- [ ] `rm -rf ~/.password-store/`
- [ ] `rm -rf ~/.gitconfig`
- [ ] `rm -rf ~/.claude/ ~/.claude.json`
- [ ] `rm -rf ~/.openclaw/`
- [ ] `rm -rf ~/.config/`
- [ ] `rm -rf ~/.local/`
- [ ] `rm -rf ~/.bash_history`
- [ ] `rm -rf ~/repos/`
- [ ] `rm -rf ~/tools/`
- [ ] `rm -rf ~/notes/`
- [ ] `rm -rf ~/.npm/`
- [ ] `rm -rf ~/.pki/`

## Step 3: Remove browsers and browser data
- [ ] Uninstall Firefox, Zen, Chrome
- [ ] Remove `~/.mozilla/` `~/.zen/` `~/.config/google-chrome/`

## Step 4: Remove chat apps
- [ ] Uninstall Vesktop, Teams, Discord

## Step 5: Clean outside home dir (sudo)
- [ ] Remove `/etc/NetworkManager/system-connections/*`
- [ ] Clean `/tmp` and `/var/tmp`
- [ ] Clean `/root/`
- [ ] Clear journal: `sudo journalctl --vacuum-time=0`

## Step 6: Revoke/rotate sessions
- [ ] GitHub sessions
- [ ] Azure DevOps PAT
- [ ] Other services

## Step 7: Wipe free space
- [ ] `sudo fstrim -v /` and `sudo fstrim -v /home`
