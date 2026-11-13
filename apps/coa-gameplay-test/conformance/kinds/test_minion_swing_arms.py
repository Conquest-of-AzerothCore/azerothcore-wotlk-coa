import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import BEHAVIOUR, verdict_evidence
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 706948, 'name': 'Fetid Mark (Skeletal Warrior swings with and without the mark)',
         'kind': 'minion_swing_arms', 'label_suffix': 'swing_arms',
         'quote': 'increases the damage the target takes from your Skeletal Warriors by $706949s1%',
         'raise_spell': 500970, 'command_spell': 504868, 'minion_entry': 50065, 'aura': 706949, 'stacks': 10,
         'holder': 'dummy', 'expected': 10, 'windows': 6, 'window_ms': 6000, 'player_spell_power': 3000}
OWNER_ENTRY = {**ENTRY, 'spell': 574138, 'name': 'Rotting Flesh (minion swings with and without the stacks)',
               'quote': 'increasing their damage dealt by $573131s1% per stack', 'aura': 573131, 'holder': 'owner',
               'expected': 20}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class MinionSwingArmsTests(unittest.TestCase):
    def built(self, entry=None):
        return behaviour_scenario(load_fixture_class_file(23), entry or ENTRY)

    def values(self, expectation, control_swing: float, treatment_swing: float, swings: int = 3,
               held: float | None = None) -> dict:
        values, total, count = {}, 0.0, 0
        stacks = expectation.model['stacks'] if expectation.model['holder'] == 'dummy' else 1
        for window in range(len(expectation.model['windows']['control'])):
            for arm, swing in (('control', control_swing), ('treatment', treatment_swing)):
                labels = expectation.model['windows'][arm][window]
                values[labels['start total']], values[labels['start count']] = total, count
                total, count = total + swing * swings + (window % 2) * 0.5, count + swings
                values[labels['end total']], values[labels['end count']] = total, count
                values[labels['aura']] = (stacks if held is None else held) if arm == 'treatment' else 0
        return values

    def judged(self, control_swing: float, treatment_swing: float, **options):
        _, [expectation] = self.built(options.pop('entry', None))
        values = self.values(expectation, control_swing, treatment_swing, **options)
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_arms_alternate_and_set_the_aura_only_in_treatment(self):
        scenario, [expectation] = self.built()
        run.validate(scenario)
        auras = [step for step in scenario['steps'] if step['action'] == 'set_aura']
        self.assertEqual([step['stacks'] for step in auras[:4]], [0, 0, 10, 0])
        self.assertTrue(all(step['target'] == 'dummy' and step['caster'] == 'caster' for step in auras))
        self.assertEqual(scenario['players'][0]['spell_power'], 3000)
        self.assertEqual(expectation.model['expected'], 10.0)

    def test_the_owner_holds_a_summon_aura_read_on_the_minion(self):
        scenario, [expectation] = self.built(OWNER_ENTRY)
        run.validate(scenario)
        auras = [step for step in scenario['steps'] if step['action'] == 'set_aura']
        self.assertTrue(all('target' not in step for step in auras))
        reads = [step for step in scenario['steps']
                 if 'swing_arms' in step.get('label', '') and step['label'].endswith(' aura')]
        self.assertEqual(len(reads), 2 * len(expectation.model['windows']['control']))
        self.assertTrue(all(step['metric'] == 'owned_creature_count' and step['spell'] == 573131 for step in reads))
        self.assertEqual(expectation.model['expected'], 20.0)

    def test_the_stated_bonus_passes_and_its_mutants_alert(self):
        self.assertEqual(self.judged(1000.0, 1100.0).status, 'ok')
        self.assertEqual(self.judged(1000.0, 1010.0).status, 'alert')
        self.assertEqual(self.judged(1000.0, 1200.0).status, 'alert')

    def test_an_unheld_aura_or_a_missing_arm_is_not_judged(self):
        self.assertEqual(self.judged(1000.0, 1100.0, held=3).status, 'unmeasured')
        self.assertEqual(self.judged(1000.0, 1100.0, swings=0).status, 'unmeasured')

    def test_an_entry_without_a_treatment_aura_has_no_contrast_and_is_refused(self):
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'stacks': 0})
        with self.assertRaises(ValueError):
            self.built({**ENTRY, 'expected': 1})

    def test_an_ok_verdict_is_behaviour_evidence_through_its_event_metric(self):
        verdict = self.judged(1000.0, 1100.0)
        self.assertEqual(verdict_evidence(verdict, ENTRY['quote'], {}), BEHAVIOUR)
