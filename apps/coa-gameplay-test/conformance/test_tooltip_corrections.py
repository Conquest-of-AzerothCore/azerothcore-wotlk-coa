import copy
import unittest

from profile import DBC_DIR, load_class_file
from tooltip_corrections import TOOLTIP_CORRECTIONS, corrected_description, only_inserted

PROTECTOR = 560492
FINISHED_CLASS_FILES = (15, 19, 23)


class OnlyInsertedTests(unittest.TestCase):
    def test_only_inserted_operators_are_accepted(self):
        self.assertTrue(only_inserted('$a$b*2', '$a+$b*2'))
        self.assertTrue(only_inserted('$a$b$c', '$a+$b+$c'))

    def test_any_other_difference_is_refused(self):
        for corrected in ('$a$b*2', '$a-$b*2', '$a+$b*3', '$a+b*2', '+$a$b*', '$a$b*2 '):
            with self.subTest(corrected=corrected):
                self.assertFalse(only_inserted('$a$b*2', corrected))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TooltipCorrectionTests(unittest.TestCase):
    def setUp(self):
        from hits import records_of
        self.class_file = load_class_file(27)
        self.records = records_of(self.class_file)

    def test_the_d166_correction_reads_the_spell_power_term(self):
        from hits import reference_script_hit_model
        text = corrected_description(self.class_file, self.records, PROTECTOR)
        self.assertIn('$<scalingbp>+$spfi*0.12', text)
        self.assertIn('D-166', self.class_file[TOOLTIP_CORRECTIONS][str(PROTECTOR)]['ruling'])
        self.assertGreater(reference_script_hit_model(self.class_file, PROTECTOR, 560493).mean, 0)

    def test_without_the_correction_the_token_stays_unreadable(self):
        from hits import Unmodelled, reference_script_hit_model
        bare = copy.deepcopy(self.class_file)
        bare.pop(TOOLTIP_CORRECTIONS)
        self.assertIsNone(corrected_description(bare, self.records, PROTECTOR))
        with self.assertRaises(Unmodelled):
            reference_script_hit_model(bare, PROTECTOR, 560493)

    def test_a_correction_beyond_inserted_operators_or_without_a_ruling_is_refused(self):
        entry = self.class_file[TOOLTIP_CORRECTIONS][str(PROTECTOR)]
        for change in ({'text': entry['text'].replace('0.12', '0.15')}, {'ruling': ''}, {'ruling': None},
                       {'text': entry['text'], 'ruling': entry['ruling'], 'source': 'x'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                corrected_description({TOOLTIP_CORRECTIONS: {str(PROTECTOR): {**entry, **change}}}, self.records,
                                      PROTECTOR)

    def test_no_finished_class_file_carries_a_correction(self):
        for class_id in FINISHED_CLASS_FILES:
            with self.subTest(class_id=class_id):
                self.assertNotIn(TOOLTIP_CORRECTIONS, load_class_file(class_id))


if __name__ == '__main__':
    unittest.main()
