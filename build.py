"""Package mod/ + LICENSE into dist/K1-HiRes-Feat-Trees-<version>.zip (version read from the script)."""
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
version = re.search(r"Feat & Power Trees (\d+\.\d+\.\d+)'", (ROOT / "mod" / "K1FeatTrees.ps1").read_text()).group(1)
name = f"K1-HiRes-Feat-Trees-{version}"
out = ROOT / "dist" / f"{name}.zip"
out.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted((ROOT / "mod").iterdir()):
        z.write(f, f"{name}/{f.name}")
    z.write(ROOT / "LICENSE", f"{name}/LICENSE")
print(out, out.stat().st_size, "bytes")
