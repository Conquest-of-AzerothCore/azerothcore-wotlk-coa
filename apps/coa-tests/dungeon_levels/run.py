from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[3]
MIGRATION = ROOT / 'data/sql/updates/pending_db_world/rev_20260926_01_vanilla_dungeon_levels.sql'


def main():
    connection = sqlite3.connect(':memory:')
    connection.execute('CREATE TABLE creature_template (entry INTEGER PRIMARY KEY, minlevel INTEGER, '
                       'maxlevel INTEGER, HealthModifier REAL, DamageModifier REAL)')
    initial = [(13036, 57, 59, 1.0, 3.9), (113036, 57, 59, 1.0, 3.9),
               (213036, 57, 59, 1.0, 3.9), (639, 20, 20, 4.0, 8.0),
               (100639, 20, 20, 4.0, 8.0), (200639, 20, 20, 4.0, 8.0),
               (999999, 42, 43, 2.0, 2.0)]
    connection.executemany('INSERT INTO creature_template VALUES (?, ?, ?, ?, ?)', initial)
    if MIGRATION.exists():
        connection.executescript(MIGRATION.read_text(encoding='utf-8'))
    expected = {113036: (60, 60), 213036: (60, 60), 100639: (63, 63), 200639: (63, 63)}
    for entry, low, high, health, damage in initial:
        actual = connection.execute(
            'SELECT minlevel, maxlevel, HealthModifier, DamageModifier FROM creature_template WHERE entry = ?',
            (entry,)).fetchone()
        assert actual == (*expected.get(entry, (low, high)), health, damage), (entry, actual)
    before = connection.execute('SELECT * FROM creature_template ORDER BY entry').fetchall()
    connection.executescript(MIGRATION.read_text(encoding='utf-8'))
    assert before == connection.execute('SELECT * FROM creature_template ORDER BY entry').fetchall()
    print('PASS: attested Mastiff and VanCleef levels; unchanged Normal/combat values; idempotent migration')


if __name__ == '__main__':
    main()
