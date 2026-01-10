#!/usr/bin/env python3
"""cold_archive_selftest.py

Python-pohjainen self-test runner cold-archive.sh:lle.

Tavoitteet:
- Ajaa samat skenaariot kuin bash-selftest (oraakkeli voidaan ajaa erikseen).
- Tulostaa vaiheiden kestot (ms) ja selkeät virheet.
- Valinnainen JUnit XML -raportti (COLD_ARCHIVE_JUNIT_OUT).
- Tmp-hakemiston säilytys debuggausta varten (COLD_ARCHIVE_KEEP_TMP=1).

Käyttö:
  python3 cold_archive_selftest.py --script ./cold-archive.sh
  COLD_ARCHIVE_JUNIT_OUT=artifacts/selftest.xml python3 cold_archive_selftest.py --script ./cold-archive.sh

Oraakkeli:
  --oracle-bash ajaa lisäksi: ./cold-archive.sh --self-test
"""

from __future__ import annotations

import argparse
import contextlib
import dataclasses
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import List, Optional, Sequence, Tuple


@dataclasses.dataclass
class PhaseResult:
    name: str
    duration_ms: int
    status: str  # passed|failed
    message: str = ""


class PhaseTimer:
    def __init__(self, results: List[PhaseResult]):
        self._results = results
        self._name: Optional[str] = None
        self._t0: float = 0.0
        self._idx: int = -1

    @contextlib.contextmanager
    def phase(self, name: str):
        self._name = name
        self._t0 = time.monotonic()
        self._idx = len(self._results)
        self._results.append(PhaseResult(name=name, duration_ms=0, status="running"))
        print(f"- {name}")
        try:
            yield
        except Exception as e:  # noqa: BLE001
            dt_ms = int((time.monotonic() - self._t0) * 1000)
            self._results[self._idx] = PhaseResult(name=name, duration_ms=dt_ms, status="failed", message=str(e))
            print(f"  (kesto) {name}: {dt_ms}ms")
            raise
        else:
            dt_ms = int((time.monotonic() - self._t0) * 1000)
            self._results[self._idx] = PhaseResult(name=name, duration_ms=dt_ms, status="passed")
            print(f"  (kesto) {name}: {dt_ms}ms")


def run_cmd(
    cmd: Sequence[str],
    *,
    check: bool,
    capture: bool = True,
    cwd: Optional[Path] = None,
    env: Optional[dict[str, str]] = None,
) -> subprocess.CompletedProcess[str]:
    cp = subprocess.run(
        list(cmd),
        text=True,
        cwd=str(cwd) if cwd else None,
        env=env,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    if check and cp.returncode != 0:
        out = (cp.stdout or "") + (cp.stderr or "")
        raise RuntimeError(f"Komento epäonnistui (rc={cp.returncode}): {' '.join(cmd)}\n{out}")
    return cp


def shasum256_for_tree(root: Path, rel: Path) -> List[Tuple[str, str]]:
    """Palauta lista (hash, './path') deterministisesti, sama muoto kuin shasum -a 256."""
    # macOS: sama hakemisto voi näkyä /var/... ja /private/var/...; käytetään realpathia, ei resolve().
    base = Path(os.path.realpath(str(root)))
    target = base / rel

    files: List[Path] = []
    for p in target.rglob("*"):
        if p.is_file() and not p.is_symlink():
            files.append(p)

    # Järjestetään samoin kuin LC_ALL=C sort (byte-order). Python sort on Unicode,
    # mutta Path.as_posix() ja encode('utf-8') antaa deterministisen.
    files.sort(key=lambda x: Path(os.path.realpath(str(x))).relative_to(base).as_posix().encode("utf-8"))

    results: List[Tuple[str, str]] = []
    import hashlib

    for p in files:
        h = hashlib.sha256()
        with p.open("rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
        relpath = "./" + Path(os.path.realpath(str(p))).relative_to(base).as_posix()
        results.append((h.hexdigest(), relpath))
    return results

def write_junit(out_path: Path, phases: List[PhaseResult]) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tests = len(phases)
    failures = sum(1 for p in phases if p.status == "failed")

    def xml_escape(s: str) -> str:
        return (
            s.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;")
        )

    lines: List[str] = []
    lines.append('<?xml version="1.0" encoding="UTF-8"?>')
    lines.append(f'<testsuite name="cold-archive.selftest" tests="{tests}" failures="{failures}">')

    for p in phases:
        time_s = f"{p.duration_ms / 1000.0:.3f}"
        name = xml_escape(p.name)
        lines.append(f'  <testcase classname="cold-archive.selftest" name="{name}" time="{time_s}">')
        if p.status == "failed":
            msg = xml_escape(p.message or "phase failed")
            lines.append(f'    <failure message="{msg}"></failure>')
        lines.append("  </testcase>")

    lines.append("</testsuite>")
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"  (junit) {out_path}")


def ensure_symlink(path: Path, *, label: str) -> None:
    if not path.is_symlink():
        raise RuntimeError(f"{label} ei ole symlink: {path}")


def file_mode(path: Path) -> int:
    # macOS stat: pyydetään suoraan mode-bitit
    return stat.S_IMODE(path.lstat().st_mode)


def main() -> int:
    ap = argparse.ArgumentParser(description="cold-archive Python self-test runner")
    ap.add_argument("--script", required=True, help="polku cold-archive.sh:ään")
    ap.add_argument("--oracle-bash", action="store_true", help="aja lisäksi bash-oraakkeli: --self-test")
    args = ap.parse_args()

    script = Path(args.script).resolve()
    if not script.exists():
        print(f"Virhe: script puuttuu: {script}", file=sys.stderr)
        return 2

    phases: List[PhaseResult] = []
    timer = PhaseTimer(phases)

    t0 = time.monotonic()

    keep_tmp = os.environ.get("COLD_ARCHIVE_KEEP_TMP", "0") == "1"
    junit_out = os.environ.get("COLD_ARCHIVE_JUNIT_OUT", "").strip()

    tmp_root = Path(tempfile.mkdtemp(prefix="tmp."))
    print(f"  (tmp) {tmp_root}")

    src_root = tmp_root / "src"
    dest_root = tmp_root / "dest"
    cs_root = tmp_root / "checksums"
    src_root.mkdir(parents=True, exist_ok=True)
    dest_root.mkdir(parents=True, exist_ok=True)
    cs_root.mkdir(parents=True, exist_ok=True)

    snap_id = f"TEST-{int(time.time())}"

    def cleanup() -> None:
        if keep_tmp:
            print(f"  (tmp säilytetty) {tmp_root}")
            return
        shutil.rmtree(tmp_root, ignore_errors=True)

    try:
        # Testidata (välilyöntejä poluissa)
        (src_root / "Dir A" / "Sub Dir").mkdir(parents=True, exist_ok=True)
        (src_root / "Dir A" / "file 1.txt").write_text("hello\n", encoding="utf-8")

        # big.bin
        big = src_root / "Dir A" / "Sub Dir" / "big.bin"
        big.write_bytes(b"\x00" * (128 * 1024))

        # symlinkit
        os.symlink("file 1.txt", src_root / "Dir A" / "link-to-file.txt")
        os.symlink("Sub Dir", src_root / "Dir A" / "link-to-dir")
        os.symlink("does-not-exist", src_root / "Dir A" / "broken-link")

        # oikeudet
        private = src_root / "Dir A" / "private.txt"
        private.write_text("secret\n", encoding="utf-8")
        private.chmod(0o400)

        runsh = src_root / "Dir A" / "run.sh"
        runsh.write_text("run\n", encoding="utf-8")
        runsh.chmod(0o755)

        # Polkulista
        paths_file = tmp_root / "paths.txt"
        paths_file.write_text(f"# test paths\n{src_root / 'Dir A'}\n", encoding="utf-8")

        def ok(cmd: Sequence[str]) -> None:
            run_cmd(cmd, check=True)

        def fail(cmd: Sequence[str]) -> None:
            cp = run_cmd(cmd, check=False)
            if cp.returncode == 0:
                raise RuntimeError(f"Komennon piti epäonnistua: {' '.join(cmd)}")

        with timer.phase("paths-validate: puuttuva polku failaa"):
            bad = tmp_root / "paths-missing.txt"
            bad.write_text(
                f"# test paths (missing)\n{src_root / 'Dir A'}\n{tmp_root / 'does-not-exist'}\n",
                encoding="utf-8",
            )
            fail([str(script), "--paths", str(bad), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--dry-run"])

        with timer.phase("paths-validate: ei lukuoikeutta failaa"):
            no_access = tmp_root / "no-access"
            no_access.mkdir(parents=True, exist_ok=True)
            no_access.chmod(0o000)
            bad = tmp_root / "paths-noaccess.txt"
            bad.write_text(
                f"# test paths (no access)\n{src_root / 'Dir A'}\n{no_access}\n",
                encoding="utf-8",
            )
            try:
                fail([str(script), "--paths", str(bad), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--dry-run"])
            finally:
                # palautetaan oikeudet siivousta varten
                no_access.chmod(0o700)

        with timer.phase("dry-run"):
            ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--dry-run"])

        with timer.phase("copy (initial)"):
            ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--copy"])

        with timer.phase(f"plan-file: plan-{snap_id}.txt syntyy"):
            plan_file = cs_root / f"plan-{snap_id}.txt"
            if not plan_file.exists():
                raise RuntimeError(f"plan-file puuttuu: {plan_file}")
            if plan_file.stat().st_size == 0:
                raise RuntimeError(f"plan-file on tyhjä: {plan_file}")

        # symlink/perms tarkistetaan arkistosta
        snap_dir = dest_root / "ColdArchive" / snap_id
        archived_src_root = snap_dir / str(src_root).lstrip("/")
        archived_dir_a = archived_src_root / "Dir A"

        with timer.phase("symlink-test: linkit säilyvät linkkeinä"):
            ensure_symlink(archived_dir_a / "link-to-file.txt", label="link-to-file")
            ensure_symlink(archived_dir_a / "link-to-dir", label="link-to-dir")
            ensure_symlink(archived_dir_a / "broken-link", label="broken-link")

        with timer.phase("permission-test: oikeudet säilyvät"):
            if file_mode(private) != file_mode(archived_dir_a / "private.txt"):
                raise RuntimeError("private.txt oikeudet eivät täsmää")
            if file_mode(runsh) != file_mode(archived_dir_a / "run.sh"):
                raise RuntimeError("run.sh oikeudet eivät täsmää")

        with timer.phase("delete-test: --delete poistaa orphanin"):
            extra_dir = archived_dir_a
            orphan = extra_dir / "orphan.txt"
            orphan.write_text("orphan\n", encoding="utf-8")
            if not orphan.exists():
                raise RuntimeError("orphan.txt ei syntynyt")

            print("- delete-test: ajetaan --copy --delete")
            ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--copy", "--delete"])

            if orphan.exists():
                raise RuntimeError("--delete ei poistanut orphan.txt")

        with timer.phase("delete-test: ilman --delete orphan säilyy"):
            extra_dir = archived_dir_a
            orphan = extra_dir / "orphan.txt"
            orphan.write_text("orphan-again\n", encoding="utf-8")
            if not orphan.exists():
                raise RuntimeError("orphan.txt ei syntynyt (no-delete)")

            ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--copy"])

            if not orphan.exists():
                raise RuntimeError("ilman --delete orphan.txt ei saanut poistua")

        # Palauta kohde puhtaaksi
        orphan = archived_dir_a / "orphan.txt"
        if orphan.exists():
            orphan.unlink()
        ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--copy", "--delete"])

        manifest = cs_root / f"manifest-{snap_id}.sha256"
        if not manifest.exists():
            raise RuntimeError("manifest puuttuu")
        if not snap_dir.exists():
            raise RuntimeError("snapshot-hakemisto puuttuu")

        with timer.phase("idempotency: copy uudestaan samaan id:hen"):
            before = tmp_root / "manifest.before.sha256"
            shutil.copyfile(manifest, before)

            ok([str(script), "--paths", str(paths_file), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--copy"])

            if before.read_bytes() != manifest.read_bytes():
                # näytä preview
                raise RuntimeError("idempotenssi rikkoutui: manifest muuttui toisella copy-ajolla")

        with timer.phase("rsync-diff: --dry-run --itemize-changes ei saa raportoida muutoksia"):
            rsync_log = tmp_root / "rsync-diff.log"
            src_dir = src_root / "Dir A"
            dst_dir = archived_src_root / "Dir A"
            if not src_dir.is_dir():
                raise RuntimeError(f"src_dir puuttuu: {src_dir}")
            if not dst_dir.is_dir():
                raise RuntimeError(f"dst_dir puuttuu: {dst_dir}")

            cp = run_cmd(["rsync", "-a", "--dry-run", "--itemize-changes", f"{src_dir}/", f"{dst_dir}/"], check=True)
            rsync_log.write_text((cp.stdout or "") + (cp.stderr or ""), encoding="utf-8")
            if rsync_log.stat().st_size != 0:
                preview = rsync_log.read_text(encoding="utf-8").splitlines()[:80]
                raise RuntimeError("rsync raportoi muutoksia idempotentissä vertailussa\n" + "\n".join(preview))

        with timer.phase("assert: src vs dst checksummat"):
            src_manifest = shasum256_for_tree(src_root, Path("Dir A"))
            dst_manifest = shasum256_for_tree(archived_src_root, Path("Dir A"))
            if src_manifest != dst_manifest:
                # tee diff-preview
                import difflib

                a = [f"{h}  {p}" for (h, p) in src_manifest]
                b = [f"{h}  {p}" for (h, p) in dst_manifest]
                diff = list(difflib.unified_diff(a, b, fromfile="src", tofile="dst", lineterm=""))
                preview = "\n".join(diff[:60])
                raise RuntimeError("src- ja dst-checksumit eivät täsmää\n" + preview)

        with timer.phase("verify (ok)"):
            ok([str(script), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--verify"])

        with timer.phase("verify (fail kun data muuttuu)"):
            target_file = next(snap_dir.rglob("file 1.txt"), None)
            if target_file is None:
                raise RuntimeError("target file puuttuu")
            with target_file.open("a", encoding="utf-8") as f:
                f.write("changed\n")

            cp = run_cmd([str(script), "--dest", str(dest_root), "--checksums", str(cs_root), "--id", snap_id, "--verify"], check=False)
            if cp.returncode == 0:
                raise RuntimeError("verify ei epäonnistunut vaikka tiedostoa muutettiin")

        total_ms = int((time.monotonic() - t0) * 1000)
        print(f"  (kesto) self-test yhteensä: {total_ms}ms")

        if args.oracle_bash:
            with timer.phase("oracle: bash --self-test"):
                ok([str(script), "--self-test"])

        print("SELF-TEST ok")
        return 0

    except Exception as e:  # noqa: BLE001
        # Merkitään viimeinen vaihe failed jos jäi running-tilaan
        if phases and phases[-1].status == "running":
            phases[-1].status = "failed"
            phases[-1].message = str(e)

        print(str(e), file=sys.stderr)
        return 1

    finally:
        # JUnit (myös epäonnistuneessa ajossa)
        if junit_out:
            try:
                write_junit(Path(junit_out), phases)
            except Exception as e:  # noqa: BLE001
                print(f"Virhe: junit-raportin kirjoitus epäonnistui: {e}", file=sys.stderr)

        cleanup()


if __name__ == "__main__":
    raise SystemExit(main())
