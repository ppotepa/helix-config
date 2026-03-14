# helix-config

Helix config with WSAD navigation, tmux runner, and one-script setup/doctor.

## Files

- `config.toml` - editor settings and keymaps.
- `languages.toml` - language server config.
- `scripts/` - tmux runner and language run/build/test mapping.
- `install.sh` - install + self-heal + doctor checks.
- `update.sh` - refresh Helix config links only.

## Install

```bash
./install.sh --strict
```

## Update config only

```bash
./update.sh
```

This refreshes the linked Helix config without reinstalling tooling.

If Helix still has only syntax highlighting and no LSP/completion, run a forced repair:

```bash
./install.sh --reinstall --strict
```

On Arch/CachyOS, repair mode reuses already-installed `pacman` packages and forces refresh mainly for managed LSP/tooling, so broken mirrors on unrelated packages do not block recovery.

Other modes:

```bash
./install.sh --link-only
./install.sh --doctor
./install.sh --reinstall --strict
```

## Expanded language coverage

This setup aims to be a broad Helix bootstrap for popular languages, not just a minimal personal config.

First-class tooling is wired for:

- C, C++, C#, Go, Rust, Java, PHP, Python, Ruby, Haskell, Dart, Zig
- JavaScript, TypeScript, JSX, TSX, Vue, Svelte
- HTML, CSS, SCSS, JSON, YAML, TOML, GraphQL, SQL, Markdown
- Bash, Lua, Dockerfile, Terraform, Typst

Nix support remains optional via `./install.sh --with-nix`.

## Current keymap

### Navigation

- Cursor move: `w a s d`
- Word move: `q e z x`
- Next/previous buffer: `Tab` / `Shift+Tab`

### Modes

- Enter insert mode: `Ctrl+r`
- Enter select mode: `Ctrl+e`
- Leave insert mode: `jk` or `Ctrl+r`
- Leave select mode: `Ctrl+e`

### Line and selection editing

- Copy current line (normal): `h`
- Duplicate below: `j` (normal/select), `Alt+j` (insert)
- Duplicate above: `J` (normal/select), `Alt+J` (insert)
- Delete current line/selection: `k` (normal), `Ctrl+x` (normal/select)
- Toggle comment on current line (normal): `l`

### Save, undo, and completion

- Save: `Ctrl+s` (normal/insert/select)
- Undo: `Ctrl+z` (normal/select)
- Completion: `Ctrl+space` or `Ctrl+n` (insert)

### Clipboard

- System clipboard copy/paste/cut (normal/select): `Ctrl+c`, `Ctrl+v`, `Ctrl+x`
- Leader clipboard: `Space+q` copy, `Space+w` delete, `Space+e` paste

### Files, search, and diagnostics

- File picker: `Ctrl+p`
- Buffer picker: `Ctrl+b`
- Global search: `Ctrl+f`
- Diagnostics picker: `Ctrl+d`
- Hover (normal): `Ctrl+k`

### LSP and code intelligence (leader)

- Code action: `Space+a`
- Rename symbol: `Space+r`
- Definition/references/hover: `Space+z`, `Space+v`, `Space+c`

### Reload and config

- Reload current file: `Space+R+r`
- Reload all files: `Space+R+a`
- Reload Helix config: `Space+R+c`
- Open config: `Space+t`

### Runner integration

- Run/build/test current file: `F5` / `F6` / `F7`
- Toggle/focus runner panes: `Space+u`, `Space+i`, `Space+o`

## Runner behavior

- F5/F6/F7 call `scripts/hx-tmux-runner.sh`.
- Window naming:
  - run mode -> `run <project>`
  - build/test mode -> `debug <project>`
- Existing same-name window is reused (no numeric windows).
- Layout is fixed: left `RUN`, right `BUILD`.

## What install.sh manages

- Symlinks under `~/.config/helix`.
- PATH in `~/.profile`, `~/.bashrc`, and `~/.config/environment.d/helix-config-path.conf`.
- `hx` alias/shim and tmux PATH sync.
- `stty -ixon` fix for `Ctrl+s`.
- Language tooling (npm/go/cargo/rustup/system where available).
- C# support via `csharp-ls` (`dotnet-sdk` + dotnet tool install).
- Additional first-class tooling for Ruby, Haskell, Dart, Zig, Typst, TOML, SQL, and Markdown.
- Health checks (`--doctor`) using the managed Helix PATH, so misplaced global LSP installs are caught and repaired.
