import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.extra_strikes import ARMS, READS, STRIKE_METRIC, extra_strikes_verdict, read_label, strike_read
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

BRUSHIN_OFF_THE_DUSK_R2 = 681488
STRIKE_SPELLS = (681392, 681489)
REPLENISHMENT = 1257670


def entry(**changes) -> dict:
    return {'spell': BRUSHIN_OFF_THE_DUSK_R2, 'name': "Brushin' Off The Dusk r2", 'kind': 'extra_strikes',
            'quote': 'to strike 3 additional times', 'strikes': 3, 'strike_spells': list(STRIKE_SPELLS),
            'proc_marker': REPLENISHMENT, 'chance_pct': 20, 'swings': 50, 'control_swings': 10,
            'off_hand_item': 30754, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ExtraStrikesTests(unittest.TestCase):
    def setUp(self):
        self.scenario, (self.expectation,) = behaviour_scenario(load_fixture_class_file(19), entry())

    def seeded(self, treatment: dict, control: dict | None = None) -> FakeRun:
        model = self.expectation.model
        values = {}
        for arm, counts in ((ARMS[0], control or {}), (ARMS[1], treatment)):
            names = [*READS, *(strike_read(spell, metric) for spell in model['strike_spells']
                               for metric in ('spell_cast_count', STRIKE_METRIC))]
            for name in names:
                values[read_label(model['prefix'], arm, 'start', name)] = 7.0
                values[read_label(model['prefix'], arm, 'end', name)] = 7.0 + counts.get(name, 0)
        return FakeRun(values)

    def treatment(self, procs: int, casts: int, strikes: int, hits: int = 250) -> dict:
        return {'off_hand_hits': hits, 'main_hand_hits': hits, 'procs': procs,
                strike_read(STRIKE_SPELLS[0], 'spell_cast_count'): casts,
                strike_read(STRIKE_SPELLS[0], STRIKE_METRIC): strikes}

    def status(self, run: FakeRun) -> str:
        return judge_behaviour(base_verdict(self.expectation), run, self.expectation).status

    def test_the_control_arm_reads_before_the_learn_and_the_treatment_after_it(self):
        steps = run.validate(self.scenario)['steps']
        learn = next(index for index, step in enumerate(steps)
                     if step == {'action': 'learn', 'actor': CASTER, 'spell': BRUSHIN_OFF_THE_DUSK_R2})
        prefix = self.expectation.model['prefix']
        labels = [step.get('label') for step in steps]
        self.assertLess(labels.index(read_label(prefix, 'control', 'end', 'procs')), learn)
        self.assertGreater(labels.index(read_label(prefix, 'treatment', 'start', 'procs')), learn)
        attacks = [step for step in steps if step['action'] == 'attack']
        self.assertEqual(len(attacks), 2)
        self.assertEqual([step['ms'] for step in steps if str(step.get('label', '')).endswith(' swings')],
                         [10 * 1800, 50 * 1800])
        self.assertEqual(self.expectation.model['metric'], STRIKE_METRIC)

    def test_three_landed_strikes_per_proc_are_ok(self):
        self.assertEqual(self.status(self.seeded(self.treatment(50, 150, 150))), 'ok')

    def test_four_strikes_per_proc_are_an_alert(self):
        self.assertEqual(self.status(self.seeded(self.treatment(50, 200, 200))), 'alert')

    def test_two_strikes_per_proc_are_an_alert(self):
        self.assertEqual(self.status(self.seeded(self.treatment(50, 100, 100))), 'alert')

    def test_a_strike_cast_that_did_not_land_is_an_alert(self):
        self.assertEqual(self.status(self.seeded(self.treatment(50, 151, 150))), 'alert')

    def test_a_control_proc_is_an_alert(self):
        self.assertEqual(self.status(self.seeded(self.treatment(50, 150, 150), {'procs': 1})), 'alert')

    def test_no_proc_is_unmeasured(self):
        self.assertEqual(self.status(self.seeded(self.treatment(0, 0, 0))), 'unmeasured')

    def test_the_proc_share_is_reported_and_pooled_parts_add_up(self):
        part = self.seeded(self.treatment(25, 75, 75))
        verdict = extra_strikes_verdict(base_verdict(self.expectation), [part, part], self.expectation.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['treatment_procs'], 50)
        self.assertIn('proc share 50 of 500 off-hand hits', verdict.explanation)

    def test_bad_entries_are_refused(self):
        for changes in ({'strike_spells': [REPLENISHMENT]}, {'strikes': 0}, {'chance_pct': 100},
                        {'strike_spells': [681392, 681392]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), entry(**changes))
