import unittest

from behaviours import COST_GATE_RESOURCES, NO_CAST_FAILURE, behaviour_scenario
from profile import DBC_DIR, load_class_file

CLASS_FILE = load_class_file(27)


def entry_of(spell: int, variant: str) -> dict:
    return next(entry for entry in CLASS_FILE['behaviours'] if entry['spell'] == spell and entry.get('variant') == variant)


def results(expectations) -> dict:
    return {expectation.label.rsplit(' ', 1)[1]: expectation.displayed for expectation in expectations}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class RefusedWithTests(unittest.TestCase):
    def test_a_reset_expects_the_recast_accepted_by_default(self):
        _, expectations = behaviour_scenario(CLASS_FILE, entry_of(301266, 'reset_horusath'))
        self.assertEqual(results(expectations)['with'], str(NO_CAST_FAILURE))

    def test_refused_with_expects_the_with_arm_refused_and_keeps_the_without_arm(self):
        entry = {**entry_of(301266, 'reset_horusath'), 'refused_with': True}
        _, expectations = behaviour_scenario(CLASS_FILE, entry)
        refused = str(COST_GATE_RESOURCES['cooldown'])
        self.assertEqual(results(expectations), {'without': refused, 'with': refused})

    def test_refused_with_needs_a_reset(self):
        entry = {**entry_of(805581, 'cd_gate'), 'refused_with': True}
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, entry)


if __name__ == '__main__':
    unittest.main()
