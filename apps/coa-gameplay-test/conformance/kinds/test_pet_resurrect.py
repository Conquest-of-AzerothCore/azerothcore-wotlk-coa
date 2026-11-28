from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_scenario
from compare import judge_behaviour
from kinds.pet_resurrect import KIND, label, pet_resurrect_spec, pet_resurrect_verdict
from profile import load_class_file
import run
from test_behaviours import FakeRun, base_verdict

DBC_DIR = Path('/srv/coa/server-data/dbc')
WITCH_HUNTER_CLASS_ID = 15
CALL_FROM_THE_SHADOWS = 578118
WHISTLE = 801343
SHADOWHOUND = 50124


def resurrect_entry(**overrides) -> dict:
    return {
        'spell': CALL_FROM_THE_SHADOWS,
        'name': 'Call From The Shadows',
        'kind': KIND,
        'quote': 'Coalesces the shadows, bringing back your Shadow Hound from the dead.',
        'summon_spell': WHISTLE,
        'pet_entry': SHADOWHOUND,
        **overrides,
    }


class PetResurrectTests(unittest.TestCase):
    def test_spec_validates_fields_and_label(self):
        spec = pet_resurrect_spec(resurrect_entry())
        self.assertEqual(spec.spell, CALL_FROM_THE_SHADOWS)
        self.assertEqual(spec.summon_spell, WHISTLE)
        self.assertEqual(spec.pet_entry, SHADOWHOUND)
        self.assertEqual(label(resurrect_entry()), [f'{CALL_FROM_THE_SHADOWS} {BEHAVIOUR_METRIC_DELTA} {KIND}'])
        for bad in (
            {'summon_spell': 0},
            {'pet_entry': 0},
            {'kill_spell': -5},
            {'wait_ms': 10},
            {'extra': True},
        ):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                pet_resurrect_spec(resurrect_entry(**bad))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_scenario_and_verdicts_judge_clean_resurrect_and_mutants(self):
        class_file = load_class_file(WITCH_HUNTER_CLASS_ID)
        scenario, expectations = behaviour_scenario(class_file, resurrect_entry())
        run.validate(scenario)
        self.assertEqual(len(expectations), 1)
        exp = expectations[0]
        reads = exp.model['reads']
        self.assertTrue(any(step.get('action') == 'set_health' and step.get('pet') is True
                            for step in scenario['steps']))

        base = base_verdict(exp)
        good = {
            reads['entry_summoned']: SHADOWHOUND, reads['health_summoned']: 3000,
            reads['entry_dead']: SHADOWHOUND, reads['health_dead']: 0, reads['health_control']: 0,
            reads['cast_failure']: 0, reads['entry_after']: SHADOWHOUND, reads['health_after']: 1500,
        }
        self.assertEqual(pet_resurrect_verdict(base, FakeRun(good), exp.model).status, 'ok')
        dispatched = judge_behaviour(base, FakeRun(good), exp)
        self.assertEqual(dispatched.status, 'ok')
        from dataclasses import replace
        from behaviours import OWN_CAST_CONTRAST
        from coverage import clause_coverage
        self.assertEqual(dispatched.detail['contrast'], OWN_CAST_CONTRAST)
        build = 'a' * 64
        cov = clause_coverage([{'spell': CALL_FROM_THE_SHADOWS,
                                'clause': 'Coalesces the shadows, bringing back your Shadow Hound from the dead.',
                                'labels': [exp.label], 'kind': 'claim'}],
                              [replace(dispatched, build=build)], build=build)
        self.assertEqual((cov.proven, cov.behaviour), (1, 1))

        still_dead = {**good, reads['health_after']: 0}
        self.assertEqual(pet_resurrect_verdict(base, FakeRun(still_dead), exp.model).status, 'alert')

        cast_failed = {**good, reads['cast_failure']: 27, reads['health_after']: 0}
        self.assertEqual(pet_resurrect_verdict(base, FakeRun(cast_failed), exp.model).status, 'alert')

        never_died = {**good, reads['health_dead']: 1}
        self.assertEqual(pet_resurrect_verdict(base, FakeRun(never_died), exp.model).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
