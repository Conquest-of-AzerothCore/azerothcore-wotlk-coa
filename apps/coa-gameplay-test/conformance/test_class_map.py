import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

import class_map
from class_map import (base_candidates, clean, core_reading, family_masks, handler_table, log_events, named_auras,
                       number_index, source_kind, token_kind)
from profile import DBC_DIR

ROOT = Path(__file__).resolve().parents[3]
TEMPLAR_CLASS_ID = 19
ABSOLUTION = 800424
SHOOT = 3018


def spell_row(effects=(0, 0, 0), auras=(0, 0, 0), misc=(0, 0, 0)):
    row = {}
    for slot in range(3):
        row[f'Effect[{slot}]'] = effects[slot]
        row[f'EffectApplyAuraName[{slot}]'] = auras[slot]
        row[f'EffectMiscValue[{slot}]'] = misc[slot]
    return row


def write(root, relative, text):
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')
    return path


class TooltipTextTest(unittest.TestCase):
    def test_token_kinds_follow_the_letter(self):
        self.assertEqual(token_kind('$s1'), 'value')
        self.assertEqual(token_kind('$520659d'), 'duration')
        self.assertEqual(token_kind('$h'), 'chance')
        self.assertEqual(token_kind('$a1'), 'radius')
        self.assertEqual(token_kind('$u'), 'stacks')
        self.assertEqual(token_kind('$/10;s1'), 'value')
        self.assertEqual(token_kind('${$m1*2}'), 'formula')
        self.assertEqual(token_kind('$<damage>'), 'variable')
        self.assertEqual(token_kind('$q'), 'other')

    def test_clean_drops_colors_markup_and_conditions(self):
        self.assertEqual(clean('|cFFFFFFFFDeals|r $s1 damage'), 'Deals $s1 damage')
        self.assertEqual(clean('$?s705306[more][less]'), '[more][less]')

    def test_source_kind_marks_data_headers(self):
        self.assertEqual(source_kind(Path('src/server/coa/AscensionTemplarData.h')), 'data')
        self.assertEqual(source_kind(Path('src/server/coa/AscensionTemplar.cpp')), 'code')


class CoreReadingTest(unittest.TestCase):
    EFFECTS = ['EffectNULL', 'EffectInstaKill', 'EffectDummy', 'EffectUnused']
    AURAS = ['HandleNULL', 'HandleAuraDummy', 'nullptr', 'HandleModDamage']

    def test_unhandled_and_script_only_effects_are_listed(self):
        unhandled, script_only, custom = core_reading(spell_row(effects=(3, 2, 0)), self.EFFECTS, self.AURAS, {})
        self.assertEqual(unhandled, ['effect 3 EffectUnused'])
        self.assertEqual(script_only, ['effect 2 EffectDummy'])
        self.assertEqual(custom, [])

    def test_an_aura_past_the_table_is_unhandled(self):
        unhandled, _, _ = core_reading(spell_row(auras=(9, 0, 0)), self.EFFECTS, self.AURAS, {})
        self.assertEqual(unhandled, ['aura 9 out of range'])

    def test_a_nullptr_aura_named_in_code_is_not_unhandled(self):
        unhandled, _, _ = core_reading(spell_row(auras=(2, 0, 0)), self.EFFECTS, self.AURAS,
                                       {2: 'SPELL_AURA_EXAMPLE'})
        self.assertEqual(unhandled, [])
        unhandled, _, _ = core_reading(spell_row(auras=(2, 0, 0)), self.EFFECTS, self.AURAS, {})
        self.assertEqual(unhandled, ['aura 2 nullptr'])

    def test_stock_passive_effects_are_left_out(self):
        unhandled, _, _ = core_reading(spell_row(effects=(20, 78, 0)), self.EFFECTS, self.AURAS, {})
        self.assertEqual(unhandled, [])

    def test_custom_mechanics_are_listed(self):
        row = spell_row(effects=(165, 0, 0), auras=(0, 354, 107), misc=(0, 0, 30))
        _, _, custom = core_reading(row, self.EFFECTS, self.AURAS, {})
        self.assertEqual(custom, ['effect 165', 'aura 354', 'modifier operation 30'])

    def test_a_spell_modifier_operation_past_the_maximum_is_unhandled(self):
        unhandled, _, _ = core_reading(spell_row(auras=(107, 0, 0), misc=(40, 0, 0)), self.EFFECTS,
                                       ['HandleNULL'] * 110, {})
        self.assertIn('aura 107 modifier operation 40', unhandled)


class SourceReadingTest(unittest.TestCase):
    def test_handler_table_reads_names_and_nullptr(self):
        with tempfile.TemporaryDirectory() as directory:
            path = write(Path(directory), 'SpellEffects.cpp',
                         'pEffect SpellEffects[TOTAL] =\n{\n    &Spell::EffectNULL,  //  0\n'
                         '    &Spell::EffectInstaKill, //  1\n    nullptr, //  2\n};\n')
            self.assertEqual(handler_table(path, 'pEffect SpellEffects['),
                             ['EffectNULL', 'EffectInstaKill', 'nullptr'])

    def test_named_auras_keeps_the_names_code_uses(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, 'src/server/game/Spells/Auras/SpellAuraDefines.h',
                  '    SPELL_AURA_USED = 354,\n    SPELL_AURA_UNUSED = 355,\n')
            write(root, 'src/server/coa/Example.cpp', 'if (type == SPELL_AURA_USED) {}\n')
            write(root, 'src/server/scripts/Example.cpp', 'SPELL_AURA_UNUSED_OTHER\n')
            self.assertEqual(named_auras(root), {354: 'SPELL_AURA_USED'})

    def test_number_index_kinds_and_core_minimum(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, 'src/server/coa/Example.cpp', 'case 800424:\n')
            write(root, 'src/server/coa/ExampleData.h', '{ 800424, 3 },\n')
            write(root, 'src/server/coa/CoAGameplayTest.cpp', 'case 800424:\n')
            write(root, 'src/server/game/Example.cpp', 'case 9999:\ncase 12345:\n')
            index, sources = number_index(root)
            self.assertEqual(sorted(index[800424]), [('src/server/coa/Example.cpp', 1, 'code'),
                                                     ('src/server/coa/ExampleData.h', 1, 'data')])
            self.assertEqual(index[12345], [('src/server/game/Example.cpp', 2, 'core')])
            self.assertNotIn(9999, index)
            self.assertNotIn('src/server/coa/CoAGameplayTest.cpp', sources)

    def test_family_masks_reads_the_three_forms(self):
        text = ('Family(info, 1, 64) SpellFamilyFlags[2] & 8 flag96(0, 4, 0) Family(info, 0, 0)')
        self.assertEqual(family_masks(text), {(1, 64), (2, 8), (1, 4)})

    def test_base_candidates_reads_the_class_spells_block(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            write(root, 'src/server/coa/AscensionCustomClassData.h',
                  'ClassSpells =\n{\n    { 19, 1, 3018 },\n    { 19, 10, 800424 },\n    { 20, 1, 5 },\n};\n'
                  'LegacyGeneratedClassSpells =\n{\n    { 19, 1, 1 },\n};\n')
            self.assertEqual(base_candidates(root), {19: {3018: 1, 800424: 10}, 20: {5: 1}})

    def test_log_events_split_casts_from_other_events(self):
        with tempfile.TemporaryDirectory() as directory:
            path = write(Path(directory), 'events.csv',
                         'SPELL_CAST_SUCCESS,800424,3\nSPELL_CAST_START,800424,2\nSPELL_DAMAGE,800424,7\n')
            casts, others = log_events(path)
            self.assertEqual(casts[800424], 5)
            self.assertEqual(others[800424], 7)
            self.assertEqual(log_events(Path(directory) / 'missing.csv'), ({}, {}))
            self.assertEqual(log_events(None), ({}, {}))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClassMapRunTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        out = Path(cls.directory.name) / 'out'
        events = write(Path(cls.directory.name), 'events.csv', f'SPELL_CAST_SUCCESS,{ABSOLUTION},4\n')
        arguments = ['class_map.py', '--worktree', str(ROOT), '--out', str(out), '--log-events', str(events)]
        with mock.patch.object(sys, 'argv', arguments), mock.patch.object(class_map, 'named_auras',
                                                                           return_value={}), \
                mock.patch('builtins.print'):
            class_map.main()
        cls.payload = json.loads((out / 'class-map.json').read_text(encoding='utf-8'))
        cls.table = (out / 'class-map-table.md').read_text(encoding='utf-8')

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def test_every_class_is_mapped(self):
        self.assertEqual(self.payload['errors'], {})
        self.assertEqual(sorted(int(key) for key in self.payload['classes']), list(range(12, 33)))
        self.assertEqual(self.table.count('\n'), 2 + 21)

    def test_the_templar_entry(self):
        templar = self.payload['classes'][str(TEMPLAR_CLASS_ID)]
        self.assertEqual(templar['title'], 'Templar')
        self.assertIn('src/server/coa/AscensionTemplar.cpp', templar['own_files'])
        spells = {spell['spell']: spell for spell in templar['spells']}
        self.assertEqual(spells[ABSOLUTION]['risk'], 'scripted')
        self.assertEqual(spells[ABSOLUTION]['source'], 'advancement')
        self.assertEqual(spells[ABSOLUTION]['log_casts'], 4)
        self.assertEqual(spells[SHOOT]['source'], 'base_candidate')

    def test_the_payload_records_its_inputs(self):
        self.assertEqual(len(self.payload['spell_dbc_sha256']), 64)
        self.assertTrue(self.payload['server_commit'])


if __name__ == '__main__':
    unittest.main()
