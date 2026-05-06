#!/usr/bin/env bash
# Deterministic emoji for a tmux session name.
# Same name always maps to the same emoji.
emojis=(🚀 🌟 🎨 🌈 🐉 🔥 ⚡ 🌙 🍀 🌊 🎯 🎭 🎪 🎬 🎮 🦄 🐙 🦊 🐢 🦋 \
        🌵 🍕 🍩 🌮 🥑 🦖 🐳 🦉 🌻 🍄 🎸 🚂 🛸 🗿 🏰 🍣 🐝 🐧 🦒 🐼 \
        🦩 🥨 🪐 ☄️  🛼 🪁 🎲 🧩 🕹️  🦑 🦔 🐊 🦕 🪸 🌴 🍉 🥥 🌽 🫐 \
        🦦 🦥 🐇 🦡 🪲 🐌 🦂 🐡 🐠 🦈 🐋 🦭 🦘 🦃 🦚 🦜 🪼 🪶 🌾 🪷)
name="${1:-}"
if [[ -z "$name" ]]; then
  printf '❓'
  exit 0
fi
hash=$(printf '%s' "$name" | cksum | awk '{print $1}')
idx=$((hash % ${#emojis[@]}))
printf '%s' "${emojis[$idx]}"
