"""Adversarial unit tests for the conservative CoA loot planner.

These tests use synthetic rows only. They exercise ``plan`` directly so running
the suite cannot read archive exports, generate SQL, or connect to a database.
"""

import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("coa_loot_sql", ROOT / "tools/coa_loot_sql.py")
COA_LOOT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COA_LOOT)


def creature(entry, *, name=None, lootid=None):
    return {"entry": entry, "name": name or f"Creature {entry}",
            "lootid": entry if lootid is None else lootid}


def item(entry, *, name=None, item_class=2, startquest=0, bonding=0):
    return {"entry": entry, "name": name or f"Item {entry}", "class": item_class,
            "startquest": startquest, "Bonding": bonding}


def loot(entry, item_id, *, reference=0, chance=10, quest_required=0,
         loot_mode=1, group_id=0, minimum=1, maximum=1):
    return {"Entry": entry, "Item": item_id, "Reference": reference,
            "Chance": chance, "QuestRequired": quest_required, "LootMode": loot_mode,
            "GroupId": group_id, "MinCount": minimum, "MaxCount": maximum}


def source_drop(item_id, *, chance="10%", label=None):
    return {"entity": {"type": "item", "key": str(item_id),
                       "label": label or f"Item {item_id}"},
            "chance": chance}


def source_npc(entry, drops, *, name=None):
    return {"key": str(entry), "name": name or f"Creature {entry}", "drops": drops}


def baseline(*, creatures=(), items=(), loot_rows=(), quests=(), conditions=()):
    return {"creature_template": list(creatures), "item_template": list(items),
            "creature_loot_template": list(loot_rows), "quest_template": list(quests),
            "conditions": list(conditions)}


class CoaLootPlannerSafetyTests(unittest.TestCase):
    def test_accepts_only_empty_own_or_zero_loot_templates(self):
        data = baseline(
            creatures=[creature(100, lootid=0), creature(101)],
            items=[item(500), item(501)],
        )
        records = [source_npc(100, [source_drop(500, chance="1.25%")]),
                   source_npc(101, [source_drop(501, chance="100%")])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual({(p["entry"], p["item"], p["chance"]) for p in patches},
                         {(100, 500, "1.25"), (101, 501, "100")})
        self.assertEqual(report["exclusions"], {})

    def test_rejects_redirected_and_shared_loot_ids(self):
        data = baseline(
            creatures=[creature(110, lootid=900), creature(111), creature(112, lootid=111)],
            items=[item(510), item(511)],
        )
        records = [source_npc(110, [source_drop(510)]),
                   source_npc(111, [source_drop(511)])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("shared_or_redirected_loot"), 2)

    def test_rejects_zero_lootid_with_existing_rows_and_conditioned_templates(self):
        data = baseline(
            creatures=[creature(120, lootid=0), creature(121)],
            items=[item(520), item(521), item(599)],
            loot_rows=[loot(120, 599)],
            conditions=[{"SourceTypeOrReferenceId": 1, "SourceGroup": 121}],
        )
        records = [source_npc(120, [source_drop(520)]),
                   source_npc(121, [source_drop(521)])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("conditional_or_unassigned_existing_loot"), 2)

    def test_any_reference_row_vetoes_new_items_for_the_template(self):
        data = baseline(
            creatures=[creature(130)],
            items=[item(530)],
            loot_rows=[loot(130, 0, reference=70000)],
        )

        patches, report = COA_LOOT.plan([source_npc(130, [source_drop(530)])], data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("reference_template_requires_review"), 1)

    def test_preserves_existing_item_even_when_its_row_has_group_semantics(self):
        data = baseline(
            creatures=[creature(140)],
            items=[item(540)],
            loot_rows=[loot(140, 540, chance=42, group_id=3, minimum=2, maximum=4)],
        )

        patches, report = COA_LOOT.plan(
            [source_npc(140, [source_drop(540, chance="9%")])], data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("existing_item_preserved"), 1)

    def test_rejects_duplicate_unknown_and_zero_source_chances(self):
        data = baseline(
            creatures=[creature(150)],
            items=[item(550), item(551), item(552)],
        )
        records = [source_npc(150, [source_drop(550, chance="8%"),
                                         source_drop(550, chance="100%"),
                                         source_drop(551, chance="—"),
                                         source_drop(552, chance="0%")])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("duplicate_source_item"), 1)
        self.assertEqual(report["exclusions"].get("unknown_or_zero_chance"), 2)

    def test_rejects_every_supported_quest_item_signal(self):
        items = [
            item(560, item_class=12),
            item(561, startquest=9001),
            item(562, bonding=4),
            item(563),
            item(564),
        ]
        quest = {"RequiredItemId1": 563, "ItemDrop1": 564}
        data = baseline(creatures=[creature(160)], items=items, quests=[quest])
        records = [source_npc(160, [source_drop(row["entry"]) for row in items])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("missing_or_quest_sensitive_item"), 5)

    def test_rejects_missing_items_stubs_and_name_conflicts(self):
        data = baseline(
            creatures=[creature(170)],
            items=[item(570, name="Known Blade"), item(571, name="Known Shield")],
        )
        records = [source_npc(170, [source_drop(999),
                                         source_drop(570, label="Item #570"),
                                         source_drop(571, label="Different Shield")])]

        patches, report = COA_LOOT.plan(records, data)

        self.assertEqual(patches, [])
        self.assertEqual(report["exclusions"].get("missing_or_quest_sensitive_item"), 1)
        self.assertEqual(report["exclusions"].get("item_name_conflict_or_stub"), 2)


if __name__ == "__main__":
    unittest.main()
