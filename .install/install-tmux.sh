## Tmux, https://github.com/tmux/tmux
sudo pacman -Syu tmux 

## Tmux Plugin Manager, https://github.com/tmux-plugins/tpm
TMUX_PLUGINS=~/.tmux/plugins/tpm
mkdir -p $TMUX_PLUGINS
if [[ -d "$TMUX_PLUGINS/.git" ]]
then
	git -C $TMUX_PLUGINS pull
else
	git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGINS" --depth=1
fi
