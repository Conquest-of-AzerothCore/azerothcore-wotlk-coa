from pathlib import Path
import sqlite3


ROOT = Path(__file__).resolve().parents[3]
db = sqlite3.connect(":memory:")
db.executescript("""
CREATE TABLE item_template (entry INT PRIMARY KEY, ItemLevel INT, InventoryType INT, ItemSet INT, name TEXT);
CREATE TABLE npc_vendor (entry INT, slot INT, item INT, maxcount INT, incrtime INT, ExtendedCost INT,
PRIMARY KEY (entry,item,ExtendedCost));
""")
expected = set()
for tier, level in enumerate((65, 68, 72, 75)):
    vendor = 91000001 + tier
    for slot, inventory in enumerate((1, 5, 20)):
        reference = 10000 + tier * 100 + slot
        item = 20000 + tier * 100 + slot
        cost = tier * 10 + (1 if inventory == 1 else 2)
        db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (reference, level, inventory, 202, "Prophecy"))
        db.execute("INSERT INTO npc_vendor VALUES (?,0,?,0,0,?)", (vendor, reference, cost))
        db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (item, level, inventory, 406, "Tier set"))
        expected.add((vendor, item, cost))
    db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (30000 + tier, level, 1, 406, "Bloodforged gear"))
    db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (40000 + tier, level, 1, 9999, "Unrelated set"))
db.execute("INSERT INTO npc_vendor VALUES (91000001,0,20000,0,0,999)")
expected.remove((91000001, 20000, 1))
expected.add((91000001, 20000, 999))
sql = (ROOT / "data/sql/updates/pending_db_world/rev_20261118_05_t1_vendor_set_completion.sql").read_text()
sql = sql.replace("DROP TEMPORARY TABLE", "DROP TABLE").replace("CREATE TEMPORARY TABLE", "CREATE TEMP TABLE")
db.executescript(sql)
actual = set(db.execute("SELECT entry,item,ExtendedCost FROM npc_vendor WHERE item BETWEEN 20000 AND 29999"))
assert actual == expected, (actual, expected)
assert db.execute("SELECT COUNT(*) FROM npc_vendor WHERE item>=30000").fetchone() == (0,)
snapshot = list(db.iterdump())
db.executescript(sql)
assert list(db.iterdump()) == snapshot
print("PASS: T1 completion matches slot prices on all four tiers, preserves existing prices, excludes unrelated "
      "and Bloodforged gear, and repeats without changes")
