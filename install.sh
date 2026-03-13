#!/usr/bin/env bash
set -Eeuo pipefail

STRICT=0
DOCTOR=0
LINK_ONLY=0
WITH_NIX=0
REINSTALL=0
FAILURES=()

for arg in "$@"; do
  case "$arg" in
    --strict)   STRICT=1 ;;
    --doctor)   DOCTOR=1 ;;
    --link-only)LINK_ONLY=1 ;;
    --with-nix) WITH_NIX=1 ;;
    --reinstall) REINSTALL=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--strict] [--doctor] [--link-only] [--with-nix] [--reinstall]

  --strict    stop on first failed step
  --doctor    only run health checks
  --link-only only link Helix config files
  --with-nix  also try to install Nix LSP support (nixd / nil)
  --reinstall force reinstall of managed Helix tooling/LSPs
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

(( EUID == 0 )) && {
  echo "[error] Run this as your normal user, not with sudo/root." >&2
  exit 1
}

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
HELIX_DIR="$XDG_CONFIG_HOME/helix"
LOCAL_BIN="$HOME/.local/bin"
NPM_PREFIX="$HOME/.local/npm"
ENV_DIR="$XDG_CONFIG_HOME/environment.d"
ENV_FILE="$ENV_DIR/helix-config-path.conf"
MANAGED_PATH="$LOCAL_BIN:$NPM_PREFIX/bin:$HOME/.cargo/bin:$HOME/go/bin:/usr/local/bin:/usr/bin:/bin"

say()  { printf '%s\n' "$*"; }
ok()   { say "[ok] $*"; }
need() { command -v "$1" >/dev/null 2>&1; }

managed_need() {
  PATH="$MANAGED_PATH" command -v "$1" >/dev/null 2>&1
}

cmd_path() {
  command -v "$1" 2>/dev/null || true
}

fail() {
  say "[warn] $*" >&2
  FAILURES+=("$*")
  (( STRICT == 1 )) && exit 1
}

run() {
  local label="$1"; shift
  say ""
  say "==> $label"
  if "$@"; then
    ok "$label"
  else
    fail "$label"
  fi
}

ensure_line() {
  local file="$1" line="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

ensure_block() {
  local file="$1" begin="$2" end="$3" body="$4"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fq "$begin" "$file" && return 0
  {
    printf '\n%s\n' "$begin"
    printf '%s\n' "$body"
    printf '%s\n' "$end"
  } >> "$file"
}

link_item() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  ok "Linked $dst -> $src"
}

sudo_do()   { sudo "$@"; }
pacman_pkg(){
  if (( REINSTALL == 1 )); then
    sudo_do pacman -S --noconfirm "$@"
  else
    sudo_do pacman -S --needed --noconfirm "$@"
  fi
}
paru_pkg()  {
  if (( REINSTALL == 1 )); then
    need paru && paru -S --noconfirm --skipreview --answerclean None --answerdiff None "$@"
  else
    need paru && paru -S --needed --noconfirm --skipreview --answerclean None --answerdiff None "$@"
  fi
}
npm_pkg()   {
  if (( REINSTALL == 1 )); then
    NPM_CONFIG_PREFIX="$NPM_PREFIX" npm install -g --force "$@"
  else
    NPM_CONFIG_PREFIX="$NPM_PREFIX" npm install -g "$@"
  fi
}
pipx_pkg()  {
  need pipx || pacman_pkg python-pipx
  PIPX_BIN_DIR="$LOCAL_BIN" pipx install --force "$1" || PIPX_BIN_DIR="$LOCAL_BIN" pipx upgrade "$1"
}
dotnet_tool_pkg() {
  mkdir -p "$LOCAL_BIN"
  dotnet tool update --tool-path "$LOCAL_BIN" "$1" || dotnet tool install --tool-path "$LOCAL_BIN" "$1"
}
cargo_pkg() {
  if (( REINSTALL == 1 )); then
    cargo install --locked --force "$@"
  else
    cargo install --locked "$@"
  fi
}
go_pkg()    { GOBIN="$LOCAL_BIN" go install "$1"; }

ensure_cmd() {
  local cmd="$1" label="$2"; shift 2
  local installer="${1:-}"
  if (( REINSTALL == 1 )); then
    if [[ "$installer" == "pacman_pkg" ]] && need "$cmd"; then
      say "[info] $cmd already installed; skipping pacman reinstall in repair mode"
      return 0
    fi
    run "$label" "$@"
    need "$cmd" || fail "$cmd unavailable after reinstall"
    return 0
  fi
  need "$cmd" && { ok "$cmd already installed"; return 0; }
  run "$label" "$@"
}

ensure_managed_cmd() {
  local cmd="$1" label="$2"; shift 2
  local found=""

  if (( REINSTALL == 1 )); then
    found="$(cmd_path "$cmd")"
    [[ -n "$found" ]] && say "[info] Reinstalling $cmd from $found into managed PATH"
    run "$label" "$@"
    managed_need "$cmd" || fail "$cmd still unavailable in managed PATH"
    return 0
  fi

  managed_need "$cmd" && { ok "$cmd already available in managed PATH"; return 0; }

  found="$(cmd_path "$cmd")"
  if [[ -n "$found" ]]; then
    say "[info] $cmd found outside managed PATH at $found; reinstalling into managed PATH"
  fi

  run "$label" "$@"
  managed_need "$cmd" || fail "$cmd still unavailable in managed PATH"
}

ensure_all_or_install() {
  local label="$1" installer="$2"; shift 2
  local pkg="${@: -1}"
  local cmds=("${@:1:$#-1}")
  local missing=0
  local c

  if (( REINSTALL == 1 )); then
    run "$label" "$installer" "$pkg"
    for c in "${cmds[@]}"; do
      need "$c" || fail "$c unavailable after reinstall"
    done
    return 0
  fi
  for c in "${cmds[@]}"; do
    need "$c" || missing=1
  done
  (( missing == 0 )) && { ok "$label already installed"; return 0; }
  run "$label" "$installer" "$pkg"
}

ensure_all_or_install_managed() {
  local label="$1" installer="$2"; shift 2
  local pkg="${@: -1}"
  local cmds=("${@:1:$#-1}")
  local missing=0
  local cmd

  if (( REINSTALL == 1 )); then
    for cmd in "${cmds[@]}"; do
      local found=""
      found="$(cmd_path "$cmd")"
      [[ -n "$found" ]] && say "[info] Reinstalling $cmd from $found into managed PATH"
    done

    run "$label" "$installer" "$pkg"

    for cmd in "${cmds[@]}"; do
      managed_need "$cmd" || fail "$cmd still unavailable in managed PATH"
    done
    return 0
  fi

  for cmd in "${cmds[@]}"; do
    managed_need "$cmd" || missing=1
  done
  (( missing == 0 )) && { ok "$label already installed in managed PATH"; return 0; }

  for cmd in "${cmds[@]}"; do
    local found=""
    found="$(cmd_path "$cmd")"
    if [[ -n "$found" ]] && ! managed_need "$cmd"; then
      say "[info] $cmd found outside managed PATH at $found; reinstalling into managed PATH"
    fi
  done

  run "$label" "$installer" "$pkg"

  for cmd in "${cmds[@]}"; do
    managed_need "$cmd" || fail "$cmd still unavailable in managed PATH"
  done
}

setup_paths() {
  mkdir -p "$LOCAL_BIN" "$NPM_PREFIX" "$ENV_DIR"

  local path_body="export PATH=\"$LOCAL_BIN:$NPM_PREFIX/bin:$HOME/.cargo/bin:$HOME/go/bin:\$PATH\""
  ensure_block "$HOME/.profile" "# >>> helix-config path >>>" "# <<< helix-config path <<<" "$path_body"
  ensure_block "$HOME/.bashrc"  "# >>> helix-config path >>>" "# <<< helix-config path <<<" "$path_body"
  ensure_line  "$HOME/.bashrc"  "stty -ixon 2>/dev/null || true"

  cat > "$ENV_FILE" <<EOF
PATH=$MANAGED_PATH
EOF
  ok "PATH configured"
}

maybe_set_helix_runtime() {
  local d=""
  for cand in /usr/lib/helix/runtime /usr/share/helix/runtime; do
    [[ -d "$cand" ]] && d="$cand" && break
  done
  [[ -z "$d" ]] && return 0
  ensure_line "$HOME/.profile" "export HELIX_RUNTIME=\"$d\""
  ensure_line "$HOME/.bashrc"  "export HELIX_RUNTIME=\"$d\""
  ok "HELIX_RUNTIME set to $d"
}

maybe_make_hx_shim() {
  if need hx; then
    ok "hx command already available"
    return 0
  fi
  if need helix; then
    mkdir -p "$LOCAL_BIN"
    cat > "$LOCAL_BIN/hx" <<'EOF'
#!/usr/bin/env bash
exec helix "$@"
EOF
    chmod +x "$LOCAL_BIN/hx"
    ok "Created hx shim at $LOCAL_BIN/hx"
  else
    fail "hx/helix not available"
  fi
}

sync_tmux_path() {
  need tmux || return 0
  tmux start-server >/dev/null 2>&1 || true
  tmux set-environment -g PATH "$LOCAL_BIN:$NPM_PREFIX/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH" >/dev/null 2>&1 || true
  ok "tmux PATH synced"
}

install_core() {
  (( REINSTALL == 1 )) && say "[info] Reinstall mode enabled: forcing reinstall of managed tooling"
  ensure_cmd helix   "Install pacman: helix"    pacman_pkg helix
  ensure_cmd tmux    "Install pacman: tmux"     pacman_pkg tmux
  ensure_cmd rg      "Install pacman: ripgrep"  pacman_pkg ripgrep
  ensure_cmd fd      "Install pacman: fd"       pacman_pkg fd
  ensure_cmd python3 "Install pacman: python"   pacman_pkg python
  ensure_cmd npm     "Install pacman: npm"      pacman_pkg npm
  ensure_cmd go      "Install pacman: go"       pacman_pkg go
  ensure_cmd cargo   "Install pacman: cargo"    pacman_pkg cargo
  ensure_cmd rustup  "Install pacman: rustup"   pacman_pkg rustup
  ensure_cmd pipx    "Install pacman: pipx"     pacman_pkg python-pipx
  ensure_cmd dotnet  "Install pacman: dotnet-sdk" pacman_pkg dotnet-sdk

  NPM_CONFIG_PREFIX="$NPM_PREFIX" npm config set prefix "$NPM_PREFIX" >/dev/null 2>&1 || true
  maybe_make_hx_shim
  maybe_set_helix_runtime
  sync_tmux_path
}

install_lang_servers() {
   ensure_managed_cmd pyright-langserver         "Install npm: pyright"                         npm_pkg pyright
   ensure_managed_cmd typescript-language-server "Install npm: typescript-language-server"      npm_pkg typescript-language-server
   ensure_managed_cmd tsc                        "Install npm: typescript"                      npm_pkg typescript
   ensure_all_or_install_managed "Install npm: vscode-langservers-extracted" npm_pkg \
     vscode-html-language-server vscode-css-language-server vscode-json-language-server vscode-langservers-extracted
   ensure_managed_cmd yaml-language-server       "Install npm: yaml-language-server"            npm_pkg yaml-language-server
   ensure_managed_cmd ansible-language-server    "Install npm: @ansible/ansible-language-server" npm_pkg @ansible/ansible-language-server
   ensure_managed_cmd bash-language-server       "Install npm: bash-language-server"            npm_pkg bash-language-server
   ensure_managed_cmd docker-langserver          "Install npm: dockerfile-language-server-nodejs" npm_pkg dockerfile-language-server-nodejs
   ensure_managed_cmd vue-language-server        "Install npm: @vue/language-server"            npm_pkg @vue/language-server
   ensure_managed_cmd svelteserver               "Install npm: svelte-language-server"          npm_pkg svelte-language-server
   ensure_managed_cmd graphql-lsp                "Install npm: graphql-language-service-cli"    npm_pkg graphql-language-service-cli
   ensure_managed_cmd sql-language-server        "Install npm: sql-language-server"             npm_pkg sql-language-server
   ensure_managed_cmd intelephense               "Install npm: intelephense"                    npm_pkg intelephense
   ensure_managed_cmd prettier                   "Install npm: prettier"                        npm_pkg prettier

  ensure_cmd ruff                       "Install pipx: ruff"                           pipx_pkg ruff
  ensure_managed_cmd csharp-ls          "Install dotnet tool: csharp-ls"               dotnet_tool_pkg csharp-ls
  ensure_cmd clangd                     "Install pacman: clang"                        pacman_pkg clang
  ensure_cmd lua-language-server        "Install pacman: lua-language-server"          pacman_pkg lua-language-server
  ensure_cmd jdtls                      "Install pacman: jdtls"                        pacman_pkg jdtls
  ensure_cmd shfmt                      "Install pacman: shfmt"                        pacman_pkg shfmt
  ensure_cmd terraform-ls               "Install pacman: terraform-ls"                 pacman_pkg terraform-ls
  ensure_cmd golangci-lint              "Install pacman: golangci-lint"                pacman_pkg golangci-lint
  ensure_cmd haskell-language-server-wrapper "Install pacman: haskell-language-server" pacman_pkg haskell-language-server
  ensure_cmd ruby-lsp                   "Install pacman: ruby-lsp"                     pacman_pkg ruby-lsp
  ensure_cmd tinymist                   "Install pacman: tinymist"                     pacman_pkg tinymist
  ensure_cmd zls                        "Install pacman: zls"                          pacman_pkg zls
  ensure_cmd dart                       "Install pacman: dart"                         pacman_pkg dart
  ensure_cmd taplo                      "Install pacman: taplo-cli"                    pacman_pkg taplo-cli
  ensure_cmd markdown-oxide             "Install pacman: markdown-oxide"               pacman_pkg markdown-oxide
  ensure_cmd marksman                   "Install pacman: marksman"                     pacman_pkg marksman

  if need rustup; then
    run "Install rustup components: rust-analyzer + rustfmt" rustup component add rust-analyzer rustfmt
  else
    fail "rustup missing; cannot install rust-analyzer/rustfmt"
  fi

  ensure_cmd gopls                      "Install go: gopls"                            go_pkg golang.org/x/tools/gopls@latest
  ensure_cmd golangci-lint-langserver   "Install go: golangci-lint-langserver"         go_pkg github.com/nametake/golangci-lint-langserver@latest
  ensure_cmd sqls                       "Install go: sqls"                             go_pkg github.com/sqls-server/sqls@latest

  ensure_cmd stylua                     "Install cargo: stylua"                        cargo_pkg stylua
}

install_nix_support() {
  (( WITH_NIX == 0 )) && { ok "Skipping Nix LSP support"; return 0; }

  if need nixd; then
    ok "nixd already installed"
    return 0
  fi

  if need paru; then
    run "Install AUR: nixd" paru_pkg nixd
    need nixd && return 0
  fi

  if need nix; then
    run "Install nil via Nix" nix profile install github:oxalica/nil
    need nil && return 0
  fi

  fail "Nix LSP support unavailable (nix repo/mirror issue or nix missing)"
}

verify_links() {
  [[ -e "$HELIX_DIR/config.toml"    ]] || fail "Missing $HELIX_DIR/config.toml"
  [[ -e "$HELIX_DIR/languages.toml" ]] || fail "Missing $HELIX_DIR/languages.toml"
  [[ -e "$HELIX_DIR/scripts"        ]] || fail "Missing $HELIX_DIR/scripts"
}

doctor() {
  say ""
  say "==> Helix health"
  say "[info] Running hx --health with managed PATH"
  env PATH="$MANAGED_PATH" hx --health || true
}

mkdir -p "$HELIX_DIR"
link_item "$REPO_DIR/config.toml"    "$HELIX_DIR/config.toml"
link_item "$REPO_DIR/languages.toml" "$HELIX_DIR/languages.toml"
[[ -d "$REPO_DIR/scripts" ]] && link_item "$REPO_DIR/scripts" "$HELIX_DIR/scripts"

verify_links

if (( DOCTOR == 1 )); then
  doctor
elif (( LINK_ONLY == 0 )); then
  setup_paths
  install_core
  install_lang_servers
  install_nix_support
  doctor
fi

say ""
say "Install complete."
say "Open a new shell, then run:"
say "  hx --health"
say "  hx <project>"
(( REINSTALL == 1 )) && say "Reinstall mode was used; existing managed LSP/tooling was refreshed."

if (( ${#FAILURES[@]} > 0 )); then
  say ""
  say "Failed steps:"
  for f in "${FAILURES[@]}"; do
    say "  - $f"
  done
  exit 1
fi
