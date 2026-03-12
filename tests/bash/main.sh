#!/usr/bin/env bash
set -euo pipefail

say_hello() {
  local prefix="$1"
  local name="$2"
  printf '%s, %s!\n' "$prefix" "$name"
}

main() {
  local prefix="Hello from Bash"
  local names=("Ada" "Grace" "Linus")

  for name in "${names[@]}"; do
    say_hello "$prefix" "$name"
  done

  case "${1:-status}" in
    status) echo "All good" ;;
    *) echo "Unknown command: $1" >&2; return 1 ;;
  esac
}

main "$@"
