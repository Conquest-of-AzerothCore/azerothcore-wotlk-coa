import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest

from inspect_dbc import DataSet, project_fields
import schemas


def wdbc(rows, fields, size, strings=b''):
    return struct.pack('<4s4I', b'WDBC', len(rows), fields, size, len(strings)) + b''.join(rows) + strings


def spell(identity=700001, offset=1, base=-12, trigger=700002):
    row = bytearray(936)
    struct.pack_into('<I', row, 0, identity)
    struct.pack_into('<I', row, 16, 0x40)
    struct.pack_into('<I', row, 284, 6)
    struct.pack_into('<i', row, 320, base)
    struct.pack_into('<f', row, 916, .375)
    struct.pack_into('<I', row, 464, trigger)
    struct.pack_into('<I', row, 544, offset)
    struct.pack_into('<I', row, 680, offset)
    return row


class InspectorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name)
        self.file = self.path / 'Spell.dbc'
        self.file.write_bytes(wdbc([spell(), spell(700002, trigger=700001)], 234, 936, b'\0Alpha\0'))

    def tearDown(self):
        self.temp.cleanup()

    def fields(self, record):
        return {field['name']: field for field in record['fields']}

    def test_signed_float_string_flag_and_raw_values(self):
        row = DataSet(self.path).record('Spell', 700001)
        values = self.fields(row)
        self.assertEqual(row['name'], 'Alpha')
        self.assertEqual(values['EffectBasePoints[0]']['value'], -12)
        self.assertEqual(values['EffectBonusMultiplier[0]']['value'], .375)
        self.assertEqual(values['Description[enUS]']['value'], 'Alpha')
        self.assertEqual(values['Attributes']['labels'], ['SPELL_ATTR0_PASSIVE'])
        self.assertEqual(values['Effect[0]']['labels'], ['SPELL_EFFECT_APPLY_AURA'])
        self.assertEqual(values['EffectBasePoints[0]']['raw_hex'], 'f4ffffff')
        self.assertEqual(row['origin']['runtime'], 'not observed')
        self.assertIsNone(row['origin']['manifest_match'])

    def test_manifest_mismatch_is_visible(self):
        manifest = {'files': {'Spell.dbc': {'sha256': '0' * 64, 'archive': 'patch-T.MPQ'}}}
        (self.path / 'client-dbc.manifest.json').write_text(json.dumps(manifest))
        row = DataSet(self.path).record('Spell', 700001)
        self.assertFalse(row['origin']['manifest_match'])
        self.assertTrue(any('stale' in note for note in row['notes']))
        manifest['files']['Spell.dbc']['sha256'] = hashlib.sha256(self.file.read_bytes()).hexdigest()
        (self.path / 'client-dbc.manifest.json').write_text(json.dumps(manifest))
        self.assertTrue(DataSet(self.path).record('Spell', 700001)['origin']['manifest_match'])

    def test_bad_string_and_nonfinite_float_are_not_plausible_values(self):
        row = spell(offset=12345)
        struct.pack_into('<f', row, 916, float('nan'))
        self.file.write_bytes(wdbc([row], 234, 936, b'\0A\0'))
        result = DataSet(self.path).record('Spell', 700001)
        fields = self.fields(result)
        self.assertIsNone(fields['SpellName[enUS]']['value'])
        self.assertIn('outside', fields['SpellName[enUS]']['error'])
        self.assertIn('Non-finite', fields['EffectBonusMultiplier[0]']['error'])
        json.dumps(result, allow_nan=False)

    def test_wrong_layout_duplicate_id_and_truncation_fail_closed(self):
        invalid = [wdbc([spell()], 233, 936, b'\0'),
                   wdbc([spell(), spell()], 234, 936, b'\0'), self.file.read_bytes()[:-1]]
        for data in invalid:
            self.file.write_bytes(data)
            with self.subTest(size=len(data)), self.assertRaises(ValueError):
                DataSet(self.path).record('Spell', 700001)

    def test_packed_advancement_tail_is_opaque(self):
        row = bytearray(692)
        struct.pack_into('<I', row, 0, 91)
        struct.pack_into('<I', row, 20, 700001)
        struct.pack_into('<I', row, 104, 25)
        row[136:140] = b'\x01\x02\x03\x04'
        (self.path / 'CharacterAdvancement.dbc').write_bytes(wdbc([row], 179, 692))
        result = DataSet(self.path).record('CharacterAdvancement', 91)
        fields = self.fields(result)
        self.assertEqual(fields['RankSpell[0]']['reference'], {'table': 'Spell', 'id': 700001})
        self.assertEqual(fields['RequiredLevel']['value'], 25)
        self.assertTrue(any(f['type'] == 'bytes' and f['offset'] == 136 for f in result['fields']))

    def test_incoming_references_include_cycles_without_recursing(self):
        dataset = DataSet(self.path)
        edges = dataset.relationships('Spell', 700001)
        self.assertIn({'field': 'EffectTriggerSpell[0]', 'table': 'Spell', 'id': 700002}, edges['outgoing'])
        self.assertIn({'field': 'EffectTriggerSpell[0]', 'table': 'Spell', 'id': 700002}, edges['incoming'])

    def test_differences_include_client_descriptions_but_ignore_string_repacking(self):
        other = self.path / 'other'
        other.mkdir()
        target = other / 'Spell.dbc'
        target.write_bytes(wdbc([spell(offset=2)], 234, 936, b'\0\0Alpha\0'))
        self.assertEqual(DataSet(self.path).compare(DataSet(other), 'Spell', 700001)['differences'], [])
        row = spell(offset=2)
        struct.pack_into('<I', row, 680, 8)
        target.write_bytes(wdbc([row], 234, 936, b'\0\0Alpha\0Changed\0'))
        changes = DataSet(self.path).compare(DataSet(other), 'Spell', 700001)['differences']
        self.assertEqual([c['after']['name'] for c in changes], ['Description[enUS]'])

    def test_unknown_table_requires_row_selection(self):
        (self.path / 'Custom.dbc').write_bytes(wdbc([b'\x01\x02\x03'], 3, 3))
        dataset = DataSet(self.path)
        with self.assertRaises(ValueError):
            dataset.record('Custom', 1)
        row = dataset.record('Custom', row=0)
        self.assertEqual(row['fields'][0]['raw_hex'], '010203')
        self.assertEqual(row['origin']['schema'], 'unknown; raw bytes only')

    def test_cached_data_cannot_silently_survive_a_file_change(self):
        dataset = DataSet(self.path)
        dataset.record('Spell', 700001)
        self.file.write_bytes(wdbc([spell(base=-99)], 234, 936, b'\0Alpha\0'))
        with self.assertRaisesRegex(ValueError, 'changed while'):
            dataset.record('Spell', 700001)

    def test_search_pagination_and_no_matches(self):
        dataset = DataSet(self.path)
        result = dataset.search('Spell', 'alpha', offset=1, limit=1)
        self.assertEqual(result['total'], 2)
        self.assertEqual(result['records'][0]['id'], 700002)
        self.assertEqual(dataset.search('Spell', 'absent')['total'], 0)
        self.assertEqual(dataset.search('Spell', offset=1, limit=1)['records'][0]['id'], 700002)

    def test_agent_projection_preserves_provenance_and_rejects_typos(self):
        dataset = DataSet(self.path)
        row = dataset.record('spell', row=0)
        self.assertEqual(row['id'], 700001)
        projected = project_fields(row, ['EffectBasePoints[0]', 'Description*'])
        self.assertEqual(len(projected['fields']), 18)
        self.assertEqual(projected['origin'], row['origin'])
        with self.assertRaisesRegex(ValueError, 'No field matches'):
            project_fields(row, ['BasePionts'])
        self.assertEqual(dataset.schema('Spell')['record_bytes'], 936)
        self.assertTrue(dataset.relationships('spell', 700001)['incoming'])

    def test_sql_and_observations_are_separate_and_mismatched_evidence_is_rejected(self):
        capture = self.path / 'sql.json'
        capture.write_text(json.dumps({'schema': 1, 'resolved_spells': [700001],
                                      'tables': {'spell_bonus_data': {'rows': [{'entry': 700001}]}}}))
        scenario = {'name': 'sample', 'steps': [{'action': 'snapshot', 'spell': 700001, 'metric': 'damage'}]}
        (self.path / 'scenario.json').write_text(json.dumps(scenario))
        summary = {'scenario': 'sample', 'run_id': 'abc', 'status': 'passed',
                   'scenario_sha256': hashlib.sha256((self.path / 'scenario.json').read_bytes()).hexdigest()}
        (self.path / 'summary.json').write_text(json.dumps(summary))
        report = {'scenario': 'sample', 'run_id': 'abc', 'steps': [
            {'index': 0, 'action': 'snapshot', 'actual': '42', 'status': 'completed'}]}
        (self.path / 'result.json').write_text(json.dumps(report))
        dataset = DataSet(self.path, sql=capture, observations=[self.path])
        row = dataset.record('Spell', 700001)
        self.assertEqual(row['observations'][0]['samples'][0]['actual'], '42')
        self.assertIn('recorded observations', row['observations'][0]['scope'])
        self.assertEqual(dataset.record('Spell', 700002)['sql_layer']['status'], 'not observed for this spell')
        report['steps'][0]['action'] = 'cast'
        (self.path / 'result.json').write_text(json.dumps(report))
        with self.assertRaisesRegex(ValueError, 'action does not match'):
            DataSet(self.path, observations=[self.path])

    def test_named_schema_fields_match_native_core_formats(self):
        import client_dbc
        registry = schemas.registry()
        for name, fmt, _ in client_dbc.core_stores():
            schema = registry.get(Path(name).stem)
            if schema is None:
                continue
            self.assertEqual(schema.fields, len(fmt), name)
            by_offset = {field.offset: field for field in schema.columns}
            for i, kind in enumerate(fmt):
                if kind in 'xX':
                    continue
                self.assertIn(i * 4, by_offset, f'{name} field {i}')
                self.assertIn(by_offset[i * 4].kind, {'s': 's', 'f': 'f'}.get(kind, 'Ii'), f'{name} field {i}')


if __name__ == '__main__':
    unittest.main()
