from pathlib import Path
import shutil
import subprocess
import tempfile
import os

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
COA = ROOT / "src/server/coa"


def main():
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "A C++20 compiler is required"
    with tempfile.TemporaryDirectory(prefix="coa-guardian-travel-") as directory:
        out = Path(directory)
        exe = out / "guardian_travel.exe"
        source = str(HERE / "test.cpp")
        command = ([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/I" + str(COA), source,
                    "/Fe" + str(exe)]
                   if Path(compiler).name.lower() == "cl.exe" else
                   [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", "-I" + str(COA), source, "-o", str(exe)])
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print("PASS: guardian travel rules, timers, arrival and shortfall")


if __name__ == "__main__":
    main()
