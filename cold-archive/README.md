# cold-archive.sh

Kylmäarkistointityökalu macOS/Linux-ympäristöihin. Skripti on tarkoitettu tilanteisiin, joissa dataa
kopioidaan **harvoin**, **offline-levylle**, ja kopioinnin jälkeen tehdään **sisältöpohjainen tarkistus**
(checksum-manifest), jota voidaan käyttää vuosienkin päästä datan eheyden todentamiseen.

Tavoite ei ole synkkaus, vaan **arkistointi**.

---

## Ominaisuudet

- Kopioi useita polkuja yhdestä listatiedostosta
- Luo jokaiselle ajolle oman snapshot-hakemiston
- Generoi SHA-256 checksum-manifestin koko arkistosta
- Tukee dry-run -ajoa ennen oikeaa kopiointia
- Tukee myöhempää verify-ajoa ilman alkuperäistä lähdettä
- Sisäänrakennettu self-test

---

## Vaatimukset

- bash (suositus: moderni bash, esim. Homebrew Bash 5+)
- rsync
- shasum (tulee macOS:ssa vakiona)

macOS:n vakio-bash (3.2) on tuettu, mutta skriptiä kehitetään "bash-mielessä".

---

## Asennus

```bash
chmod +x cold-archive.sh
```

Halutessasi voit asentaa modernin bashin:

```bash
brew install bash
```

ja vaihtaa shebangin esim:

```bash
#!/opt/homebrew/bin/bash
```

---

## paths.txt

Polkulista on tavallinen tekstitiedosto:

```text
# Kommentit sallittu
/Users/me/Documents/Important
/Users/me/Pictures
/Users/me/Movies/archive.mov
```

- yksi polku per rivi
- absoluuttiset polut suositeltuja
- `#` aloittaa kommentin

---

## Peruskäyttö

### Apu ja kaikki optiot

```bash
./cold-archive.sh --help
```

Tulostaa kaikki parametrit, toiminnot ja esimerkkikäytön.

---

### 1. Dry-run (suunnitelman tarkistus)

```bash
./cold-archive.sh \
  --paths paths.txt \
  --dest /Volumes/Arkisto \
  --checksums ~/ArchiveManifests \
  --dry-run
```

Näyttää mitä kopioitaisiin ja antaa karkean kokoarvion.

---

### 2. Kopiointi + manifestin luonti

```bash
./cold-archive.sh \
  --paths paths.txt \
  --dest /Volumes/Arkisto \
  --checksums ~/ArchiveManifests \
  --copy
```

Esimerkki, jossa myös manifestit tallennetaan samalle arkistolevylle:

```bash
./cold-archive.sh \
  --paths paths.txt \
  --dest /Volumes/Arkisto \
  --checksums /Volumes/Arkisto/Manifests \
  --copy
```

(Teknisesti toimiva, mutta arkistokäytössä suositellaan silti säilyttämään manifestit lisäksi myös eri levyllä tai pilvessä.)

Jos haluat peilata hakemistoja niin, että myös poistuneet tiedostot poistetaan kohteesta, käytä `--delete`:

```bash
./cold-archive.sh \
  --paths paths.txt \
  --dest /Volumes/Arkisto \
  --checksums ~/ArchiveManifests \
  --copy --delete
```

⚠️ Huom: `--delete` on tehokas ja voi poistaa dataa kohteesta. Kylmäarkistossa sitä kannattaa käyttää harkiten.

Tämä luo rakenteen:

```
/Volumes/Arkisto/ColdArchive/<SNAPSHOT-ID>/...
```

ja checksums-hakemistoon:

```
manifest-<SNAPSHOT-ID>.sha256
plan-<SNAPSHOT-ID>.txt
log-<SNAPSHOT-ID>.txt
```

---

### 3. Tarkistus myöhemmin

```bash
./cold-archive.sh \
  --dest /Volumes/Arkisto \
  --checksums ~/ArchiveManifests \
  --id <SNAPSHOT-ID> \
  --verify
```

Verify-vaihe ei vaadi enää `--paths`-parametria. Tarvitaan vain snapshotin sijainti ja manifest.

---

## Self-test

Self-testit on erotettu omaan tiedostoonsa, jotta pääskripti pysyy luettavana:

```
cold-archive.selftest.sh
```

Ajo:

```bash
./cold-archive.sh --self-test
```

Self-test tekee mm:

- dry-run (ei muutoksia)
- copy (luo snapshotin ja manifestin)
- assert: lähde ja arkisto tuottavat samat checksumit
- verify (ehjä data → ok)
- verify (rikottu data → epäonnistuu)

### Debug-tila self-testeille

Jos haluat säilyttää testin luoman temppidatan debuggausta varten:

```bash
COLD_ARCHIVE_KEEP_TMP=1 ./cold-archive.sh --self-test
```

Tällöin skripti tulostaa temp-hakemiston polun eikä poista sitä ajon lopussa.
---

## Arkistointifilosofia

Tämä työkalu on tarkoitettu **kylmään arkistointiin**:

- levy ei ole jatkuvasti kiinni
- snapshotteja ei muuteta jälkeenpäin
- manifestit säilytetään **eri paikassa** kuin itse data

Suositus:

- vähintään **2 fyysistä kopiota**
- vähintään **1 offsite-kopio**
- ajoittainen verify (esim. 1–2 kertaa vuodessa)

---

## Lisenssi

MIT. Katso `LICENSE`.

---

## Tekijät

- Päätekijä: sirpete@iki.fi
- Additional contributor: ChatGPT (OpenAI)
