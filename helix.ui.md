# Helix UI/UX Profile

This document is the full, coherent description of the current Helix profile.
It is aligned with:

- `config.toml` (source of truth for behavior)
- `README.md` (user-facing shortcut tables)
- `tests/README.md` (language workspace usage)

## 1. Design principles

1. One-hand editing first (left side of keyboard).
2. tmux-safe key strategy (avoid heavy Alt usage collisions).
3. Fast language workflow: edit -> complete -> run/build/test.
4. Per-language workspaces for stable LSP behavior.

## 2. Interaction model

## 2.1 Modes

- `Normal`: navigation and commands
- `Insert`: typing text
- `Select`: selection/extend mode

Mode switches:

- `i` -> Insert
- `v` -> Select
- `Esc` -> Normal
- `jk` in Insert -> Normal

## 2.2 Core movement (WSAD profile)

Normal mode:

- `w` up
- `a` left
- `s` down
- `d` right
- `q` previous word start
- `e` next word start
- `z` previous word end
- `x` next word end

Select mode:

- `w/a/s/d` extends selection in matching direction

## 2.3 Save, search, docs, completion

- `Ctrl+s` save (Normal/Insert/Select)
- `Ctrl+f` global search
- `Ctrl+d` diagnostics picker
- `Ctrl+k` hover docs
- `Ctrl+space` completion (Insert)

Completion policy:

- auto-completion enabled
- trigger length set to `1`
- manual trigger always available via `Ctrl+space`

## 2.4 Buffer and file navigation

- `Ctrl+p` file picker
- `Ctrl+b` buffer picker
- `Tab` next buffer (primary)
- `Shift+Tab` previous buffer (primary)

Left-hand leader layer (`Space + ...`):

- `space + a` previous buffer
- `space + d` next buffer
- `space + s` buffer picker
- `space + w` file picker
- `space + f` global search
- `space + e` diagnostics picker
- `space + q` close current split
- `space + r` rename symbol
- `space + x` code action
- `space + c` hover docs
- `space + z` go to definition
- `space + v` go to references
- `space + t` open config
- `space + R` reload config

## 2.5 Run/build/test UX

Mapped keys:

- `F5` run current file/project
- `F6` build/check current file/project
- `F7` test current file/project

Implementation:

- primary entrypoint is `scripts/hx-tmux-runner.sh`
- tmux runner creates/reuses a dedicated window per Helix pane (`RUN` + `BUILD`)
- tmux runner routes commands to dedicated panes:
  - `run` -> `RUN`
  - `build`/`test` -> `BUILD`
- language command execution is delegated to `scripts/hx-lang-runner.sh`
- language runner dispatches by current file extension and nearest project marker

Fallback keys on leader layer:

- `space + u` toggle tmux runner window
- `space + i` focus tmux RUN pane
- `space + o` focus tmux BUILD pane

## 3. Language runner policy

## 3.1 Supported by F5/F6/F7

- Rust
- Go
- Python
- JavaScript
- TypeScript
- C
- C++
- Java
- C#
- PHP
- Shell
- Lua

## 3.2 Intentionally not supported by runner

- SQL
- JSON/YAML/TOML
- Dockerfile
- Terraform
- GraphQL
- Markdown and other data/config documents

Reason: these are not consistent application entrypoint targets in the same way code files are.

## 4. Workspace structure

Use separate language workspaces under `tests/`:

- `tests/rust`
- `tests/go`
- `tests/python`
- `tests/sql`
- `tests/csharp`
- `tests/php`
- `tests/dockerfile`
- `tests/terraform`
- `tests/graphql`
- `tests/vue`
- `tests/svelte`
- and others

Rule:

- open one language workspace at a time when validating LSP behavior
- this avoids mixed-root workspace failures

## 5. tmux integration model

Current profile assumes tmux-heavy usage and is designed to coexist with the custom tmux profile in:

- `/home/ppotepa/git/tmux-profile`

## 5.1 tmux baseline assumptions

From the tmux profile:

- Prefix is `Ctrl+a`
- No-prefix Alt navigation is active:
  - `M-a`, `M-s`, `M-w`, `M-d` (pane navigation)
  - `M-1..M-6` (window selection)
- Pane management and session management are left-hand optimized around the `C-a` layer.

## 5.2 Collision policy (Helix vs tmux)

To avoid conflicts:

1. Helix uses mostly:
  - `Ctrl+...`
  - `Space + ...` leader
2. Helix avoids introducing new default `Alt` mappings.
3. Buffer navigation is on `Tab` / `Shift+Tab` (with `space+a` / `space+d` fallback) instead of `Alt+...`.
4. Function keys are used for run/build/test (`F5/F6/F7`) and do not overlap with no-prefix Alt binds.

## 5.3 Current tmux + Helix behavior

Today, run/build/test is tmux-routed through `hx-tmux-runner.sh`.

Behavior:

1. Script identifies the active Helix tmux pane (`$TMUX_PANE`).
2. Script creates or reuses dedicated runner window for that pane.
3. Runner window contains two panes:
  - left pane titled `RUN`
  - right pane titled `BUILD`
4. `F5` sends run command to `RUN`.
5. `F6` and `F7` send build/test commands to `BUILD`.

Resilience:

- if runner window/panes are closed manually, next action recreates them automatically.
- each Helix pane gets isolated runner targets.

## 5.4 Key forwarding notes (terminal + tmux)

Not every terminal forwards all combinations reliably.

Known risk keys:

- `Ctrl+Tab`
- `Ctrl+Shift+Tab`
- some shifted function key combinations (`Ctrl+Shift+F5` etc.)

Operational rule:

- prefer `Space` leader and plain `F5/F6/F7` for stable behavior
- only add shifted function combos after terminal verification

## 5.5 tmux runner controls

Current controls:

1. `space + u` toggle runner window
2. `space + i` focus RUN pane
3. `space + o` focus BUILD pane

Note:

- this profile intentionally uses `space + u/i/o` as primary control to avoid terminal/parser inconsistencies with shifted function combinations.

## 6. Step-by-step daily workflow

1. Open project/workspace: `hx <path>`
2. Edit with WSAD normal movement.
3. Use `Ctrl+space` for completion when needed.
4. Use `space + z` / `space + v` for code navigation.
5. Use `F5/F6/F7` for run/build/test.
6. Move across open buffers with `Tab` / `Shift+Tab` (or fallback `space + a` / `space + d`).
7. Save with `Ctrl+s`, reload config with `space + R` when keymaps change.

## 7. Consistency checklist

After any keymap or UX change:

1. Verify `config.toml` is valid TOML.
2. Ensure `README.md` shortcut tables match key bindings exactly.
3. Ensure this file (`helix.ui.md`) reflects current behavior, not planned behavior.
4. Validate at least one supported runner language (for example Rust or Go) with F5/F6.
5. Validate one intentionally unsupported language to confirm clear failure message.

## 8. tmux quick reference for this profile

Useful tmux keys in context of this Helix setup:

1. `C-a r` reload tmux config
2. `C-a c` create window
3. `C-a q` and `C-a e` split panes
4. `C-a a/s/w/d` pane navigation with prefix
5. `M-a/s/w/d` pane navigation without prefix
6. `C-a Tab` jump to last window

This allows a fast layout workflow:

1. Create/arrange panes with tmux
2. Open Helix in the main pane
3. Use Helix keymaps for coding
4. Use tmux pane/window controls for environment management
