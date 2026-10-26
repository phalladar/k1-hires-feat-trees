"""End-to-end tests: run mod/K1FeatTrees.ps1 (Windows PowerShell 5.1) against copies of real executables.

The executables are copyrighted and not in this repo. Point the env vars at local copies:
    K1FT_BASE_EXE   KOTOR Editable Executable (or GOG 1.03 swkotor.exe), unmodified
    K1FT_HR_EXE     an exe after UniWS + KotOR High Resolution Menus (optionally + K1 Area Map Fixes)
    K1FT_AMF_EXE    an HR exe that also has K1 Area Map Fixes installed (8 KB larger)
    K1FT_STEAM_EXE  the packed Steam swkotor.exe (must be refused)
Tests whose exe is missing are skipped.   python -m unittest discover -s tests -v
"""
import os
import shutil
import struct
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "mod" / "K1FeatTrees.ps1"
EXES = {
    "base": os.environ.get("K1FT_BASE_EXE", r"D:\KotorModding\extract\185_editable_exe\KOTOR Editable Executable"
                                            r"\KOTOR Editable Executable\swkotor.exe"),
    "hr": os.environ.get("K1FT_HR_EXE", r"D:\KotorModding\backup\swkotor_before_areamap.exe"),
    "amf": os.environ.get("K1FT_AMF_EXE", r"D:\SteamLibrary\steamapps\common\swkotor\swkotor.exe"),
    "steam": os.environ.get("K1FT_STEAM_EXE", r"D:\KotorModding\backup\swkotor_steam_original.exe"),
}
ROW = (0x2CD8D9, 0x2CDB79)
ARROW, ARROW_NEG, ARROW_HALF = 0x2CCE5F, 0x2CCF08, (0x2CCF2A, 0x2CCF5C)
NATIVE = (0x2CCD7F, 0x2CCDC2)    # push 1/0: draw icon/arrow pictures at native size


def values(data):
    return ([struct.unpack_from("<i", data, o)[0] for o in ROW], struct.unpack_from("<i", data, ARROW)[0],
            struct.unpack_from("<b", data, ARROW_NEG)[0], [struct.unpack_from("<b", data, o)[0] for o in ARROW_HALF],
            [data[o] for o in NATIVE])


class PatcherTest(unittest.TestCase):
    def game(self, which):
        src = Path(EXES[which])
        if not src.is_file():
            self.skipTest(f"{which} exe not available ({src})")
        d = Path(tempfile.mkdtemp(prefix="k1ft_"))
        self.addCleanup(shutil.rmtree, d, ignore_errors=True)
        shutil.copy2(src, d / "swkotor.exe")
        (d / "chitin.key").write_bytes(b"")
        return d

    def run_ps(self, game, *args):
        r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(SCRIPT),
                            "-GameDir", str(game), *args], capture_output=True, text=True, stdin=subprocess.DEVNULL)
        return r.returncode, r.stdout + r.stderr

    def test_hr_exe_auto_height_and_uninstall_roundtrip(self):
        self.roundtrip("hr")

    def test_area_map_fixes_exe_roundtrip(self):
        self.roundtrip("amf")

    def roundtrip(self, which):
        g = self.game(which)
        code, out = self.run_ps(g, "-Uninstall")          # fixture may already carry an install
        self.assertEqual(code, 0, out)
        (g / "swkotor.exe.before-feat-trees.bak").unlink(missing_ok=True)
        before = (g / "swkotor.exe").read_bytes()
        self.assertEqual(values(before), ([40, 40], 32, -32, [-16, -16], [1, 1]))
        code, out = self.run_ps(g)
        self.assertEqual(code, 0, out)
        after = (g / "swkotor.exe").read_bytes()
        h = -struct.unpack_from("<i", before, 0xB6DA)[0]
        row, arrow = round(40 * h / 480), min(128, round(32 * h / 480)) // 2 * 2
        self.assertEqual(values(after), ([row, row], arrow, -arrow, [-arrow // 2] * 2, [0, 0]), out)
        changed = [i for i in range(len(before)) if before[i] != after[i]]
        allowed = set()
        for o in ROW + (ARROW,):
            allowed.update(range(o, o + 4))
        allowed.update((ARROW_NEG,) + ARROW_HALF + NATIVE)
        self.assertTrue(set(changed) <= allowed, [hex(i) for i in changed])
        self.assertTrue((g / "swkotor.exe.before-feat-trees.bak").read_bytes() == before)
        code, out = self.run_ps(g)
        self.assertEqual(code, 0, out)
        self.assertIn("Nothing to do", out)
        code, out = self.run_ps(g, "-Uninstall")
        self.assertEqual(code, 0, out)
        self.assertEqual((g / "swkotor.exe").read_bytes(), before)

    def test_explicit_height_on_base_exe(self):
        g = self.game("base")
        code, out = self.run_ps(g, "-Height", "1440")
        self.assertEqual(code, 0, out)
        self.assertEqual(values((g / "swkotor.exe").read_bytes()), ([120, 120], 96, -96, [-48, -48], [0, 0]))
        code, out = self.run_ps(g, "-Height", "1080")      # re-run at another resolution
        self.assertEqual(code, 0, out)
        self.assertEqual(values((g / "swkotor.exe").read_bytes()), ([90, 90], 72, -72, [-36, -36], [0, 0]))

    def test_base_exe_without_hr_menus_is_refused(self):
        g = self.game("base")
        before = (g / "swkotor.exe").read_bytes()
        code, out = self.run_ps(g)
        self.assertEqual(code, 1, out)
        self.assertIn("640x480", out)
        self.assertEqual((g / "swkotor.exe").read_bytes(), before)

    def test_steam_exe_is_refused(self):
        g = self.game("steam")
        before = (g / "swkotor.exe").read_bytes()
        code, out = self.run_ps(g, "-Height", "1440")
        self.assertEqual(code, 1, out)
        self.assertIn("Editable Executable", out)
        self.assertEqual((g / "swkotor.exe").read_bytes(), before)

    def test_dry_run_writes_nothing(self):
        g = self.game("hr")
        before = (g / "swkotor.exe").read_bytes()
        code, out = self.run_ps(g, "-DryRun")
        self.assertEqual(code, 0, out)
        self.assertEqual((g / "swkotor.exe").read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
