#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
HELIX_DIR="$CONFIG_ROOT/helix"
STAMP="$(date +%Y%m%d-%H%M%S)"
LINK_ONLY=0
STRICT=0
DOCTOR=0
FAILURES=()

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--link-only] [--strict] [--doctor]

Options:
  --link-only   Only create/update symlinks in ~/.config/helix.
  --strict      Fail immediately on first unmet requirement.
  --doctor      Run diagnostics only (no installs), return non-zero on problems.
  -h, --help    Show this help
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --link-only) LINK_ONLY=1 ;;
    --strict) STRICT=1 ;;
    --doctor) DOCTOR=1 ;;
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

tool_exists() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi

  local dir
  for dir in "$HOME/.local/bin" "$HOME/go/bin" "${CARGO_HOME:-$HOME/.cargo}/bin" "$HOME/.dotnet/tools"; do
    if [[ -x "$dir/$cmd" ]]; then
      return 0
    fi
  done
  return 1
}

add_failure() {
  local msg="$1"
  local existing
  for existing in "${FAILURES[@]:-}"; do
    if [[ "$existing" == "$msg" ]]; then
      return 0
    fi
  done
  FAILURES+=("$msg")
}

fail_or_warn() {
  local msg="$1"
  echo "[warn] $msg"
  add_failure "$msg"
  if [[ "$STRICT" -eq 1 ]]; then
    exit 1
  fi
}

log_step() {
  echo ""
  echo "==> $*"
}

log_ok() {
  echo "[ok] $*"
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
  [[ -t 0 ]]
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
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

ensure_path_block_in_file() {
  local target="$1"
  local begin="# >>> helix-config-path >>>"
  local end="# <<< helix-config-path <<<"
  local legacy_begin="# >>> helix-config >>>"
  local legacy_end="# <<< helix-config <<<"
  local tmp

  touch "$target"

  # Remove old/legacy managed blocks to avoid duplicated PATH injections.
  tmp="$(mktemp)"
  awk -v b1="$begin" -v e1="$end" -v b2="$legacy_begin" -v e2="$legacy_end" '
    $0==b1 {skip=1; next}
    $0==e1 {skip=0; next}
    $0==b2 {skip=1; next}
    $0==e2 {skip=0; next}
    !skip {print}
  ' "$target" >"$tmp"
  mv "$tmp" "$target"

  if grep -Fq "$begin" "$target"; then
    log_ok "PATH block already present in $target"
    return 0
  fi

  cat >>"$target" <<PATHBLOCK
$begin
export PATH="\$HOME/.local/bin:\$HOME/go/bin:\$HOME/.cargo/bin:\$HOME/.dotnet/tools:\$PATH"
$end
PATHBLOCK
  log_ok "Added PATH block to $target"
}

ensure_shell_path_blocks() {
  ensure_path_block_in_file "$HOME/.profile"
  ensure_path_block_in_file "$HOME/.bashrc"
}

ensure_environmentd_path_file() {
  local envd_dir="$HOME/.config/environment.d"
  local envd_file="$envd_dir/helix-config-path.conf"

  mkdir -p "$envd_dir"
  cat >"$envd_file" <<ENVFILE
# Managed by helix-config install.sh
PATH=$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.dotnet/tools:\${PATH}
ENVFILE
  log_ok "Wrote $envd_file"
}

ensure_bash_alias_hx() {
  local bashrc="$HOME/.bashrc"
  local begin="# >>> helix-config-hx-alias >>>"
  local end="# <<< helix-config-hx-alias <<<"
  local tmp

  touch "$bashrc"
  tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    # Remove legacy unmanaged aliases from previous installer versions.
    $0 ~ /^[[:space:]]*alias[[:space:]]+hx='\''helix'\''[[:space:]]*$/ {next}
    !skip {print}
  ' "$bashrc" >"$tmp"
  mv "$tmp" "$bashrc"

  cat >>"$bashrc" <<ALIASBLOCK
$begin
alias hx='helix'
$end
ALIASBLOCK
  log_ok "Ensured hx alias in $bashrc"
}

ensure_hx_shim() {
  local shim_dir="$HOME/.local/bin"
  local shim="$shim_dir/hx"

  if have hx; then
    log_ok "hx command already available"
    return 0
  fi

  if ! have helix; then
    fail_or_warn "Cannot create hx shim because helix binary is missing"
    return 1
  fi

  mkdir -p "$shim_dir"
  cat >"$shim" <<'SHIM'
#!/usr/bin/env bash
exec helix "$@"
SHIM
  chmod +x "$shim"
  log_ok "Created hx shim at $shim"
}

install_system_pkg() {
  local pkg="$1"
  if ! sudo_available; then
    return 1
  fi

  if have pacman; then
    pacman -Si "$pkg" >/dev/null 2>&1 || return 1
    run_as_root pacman -S --needed --noconfirm "$pkg"
  elif have apt-get; then
    run_as_root apt-get install -y "$pkg"
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
    if yay -Si "$pkg" >/dev/null 2>&1; then
      if yay -S --needed --noconfirm "$pkg"; then
        return 0
      fi
    fi
  done
  return 1
}

ensure_system_cmd() {
  local cmd="$1"
  local label="$2"
  shift 2

  if tool_exists "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_step "$label"

  if install_system_pkg_any "$@" && tool_exists "$cmd"; then
    log_ok "$label"
    return 0
  fi

  if have pacman && have yay; then
    if install_aur_pkg_any "$@" && tool_exists "$cmd"; then
      log_ok "$label (AUR)"
      return 0
    fi
  fi

  fail_or_warn "$label"
}

ensure_npm_cmd() {
  local cmd="$1"
  local pkg="$2"

  if tool_exists "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_step "Install npm: $pkg"
  if npm install -g --prefix "$HOME/.local" "$pkg" && tool_exists "$cmd"; then
    log_ok "Install npm: $pkg"
  else
    fail_or_warn "Install npm: $pkg"
  fi
}

ensure_go_cmd() {
  local cmd="$1"
  local module="$2"

  if tool_exists "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_step "Install go: $cmd"
  if go install "${module}@latest" && tool_exists "$cmd"; then
    log_ok "Install go: $cmd"
  else
    fail_or_warn "Install go: $cmd"
  fi
}

ensure_cargo_cmd() {
  local cmd="$1"
  shift

  if tool_exists "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_step "Install cargo: $cmd"
  if cargo install --locked "$@" && tool_exists "$cmd"; then
    log_ok "Install cargo: $cmd"
  else
    fail_or_warn "Install cargo: $cmd"
  fi
}

ensure_dotnet_tool() {
  local cmd="$1"
  local pkg="$2"

  if tool_exists "$cmd"; then
    log_ok "$cmd already installed"
    return 0
  fi

  log_step "Install dotnet tool: $pkg"
  if dotnet tool update --global "$pkg" || dotnet tool install --global "$pkg"; then
    if tool_exists "$cmd"; then
      log_ok "Install dotnet tool: $pkg"
      return 0
    fi
  fi
  fail_or_warn "Install dotnet tool: $pkg"
}

ensure_one_of_cmds() {
  local label="$1"
  local cmd_a="$2"
  local cmd_b="$3"
  shift 3

  if tool_exists "$cmd_a" || tool_exists "$cmd_b"; then
    log_ok "$label already installed"
    return 0
  fi

  log_step "$label"

  if install_system_pkg_any "$@" && (tool_exists "$cmd_a" || tool_exists "$cmd_b"); then
    log_ok "$label"
    return 0
  fi

  if have pacman && have yay; then
    if install_aur_pkg_any "$@" && (tool_exists "$cmd_a" || tool_exists "$cmd_b"); then
      log_ok "$label (AUR)"
      return 0
    fi
  fi

  fail_or_warn "$label"
}

install_toolchain() {
  echo ""
  echo "Installing FULL language support toolchain..."

  ensure_shell_path_blocks
  ensure_environmentd_path_file
  ensure_bash_alias_hx

  # Core runtime and editor dependencies.
  ensure_system_cmd helix "Install helix" helix
  ensure_hx_shim
  ensure_system_cmd tmux "Install tmux" tmux
  ensure_system_cmd rg "Install ripgrep" ripgrep
  ensure_system_cmd fd "Install fd" fd fd-find
  ensure_system_cmd python3 "Install Python runtime" python python3
  ensure_system_cmd npm "Install Node/npm runtime" npm nodejs-lts nodejs
  ensure_system_cmd go "Install Go runtime" go golang
  ensure_system_cmd cargo "Install Rust toolchain" cargo rust

  # npm-based toolchain.
  if have npm; then
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
    fail_or_warn "npm toolchain unavailable"
  fi

  # Python tools.
  if have python3; then
    if have ruff; then
      log_ok "ruff already installed"
    else
      log_step "Install pip: ruff"
      if python3 -m pip install --user --upgrade ruff && have ruff; then
        log_ok "Install pip: ruff"
      else
        fail_or_warn "Install pip: ruff"
      fi
    fi
  else
    fail_or_warn "Python tools unavailable"
  fi

  # Go tools.
  if have go; then
    ensure_go_cmd gopls golang.org/x/tools/gopls
    ensure_go_cmd golangci-lint-langserver github.com/nametake/golangci-lint-langserver
    ensure_go_cmd golangci-lint github.com/golangci/golangci-lint/cmd/golangci-lint
    ensure_go_cmd sqls github.com/sqls-server/sqls
    ensure_go_cmd terraform-ls github.com/hashicorp/terraform-ls
    ensure_go_cmd shfmt mvdan.cc/sh/v3/cmd/shfmt
  else
    fail_or_warn "Go tools unavailable"
  fi

  # Rust/Cargo tools.
  if have rustup; then
    log_step "Install rustup components: rust-analyzer + rustfmt"
    if rustup component add rust-analyzer rustfmt && have rust-analyzer; then
      log_ok "Install rustup components: rust-analyzer + rustfmt"
    else
      fail_or_warn "Install rustup components: rust-analyzer + rustfmt"
    fi
  else
    fail_or_warn "rustup unavailable"
  fi

  if have cargo; then
    ensure_cargo_cmd marksman marksman
    ensure_cargo_cmd markdown-oxide markdown-oxide
    ensure_cargo_cmd taplo taplo-cli --features lsp
    ensure_cargo_cmd stylua stylua
  else
    fail_or_warn "Cargo tools unavailable"
  fi

  # System LSP / runtimes for additional stacks.
  ensure_system_cmd clangd "Install clangd" clangd clang-tools
  ensure_system_cmd lua-language-server "Install lua-language-server" lua-language-server lua-language-server-bin
  ensure_system_cmd jdtls "Install jdtls" jdtls jdtls-bin eclipse-jdtls
  ensure_one_of_cmds "Install Nix LSP (nil or nixd)" nil nixd nixd nil nixd-bin nixd-git nil-language-server nil-git
  ensure_system_cmd php "Install php" php
  ensure_system_cmd java "Install Java runtime" java openjdk-21-jdk openjdk-17-jdk java-21-openjdk java-17-openjdk
  ensure_system_cmd dotnet "Install dotnet SDK" dotnet dotnet-sdk

  if have dotnet; then
    ensure_dotnet_tool csharp-ls csharp-ls
  else
    fail_or_warn "dotnet unavailable for csharp-ls"
  fi
}

verify_final_state() {
  local missing=()
  local cmd
  local required=(
    hx tmux rg python3 npm go cargo
    pyright-langserver typescript-language-server tsc
    vscode-html-language-server vscode-css-language-server vscode-json-language-server
    yaml-language-server ansible-language-server bash-language-server
    docker-langserver vue-language-server svelteserver graphql-lsp sql-language-server intelephense prettier
    ruff gopls golangci-lint-langserver golangci-lint sqls terraform-ls shfmt
    rust-analyzer marksman markdown-oxide taplo stylua
    clangd lua-language-server jdtls php java dotnet csharp-ls
  )

  for cmd in "${required[@]}"; do
    if ! tool_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if ! tool_exists nil && ! tool_exists nixd; then
    missing+=("nil|nixd")
  fi

  if [[ "${#missing[@]}" -eq 0 ]]; then
    log_ok "Final verification passed"
    return 0
  fi

  echo ""
  echo "Missing commands after installation:"
  for cmd in "${missing[@]}"; do
    echo "- $cmd"
  done

  add_failure "final verification"
  if [[ "$STRICT" -eq 1 ]]; then
    exit 1
  fi
}

verify_hx_health_for_configured_languages() {
  local out
  local line
  local lang
  local marker
  local bad=0
  local wanted_ok=(
    bash go html css scss json jsx tsx
    lua markdown python rust yaml
  )
  local wanted_none=(
    nix toml
  )

  if ! tool_exists hx; then
    fail_or_warn "hx binary missing for health verification"
    return
  fi

  out="$(hx --health 2>/dev/null | sed -E 's/\x1B\\[[0-9;]*[mK]//g')"

  for lang in "${wanted_ok[@]}"; do
    line="$(printf '%s\n' "$out" | awk -v l="$lang" '$1==l {print; exit}')"
    if [[ -z "$line" ]]; then
      echo "[warn] hx --health: missing row for language '$lang'"
      bad=1
      continue
    fi
    marker="$(printf '%s\n' "$line" | awk '{print $2}')"
    if [[ "$marker" != "✓" ]]; then
      echo "[warn] hx --health: language '$lang' LSP not ready (marker=$marker)"
      bad=1
    fi
  done

  for lang in "${wanted_none[@]}"; do
    line="$(printf '%s\n' "$out" | awk -v l="$lang" '$1==l {print; exit}')"
    if [[ -z "$line" ]]; then
      echo "[warn] hx --health: missing row for language '$lang'"
      bad=1
      continue
    fi
    marker="$(printf '%s\n' "$line" | awk '{print $2}')"
    if [[ "$marker" != "None" ]]; then
      echo "[warn] hx --health: language '$lang' expected no LSP, got marker=$marker"
      bad=1
    fi
  done

  if [[ "$bad" -eq 0 ]]; then
    log_ok "hx --health verification passed for configured languages"
    return 0
  fi

  add_failure "hx health verification"
  if [[ "$STRICT" -eq 1 ]]; then
    exit 1
  fi
}

mkdir -p "$HELIX_DIR"
link_item "$REPO_DIR/config.toml" "$HELIX_DIR/config.toml"
link_item "$REPO_DIR/languages.toml" "$HELIX_DIR/languages.toml"
link_item "$REPO_DIR/scripts" "$HELIX_DIR/scripts"

if [[ "$DOCTOR" -eq 1 ]]; then
  verify_final_state
  verify_hx_health_for_configured_languages
elif [[ "$LINK_ONLY" -eq 0 ]]; then
  install_toolchain
  verify_final_state
  verify_hx_health_for_configured_languages
fi

cat <<'EOF_MSG'

Install complete.
Next steps:
1) Restart shell (or source ~/.bashrc)
2) Start Helix: hx <project>
3) Run :config-reload
4) Run :lsp-restart
5) Check health: hx --health
EOF_MSG

if [[ "${#FAILURES[@]}" -gt 0 ]]; then
  echo ""
  echo "Some steps failed:"
  for item in "${FAILURES[@]}"; do
    echo "- $item"
  done
  if [[ "$STRICT" -eq 0 ]]; then
    echo "Re-run with --strict to stop on first failure."
  fi
fi

if [[ "${#FAILURES[@]}" -gt 0 ]]; then
  exit 1
fi
