#!/usr/bin/env bash
set -euo pipefail

runner=/azerothcore-src/apps/coa-gameplay-test/run.py

if [[ "${1:-}" != run ]]; then
  exec python3 "$runner" "$@"
fi
shift

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD must be set}"
if [[ ! -w /results ]]; then
  echo "ERROR: /results is not writable; create .cache/coa-gameplay-tests as your user first" >&2
  exit 1
fi

container_credentials_dir="$(mktemp -d)"
mysql_escaped_password="${MYSQL_ROOT_PASSWORD//\\/\\\\}"
(
  umask 077
  printf '[client]\nhost=127.0.0.1\nport=3306\nuser=root\npassword="%s"\n' "$mysql_escaped_password" \
    > "$container_credentials_dir/admin-client.ini"
)
unset MYSQL_ROOT_PASSWORD mysql_escaped_password

exec python3 "$runner" run "$@" \
  --worldserver /azerothcore/env/dist/bin/worldserver \
  --config /coa/source-etc/worldserver.conf \
  --modules-config-dir /coa/source-etc/modules \
  --server-modules-dir /azerothcore/env/dist/etc/modules \
  --mysql /usr/bin/mysql \
  --mysqldump /usr/bin/mysqldump \
  --database-client-config "$container_credentials_dir/admin-client.ini" \
  --world-cache-dir /results/world-cache \
  --output "/results/$(date -u +%Y%m%dT%H%M%S%NZ)"
