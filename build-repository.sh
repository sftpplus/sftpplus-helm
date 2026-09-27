#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repository_root"

helm_bin="${HELM_BIN:-helm}"
repository_url="${HELM_REPOSITORY_URL:-https://helm.sftpplus.com/}"

if ! command -v "$helm_bin" >/dev/null 2>&1; then
  printf 'Helm executable not found: %s\n' "$helm_bin" >&2
  exit 1
fi

mkdir -p dist
"$helm_bin" lint . \
  --set-string storage.existingClaim=lint-pvc \
  --set-string credentials.adminPassword=lint-admin \
  --set-string credentials.workerPassword=lint-worker
"$helm_bin" package . --destination dist
"$helm_bin" repo index dist --url "${repository_url%/}/"
