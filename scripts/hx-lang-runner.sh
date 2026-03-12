#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
file="${2:-}"

if [[ -z "$mode" || -z "$file" ]]; then
  echo "Usage: hx-lang-runner.sh <run|build|test> <file>"
  exit 2
fi

if [[ ! -f "$file" ]]; then
  echo "File not found: $file"
  exit 2
fi

ext="${file##*.}"
file_dir="$(cd "$(dirname "$file")" && pwd)"
base_name="$(basename "$file")"
base_no_ext="${base_name%.*}"

find_up() {
  local start="$1"
  local marker="$2"
  local dir="$start"
  while true; do
    if [[ -e "$dir/$marker" ]]; then
      echo "$dir"
      return 0
    fi
    if [[ "$dir" == "/" ]]; then
      return 1
    fi
    dir="$(dirname "$dir")"
  done
}

run_in_dir() {
  local dir="$1"
  shift
  (
    cd "$dir"
    echo "[helix:$mode] cwd=$dir"
    echo "[helix:$mode] cmd=$*"
    "$@"
  )
}

run_node_like() {
  local root
  if root="$(find_up "$file_dir" package.json)"; then
    case "$mode" in
      run)
        if [[ "$ext" == "js" || "$ext" == "mjs" || "$ext" == "cjs" ]]; then
          run_in_dir "$root" node "$file"
        elif [[ "$ext" == "ts" ]]; then
          run_in_dir "$root" npx --yes tsx "$file"
        else
          echo "Run not defined for .$ext"
          exit 1
        fi
        ;;
      build)
        if [[ "$ext" == "ts" ]]; then
          run_in_dir "$root" npx --yes tsc --noEmit
        else
          run_in_dir "$root" node --check "$file"
        fi
        ;;
      test)
        if [[ -f "$root/package.json" ]] && grep -q '"test"' "$root/package.json"; then
          run_in_dir "$root" npm test
        else
          echo "No test script in package.json"
          exit 1
        fi
        ;;
    esac
  else
    echo "No package.json found for JS/TS project"
    exit 1
  fi
}

case "$ext" in
  rs)
    root="$(find_up "$file_dir" Cargo.toml || true)"
    [[ -n "${root:-}" ]] || { echo "No Cargo.toml found"; exit 1; }
    case "$mode" in
      run) run_in_dir "$root" cargo run ;;
      build) run_in_dir "$root" cargo build ;;
      test) run_in_dir "$root" cargo test ;;
    esac
    ;;
  go)
    root="$(find_up "$file_dir" go.mod || true)"
    [[ -n "${root:-}" ]] || { echo "No go.mod found"; exit 1; }
    case "$mode" in
      run) run_in_dir "$root" go run . ;;
      build) run_in_dir "$root" go build ./... ;;
      test) run_in_dir "$root" go test ./... ;;
    esac
    ;;
  py)
    case "$mode" in
      run) run_in_dir "$file_dir" python3 "$file" ;;
      build) run_in_dir "$file_dir" python3 -m py_compile "$file" ;;
      test)
        if command -v pytest >/dev/null 2>&1; then
          run_in_dir "$file_dir" pytest
        else
          run_in_dir "$file_dir" python3 -m unittest discover
        fi
        ;;
    esac
    ;;
  js|mjs|cjs|ts)
    run_node_like
    ;;
  c)
    out="${file_dir}/${base_no_ext}.out"
    case "$mode" in
      run) run_in_dir "$file_dir" cc "$file" -o "$out" && run_in_dir "$file_dir" "$out" ;;
      build) run_in_dir "$file_dir" cc "$file" -o "$out" ;;
      test) echo "No generic C test runner configured"; exit 1 ;;
    esac
    ;;
  cpp|cc|cxx)
    out="${file_dir}/${base_no_ext}.out"
    case "$mode" in
      run) run_in_dir "$file_dir" c++ -std=c++20 "$file" -o "$out" && run_in_dir "$file_dir" "$out" ;;
      build) run_in_dir "$file_dir" c++ -std=c++20 "$file" -o "$out" ;;
      test) echo "No generic C++ test runner configured"; exit 1 ;;
    esac
    ;;
  java)
    case "$mode" in
      run) run_in_dir "$file_dir" javac "$file" && run_in_dir "$file_dir" java "$base_no_ext" ;;
      build) run_in_dir "$file_dir" javac "$file" ;;
      test) echo "No generic Java test runner configured"; exit 1 ;;
    esac
    ;;
  cs)
    root="$(find_up "$file_dir" '*.csproj' || true)"
    # find_up does not support globs; fallback manual
    if [[ -z "${root:-}" ]]; then
      probe="$file_dir"
      while true; do
        if compgen -G "$probe/*.csproj" >/dev/null; then
          root="$probe"
          break
        fi
        [[ "$probe" == "/" ]] && break
        probe="$(dirname "$probe")"
      done
    fi
    [[ -n "${root:-}" ]] || { echo "C#: open a folder with .csproj to run/build/test"; exit 1; }
    case "$mode" in
      run) run_in_dir "$root" dotnet run ;;
      build) run_in_dir "$root" dotnet build ;;
      test) run_in_dir "$root" dotnet test ;;
    esac
    ;;
  php)
    case "$mode" in
      run) run_in_dir "$file_dir" php "$file" ;;
      build) run_in_dir "$file_dir" php -l "$file" ;;
      test)
        if command -v phpunit >/dev/null 2>&1; then
          run_in_dir "$file_dir" phpunit
        else
          echo "No phpunit found"
          exit 1
        fi
        ;;
    esac
    ;;
  sh|bash|zsh)
    case "$mode" in
      run) run_in_dir "$file_dir" bash "$file" ;;
      build) run_in_dir "$file_dir" bash -n "$file" ;;
      test) echo "No generic shell test runner configured"; exit 1 ;;
    esac
    ;;
  lua)
    case "$mode" in
      run) run_in_dir "$file_dir" lua "$file" ;;
      build)
        if command -v luac >/dev/null 2>&1; then
          run_in_dir "$file_dir" luac -p "$file"
        else
          echo "luac not found"
          exit 1
        fi
        ;;
      test) echo "No generic Lua test runner configured"; exit 1 ;;
    esac
    ;;
  *)
    echo "No run/build/test mapping for .$ext (intentionally unsupported for config/data languages)."
    exit 1
    ;;
esac
