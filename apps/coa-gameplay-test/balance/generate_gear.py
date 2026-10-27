CLI_DESCRIPTION = """Regenerate apps/coa-gameplay-test/balance/gear.json from item_pool.json and catalog.json.

item_pool.json is a committed snapshot of item_template (class IN (2, 4), ScalingStatDistribution != 0,
Quality IN (4, 6, 7), AllowableClass=-1, plus a plain-necklace fallback) joined with
ScalingStatDistribution.dbc's StatMod and MaxLevel, refreshed against the configured world database with
refresh_item_pool.py. Weapon/shield proficiency per class is derived from
src/server/coa/AscensionLiveBaselineData.h's AscensionLiveBaseline::Proficiencies, the table
AscensionCompatHandler::SynchronizeProficiencies enforces at runtime (talent-gated proficiencies in
AscensionCustomClassData.h's TalentProficiencies are excluded: gear.json is shared across all specs of a
class, so only a proficiency every spec keeps is safe to equip). This script is a pure function of that
snapshot, of catalog.json and of that header; it runs without a database or a DBC directory and is
deterministic. It excludes any ScalingStatDistribution candidate whose MaxLevel is below the level bucket
being generated: CanEquipItem rejects such an item above that level (Player.cpp), the exact defect a level 60
"Necklace of the Sunken Empire" (ssd MaxLevel 55) hit before this check existed.
"""

import argparse
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[2]
ITEM_POOL_PATH = HERE / "item_pool.json"
CATALOG_PATH = HERE / "catalog.json"
GEAR_PATH = HERE / "gear.json"
LIVE_BASELINE_PATH = REPO_ROOT / "src/server/coa/AscensionLiveBaselineData.h"

LEVELS = (20, 40, 60)
QUALITY_PRIORITY = (7, 6, 4)

EQUIPMENT_SLOT_HEAD = 0
EQUIPMENT_SLOT_NECK = 1
EQUIPMENT_SLOT_SHOULDERS = 2
EQUIPMENT_SLOT_CHEST = 4
EQUIPMENT_SLOT_WAIST = 5
EQUIPMENT_SLOT_LEGS = 6
EQUIPMENT_SLOT_FEET = 7
EQUIPMENT_SLOT_WRISTS = 8
EQUIPMENT_SLOT_HANDS = 9
EQUIPMENT_SLOT_FINGER1 = 10
EQUIPMENT_SLOT_FINGER2 = 11
EQUIPMENT_SLOT_TRINKET1 = 12
EQUIPMENT_SLOT_TRINKET2 = 13
EQUIPMENT_SLOT_BACK = 14
EQUIPMENT_SLOT_MAINHAND = 15
EQUIPMENT_SLOT_OFFHAND = 16

ARMOR_SUBCLASS = {"cloth": 1, "leather": 2, "mail": 3, "plate": 4}

ARMOR_SLOTS = (
    ("head", ((1, "material"),), EQUIPMENT_SLOT_HEAD),
    ("neck", ((2, "generic"),), EQUIPMENT_SLOT_NECK),
    ("shoulders", ((3, "material"),), EQUIPMENT_SLOT_SHOULDERS),
    ("back", ((16, "cloak"),), EQUIPMENT_SLOT_BACK),
    ("chest", ((5, "material"), (20, "material")), EQUIPMENT_SLOT_CHEST),
    ("wrist", ((9, "material"),), EQUIPMENT_SLOT_WRISTS),
    ("hands", ((10, "material"),), EQUIPMENT_SLOT_HANDS),
    ("waist", ((6, "material"),), EQUIPMENT_SLOT_WAIST),
    ("legs", ((7, "material"),), EQUIPMENT_SLOT_LEGS),
    ("feet", ((8, "material"),), EQUIPMENT_SLOT_FEET),
)

PROFICIENCY_TABLE_PATTERN = re.compile(r"Proficiencies\s*=\s*\{\{(.*?)\}\};", re.DOTALL)
PROFICIENCY_ROW_PATTERN = re.compile(r"\{\s*(\d+)\s*,\s*\d+\s*,\s*(\d+)\s*\}")


def load_class_proficiency_spells(path=LIVE_BASELINE_PATH):
    text = path.read_text(encoding="utf-8")
    table = PROFICIENCY_TABLE_PATTERN.search(text)
    if table is None:
        raise SystemExit(f"could not find AscensionLiveBaseline::Proficiencies in {path}")
    rows = PROFICIENCY_ROW_PATTERN.findall(table.group(1))
    if not rows:
        raise SystemExit(f"found no proficiency rows in {path}")
    return tuple((int(class_id), int(spell)) for class_id, spell in rows)


CLASS_PROFICIENCY_SPELLS = load_class_proficiency_spells()

PROFICIENCY_SPELL_SKILL = {
    196: "Axe", 197: "Axe2H", 198: "Mace", 199: "Mace2H", 200: "Polearm", 201: "Sword",
    202: "Sword2H", 227: "Staff", 264: "Bow", 266: "Gun", 750: "PlateMail", 1180: "Dagger",
    2567: "Thrown", 5009: "Wand", 5011: "Crossbow", 8737: "Mail", 9077: "Leather", 9078: "Cloth",
    9116: "Shield", 15590: "FistWeapon",
}

WEAPON_SUBCLASS = {
    "Axe": 0, "Axe2H": 1, "Bow": 2, "Gun": 3, "Mace": 4, "Mace2H": 5, "Polearm": 6, "Sword": 7,
    "Sword2H": 8, "Staff": 10, "FistWeapon": 13, "Dagger": 15, "Thrown": 16, "Crossbow": 18, "Wand": 19,
}

ONE_HAND_PRIORITY = ("Sword", "Mace", "Axe", "Dagger", "FistWeapon")
TWO_HAND_PRIORITY = ("Polearm", "Sword2H", "Axe2H", "Mace2H", "Staff")


def class_proficiencies():
    by_class = {}
    for class_id, spell in CLASS_PROFICIENCY_SPELLS:
        by_class.setdefault(class_id, set()).add(PROFICIENCY_SPELL_SKILL[spell])
    return by_class


def load_pool():
    return json.loads(ITEM_POOL_PATH.read_text(encoding="utf-8"))["items"]


def eligible(pool, level, inventory_type, item_class, subclass=None):
    rows = [row for row in pool if row["inventory_type"] == inventory_type and row["class"] == item_class
            and row["required_level"] <= level and row.get("max_level", 999) >= level]
    if subclass is not None:
        rows = [row for row in rows if row["subclass"] == subclass]
    return rows


def pick(rows, stat):
    for quality in QUALITY_PRIORITY:
        at_quality = [row for row in rows if row["quality"] == quality]
        if not at_quality:
            continue
        tagged = sorted((row for row in at_quality if stat and stat in row["stats"]), key=lambda row: row["entry"])
        if tagged:
            return tagged[0]
        untagged = sorted((row for row in at_quality if not row["stats"]), key=lambda row: row["entry"])
        if untagged:
            return untagged[0]
        any_row = sorted(at_quality, key=lambda row: row["entry"])
        if any_row:
            return any_row[0]
    return None


def pick_by_item_level(rows, level):
    with_item_level = [row for row in rows if row.get("item_level")]
    if not with_item_level:
        return None
    return min(with_item_level, key=lambda row: (abs(row["item_level"] - level), row["entry"]))


def pick_two(rows, stat):
    for quality in QUALITY_PRIORITY:
        at_quality = [row for row in rows if row["quality"] == quality]
        tagged = sorted((row for row in at_quality if stat and stat in row["stats"]), key=lambda row: row["entry"])
        untagged = sorted((row for row in at_quality if not row["stats"]), key=lambda row: row["entry"])
        ordered = tagged + untagged
        if len(ordered) >= 2:
            return [ordered[0], ordered[1]]
        if len(ordered) == 1:
            return [ordered[0], ordered[0]]
    return None


def subclass_for(kind, armor):
    if kind == "material":
        return ARMOR_SUBCLASS[armor]
    if kind == "cloak":
        return 1
    return 0


def build_armor_kit(pool, level, armor, stat):
    kit = []
    missing = []
    for slot_name, candidates, equip_slot in ARMOR_SLOTS:
        row = None
        all_rows = []
        for inventory_type, kind in candidates:
            rows = eligible(pool, level, inventory_type, 4, subclass_for(kind, armor))
            all_rows.extend(rows)
            row = pick(rows, stat)
            if row is not None:
                break
        if row is None:
            row = pick_by_item_level(all_rows, level)
        if row is None:
            missing.append(slot_name)
            continue
        kit.append({"item": row["entry"], "slot": equip_slot})
    finger_rows = eligible(pool, level, 11, 4, 0)
    fingers = pick_two(finger_rows, stat)
    if fingers is None:
        missing.append("finger1/finger2")
    else:
        kit.append({"item": fingers[0]["entry"], "slot": EQUIPMENT_SLOT_FINGER1})
        kit.append({"item": fingers[1]["entry"], "slot": EQUIPMENT_SLOT_FINGER2})
    trinket_rows = eligible(pool, level, 12, 4, 0)
    trinkets = pick_two(trinket_rows, stat)
    if trinkets is None:
        missing.append("trinket1/trinket2")
    else:
        kit.append({"item": trinkets[0]["entry"], "slot": EQUIPMENT_SLOT_TRINKET1})
        kit.append({"item": trinkets[1]["entry"], "slot": EQUIPMENT_SLOT_TRINKET2})
    if missing:
        raise SystemExit(f"No candidate item for {armor}/{stat} at level {level}: {', '.join(missing)}")
    return kit


def build_weapon_kit(pool, level, class_id, group, stat, proficiency):
    kit = []
    has_shield = "Shield" in proficiency

    def one_hand(priority):
        for name in priority:
            if name not in proficiency:
                continue
            rows = eligible(pool, level, 13, 2, WEAPON_SUBCLASS[name]) + \
                eligible(pool, level, 21, 2, WEAPON_SUBCLASS[name])
            row = pick(rows, stat)
            if row is not None:
                return row
        return None

    def two_hand(priority):
        for name in priority:
            if name not in proficiency:
                continue
            row = pick(eligible(pool, level, 17, 2, WEAPON_SUBCLASS[name]), stat)
            if row is not None:
                return row
        return None

    def shield():
        return pick(eligible(pool, level, 14, 4, 6), stat)

    def holdable():
        return pick(eligible(pool, level, 23, 4, 0), stat)

    if stat == "intellect":
        main = one_hand(ONE_HAND_PRIORITY)
        if main is not None:
            kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
            off = shield() if (group == "tank" and has_shield) else holdable()
            if off is not None:
                kit.append({"item": off["entry"], "slot": EQUIPMENT_SLOT_OFFHAND})
        else:
            main = two_hand(("Staff",) + TWO_HAND_PRIORITY)
            if main is not None:
                kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
    elif group == "tank":
        main = one_hand(ONE_HAND_PRIORITY)
        if main is not None:
            kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
            off = shield() if has_shield else holdable()
            if off is not None:
                kit.append({"item": off["entry"], "slot": EQUIPMENT_SLOT_OFFHAND})
        else:
            main = two_hand(TWO_HAND_PRIORITY)
            if main is not None:
                kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
    else:
        main = two_hand(TWO_HAND_PRIORITY)
        if main is not None:
            kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
        else:
            main = one_hand(ONE_HAND_PRIORITY)
            if main is not None:
                kit.append({"item": main["entry"], "slot": EQUIPMENT_SLOT_MAINHAND})
                off = holdable()
                if off is not None:
                    kit.append({"item": off["entry"], "slot": EQUIPMENT_SLOT_OFFHAND})
    if not kit:
        raise SystemExit(f"No weapon candidate for class {class_id} ({group}/{stat}) at level {level}")
    return kit


def weapon_key(class_id, group, stat):
    return f"{class_id}/{group}/{stat}"


def generate(pool, catalog):
    by_class = class_proficiencies()
    armor_keys = sorted({(spec["armor"], spec["primary_stat"]) for spec in catalog["specs"]})
    weapon_keys = sorted({(spec["class_id"], spec["group"], spec["primary_stat"]) for spec in catalog["specs"]})
    armor = {}
    weapons = {}
    for level in LEVELS:
        armor[str(level)] = {
            f"{a}/{s}": build_armor_kit(pool, level, a, s) for a, s in armor_keys
        }
        weapons[str(level)] = {
            weapon_key(class_id, group, stat): build_weapon_kit(
                pool, level, class_id, group, stat, by_class[class_id])
            for class_id, group, stat in weapon_keys
        }
    return {
        "version": 2,
        "schema": {
            "armor": {
                "level": {
                    "armor_type/primary_stat": "shared armor-slot kit (head..trinket2) for that armor "
                                                "material and primary stat"
                }
            },
            "weapons": {
                "level": {
                    "class_id/group/primary_stat": "mainhand (+ offhand/shield) kit for that class's "
                                                     "proficiency, role group and primary stat"
                }
            },
        },
        "armor": armor,
        "weapons": weapons,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.parse_args(argv)
    pool = load_pool()
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    gear = generate(pool, catalog)
    GEAR_PATH.write_text(json.dumps(gear, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {GEAR_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
