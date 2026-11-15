import json
from pathlib import Path
import re
import sqlite3
import unittest


ROOT = Path(__file__).resolve().parents[3]
WORLD = ROOT / 'data/sql/updates/pending_db_world/rev_20261103_01_manastorm_coa_token_rewards.sql'
CHARACTERS = ROOT / 'data/sql/updates/pending_db_characters/rev_20261103_01_manastorm_coa_token_rewards.sql'


def migration(path):
    return re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', path.read_text(encoding='utf-8'))


def statement(name):
    path = ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp'
    source = path.read_text(encoding='utf-8')
    match = re.search(r'PrepareStatement\(' + name + r',\s*((?:"[^"\n]*"\s*)+), CONNECTION_', source)
    if not match:
        raise ValueError('Missing prepared statement ' + name)
    return ''.join(json.loads(part) for part in re.findall(r'"[^"\n]*"', match[1]))


def upsert(name):
    sql = statement(name)
    if name == 'CHAR_SAVE_MANASTORM_COA_TOKEN_WINDOW':
        sql = sql.replace('ON DUPLICATE KEY UPDATE revision = IF(revision = ?, revision + 1, 0)',
            'ON CONFLICT(guid) DO UPDATE SET revision = CASE WHEN revision = ? THEN revision + 1 ELSE 0 END')
    else:
        sql = sql.replace('ON DUPLICATE KEY UPDATE', 'ON CONFLICT(guid, mode, track, depth) DO UPDATE SET')
    return re.sub(r'VALUES\((\w+)\)', r'excluded.\1', sql)


class TokenDatabaseTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.executescript(migration(CHARACTERS))
        self.window = upsert('CHAR_SAVE_MANASTORM_COA_TOKEN_WINDOW')
        self.clear = upsert('CHAR_SAVE_MANASTORM_COA_TOKEN_CLEAR')

    def tearDown(self):
        self.db.close()

    def test_seed_is_idempotent_and_preserves_tuning(self):
        self.db.executescript(migration(WORLD))
        self.assertEqual(self.db.execute('SELECT first_clear_tokens, repeat_tokens '
            'FROM manastorm_coa_token_rewards').fetchone(), (25, 10))
        self.db.execute('UPDATE manastorm_coa_token_rewards SET first_clear_tokens=40, enabled=0')
        self.db.executescript(migration(WORLD))
        self.assertEqual(self.db.execute('SELECT COUNT(*), first_clear_tokens, enabled '
            'FROM manastorm_coa_token_rewards').fetchone(), (1, 40, 0))

    def test_clears_are_separate_by_character_mode_and_track(self):
        for guid, mode, track in [(1, 1, 1), (1, 2, 1), (1, 1, 2), (2, 1, 1)]:
            self.db.execute(self.clear, (guid, mode, track, 5, 1000))
        self.assertEqual(self.db.execute('SELECT COUNT(*) '
            'FROM character_manastorm_coa_token_clear').fetchone()[0], 4)
        self.db.execute(self.clear, (1, 1, 1, 5, 87400))
        self.assertEqual(self.db.execute('SELECT window_start FROM character_manastorm_coa_token_clear '
            'WHERE guid=1 AND mode=1 AND track=1').fetchone()[0], 87400)

    def test_repeat_uses_saved_expiry(self):
        self.db.execute(self.window, (1, 1000, 87400, 25, 0))
        self.db.execute(self.window, (1, 1000, 87400, 35, 1))
        self.assertEqual(self.db.execute('SELECT window_start, window_end, tokens_earned, revision '
            'FROM character_manastorm_coa_token_window').fetchone(), (1000, 87400, 35, 2))

    def test_stale_claim_rolls_back_clear_and_counters(self):
        self.db.execute(self.window, (1, 1000, 87400, 995, 0))
        self.db.commit()
        self.db.execute(self.window, (1, 1000, 87400, 1000, 1))
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute(self.clear, (1, 2, 2, 8, 1000))
                self.db.execute(self.window, (1, 1000, 87400, 1000, 1))
        self.assertEqual(self.db.execute('SELECT COUNT(*) '
            'FROM character_manastorm_coa_token_clear').fetchone()[0], 0)
        self.assertEqual(self.db.execute('SELECT tokens_earned, revision '
            'FROM character_manastorm_coa_token_window').fetchone(), (1000, 2))

    def test_initial_claim_cannot_overwrite_another_initial_claim(self):
        self.db.execute(self.window, (1, 1000, 87400, 25, 0))
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute(self.window, (1, 1001, 87401, 25, 0))

    def test_duplicate_receipt_rolls_back_token_award(self):
        self.db.execute('CREATE TABLE receipt (guid INTEGER, run INTEGER, depth INTEGER, '
            'PRIMARY KEY(guid, run, depth))')
        self.db.execute('INSERT INTO receipt VALUES(1,50,8)')
        self.db.execute(self.window, (1, 1000, 87400, 25, 0))
        self.db.commit()
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute(self.window, (1, 1000, 87400, 50, 1))
                self.db.execute('INSERT INTO receipt VALUES(1,50,8)')
        self.assertEqual(self.db.execute('SELECT tokens_earned '
            'FROM character_manastorm_coa_token_window').fetchone()[0], 25)


if __name__ == '__main__':
    unittest.main()
