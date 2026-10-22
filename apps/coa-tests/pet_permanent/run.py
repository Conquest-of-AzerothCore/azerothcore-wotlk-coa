CLI_DESCRIPTION = """Check which pets the client treats as permanent, without a server.

Compiles the production Pet::IsPermanentPetFor and checks the stock warlock, death knight, mage and hunter
rules, plus the custom-class summons that previously returned false: a Tinker's build pets and any Ascension
class's summoned pet. No database, build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read changed production code from a local Git ref for regression checks.")
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(["git", "show", f"{args.source_ref}:{name}"], cwd=ROOT).decode("utf-8")
        return (ROOT / name).read_text(encoding="utf-8")

    pet = source("src/server/game/Entities/Pet/Pet.cpp")
    harness = (HERE / "harness.cpp").read_text(encoding="utf-8")
    harness = harness.replace("// ACTUAL_PERMANENT", method(pet, "bool Pet::IsPermanentPetFor("))

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-pet-permanent-") as directory:
        out = Path(directory)
        (out / "harness.cpp").write_text(harness, encoding="utf-8")
        executable = out / ("permanent.exe" if os.name == "nt" else "permanent")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", str(out / "harness.cpp"), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", str(out / "harness.cpp"), "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Pet permanence harness did not compile:\n" + build.stdout + build.stderr)
        subprocess.run([str(executable)], cwd=out, check=True)


if __name__ == "__main__":
    main()
