from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_scenario
from compare import judge_behaviour
from kinds.pet_dismiss import KIND, label, pet_dismiss_spec, pet_dismiss_verdict
from profile import load_class_file
import run
from test_behaviours import FakeRun, base_verdict

DBC_DIR = Path('/srv/coa/server-data/dbc')
WITCH_HUNTER_CLASS_ID = 15
DISMISS_HOUND = 680263
WHISTLE = 801343
SHADOWHOUND = 50124


def dismiss_entry(**overrides) -> dict:
    return {
        'spell': DISMISS_HOUND,
        'name': 'Dismiss Hound',
        'kind': KIND,
        'quote': 'Dismiss your Shadow Hound.',
        'summon_spell': WHISTLE,
        'pet_entry': SHADOWHOUND,
        **overrides,
    }


class PetDismissTests(unittest.TestCase):
    def test_spec_validates_fields_and_label(self):
        spec = pet_dismiss_spec(dismiss_entry())
        self.assertEqual(spec.spell, DISMISS_HOUND)
        self.assertEqual(spec.summon_spell, WHISTLE)
        self.assertEqual(spec.pet_entry, SHADOWHOUND)
        self.assertEqual(label(dismiss_entry()), [f'{DISMISS_HOUND} {BEHAVIOUR_METRIC_DELTA} {KIND}'])
        for bad in (
            {'summon_spell': 0},
            {'pet_entry': -1},
            {'wait_ms': 10},
            {'unknown_key': 1},
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                pet_dismiss_spec(dismiss_entry(**bad))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_and_verdicts_judge_clean_dismiss_and_mutants(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        scenario, expectations = behaviour_scenario(class_file, dismiss_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        exp = expectations[0]
        reads = exp.model['reads']
        metrics = [step.get('metric') for step in scenario['steps'] if step.get('action') == 'assert']
        self.assertIn('pet_entry', metrics)
        self.assertIn('cast_failure', metrics)

        base = base_verdict(exp)
        ok_run = FakeRun({reads['before']: SHADOWHOUND, reads['control']: SHADOWHOUND,
                          reads['cast_failure']: 0, reads['after']: 0})
        self.assertEqual(pet_dismiss_verdict(base, ok_run, exp.model).status, 'ok')

        stuck_run = FakeRun({reads['before']: SHADOWHOUND, reads['control']: SHADOWHOUND,
                             reads['cast_failure']: 0, reads['after']: SHADOWHOUND})
        self.assertEqual(pet_dismiss_verdict(base, stuck_run, exp.model).status, 'alert')

        failed_cast = FakeRun({reads['before']: SHADOWHOUND, reads['control']: SHADOWHOUND,
                               reads['cast_failure']: 27, reads['after']: SHADOWHOUND})
        self.assertEqual(pet_dismiss_verdict(base, failed_cast, exp.model).status, 'alert')

        missing_pet = FakeRun({reads['before']: 0, reads['control']: 0,
                               reads['cast_failure']: 0, reads['after']: 0})
        self.assertEqual(pet_dismiss_verdict(base, missing_pet, exp.model).status, 'unmeasured')

        via_dispatch = judge_behaviour(base, ok_run, exp)
        self.assertEqual(via_dispatch.status, 'ok')
        from dataclasses import replace
        from behaviours import OWN_CAST_CONTRAST
        from coverage import clause_coverage
        self.assertEqual(via_dispatch.detail['contrast'], OWN_CAST_CONTRAST)
        build = 'a' * 64
        cov = clause_coverage([{'spell': DISMISS_HOUND, 'clause': 'Dismiss your Shadow Hound.',
                                'labels': [exp.label], 'kind': 'claim'}],
                              [replace(via_dispatch, build=build)], build=build)
        self.assertEqual((cov.proven, cov.behaviour), (1, 1))


if __name__ == '__main__':
    unittest.main()
