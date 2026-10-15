import os
from pathlib import Path
import re
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def main():
    source = (ROOT / "src/server/coa/AscensionBloodmageSecondary.cpp").read_text()
    header = (ROOT / "src/server/game/Spells/AscensionPooledVitality.h").read_text()
    strip = lambda text: re.sub(r"^#include.*\n", "", text, flags=re.M)
    code = Path(__file__).with_name("harness.cpp").read_text().replace("// POOLED_HEADER", strip(header))
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    code = code.replace("// SOURCE", strip(source))
    with tempfile.TemporaryDirectory(prefix="coa-bloodmage-secondary-") as directory:
        out = Path(directory)
        cpp, exe = out / "bloodmage.cpp", out / "bloodmage.exe"
        cpp.write_text(code, encoding="utf-8")
        compiler = Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe"
        subprocess.run([str(compiler), "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / "Spell.dbc").read_bytes()
    count = struct.unpack_from("<I", raw, 4)[0]
    ids = {562720,562572,572856,707706,681395,572280,704659,707447,706605,706607,706606,706608}
    rows = {r[0]:r for r in struct.iter_unpack("<234I",raw[20:20+count*936]) if r[0] in ids}
    assert rows[707706][80]+rows[707706][74] == rows[681395][80]+rows[681395][74] == 25
    assert rows[572280][80]+rows[572280][74] == 100
    assert rows[572856][49] == 2 and rows[572856][80]+rows[572856][74] == 5000
    assert rows[562720][210] & rows[572856][123] == rows[562572][210] & rows[572856][123] != 0
    assert rows[704659][35] == rows[707447][35] == 40
    assert rows[706605][116] == 706607 and rows[706605][4] & 0x10000000
    assert rows[706607][116] == 706606 and rows[706607][89] == 7 and rows[706607][212] == 3
    assert rows[706606][71] == 3 and rows[706606][6] & 1
    assert rows[706608][71:73] == (136,137) and rows[706608][111] == 1
    print("PASS: conditional damage/crit, pre-hit Reave conditions, form charges, actual-cost refunds and owned Kiss copies")


if __name__ == "__main__":
    main()
