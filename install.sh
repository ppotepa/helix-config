#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
HELIX_DIR="$CONFIG_ROOT/helix"
STAMP="$(date +%Y%m%d-%H%M%S)"

backup_if_needed() {
  local dst="$1"
  local src="$2"
  local current=""

  if [[ ! -e "$dst" && ! -L "$dst" ]]; then
    return 0
  fi

  current="$(readlink -f "$dst" 2>/dev/null || true)"
  if [[ "$current" == "$src" ]]; then
    return 0
  fi

  local backup="${dst}.bak.${STAMP}"
  mv "$dst" "$backup"
  echo "Backed up $dst -> $backup"
}

link_item() {
  local src="$1"
  local dst="$2"
  backup_if_needed "$dst" "$src"
  ln -sfn "$src" "$dst"
  echo "Linked $dst -> $src"
}

mkdir -p "$HELIX_DIR"

link_item "$REPO_DIR/config.toml" "$HELIX_DIR/config.toml"
link_item "$REPO_DIR/languages.toml" "$HELIX_DIR/languages.toml"
link_item "$REPO_DIR/scripts" "$HELIX_DIR/scripts"

cat <<EOF

Install complete.
Next steps:
1) Start Helix: hx <project>
2) Run :config-reload
3) Run :lsp-restart
EOF
