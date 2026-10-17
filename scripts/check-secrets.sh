#!/usr/bin/env bash
set -euo pipefail

# Work from the repository root.
cd "$(git rev-parse --show-toplevel)"

# Scan the staged changes, redacting detected secret values.
# The scanner gets read-only access and no network connection.
docker run --rm \
  --network none \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/repo:ro" \
  -w /repo \
  ghcr.io/gitleaks/gitleaks:v8.30.1 \
  git --pre-commit --staged --redact=100 --verbose --no-banner .
