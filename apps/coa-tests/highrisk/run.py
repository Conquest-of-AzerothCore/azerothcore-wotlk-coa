from pathlib import Path
import shutil
import subprocess
import tempfile
import os

HERE = Path(__file__).resolve().parent
TESTS = ["test_chests", "test_drops", "test_power"]


def main():
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "A C++20 compiler is required"
    msvc = Path(compiler).name.lower() == "cl.exe"
    with tempfile.TemporaryDirectory(prefix="coa-highrisk-") as directory:
        out = Path(directory)
        for name in TESTS:
            exe = out / (name + ".exe")
            source = str(HERE / (name + ".cpp"))
            command = ([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", source, "/Fe" + str(exe)]
                       if msvc else [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", source, "-o", str(exe)])
            subprocess.run(command, cwd=out, check=True, timeout=120)
            subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print("PASS: High-Risk chest, Bloodforged drop and PvP Power policy checks")


if __name__ == "__main__":
    main()
