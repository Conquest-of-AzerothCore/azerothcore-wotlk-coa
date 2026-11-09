import unittest

from score import entries_match, merge_sides, score, score_kind, values_equal

CLASS_FILE = {
    'literal_tokens': [
        {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100},
        {'spell': 2, 'effect': 0, 'quote': 'b', 'value': 50},
    ],
    'procs': [{'aura': 10, 'chance_token': '$s1', 'name': 'p'}],
}


def record(kind, entry):
    return {'entry_kind': kind, 'entry': entry}


class ValueComparisonTests(unittest.TestCase):
    def test_numbers_within_tolerance_are_equal(self):
        self.assertTrue(values_equal(100, 100.0000001))

    def test_numbers_outside_tolerance_differ(self):
        self.assertFalse(values_equal(100, 103))

    def test_tolerance_matches_compare_pys_absolute_floor(self):
        self.assertTrue(values_equal(100, 101))
        self.assertFalse(values_equal(100, 102))

    def test_tolerance_matches_compare_pys_relative_floor(self):
        self.assertTrue(values_equal(1000, 1005))
        self.assertFalse(values_equal(1000, 1006))

    def test_nested_dicts_compare_field_by_field(self):
        self.assertTrue(values_equal({'a': 1, 'b': [1, 2]}, {'a': 1, 'b': [1, 2]}))
        self.assertFalse(values_equal({'a': 1}, {'a': 5}))

    def test_entries_match_ignores_field_order(self):
        self.assertTrue(entries_match('literal_tokens', {'spell': 1, 'value': 100}, {'value': 100, 'spell': 1}))

    def test_operational_mode_ignores_free_text_wording(self):
        expected = {'spell': 1, 'effect': 0, 'quote': 'Doubles the healing done to you', 'value': 100}
        actual = {'spell': 1, 'effect': 0, 'quote': 'twice the healing you take', 'value': 100}
        self.assertTrue(entries_match('literal_tokens', expected, actual))
        self.assertFalse(entries_match('literal_tokens', expected, actual, strict=True))

    def test_operational_mode_still_catches_a_numeric_disagreement(self):
        expected = {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100}
        actual = {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 999}
        self.assertFalse(entries_match('literal_tokens', expected, actual))

    def test_operational_mode_catches_a_wrong_proc_chance(self):
        expected = {'aura': 1, 'proc_spell': 2, 'chance_token': '$s1'}
        actual = {'aura': 1, 'proc_spell': 2, 'chance_token': '$s2'}
        self.assertFalse(entries_match('procs', expected, actual))

    def test_operational_mode_catches_a_wrong_behaviour_expected_value(self):
        expected = {'spell': 1, 'kind': 'count', 'expected': 2}
        actual = {'spell': 1, 'kind': 'count', 'expected': 5}
        self.assertFalse(entries_match('behaviours', expected, actual))


class ScoreKindTests(unittest.TestCase):
    def test_exact_match_counts_as_match(self):
        records = [record('literal_tokens', {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100})]
        result = score_kind(CLASS_FILE, records, 'literal_tokens')
        self.assertEqual(result['match'], 1)
        self.assertEqual(result['miss'], 1)
        self.assertEqual(result['false_claim'], 0)
        self.assertEqual(result['wrong_value'], 0)

    def test_wrong_value_counts_separately_from_miss(self):
        records = [record('literal_tokens', {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 999})]
        result = score_kind(CLASS_FILE, records, 'literal_tokens')
        self.assertEqual(result['wrong_value'], 1)
        self.assertEqual(result['match'], 0)

    def test_false_claim_counts_an_entry_with_no_ground_truth(self):
        records = [record('literal_tokens', {'spell': 99, 'effect': 0, 'quote': 'x', 'value': 1})]
        result = score_kind(CLASS_FILE, records, 'literal_tokens')
        self.assertEqual(result['false_claim'], 1)
        self.assertEqual(result['miss'], 2)

    def test_precision_and_recall_are_computed(self):
        records = [record('literal_tokens', {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100})]
        result = score_kind(CLASS_FILE, records, 'literal_tokens')
        self.assertAlmostEqual(result['precision'], 1.0)
        self.assertAlmostEqual(result['recall'], 0.5)

    def test_empty_records_yields_none_precision(self):
        result = score_kind(CLASS_FILE, [], 'literal_tokens')
        self.assertIsNone(result['precision'])
        self.assertEqual(result['recall'], 0.0)

    def test_duplicate_key_ground_truth_entries_are_not_dropped(self):
        class_file = {
            'procs': [
                {'aura': 10, 'chance_token': '$s1', 'name': 'first', 'proc_spell': 11},
                {'aura': 10, 'chance_token': '$s1', 'name': 'second', 'proc_spell': 22},
            ],
        }
        records = [record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'first', 'proc_spell': 11})]
        result = score_kind(class_file, records, 'procs')
        self.assertEqual(result['match'], 1)
        self.assertEqual(result['miss'], 1)
        self.assertEqual(result['false_claim'], 0)
        self.assertEqual(result['wrong_value'], 0)

    def test_duplicate_key_generated_entries_are_not_dropped(self):
        class_file = {
            'procs': [{'aura': 10, 'chance_token': '$s1', 'name': 'first', 'proc_spell': 11}],
        }
        records = [record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'first', 'proc_spell': 11}),
                  record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'other', 'proc_spell': 99})]
        result = score_kind(class_file, records, 'procs')
        self.assertEqual(result['match'], 1)
        self.assertEqual(result['miss'], 0)
        self.assertEqual(result['false_claim'], 1)
        self.assertEqual(result['wrong_value'], 0)

    def test_duplicate_key_with_both_sides_unmatched_counts_wrong_value(self):
        class_file = {
            'procs': [{'aura': 10, 'chance_token': '$s1', 'name': 'first', 'proc_spell': 11}],
        }
        records = [record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'other', 'proc_spell': 99})]
        result = score_kind(class_file, records, 'procs')
        self.assertEqual(result['match'], 0)
        self.assertEqual(result['miss'], 0)
        self.assertEqual(result['false_claim'], 0)
        self.assertEqual(result['wrong_value'], 1)


class ScoreTests(unittest.TestCase):
    def test_overall_sums_every_kind(self):
        records = [record('literal_tokens', {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100}),
                  record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'p'})]
        result = score(CLASS_FILE, records)
        self.assertEqual(result['overall']['match'], 2)
        self.assertIn('literal_tokens', result['per_kind'])
        self.assertIn('procs', result['per_kind'])

    def test_unmodelled_effects_is_not_a_separate_scored_kind(self):
        result = score(CLASS_FILE, [])
        self.assertNotIn('unmodelled_effects', result['per_kind'])
        self.assertIn('effect_notes', result['per_kind'])


class KindMergeTests(unittest.TestCase):
    CLASS_FILE = {'effect_notes': [{'spell': 1, 'effect': 0, 'reason': 'hand reason'}]}

    def test_a_reader_filed_under_the_other_merged_kind_still_matches(self):
        records = [record('unmodelled_effects', {'spell': 1, 'effect': 0, 'reason': 'reader reason'})]
        result = score_kind(self.CLASS_FILE, records, 'effect_notes')
        self.assertEqual(result['match'], 1)
        self.assertEqual(result['false_claim'], 0)

    def test_the_merged_kind_is_not_also_scored_as_unmodelled_effects(self):
        records = [record('unmodelled_effects', {'spell': 1, 'effect': 0, 'reason': 'reader reason'})]
        result = score(self.CLASS_FILE, records)
        self.assertEqual(result['overall']['match'], 1)
        self.assertEqual(result['overall']['false_claim'], 0)


class MergeSidesTests(unittest.TestCase):
    def test_agreeing_sides_promote_to_one_merged_record(self):
        side_a = [record('triggers', {'aura': 1, 'observe_spell': 2, 'name': 'a wording'})]
        side_b = [record('triggers', {'aura': 1, 'observe_spell': 2, 'name': 'b wording'})]
        result = merge_sides(side_a, side_b)
        self.assertEqual(len(result['merged']), 1)
        self.assertEqual(result['only_a'], [])
        self.assertEqual(result['only_b'], [])
        self.assertEqual(result['conflicts'], [])

    def test_disagreeing_sides_are_a_conflict_not_a_merge(self):
        side_a = [record('triggers', {'aura': 1, 'observe_spell': 2, 'name': 'a'})]
        side_b = [record('triggers', {'aura': 1, 'observe_spell': 705268, 'name': 'b'})]
        result = merge_sides(side_a, side_b)
        self.assertEqual(result['merged'], [])
        self.assertEqual(len(result['conflicts']), 1)

    def test_one_sided_key_is_not_promoted(self):
        side_a = [record('triggers', {'aura': 1, 'observe_spell': 2, 'name': 'a'})]
        result = merge_sides(side_a, [])
        self.assertEqual(result['merged'], [])
        self.assertEqual(len(result['only_a']), 1)


if __name__ == '__main__':
    unittest.main()
