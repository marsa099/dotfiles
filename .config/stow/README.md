# Stow Packages

This directory contains all [GNU Stow](https://www.gnu.org/software/stow/) packages for managing dotfiles and user configurations.

## What is Stow?

Stow creates symlinks from your home directory to files stored in this repository. This allows you to version-control your configuration files while keeping them in their expected locations.

## How Stow Works

Each subdirectory here is a "stow package". The directory structure inside each package mirrors where files should be symlinked in your home directory.

**Example:**
```
stow/launchers/.local/share/applications/jira-sis.desktop
```
When stowed, creates:
```
~/.local/share/applications/jira-sis.desktop
  → ~/.config/stow/launchers/.local/share/applications/jira-sis.desktop
```

The package name (`launchers/`) is stripped, and everything inside is linked relative to the target directory.

## Available Packages

### `launchers/`
Custom desktop launcher entries and application icons.

**Contains:**
- `jira-sis.desktop` - JIRA launcher (opens in Chrome SIS profile, app mode)
- `azure-devops.desktop` - Azure DevOps launcher (opens in Chrome Devops profile, app mode)
- Icons for both applications

**Stows to:** `~/.local/share/applications/` and `~/.local/share/icons/`

## Installation

### Prerequisites

Install GNU Stow:
```bash
sudo pacman -S stow
```

### Installing Packages

From the stow directory:
```bash
cd ~/.config/stow
stow -t ~ <package-name>
```

**Example:**
```bash
cd ~/.config/stow
stow -t ~ launchers
```

### Installing All Packages

```bash
cd ~/.config/stow
stow -t ~ */
```

## Common Operations

### Unstow (Remove Symlinks)

```bash
cd ~/.config/stow
stow -D -t ~ <package-name>
```

### Restow (Update After Changes)

```bash
cd ~/.config/stow
stow -R -t ~ <package-name>
```

### Dry Run (Preview Changes)

```bash
cd ~/.config/stow
stow -nv -t ~ <package-name>
```

The `-n` flag performs a dry run, `-v` shows verbose output.

## Adding New Packages

1. Create a new package directory:
   ```bash
   mkdir -p ~/.config/stow/<package-name>
   ```

2. Create the target directory structure inside the package:
   ```bash
   # Example for ~/.local/bin scripts
   mkdir -p ~/.config/stow/<package-name>/.local/bin
   ```

3. Move your files into the package:
   ```bash
   mv ~/.local/bin/my-script ~/.config/stow/<package-name>/.local/bin/
   ```

4. Stow the package:
   ```bash
   cd ~/.config/stow
   stow -t ~ <package-name>
   ```

5. Commit to git:
   ```bash
   git add <package-name>
   git commit -m "Add <package-name> package"
   ```

## Package Naming Conventions

- Use lowercase with hyphens: `my-package`
- Be descriptive but concise
- Group related configs logically
- Examples: `launchers`, `scripts`, `shell`, `fonts`

## Troubleshooting

### Conflict: File Already Exists

If stow reports a conflict:
```
WARNING! stowing launchers would cause conflicts:
  * existing target is neither a link nor a directory: .local/share/applications/jira-sis.desktop
```

**Solution:** Remove or backup the existing file first:
```bash
mv ~/.local/share/applications/jira-sis.desktop{,.backup}
cd ~/.config/stow
stow -t ~ launchers
```

### Verifying Symlinks

Check if a file is properly symlinked:
```bash
ls -la ~/.local/share/applications/jira-sis.desktop
```

Should show:
```
jira-sis.desktop -> ../../../.config/stow/launchers/.local/share/applications/jira-sis.desktop
```

### Broken Symlinks

If symlinks are broken after moving the package:
```bash
cd ~/.config/stow
stow -R -t ~ <package-name>  # Restow to fix
```

## Suggested Packages to Add

Consider creating these packages for better dotfile management:

### `scripts/`
Custom scripts from `~/.local/bin/`:
```bash
mkdir -p ~/.config/stow/scripts/.local/bin
mv ~/.local/bin/my-script ~/.config/stow/scripts/.local/bin/
```

### `shell/`
Shell configuration files:
```bash
mkdir -p ~/.config/stow/shell
mv ~/.bashrc ~/.config/stow/shell/.bashrc
```

### `fonts/`
Custom fonts:
```bash
mkdir -p ~/.config/stow/fonts/.local/share/fonts
cp -r ~/.local/share/fonts/* ~/.config/stow/fonts/.local/share/fonts/
```

## Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Managing Dotfiles with GNU Stow](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html)
