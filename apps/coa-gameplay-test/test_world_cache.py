import copy
import json
from pathlib import Path
import re
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from world_cache import WorldCache, input_fingerprint, world_fingerprint

SERVER_UUID = '11111111-2222-3333-4444-555555555555'


class DatabaseFixture:
    def __init__(self, directory):
        self.directory = directory
        self.connections = {'world': SimpleNamespace(host='127.0.0.1', port=3306, database='source_world')}
        self.names = {'world': 'coa_test_012345abcdef_world'}
        self.schemas = {'source_world': {'data': 'original data', 'token': None}}
        self.copies = 0
        self.dropped = []

    def sql(self, role, statement, timeout=60):
        if statement == 'SELECT @@server_uuid;':
            return SERVER_UUID
        name = re.search(r'`([^`]+)`', statement)[1]
        if statement.startswith('CREATE DATABASE'):
            if name in self.schemas:
                raise ValueError('Database already exists')
            self.schemas[name] = {'data': '', 'token': None}
        elif statement.startswith('DROP DATABASE'):
            self.dropped.append(name)
            del self.schemas[name]
        elif statement.startswith('CREATE TABLE'):
            self.schemas[name]['token'] = re.search(r"VALUES \('([0-9a-f]+)'\)", statement)[1]
        elif statement.startswith('SELECT token'):
            return self.schemas[name]['token']
        else:
            raise AssertionError(statement)
        return ''

    def copy(self, role):
        self.copies += 1
        self.schemas[self.names[role]] = copy.deepcopy(self.schemas['source_world'])


class WorldCacheTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.database = DatabaseFixture(self.directory)
        patched = patch('world_cache.world_fingerprint',
                        side_effect=lambda database, name: database.schemas[name]['data'])
        patched.start()
        self.addCleanup(patched.stop)

    def cache(self, inputs='source SQL/config v1'):
        return WorldCache(self.database, self.directory / 'cache', inputs)

    def run_clean(self, cache, startup_data=None):
        cache.prepare()
        if startup_data:
            self.database.schemas[cache.name]['data'] = startup_data
        cache.ready({'waiting_for_start': 'true'}, self.directory / 'start.json', '012345abcdef')
        self.assertEqual(json.loads((self.directory / 'start.json').read_text())['run_id'], '012345abcdef')
        cache.finish()
        self.assertTrue(cache.info['retained'])

    def test_second_run_reuses_world_after_startup_updates(self):
        first = self.cache()
        self.run_clean(first, startup_data='migrations applied')
        second = self.cache()
        self.run_clean(second)
        self.assertEqual(self.database.copies, 1)
        self.assertEqual(first.name, second.name)
        self.assertEqual(second.info['mode'], 'reused')
        self.assertEqual(self.database.schemas[second.name]['data'], 'migrations applied')

    def test_source_data_changes_refresh_owned_copy(self):
        first = self.cache()
        self.run_clean(first)
        self.database.schemas['source_world']['data'] = 'new spell data'
        second = self.cache()
        self.run_clean(second)
        self.assertEqual(self.database.copies, 2)
        self.assertEqual(self.database.dropped, [first.name])
        self.assertEqual(second.info['mode'], 'refreshed')
        self.assertEqual(self.database.schemas[second.name]['data'], 'new spell data')

    def test_sql_or_configuration_change_refreshes_copy(self):
        first = self.cache()
        self.run_clean(first)
        second = self.cache(inputs='uncommitted SQL change')
        self.run_clean(second)
        self.assertEqual(self.database.copies, 2)
        self.assertEqual(self.database.dropped, [first.name])

    def test_external_cache_edit_cannot_become_starting_state(self):
        first = self.cache()
        self.run_clean(first)
        self.database.schemas[first.name]['data'] = 'unexpected edit'
        second = self.cache()
        self.run_clean(second)
        self.assertEqual(second.info['mode'], 'refreshed')
        self.assertEqual(self.database.schemas[second.name]['data'], 'original data')

    def test_explicit_refresh_replaces_an_unchanged_copy(self):
        first = self.cache()
        self.run_clean(first)
        second = self.cache()
        second.prepare(refresh=True)
        self.assertEqual(second.info['mode'], 'refreshed')
        self.assertNotEqual(first.name, second.name)
        second.finish()
        self.assertEqual(set(self.database.schemas), {'source_world'})

    def test_scenario_world_writes_invalidate_cache(self):
        cache = self.cache()
        cache.prepare()
        cache.ready({'waiting_for_start': True}, self.directory / 'start.json', '012345abcdef')
        self.database.schemas[cache.name]['data'] = 'scenario changed a spawn'
        cache.finish()
        self.assertFalse(cache.info['retained'])
        self.assertIn('invalidated', cache.info)
        self.assertEqual(set(self.database.schemas), {'source_world'})
        self.assertFalse(cache.lock.exists())

    def test_partial_copy_cleanup_drops_only_owned_schema(self):
        cache = self.cache()
        with patch.object(self.database, 'copy', side_effect=ValueError('copy failed')):
            with self.assertRaisesRegex(ValueError, 'copy failed'):
                cache.prepare()
        cache.finish()
        self.assertEqual(set(self.database.schemas), {'source_world'})
        self.assertFalse(cache.path.exists())

    def test_name_collision_is_never_adopted_or_dropped(self):
        name = 'coa_test_aaaaaaaaaaaa_world'
        self.database.schemas[name] = {'data': 'unrelated', 'token': None}
        cache = self.cache()
        with patch('world_cache.secrets.token_hex', side_effect=lambda count: 'a' * (2 * count)):
            with self.assertRaisesRegex(ValueError, 'already exists'):
                cache.prepare()
        cache.finish()
        self.assertEqual(self.database.schemas[name]['data'], 'unrelated')
        self.assertEqual(self.database.dropped, [])

    def test_ownership_mismatch_refuses_even_explicit_refresh(self):
        first = self.cache()
        self.run_clean(first)
        self.database.schemas[first.name]['token'] = 'somebody else'
        second = self.cache()
        with self.assertRaisesRegex(ValueError, 'ownership mismatch'):
            second.prepare(refresh=True)
        second.finish()
        self.assertEqual(self.database.dropped, [])

    def test_empty_server_identity_is_retried_without_creating_a_different_cache(self):
        first = self.cache()
        with patch.object(self.database, 'sql', side_effect=['', SERVER_UUID]) as query:
            second = self.cache()
        self.assertEqual(first.identity, second.identity)
        self.assertEqual(query.call_count, 2)

    def test_missing_server_identity_never_acquires_a_cache(self):
        with patch.object(self.database, 'sql', return_value='') as query:
            with self.assertRaisesRegex(ValueError, 'no data after three reads'):
                self.cache()
        self.assertEqual(query.call_count, 3)
        self.assertEqual(self.database.copies, 0)
        self.assertEqual(self.database.dropped, [])

    def test_truncated_server_identity_is_not_a_new_cache_key(self):
        with patch.object(self.database, 'sql', return_value=SERVER_UUID[:8]):
            with self.assertRaisesRegex(ValueError, 'not a complete MySQL UUID'):
                self.cache()
        self.assertEqual(self.database.copies, 0)

    def test_empty_ownership_read_retries_but_a_real_mismatch_still_fails(self):
        first = self.cache()
        self.run_clean(first)
        with patch.object(self.database, 'sql', side_effect=['', first.metadata['token']]) as query:
            first.verify_owner()
        self.assertEqual(query.call_count, 2)
        with patch.object(self.database, 'sql', side_effect=['', 'somebody else']) as query:
            with self.assertRaisesRegex(ValueError, 'ownership mismatch'):
                first.verify_owner()
        self.assertEqual(query.call_count, 2)
        self.assertEqual(self.database.dropped, [])

    def test_concurrent_run_does_not_remove_other_lease(self):
        first = self.cache()
        first.prepare()
        second = self.cache()
        with self.assertRaisesRegex(ValueError, 'leased'):
            second.prepare()
        second.finish()
        self.assertTrue(first.lock.exists())
        first.finish()

    def test_lease_points_to_results_instead_of_temporary_credentials(self):
        results = self.directory / 'results'
        cache = WorldCache(self.database, self.directory / 'cache', 'inputs', result_directory=results)
        cache.prepare()
        self.assertEqual(json.loads(cache.lock.read_text())['results'], str(results))
        cache.finish()

    def test_unstoppable_child_retains_world_and_exclusive_lease(self):
        first = self.cache()
        first.prepare()
        first.finish(server_still_running=True)
        self.assertIn(first.name, self.database.schemas)
        self.assertTrue(first.lock.exists())
        with self.assertRaisesRegex(ValueError, 'leased'):
            self.cache().prepare(refresh=True)
        first.finish()

    def test_copy_rejects_concurrent_source_changes(self):
        cache = self.cache()
        copy_world = self.database.copy

        def changing_source(role):
            copy_world(role)
            self.database.schemas['source_world']['data'] = 'changed during snapshot'

        with patch.object(self.database, 'copy', side_effect=changing_source):
            with self.assertRaisesRegex(ValueError, 'changed while copying'):
                cache.prepare()
        cache.finish()
        self.assertEqual(set(self.database.schemas), {'source_world'})

    def test_failed_audit_requires_refresh_before_reuse(self):
        first = self.cache()
        first.prepare()
        first.ready({'waiting_for_start': True}, self.directory / 'start.json', '012345abcdef')
        with patch('world_cache.world_fingerprint', side_effect=ValueError('checksum timed out')):
            with self.assertRaisesRegex(ValueError, 'checksum timed out'):
                first.finish()
        self.assertFalse(first.lock.exists())
        self.assertEqual(json.loads(first.path.read_text())['state'], 'invalid')
        second = self.cache()
        self.run_clean(second)
        self.assertEqual(second.info['mode'], 'refreshed')
        self.assertEqual(self.database.dropped, [first.name])

    def test_missing_native_barrier_never_releases_scenario(self):
        cache = self.cache()
        cache.prepare()
        with self.assertRaisesRegex(ValueError, 'startup barrier'):
            cache.ready({'status': 'ready'}, self.directory / 'start.json', '012345abcdef')
        self.assertFalse((self.directory / 'start.json').exists())
        cache.finish()

    def test_source_name_in_manifest_is_rejected_without_database_mutation(self):
        first = self.cache()
        self.run_clean(first)
        metadata = json.loads(first.path.read_text())
        metadata['world_id'] = 'source_world'
        first.path.write_text(json.dumps(metadata))
        second = self.cache()
        with self.assertRaisesRegex(ValueError, 'Invalid cached world ID'):
            second.prepare(refresh=True)
        second.finish()
        self.assertEqual(self.database.dropped, [])


class FingerprintTests(unittest.TestCase):
    def test_environment_configuration_changes_invalidate_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = root / 'worldserver.conf'
            config.write_text('Rate.XP.Kill = 1\n')
            original = input_fingerprint(root, config, root, {'AC_RATE_XP_KILL': '1', 'PATH': 'old'})
            self.assertEqual(original,
                             input_fingerprint(root, config, root, {'AC_RATE_XP_KILL': '1', 'PATH': 'new'}))
            self.assertNotEqual(original, input_fingerprint(root, config, root, {'AC_RATE_XP_KILL': '2'}))

    def test_inputs_include_sql_and_configs_but_not_binary_or_cpp_changes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            module = root / 'modules/example'
            module.mkdir(parents=True)
            config = root / 'worldserver.conf'
            config.write_text('source configuration')
            original = input_fingerprint(root, config, module)
            (module / 'test.cpp').write_text('new code')
            self.assertEqual(input_fingerprint(root, config, module), original)
            (module / 'update.sql').write_text('new data')
            updated = input_fingerprint(root, config, module)
            self.assertNotEqual(updated, original)
            (module / 'settings.conf').write_text('new settings')
            self.assertNotEqual(input_fingerprint(root, config, module), updated)

    def test_fingerprint_checks_data_and_definitions_and_rejects_null_checksums(self):
        database = SimpleNamespace(sql=None)
        responses = ['spells\tBASE TABLE', 'world.spells\t123', 'spells\tCREATE TABLE spells (...)', '0']
        with patch.object(database, 'sql', side_effect=responses):
            original = world_fingerprint(database, 'world')
        for changed in (
            [responses[0], 'world.spells\t456', responses[2], '0'],
            [responses[0], responses[1], 'spells\tCREATE TABLE spells (new_column INT)', '0'],
        ):
            with patch.object(database, 'sql', side_effect=changed):
                self.assertNotEqual(world_fingerprint(database, 'world'), original)
        with patch.object(database, 'sql', side_effect=[responses[0], 'world.spells\tNULL']):
            with self.assertRaisesRegex(ValueError, 'checksum unavailable'):
                world_fingerprint(database, 'world')

    def test_persistent_programs_cannot_escape_the_cache_audit(self):
        database = SimpleNamespace(sql=None)
        responses = ['spells\tBASE TABLE', 'world.spells\t123', 'spells\tCREATE TABLE spells (...)', '1']
        with patch.object(database, 'sql', side_effect=responses):
            with self.assertRaisesRegex(ValueError, 'excludes triggers/routines/events'):
                world_fingerprint(database, 'world')

    def test_incomplete_definitions_are_retried_but_never_used_as_a_fingerprint(self):
        database = SimpleNamespace(sql=None)
        prefix = ['spells\tBASE TABLE', 'world.spells\t123']
        definitions = 'spells\tCREATE TABLE spells (...)'
        with patch.object(database, 'sql', side_effect=prefix + [definitions, '0']):
            expected = world_fingerprint(database, 'world')
        with patch.object(database, 'sql', side_effect=prefix + ['', definitions, '0']):
            self.assertEqual(world_fingerprint(database, 'world'), expected)
        with patch.object(database, 'sql', side_effect=prefix + ['', '', '']) as query:
            with self.assertRaisesRegex(ValueError, 'Incomplete world table definitions'):
                world_fingerprint(database, 'world')
        self.assertEqual(query.call_count, 5)


if __name__ == '__main__':
    unittest.main()
