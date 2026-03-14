#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$REPO_DIR/install.sh" --link-only "$@"

printf '\nConfig links refreshed.\n'
printf 'If Helix is already open, use Space R c to reload config or Space R r to reload the current file.\n'
