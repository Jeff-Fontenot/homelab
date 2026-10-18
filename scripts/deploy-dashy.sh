#!/usr/bin/env bash
set -euo pipefail

# OpenSSH supplies the caller's requested commit through this variable.
target_sha="${SSH_ORIGINAL_COMMAND:-}"
if [[ ! "$target_sha" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: expected a full, 40-character commit SHA." >&2
  exit 1
fi

cd /home/jeff/homelab

# Hold this lock until the script exits.
exec 9>.git/dashy-deploy.lock
flock -n 9

# Preserve local work and require the production branch.
if [[ "$(git branch --show-current)" != main ]] ||
   [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "Error: Services must have a clean, tracked main checkout." >&2
  exit 1
fi

# Public HTTPS fetch avoids the passphrase on the server's GitHub SSH key.
git fetch --no-tags https://github.com/Jeff-Fontenot/homelab.git \
  +refs/heads/main:refs/remotes/origin/main

# Refuse a request superseded by a newer push.
if [[ "$target_sha" != "$(git rev-parse origin/main)" ]]; then
  echo "Error: requested commit is no longer the tip of main." >&2
  exit 1
fi

# Require a fast-forward, then select exactly the checked commit.
git merge-base --is-ancestor HEAD "$target_sha"
git merge --ff-only "$target_sha"
docker compose --env-file .env -f docker-compose.yml config --quiet

# A successful deployment marker lets documentation-only pushes avoid restarts.
last_deployed="$(cat .git/dashy-deployed-sha 2>/dev/null || true)"
if [[ -n "$last_deployed" ]] &&
   git diff --quiet "$last_deployed" "$target_sha" -- \
     docker-compose.yml dashy-conf.yml icons/ patches/; then
  echo "Dashy inputs unchanged; keeping the current container."
else
  docker compose --env-file .env -f docker-compose.yml up \
    --no-deps --force-recreate --pull missing \
    --wait --wait-timeout 600 dashy
fi

# Also check health when a documentation-only push skipped recreation.
if [[ "$(docker inspect --format '{{.State.Health.Status}}' dashy)" != healthy ]]; then
  echo "Error: Dashy is not healthy." >&2
  exit 1
fi

printf '%s\n' "$target_sha" > .git/dashy-deployed-sha
printf 'DEPLOYED %s\n' "$target_sha"