from pathlib import Path
import re
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "data/sql/updates/pending_db_world/rev_20260911_01_live_starter_templates.sql"
BASE = ROOT / "data/sql/base/db_world/item_template.sql"


def installed_template_ids():
    result = set()
    for path in [BASE, *MIGRATION.parent.glob("*.sql")]:
        if path == MIGRATION:
            continue
        for statement in re.findall(
            r"(?:INSERT(?: IGNORE)? INTO|REPLACE INTO)\s+`item_template`\s*[^;]+;",
            path.read_text(encoding="utf-8"), re.S,
        ):
            if "VALUES" in statement:
                result.update(map(int, re.findall(r"\(\s*(\d+),", statement.split("VALUES", 1)[1])))
    return result


class StarterTemplates(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.addCleanup(self.db.close)
        schema = BASE.read_text(encoding="utf-8").split("CREATE TABLE `item_template` (", 1)[1]
        columns = []
        for name, definition in re.findall(r"^  `([^`]+)` (.+),?$", schema.split(") ENGINE", 1)[0], re.M):
            storage = "TEXT" if definition.startswith(("varchar", "char", "text")) else "NUMERIC"
            default = re.search(r"\bDEFAULT ('[^']*'|NULL|[-\d.]+)", definition)
            columns.append(f"`{name}` {storage}" + (" PRIMARY KEY" if name == "entry" else "")
                           + (" DEFAULT " + default[1] if default else ""))
        self.db.execute("CREATE TABLE item_template (" + ",".join(columns) + ")")
        self.sql = MIGRATION.read_text(encoding="utf-8").replace(
            "CREATE TEMPORARY TABLE `_ascension_live_starter_items` LIKE `item_template`;",
            "CREATE TEMPORARY TABLE `_ascension_live_starter_items` AS SELECT * FROM item_template WHERE 0;",
        ).replace("DROP TEMPORARY TABLE", "DROP TABLE")

    def test_missing_travel_permit_has_captured_definition(self):
        self.db.executescript(self.sql)
        self.assertEqual(self.db.execute(
            "SELECT name, displayid, Quality, stackable, bonding, spellid_1, spellcooldown_1 "
            "FROM item_template WHERE entry = 977028"
        ).fetchone(), ("Travel Permit", 50709, 6, 1, 1, 1001088, 300000))

    def test_existing_templates_and_replays_are_unchanged(self):
        self.db.execute(
            "INSERT INTO item_template (entry, name, flagsCustom, ScriptName) VALUES (?, ?, ?, ?)",
            (977028, "Locally customized permit", 123, "local_permit"),
        )
        before = self.db.execute("SELECT * FROM item_template WHERE entry = 977028").fetchone()
        self.db.executescript(self.sql)
        self.assertEqual(self.db.execute("SELECT * FROM item_template WHERE entry = 977028").fetchone(), before)
        first = self.db.execute("SELECT * FROM item_template ORDER BY entry").fetchall()
        self.db.executescript(self.sql)
        self.assertEqual(self.db.execute("SELECT * FROM item_template ORDER BY entry").fetchall(), first)

    def test_clean_bootstrap_covers_every_live_starter(self):
        header = (ROOT / "src/server/coa/AscensionCustomClassData.h").read_text(encoding="utf-8")
        block = header.split("LiveStarterItems =", 1)[1].split("}};", 1)[0]
        starters = [tuple(map(int, row)) for row in re.findall(
            r"\{(\d+), (\d+), (\d+), (\d+), (\d+)\}", block,
        )]
        self.db.executescript(self.sql)
        added = {entry for entry, in self.db.execute("SELECT entry FROM item_template")}
        expected = {entry for _, entry, _, _, _ in starters}
        self.assertEqual(added, expected - installed_template_ids())
        for _, entry, _, slot, count in starters:
            if entry not in added:
                continue
            stack, level = self.db.execute(
                "SELECT stackable, RequiredLevel FROM item_template WHERE entry = ?", (entry,),
            ).fetchone()
            self.assertGreaterEqual(stack, count, entry)
            if slot < 19:
                self.assertLessEqual(level, 1, entry)


if __name__ == "__main__":
    unittest.main()
