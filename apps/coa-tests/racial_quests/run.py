CLI_DESCRIPTION = """Check actual racial grant predicates and Draenei rescue spell admission without a server build."""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Use the pre-fix source from a local Git ref.")
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()

    def source(path):
        if args.source_ref:
            return git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
        return ROOT.joinpath(path).read_text(encoding="utf-8")

    shared = source("src/server/shared/SharedDefines.h")
    dbc_enums = source("src/server/shared/DataStores/DBCEnums.h")
    dbc_structs = source("src/server/shared/DataStores/DBCStructure.h")
    code = "#include <algorithm>\n#include <array>\n#include <cassert>\n#include <cstdint>\n#include <vector>\n"
    code += "using uint8=std::uint8_t; using uint32=std::uint32_t; using int32=std::int32_t;\n"
    code += "\n".join(method(shared, "enum " + name) + ";" for name in ("Races", "Classes", "SkillType"))
    code += "\n" + re.search(r"^#define MAX_CLASSES .*", shared, re.M)[0] + "\n"
    code += method(shared, "constexpr bool IsAscensionClass(")
    code += method(dbc_enums, "enum AbilytyLearnType") + ";\n"
    code += method(dbc_structs, "struct SkillLineAbilityEntry") + ";\n"
    header = source("src/server/coa/AscensionRacialAbilities.h")
    code += re.sub(r'^#include.*\n', '', header, flags=re.M)
    tests = source("src/test/server/game/Modules/AscensionRacialAbilitiesTest.cpp")
    code += "\n#define TEST(suite,name) void suite##name()\n"
    code += "#define EXPECT_TRUE(value) assert(value)\n#define EXPECT_FALSE(value) assert(!(value))\n"
    code += "#define EXPECT_EQ(a,b) assert((a)==(b))\n"
    code += re.sub(r'^#include.*\n', '', tests, flags=re.M)
    calls = [suite + name + "();" for suite, name in re.findall(r"TEST\((\w+),\s*(\w+)\)", tests)]

    zone = source("src/server/scripts/Kalimdor/zone_azuremyst_isle.cpp")
    code += method(zone, "enum draeneiSurvivor") + ";\n"
    code += """
struct Unit { uint32 GetGUID() const { return 42; } };
constexpr uint32 UNIT_FLAG_PLAYER_CONTROLLED=8, UNIT_STAND_STATE_STAND=0;
struct Creature : Unit
{
    bool rescued=false;
    void RemoveUnitFlag(uint32) { rescued=true; }
    void SetStandState(uint32) { }
};
struct SpellInfo { uint32 Id=0; std::array<uint32,3> SpellFamilyFlags{}; };
struct Survivor
{
    Creature creature;
    Creature* me=&creature;
    uint32 pCaster=0, SayThanksTimer=0;
    void DoCast(Creature*, uint32 id, bool) { assert(id==SPELL_STUNNED); }
"""
    code += method(zone, "void SpellHit(Unit* Caster, SpellInfo const* Spell)").replace(" override", "")
    code += "};\nint main(){\n" + "\n".join(calls)
    code += """
    Unit caster;
    for (uint32 id : {814280,814281,814282,28880,12345})
    {
        Survivor survivor;
        SpellInfo spell;
        spell.Id=id;
        if (id==28880) spell.SpellFamilyFlags[2]=0x80000000u;
        survivor.SpellHit(&caster,&spell);
        bool expected=id!=12345;
        assert(survivor.creature.rescued==expected);
        assert(survivor.SayThanksTimer==(expected?5000u:0u));
        assert(survivor.pCaster==(expected?caster.GetGUID():0u));
    }
"""
    if args.dbc_dir:
        raw = args.dbc_dir.joinpath("SkillLineAbility.dbc").read_bytes()
        magic, count, fields, size, _ = struct.unpack_from("<4s4I", raw)
        assert magic == b"WDBC" and fields == 14 and size == 56
        rows = list(struct.iter_unpack("<14I", raw[20:20 + count * size]))
        gift = next(row for row in rows if row[1] == 11760 and row[2] == 814280)
        values = [gift[i] for i in (0, 1, 2, 3, 4, 7, 8, 9, 10, 11)]
        code += "SkillLineAbilityEntry gift{" + ",".join(str(value) + "u" for value in values) + "};\n"
        code += "assert(AscensionRacialAbilities::CanLearn(gift,RACE_DRAENEI,CLASS_NECROMANCER));\n"
        raw = args.dbc_dir.joinpath("Spell.dbc").read_bytes()
        magic, count, fields, size, _ = struct.unpack_from("<4s4I", raw)
        assert magic == b"WDBC" and fields == 234 and size == 936
        spells = {row[0]: row for row in struct.iter_unpack("<234I", raw[20:20 + count * size])}
        torrents = [row for row in rows if row[1] == 756 and row[2] in (28730, *range(814286, 814293))]
        code += "uint32 witchHunterTorrents=0;\n"
        for row in torrents:
            values = [row[i] for i in (0, 1, 2, 3, 4, 7, 8, 9, 10, 11)]
            code += "{SkillLineAbilityEntry torrent{" + ",".join(str(v) + "u" for v in values) + "};\n"
            code += "if(AscensionRacialAbilities::CanLearn(torrent,RACE_BLOODELF,CLASS_WITCH_HUNTER))"
            code += "{++witchHunterTorrents;assert(torrent.Spell==28730);}}\n"
        code += "assert(witchHunterTorrents==1);\n"
        assert spells[28730][117] == 828730
        assert spells[828730][71:74] == (30, 30, 137)
        assert spells[828730][110:113] == (3, 1, 0)
        for spell_id in (814280, 814281, 814282):
            assert spells[spell_id][95] == 8
            assert not spells[spell_id][211] & 0x80000000
    code += "}\n"

    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="coa-racial-quests-") as directory:
        out = Path(directory)
        cpp = out / "cases.cpp"
        cpp.write_text(code, encoding="utf-8")
        executable = out / ("cases.exe" if os.name == "nt" else "cases")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", str(cpp), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)
    print("PASS: racial predicates, Witch Hunter Torrent, Draenei Gift and rescue admission")


if __name__ == "__main__":
    main()
