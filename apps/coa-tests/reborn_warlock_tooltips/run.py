CLI_DESCRIPTION = """Check that Warcraft Reborn Warlock spells are wired to do what their own tooltips say."""

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

method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
EFFECT, AURA, MISC, MASK, FAMILY_FLAGS = 71, 95, 110, 122, 209
BASE, REAL_POINTS_PER_LEVEL, DURATION = 80, 77, 40
SPELL_EFFECT_APPLY_AURA = 6
SPELL_AURA_DUMMY, SPELL_AURA_PERIODIC_DAMAGE = 4, 3
SPELL_AURA_ADD_FLAT_MODIFIER, SPELL_AURA_ADD_PCT_MODIFIER = 107, 108
CONFLAGRATE, CONFLAGRATE_DOT = 1117962, 1217962
BACKDRAFT_RANK_3 = 1154277
REIGN_OF_DREAD = 1118800
SOUL_GORGE = (1161363, 1161372)
LIFE_TAP = (1101455, 1101456, 1111687, 1111688, 1111689, 1127222)
MIGRATION = "data/sql/updates/pending_db_world/rev_20261016_30_reborn_warlock_tooltips.sql"


def read_dbc(path):
    data = path.read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    rows = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        rows[record[0]] = record
    return rows


def as_float(value):
    return struct.unpack("<f", struct.pack("<I", value))[0]


def source(name):
    path = ROOT / name
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def body(text_, signature):
    return method(text_, signature) if signature in text_ else ""


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_client(directory):
    spells = read_dbc(directory / "Spell.dbc")
    problems = []
    conflagrate = spells.get(CONFLAGRATE)
    if not conflagrate or conflagrate[EFFECT + 1] != SPELL_EFFECT_APPLY_AURA or conflagrate[AURA + 1] != SPELL_AURA_DUMMY:
        problems.append("Conflagrate effect 2 is no longer the dummy aura the contract turns periodic")
    elif spells.get(CONFLAGRATE_DOT, (0,) * 300)[DURATION] != 32:
        problems.append("the Conflagrate duration index 32 (6 sec) changed")
    backdraft = spells.get(BACKDRAFT_RANK_3)
    if not backdraft or backdraft[AURA + 2] != SPELL_AURA_ADD_FLAT_MODIFIER:
        problems.append("Backdraft rank 3's zero crit modifier is gone")
    if any(spells[spell][FAMILY_FLAGS + 2] & 0x10000 == 0 for spell in SOUL_GORGE if spell in spells):
        problems.append("Soul Gorge no longer carries family flag [2] 0x10000")
    if REIGN_OF_DREAD in spells and any(spells[REIGN_OF_DREAD][FAMILY_FLAGS:FAMILY_FLAGS + 3]):
        problems.append("Reign of Dread now has family flags: Nemesis could cover it by mask")
    if any(as_float(spells[spell][REAL_POINTS_PER_LEVEL]) == 0 for spell in LIFE_TAP if spell in spells):
        problems.append("a Reborn Life Tap rank no longer grows per level")
    return check(not problems, "the client rows match what the fixes assume (Conflagrate dummy, Backdraft r3 zero crit, "
                 "Soul Gorge flag, flagless Reign of Dread, Life Tap per-level growth)", problems)


def check_twins():
    problems = []
    fear = body(source("src/server/game/Spells/Auras/SpellAuras.cpp"),
                "void Aura::HandleAuraSpecificMods(AuraApplication const* aurApp, Unit* caster, bool apply, bool onReapply)")
    if "GetSpellTwinFor(60947, aurEff->GetId())" not in fear or "GetSpellTwinFor(60946, aurEff->GetId())" not in fear:
        problems.append("Improved Fear does not cast the Nightmare of its own family")
    shadowflame = source("src/server/scripts/Spells/spell_warlock.cpp")
    if not re.search(r"GetSpellTwinFor\(\s*sSpellMgr->GetSpellTwinSource\(GetSpellInfo\(\)->Id\) == 47897 \? 47960 : 61291",
                     shadowflame):
        problems.append("Shadowflame does not cast the burn of its own family")
    migration = source(MIGRATION)
    for row in ("SELECT -1147258,", "SELECT -1147201,", "(1123785, 0, 1100416, 1123759)", "(1123825, 0, 1117252, 1135706)",
                "(1119028, 0, 0, 1125228)", "(1701521, 0, 0, 1701522)",
                "(1701522, 'spell_ascension_reborn_summoners_armor_demon')",
                "(1118800, 'spell_ascension_reborn_reign_of_dread')"):
        if row not in migration:
            problems.append(f"{MIGRATION} lacks {row}")
    return check(not problems, "Reborn Nightmare, Shadowflame burn, Backdraft/Everlasting Affliction procs and the Reborn "
                 "demon auras are wired", problems)


CONTRACTS = r"""
#include <cassert>
#include <cstdint>
#include <cstddef>
#include <array>
#include <algorithm>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_PERIODIC_DAMAGE = 3, SPELL_AURA_DUMMY = 4,
    SPELL_AURA_ADD_FLAT_MODIFIER = 107, SPELL_AURA_ADD_PCT_MODIFIER = 108,
    SPELL_AURA_MOD_ATTACKER_SPELL_CRIT_CHANCE = 179, SPELL_AURA_MOD_ATTACKER_MELEE_CRIT_CHANCE = 187 };
enum SpellEffects { SPELL_EFFECT_APPLY_AURA = 6 };
enum SpellModOp { SPELLMOD_DAMAGE = 0, SPELLMOD_THREAT = 2, SPELLMOD_CRITICAL_CHANCE = 7, SPELLMOD_ALL_EFFECTS = 8,
    SPELLMOD_NOT_LOSE_CASTING_TIME = 9, SPELLMOD_DOT = 22 };
enum SpellEffIndex { EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
};
struct SpellEffectInfo
{
    uint32 Effect = 0; AuraType ApplyAuraName = SPELL_AURA_NONE; int32 MiscValue = 0; int32 BasePoints = 0;
    int32 DieSides = 1; int32 Amplitude = 0; float RealPointsPerLevel = 0; flag96 SpellClassMask;
    int32 CalcValue() const { return BasePoints + DieSides; }
};
struct SpellDurationEntry { uint32 ID = 0; };
struct SpellInfo
{
    uint32 Id = 0; uint32 MaxLevel = 0; uint32 BaseLevel = 0; uint32 SpellLevel = 0;
    SpellDurationEntry const* DurationEntry = nullptr; SpellEffectInfo Effects[3];
};
struct SpellEntry { uint32 MaxLevel = 26; uint32 BaseLevel = 16; uint32 SpellLevel = 16;
    std::array<float, 3> EffectRealPointsPerLevel = { 3.0f, 0.0f, 0.0f }; };
struct DurationStore
{
    SpellDurationEntry entry;
    SpellDurationEntry const* LookupEntry(uint32 id) { entry.ID = id; return &entry; }
} sSpellDurationStore;
struct SpellStore
{
    SpellEntry entry;
    SpellEntry const* LookupEntry(uint32) { return &entry; }
} sSpellStore;
namespace AscensionWarcraftReborn
{
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornWarlock.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornWarlockContracts(SpellInfo* spellInfo)")
    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    if not apply or "ApplyAscensionWarcraftRebornWarlockContracts(spellInfo);" not in mechanics:
        return check(False, "the Warlock contracts follow the tooltips", ["the Warlock contracts are not applied"])
    constants = "\n".join(re.findall(r"^constexpr (?:u?int32|std::array<uint32, \d+>) .*;", source_, re.M))
    contains = body(source_, "bool Contains(std::array<uint32, N> const& ids, uint32 id)")
    code = CONTRACTS + constants + "\ntemplate <std::size_t N>\n" + contains + "\n}\n" + apply + r"""
SpellInfo Modifier(uint32 id, int32 misc, uint32 mask0, uint32 mask1, uint32 mask2, SpellEffIndex index = EFFECT_0)
{
    SpellInfo info; info.Id = id;
    info.Effects[index].Effect = SPELL_EFFECT_APPLY_AURA;
    info.Effects[index].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    info.Effects[index].MiscValue = misc;
    info.Effects[index].SpellClassMask[0] = mask0; info.Effects[index].SpellClassMask[1] = mask1;
    info.Effects[index].SpellClassMask[2] = mask2;
    return info;
}

int main()
{
    SpellInfo conflagrate; conflagrate.Id = 1117962;
    conflagrate.Effects[1].Effect = SPELL_EFFECT_APPLY_AURA; conflagrate.Effects[1].ApplyAuraName = SPELL_AURA_DUMMY;
    ApplyAscensionWarcraftRebornWarlockContracts(&conflagrate);
    assert(conflagrate.Effects[1].ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE && conflagrate.Effects[1].Amplitude == 2000);
    assert(conflagrate.DurationEntry && conflagrate.DurationEntry->ID == 32);

    SpellInfo backdraft; backdraft.Id = 1154277;
    backdraft.Effects[2].Effect = SPELL_EFFECT_APPLY_AURA; backdraft.Effects[2].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    backdraft.Effects[2].MiscValue = SPELLMOD_CRITICAL_CHANCE; backdraft.Effects[2].BasePoints = -1;
    ApplyAscensionWarcraftRebornWarlockContracts(&backdraft);
    assert(backdraft.Effects[2].Effect == 0 && backdraft.Effects[2].ApplyAuraName == SPELL_AURA_NONE);

    for (auto [id, melee, spell] : { std::array<int32, 3>{ 1130319, -3, -2 }, std::array<int32, 3>{ 1130321, -7, -4 } })
    {
        SpellInfo resilience; resilience.Id = uint32(id);
        resilience.Effects[0].ApplyAuraName = SPELL_AURA_MOD_ATTACKER_MELEE_CRIT_CHANCE; resilience.Effects[0].BasePoints = melee;
        resilience.Effects[2].ApplyAuraName = SPELL_AURA_MOD_ATTACKER_SPELL_CRIT_CHANCE; resilience.Effects[2].BasePoints = spell;
        ApplyAscensionWarcraftRebornWarlockContracts(&resilience);
        assert(resilience.Effects[2].BasePoints == melee);
    }

    SpellInfo contagion; contagion.Id = 1130062;
    contagion.Effects[0].MiscValue = SPELLMOD_DOT; contagion.Effects[0].BasePoints = 5;
    contagion.Effects[1].MiscValue = SPELLMOD_DAMAGE; contagion.Effects[1].BasePoints = 2;
    ApplyAscensionWarcraftRebornWarlockContracts(&contagion);
    assert(contagion.Effects[1].BasePoints == 5);

    SpellInfo drainSoul = Modifier(1118372, SPELLMOD_THREAT, 0, 0x40f1b, 0x100, EFFECT_1);
    ApplyAscensionWarcraftRebornWarlockContracts(&drainSoul);
    assert(drainSoul.Effects[1].SpellClassMask[0] == 0x48c41a && drainSoul.Effects[1].SpellClassMask[1] == 0x40f1b &&
        drainSoul.Effects[1].SpellClassMask[2] == 0x900);

    SpellInfo concentration = Modifier(1117784, SPELLMOD_NOT_LOSE_CASTING_TIME, 0x4018, 0, 0);
    ApplyAscensionWarcraftRebornWarlockContracts(&concentration);
    assert(concentration.Effects[0].SpellClassMask[1] == 0x40100);

    SpellInfo emberstorm = Modifier(1117958, SPELLMOD_DAMAGE, 0x803e5, 0x8790d0, 0x1000102);
    emberstorm.Effects[1].MiscValue = SPELLMOD_DOT;
    emberstorm.Effects[1].SpellClassMask[0] = 0x44ee; emberstorm.Effects[1].SpellClassMask[1] = 0x818002;
    ApplyAscensionWarcraftRebornWarlockContracts(&emberstorm);
    assert(emberstorm.Effects[0].SpellClassMask[2] == (0x1000102u | 0x10000u));
    assert(emberstorm.Effects[1].SpellClassMask[1] == (0x818002u | 0x110u));

    SpellInfo mastery = Modifier(1118275, SPELLMOD_DAMAGE, 0x80091, 0x451910, 0);
    ApplyAscensionWarcraftRebornWarlockContracts(&mastery);
    assert(mastery.Effects[0].SpellClassMask[2] == 0x10000);

    SpellInfo aegis = Modifier(1130145, SPELLMOD_ALL_EFFECTS, 0, 0x20000020, 0);
    ApplyAscensionWarcraftRebornWarlockContracts(&aegis);
    assert(aegis.Effects[0].SpellClassMask[2] == 0x10);

    SpellInfo lifeTap; lifeTap.Id = 1101455; lifeTap.MaxLevel = 16; lifeTap.BaseLevel = 6; lifeTap.SpellLevel = 6;
    ApplyAscensionWarcraftRebornWarlockContracts(&lifeTap);
    assert(lifeTap.Effects[0].RealPointsPerLevel == 3.0f && lifeTap.MaxLevel == 26 && lifeTap.BaseLevel == 16 &&
        lifeTap.SpellLevel == 16);

    SpellInfo stockLifeTap; stockLifeTap.Id = 1455; stockLifeTap.MaxLevel = 16;
    ApplyAscensionWarcraftRebornWarlockContracts(&stockLifeTap);
    assert(stockLifeTap.MaxLevel == 16 && stockLifeTap.Effects[0].RealPointsPerLevel == 0.0f);

    SpellInfo stock = Modifier(18275, SPELLMOD_DAMAGE, 0x80091, 0, 0);
    ApplyAscensionWarcraftRebornWarlockContracts(&stock);
    assert(stock.Effects[0].SpellClassMask[2] == 0);
}
"""
    return check(compile_and_run(code, "coa-reborn-warlock-contracts-"),
                 "Conflagrate burns on, Backdraft r3 keeps three charges, Demonic Resilience and Contagion carry their "
                 "full values, the talent masks cover what their tooltips name, Life Tap grows per level")


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
    results = [check_client(directory), check_twins(), check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
