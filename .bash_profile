#
# ~/.bash_profile
#

# Seed ~/.scripts onto PATH here, in the tty1 login shell that execs niri-session
# below. niri-session runs `systemctl --user import-environment`, so this PATH is
# imported into systemd --user and inherited by every child of the session —
# terminals, GUI apps, and non-interactive shells like Claude Code's, where
# .bashrc returns early and ~/.config/environment.d gets clobbered by that same
# import. This is why wrapper scripts in ~/.scripts (e.g. `config`) resolve
# everywhere, not just interactive shells.
case ":$PATH:" in
    *":$HOME/.scripts:"*) ;;
    *) export PATH="$HOME/.scripts:$PATH" ;;
esac

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ] ; then
    # -l flag skips niri-session's re-exec through login shell (we're already in one)
    exec niri-session -l
fi
