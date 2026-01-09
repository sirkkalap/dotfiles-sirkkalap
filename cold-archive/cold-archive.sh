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
  cold-archive.sh --paths FILE --dest DEST_ROOT --checksums DIR [--dry-run] [--sync] [--verify] [--id NAME] [--self-test]

Parametrit:
  --paths FILE        Tiedosto, jossa polut (yksi per rivi). # kommentit sallittu.
  --dest DEST_ROOT    Kohteen juuri (esim. /Volumes/Arkisto)
  --checksums DIR     Hakemisto, johon checksum-manifestit talteen (esim. /Users/me/ArchiveManifests)
  --id NAME           Snapshotin nimi. Oletus: YYYYmmdd-HHMMSS
  --dry-run           Näytä mitä tehtäisiin (ei muutoksia)
  --sync              Suorita kopiointi rsyncillä
  --verify            Tarkista kohde manifestia vasten (sha256)
  --self-test         Aja sisäänrakennetut perus-testit (ei vaadi erillisiä työkaluja)

Esimerkkejä:
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --dry-run
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --sync
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --verify --id 20260109-120000
  ./cold-archive.sh --self-test
EOF
}

die() { echo "Virhe: $*" >&2; exit 1; }

PATHS_FILE=""
DEST_ROOT=""
CS_DIR=""
SNAP_ID=""
DO_DRYRUN=0
DO_SYNC=0
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
    --verify) DO_VERIFY=1; shift ;;
    --self-test) DO_SELFTEST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Tuntematon parametri: $1" ;;
  esac
done

if [[ $DO_SELFTEST -eq 0 ]]; then
  [[ -n "$PATHS_FILE" ]] || die "--paths puuttuu"
  [[ -n "$DEST_ROOT" ]] || die "--dest puuttuu"
  [[ -n "$CS_DIR" ]] || die "--checksums puuttuu"
  [[ -f "$PATHS_FILE" ]] || die "Polkutiedostoa ei löydy: $PATHS_FILE"
fi

if [[ $DO_DRYRUN -eq 0 && $DO_SYNC -eq 0 && $DO_VERIFY -eq 0 && $DO_SELFTEST -eq 0 ]]; then
  die "Anna vähintään yksi toiminto: --dry-run tai --sync tai --verify tai --self-test"
fi

if [[ -z "$SNAP_ID" ]]; then
  SNAP_ID="$(date +"%Y%m%d-%H%M%S")"
fi

self_test() {
  echo "== SELF-TEST: cold-archive.sh perus-testit =="

  local tmp_root
  tmp_root="$(mktemp -d)"
  local src_root="$tmp_root/src"
  local dest_root="$tmp_root/dest"
  local cs_root="$tmp_root/checksums"
  local paths_file="$tmp_root/paths.txt"
  local snap_id="TEST-$(date +%s)"

  mkdir -p "$src_root" "$dest_root" "$cs_root"

  cleanup() { rm -rf "$tmp_root"; }
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

  # Apu: aja komento ja tarkista exit
  run_ok() {
    "$@" >/dev/null
  }

  run_fail() {
    set +e
    "$@" >/dev/null 2>&1
    local rc=$?
    set -e
    [[ $rc -ne 0 ]]
  }

  echo "- dry-run"
  run_ok "$0" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --dry-run

  echo "- sync"
  run_ok "$0" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --sync

  local manifest="$cs_root/manifest-$snap_id.sha256"
  local snap_dir="$dest_root/ColdArchive/$snap_id"

  [[ -f "$manifest" ]] || die "SELF-TEST: manifest puuttuu"
  [[ -d "$snap_dir" ]] || die "SELF-TEST: snapshot-hakemisto puuttuu"

  echo "- verify (ok)"
  run_ok "$0" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --verify

  echo "- verify (pitäis epäonnistua jos data muuttuu)"
  printf "changed\n" >> "$snap_dir/./$src_root/Dir A/file 1.txt" 2>/dev/null || true
  # Yllä oleva polku ei välttämättä täsmää kaikissa ympäristöissä, joten etsitään tiedosto kohteesta ja rikotaan se varmasti
  local target_file
  target_file="$(find "$snap_dir" -type f -name 'file 1.txt' -print -quit)"
  [[ -n "$target_file" ]] || die "SELF-TEST: target file puuttuu"
  printf "changed\n" >> "$target_file"

  run_fail "$0" --paths "$paths_file" --dest "$dest_root" --checksums "$cs_root" --id "$snap_id" --verify \
    || die "SELF-TEST: verify ei epäonnistunut vaikka tiedostoa muutettiin"

  echo "SELF-TEST ok"
}

if [[ $DO_SELFTEST -eq 1 ]]; then
  self_test
  exit 0
fi

mkdir -p "$CS_DIR"
MANIFEST="$CS_DIR/manifest-$SNAP_ID.sha256"
PLAN="$CS_DIR/plan-$SNAP_ID.txt"
LOG="$CS_DIR/log-$SNAP_ID.txt"

# Kerää polut: poista tyhjät rivit ja kommentit (Bash 3.2 yhteensopiva, ei mapfile)
RAW_PATHS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  # trimmaa rivin lopun whitespace
  line="${line%$'\r'}"
  line="${line%%[[:space:]]}" 2>/dev/null || true
  # poista trailing whitespace turvallisemmin (bash 3.2)
  while [[ "$line" == *[[:space:]] ]]; do
    line="${line%[[:space:]]}"
  done

  # ohita tyhjät ja kommenttirivit (myös whitespace + #)
  case "$line" in
    "" ) continue ;;
    [[:space:]]* )
      # jos alkaa whitespace: tarkista kommentti/tyhjä uudestaan
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

# Normalisoi: laajenna ~ ja tee absoluuttinen jos mahdollista
normalize_path() {
  local p="$1"
  # shellcheck disable=SC2086
  p=$(eval echo "$p")  # laajentaa ~
  echo "$p"
}

# Muodosta kohdehakemisto snapshotille
DEST_SNAP="$DEST_ROOT/ColdArchive/$SNAP_ID"

echo "Snapshot: $SNAP_ID"
echo "Kohde:    $DEST_SNAP"
echo "Manifest: $MANIFEST"
echo "Logi:     $LOG"
echo

# Kirjoita plan-tiedosto (mitä on listassa)
{
  echo "Snapshot: $SNAP_ID"
  echo "Created:  $(date -Iseconds)"
  echo "Dest:     $DEST_SNAP"
  echo "Paths:"
  for p in "${RAW_PATHS[@]}"; do
    echo "  - $(normalize_path "$p")"
  done
} > "$PLAN"

# Laske karkea koko (du) ja listaa mitä löytyi
calc_size_bytes() {
  local total=0
  local p
  for p in "${RAW_PATHS[@]}"; do
    p="$(normalize_path "$p")"
    if [[ -e "$p" ]]; then
      # macOS: du -sk antaa kilot
      local kb
      kb=$(du -sk "$p" 2>/dev/null | awk '{print $1}' || echo 0)
      total=$(( total + kb * 1024 ))
    fi
  done
  echo "$total"
}

human_bytes() {
  # macOS: awk-pohjainen muunnos
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
  for p in "${RAW_PATHS[@]}"; do
    src="$(normalize_path "$p")"
    if [[ ! -e "$src" ]]; then
      echo "  (puuttuu) $src"
      continue
    fi

    # Kopioidaan hakemistot ja tiedostot DEST_SNAPin alle säilyttäen polku "sellaisenaan"
    # Rakennetaan relative-polku ilman leading slashia
    rel="${src#/}"
    dest_dir="$DEST_SNAP/$(dirname "$rel")"

    echo "  rsync '$src' -> '$dest_dir/'"
    rsync -aN --dry-run --itemize-changes "$src" "$dest_dir/" | head -n 50
    # (head siksi ettei räjähdä ruudulle, mutta itemize antaa hyvän kuvan)
  done
  echo
  echo "Dry-run tehty. Plan: $PLAN"
fi

if [[ $DO_SYNC -eq 1 ]]; then
  echo
  echo "== SYNC: kopioidaan rsyncillä =="
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
    dest_dir="$DEST_SNAP/$(dirname "$rel")"
    mkdir -p "$dest_dir"

    echo "Kopioidaan: $src -> $dest_dir/" | tee -a "$LOG"
    # -a säilyttää metatiedot, --protect-args suojaa välilyöntejä, --info näyttää etenemistä
    rsync -a --protect-args --info=stats2,progress2 "$src" "$dest_dir/" | tee -a "$LOG"
  done

  echo "== SYNC valmis, tehdään manifest (sha256) ==" | tee -a "$LOG"

  # Manifestiin: kaikki tiedostot kohteesta, suhteellisilla poluilla, deterministisessä järjestyksessä
  # -print0 + sort -z + xargs -0 toimii macOS:ssä
  (
    cd "$DEST_SNAP"
    find . -type f -print0 \
      | LC_ALL=C sort -z \
      | xargs -0 shasum -a 256
  ) > "$MANIFEST"

  echo "Manifest luotu: $MANIFEST" | tee -a "$LOG"
  echo "SYNC done." | tee -a "$LOG"
fi

if [[ $DO_VERIFY -eq 1 ]]; then
  echo
  echo "== VERIFY: tarkistetaan manifestia vasten =="

  [[ -d "$DEST_SNAP" ]] || die "Kohdesnapshotia ei löydy: $DEST_SNAP"
  [[ -f "$MANIFEST" ]] || die "Manifestia ei löydy: $MANIFEST (anna oikea --id tai käytä samaa checksums-hakemistoa)"

  # shasum -c odottaa tiedostonimiä suhteessa nykyiseen hakemistoon (manifestissa on ./polut)
  (
    cd "$DEST_SNAP"
    shasum -a 256 -c "$MANIFEST"
  )
  echo "VERIFY ok."
fi