import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from aura354 import Aura354Error, aura354_lines, aura354_rows
from conformance import main


def spell(spell_id, risk, mechanics, hits=()):
    return {'spell': spell_id, 'name': f'Spell {spell_id}', 'risk': risk, 'custom_mechanics': list(mechanics),
            'code_hits': list(hits)}


CLASS_MAP = {'classes': {'23': {'spells': [
    spell(1, 'scripted', ['11: effect 190', '11: aura 354'], ['src/A.cpp:1:code:11', 'b', 'c', 'd']),
    spell(2, 'stock', ['2: aura 354', '2: aura 354']),
    spell(3, 'data_row', ['3: aura 3540']),
    spell(4, 'data_row', ['4: aura 354']),
    spell(5, 'family_mask', [])]}}}


class Aura354Test(unittest.TestCase):
    def test_only_aura_354_spells_are_listed_and_those_without_class_code_flagged(self):
        rows = aura354_rows(CLASS_MAP, 23)
        self.assertEqual([(row['spell'], row['carriers'], row['candidate_defect']) for row in rows],
                         [(1, [11], False), (2, [2], True), (4, [4], True)])

    def test_lines_show_three_code_hits_and_a_summary(self):
        lines = aura354_lines(aura354_rows(CLASS_MAP, 23), 23)
        self.assertTrue(lines[0].endswith('src/A.cpp:1:code:11, b, c'))
        self.assertIn('CANDIDATE DEFECT', lines[1])
        self.assertEqual(lines[-1], 'class 23: 3 spells with aura 354, 2 candidate defects (risk stock or data_row)')

    def test_an_unknown_class_is_refused(self):
        with self.assertRaises(Aura354Error):
            aura354_rows(CLASS_MAP, 19)

    def test_the_command_prints_and_writes_the_rows(self):
        with tempfile.TemporaryDirectory() as name:
            class_map = Path(name) / 'class-map.json'
            class_map.write_text(json.dumps(CLASS_MAP), encoding='utf-8')
            out = Path(name) / 'aura354.json'
            with mock.patch('sys.stdout'):
                self.assertEqual(main(['aura354', '--class-map', str(class_map), '--class', '23', '--out',
                                       str(out)]), 0)
            self.assertEqual(len(json.loads(out.read_text(encoding='utf-8'))['spells']), 3)
            with mock.patch('sys.stderr'):
                self.assertEqual(main(['aura354', '--class-map', str(class_map), '--class', '19']), 2)


if __name__ == '__main__':
    unittest.main()
