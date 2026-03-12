# helix-config

Simple Helix setup stored in Git.

## Files

- `config.toml` - editor settings and keybindings.
- `languages.toml` - language settings for common languages.
- `scripts/` - tmux runner + language runner scripts used by `F5/F6/F7`.
- `install.sh` - one-command local install (creates symlinks in `~/.config/helix`).
- `helix.ui.md` - UX architecture and step-by-step workflow design.

## Quick install

```bash
./install.sh
```

Then in Helix:

- `:config-reload` - reload config.
- `:config-open` - open your Helix config.
- `:lsp-restart` - restart language servers.

Manual install (if needed):

```bash
mkdir -p ~/.config/helix
ln -sfn "$PWD/config.toml" ~/.config/helix/config.toml
ln -sfn "$PWD/languages.toml" ~/.config/helix/languages.toml
ln -sfn "$PWD/scripts" ~/.config/helix/scripts
```

## Main features (grouped)

```text
+-------------------+--------------------------------------------+---------------------------+
| Group             | What you get                               | Main keys                 |
+-------------------+--------------------------------------------+---------------------------+
| WSAD movement     | Gamer-style normal/select movement         | w a s d, q e z x          |
| Fast file access  | File + buffer pickers                      | Ctrl+p, Ctrl+b            |
| Buffer switching  | Quick next/prev buffers                    | Tab, Shift+Tab            |
| Code help         | Completion, hover, diagnostics             | Ctrl+space, Ctrl+k, Ctrl+d|
| LSP navigation    | Definition/references/rename/actions       | Space+z/v/r/x             |
| Runner (tmux)     | Dedicated RUN + BUILD panes per Helix pane | F5, F6, F7, Space+u/i/o   |
| Config ops        | Open/reload config quickly                 | Space+t, Space+R          |
+-------------------+--------------------------------------------+---------------------------+
```

## Shortcut tables (WSAD profile v1)

These tables are the current source of truth.  
We will update them iteratively.

### Movement

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `w` | Move up | `move_line_up` |
| Normal | `a` | Move left | `move_char_left` |
| Normal | `s` | Move down | `move_line_down` |
| Normal | `d` | Move right | `move_char_right` |
| Normal | `q` | Previous word start | `move_prev_word_start` |
| Normal | `e` | Next word start | `move_next_word_start` |
| Normal | `z` | Previous word end | `move_prev_word_end` |
| Normal | `x` | Next word end | `move_next_word_end` |

### Selection

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Select | `w` | Extend up | `extend_line_up` |
| Select | `a` | Extend left | `extend_char_left` |
| Select | `s` | Extend down | `extend_line_down` |
| Select | `d` | Extend right | `extend_char_right` |

### Editing

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Insert | `jk` | Exit insert mode | `normal_mode` |

### Save

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `Ctrl+s` | Save file | `:write` |
| Insert | `Ctrl+s` | Save file | `:write` |
| Select | `Ctrl+s` | Save file | `:write` |

### Navigation

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `Ctrl+p` | Open file picker | `file_picker` |
| Normal | `Ctrl+b` | Open buffer picker | `buffer_picker` |
| Normal | `Tab` | Next buffer | `goto_next_buffer` |
| Normal | `Shift+Tab` | Previous buffer | `goto_previous_buffer` |

### Search

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `Ctrl+f` | Global search in workspace | `global_search` |

### Diagnostics

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `Ctrl+d` | Open diagnostics picker | `diagnostics_picker` |

### Docs

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `Ctrl+k` | Hover docs | `hover` |

### Completion

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Insert | `Ctrl+space` | Trigger completion | `completion` |

### Run/Build/Test

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal | `F5` | Run in tmux RUN target | `:run-shell-command ... hx-tmux-runner.sh run %{buffer_name}` |
| Normal | `F6` | Build in tmux BUILD target | `:run-shell-command ... hx-tmux-runner.sh build %{buffer_name}` |
| Normal | `F7` | Test in tmux BUILD target | `:run-shell-command ... hx-tmux-runner.sh test %{buffer_name}` |

### Leader

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal (`space`) | `space` + `a` | Previous buffer | `goto_previous_buffer` |
| Normal (`space`) | `space` + `d` | Next buffer | `goto_next_buffer` |
| Normal (`space`) | `space` + `s` | Buffer picker | `buffer_picker` |
| Normal (`space`) | `space` + `w` | File picker | `file_picker` |
| Normal (`space`) | `space` + `f` | Global search | `global_search` |
| Normal (`space`) | `space` + `e` | Diagnostics picker | `diagnostics_picker` |
| Normal (`space`) | `space` + `q` | Close current split | `wclose` |
| Normal (`space`) | `space` + `r` | Rename symbol | `rename_symbol` |
| Normal (`space`) | `space` + `x` | Code action | `code_action` |
| Normal (`space`) | `space` + `c` | Hover docs | `hover` |
| Normal (`space`) | `space` + `z` | Go to definition | `goto_definition` |
| Normal (`space`) | `space` + `v` | Go to references | `goto_reference` |
| Normal (`space`) | `space` + `u` | Toggle tmux runner window | `:run-shell-command ... hx-tmux-runner.sh toggle %{buffer_name}` |
| Normal (`space`) | `space` + `i` | Focus tmux RUN pane | `:run-shell-command ... hx-tmux-runner.sh focus-run %{buffer_name}` |
| Normal (`space`) | `space` + `o` | Focus tmux BUILD pane | `:run-shell-command ... hx-tmux-runner.sh focus-build %{buffer_name}` |

### Config

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal (`space`) | `space` + `t` | Open Helix config | `:config-open` |
| Normal (`space`) | `space` + `R` | Reload Helix config | `:config-reload` |

## Included languages

Basic settings are included for:

- Rust, Go, Python
- JavaScript, TypeScript, JSX, TSX
- JSON, YAML, TOML
- Bash, Lua, Nix
- HTML, CSS, SCSS, Markdown

## Next steps

1. Run `hx --health` to see missing LSP servers and formatters.
2. Install tools only for languages you use.
3. Adjust keybindings in `config.toml` to your keyboard habits.

## Runner support

`F5/F6/F7` support is configured for:
- Rust, Go, Python
- JavaScript, TypeScript
- C, C++, Java, C#
- PHP, Shell, Lua

Intentionally unsupported by runner:
- SQL and data/config languages (JSON, YAML, TOML, etc.)

tmux runner controls:
- primary: `space + u/i/o`
