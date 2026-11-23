import unittest

from behaviours import behaviour_scenario
from compare import Verdict, judge_behaviour
from kinds.caster_hits import SECOND_CASTER, caster_hits_spec
from profile import CASTER, DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun

QUOTE = ("Torpedo forward in the direction you're running and deal ${$500761m1+$500761ppl1+$AP*.35} Shadowflame "
         "Damage to enemies in your path.")


def torpedo_entry(casters: int = 2, **changes) -> dict:
    entry = {'spell': 500610, 'name': 'Fel Torpedo', 'kind': 'caster_hits', 'label_suffix': 'torpedo',
             'quote': QUOTE, 'cast_spell': 500610, 'hit_spell': 500761, 'casters': casters, 'trials': 3,
             'hits_per_cast': 1, 'dummy_distance': 2, 'cast_power': 100, 'settle_ms': 1500, 'cast_target': 'self',
             'trial_position': {'map': 0, 'x': -9617.06, 'y': -288.949, 'z': 57.3053, 'o': 0}}
    if casters == 2:
        entry['gap_ms'] = 100
    return {**entry, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CasterHitsTests(unittest.TestCase):
    def built(self, casters: int = 2):
        return behaviour_scenario(load_fixture_class_file(23), torpedo_entry(casters))

    def statuses(self, per_cast: dict[str, int]) -> list[str]:
        _, expectations = self.built()
        values = {}
        for expectation in expectations:
            actor = SECOND_CASTER if f' {SECOND_CASTER} #' in expectation.label else CASTER
            trial = int(expectation.label.rsplit('#', 1)[1])
            values[expectation.model['before_label']] = float((trial - 1) * per_cast[actor])
            values[expectation.model['after_label']] = float(trial * per_cast[actor])
        verdicts = []
        for expectation in expectations:
            base = Verdict(expectation.label, 'alert', None, None, None, None, '', 'fake', expectation.spell_id,
                           expectation.rank_id, expectation.check)
            verdicts.append(judge_behaviour(base, FakeRun(values), expectation).status)
        return verdicts

    def test_the_second_caster_casts_the_gap_after_the_first_and_both_are_read(self):
        scenario, expectations = self.built()
        steps = run.validate(scenario)['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast']
        self.assertEqual([steps[index]['actor'] for index in casts[:2]], [CASTER, SECOND_CASTER])
        self.assertEqual([steps[index]['target'] for index in casts[:2]], [CASTER, SECOND_CASTER])
        self.assertEqual(steps[casts[0] + 1], {'action': 'wait', 'label': 'second caster gap 1', 'ms': 100})
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER, SECOND_CASTER])
        self.assertEqual(scenario['location'], {'map': 0, 'x': -9617.06, 'y': -288.949, 'z': 57.3053, 'o': 0.0})
        self.assertEqual(len(expectations), 6)

    def test_one_caster_has_no_second_player(self):
        scenario, expectations = self.built(casters=1)
        self.assertEqual([player['id'] for player in scenario['players']], [CASTER])
        self.assertEqual(len(expectations), 3)

    def test_one_hit_per_caster_per_cast_passes(self):
        self.assertEqual(set(self.statuses({CASTER: 1, SECOND_CASTER: 1})), {'ok'})

    def test_two_hits_per_cast_alert(self):
        self.assertEqual(set(self.statuses({CASTER: 2, SECOND_CASTER: 2})), {'alert'})

    def test_a_second_caster_blocked_by_the_first_alerts(self):
        statuses = self.statuses({CASTER: 1, SECOND_CASTER: 0})
        self.assertEqual(statuses[:3], ['ok'] * 3)
        self.assertEqual(statuses[3:], ['alert'] * 3)

    def test_a_second_caster_without_a_gap_is_refused(self):
        with self.assertRaises(ValueError):
            caster_hits_spec(torpedo_entry(gap_ms=0))
        with self.assertRaises(ValueError):
            caster_hits_spec(torpedo_entry(casters=3))
        with self.assertRaises(ValueError):
            caster_hits_spec(torpedo_entry(cast_target='enemy'))
