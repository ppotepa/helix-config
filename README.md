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

## Shortcut table (WSAD profile v1)

This table is the current source of truth.  
We will update it iteratively as we tune your layout.

| Category | Mode | Keys | Action | Helix command |
|---|---|---|---|---|
| Movement | Normal | `w` | Move up | `move_line_up` |
| Movement | Normal | `a` | Move left | `move_char_left` |
| Movement | Normal | `s` | Move down | `move_line_down` |
| Movement | Normal | `d` | Move right | `move_char_right` |
| Movement | Normal | `q` | Previous word start | `move_prev_word_start` |
| Movement | Normal | `e` | Next word start | `move_next_word_start` |
| Movement | Normal | `z` | Previous word end | `move_prev_word_end` |
| Movement | Normal | `x` | Next word end | `move_next_word_end` |
| Selection | Select | `w/a/s/d` | Extend selection up/left/down/right | `extend_*` |
| Editing | Insert | `jk` | Exit insert mode | `normal_mode` |
| Save | Normal/Insert/Select | `Ctrl+s` | Save file | `:write` |
| Navigation | Normal | `Ctrl+p` | Open file picker | `file_picker` |
| Navigation | Normal | `Ctrl+b` | Open buffer picker | `buffer_picker` |
| Search | Normal | `Ctrl+f` | Global search in workspace | `global_search` |
| Diagnostics | Normal | `Ctrl+d` | Open diagnostics picker | `diagnostics_picker` |
| Docs | Normal | `Ctrl+k` | Hover docs | `hover` |
| Completion | Insert | `Ctrl+space` | Trigger completion | `completion` |
| Leader | Normal (`space`) | `space` + `f` | File picker | `file_picker` |
| Leader | Normal (`space`) | `space` + `b` | Buffer picker | `buffer_picker` |
| Leader | Normal (`space`) | `space` + `g` | Global search | `global_search` |
| Leader | Normal (`space`) | `space` + `d` | Diagnostics picker | `diagnostics_picker` |
| Leader | Normal (`space`) | `space` + `a` | Code action | `code_action` |
| Leader | Normal (`space`) | `space` + `r` | Rename symbol | `rename_symbol` |
| Leader | Normal (`space`) | `space` + `h` | Hover docs | `hover` |
| Config | Normal (`space`) | `space` + `c` | Open Helix config | `:config-open` |
| Config | Normal (`space`) | `space` + `R` | Reload Helix config | `:config-reload` |

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
