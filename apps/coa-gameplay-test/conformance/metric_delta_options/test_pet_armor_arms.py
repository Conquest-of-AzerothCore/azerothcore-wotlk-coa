import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import metric_evidence
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

PROBE = 340.0


def armor_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry.get('spell') == 804194 and entry.get('variant') == 'hound_ignore_armor')
    return {**entry, **changes}


def readings(model: dict, with_ratio: float = 1.0, without_ratio: float = PROBE / 1000, pet: int = 50124,
             bare_armor: int = 0, aura: int = 1, lapsed: bool = False) -> dict:
    arms = model['pet_armor_arms']
    values = {arms['pet_entry']: pet, arms['armor']['dummy']: 10528, arms['armor']['bare_dummy']: bare_armor,
              **{label: aura for label in arms['auras'].values()},
              arms['probes']['without']['dummy']: PROBE, arms['probes']['without']['bare_dummy']: 1000,
              arms['probes']['with']['dummy']: 1000, arms['probes']['with']['bare_dummy']: 1000}
    armor = {'dummy': 10528, 'bare_dummy': bare_armor}
    for index, read in enumerate(arms['window_armor']):
        unit = read.rsplit(' ', 1)[1]
        values[read] = 528 if lapsed and unit == 'dummy' and index % 7 == 3 else armor[unit]
    for phase, ratio in (('with', with_ratio), ('without', without_ratio)):
        for dummy, scale in (('dummy', ratio), ('bare_dummy', 1.0)):
            total = count = 0.0
            for mark, (total_label, count_label) in enumerate(arms['reads'][phase][dummy]):
                if mark:
                    total += 2 * 100 * scale * (1 + (0.02 if mark % 2 else -0.02))
                    count += 2
                values[total_label], values[count_label] = total, count
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PetArmorArmsTests(unittest.TestCase):
    def judged(self, **reads):
        _, [expectation] = behaviour_scenario(load_class_file(15), armor_entry())
        return judge_behaviour(base_verdict(expectation), FakeRun(readings(expectation.model, **reads)), expectation)

    def test_the_pet_swings_at_one_dummy_at_a_time_and_the_trigger_precedes_every_treatment_window(self):
        scenario, _ = behaviour_scenario(load_class_file(15), armor_entry())
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        attacks = [step['target'] for step in steps if step['action'] == 'attack']
        self.assertEqual(attacks, ['dummy', 'bare_dummy', 'dummy', 'bare_dummy'])
        self.assertTrue(all(step['pet'] for step in steps if step['action'] == 'attack'))
        casts = [step for step in steps if step['action'] == 'cast' and step['spell'] == 804194]
        self.assertEqual(len(casts), 1 + 2 * armor_entry()['pet_armor_arms']['trials'])
        reads = [step for step in steps if step.get('metric') in ('pet_melee_plain_damage', 'pet_melee_plain_count')]
        self.assertFalse([step for step in reads if 'entry' in step])
        self.assertEqual([creature['id'] for creature in scenario['creatures']], ['dummy', 'bare_dummy'])
        self.assertEqual(metric_evidence()['pet_melee_plain_damage'], 'event')

    def test_armor_ignored_with_the_trigger_and_the_read_factor_without_it_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_pet_that_still_meets_the_armor_with_the_trigger_alerts(self):
        self.assertEqual(self.judged(with_ratio=PROBE / 1000).status, 'alert')
        self.assertEqual(self.judged(with_ratio=0.5).status, 'alert')

    def test_a_contrast_that_misses_the_read_armor_factor_alerts(self):
        self.assertEqual(self.judged(without_ratio=1.0).status, 'alert')

    def test_a_failed_precondition_leaves_the_entry_unmeasured(self):
        for reads in ({'pet': 50224}, {'bare_armor': 12}, {'aura': 0}, {'lapsed': True}):
            with self.subTest(reads=reads):
                self.assertEqual(self.judged(**reads).status, 'unmeasured')

    def test_the_option_refuses_fields_or_a_strike(self):
        entry = armor_entry()
        for changes in ({'fields': {'entry': 50124}}, {'pet_armor_arms': {**entry['pet_armor_arms'], 'trials': 0}},
                        {'metric': 'pet_melee_plain_count'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), {**entry, **changes})


if __name__ == '__main__':
    unittest.main()
