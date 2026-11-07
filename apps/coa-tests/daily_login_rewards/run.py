import json
from pathlib import Path
import re
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[3]


class DailyLoginTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        schema = (ROOT / 'data/sql/updates/pending_db_characters/rev_20261104_01_coa_daily_login.sql') \
            .read_text(encoding='utf-8')
        self.db.executescript(re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', schema))
        self.db.execute('CREATE TABLE reward_mail (account_id INTEGER, quantity INTEGER)')
        source = (ROOT / 'src/server/database/Database/Implementation/CharacterDatabase.cpp') \
            .read_text(encoding='utf-8')
        pattern = r'PrepareStatement\(CHAR_CLAIM_COA_DAILY_LOGIN,\s*((?:"[^"\n]*"\s*)+), CONNECTION_'
        statement = re.search(pattern, source)[1]
        self.claim = ''.join(json.loads(part) for part in re.findall(r'"[^"\n]*"', statement))
        self.claim = self.claim.replace('ON DUPLICATE KEY UPDATE', 'ON CONFLICT(account_id) DO UPDATE SET')
        self.claim = self.claim.replace('IF(next_claim_at <= ? AND claim_number = ?, claim_number + 1, 0)',
            'CASE WHEN next_claim_at <= ? AND claim_number = ? THEN claim_number + 1 ELSE 0 END')
        self.claim = re.sub(r'VALUES\((\w+)\)', r'excluded.\1', self.claim)

    def tearDown(self):
        self.db.close()

    def award(self, account, now, revision):
        with self.db:
            self.db.execute(self.claim, (account, now, now + 86400, now, revision))
            self.db.execute('INSERT INTO reward_mail VALUES (?, 200)', (account,))

    def test_shared_account_cooldown_and_independent_accounts(self):
        self.award(1, 1000, 0)
        with self.assertRaises(sqlite3.IntegrityError):
            self.award(1, 1001, 1)
        self.award(2, 1001, 0)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM reward_mail').fetchone()[0], 2)

    def test_exact_expiry_and_clock_rollback(self):
        self.award(1, 1000, 0)
        for now in (999, 87399):
            with self.assertRaises(sqlite3.IntegrityError):
                self.award(1, now, 1)
        self.award(1, 87400, 1)
        self.assertEqual(self.db.execute('SELECT next_claim_at, claim_number FROM account_coa_daily_login')
            .fetchone(), (173800, 2))

    def test_stale_simultaneous_claim_rolls_back(self):
        self.award(1, 1000, 0)
        with self.assertRaises(sqlite3.IntegrityError):
            self.award(1, 1000, 0)
        self.award(1, 87400, 1)
        with self.assertRaises(sqlite3.IntegrityError):
            self.award(1, 173800, 1)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM reward_mail').fetchone()[0], 2)

    def test_failure_rolls_back_cooldown(self):
        with self.assertRaises(sqlite3.IntegrityError):
            with self.db:
                self.db.execute(self.claim, (1, 1000, 87400, 1000, 0))
                self.db.execute('INSERT INTO account_coa_daily_login VALUES (2, 0, 0, 0)')
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM account_coa_daily_login').fetchone()[0], 0)
        self.award(1, 1000, 0)

    def test_reward_seed_preserves_tuning(self):
        text = (ROOT / 'data/sql/updates/pending_db_world/rev_20261104_01_coa_daily_login.sql') \
            .read_text(encoding='utf-8')
        text = re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', text).replace('INSERT IGNORE', 'INSERT OR IGNORE')
        self.db.executescript(text)
        self.assertEqual(self.db.execute('SELECT item_entry, quantity FROM coa_daily_login_rewards').fetchone(),
            (975001, 200))
        self.db.execute('UPDATE coa_daily_login_rewards SET quantity=300, enabled=0')
        self.db.executescript(text)
        self.assertEqual(self.db.execute('SELECT quantity, enabled FROM coa_daily_login_rewards').fetchone(), (300, 0))

    def test_publication_order_and_login_guards(self):
        source = (ROOT / 'src/server/coa/AscensionDailyLogin.cpp').read_text(encoding='utf-8')
        completion = source.split('void CompleteDailyLogin(', 1)[1].split('void GrantDailyLogin(', 1)[0]
        self.assertLess(completion.index('AsyncCommitTransaction'), completion.index('mail->PublishStagedMail'))
        self.assertLess(completion.index('mail->PublishStagedMail'), completion.index('ShowRewardToast(current,'))
        for guard in ('draft->DiscardItems()', 'session->IsBot()',
                      '!current->IsInWorld()', '"Daily Login Reward"', 'HandleItemQuerySingleOpcode'):
            self.assertIn(guard, source)
        self.assertNotIn('AscensionWildcard', source)
        self.assertNotIn('ReadRealm()', source)


if __name__ == '__main__':
    unittest.main()
