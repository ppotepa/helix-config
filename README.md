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

### Normal mode
- Move: `w a s d`
- Word move: `q e z x`
- Save: `Ctrl+s`
- Enter insert: `Ctrl+r`, select: `Ctrl+e`
- Clipboard: `Ctrl+q` copy selection, `Ctrl+w` paste, `Ctrl+x` cut/delete
- File/buffer picker: `Ctrl+p`, `Ctrl+b`
- Search/diagnostics/hover: `Ctrl+f`, `Ctrl+d`, `Ctrl+k`
- Enter insert/select: `Ctrl+r`, `Ctrl+e`
- Runner: `F5` run, `F6` build, `F7` test

### Insert mode

- Leave insert: `jk` or `Ctrl+r`
- Save: `Ctrl+s`
- Completion: `Ctrl+space`, `Ctrl+n`

### Select mode

- Extend selection: `w a s d`
- Leave select: `Ctrl+e`
- Save: `Ctrl+s`

### Clipboard via leader

- `Space+q` copy selection to system clipboard
- `Space+w` delete selection
- `Space+e` paste clipboard after cursor

### Leader highlights

- LSP: `Space+a` code action, `Space+r` rename, `Space+z` definition, `Space+v` references, `Space+c` hover
- Reload: `Space+R+r` reload current file, `Space+R+a` reload all files, `Space+R+c` reload Helix config
- Runner: `Space+u` toggle, `Space+i` focus run pane, `Space+o` focus build pane
- Config: `Space+t` open config
- Select-mode clipboard: `Ctrl+c` copy, `Ctrl+x` cut/delete, `Ctrl+v` paste; undo is `Ctrl+z`

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
