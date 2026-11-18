import os
import pwd
import re
import shutil
import sqlite3
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261118_01_bwl_mc_style_boss_and_trash_scaling.sql"
LOOT_SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261118_02_bwl_chromatic_tokens_replace_t2.sql"
DIFFICULTY_LOOT_SQL = LOOT_SQL.with_name("rev_20261118_04_bwl_difficulty_loot.sql")
SPAWN_SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261118_03_bwl_spawns_all_difficulties.sql"
COLUMNS = {
    "creature_template": [
        "entry",
        "difficulty_entry_1",
        "difficulty_entry_2",
        "difficulty_entry_3",
        "KillCredit1",
        "KillCredit2",
        "name",
        "subname",
        "IconName",
        "gossip_menu_id",
        "minlevel",
        "maxlevel",
        "exp",
        "faction",
        "npcflag",
        "speed_walk",
        "speed_run",
        "speed_swim",
        "speed_flight",
        "detection_range",
        "rank",
        "dmgschool",
        "DamageModifier",
        "BaseAttackTime",
        "RangeAttackTime",
        "BaseVariance",
        "RangeVariance",
        "unit_class",
        "unit_flags",
        "unit_flags2",
        "dynamicflags",
        "family",
        "type",
        "type_flags",
        "lootid",
        "pickpocketloot",
        "skinloot",
        "PetSpellDataId",
        "VehicleId",
        "mingold",
        "maxgold",
        "AIName",
        "MovementType",
        "HoverHeight",
        "HealthModifier",
        "ManaModifier",
        "ArmorModifier",
        "ExperienceModifier",
        "RacialLeader",
        "movementId",
        "RegenHealth",
        "CreatureImmunitiesId",
        "flags_extra",
        "ScriptName",
        "VerifiedBuild"
    ],
    "creature_template_addon": [
        "entry",
        "path_id",
        "mount",
        "bytes1",
        "bytes2",
        "emote",
        "visibilityDistanceType",
        "auras"
    ],
    "creature_template_model": [
        "CreatureID",
        "Idx",
        "CreatureDisplayID",
        "DisplayScale",
        "Probability",
        "VerifiedBuild"
    ],
    "creature_template_movement": [
        "CreatureId",
        "Ground",
        "Swim",
        "Flight",
        "Rooted",
        "Chase",
        "Random",
        "InteractionPauseTimer"
    ],
    "creature_template_resistance": [
        "CreatureID",
        "School",
        "Resistance",
        "VerifiedBuild"
    ],
    "creature_template_spell": [
        "CreatureID",
        "Index",
        "Spell",
        "VerifiedBuild"
    ]
}
BOSSES = {
    11583: 1558215, 11981: 422837, 11983: 422837, 12017: 1281332,
    12435: 521444, 13020: 1997673, 14020: 1042888, 14601: 422837,
}
MC = {
    11658: 133964, 11661: 88412, 11662: 121814, 11665: 42384, 11666: 16784,
    11668: 33777, 11669: 3887, 11671: 20359, 11673: 87174, 12100: 16784,
}
TRASH = [
    12416, 12420, 12422, 12457, 12458, 12459, 12460, 12461, 12463, 12464,
    12465, 12467, 12468, 12557, 13996, 14022, 14023, 14024, 14025, 14261,
    14262, 14263, 14264, 14265, 14302, 14401, 14456, 14605,
]


def insert(db, table, values):
    columns = ", ".join(f"`{key}`" for key in values)
    placeholders = ", ".join("?" for _ in values)
    db.execute(f"INSERT INTO `{table}` ({columns}) VALUES ({placeholders})", tuple(values.values()))


def fixture():
    db = sqlite3.connect(":memory:")
    db.create_function("CONCAT", -1, lambda *values: "".join(str(value) for value in values))
    for table, columns in COLUMNS.items():
        text_columns = {"name", "subname", "IconName", "AIName", "ScriptName", "auras"}
        fields = ", ".join(f"`{column}` VARCHAR(255) DEFAULT ''" if column in text_columns
                           else f"`{column}` NUMERIC DEFAULT 0" for column in columns)
        key = f"`{columns[0]}`"
        if table != "creature_template":
            key += f", `{columns[1]}`" if table not in (
                "creature_template_addon", "creature_template_movement"
            ) else ""
        db.execute(f"CREATE TABLE `{table}` ({fields}, PRIMARY KEY ({key}))")
    db.execute("CREATE TABLE coa_boss_flex (entry INT PRIMARY KEY, hp_d0 INT, hp_d1 INT, "
               "hp_d2 INT, hp_d3 INT, comment TEXT)")
    loot_columns = ("Entry INT, Item INT, Reference INT DEFAULT 0, Chance REAL DEFAULT 100, "
                    "QuestRequired INT DEFAULT 0, LootMode INT DEFAULT 1, GroupId INT DEFAULT 0, "
                    "MinCount INT DEFAULT 1, MaxCount INT DEFAULT 1, Comment VARCHAR(255), "
                    "PRIMARY KEY (Entry,Item,Reference,GroupId)")
    for table in ("creature_loot_template", "reference_loot_template"):
        db.execute(f"CREATE TABLE {table} ({loot_columns})")
    for table in ("creature", "gameobject"):
        db.execute(f"CREATE TABLE {table} (guid INT PRIMARY KEY, map INT, spawnMask INT)")
        db.executemany(f"INSERT INTO {table} VALUES (?, ?, ?)",
                       [(1, 469, 1), (2, 469, 0), (3, 469, 16), (4, 409, 1), (5, 0, 1)])
    for entry in [*BOSSES, *TRASH, *MC, 99999]:
        insert(db, "creature_template", {
            "entry": entry, "name": f"creature-{entry}", "HealthModifier": 13,
            "DamageModifier": 22, "lootid": entry, "minlevel": 62, "maxlevel": 62,
            "ScriptName": "boss_razorgore_coa" if entry == 12435 else "",
        })
        for table, columns in COLUMNS.items():
            if table == "creature_template":
                continue
            values = {column: index + 1 for index, column in enumerate(columns)}
            values[columns[0]] = entry
            insert(db, table, values)
    for entry, hp in {**MC, **BOSSES, 99999: 12345}.items():
        db.execute("INSERT INTO coa_boss_flex VALUES (?, ?, ?, ?, ?, ?)",
                   (entry, hp, hp * 2, hp * 3, hp * 4, "original"))
    insert(db, "creature_template", {
        "entry": 112435, "name": "custom heroic Razorgore", "lootid": 9912435,
        "ScriptName": "boss_razorgore_coa",
    })
    db.execute("INSERT INTO creature_loot_template (Entry,Item,Chance) VALUES (9912435,2622462,100)")
    db.execute("INSERT INTO creature_loot_template (Entry,Item,Chance) VALUES (12460,12345,17)")
    db.execute("INSERT INTO creature_loot_template (Entry,Item,Chance) VALUES (12435,16900,9)")
    db.execute("INSERT INTO reference_loot_template (Entry,Item,Chance) VALUES (30342,16900,9)")
    db.execute("INSERT INTO reference_loot_template (Entry,Item,Chance,GroupId) VALUES (30348,19341,18,1)")
    db.execute("INSERT INTO creature_loot_template (Entry,Item,Chance) VALUES (12460,19354,2)")
    return db


def snapshot(db):
    return {
        table: db.execute(f"SELECT * FROM `{table}` ORDER BY 1, 2").fetchall()
        for table in [*COLUMNS, "coa_boss_flex", "creature_loot_template", "reference_loot_template",
                      "creature", "gameobject"]
    }



def verify_mysql(fixture_sql, migration):
    migration = "\n".join((migration, LOOT_SQL.read_text(), SPAWN_SQL.read_text(), DIFFICULTY_LOOT_SQL.read_text()))
    server = shutil.which("mysqld") or "/usr/sbin/mysqld"
    if not Path(server).is_file() or not shutil.which("mysql") or not shutil.which("mysqldump"):
        print("MySQL dialect execution unavailable: mysql, mysqldump or mysqld is missing")
        return
    with tempfile.TemporaryDirectory(prefix="coa-bwl-mysql-") as directory:
        root = Path(directory)
        data = root / "data"
        socket = root / "mysql.sock"
        subprocess.run([server, "--no-defaults", "--initialize-insecure", f"--datadir={data}"],
                       check=True, capture_output=True, timeout=60)
        args = [server, "--no-defaults", f"--datadir={data}", f"--socket={socket}",
                f"--pid-file={root / 'mysql.pid'}", "--skip-networking", "--mysqlx=OFF",
                f"--user={pwd.getpwuid(os.getuid()).pw_name}"]
        client = ["mysql", "--no-defaults", "--protocol=socket", f"--socket={socket}",
                  "--user=root", "--batch", "--skip-column-names"]
        environment = {key: value for key, value in os.environ.items() if key != "MYSQL_PWD"}
        with (root / "server.log").open("w") as log:
            process = subprocess.Popen(args, stdout=log, stderr=subprocess.STDOUT, env=environment)
            try:
                deadline = time.monotonic() + 30
                while time.monotonic() < deadline:
                    ready = subprocess.run(client + ["-e", "SELECT 1"], capture_output=True, env=environment)
                    if ready.returncode == 0:
                        break
                    if process.poll() is not None:
                        raise AssertionError((root / "server.log").read_text())
                    time.sleep(0.1)
                else:
                    raise AssertionError("Isolated MySQL did not become ready")
                fixture_sql = fixture_sql.replace("BEGIN TRANSACTION;", "START TRANSACTION;")
                fixture_sql = fixture_sql.replace("NUMERIC", "DECIMAL(20,4)")
                prefix = ("SET SESSION sql_mode = CONCAT(@@sql_mode, ',ANSI_QUOTES'); "
                          "CREATE DATABASE coa_test_bwl_scaling; USE coa_test_bwl_scaling;\n")
                result = subprocess.run(client, input=prefix + fixture_sql + "\n" + migration,
                                        capture_output=True, text=True, env=environment)
                assert result.returncode == 0, result.stderr
                dump = ["mysqldump", *client[1:5], "--compact", "--skip-comments", "--no-create-info",
                        "--skip-extended-insert", "--set-gtid-purged=OFF", "coa_test_bwl_scaling"]
                first = subprocess.check_output(dump, env=environment)
                result = subprocess.run(client + ["coa_test_bwl_scaling"], input=migration,
                                        capture_output=True, text=True, env=environment)
                assert result.returncode == 0, result.stderr
                assert subprocess.check_output(dump, env=environment) == first
                checks = subprocess.check_output(client + ["coa_test_bwl_scaling", "-e",
                    "SELECT hp_d0 FROM coa_boss_flex WHERE entry=12460; "
                    "SELECT lootid FROM creature_template WHERE entry=112435;"], env=environment, text=True)
                assert [int(float(value)) for value in checks.split()] == [192908, 112435]
                tokens = subprocess.check_output(client + ["coa_test_bwl_scaling", "-e",
                    "SELECT Entry,Item,Chance,MinCount,MaxCount FROM creature_loot_template "
                    "WHERE Comment='BWL Chromatic tier token' ORDER BY Entry,Item;"],
                    env=environment, text=True)
                actual = [tuple(int(float(value)) for value in row.split()) for row in tokens.splitlines()]
                slots = {12435: 2522462, 13020: 2522463, 12017: 2522465, 11983: 2522464,
                         14601: 2522464, 11981: 2522464, 14020: 2522461}
                expected = []
                for tier, item_offset in enumerate((0, 100000, 1200000, 200000)):
                    expected.extend((entry + tier * 100000, item + item_offset, 100, 2, 2)
                                    for entry, item in slots.items())
                    expected.extend((11583 + tier * 100000, item + item_offset, 100, 1, 1)
                                    for item in (2522460, 2522450))
                assert actual == sorted(expected)
                gear = subprocess.check_output(client + ["coa_test_bwl_scaling", "-e",
                    "SELECT boss.entry,pool.Item,pool.Chance,pool.GroupId FROM creature_template AS boss "
                    "JOIN creature_loot_template AS loot ON loot.Entry=boss.lootid "
                    "JOIN reference_loot_template AS pool ON pool.Entry=loot.Reference "
                    "WHERE MOD(boss.entry,100000)=12017 ORDER BY boss.entry; "
                    "SELECT mob.entry,loot.Item,loot.Chance FROM creature_template AS mob "
                    "JOIN creature_loot_template AS loot ON loot.Entry=mob.lootid "
                    "WHERE MOD(mob.entry,100000)=12460 ORDER BY mob.entry,loot.Item;"],
                    env=environment, text=True)
                gear_rows = [tuple(int(float(value)) for value in row.split()) for row in gear.splitlines()]
                offsets = (0, 300000, 1300000, 200000)
                expected_gems = [(12017 + mode * 100000, 19341 + offset, 18, 1)
                                 for mode, offset in enumerate(offsets)]
                expected_trash = [(12460 + mode * 100000, item, chance)
                                  for mode, offset in enumerate(offsets)
                                  for item, chance in ((12345, 17), (19354 + offset, 2))]
                assert gear_rows == expected_gems + expected_trash
                checks = subprocess.check_output(client + ["coa_test_bwl_scaling", "-e",
                    "SELECT COUNT(*) FROM creature_loot_template WHERE Item=16900; "
                    "SELECT COUNT(*) FROM reference_loot_template WHERE Entry=30342 AND Item=16900; "
                    "SELECT COUNT(*) FROM reference_loot_template WHERE Entry=90030342; "
                    "SELECT Chance FROM creature_loot_template WHERE Entry=12460 AND Item=12345;"],
                    env=environment, text=True)
                assert [int(float(value)) for value in checks.split()] == [0, 1, 6, 17]
                for table in ("creature", "gameobject"):
                    masks = subprocess.check_output(client + ["coa_test_bwl_scaling", "-e",
                        f"SELECT spawnMask FROM {table} ORDER BY guid;"], env=environment, text=True)
                    assert [int(value) for value in masks.split()] == [15, 15, 31, 1, 1]
                print("PASS: all migrations execute twice unchanged on isolated MySQL; BWL spawns cover "
                      "all four modes without changing other maps; all 32 boss loot "
                      "tables have tier-matched tokens, Broodlord and trash gear scale, and unrelated loot survives")
            finally:
                process.terminate()
                process.wait(timeout=30)


def main():
    db = fixture()
    before = snapshot(db)
    fixture_sql = "\n".join(db.iterdump())
    sql = SQL.read_text().replace("DROP TEMPORARY TABLE", "DROP TABLE")
    sql = sql.replace("CREATE TEMPORARY TABLE", "CREATE TEMP TABLE")
    sql = re.sub(r"ON DUPLICATE KEY UPDATE\s+`HealthModifier` = VALUES\(`HealthModifier`\), "
                 r"`DamageModifier` = VALUES\(`DamageModifier`\),",
                 "ON CONFLICT(entry) DO UPDATE SET HealthModifier=excluded.HealthModifier, "
                 "DamageModifier=excluded.DamageModifier,", sql)
    db.executescript(sql)
    after = snapshot(db)
    db.executescript(sql)
    assert snapshot(db) == after, "Reapplying the migration must not compound scaling or change loot"
    assert after["creature_loot_template"] == before["creature_loot_template"]
    assert db.execute("SELECT lootid FROM creature_template WHERE entry=112435").fetchone() == (9912435,)
    for entry, hp in BOSSES.items():
        row = db.execute("SELECT hp_d0,hp_d1,hp_d2,hp_d3 FROM coa_boss_flex WHERE entry=?", (entry,)).fetchone()
        assert row == (hp, round(hp * 1.44), round(hp * 1.88), round(hp * 2.32)), (entry, row)
    expected = {12460: 192908, 12457: 48639, 13996: 5597, 14261: 29317, 14302: 61033}
    for entry, hp in expected.items():
        row = db.execute("SELECT hp_d0,hp_d1,hp_d2,hp_d3 FROM coa_boss_flex WHERE entry=?", (entry,)).fetchone()
        assert row == (hp, round(hp * 1.44), round(hp * 1.88), round(hp * 2.32)), (entry, row)
        for count in (10, 25):
            assert all(row[i] * count < row[i + 1] * count for i in range(3))
    for entry in [*TRASH, *BOSSES]:
        assert db.execute("SELECT difficulty_entry_1,difficulty_entry_2,difficulty_entry_3 "
                          "FROM creature_template WHERE entry=?", (entry,)).fetchone() == (
                              entry + 100000, entry + 200000, entry + 300000)
        for offset, multiplier in ((100000, 1.44), (200000, 1.88), (300000, 2.32)):
            row = db.execute("SELECT DamageModifier,ScriptName FROM creature_template WHERE entry=?",
                             (entry + offset,)).fetchone()
            assert row == (round(22 * multiplier, 4), "boss_razorgore_coa" if entry == 12435 else "")
            for table, columns in COLUMNS.items():
                if table == "creature_template":
                    continue
                base = db.execute(f"SELECT * FROM `{table}` WHERE `{columns[0]}`=?", (entry,)).fetchone()
                variant = db.execute(f"SELECT * FROM `{table}` WHERE `{columns[0]}`=?",
                                     (entry + offset,)).fetchone()
                assert variant == (entry + offset, *base[1:]), (table, entry)
    for table, rows in before.items():
        if table == "creature_loot_template":
            continue
        untouched = [row for row in rows if row[0] in (*MC, 99999)]
        assert [row for row in after[table] if row[0] in (*MC, 99999)] == untouched, table
    verify_mysql(fixture_sql, SQL.read_text())
    print("PASS: BWL tier progression, MC-relative trash baselines, loot preservation, "
          "difficulty metadata, unaffected MC rows and migration idempotency")


if __name__ == "__main__":
    main()
