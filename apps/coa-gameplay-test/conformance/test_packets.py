import json
from pathlib import Path
import tempfile
import unittest

from conformance import main
from packets import (PacketError, annotated_tooltip, chunk_spells, class_map_match, label_kinds, packet,
                     render_packet, write_packets)
from profile import DBC_DIR, load_class_file
from tooltip import Displayed, Readout
from values import dataset

TEMPLAR_CLASS_ID = 19
PARRY_DANCE = 804912
PARRY_DANCE_BUFF = 560651
ZEALOTRY = 92108
MISSING_SPELL = 99999999


def row(index, spell=PARRY_DANCE, bucket='D', labels=(), hits=None):
    return {'index': index, 'spell': spell, 'clause': f'clause {index}', 'bucket': bucket, 'evidence': 'data',
            'token_kind': 'value', 'script_touch': bool(hits), 'readable_token': True, 'labels': list(labels),
            'label_statuses': {label: 'ok' for label in labels}, 'missing_labels': [],
            'script_touch_hits': hits or {}}


BUCKET_ROWS = [row(376, labels=('804912 effect_value 560651e0 #0',),
                   hits={str(PARRY_DANCE_BUFF): {'id': ['src/server/coa/Example.cpp:184'], 'family': []}}),
               row(377, bucket='out_of_scope', labels=('804912 trigger_count',)),
               row(900, spell=ZEALOTRY)]
SAMPLE = {'chunks': {'1': {'spells': [ZEALOTRY], 'clauses': 1}, '2': {'spells': [PARRY_DANCE], 'clauses': 1}},
          'draws': [{'chunk': 2, 'clauses': [BUCKET_ROWS[0]]}, {'chunk': 1, 'clauses': [BUCKET_ROWS[2]]}]}
CLASS_MAP = {'classes': {str(TEMPLAR_CLASS_ID): {'spells': [
    {'spell': PARRY_DANCE, 'name': 'Parry Dance', 'risk': 'scripted', 'gap': 'covered_by_code',
     'custom_mechanics': [], 'log_casts': 0, 'log_other_events': 0, 'log_linked_events': 0},
    {'spell': 801446, 'name': 'Vindication', 'risk': 'scripted', 'gap': 'covered_by_code', 'custom_mechanics': [],
     'code_hits': ['src/server/coa/Example.cpp:19:code:573324'], 'log_casts': 4, 'log_other_events': 1,
     'log_linked_events': 2}]}}}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PacketTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dbc = dataset(DBC_DIR)
        cls.class_file = load_class_file(TEMPLAR_CLASS_ID)
        cls.data = packet(cls.dbc, cls.class_file, PARRY_DANCE, BUCKET_ROWS, {376}, CLASS_MAP)

    def test_tooltip_tokens_are_resolved_in_place(self):
        annotated = self.data['tooltip']['annotated']
        self.assertIn('$560651s1[=3]%', annotated)
        self.assertIn('stacking $560651u[=5] times', annotated)

    def test_effects_hold_the_spell_and_its_triggered_spell_with_dbc_labels(self):
        spells = [spell['spell'] for spell in self.data['effects']]
        self.assertEqual(spells, [PARRY_DANCE, PARRY_DANCE_BUFF])
        trigger = self.data['effects'][0]['effects'][1]
        self.assertEqual(trigger['EffectTriggerSpell'], str(PARRY_DANCE_BUFF))
        self.assertIn('SPELL_AURA_PROC_TRIGGER_SPELL', trigger['EffectApplyAuraName'])

    def test_ledger_rows_are_every_row_of_the_spell_marked_by_chunk(self):
        self.assertEqual([(found['index'], found['in_chunk']) for found in self.data['ledger_rows']],
                         [(376, True), (377, False)])
        self.assertEqual(self.data['script_touch_hits'],
                         {str(PARRY_DANCE_BUFF): {'id': ['src/server/coa/Example.cpp:184'], 'family': []}})

    def test_the_existing_entry_and_the_nearest_entry_of_its_kind_come_from_the_class_file(self):
        def spell_of(item):
            return item['entry'].get('aura', item['entry'].get('spell'))

        self.assertEqual([(item['section'], spell_of(item)) for item in self.data['class_entries']],
                         [('triggers', PARRY_DANCE), ('behaviours', PARRY_DANCE), ('behaviours', PARRY_DANCE_BUFF)])
        nearest = self.data['nearest_entries']
        self.assertEqual([(item['section'], item['kind']) for item in nearest],
                         [('behaviours', 'metric_delta'), ('triggers', None)])
        self.assertNotIn(PARRY_DANCE, [spell_of(item) for item in nearest])

    def test_class_map_fields_come_from_the_map_by_id_or_by_name_and_hit(self):
        self.assertEqual(self.data['class_map']['fields']['risk'], 'scripted')
        spells = CLASS_MAP['classes'][str(TEMPLAR_CLASS_ID)]['spells']
        by_name = class_map_match(spells, 573324, 'Vindication')
        self.assertEqual((by_name.fields['log_casts'], by_name.how.split()[2]), (4, '801446'))
        self.assertIsNone(class_map_match(spells, 573324, 'Other').fields)
        self.assertEqual(class_map_match([], PARRY_DANCE, 'Parry Dance').how, 'no class map given')

    def test_labels_name_check_kinds(self):
        self.assertEqual(label_kinds(['500678 behaviour_dispel_removal 55095', '92108 trigger_count',
                                      '524620 proc_rate', '1 behaviour_unknown_kind']),
                         [('behaviours', 'dispel_removal'), ('procs', None), ('triggers', None)])

    def test_a_token_missing_from_the_description_is_skipped(self):
        readout = Readout([Displayed('$s9', 1.0, None, 'flat'), Displayed('$s1', 2.0, 0, 'flat')], [])
        self.assertEqual(annotated_tooltip('by $s1 and $s1', readout), 'by $s1[=2] and $s1')

    def test_render_names_every_section(self):
        text = render_packet(self.data)
        for heading in ('## Tooltip', '## Class map', '## Spell.dbc effects', '## Script touch hits',
                        '## Ledger rows', '## Existing class-file entries', '## Nearest entry of the same check kind',
                        '## Fixtures'):
            self.assertIn(heading, text)

    def test_an_unknown_spell_or_chunk_is_refused(self):
        with self.assertRaises(PacketError):
            packet(self.dbc, self.class_file, MISSING_SPELL, BUCKET_ROWS, set())
        with self.assertRaises(PacketError):
            chunk_spells(SAMPLE, '3')

    def test_write_packets_writes_the_chunk_spells_the_same_way_twice(self):
        with tempfile.TemporaryDirectory() as out:
            first = write_packets(DBC_DIR, self.class_file, SAMPLE, '2', BUCKET_ROWS, Path(out), CLASS_MAP)
            text = first[0].read_text(encoding='utf-8')
            second = write_packets(DBC_DIR, self.class_file, SAMPLE, '2', BUCKET_ROWS, Path(out), CLASS_MAP)
            self.assertEqual([path.name for path in first], [f'{PARRY_DANCE}.md'])
            self.assertEqual(second[0].read_text(encoding='utf-8'), text)

    def test_the_command_writes_the_packets(self):
        with tempfile.TemporaryDirectory() as root:
            root = Path(root)
            (root / 'sample.json').write_text(json.dumps(SAMPLE), encoding='utf-8')
            (root / 'buckets.json').write_text(json.dumps({'clauses': BUCKET_ROWS}), encoding='utf-8')
            (root / 'map.json').write_text(json.dumps(CLASS_MAP), encoding='utf-8')
            code = main(['packets', '--class', str(TEMPLAR_CLASS_ID), '--sample', str(root / 'sample.json'),
                         '--chunk', '1', '--buckets', str(root / 'buckets.json'), '--class-map',
                         str(root / 'map.json'), '--out', str(root / 'out')])
            self.assertEqual(code, 0)
            self.assertTrue((root / 'out' / f'{ZEALOTRY}.md').is_file())


if __name__ == '__main__':
    unittest.main()
