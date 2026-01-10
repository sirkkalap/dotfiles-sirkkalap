#!/usr/bin/env bash
#
# cold-archive.sh — kylmäarkistointityökalu macOS/Linux-ympäristöihin
#
# Copyright (c) 2026
#
# Authors:
#   - (lisää nimesi tähän)
#
# License: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
set -euo pipefail

usage() {
  cat <<'EOF'
Käyttö:
  cold-archive.sh --dest DEST_ROOT --checksums DIR [--paths FILE] [--dry-run] [--copy|--sync] [--delete] [--verify] [--id NAME] [--self-test]

Parametrit:
  --paths FILE        Tiedosto, jossa polut (yksi per rivi). # kommentit sallittu.
  --dest DEST_ROOT    Kohteen juuri (esim. /Volumes/Arkisto)
  --checksums DIR     Hakemisto, johon checksum-manifestit talteen (esim. /Users/me/ArchiveManifests)
  --id NAME           Snapshotin nimi. Oletus: YYYYmmdd-HHMMSS
  --dry-run           Näytä mitä tehtäisiin (ei muutoksia)
  --copy              Kopioi (rsync). (--sync toimii aliaksena)
  --delete            Poistaa kohteesta tiedostot, joita ei enää ole lähteessä (vain --copy/--sync)
  --verify            Tarkista kohde manifestia vasten (sha256). Ei vaadi --paths.
  --self-test         Aja testit (oletus: ./cold-archive.selftest.sh)

Esimerkkejä:
  ./cold-archive.sh --help
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --dry-run
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --copy
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --copy --delete
  ./cold-archive.sh --dest /Volumes/Arkisto --checksums ~/Manifests --verify --id 20260109-120000
  ./cold-archive.sh --self-test
EOF
}

die() { echo "Virhe: $*" >&2; exit 1; }

PATHS_FILE=""
DEST_ROOT=""
CS_DIR=""
SNAP_ID=""
DEST_SNAP=""
DO_DRYRUN=0
DO_SYNC=0
DO_DELETE=0
DO_VERIFY=0
DO_SELFTEST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --paths) PATHS_FILE="${2:-}"; shift 2 ;;
    --dest) DEST_ROOT="${2:-}"; shift 2 ;;
    --checksums) CS_DIR="${2:-}"; shift 2 ;;
    --id) SNAP_ID="${2:-}"; shift 2 ;;
    --dry-run) DO_DRYRUN=1; shift ;;
    --sync) DO_SYNC=1; shift ;;
    --copy) DO_SYNC=1; shift ;;
    --delete) DO_DELETE=1; shift ;;
    --verify) DO_VERIFY=1; shift ;;
    --self-test) DO_SELFTEST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Tuntematon parametri: $1" ;;
  esac
done

if [[ $DO_DRYRUN -eq 0 && $DO_SYNC -eq 0 && $DO_VERIFY -eq 0 && $DO_SELFTEST -eq 0 ]]; then
  die "Anna vähintään yksi toiminto: --dry-run tai --sync tai --verify tai --self-test"
fi

if [[ $DO_SELFTEST -eq 0 ]]; then
  [[ -n "$DEST_ROOT" ]] || die "--dest puuttuu"
  [[ -n "$CS_DIR" ]] || die "--checksums puuttuu"

  # --paths vaaditaan vain dry-run/copy/sync -ajoissa
  if [[ $DO_DRYRUN -eq 1 || $DO_SYNC -eq 1 ]]; then
    [[ -n "$PATHS_FILE" ]] || die "--paths puuttuu"
    [[ -f "$PATHS_FILE" ]] || die "Polkutiedostoa ei löydy: $PATHS_FILE"
  fi
fi

if [[ -z "$SNAP_ID" ]]; then
  # ISO-tyylinen aikaleima, tiedostonimeen sopivilla erottimilla
  SNAP_ID="$(date +"%Y-%m-%dT%H-%M-%S")"
fi

# Kohdesnapshotin polku (tarvitaan myös verify-only -ajossa ennen polkulistan lukua)
if [[ $DO_SELFTEST -eq 0 ]]; then
  DEST_SNAP="$DEST_ROOT/ColdArchive/$SNAP_ID"
fi

self_test() {
  echo "== SELF-TEST: cold-archive.sh perus-testit =="

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local selftest_file="${COLD_ARCHIVE_SELFTEST_FILE:-$script_dir/cold-archive.selftest.sh}"
  [[ -f "$selftest_file" ]] || die "Self-test tiedostoa ei löydy: $selftest_file"

  # shellcheck disable=SC1090
  source "$selftest_file"

  type run_self_test >/dev/null 2>&1 || die "Self-test tiedostosta puuttuu funktio: run_self_test"

  run_self_test "$0"
}

if [[ $DO_SELFTEST -eq 1 ]]; then
  self_test
  exit 0
fi

mkdir -p "$CS_DIR"
MANIFEST="$CS_DIR/manifest-$SNAP_ID.sha256"
PLAN="$CS_DIR/plan-$SNAP_ID.txt"
LOG="$CS_DIR/log-$SNAP_ID.txt"

normalize_path() {
  local p="$1"
  # shellcheck disable=SC2086
  p=$(eval echo "$p")
  echo "$p"
}

validate_paths() {
  local errors=0
  local p src

  for p in "${RAW_PATHS[@]}"; do
    src="$(normalize_path "$p")"

    if [[ ! -e "$src" ]]; then
      echo "Virhe: Polku ei löydy: $src" >&2
      errors=$((errors + 1))
      continue
    fi

    if [[ ! -r "$src" ]]; then
      echo "Virhe: Ei lukuoikeutta polkuun: $src" >&2
      errors=$((errors + 1))
      continue
    fi

    if [[ -d "$src" && ! -x "$src" ]]; then
      echo "Virhe: Hakemisto ei ole selattavissa (puuttuu x-oikeus): $src" >&2
      errors=$((errors + 1))
      continue
    fi
  done

  [[ $errors -eq 0 ]] || die "Polkulistan validointi epäonnistui ($errors virhettä)"
}

if [[ $DO_DRYRUN -eq 1 || $DO_SYNC -eq 1 ]]; then

# Kerää polut: poista tyhjät rivit ja kommentit (Bash 3.2 yhteensopiva, ei mapfile)
RAW_PATHS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  while [[ "$line" == *[[:space:]] ]]; do
    line="${line%[[:space:]]}"
  done

  case "$line" in
    "" ) continue ;;
    [[:space:]]* )
      local_trim="$line"
      while [[ "$local_trim" == [[:space:]]* ]]; do
        local_trim="${local_trim#[[:space:]]}"
      done
      [[ -z "$local_trim" ]] && continue
      [[ "$local_trim" == \#* ]] && continue
      line="$local_trim"
      ;;
    \#* ) continue ;;
  esac

  RAW_PATHS+=("$line")
done < "$PATHS_FILE"

[[ ${#RAW_PATHS[@]} -gt 0 ]] || die "Polkulista on tyhjä: $PATHS_FILE"

# Validoidaan polut ennen operaatioita (dry-run/copy)
if [[ $DO_DRYRUN -eq 1 || $DO_SYNC -eq 1 ]]; then
  validate_paths
fi

echo "Snapshot: $SNAP_ID"
echo "Kohde:    $DEST_SNAP"
echo "Manifest: $MANIFEST"
echo "Logi:     $LOG"
echo

{
  echo "Snapshot: $SNAP_ID"
  echo "Created:  $(date -Iseconds)"
  echo "Dest:     $DEST_SNAP"
  echo "Paths:"
  for p in "${RAW_PATHS[@]}"; do
    echo "  - $(normalize_path "$p")"
  done
} > "$PLAN"

calc_size_bytes() {
  local total=0
  local p
  for p in "${RAW_PATHS[@]}"; do
    p="$(normalize_path "$p")"
    if [[ -e "$p" ]]; then
      local kb
      kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}' || echo 0)
      total=$(( total + kb * 1024 ))
    fi
  done
  echo "$total"
}

human_bytes() {
  awk -v b="$1" 'function human(x){
    s="B KB MB GB TB PB"; split(s,a," ")
    i=1
    while(x>=1024 && i<6){x/=1024; i++}
    return sprintf("%.2f %s", x, a[i])
  } BEGIN{print human(b)}'
}

TOTAL_BYTES="$(calc_size_bytes)"
echo "Arvioitu koko yhteensä: $(human_bytes "$TOTAL_BYTES")"

if [[ $DO_DRYRUN -eq 1 ]]; then
  echo
  echo "== DRY-RUN: rsync suunnitelma =="

  RSYNC_DRY_OPTS=(-a --dry-run --itemize-changes)
  # -N == --crtimes. Kaikki rsync-buildit eivät tue tätä (esim. Debian/CI).
  if rsync_supports_flag "--crtimes"; then
    RSYNC_DRY_OPTS+=(-N)
  fi

  for p in "${RAW_PATHS[@]}"; do
    src="$(normalize_path "$p")"
    if [[ ! -e "$src" ]]; then
      echo "  (puuttuu) $src"
      continue
    fi

    rel="${src#/}"
    dest_dir="$DEST_SNAP/$(dirname "$rel")"

    echo "  rsync '$src' -> '$dest_dir/'"
    rsync "${RSYNC_DRY_OPTS[@]}" "$src" "$dest_dir/" | head -n 50
  done
  echo
  echo "Dry-run tehty. Plan: $PLAN"
fi

if [[ $DO_SYNC -eq 1 ]]; then
  echo
  echo "== COPY: kopioidaan rsyncillä =="
  mkdir -p "$DEST_SNAP"
  {
    echo "== $(date -Iseconds) SYNC start =="
    echo "Dest: $DEST_SNAP"
  } >> "$LOG"

  for p in "${RAW_PATHS[@]}"; do
    src="$(normalize_path "$p")"
    if [[ ! -e "$src" ]]; then
      echo "(ohitetaan, puuttuu) $src" | tee -a "$LOG"
      continue
    fi

    rel="${src#/}"

    if [[ -d "$src" ]]; then
      # Hakemisto: peilaa sisällöt kohteessa samaan hakemistoon
      dest_path="$DEST_SNAP/$rel"
      mkdir -p "$(dirname "$dest_path")" "$dest_path"

      echo "Kopioidaan (dir): $src/ -> $dest_path/" | tee -a "$LOG"
      if [[ $DO_DELETE -eq 1 ]]; then
        rsync -a --delete --protect-args --info=stats2,progress2 "$src/" "$dest_path/" | tee -a "$LOG"
      else
        rsync -a --protect-args --info=stats2,progress2 "$src/" "$dest_path/" | tee -a "$LOG"
      fi
    else
      # Yksittäinen tiedosto: kopioi parent-hakemistoon
      dest_dir="$DEST_SNAP/$(dirname "$rel")"
      mkdir -p "$dest_dir"

      echo "Kopioidaan (file): $src -> $dest_dir/" | tee -a "$LOG"
      rsync -a --protect-args --info=stats2,progress2 "$src" "$dest_dir/" | tee -a "$LOG"
    fi
  done

  echo "== SYNC valmis, tehdään manifest (sha256) ==" | tee -a "$LOG"

  (
    cd "$DEST_SNAP"
    find . -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256
  ) > "$MANIFEST"

  echo "Manifest luotu: $MANIFEST" | tee -a "$LOG"
  echo "COPY done." | tee -a "$LOG"
fi  # DO_SYNC
fi  # DO_DRYRUN/DO_SYNC (paths-pohjaiset operaatiot)

if [[ $DO_VERIFY -eq 1 ]]; then
  echo
  echo "== VERIFY: tarkistetaan manifestia vasten =="

  if [[ -z "${DEST_SNAP:-}" ]]; then
    DEST_SNAP="$DEST_ROOT/ColdArchive/$SNAP_ID"
  fi

  [[ -d "$DEST_SNAP" ]] || die "Kohdesnapshotia ei löydy: $DEST_SNAP"
  [[ -f "$MANIFEST" ]] || die "Manifestia ei löydy: $MANIFEST (anna oikea --id tai käytä samaa checksums-hakemistoa)"

  (
    cd "$DEST_SNAP"
    shasum -a 256 -c "$MANIFEST"
  )
  echo "VERIFY ok."
fi