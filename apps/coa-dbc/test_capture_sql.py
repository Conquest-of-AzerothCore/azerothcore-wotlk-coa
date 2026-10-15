import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import capture_sql


class CaptureTests(unittest.TestCase):
    def test_local_capture_follows_rank_chain_with_selects_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'server.conf'
            config.write_text('WorldDatabaseInfo = "127.0.0.1;3306;fixture_user;fixture_secret;world"\n')
            queries, option_files = [], []
            def database(command, *, input, **kwargs):
                self.assertNotIn('fixture_secret', ' '.join(command))
                option_file = Path(next(arg.split('=', 1)[1] for arg in command if arg.startswith('--defaults')))
                self.assertEqual(option_file.stat().st_mode & 0o777, 0o600)
                option_files.append(option_file)
                queries.append(input)
                self.assertTrue(input.startswith('SELECT '))
                if 'information_schema' in input:
                    table = next(name for name in capture_sql.TABLE_KEYS if f"'{name}'" in input)
                    values = ['first_spell_id', 'spell_id', 'rank'] if table == 'spell_ranks' else [
                        capture_sql.TABLE_KEYS[table]]
                elif 'FROM `spell_ranks`' in input:
                    values = [{'first_spell_id': 116, 'spell_id': 116, 'rank': 1},
                              {'first_spell_id': 116, 'spell_id': 205, 'rank': 2}]
                else:
                    values = []
                return SimpleNamespace(returncode=0, stdout='\n'.join(map(json.dumps, values)), stderr='')
            with patch.object(capture_sql.subprocess, 'run', side_effect=database):
                result = capture_sql.capture(config, 'mysql', [205])
            self.assertEqual(result['resolved_spells'], [116, 205])
            self.assertTrue(any('ABS(`SpellId`) IN (116,205)' in query for query in queries))
            self.assertNotIn('fixture_secret', json.dumps(result))
            self.assertTrue(all(not path.exists() for path in option_files))

    def test_invalid_ids_and_remote_endpoint_fail_before_query(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'server.conf'
            config.write_text('WorldDatabaseInfo = "remote.example;3306;user;secret;world"\n')
            with patch.object(capture_sql.subprocess, 'run') as query:
                for ids in ([], [-1], [True], [116]):
                    with self.subTest(ids=ids), self.assertRaises(ValueError):
                        capture_sql.capture(config, 'mysql', ids)
                query.assert_not_called()

    def test_quest_only_capture_uses_quest_keys_and_does_not_query_spell_ranks(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'server.conf'
            config.write_text('WorldDatabaseInfo = "127.0.0.1;3306;user;secret;world"\n')
            queries = []
            def database(command, *, input, **kwargs):
                queries.append(input)
                self.assertTrue(input.startswith('SELECT '))
                if 'information_schema' in input:
                    table = next(name for name in capture_sql.QUEST_KEYS if f"'{name}'" in input)
                    values = [capture_sql.QUEST_KEYS[table]]
                else:
                    values = []
                return SimpleNamespace(returncode=0, stdout='\n'.join(map(json.dumps, values)), stderr='')
            with patch.object(capture_sql.subprocess, 'run', side_effect=database):
                result = capture_sql.capture(config, 'mysql', [], [7])
            self.assertEqual(result['requested_quests'], [7])
            self.assertEqual(result['resolved_spells'], [])
            self.assertFalse(any('spell_ranks' in query for query in queries))
            self.assertTrue(any('FROM `creature_queststarter` WHERE `quest` IN (7)' in query for query in queries))


if __name__ == '__main__':
    unittest.main()
