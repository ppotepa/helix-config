#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
HELIX_DIR="$CONFIG_ROOT/helix"
STAMP="$(date +%Y%m%d-%H%M%S)"
LINK_ONLY=0
STRICT=0
FAILURES=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--link-only] [--strict]

Options:
  --link-only   Only create/update symlinks in ~/.config/helix
  --strict      Exit on first tool installation failure
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --link-only) LINK_ONLY=1 ;;
    --strict) STRICT=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      usage
      exit 2
      ;;
  esac
done

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

have() {
  command -v "$1" >/dev/null 2>&1
}

run_step() {
  local label="$1"
  shift
  echo ""
  echo "==> $label"
  if "$@"; then
    echo "[ok] $label"
  else
    echo "[warn] $label"
    FAILURES+=("$label")
    if [[ "$STRICT" -eq 1 ]]; then
      echo "Stopping due to --strict"
      exit 1
    fi
  fi
}

install_system_pkg() {
  local pkg="$1"
  if have apt-get; then
    sudo apt-get install -y "$pkg"
  elif have pacman; then
    sudo pacman -S --noconfirm "$pkg"
  elif have dnf; then
    sudo dnf install -y "$pkg"
  elif have zypper; then
    sudo zypper --non-interactive install "$pkg"
  else
    return 1
  fi
}

install_npm_global() {
  local pkg="$1"
  npm install -g --prefix "$HOME/.local" "$pkg"
}

ensure_profile_path_block() {
  local profile="$HOME/.profile"
  local begin="# >>> helix-config >>>"
  local end="# <<< helix-config <<<"

  touch "$profile"
  if grep -Fq "$begin" "$profile"; then
    return 0
  fi

  cat >>"$profile" <<EOF
$begin
export PATH="\$HOME/.local/bin:\$HOME/go/bin:\$HOME/.cargo/bin:\$PATH"
$end
EOF
  echo "Added PATH block to $profile"
}

install_toolchain() {
  echo ""
  echo "Installing language support toolchain (best effort)..."

  run_step "Ensure profile PATH has ~/.local/bin, ~/go/bin, ~/.cargo/bin" ensure_profile_path_block

  if have npm; then
    run_step "Install npm: pyright" install_npm_global pyright
    run_step "Install npm: typescript" install_npm_global typescript
    run_step "Install npm: typescript-language-server" install_npm_global typescript-language-server
    run_step "Install npm: vscode-langservers-extracted (HTML/CSS/JSON)" install_npm_global vscode-langservers-extracted
    run_step "Install npm: yaml-language-server" install_npm_global yaml-language-server
    run_step "Install npm: bash-language-server" install_npm_global bash-language-server
    run_step "Install npm: @ansible/ansible-language-server" install_npm_global @ansible/ansible-language-server
  else
    echo "[warn] npm not found; skipping JS/TS/YAML/Bash/Ansible/Pyright npm tooling"
    FAILURES+=("npm toolchain")
  fi

  if have python3; then
    run_step "Install pip: ruff (user)" python3 -m pip install --user --upgrade ruff
  else
    echo "[warn] python3 not found; skipping ruff"
    FAILURES+=("ruff")
  fi

  if have go; then
    run_step "Install go: gopls" go install golang.org/x/tools/gopls@latest
    run_step "Install go: golangci-lint-langserver" go install github.com/nametake/golangci-lint-langserver@latest
    run_step "Install go: golangci-lint" go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
  else
    echo "[warn] go not found; skipping Go language servers"
    FAILURES+=("go toolchain")
  fi

  if have rustup; then
    run_step "Install rustup components: rust-analyzer + rustfmt" rustup component add rust-analyzer rustfmt
  else
    echo "[warn] rustup not found; trying package-manager rust-analyzer later"
    FAILURES+=("rustup components")
  fi

  if have cargo; then
    run_step "Install cargo: marksman" cargo install --locked marksman
    run_step "Install cargo: markdown-oxide" cargo install --locked markdown-oxide
  else
    echo "[warn] cargo not found; skipping marksman/markdown-oxide"
    FAILURES+=("cargo markdown tooling")
  fi

  if have lua-language-server; then
    echo "[ok] lua-language-server already installed"
  else
    if have sudo; then
      run_step "Install system package: lua-language-server" install_system_pkg lua-language-server
    else
      echo "[warn] lua-language-server missing and sudo unavailable"
      FAILURES+=("lua-language-server")
    fi
  fi
}

mkdir -p "$HELIX_DIR"

link_item "$REPO_DIR/config.toml" "$HELIX_DIR/config.toml"
link_item "$REPO_DIR/languages.toml" "$HELIX_DIR/languages.toml"
link_item "$REPO_DIR/scripts" "$HELIX_DIR/scripts"

if [[ "$LINK_ONLY" -eq 0 ]]; then
  install_toolchain
fi

cat <<EOF

Install complete.
Next steps:
1) Start Helix: hx <project>
2) Run :config-reload
3) Run :lsp-restart
4) Check health: hx --health
EOF

if [[ "${#FAILURES[@]}" -gt 0 ]]; then
  echo ""
  echo "Some steps failed (best-effort mode):"
  for item in "${FAILURES[@]}"; do
    echo "- $item"
  done
  echo "Re-run with --strict if you want hard-fail behavior."
fi
