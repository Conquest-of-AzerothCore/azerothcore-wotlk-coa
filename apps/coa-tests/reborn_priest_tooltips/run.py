CLI_DESCRIPTION = """Check that Warcraft Reborn Priest spells are wired to do what their own tooltips say."""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402
from coa_talent_catalog import STUBS  # noqa: E402

method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
PENDING = ROOT / "data/sql/updates/pending_db_world"
EFFECT, AURA, MISC, MASK, FAMILY, FAMILY_FLAGS = 71, 95, 110, 122, 208, 209
HEAL = 10
SPELL_AURA_ADD_PCT_MODIFIER, SPELLMOD_DAMAGE = 108, 0
REBORN_SPELL_OFFSET = 1100000
HOLY_NOVA = {15237: 23455, 15430: 23458, 15431: 23459, 27799: 27803, 27800: 27804, 27801: 27805, 25331: 25329,
             48077: 48075, 48078: 48076}
DIVINE_PROVIDENCE = (1147562, 1147564, 1147565)
PRAYER_OF_MENDING_HEAL = 1133110
MIND_SEAR_STOCK_TOP, MIND_SEAR_REBORN_TOP = 53023, 1148051
PRIEST_TRAINER_ROWS = [(48045, 75), (MIND_SEAR_STOCK_TOP, 80)]


def read_dbc(path):
    data = path.read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    rows = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        rows[record[0]] = record
    return rows


def source(name):
    path = ROOT / name
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def body(text_, signature):
    return method(text_, signature) if signature in text_ else ""


def sql_rows(table):
    rows = []
    for path in sorted(PENDING.glob("rev_*.sql")):
        sql = path.read_text(encoding="utf-8")
        if not sql.startswith("-- Warcraft Reborn Priest:"):
            continue
        for block in re.findall(r"INSERT INTO `" + table + r"`[^;]*;", sql):
            values = block.split("VALUES", 1)[1]
            rows += [row.split(", ") for row in re.findall(r"^\((-?\d+(?:, -?\d+)*)", values, re.M)]
    return rows


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_client(directory):
    spells = read_dbc(directory / "Spell.dbc")
    trainer = {row[1] for row in read_dbc(directory / "NPCTrainer.dbc").values()}
    problems = []
    for trigger, heal in HOLY_NOVA.items():
        for spell in (trigger + REBORN_SPELL_OFFSET, heal + REBORN_SPELL_OFFSET):
            if spell not in spells:
                problems.append(f"Reborn Holy Nova spell {spell} is missing")
        if heal + REBORN_SPELL_OFFSET in spells and spells[heal + REBORN_SPELL_OFFSET][EFFECT] != HEAL:
            problems.append(f"{heal + REBORN_SPELL_OFFSET} is no longer a heal")
    pom = spells[PRAYER_OF_MENDING_HEAL][FAMILY_FLAGS:FAMILY_FLAGS + 3]
    for spell in DIVINE_PROVIDENCE:
        row = spells[spell]
        mask = row[MASK:MASK + 3]
        if row[AURA] != SPELL_AURA_ADD_PCT_MODIFIER or row[MISC] != SPELLMOD_DAMAGE:
            problems.append(f"Divine Providence {spell} effect 1 is no longer the healing modifier")
        if any(m & f for m, f in zip(mask, pom)):
            problems.append(f"Divine Providence {spell} already covers Prayer of Mending's heal")
    if MIND_SEAR_REBORN_TOP in trainer:
        problems.append("Mind Sear rank 7 is now in NPCTrainer.dbc")
    if MIND_SEAR_STOCK_TOP + REBORN_SPELL_OFFSET in spells:
        problems.append("stock Mind Sear rank 2 now has a Reborn copy")
    return check(not problems, "the client rows match what the fixes assume (Holy Nova heals, Divine Providence masks, "
                 "Mind Sear rank 7 outside NPCTrainer.dbc)", problems)


def check_wiring():
    links = {(int(row[0]), int(row[1])) for row in sql_rows("spell_linked_spell")}
    problems = [f"Reborn Holy Nova {trigger + REBORN_SPELL_OFFSET} does not heal with {heal + REBORN_SPELL_OFFSET}"
                for trigger, heal in HOLY_NOVA.items()
                if (trigger + REBORN_SPELL_OFFSET, heal + REBORN_SPELL_OFFSET) not in links]
    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    problems += ["the Priest contracts are not applied"] if \
        "ApplyAscensionWarcraftRebornPriestContracts(spellInfo);" not in mechanics else []
    return check(not problems, "Reborn Holy Nova heals with its own Reborn heal spells", problems)


CONTRACTS = r"""
#include <cassert>
#include <cstdint>
#include <array>
#include <algorithm>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_ADD_PCT_MODIFIER = 108 };
enum SpellModOp { SPELLMOD_DAMAGE = 0 };
enum SpellEffIndex { EFFECT_0 = 0 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
};
struct SpellEffectInfo { AuraType ApplyAuraName = SPELL_AURA_NONE; int32 MiscValue = 0; flag96 SpellClassMask; };
struct SpellInfo { uint32 Id = 0; SpellEffectInfo Effects[3]; };
namespace AscensionWarcraftReborn
{
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornPriest.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornPriestContracts(SpellInfo* spellInfo)")
    if not apply:
        return check(False, "Divine Providence covers Prayer of Mending's heal", ["no Warcraft Reborn priest contracts"])
    constants = "\n".join(re.findall(r"^constexpr (?:uint32|std::array<uint32, \d+>) .*;", source_, re.M))
    code = CONTRACTS + constants + "\n}\n" + apply + r"""
int main()
{
    for (uint32 id : { 1147562u, 1147564u, 1147565u })
    {
        SpellInfo dp; dp.Id = id;
        dp.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER; dp.Effects[0].MiscValue = SPELLMOD_DAMAGE;
        dp.Effects[0].SpellClassMask[0] = 0x18000200; dp.Effects[0].SpellClassMask[1] = 0x4; dp.Effects[0].SpellClassMask[2] = 0x4;
        ApplyAscensionWarcraftRebornPriestContracts(&dp);
        assert(dp.Effects[0].SpellClassMask[1] & 0x20);
        assert(dp.Effects[0].SpellClassMask[0] == 0x18000200 && dp.Effects[0].SpellClassMask[2] == 0x4);
    }
    SpellInfo other; other.Id = 47565;
    other.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    ApplyAscensionWarcraftRebornPriestContracts(&other);
    assert(other.Effects[0].SpellClassMask[1] == 0);
}
"""
    ok = compile_and_run(code, "coa-reborn-priest-contracts-")
    return check(ok, "Divine Providence's healing bonus covers Prayer of Mending's heal")


TRAINER = r"""
#include "AscensionWarcraftRebornRules.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include <cstdio>
#include <unordered_map>
using namespace AscensionWarcraftReborn;
int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    Data data;
    if (!LoadData(data)) return 2;
    std::unordered_map<std::uint32_t, std::uint32_t> levels;
    ClientDBC spells;
    if (!spells.Load(DbcDirectory + "Spell.dbc", 40)) return 3;
    for (std::uint32_t i = 0; i < spells.GetRecordCount(); ++i)
        levels[spells.GetRecord(i).GetUInt32(0)] = spells.GetRecord(i).GetUInt32(39);
    AscensionFreepick::Realm realm;
    realm.Live = true;
    realm.WarcraftReborn = true;
    std::vector<TrainerSpell> stock;
    ROWS
    auto const exists = [&levels](std::uint32_t id) { return levels.contains(id); };
    auto const reborn = [&levels](std::uint32_t id) { TrainerSpell t; t.SpellId = id; t.ReqLevel = levels[id]; return t; };
    for (TrainerSpell const& s : TrainerSpells(data, realm, 5, stock, exists, reborn))
        std::printf("%u %u\n", s.SpellId, s.ReqLevel);
    return 0;
}
"""


def check_trainer(directory):
    rows = "\n    ".join(f"{{ TrainerSpell t; t.SpellId = {spell}; t.ReqLevel = {level}; stock.push_back(t); }}"
                         for spell, level in PRIEST_TRAINER_ROWS)
    with tempfile.TemporaryDirectory(prefix="coa-reborn-priest-trainer-") as tmp:
        out = Path(tmp)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(TRAINER.replace("ROWS", rows), encoding="utf-8")
        inc = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
        src = [out / "main.cpp", ROOT / "src/server/coa/AscensionWarcraftRebornRules.cpp",
               ROOT / "src/server/coa/AscensionFreepickRules.cpp", ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        exe = out / "trainer"
        compiler = shutil.which(os.environ.get("CXX", "c++"))
        if not compiler:
            return check(False, "Mind Sear rank 7 is taught at level 80", ["no C++ compiler"])
        built = subprocess.run([compiler, "-std=c++20", "-O1", *["-I" + str(p) for p in inc], *map(str, src), "-o", str(exe)],
                               capture_output=True, text=True)
        if built.returncode:
            return check(False, "Mind Sear rank 7 is taught at level 80", [built.stderr[-1500:]])
        result = subprocess.run([str(exe), str(directory)], capture_output=True, text=True)
    listed = dict(tuple(map(int, line.split())) for line in result.stdout.split("\n") if line.strip())
    problems = []
    if listed.get(MIND_SEAR_REBORN_TOP) != 80:
        problems.append(f"Mind Sear rank 7 ({MIND_SEAR_REBORN_TOP}) is taught at {listed.get(MIND_SEAR_REBORN_TOP)}")
    if MIND_SEAR_STOCK_TOP in listed:
        problems.append(f"the stock Mind Sear rank 2 ({MIND_SEAR_STOCK_TOP}) is still sold")
    return check(result.returncode == 0 and not problems,
                 "the Warcraft Reborn priest trainer teaches Mind Sear rank 7 at level 80, not the stock rank", problems)


def compile_and_run(code, prefix):
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix=prefix) as directory:
        out = Path(directory)
        cpp, exe = out / "contracts.cpp", out / ("contracts.exe" if os.name == "nt" else "contracts")
        cpp.write_text(code, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        return subprocess.run([str(exe)], cwd=out).returncode == 0


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    results = [check_client(directory), check_wiring(), check_contracts(), check_trainer(directory)]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
