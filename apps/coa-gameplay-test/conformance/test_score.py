import unittest

from score import entries_match, score, score_kind, values_equal

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
        self.assertFalse(values_equal(100, 101))

    def test_nested_dicts_compare_field_by_field(self):
        self.assertTrue(values_equal({'a': 1, 'b': [1, 2]}, {'a': 1, 'b': [1, 2]}))
        self.assertFalse(values_equal({'a': 1}, {'a': 2}))

    def test_entries_match_ignores_field_order(self):
        self.assertTrue(entries_match('literal_tokens', {'spell': 1, 'value': 100}, {'value': 100, 'spell': 1}))


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


class ScoreTests(unittest.TestCase):
    def test_overall_sums_every_kind(self):
        records = [record('literal_tokens', {'spell': 1, 'effect': 0, 'quote': 'a', 'value': 100}),
                  record('procs', {'aura': 10, 'chance_token': '$s1', 'name': 'p'})]
        result = score(CLASS_FILE, records)
        self.assertEqual(result['overall']['match'], 2)
        self.assertIn('literal_tokens', result['per_kind'])
        self.assertIn('procs', result['per_kind'])


if __name__ == '__main__':
    unittest.main()
