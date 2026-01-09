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
  --sync
```

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
  --paths paths.txt \
  --dest /Volumes/Arkisto \
  --checksums ~/ArchiveManifests \
  --id <SNAPSHOT-ID> \
  --verify
```

Tämä lukee koko arkiston ja vertaa sen sisältöä manifestiin.

---

## Self-test

```bash
./cold-archive.sh --self-test
```

Ajaa sisäisen testin, joka varmistaa että:

- dry-run toimii
- sync luo snapshotin ja manifestin
- verify tunnistaa ehjän datan
- verify epäonnistuu jos dataa muutetaan

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

- Päätekijä: (lisää nimesi tähän)
- Additional contributor: ChatGPT (OpenAI)
