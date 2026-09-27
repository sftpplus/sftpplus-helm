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

mkdir -p docs
"$helm_bin" lint . \
  --set-string storage.existingClaim=lint-pvc \
  --set-string credentials.adminPassword=lint-admin \
  --set-string credentials.workerPassword=lint-worker
"$helm_bin" package . --destination docs
"$helm_bin" repo index docs --url "${repository_url%/}/"

printf 'helm.sftpplus.com\n' > docs/CNAME
cat > docs/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>SFTPPlus Helm repository</title>
</head>
<body>
  <h1>SFTPPlus Helm repository</h1>
  <p>Add this repository with Helm:</p>
  <pre>helm repo add sftpplus https://helm.sftpplus.com/</pre>
  <p><a href="index.yaml">Chart index</a></p>
</body>
</html>
HTML
