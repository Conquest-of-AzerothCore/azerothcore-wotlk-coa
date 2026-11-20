from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
db = sqlite3.connect(":memory:")
db.executescript("""
CREATE TABLE creature_template (entry INT PRIMARY KEY, name TEXT, minlevel INT, maxlevel INT,
faction INT, npcflag INT, unit_class INT, type INT);
CREATE TABLE item_template (entry INT PRIMARY KEY, ItemSet INT);
CREATE TABLE npc_vendor (entry INT, slot INT, item INT, maxcount INT, incrtime INT,
ExtendedCost INT, VerifiedBuild INT, PRIMARY KEY (entry,item,ExtendedCost));
INSERT INTO creature_template VALUES (42,'Other vendor',1,1,35,128,1,7);
INSERT INTO npc_vendor VALUES (42,0,999,0,0,17,NULL);
""")
sets = list(range(201, 210)) + [211, 406, 1205, 1208, 1209, 1210, 1219, 1223, 1226, 1227, 1321, 2020]
for tier in range(4):
    for group, item_set in enumerate(sets):
        for slot in range(8):
            item = 100000 + tier * 10000 + group * 8 + slot
            db.execute("INSERT INTO item_template VALUES (?,?)", (item, item_set))
            db.execute("INSERT INTO npc_vendor VALUES (?,?,?,?,?,?,?)",
                       (91000001 + tier, slot, item, slot % 2, slot % 2 * 60, 100 + tier * 10 + slot, None))
db.commit()
canonical = db.execute("SELECT * FROM npc_vendor ORDER BY entry,item,ExtendedCost").fetchall()
sql = (ROOT / "data/sql/updates/pending_db_world/rev_20261119_01_t1_vendor_pages.sql").read_text()
sql = sql.replace("ON DUPLICATE KEY UPDATE", "ON CONFLICT(entry) DO UPDATE SET")
sql = re.sub(r"VALUES\(`(\w+)`\)", r"excluded.`\1`", sql)
db.executescript(sql.replace("START TRANSACTION", "BEGIN TRANSACTION"))
assert db.execute("SELECT * FROM npc_vendor WHERE entry<91000101 ORDER BY entry,item,ExtendedCost").fetchall() == canonical
for tier in range(4):
    original = db.execute("SELECT slot,item,maxcount,incrtime,ExtendedCost,VerifiedBuild FROM npc_vendor "
                          "WHERE entry=? ORDER BY item,ExtendedCost", (91000001 + tier,)).fetchall()
    first = 91000101 + tier * 2
    split = db.execute("SELECT slot,item,maxcount,incrtime,ExtendedCost,VerifiedBuild FROM npc_vendor "
                       "WHERE entry IN (?,?) ORDER BY item,ExtendedCost", (first, first + 1)).fetchall()
    assert split == original
    assert [db.execute("SELECT COUNT(*) FROM npc_vendor WHERE entry=?", (first + part,)).fetchone()[0]
            for part in range(2)] == [80, 88]
    assert db.execute("SELECT i.ItemSet FROM npc_vendor v JOIN item_template i ON i.entry=v.item "
                      "WHERE v.entry IN (?,?) GROUP BY i.ItemSet HAVING COUNT(DISTINCT v.entry)>1",
                      (first, first + 1)).fetchall() == []
    assert db.execute("SELECT COUNT(*) FROM creature_template WHERE entry IN (?,?) AND npcflag=128",
                      (first, first + 1)).fetchone() == (2,)
snapshot = list(db.iterdump())
db.executescript(sql.replace("START TRANSACTION", "BEGIN TRANSACTION"))
assert list(db.iterdump()) == snapshot
print("PASS: all four T1 tiers split 80/88 without losing offers, splitting sets, changing costs/stock, "
      "or touching canonical and unrelated vendors; migration repeats unchanged")

source = (ROOT / "src/server/coa/AscensionTierTokenVendor.cpp").read_text()
adapter = r"""
#include <array>
#include <cassert>
#include <cstdint>
#include <string>
#include <vector>
using uint32 = std::uint32_t;
constexpr uint32 GOSSIP_ICON_VENDOR = 1, GOSSIP_SENDER_MAIN = 1, DEFAULT_GOSSIP_MESSAGE = 1;
struct WorldSession { uint32 inventory = 0; void SendListInventory(uint32, uint32 entry) { inventory = entry; } };
struct Player { WorldSession session; std::vector<uint32> actions; std::vector<std::string> labels;
    WorldSession* GetSession() { return &session; } };
struct Creature { uint32 GetGUID() const { return 14394; } };
struct CreatureScript {
    explicit CreatureScript(char const*) { }
    virtual bool OnGossipHello(Player*, Creature*) { return false; }
    virtual bool OnGossipSelect(Player*, Creature*, uint32, uint32) { return false; }
    virtual ~CreatureScript() = default;
};
void ClearGossipMenuFor(Player* p) { p->actions.clear(); p->labels.clear(); }
void CloseGossipMenuFor(Player*) { }
void AddGossipItemFor(Player* p, uint32, char const* text, uint32, uint32 action) {
    p->actions.push_back(action); p->labels.emplace_back(text);
}
void SendGossipMenuFor(Player*, uint32, uint32) { }
"""
cases = r"""
int main() {
    npc_coa_tier_token_vendor script;
    Player player;
    Creature creature;
    assert(script.OnGossipHello(&player, &creature));
    assert(player.actions.size() == 21);
    std::array<uint32, 21> expected = {91000101,91000102,91000103,91000104,91000105,91000106,91000107,91000108,
        91000109,91000110,91000111,91000112,91000113,91000114,91000115,91000116,91000009,91000010,91000011,91000012,91000013};
    for (uint32 i = 0; i < expected.size(); ++i) {
        script.OnGossipHello(&player, &creature);
        assert(player.actions[i] == i + 1);
        if (i < 16) assert(player.labels[i].find(i % 2 ? "Part 2" : "Part 1") != std::string::npos);
        script.OnGossipSelect(&player, &creature, 0, player.actions[i]);
        assert(player.session.inventory == expected[i]);
    }
    for (uint32 action : {0u, 22u, 0xFFFFFFFFu}) {
        player.session.inventory = 0;
        script.OnGossipSelect(&player, &creature, 0, action);
        assert(player.session.inventory == 0);
    }
}
"""
code = adapter + "\n" + re.sub(r"^#include.*$", "", source, flags=re.MULTILINE) + "\n" + cases
with tempfile.TemporaryDirectory(prefix="coa-tier-vendor-") as directory:
    target = Path(directory)
    (target / "check.cpp").write_text(code)
    subprocess.run(["g++", "-std=c++20", "-Wall", "-Wextra", "-Werror", "-fsanitize=undefined",
                    str(target / "check.cpp"), "-o", str(target / "check")], check=True)
    subprocess.run([str(target / "check")], check=True)
print("PASS: all 21 gossip actions open the intended inventory; T1/T2 split pages and T3 preserved and invalid actions ignored")
