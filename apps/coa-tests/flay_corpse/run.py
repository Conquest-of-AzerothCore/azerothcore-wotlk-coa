CLI_DESCRIPTION = """Regress Flay Corpse's automatic choice of the nearest eligible corpse (#5104)."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
PATH = "src/server/coa/AscensionXorothAbilities.cpp"


def braced(source, start):
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


def helpers(source):
    if "constexpr char FlayedCorpseKey" in source:
        return source[source.index("constexpr char FlayedCorpseKey"):source.index("class xoroth_flayed_corpse_death")]
    return "\n".join(braced(source, source.index(signature)) for signature in
                     ("bool Flayable(Unit* unit)", "float FlayRange(Player* player, Spell* spell)",
                      "Creature* NearestFlayable(Player* player, float range)") if signature in source)
def compile_and_run(code):
    with tempfile.TemporaryDirectory(prefix="coa-flay-corpse-", ignore_cleanup_errors=True) as directory:
        out = Path(directory)
        cpp, exe = out / "flay.cpp", out / "flay.exe"
        cpp.write_text(code, encoding="utf-8")
        msvc = shutil.which("cl")
        if msvc is None and os.environ.get("VCToolsInstallDir"):
            msvc = str(Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe")
        if msvc:
            command = [msvc, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", "/UNDEBUG",
                       "/I" + str(ROOT / "src/common/Utilities"), str(cpp), "/Fe" + str(exe)]
        else:
            compiler = shutil.which(os.environ.get("CXX", "g++"))
            assert compiler, "Run from a Visual Studio developer prompt or set CXX to a C++17 compiler."
            command = [compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", "-UNDEBUG", "-I",
                       str(ROOT / "src/common/Utilities"), str(cpp), "-o", str(exe)]
        subprocess.run(command, cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Use an earlier Xoroth abilities source as a negative control")
    args = parser.parse_args()
    source = (git_source(["git", "show", f"{args.source_ref}:{PATH}"], cwd=ROOT).decode("utf-8")
              if args.source_ref else (ROOT / PATH).read_text(encoding="utf-8"))
    check = braced(source, source.index("void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result)"))
    block = braced(check, check.index("if (info->Id == 801042)"))
    harness = (Path(__file__).with_name("harness.cpp")).read_text(encoding="utf-8")
    compile_and_run(harness.replace("// ACTUAL_FLAY_HELPERS", helpers(source))
                   .replace("// ACTUAL_FLAY_CAST_CHECK", block))
    print("PASS: Flay Corpse keeps a chosen corpse and otherwise takes the nearest eligible one in sight and reach")


if __name__ == "__main__":
    main()
