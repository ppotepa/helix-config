# helix-config

Simple Helix setup stored in Git.

## Files

- `config.toml` - editor settings and keybindings.
- `languages.toml` - language settings for common languages.

## Quick setup

```bash
mkdir -p ~/.config/helix
ln -sfn /home/ppotepa/git/helix-config/config.toml ~/.config/helix/config.toml
ln -sfn /home/ppotepa/git/helix-config/languages.toml ~/.config/helix/languages.toml
```

Then in Helix:

- `:config-reload` - reload config.
- `:config-open` - open your Helix config.
- `:lsp-restart` - restart language servers.

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

### Leader

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal (`space`) | `space` + `f` | File picker | `file_picker` |
| Normal (`space`) | `space` + `b` | Buffer picker | `buffer_picker` |
| Normal (`space`) | `space` + `g` | Global search | `global_search` |
| Normal (`space`) | `space` + `d` | Diagnostics picker | `diagnostics_picker` |
| Normal (`space`) | `space` + `a` | Code action | `code_action` |
| Normal (`space`) | `space` + `r` | Rename symbol | `rename_symbol` |
| Normal (`space`) | `space` + `h` | Hover docs | `hover` |

### Config

| Mode | Keys | Action | Helix command |
|---|---|---|---|
| Normal (`space`) | `space` + `c` | Open Helix config | `:config-open` |
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
