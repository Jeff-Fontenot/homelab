#!/usr/bin/env bash
set -euo pipefail

# Read the command supplied through SSH.
target_sha="${SSH_ORIGINAL_COMMAND:-}"

# Require exactly 40 lowercase hexadecimal characters.
if [[ ! "$target_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: expected a full, 40-character commit SHA." >&2
  exit 1
fi

# Display the value we received.
echo "Requested commit: $target_sha"