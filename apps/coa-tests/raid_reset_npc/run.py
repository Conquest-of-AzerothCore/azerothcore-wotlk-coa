from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
db = sqlite3.connect(":memory:")
db.create_function("CONCAT", -1, lambda *values: "".join(values))
db.executescript("""
CREATE TABLE creature_template (entry INT PRIMARY KEY, name TEXT, subname TEXT, minlevel INT, maxlevel INT,
faction INT, npcflag INT, unit_class INT, type INT, ScriptName TEXT);
CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT, DisplayScale REAL,
Probability REAL, PRIMARY KEY (CreatureID,Idx));
CREATE TABLE npc_text (ID INT PRIMARY KEY, text0_0 TEXT, Probability0 REAL);
CREATE TABLE creature (guid INT PRIMARY KEY, id INT, map INT, spawnMask INT, phaseMask INT, position_x REAL,
position_y REAL, position_z REAL, orientation REAL, spawntimesecs INT, MovementType INT);
CREATE TABLE gameobject (guid INT PRIMARY KEY, id INT, map INT, position_x REAL, position_y REAL,
position_z REAL, orientation REAL);
INSERT INTO gameobject VALUES (7905400,402000,0,-8824.9,630.397,93.8,3.92699);
INSERT INTO creature VALUES (99,68,0,1,1,-8800,600,93,0,120,0);
""")
sql = (ROOT / "data/sql/updates/pending_db_world/rev_20261118_04_stormwind_raid_reset_registrar.sql").read_text()
sql = sql.replace("ON DUPLICATE KEY UPDATE", "ON CONFLICT(entry) DO UPDATE SET")
sql = re.sub(r"VALUES\(`(\w+)`\)", r"excluded.`\1`", sql)
db.executescript(sql)
snapshot = list(db.iterdump())
db.executescript(sql)
assert list(db.iterdump()) == snapshot
assert db.execute("SELECT id,map,spawnMask,phaseMask,position_x,position_y,position_z FROM creature "
                  "WHERE guid=9990501").fetchone() == (9990501, 0, 1, 1, -8826.9, 632.397, 93.8)
assert db.execute("SELECT ScriptName FROM creature_template WHERE entry=9990501").fetchone() == (
    "npc_coa_raid_reset",)
assert db.execute("SELECT id FROM creature WHERE guid=99").fetchone() == (68,)
print("PASS: NPC migration repeats unchanged and places one registrar beside the Stormwind Callboard")
source = (ROOT / "src/server/coa/CoARaidResetNpc.cpp").read_text()
code = (HERE / "adapter.hpp").read_text() + "\n"
code += "\n".join(line for line in source.splitlines() if not line.startswith("#include"))
code += "\n" + (HERE / "cases.cpp").read_text()
with tempfile.TemporaryDirectory(prefix="coa-raid-reset-") as directory:
    target = Path(directory)
    (target / "check.cpp").write_text(code)
    subprocess.run(["g++", "-std=c++20", "-pthread", "-Wall", "-Wextra", "-Werror",
                    "-fsanitize=undefined", str(target / "check.cpp"), "-o", str(target / "check")], check=True)
    subprocess.run([str(target / "check")], check=True)
