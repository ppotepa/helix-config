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
  cat <<'USAGE'
Usage: ./install.sh [--link-only] [--strict]

Options:
  --link-only   Only create/update symlinks in ~/.config/helix.
  --strict      Exit on first installation failure.
  -h, --help    Show this help
USAGE
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

have() {
  command -v "$1" >/dev/null 2>&1
}

log_ok() {
  echo "[ok] $1"
}

log_warn() {
  echo "[warn] $1"
}

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

run_step() {
  local label="$1"
  shift
  local status=0
  echo ""
  echo "==> $label"
  if "$@"; then
    echo "[ok] $label"
  else
    status=1
    echo "[warn] $label"
    FAILURES+=("$label")
    if [[ "$STRICT" -eq 1 ]]; then
      echo "Stopping due to --strict"
      exit 1
    fi
  fi
  return "$status"
}

sudo_available() {
  if [[ "$(id -u)" -eq 0 ]]; then
    return 0
  fi
  if ! have sudo; then
    return 1
  fi
  if sudo -n true >/dev/null 2>&1; then
    return 0
  fi
  if [[ -t 0 ]]; then
    # Let sudo ask for password in an interactive terminal.
    return 0
  fi
  return 1
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_system_pkg() {
  local pkg="$1"
  if ! sudo_available; then
    return 1
  fi

  if have apt-get; then
    run_as_root apt-get install -y "$pkg"
  elif have pacman; then
    run_as_root pacman -S --needed --noconfirm "$pkg"
  elif have dnf; then
    run_as_root dnf install -y "$pkg"
  elif have zypper; then
    run_as_root zypper --non-interactive install "$pkg"
  else
    return 1
  fi
}

install_system_pkg_any() {
  local pkg
  for pkg in "$@"; do
    if install_system_pkg "$pkg"; then
      return 0
    fi
  done
  return 1
}

install_aur_pkg_any() {
  local pkg
  if ! have yay; then
    return 1
  fi
  for pkg in "$@"; do
    if yay -S --needed --noconfirm "$pkg"; then
      return 0
    fi
  done
  return 1
}

install_npm_global() {
  local pkg="$1"
  npm install -g --prefix "$HOME/.local" "$pkg"
}

install_dotnet_tool() {
  local tool="$1"
  dotnet tool update --global "$tool" || dotnet tool install --global "$tool"
}

ensure_system_cmd() {
  local cmd="$1"
  local label="$2"
  shift 2
  if have "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  if sudo_available; then
    if install_system_pkg_any "$@"; then
      log_ok "$label"
      return 0
    fi
  fi

  # Arch fallback for packages that exist only in AUR.
  if sudo_available && have pacman && have yay; then
    if run_step "$label (AUR fallback)" install_aur_pkg_any "$@"; then
      return 0
    fi
  fi

  log_warn "$cmd missing; cannot auto-install system package"
  FAILURES+=("$label")
  if [[ "$STRICT" -eq 1 ]]; then
    exit 1
  fi
}

ensure_npm_cmd() {
  local cmd="$1"
  local pkg="$2"
  if have "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi
  run_step "Install npm: $pkg" install_npm_global "$pkg"
}

ensure_go_cmd() {
  local cmd="$1"
  local module="$2"
  if have "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi
  run_step "Install go: $cmd" go install "${module}@latest"
}

ensure_cargo_cmd() {
  local cmd="$1"
  shift
  if have "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi
  run_step "Install cargo: $cmd" cargo install --locked "$@"
}

ensure_profile_path_block() {
  local profile="$HOME/.profile"
  local begin="# >>> helix-config >>>"
  local end="# <<< helix-config <<<"

  touch "$profile"
  if grep -Fq "$begin" "$profile"; then
    return 0
  fi

  cat >>"$profile" <<PATHBLOCK
$begin
export PATH="\$HOME/.local/bin:\$HOME/go/bin:\$HOME/.cargo/bin:\$HOME/.dotnet/tools:\$PATH"
$end
PATHBLOCK
  echo "Added PATH block to $profile"
}

install_toolchain() {
  echo ""
  echo "Installing FULL language support toolchain (best effort)..."

  run_step "Ensure profile PATH has ~/.local/bin, ~/go/bin, ~/.cargo/bin, ~/.dotnet/tools" ensure_profile_path_block

  # Runtime bootstrap.
  if ! have python3 && sudo_available; then
    run_step "Install runtime: python3 + pip" install_system_pkg_any python3 python3-pip
  fi
  if ! have npm && sudo_available; then
    run_step "Install runtime: npm/node" install_system_pkg_any npm nodejs-lts nodejs
  fi
  if ! have go && sudo_available; then
    run_step "Install runtime: go" install_system_pkg_any golang-go golang go
  fi
  if ! have rustup && ! have cargo && sudo_available; then
    run_step "Install runtime: rustup/cargo" install_system_pkg_any rustup cargo rust
  fi
  if ! have dotnet && sudo_available; then
    run_step "Install runtime: dotnet SDK" install_system_pkg_any dotnet-sdk dotnet-sdk-8.0 dotnet-sdk-7.0
  fi

  if have npm; then
    # JS/TS + web + config/data ecosystem.
    ensure_npm_cmd pyright-langserver pyright
    ensure_npm_cmd typescript-language-server typescript-language-server
    ensure_npm_cmd tsc typescript
    ensure_npm_cmd vscode-html-language-server vscode-langservers-extracted
    ensure_npm_cmd vscode-css-language-server vscode-langservers-extracted
    ensure_npm_cmd vscode-json-language-server vscode-langservers-extracted
    ensure_npm_cmd yaml-language-server yaml-language-server
    ensure_npm_cmd ansible-language-server @ansible/ansible-language-server
    ensure_npm_cmd bash-language-server bash-language-server
    ensure_npm_cmd docker-langserver dockerfile-language-server-nodejs
    ensure_npm_cmd vue-language-server @vue/language-server
    ensure_npm_cmd svelteserver svelte-language-server
    ensure_npm_cmd graphql-lsp graphql-language-service-cli
    ensure_npm_cmd sql-language-server sql-language-server
    ensure_npm_cmd intelephense intelephense
    ensure_npm_cmd prettier prettier
  else
    log_warn "npm not found; skipping npm-based LSP toolchain"
    FAILURES+=("npm toolchain")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
    fi
  fi

  if have python3; then
    if have ruff; then
      log_ok "ruff already installed"
    else
      run_step "Install pip: ruff (user)" python3 -m pip install --user --upgrade ruff
    fi
  else
    log_warn "python3 not found; skipping ruff"
    FAILURES+=("ruff")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
    fi
  fi

  if have go; then
    ensure_go_cmd gopls golang.org/x/tools/gopls
    ensure_go_cmd golangci-lint-langserver github.com/nametake/golangci-lint-langserver
    ensure_go_cmd golangci-lint github.com/golangci/golangci-lint/cmd/golangci-lint
    ensure_go_cmd sqls github.com/sqls-server/sqls
    ensure_go_cmd terraform-ls github.com/hashicorp/terraform-ls
    ensure_go_cmd shfmt mvdan.cc/sh/v3/cmd/shfmt
  else
    log_warn "go not found; skipping Go-based tools"
    FAILURES+=("go toolchain")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
    fi
  fi

  if have rustup; then
    run_step "Install rustup components: rust-analyzer + rustfmt" rustup component add rust-analyzer rustfmt
  else
    log_warn "rustup not found; skipping rustup components"
    FAILURES+=("rustup components")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
    fi
  fi

  if have cargo; then
    ensure_cargo_cmd marksman marksman
    ensure_cargo_cmd markdown-oxide markdown-oxide
    ensure_cargo_cmd taplo taplo-cli --features lsp
    ensure_cargo_cmd stylua stylua
  else
    log_warn "cargo not found; skipping cargo-based tools"
    FAILURES+=("cargo toolchain")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
    fi
  fi

  # System tools used by C/C++/Java/Lua/Nix/.NET/PHP stacks.
  ensure_system_cmd clangd "Install system package: clangd/clang-tools" clangd clang-tools
  ensure_system_cmd lua-language-server "Install system package: lua-language-server" lua-language-server lua-language-server-bin
  ensure_system_cmd jdtls "Install system package: jdtls" jdtls jdtls-bin eclipse-jdtls

  if have nil || have nixd; then
    log_ok "Nix LSP already installed (nil or nixd)"
  else
    ensure_system_cmd nil "Install system package: Nix LSP (nil/nixd)" nil nil-language-server nil-git nixd nixd-bin nixd-git
  fi

  ensure_system_cmd php "Install system package: php CLI" php
  ensure_system_cmd java "Install system package: Java JDK" openjdk-21-jdk openjdk-17-jdk java-21-openjdk java-17-openjdk
  ensure_system_cmd dotnet "Install system package: dotnet SDK" dotnet-sdk

  if have dotnet; then
    if have csharp-ls; then
      log_ok "csharp-ls already installed"
    else
      run_step "Install dotnet tool: csharp-ls" install_dotnet_tool csharp-ls
    fi
  else
    log_warn "dotnet not found; skipping csharp-ls"
    FAILURES+=("csharp-ls")
    if [[ "$STRICT" -eq 1 ]]; then
      exit 1
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

cat <<'EOF_MSG'

Install complete.
Next steps:
1) Restart shell (or source ~/.profile)
2) Start Helix: hx <project>
3) Run :config-reload
4) Run :lsp-restart
5) Check health: hx --health
EOF_MSG

if [[ "${#FAILURES[@]}" -gt 0 ]]; then
  echo ""
  echo "Some steps failed (best-effort mode):"
  for item in "${FAILURES[@]}"; do
    echo "- $item"
  done
  echo "Re-run with --strict if you want hard-fail behavior."
fi
