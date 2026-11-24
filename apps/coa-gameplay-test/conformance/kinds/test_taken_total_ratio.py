import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

ENTRY = {'spell': 707527, 'name': 'Hateforged Barrier (Physical damage taken while it holds)',
         'kind': 'taken_total_ratio', 'label_suffix': 'physical_taken',
         'quote': 'While the barrier holds, you take $s2% reduced Physical Damage.', 'strike_spell': 92559,
         'magic_spell': 41394, 'reduction_effect': 1, 'absorb_effect': 0, 'stamina_coefficient': 1,
         'trials': 4, 'caster_max_health': 100000}
CONTROL = 954
MAGIC = 1100
STAMINA = 79


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TakenTotalRatioTests(unittest.TestCase):
    def generated(self):
        class_file = {**load_fixture_class_file(23), 'level': 60}
        return behaviour_scenario(class_file, ENTRY)

    def values(self, treatment=859, magic=MAGIC, broken=CONTROL, absorbed=831, held=1, gone=0, crit=False):
        _, expectations = self.generated()
        values = {}
        arms = {'control': (CONTROL, 0), 'treatment': (treatment, absorbed), 'magic_control': (MAGIC, 0),
                'magic': (magic, absorbed), 'broken': (broken, 0)}
        for expectation in expectations:
            model = expectation.model
            values[model['stamina']] = STAMINA
            for name in model['arms']:
                strike, absorb = arms[name]
                for index, (mark, reads) in enumerate(model['reads'][name].items()):
                    values[reads['total']] = index * (strike - absorb)
                    values[reads['absorb']] = index * absorb
                    values[reads['logs']] = index
                    values[reads['crits']] = index if crit else 0
                    if 'held' in reads:
                        values[reads['held']] = held
                    if 'broken' in reads:
                        values[reads['broken']] = gone
        return expectations, values

    def statuses(self, **changes):
        expectations, values = self.values(**changes)
        return {expectation.label.rsplit(' ', 1)[1]: judge_behaviour(base_verdict(expectation), FakeRun(values),
                                                                      expectation).status
                for expectation in expectations}

    def test_the_scenario_validates_and_states_the_dbc_reduction(self):
        scenario, expectations = self.generated()
        run.validate(scenario)
        self.assertEqual([expectation.label for expectation in expectations],
                         ['707527 behaviour_hit_ratio physical_taken', '707527 behaviour_hit_ratio magic_taken',
                          '707527 behaviour_hit_ratio physical_after_break'])
        self.assertEqual(expectations[0].model['factor'], [90, 100])
        self.assertEqual((expectations[1].model['absorb_low'], expectations[1].model['absorb_high']), (752, 783))
        self.assertEqual(expectations[0].model['metric'], 'spell_damage_with_resist_total')

    def test_the_stated_totals_are_ok(self):
        self.assertEqual(self.statuses(), {'physical_taken': 'ok', 'magic_taken': 'ok', 'physical_after_break': 'ok'})
        self.assertEqual(self.statuses(treatment=858)['physical_taken'], 'ok')

    def test_mutant_without_the_physical_reduction_alerts(self):
        self.assertEqual(self.statuses(treatment=CONTROL)['physical_taken'], 'alert')

    def test_a_reduced_magic_hit_or_a_reduction_after_the_break_alerts(self):
        self.assertEqual(self.statuses(magic=990)['magic_taken'], 'alert')
        self.assertEqual(self.statuses(broken=859)['physical_after_break'], 'alert')
        self.assertEqual(self.statuses(gone=1)['physical_after_break'], 'alert')

    def test_an_absorb_outside_the_tooltip_formula_alerts(self):
        self.assertEqual(self.statuses(absorbed=STAMINA + 752 - 1)['magic_taken'], 'alert')
        self.assertEqual(self.statuses(absorbed=STAMINA + 783)['magic_taken'], 'ok')

    def test_a_strike_without_the_barrier_alerts_and_critical_strikes_are_unmeasured(self):
        self.assertEqual(self.statuses(held=0)['physical_taken'], 'alert')
        self.assertEqual(set(self.statuses(crit=True).values()), {'unmeasured'})

    def test_a_missing_read_is_unmeasured(self):
        _, expectations = self.generated()
        self.assertEqual(judge_behaviour(base_verdict(expectations[0]), FakeRun({}), expectations[0]).status,
                         'unmeasured')


if __name__ == '__main__':
    unittest.main()
