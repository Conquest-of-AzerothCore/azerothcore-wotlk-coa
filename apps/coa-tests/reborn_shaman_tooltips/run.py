CLI_DESCRIPTION = """Check that Warcraft Reborn Shaman spells are wired to do what their own tooltips say."""

import argparse
from pathlib import Path
import re
import struct
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

PENDING = ROOT / "data/sql/updates/pending_db_world"
EFFECT, BASE, AURA, MISC, TRIGGER = 71, 80, 95, 110, 116
WEAPON_PERCENT_DAMAGE, DUMMY, ENCHANT_ITEM_TEMPORARY = 31, 3, 54
REBORN_SPELL_OFFSET = 1100000
TOTEM_PAYLOADS = {1131133: 58655, 1130654: 57663, 1131129: 58646, 1131165: 58702, 1131185: 58765, 1106112: 8515}
STOCK_TOTEM_PAYLOADS = {1115447: 2895, 1105925: 8178}
LIGHTNING_SHIELD = (324, 1100324)
LIGHTNING_SHIELD_DAMAGE = (26364, 26365, 26366, 26367, 26369, 26370, 26363, 26371, 26372, 49278, 49279)
BLOODLUST = (2825, 1102825)
ROCKBITER_WEAPON, ROCKBITER_ENCHANT = 1110399, 10503
LAVA_SWEEP = 1568910
EARTHEN_GUARDIAN, EARTHEN_GUARDIAN_LINKS = 1182001, (1182006, 1182007)
SPELL_AURA_MOD_THREAT, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE = 10, 79
SCRIPTS = {(-1100324, "spell_sha_lightning_shield"), (1102825, "spell_sha_bloodlust"),
           (LAVA_SWEEP, "spell_ascension_reborn_lava_sweep")}


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


def sql_rows(table):
    rows = []
    for path in sorted(PENDING.glob("rev_*.sql")):
        sql = path.read_text(encoding="utf-8")
        if not sql.startswith("-- Warcraft Reborn Shaman: totems"):
            continue
        for block in re.findall(r"INSERT INTO `" + table + r"`[^;]*;", sql):
            if "VALUES" in block:
                values = block.split("VALUES", 1)[1]
                rows += [re.findall(r"-?\d+|'[^']*'", row) for row in re.findall(r"^\((.*)\)[,;]$", values, re.M)]
            else:
                rows += [re.findall(r"^SELECT (-?\d+)", block, re.M)]
    return rows


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def layout(row):
    return row[EFFECT:EFFECT + 3], row[AURA:AURA + 3]


def check_client(directory):
    spells = read_dbc(directory / "Spell.dbc")
    enchants = read_dbc(directory / "SpellItemEnchantment.dbc")
    problems = [f"Reborn totem payload {stock + REBORN_SPELL_OFFSET} is missing"
                for stock in TOTEM_PAYLOADS.values() if stock + REBORN_SPELL_OFFSET not in spells]
    problems += [f"Reborn Lightning Shield damage {spell + REBORN_SPELL_OFFSET} is missing"
                 for spell in LIGHTNING_SHIELD_DAMAGE if spell + REBORN_SPELL_OFFSET not in spells]
    for stock, reborn in (LIGHTNING_SHIELD, BLOODLUST):
        if reborn not in spells or layout(spells[stock]) == layout(spells[reborn]):
            problems.append(f"{reborn} now shares the layout of {stock} and takes its stock scripts by itself")
    rockbiter = spells.get(ROCKBITER_WEAPON)
    if not rockbiter or rockbiter[EFFECT + 1] != ENCHANT_ITEM_TEMPORARY or rockbiter[MISC + 1] != ROCKBITER_ENCHANT \
            or ROCKBITER_ENCHANT not in enchants:
        problems.append(f"Rockbiter Weapon {ROCKBITER_WEAPON} no longer enchants with {ROCKBITER_ENCHANT}")
    sweep = spells.get(LAVA_SWEEP)
    if not sweep or sweep[EFFECT] != WEAPON_PERCENT_DAMAGE or sweep[EFFECT + 1] != DUMMY:
        problems.append(f"Lava Sweep {LAVA_SWEEP} is no longer weapon damage with a dummy one-handed bonus")
    auras = {aura for spell in EARTHEN_GUARDIAN_LINKS if spell in spells for aura in spells[spell][AURA:AURA + 3]}
    if not {SPELL_AURA_MOD_THREAT, SPELL_AURA_MOD_DAMAGE_PERCENT_DONE} <= auras:
        problems.append("the Earthen Guardian companion spells no longer carry its threat and damage done auras")
    if SPELL_AURA_MOD_THREAT in spells[EARTHEN_GUARDIAN][AURA:AURA + 3]:
        problems.append("Earthen Guardian now carries its own threat aura")
    return check(not problems, "the client rows match what the fixes assume (Reborn payloads, Lightning Shield damage, "
                 "Rockbiter enchantment, Lava Sweep effects, Earthen Guardian companions)", problems)


def check_wiring():
    totems = {(int(row[0]), int(row[1])): int(row[2]) for row in sql_rows("creature_template_spell")}
    problems = [f"Reborn totem {creature} still casts stock {stock}"
                for creature, stock in TOTEM_PAYLOADS.items()
                if totems.get((creature, 0)) != stock + REBORN_SPELL_OFFSET]
    problems += [f"Reborn totem {creature} no longer casts stock {stock}"
                 for creature, stock in STOCK_TOTEM_PAYLOADS.items() if (creature, 0) in totems]
    scripts = {(int(row[0]), row[1].strip("'")) for row in sql_rows("spell_script_names")}
    problems += [f"{spell} is not bound to {name}" for spell, name in sorted(SCRIPTS - scripts)]
    links = {(int(row[0]), int(row[1]), int(row[2])) for row in sql_rows("spell_linked_spell")}
    problems += [f"Earthen Guardian does not apply {spell}" for spell in EARTHEN_GUARDIAN_LINKS
                 if (EARTHEN_GUARDIAN, spell, 2) not in links]
    procs = {int(row[0]) for row in sql_rows("spell_proc")}
    problems += ["the Reborn Lightning Shield chain has no proc row"] if -LIGHTNING_SHIELD[1] not in procs else []
    return check(not problems, "Reborn totems cast their Reborn payloads; Reborn Lightning Shield, Bloodlust and "
                 "Lava Sweep have their scripts; Earthen Guardian applies its companion auras", problems)


def check_scripts():
    shaman = source("src/server/scripts/Spells/spell_shaman.cpp")
    effects = source("src/server/game/Spells/SpellEffects.cpp")
    reborn = source("src/server/coa/AscensionWarcraftRebornShaman.cpp")
    problems = []
    if not re.search(r"GetSpellTwinSource\(spellInfo->Id\)\);\s*if \(!firstRankSpellInfo \|\| !stockRank \|\| "
                     r"!stockRank->IsRankOf\(firstRankSpellInfo\)\)", shaman):
        problems.append("Fire Nova does not accept the Reborn ranks")
    if "GetSpellTwinFor(sSpellMgr->GetSpellWithRank(SPELL_SHAMAN_FIRE_NOVA_TRIGGERED_R1, rank), spellId)" not in shaman:
        problems.append("Reborn Fire Nova does not trigger its Reborn nova")
    if "GetSpellTwinFor(sSpellMgr->GetSpellWithRank(SPELL_SHAMAN_LIGHTNING_SHIELD_DAMAGE_R1, rank), aurEff->GetId())" \
            not in shaman:
        problems.append("Reborn Lightning Shield does not strike with its Reborn damage spell")
    if not re.search(r"SpellFamilyFlags\[0\] & 0x400000 &&\s*sSpellMgr->GetSpellTwinSource\(m_spellInfo->Id\) == "
                     r"m_spellInfo->Id\)", effects):
        problems.append("Reborn Rockbiter Weapon still goes through the legacy rank table")
    totem = shaman.split("class spell_sha_healing_stream_totem", 1)[-1].split("void Register()", 1)[0]
    if "damage = triggeringSpell->Effects[EFFECT_0].CalcValue(owner);" not in totem:
        problems.append("Reborn Healing Stream Totem does not heal for its own tooltip value")
    if "SHAMAN_ICON_ID_RESTORATIVE_TOTEMS" in totem or "SPELL_SHAMAN_GLYPH_OF_HEALING_STREAM_TOTEM, EFFECT_0" in totem:
        problems.append("Healing Stream Totem applies Restorative Totems and its glyph again on top of the core")
    if "RegisterSpellScript(spell_ascension_reborn_lava_sweep);" not in reborn:
        problems.append("Lava Sweep has no script")
    return check(not problems, "Fire Nova, Lightning Shield, Rockbiter Weapon and Healing Stream handle the Reborn ranks; "
                 "Lava Sweep has its script", problems)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    results = [check_client(directory), check_wiring(), check_scripts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
