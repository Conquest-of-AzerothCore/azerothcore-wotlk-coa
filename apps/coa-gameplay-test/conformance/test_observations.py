import unittest

from observations import PlayerObservation, checked_observation, observations_by_spell, player_observations

WELL_FORMED = {'spell': 706325, 'name': 'Condemnation', 'date': '2026-11-07',
              'citation': 'player report 2026-11-07', 'claim': 'Zealotry procs on each damage tick.',
              'corroborates': '706325 proc_rate'}


class CheckedObservationTest(unittest.TestCase):
    def test_accepts_well_formed_entry(self):
        self.assertEqual(checked_observation(dict(WELL_FORMED)), WELL_FORMED)

    def test_rejects_missing_field(self):
        entry = {key: value for key, value in WELL_FORMED.items() if key != 'claim'}
        with self.assertRaises(ValueError):
            checked_observation(entry)

    def test_rejects_citation_without_the_player_report_prefix(self):
        entry = {**WELL_FORMED, 'citation': '2026-11-07 player report'}
        with self.assertRaises(ValueError):
            checked_observation(entry)

    def test_rejects_citation_naming_a_person(self):
        entry = {**WELL_FORMED, 'citation': 'Someone report 2026-11-07'}
        with self.assertRaises(ValueError):
            checked_observation(entry)

    def test_rejects_date_mismatched_with_the_citation(self):
        entry = {**WELL_FORMED, 'date': '2026-11-06'}
        with self.assertRaises(ValueError):
            checked_observation(entry)


class PlayerObservationsTest(unittest.TestCase):
    def test_reads_well_formed_entries_from_the_class_file(self):
        class_file = {'player_observations': [WELL_FORMED]}
        self.assertEqual(player_observations(class_file), [PlayerObservation(**WELL_FORMED)])

    def test_defaults_to_empty_when_the_class_file_has_no_entries(self):
        self.assertEqual(player_observations({}), [])

    def test_raises_on_a_malformed_entry_instead_of_silently_dropping_it(self):
        class_file = {'player_observations': [{**WELL_FORMED, 'citation': 'not a citation'}]}
        with self.assertRaises(ValueError):
            player_observations(class_file)


class ObservationsBySpellTest(unittest.TestCase):
    def test_groups_by_spell_and_keeps_entry_order(self):
        second = {**WELL_FORMED, 'claim': 'a second, independent claim about the same spell.'}
        observations = [PlayerObservation(**WELL_FORMED), PlayerObservation(**second)]
        grouped = observations_by_spell(observations)
        self.assertEqual(list(grouped), [706325])
        self.assertEqual(grouped[706325], observations)

    def test_a_spell_with_no_observations_is_absent_from_the_mapping(self):
        self.assertEqual(observations_by_spell([]), {})


if __name__ == '__main__':
    unittest.main()
