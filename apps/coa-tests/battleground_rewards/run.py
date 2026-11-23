from pathlib import Path
import os
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent


def main():
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "A C++20 compiler is required"
    msvc = Path(compiler).name.lower() == "cl.exe"
    with tempfile.TemporaryDirectory(prefix="coa-bg-rewards-") as directory:
        out = Path(directory)
        exe = out / "test_policy.exe"
        source = str(HERE / "test_policy.cpp")
        command = ([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", source, "/Fe" + str(exe)]
                   if msvc else [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", source, "-o", str(exe)])
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print("PASS: battleground reward quest policy checks")


if __name__ == "__main__":
    main()
