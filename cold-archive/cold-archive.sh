#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Käyttö:
  cold-archive.sh --paths FILE --dest DEST_ROOT --checksums DIR [--dry-run] [--sync] [--verify] [--id NAME]

Parametrit:
  --paths FILE        Tiedosto, jossa polut (yksi per rivi). # kommentit sallittu.
  --dest DEST_ROOT    Kohteen juuri (esim. /Volumes/Arkisto)
  --checksums DIR     Hakemisto, johon checksum-manifestit talteen (esim. /Users/me/ArchiveManifests)
  --id NAME           Snapshotin nimi. Oletus: YYYYmmdd-HHMMSS
  --dry-run           Näytä mitä tehtäisiin (ei muutoksia)
  --sync              Suorita kopiointi rsyncillä
  --verify            Tarkista kohde manifestia vasten (sha256)

Esimerkkejä:
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --dry-run
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --sync
  ./cold-archive.sh --paths paths.txt --dest /Volumes/Arkisto --checksums ~/Manifests --verify --id 20260109-120000
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --paths) PATHS_FILE="${2:-}"; shift 2 ;;
    --dest) DEST_ROOT="${2:-}"; shift 2 ;;
    --checksums) CS_DIR="${2:-}"; shift 2 ;;
    --id) SNAP_ID="${2:-}"; shift 2 ;;
    --dry-run) DO_DRYRUN=1; shift ;;
    --sync) DO_SYNC=1; shift ;;
    --verify) DO_VERIFY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Tuntematon parametri: $1" ;;
  esac
done

[[ -n "$PATHS_FILE" ]] || die "--paths puuttuu"
[[ -n "$DEST_ROOT" ]] || die "--dest puuttuu"
[[ -n "$CS_DIR" ]] || die "--checksums puuttuu"
[[ -f "$PATHS_FILE" ]] || die "Polkutiedostoa ei löydy: $PATHS_FILE"

if [[ -z "$SNAP_ID" ]]; then
  SNAP_ID="$(date +"%Y%m%d-%H%M%S")"
fi

if [[ $DO_DRYRUN -eq 0 && $DO_SYNC -eq 0 && $DO_VERIFY -eq 0 ]]; then
  die "Anna vähintään yksi toiminto: --dry-run tai --sync tai --verify"
fi

mkdir -p "$CS_DIR"
MANIFEST="$CS_DIR/manifest-$SNAP_ID.sha256"
PLAN="$CS_DIR/plan-$SNAP_ID.txt"
LOG="$CS_DIR/log-$SNAP_ID.txt"

# Kerää polut: poista tyhjät rivit ja kommentit
mapfile -t RAW_PATHS < <(sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$PATHS_FILE")

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