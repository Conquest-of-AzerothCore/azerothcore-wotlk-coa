from pathlib import Path
import re
import runpy
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-manastorm-endless/src'


class EncounterTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        for name in ('rev_20261103_01_manastorm_coa_token_rewards.sql',
                     'rev_20261104_02_manastorm_coa_encounter_rewards.sql'):
            sql = (ROOT / 'data/sql/updates/pending_db_characters' / name).read_text()
            self.db.executescript(re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', sql))
        helpers = runpy.run_path(str(ROOT / 'apps/coa-tests/manastorm_coa_token_sql/run.py'))
        self.save = helpers['upsert']('CHAR_SAVE_MANASTORM_COA_TOKEN_WINDOW')
        self.receipt = helpers['statement']('CHAR_INS_MANASTORM_COA_ENCOUNTER')
        self.db.execute('CREATE TABLE reward_delivery (quantity INTEGER, gold INTEGER)')

    def tearDown(self):
        self.db.close()

    def claim(self, receipt, guid=1, requested=100, earned=0, revision=0):
        quantity = min(requested, max(0, 1000 - earned))
        with self.db:
            self.db.execute(self.receipt, (receipt, guid))
            self.db.execute(self.save, (guid, 1000, 87400, earned + quantity, revision))
            self.db.execute('INSERT INTO reward_delivery VALUES (?, 930000)', (quantity,))

    def test_receipt_is_global_and_rejects_repeated_loot(self):
        self.claim('one-object')
        with self.assertRaises(sqlite3.IntegrityError):
            self.claim('one-object', guid=2)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM reward_delivery').fetchone()[0], 1)

    def test_shared_partial_cap_and_gold_at_cap(self):
        self.db.execute(self.save, (1, 1000, 87400, 995, 0))
        self.db.commit()
        self.claim('first', earned=995, revision=1)
        self.claim('second', earned=1000, revision=2)
        self.assertEqual(self.db.execute('SELECT * FROM reward_delivery').fetchall(), [(5, 930000), (0, 930000)])

    def test_stale_allowance_rolls_back_receipt_and_delivery(self):
        self.claim('first')
        with self.assertRaises(sqlite3.IntegrityError):
            self.claim('second')
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM character_manastorm_coa_encounter').fetchone()[0], 1)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM reward_delivery').fetchone()[0], 1)

    def test_seed_and_replay_preserve_tuning(self):
        sql = (ROOT / 'data/sql/updates/pending_db_world/rev_20261104_02_manastorm_coa_encounter_rewards.sql').read_text()
        sql = re.sub(r'\) ENGINE=InnoDB[^;]*;', ');', sql).replace('INSERT IGNORE', 'INSERT OR IGNORE')
        self.db.executescript(sql)
        self.assertEqual(self.db.execute('SELECT * FROM manastorm_coa_encounter_rewards ORDER BY source, quality')
            .fetchall(), [(1, 2, 25), (1, 3, 50), (1, 4, 100), (2, 0, 50)])
        self.db.execute('UPDATE manastorm_coa_encounter_rewards SET tokens=75 WHERE source=2')
        self.db.executescript(sql)
        self.assertEqual(self.db.execute('SELECT tokens FROM manastorm_coa_encounter_rewards WHERE source=2')
            .fetchone()[0], 75)

    def test_reward_routing_and_rollback_wiring(self):
        source = (MODULE / 'ManastormRewards.cpp').read_text()
        greedy = source.split('bool ManastormRewards::AwardCoAGreedyReward(', 1)[1].split(
            'std::string ManastormRewards::CoATokenClientState', 1)[0]
        self.assertIn('IsCoALootMode(guid)', greedy)
        self.assertIn('AppendCoAAllowance', greedy)
        self.assertLess(greedy.index('SaveGoldToDB(transaction)'), greedy.index('AsyncCommitTransaction'))
        self.assertLess(greedy.index('AsyncCommitTransaction'), greedy.index('PublishCommitted(publications)'))
        self.assertIn('player->SetMoney(previousGold)', greedy)
        self.assertIn('entry == 1478051', source)
        self.assertIn('"item_manastorm_material_cache"', source)
        self.assertIn('if (!IsCoAMaterialCache(cacheItemEntry))', source)
        self.assertIn('cacheCount = 0;', source)
        self.assertIn('error, encounterTokens)', source)
        self.assertIn('bonusTokens=', source)
        ui = (MODULE / 'ManastormClientUIFixes.cpp').read_text()
        self.assertIn('quantity + (data.bonusTokens or 0)', ui)
        source = (MODULE / 'ManastormGreedyDemon.cpp').read_text().split('bool ManastormGreedyDemon::ClaimLoot(', 1)[1]
        self.assertIn('if (!coaLoot)', source)
        self.assertIn('HasGameObjectFlag(GO_FLAG_NOT_SELECTABLE)', source)
        self.assertIn('RemoveGameObjectFlag(GO_FLAG_NOT_SELECTABLE)', source)


if __name__ == '__main__':
    unittest.main()
