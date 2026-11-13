from pathlib import Path
import tempfile
import unittest

from profile import DBC_DIR, load_class_file
from sheets import render_text, scripted_hooks, sheet, talent_catalog_entry, talent_catalog_ranks, write_sheets
from values import dataset

TEMPLAR_CLASS_ID = 19
SCOURGEBANE = 92111
LIBERTY = 705266
MISSING_SPELL = 99999999


class SheetTests(unittest.TestCase):
    def setUp(self):
        self.class_file = load_class_file(TEMPLAR_CLASS_ID)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_rejects_unknown_spell(self):
        with self.assertRaises(ValueError):
            sheet(DBC_DIR, self.class_file, MISSING_SPELL)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_tooltip_resolves_tokens_at_two_stat_bounds(self):
        data = sheet(DBC_DIR, self.class_file, SCOURGEBANE)
        self.assertEqual(data['spell_id'], SCOURGEBANE)
        self.assertEqual(data['name'], 'Scourgebane')
        low_values = data['tooltip']['low']['values']
        high_values = data['tooltip']['high']['values']
        self.assertTrue(low_values)
        self.assertEqual(len(low_values), len(high_values))
        stat_dependent = [value for value in high_values if value['kind'] == 'flat']
        self.assertTrue(stat_dependent)
        low_by_text = {value['text']: value['value'] for value in low_values}
        high_by_text = {value['text']: value['value'] for value in high_values}
        self.assertNotEqual(low_by_text[stat_dependent[0]['text']], high_by_text[stat_dependent[0]['text']])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_decodes_effects_in_plain_words(self):
        data = sheet(DBC_DIR, self.class_file, SCOURGEBANE)
        self.assertTrue(data['effects'])
        first = data['effects'][0]
        self.assertEqual(first['spell_id'], SCOURGEBANE)
        self.assertIn('family', first)
        self.assertIn('reason', first)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_proc_trigger_fields_are_raw_dbc_values(self):
        data = sheet(DBC_DIR, self.class_file, SCOURGEBANE)
        fields = data['proc_trigger_fields']
        self.assertEqual(fields['ProcChance'], 100)
        self.assertEqual(fields['EffectTriggerSpell[0]'], 807414)

    def test_scripted_hooks_cite_file_and_line(self):
        hooks = scripted_hooks(SCOURGEBANE)
        self.assertTrue(hooks)
        for hook in hooks:
            path, _, _ = hook.partition(':')
            self.assertTrue(path.startswith('src/server/coa/'))

    def test_scripted_hooks_empty_for_unscripted_src_dir(self):
        with tempfile.TemporaryDirectory() as empty_dir:
            self.assertEqual(scripted_hooks(SCOURGEBANE, Path(empty_dir)), [])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_render_text_includes_name_and_tooltip(self):
        data = sheet(DBC_DIR, self.class_file, SCOURGEBANE)
        text = render_text(data)
        self.assertIn('Scourgebane', text)
        self.assertIn('Decoded effects:', text)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sheet_is_deterministic(self):
        first = sheet(DBC_DIR, self.class_file, LIBERTY)
        second = sheet(DBC_DIR, self.class_file, LIBERTY)
        self.assertEqual(first, second)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_write_sheets_writes_json_and_text_per_spell(self):
        with tempfile.TemporaryDirectory() as out_dir:
            written = write_sheets(DBC_DIR, self.class_file, out_dir, [SCOURGEBANE, LIBERTY])
            self.assertEqual(len(written), 2)
            for spell_id in (SCOURGEBANE, LIBERTY):
                self.assertTrue((Path(out_dir) / f'{spell_id}.json').is_file())
                self.assertTrue((Path(out_dir) / f'{spell_id}.txt').is_file())

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_write_sheets_omits_class_file_entries_and_verdicts_by_default(self):
        with tempfile.TemporaryDirectory() as out_dir:
            write_sheets(DBC_DIR, self.class_file, out_dir, [SCOURGEBANE])
            text = (Path(out_dir) / f'{SCOURGEBANE}.json').read_text(encoding='utf-8')
            self.assertNotIn('"procs"', text)
            self.assertNotIn('"verdict"', text)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_talent_catalog_entry_resolves_the_rank_key_space(self):
        dbc = dataset(DBC_DIR)
        entry = talent_catalog_entry(dbc, SCOURGEBANE)
        self.assertIsNotNone(entry)
        self.assertIn(SCOURGEBANE, entry['ranks'])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_talent_catalog_entry_is_none_for_a_spell_outside_the_catalog(self):
        dbc = dataset(DBC_DIR)
        self.assertIsNone(talent_catalog_entry(dbc, MISSING_SPELL))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_sheet_carries_the_talent_catalog_entry(self):
        data = sheet(DBC_DIR, self.class_file, SCOURGEBANE)
        self.assertIn(SCOURGEBANE, data['talent_catalog_entry']['ranks'])

    def test_talent_catalog_ranks_falls_back_on_a_missing_table(self):
        class MissingTableDataset:
            def load(self, name):
                raise ValueError(f'Table not found: {name}')

        self.assertEqual(talent_catalog_ranks(MissingTableDataset()), {})


if __name__ == '__main__':
    unittest.main()
