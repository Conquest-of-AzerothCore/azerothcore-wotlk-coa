import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 804822, 'kind': 'avoided_proc_instances', 'name': 'Vengeance Is Mine (Twin Slice instances)',
         'variant': 'twin_slice_instances', 'label_suffix': 'twin_slice_instances',
         'quote': 'next 10 instances of damage with Twin Slice', 'gain_quote': 'and generate 1 Felfury.',
         'proc_aura': 807163, 'cast_spell': 801901, 'hit_spells': [808303, 808304], 'stack_aura': 800058,
         'instances': 10, 'power': 3, 'power_value': 45, 'striker_entry': 36, 'strikers': 10,
         'striker_auras': [42716, 62531, 2116852], 'swing_ms': 500, 'proc_windows': 30, 'casts': 8,
         'cast_gap_ms': 1100}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class AvoidedProcInstancesTests(unittest.TestCase):
    def generated(self, entry=ENTRY):
        scenario, expectations = behaviour_scenario(load_fixture_class_file(23), entry)
        return scenario, {expectation.label.rsplit(' ', 1)[-1]: expectation for expectation in expectations}

    def values(self, expectation, instances=10, gain=1, own=1, control_aura=False, start_aura=True, reproc=False,
               remaining=9800.0):
        model = expectation.model
        values = {model['start']['aura']: float(start_aura), model['start']['applies']: 7.0,
                  model['start']['remaining']: remaining, model['start']['time']: 1000.0,
                  model['start']['value']: float(instances), model['end_applies']: 8.0 if reproc else 7.0}
        left, hits_so_far = instances, {spell: 0.0 for spell in model['hit_spells']}
        for arm in ('control', 'treatment'):
            for cast, labels in enumerate(model['reads'][arm], start=1):
                hits = 2
                consumed = min(hits, left) if arm == 'treatment' else 0
                left -= consumed
                values[labels['stacks']] = own + gain * consumed
                values[labels['aura']] = float(arm == 'treatment' and left > 0 or (arm == 'control' and control_aura))
                values[labels['time']] = 1000.0 + 1100 * cast
                values[labels['value']] = float(left if arm == 'treatment' and left > 0 else 0)
                for spell in model['hit_spells']:
                    hits_so_far[spell] += 1.0
                    values[labels[f'hits {spell}']] = hits_so_far[spell]
        return values

    def judge(self, expectation, values):
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_the_scenario_learns_after_the_control_casts_and_procs_by_dodges(self):
        scenario, expectations = self.generated()
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        model = expectations['instances'].model
        learn = next(index for index, step in enumerate(steps)
                     if step['action'] == 'learn' and step['spell'] == 804822)
        self.assertLess(labels.index(model['reads']['control'][-1]['stacks']), learn)
        self.assertLess(learn, labels.index(model['start']['aura']))
        self.assertFalse([step for step in steps if step['action'] == 'set_aura' and step['spell'] == 807163])
        self.assertEqual(set(expectations), {'instances', 'gain_per_instance'})

    def test_ten_instances_at_one_felfury_each_are_ok(self):
        _, expectations = self.generated()
        for name, expectation in expectations.items():
            with self.subTest(name=name):
                verdict = self.judge(expectation, self.values(expectation))
                self.assertEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_mutant_nine_instances_alerts_on_the_count_only(self):
        _, expectations = self.generated()
        self.assertEqual(self.judge(expectations['instances'],
                                    self.values(expectations['instances'], instances=9)).status, 'alert')
        self.assertEqual(self.judge(expectations['gain_per_instance'],
                                    self.values(expectations['gain_per_instance'], instances=9)).status, 'ok')

    def test_a_mutant_eleven_instances_alerts(self):
        _, expectations = self.generated()
        self.assertEqual(self.judge(expectations['instances'],
                                    self.values(expectations['instances'], instances=11)).status, 'alert')

    def test_a_mutant_two_felfury_per_instance_alerts_on_the_gain_only(self):
        _, expectations = self.generated()
        self.assertEqual(self.judge(expectations['gain_per_instance'],
                                    self.values(expectations['gain_per_instance'], gain=2)).status, 'alert')
        self.assertEqual(self.judge(expectations['instances'],
                                    self.values(expectations['instances'], gain=2)).status, 'ok')

    def test_a_mutant_without_felfury_alerts_on_the_gain_and_voids_the_count(self):
        _, expectations = self.generated()
        self.assertEqual(self.judge(expectations['gain_per_instance'],
                                    self.values(expectations['gain_per_instance'], gain=0)).status, 'alert')
        self.assertEqual(self.judge(expectations['instances'],
                                    self.values(expectations['instances'], gain=0)).status, 'unmeasured')

    def test_a_proc_aura_before_the_learn_alerts(self):
        _, expectations = self.generated()
        verdict = self.judge(expectations['instances'], self.values(expectations['instances'], control_aura=True))
        self.assertEqual(verdict.status, 'alert')

    def test_no_proc_a_reproc_or_an_expiry_by_duration_is_void(self):
        _, expectations = self.generated()
        expectation = expectations['instances']
        for change in ({'start_aura': False}, {'reproc': True}):
            with self.subTest(change=change):
                self.assertEqual(self.judge(expectation, self.values(expectation, **change)).status, 'unmeasured')
        expired = self.values(expectation, remaining=2000.0)
        for cast, labels in enumerate(expectation.model['reads']['treatment'], start=1):
            if cast >= 3:
                expired[labels['aura']] = 0.0
            if cast >= 4:
                expired[labels['stacks']] = 1.0
        self.assertEqual(self.judge(expectation, expired).status, 'unmeasured')

    def test_entries_that_cannot_pass_the_count_are_refused(self):
        for entry in ({**ENTRY, 'casts': 5}, {**ENTRY, 'instances': 9}, {**ENTRY, 'hit_spells': []}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                self.generated(entry)


if __name__ == '__main__':
    unittest.main()
