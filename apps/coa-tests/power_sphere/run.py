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
    source = (ROOT / "src/server/coa/AscensionStormbringerSphere.cpp").read_text()
    code = Path(__file__).with_name("harness.cpp").read_text().replace(
        "// SOURCE", re.sub(r"^#include.*\n", "", source, flags=re.M))
    with tempfile.TemporaryDirectory(prefix="coa-power-sphere-") as directory:
        out = Path(directory)
        cpp, exe = out / "sphere.cpp", out / "sphere.exe"
        cpp.write_text(code, encoding="utf-8")
        compiler = Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe"
        subprocess.run([str(compiler), "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    dbc = dbc_dir()
    raw = (dbc / "Spell.dbc").read_bytes()
    count = struct.unpack_from("<I", raw, 4)[0]
    rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20+count*936]) if r[0] in {706433,706434}}
    assert rows[706434][35] == 25 and rows[706434][110] == 503201 and rows[706434][113] == 61
    assert rows[706433][208] == 22 and rows[706433][225] == 72
    assert rows[706433][86] == 6 and rows[706433][89] == 16 and rows[706433][92] == 8
    assert rows[706433][80]+rows[706433][74] == 997
    raw = (dbc / "CreatureDisplayInfo.dbc").read_bytes()
    count = struct.unpack_from("<I",raw,4)[0]
    displays = {r[0]:r[1] for r in struct.iter_unpack("<16I",raw[20:20+count*64])}
    assert displays[29352] == 3134
    print("PASS: sphere chance/gates, one-owned-summon limit, Stormflow ranks, arrival/cleanup and max-school scaling")


if __name__ == "__main__":
    main()
