CLI_DESCRIPTION = """Regress Barbaric Rage's contract: its native global cooldown modifier is not retargeted (#3945)."""
import argparse
from pathlib import Path
import os
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def extract_if_body(source, needle):
    start = source.index(needle)
    after_cond = source.index(")", start) + 1
    brace = source.index("{", after_cond)
    semicolon = source.index(";", after_cond)
    if brace < semicolon:
        end = brace + 1
        depth = 1
        while depth:
            depth += (source[end] == "{") - (source[end] == "}")
            end += 1
        return source[start:end]
    return source[start:semicolon + 1]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Use an earlier ApplyContracts as a negative control")
    args = parser.parse_args()
    path = "src/server/coa/AscensionBarbarianCompletion.cpp"
    if args.source_ref:
        source = git_source(["git", "show", f"{args.source_ref}:{path}"],
                                          cwd=ROOT).decode("utf-8")
    else:
        source = (ROOT / path).read_text(encoding="utf-8")
    contracts = extract_if_body(source, "void ApplyContracts(SpellInfo* info)")
    needle = "if (id == 804337)"
    block = extract_if_body(source, needle) if needle in contracts else ""
    code = r"""
#include <cstdint>
#include <cassert>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
constexpr uint32 EFFECT_0 = 0;
constexpr int32 SPELLMOD_COOLDOWN = 11, SPELLMOD_GLOBAL_COOLDOWN = 21;
struct SpellEffectInfo { int32 MiscValue = SPELLMOD_GLOBAL_COOLDOWN; };
struct SpellInfo { uint32 Id = 0; SpellEffectInfo Effects[3]; };
void ApplyBarbaricRageContract(SpellInfo* info)
{
    uint32 id = info->Id;
    (void)id;
""" + block + r"""
}
int main()
{
    SpellInfo rage;
    rage.Id = 804337;
    ApplyBarbaricRageContract(&rage);
    assert(rage.Effects[EFFECT_0].MiscValue == SPELLMOD_GLOBAL_COOLDOWN);
    assert(rage.Effects[EFFECT_0].MiscValue != SPELLMOD_COOLDOWN);
    SpellInfo other;
    other.Id = 801761;
    ApplyBarbaricRageContract(&other);
    assert(other.Effects[EFFECT_0].MiscValue == SPELLMOD_GLOBAL_COOLDOWN);
}
"""
    with tempfile.TemporaryDirectory(prefix="coa-barbaric-rage-") as directory:
        out = Path(directory)
        cpp, exe = out / "rage.cpp", out / "rage.exe"
        cpp.write_text(code, encoding="utf-8")
        compiler = Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe"
        subprocess.run([str(compiler), "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print("PASS: Barbaric Rage keeps its native global cooldown modifier; unrelated spells are untouched")


if __name__ == "__main__":
    main()
