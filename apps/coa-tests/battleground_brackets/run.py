from pathlib import Path
import shutil
import subprocess
import tempfile
import os

HERE = Path(__file__).resolve().parent
TESTS = ["test_brackets", "test_lift_resources"]
ROOT = HERE.parents[2]


def main():
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "A C++20 compiler is required"
    msvc = Path(compiler).name.lower() == "cl.exe"
    with tempfile.TemporaryDirectory(prefix="coa-bg-brackets-") as directory:
        out = Path(directory)
        for name in TESTS:
            exe = out / (name + ".exe")
            source = str(HERE / (name + ".cpp"))
            if name == "test_lift_resources":
                production = (ROOT / "src/server/coa/AscensionBattlegroundCatchUp.cpp").read_text(encoding="utf-8")
                helpers = production[production.index("constexpr char LiftKey"):production.index("uint32 LiftTargetLevel")]
                refresh = production[production.index("void RefreshPlayerLift"):production.index("Policy::LevelValues PetLevelValues")]
                code = Path(source).read_text(encoding="utf-8").replace("// ACTUAL_LIFT", helpers)
                code = code.replace("// ACTUAL_REFRESH", refresh)
                code = code.replace("POLICY_HEADER", (ROOT / "src/server/game/Battlegrounds/AscensionBattlegroundBracketsPolicy.h").as_posix())
                source = str(out / (name + ".cpp"))
                Path(source).write_text(code, encoding="utf-8")
            command = ([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", source, "/Fe" + str(exe)]
                       if msvc else [compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", source, "-o", str(exe)])
            subprocess.run(command, cwd=out, check=True, timeout=120)
            subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print("PASS: battleground wide bracket parsing, widening and catch-up lift checks")


if __name__ == "__main__":
    main()
