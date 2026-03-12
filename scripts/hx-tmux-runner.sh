#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
file="${2:-}"

if [[ -z "$mode" ]]; then
  echo "Usage: hx-tmux-runner.sh <run|build|test|toggle|focus-run|focus-build> [file]"
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LANG_RUNNER="$SCRIPT_DIR/hx-lang-runner.sh"

if [[ -n "$file" && "$file" != /* ]]; then
  file="$PWD/$file"
fi

if [[ -z "${TMUX:-}" ]]; then
  if [[ "$mode" == "run" || "$mode" == "build" || "$mode" == "test" ]]; then
    exec "$LANG_RUNNER" "$mode" "$file"
  fi
  echo "Not running inside tmux; mode '$mode' is unavailable"
  exit 1
fi

src_pane="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}') }"
src_window_id="$(tmux display-message -p -t "$src_pane" '#{window_id}')"
win_name="hxrun-${src_pane#%}"

pane_exists() {
  local pane_id="$1"
  tmux list-panes -a -F '#{pane_id}' | grep -Fxq "$pane_id"
}

window_exists() {
  local window_id="$1"
  tmux list-windows -a -F '#{window_id}' | grep -Fxq "$window_id"
}

get_pane_opt() {
  local key="$1"
  tmux show-options -p -v -t "$src_pane" "$key" 2>/dev/null || true
}

set_pane_opt() {
  local key="$1"
  local val="$2"
  tmux set-option -p -t "$src_pane" "$key" "$val" >/dev/null
}

ensure_runner_layout() {
  local runner_window_id
  local run_pane_id
  local build_pane_id

  runner_window_id="$(get_pane_opt @hx_runner_window_id)"
  run_pane_id="$(get_pane_opt @hx_runner_run_pane_id)"
  build_pane_id="$(get_pane_opt @hx_runner_build_pane_id)"

  if [[ -n "$runner_window_id" ]] && [[ -n "$run_pane_id" ]] && [[ -n "$build_pane_id" ]] \
    && window_exists "$runner_window_id" && pane_exists "$run_pane_id" && pane_exists "$build_pane_id"; then
    set_pane_opt @hx_source_window_id "$src_window_id"
    echo "$runner_window_id|$run_pane_id|$build_pane_id"
    return 0
  fi

  # Recreate if missing or stale.
  runner_window_id="$(tmux new-window -d -P -F '#{window_id}' -n "$win_name" -c "$PWD")"
  run_pane_id="$(tmux display-message -p -t "$runner_window_id" '#{pane_id}')"
  build_pane_id="$(tmux split-window -d -h -P -F '#{pane_id}' -t "$run_pane_id" -c "$PWD")"

  tmux select-pane -t "$run_pane_id" -T RUN
  tmux select-pane -t "$build_pane_id" -T BUILD

  set_pane_opt @hx_runner_window_id "$runner_window_id"
  set_pane_opt @hx_runner_run_pane_id "$run_pane_id"
  set_pane_opt @hx_runner_build_pane_id "$build_pane_id"
  set_pane_opt @hx_source_window_id "$src_window_id"

  echo "$runner_window_id|$run_pane_id|$build_pane_id"
}

dispatch_to_pane() {
  local target_pane="$1"
  local run_mode="$2"
  local run_file="$3"
  local cmd

  printf -v cmd '%q %q %q' "$LANG_RUNNER" "$run_mode" "$run_file"
  tmux send-keys -t "$target_pane" C-c
  tmux send-keys -t "$target_pane" "$cmd" Enter
}

IFS='|' read -r runner_window_id run_pane_id build_pane_id <<< "$(ensure_runner_layout)"

case "$mode" in
  run)
    [[ -n "$file" ]] || { echo "run mode requires file path"; exit 2; }
    dispatch_to_pane "$run_pane_id" run "$file"
    ;;
  build)
    [[ -n "$file" ]] || { echo "build mode requires file path"; exit 2; }
    dispatch_to_pane "$build_pane_id" build "$file"
    ;;
  test)
    [[ -n "$file" ]] || { echo "test mode requires file path"; exit 2; }
    dispatch_to_pane "$build_pane_id" test "$file"
    ;;
  toggle)
    current_window_id="$(tmux display-message -p '#{window_id}')"
    source_window_id="$(get_pane_opt @hx_source_window_id)"
    if [[ "$current_window_id" == "$runner_window_id" && -n "$source_window_id" ]] && window_exists "$source_window_id"; then
      tmux switch-client -t "$source_window_id"
    else
      tmux switch-client -t "$runner_window_id"
    fi
    ;;
  focus-run)
    tmux switch-client -t "$runner_window_id"
    tmux select-pane -t "$run_pane_id"
    ;;
  focus-build)
    tmux switch-client -t "$runner_window_id"
    tmux select-pane -t "$build_pane_id"
    ;;
  *)
    echo "Unknown mode: $mode"
    exit 2
    ;;
esac
