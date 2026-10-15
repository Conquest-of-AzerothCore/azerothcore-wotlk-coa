import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / "src/server/coa"


def main():
    extract = runpy.run_path(str(ROOT / "apps/coa-tests/client_compat/run.py"))["method"]
    service = extract((MODULE / "AscensionCompat.cpp").read_text(), "class AscensionResourceService")
    harness = (Path(__file__).parent.parent / "resource_generation/harness.cpp").read_text()
    harness = harness.replace("uint32 Id = 0;", "uint32 Id = 0, SpellFamilyName = 22, CasterAuraSpell = 0;")
    harness = harness.replace("    bool HasAura(uint32 id) const", """
    Aura const* GetAura(uint32 id) const
    {
        auto it = auras.find(id);
        return it != auras.end() && it->second.m_stackAmount ? &it->second : nullptr;
    }
    bool HasAura(uint32 id) const""")
    harness = harness.replace("    int32 Count(uint32 id)",
                              "    void RemoveAurasDueToSpell(uint32 id) { auras.erase(id); }\n    int32 Count(uint32 id)")
    harness = harness.replace("// NATIVE_STACK", extract(
        (ROOT / "src/server/game/Spells/Auras/SpellAuras.cpp").read_text(), "bool Aura::ModStackAmount("))
    core = (ROOT / "src/server/game/Spells/SpellEffects.cpp").read_text()
    constants = "\n".join(re.findall(r"constexpr uint32 ASCENSION_\w+ = \d+;", core))
    code = (MODULE / "AscensionCustomResourceData.h").read_text() + harness + constants + "\n"
    code += """
constexpr uint32 CLASS_STORMBRINGER=16, CLASS_RANGER=23;
constexpr uint32 SPELL_STORMBRINGER_STATIC=803102, SPELL_STORMBRINGER_CHARGED_CONDUIT=803790;
using SpellCastResult=int;
constexpr int SPELL_CAST_OK=0, SPELL_FAILED_CASTER_AURASTATE=1, SPELL_FAILED_NO_POWER=2;
"""
    code += extract(core, "void ModifyAscensionAuraStacks(") + "\n"
    cast = extract(service, "void OnSpellCast(")
    cast = cast[:cast.index("        for (AscensionCompatData::ResourceGainRule")] + cast[
        cast.index("        for (AscensionCompatData::ResourceCostRule"):cast.index("        ConsumeReaperSouls")] + "}"
    code += "struct ResourceService {\n" + "\n".join(extract(service, signature) for signature in (
        "static bool Matches(", "static uint8 GetAuraStacks(", "static void ModifyAuraStacks(",
        "void CheckCast(")) + "\n" + cast + "\n};\n"
    code += Path(__file__).with_name("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-storm-resources-") as directory:
        out = Path(directory)
        cpp, exe = out / "resources.cpp", out / "resources.exe"
        cpp.write_text(code, encoding="utf-8")
        compiler = Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe"
        subprocess.run([str(compiler), "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print("PASS: every Static cost rule, threshold checks, conduit preservation and native positive/negative gates")


if __name__ == "__main__":
    main()
