#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts

SCRIPT_PATH="./cold-archive.sh"

[[ -x "$SCRIPT_PATH" ]] || {
  echo "Virhe: cold-archive.sh ei ole ajettava: $SCRIPT_PATH" >&2
  exit 2
}

echo "== CI self-test =="
echo "  script: $SCRIPT_PATH"
echo "  junit : ${COLD_ARCHIVE_JUNIT_OUT:-}"

export COLD_ARCHIVE_JUNIT_OUT="${COLD_ARCHIVE_JUNIT_OUT:-artifacts/selftest.xml}"

python3 cold_archive_selftest.py --script "$SCRIPT_PATH"
test -s "$COLD_ARCHIVE_JUNIT_OUT"
