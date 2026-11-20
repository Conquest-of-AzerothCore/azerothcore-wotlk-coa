from pathlib import Path
import re
import sqlite3


ROOT = Path(__file__).resolve().parents[3]
db = sqlite3.connect(":memory:")
db.executescript("""
CREATE TABLE creature_template (entry INT PRIMARY KEY, name TEXT, minlevel INT, maxlevel INT,
faction INT, npcflag INT, unit_class INT, type INT);
CREATE TABLE item_template (entry INT PRIMARY KEY, name TEXT, ItemSet INT, ItemLevel INT, InventoryType INT);
CREATE TABLE npc_vendor (entry INT, slot INT, item INT, maxcount INT, incrtime INT,
ExtendedCost INT, VerifiedBuild INT, PRIMARY KEY (entry,item,ExtendedCost));
INSERT INTO creature_template VALUES (42,'Other vendor',1,1,35,128,1,7);
INSERT INTO npc_vendor VALUES (42,0,999,0,0,17,NULL);
INSERT INTO npc_vendor VALUES (91000101,0,998,0,0,18,NULL);
""")
sets = [210, 212, 213, 214, 215, 216, 217, 218, 220, 404,
        1211, 1214, 1216, 1217, 1218, 1224, 1228, 2021, 2214]
slots = [1, 3, 5, 6, 7, 8, 9, 10]
levels = [72, 77, 79, 71, 72, 71, 71, 71]
expected = {}
excluded = set()
for tier, upgrade in enumerate([0, 4, 7, 11]):
    vendor = 91000005 + tier
    expected[vendor] = {}
    for group, item_set in enumerate(sets):
        for slot, level in zip(slots, levels):
            item = 100000 + tier * 10000 + group * 100 + slot
            inventory = 20 if item_set == 210 and slot == 5 else slot
            db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)",
                       (item, 'Tier set', item_set, level + upgrade, inventory))
            cost = 40000 + tier * 100 + slot
            expected[vendor][item] = cost
            if group < 9 or (tier != 2 and slot in [1, 3, 5, 7]):
                db.execute("INSERT INTO npc_vendor VALUES (?,?,?,?,?,?,?)", (vendor, slot, item, 0, 0, cost, None))
    for slot in slots:
        item = 500000 + tier * 100 + slot
        db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (item, 'Existing Faith offer', 525, 86 + upgrade, slot))
        db.execute("INSERT INTO npc_vendor VALUES (?,?,?,?,?,?,?)", (vendor, slot, item, 1, 60, 50000 + slot, 12340))
        expected[vendor][item] = 50000 + slot
    for item_set, name, level in [(1214, 'Bloodforged Tier set', 71 + upgrade),
                                  (9999, 'Unrelated item', 71 + upgrade),
                                  (1214, 'Wrong difficulty', 123 + upgrade)]:
        item = 600000 + tier * 100 + len(excluded)
        db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (item, name, item_set, level, 8))
        excluded.add(item)
    item = 100000 + tier * 10000 + sets.index(1214) * 100 + 1
    if tier != 2:
        db.execute("UPDATE npc_vendor SET ExtendedCost=99999 WHERE entry=? AND item=?", (vendor, item))
        expected[vendor][item] = 99999
for slot, level in zip(slots, levels):
    if slot == 3:
        continue
    item = 700000 + slot
    db.execute("INSERT INTO item_template VALUES (?,?,?,?,?)", (item, 'Additional Ten Storms variant', 1216, level, slot))
    expected[91000005][item] = 40000 + slot
db.commit()
original = db.execute("SELECT * FROM npc_vendor ORDER BY entry,item,ExtendedCost").fetchall()
sql = (ROOT / "data/sql/updates/pending_db_world/rev_20261119_02_t2_vendor_set_completion_and_pages.sql").read_text()
sql = sql.replace("START TRANSACTION", "BEGIN TRANSACTION")
sql = sql.replace("DROP TEMPORARY TABLE", "DROP TABLE").replace("CREATE TEMPORARY TABLE", "CREATE TEMP TABLE")
sql = sql.replace("ON DUPLICATE KEY UPDATE", "ON CONFLICT(entry) DO UPDATE SET")
sql = re.sub(r"VALUES\(`(\w+)`\)", r"excluded.`\1`", sql)
db.executescript(sql)
for row in original:
    assert db.execute("SELECT * FROM npc_vendor WHERE entry=? AND item=? AND ExtendedCost=?",
                      (row[0], row[2], row[5])).fetchone() == row
for tier in range(4):
    vendor = 91000005 + tier
    actual = dict(db.execute("SELECT item,ExtendedCost FROM npc_vendor WHERE entry=?", (vendor,)))
    assert actual == expected[vendor], (vendor, set(actual) ^ set(expected[vendor]))
    assert not (set(actual) & excluded)
    for item_set in sets:
        count = db.execute("SELECT COUNT(*) FROM npc_vendor v JOIN item_template i ON i.entry=v.item "
                           "WHERE v.entry=? AND i.ItemSet=?", (vendor, item_set)).fetchone()[0]
        assert count == (15 if tier == 0 and item_set == 1216 else 8), (vendor, item_set, count)
    first = 91000109 + tier * 2
    assert dict(db.execute("SELECT item,ExtendedCost FROM npc_vendor WHERE entry IN (?,?)",
                           (first, first + 1))) == actual
    assert [db.execute("SELECT COUNT(*) FROM npc_vendor WHERE entry=?", (first + part,)).fetchone()[0]
            for part in range(2)] == [80, 87 if tier == 0 else 80]
    assert db.execute("SELECT i.ItemSet FROM npc_vendor v JOIN item_template i ON i.entry=v.item "
                      "WHERE v.entry IN (?,?) GROUP BY i.ItemSet HAVING COUNT(DISTINCT v.entry)>1",
                      (first, first + 1)).fetchall() == []
snapshot = list(db.iterdump())
db.executescript(sql)
assert list(db.iterdump()) == snapshot
print("PASS: T2 sets completed across all four difficulties, including absent Mythic variants; "
      "existing prices/stock and T1 preserved; incorrect variants excluded; complete-set pages below 150; "
      "repeated migration unchanged")
