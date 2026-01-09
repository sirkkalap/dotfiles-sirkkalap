#!/usr/bin/env bash
set -euo pipefail

# Self-test runner.
# Käyttö: run_self_test "/polku/cold-archive.sh"
run_self_test() {
  local script="${1:?missing path to cold-archive.sh}"

  local t0
  t0=$(date +%s)

  phase_start() {
    phase_name="$1"
    phase_t0=$(date +%s)
    echo "- $phase_name"
  }

  phase_end() {
    local t1
    t1=$(date +%s)
    echo "  (kesto) $phase_name: $((t1 - phase_t0))s"
  }

  local phase_name=""
  local phase_t0=0

  local tmp_root
  tmp_root="$(mktemp -d)"
  local keep_tmp="${COLD_ARCHIVE_KEEP_TMP:-0}"
  echo "  (tmp) $tmp_root"

  local src_root="$tmp_root/src"
  local dest_root="$tmp_root/dest"
  local cs_root="$tmp_root/checksums"
  local paths_file="$tmp_root/paths.txt"
  local snap_id="TEST-$(date +%s)"

  mkdir -p "$src_root" "$dest_root" "$cs_root"

  cleanup() {
    if [[ "$keep_tmp" == "1" ]]; then
      echo "  (tmp säilytetty) $tmp_root"
      return
    fi
    rm -rf "${tmp_root:-}"
  }
  trap cleanup EXIT

  # Luo testidata (myös välilyöntejä poluissa)
  mkdir -p "$src_root/Dir A/Sub Dir"
  printf "hello\n" > "$src_root/Dir A/file 1.txt"
  dd if=/dev/zero of="$src_root/Dir A/Sub Dir/big.bin" bs=1024 count=128 >/dev/null 2>&1

  # Polkulista
  {
    echo "# test paths"
    echo "$src_root/Dir A"
  } > "$paths_file"

  run_ok() { "$@" >/dev/null; }

  run_fail() {
    set +e
    "$@" >/dev/null 2>&1
    local rc=$?
    set -e
    [[ $rc -ne 0 ]]
  }

  phase_start "dry-run"
  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --dry-run
  phase_end

  phase_start "copy (initial)"
  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --copy
  phase_end

  phase_start "delete-test: --delete poistaa orphanin"

  # Luo kohteeseen ylimääräinen tiedosto, jota ei ole lähteessä
  extra_dir="$dest_root/ColdArchive/$snap_id/${src_root#/}/Dir A"
  mkdir -p "$extra_dir"
  printf "orphan\n" > "$extra_dir/orphan.txt"

  [[ -f "$extra_dir/orphan.txt" ]] || { echo "Virhe: SELF-TEST: orphan.txt ei syntynyt" >&2; exit 1; }

  echo "- delete-test: ajetaan --copy --delete"
  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --copy --delete

  if [[ -f "$extra_dir/orphan.txt" ]]; then
    echo "Virhe: SELF-TEST: --delete ei poistanut orphan.txt" >&2
    exit 1
  fi
  phase_end

  phase_start "delete-test: ilman --delete orphan säilyy"
  printf "orphan-again\n" > "$extra_dir/orphan.txt"
  [[ -f "$extra_dir/orphan.txt" ]] || { echo "Virhe: SELF-TEST: orphan.txt ei syntynyt (no-delete)" >&2; exit 1; }

  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --copy

  if [[ ! -f "$extra_dir/orphan.txt" ]]; then
    echo "Virhe: SELF-TEST: ilman --delete orphan.txt ei saanut poistua" >&2
    exit 1
  fi
  phase_end

  # Palauta kohde vastaamaan lähdettä ennen checksum/assert/verify -vaiheita
  rm -f "$extra_dir/orphan.txt" || true
  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --copy --delete

  local manifest="$cs_root/manifest-$snap_id.sha256"
  local snap_dir="$dest_root/ColdArchive/$snap_id"

  [[ -f "$manifest" ]] || { echo "Virhe: SELF-TEST: manifest puuttuu" >&2; exit 1; }
  [[ -d "$snap_dir" ]] || { echo "Virhe: SELF-TEST: snapshot-hakemisto puuttuu" >&2; exit 1; }

  phase_start "idempotency: copy uudestaan samaan id:hen"

  local manifest_before="$tmp_root/manifest.before.sha256"
  cp "$manifest" "$manifest_before"

  run_ok "$script" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --copy

  if ! diff -u "$manifest_before" "$manifest" >/dev/null; then
    echo "Virhe: SELF-TEST: idempotenssi rikkoutui: manifest muuttui toisella copy-ajolla" >&2
    echo "--- manifest diff preview (first 60 lines) ---" >&2
    diff -u "$manifest_before" "$manifest" | head -n 60 >&2 || true
    echo "--- end preview ---" >&2
    [[ "$keep_tmp" == "1" ]] && echo "  (tmp säilytetty) $tmp_root" >&2
    exit 1
  fi

  phase_end

  phase_start "assert: src vs dst checksummat"

  local src_manifest="$tmp_root/src-manifest.sha256"
  local dst_manifest="$tmp_root/dst-manifest.sha256"
  local diff_out="$tmp_root/manifest.diff"

  (
    cd "$src_root"
    find "./Dir A" -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256
  ) > "$src_manifest"

  local archived_src_root="$snap_dir/${src_root#/}"
  [[ -d "$archived_src_root" ]] || { echo "Virhe: SELF-TEST: archived_src_root puuttuu: $archived_src_root" >&2; exit 1; }

  (
    cd "$archived_src_root"
    find "./Dir A" -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256
  ) > "$dst_manifest"

  if ! diff -u "$src_manifest" "$dst_manifest" > "$diff_out"; then
    echo "SELF-TEST: src- ja dst-checksumit eivät täsmää. Diff: $diff_out" >&2
    echo "--- diff preview (first 60 lines) ---" >&2
    head -n 60 "$diff_out" >&2 || true
    echo "--- end preview ---" >&2
    [[ "$keep_tmp" == "1" ]] && echo "  (tmp säilytetty) $tmp_root" >&2
    echo "Virhe: SELF-TEST: src- ja dst-checksumit eivät täsmää" >&2
    exit 1
  fi
  phase_end

  phase_start "verify (ok)"
  run_ok "$script" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --verify
  phase_end

  phase_start "verify (fail kun data muuttuu)"
  local target_file
  target_file="$(find "$snap_dir" -type f -name 'file 1.txt' -print -quit)"
  [[ -n "$target_file" ]] || { echo "Virhe: SELF-TEST: target file puuttuu" >&2; exit 1; }
  printf "changed\n" >> "$target_file"

  run_fail "$script" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --verify \
    || { echo "Virhe: SELF-TEST: verify ei epäonnistunut vaikka tiedostoa muutettiin" >&2; exit 1; }
  phase_end

  local t_end
  t_end=$(date +%s)
  echo "  (kesto) self-test yhteensä: $((t_end - t0))s"

  cleanup
  trap - EXIT
  echo "SELF-TEST ok"
}