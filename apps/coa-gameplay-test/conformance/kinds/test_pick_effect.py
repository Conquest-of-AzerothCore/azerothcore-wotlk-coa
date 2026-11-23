import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from profile import DBC_DIR, load_fixture_class_file
import run
from test_behaviours import FakeRun, base_verdict

HASTE, HEALING, CRIT, ARMOR = 802207, 802208, 802215, 802216
ENTRY = {'spell': 705848, 'name': "Loa's Blessing (each blessing's effect)", 'kind': 'pick_effect',
         'variant': 'blessings', 'label_suffix': 'blessing', 'quote': '@ext:@s:802207:0@:ext@',
         'cast_spell': 501205, 'cast_power': 1400, 'trials': 20, 'control_trials': 1,
         'picks': [{'aura': HASTE, 'label_suffix': 'pick_haste', 'quote': '@ext:@s:802207:0@:ext@',
                    'reads': [{'metric': 'cast_speed_multiplier', 'ratio': 0.970874, 'tolerance': 0.0001}]},
                   {'aura': HEALING, 'label_suffix': 'pick_healing', 'quote': '@ext:@s:802208:0@:ext@',
                    'reads': [{'metric': 'spell_healing_taken', 'fields': {'spell': 501205, 'target': 'caster'},
                               'ratio': 1.03, 'tolerance': 0.001}]},
                   {'aura': CRIT, 'label_suffix': 'pick_crit', 'quote': '@ext:@s:802215:0@:ext@',
                    'reads': [{'metric': 'melee_crit_chance', 'gain': 3, 'tolerance': 0.01}]},
                   {'aura': ARMOR, 'label_suffix': 'pick_physical', 'quote': '@ext:@s:802216:0@:ext@',
                    'reads': [{'metric': 'melee_damage_taken', 'ratio': 0.97, 'tolerance': 0.001}]}]}
STATES = {'cast_speed_multiplier': (1.0, 0.970874), 'spell_healing_taken spell 501205 target caster': (1000.0, 1030.0),
          'melee_crit_chance': (5.0, 8.0), 'melee_damage_taken': (1000.0, 970.0)}
PICKED_READ = {str(HASTE): 'cast_speed_multiplier', str(HEALING): 'spell_healing_taken spell 501205 target caster',
               str(CRIT): 'melee_crit_chance', str(ARMOR): 'melee_damage_taken'}


def built(**changes):
    return behaviour_scenario(load_fixture_class_file(23), {**ENTRY, **changes})


def values_for(model: dict, picks: list[str | None], broken: str | None = None) -> dict:
    values = {}
    for row, pick in zip(model['rows'], picks):
        for aura, label in row['auras'].items():
            values[label] = 1.0 if aura == pick else 0.0
        for key, (pre, post) in row['reads'].items():
            plain, changed = STATES[key]
            values[pre] = plain
            values[post] = changed if pick is not None and PICKED_READ[pick] == key and pick != broken else plain
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PickEffectTests(unittest.TestCase):
    def test_each_trial_clears_reads_casts_and_reads_again(self):
        scenario, expectations = built()
        run.validate(scenario)
        self.assertEqual([expectation.label for expectation in expectations],
                         ['705848 behaviour_metric_delta pick_haste', '705848 behaviour_metric_delta pick_healing',
                          '705848 behaviour_metric_delta pick_crit', '705848 behaviour_metric_delta pick_physical'])
        steps = scenario['steps']
        learn = next(index for index, step in enumerate(steps) if step['action'] == 'learn' and step['spell'] == 705848)
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 501205]
        self.assertEqual(len(casts), 21)
        self.assertLess(casts[0], learn)
        self.assertLess(learn, casts[1])
        clears = [index for index, step in enumerate(steps)
                  if step == {'action': 'set_aura', 'actor': 'caster', 'spell': HASTE, 'stacks': 0}]
        self.assertEqual(len(clears), 21)
        self.assertEqual(scenario['creatures'][0]['id'], 'dummy')
        attacker = next(step for step in steps if step.get('metric') == 'melee_damage_taken')
        self.assertEqual(attacker['target'], 'dummy')
        self.assertEqual(expectations[0].model['metric'], 'pick_effect')
        self.assertEqual(expectations[0].model['contrast'], 'learned')

    def test_the_skill_fixture_refreshes_the_stats_before_the_first_read(self):
        scenario, _ = built()
        skills = [step for step in scenario['steps'] if step['action'] == 'set_skill']
        self.assertTrue(skills)
        self.assertTrue(all(step['refresh_stats'] is True for step in skills))
        first_read = next(index for index, step in enumerate(scenario['steps'])
                          if step.get('metric') == 'melee_crit_chance')
        last_skill = max(index for index, step in enumerate(scenario['steps']) if step['action'] == 'set_skill')
        self.assertLess(last_skill, first_read)

    def test_a_pick_holds_its_change_and_no_other(self):
        _, expectations = built()
        model = expectations[0].model
        cycle = [str(HASTE), str(HEALING), str(CRIT), str(ARMOR)]
        picks = [None] + [cycle[index % 4] for index in range(20)]
        for expectation in expectations:
            with self.subTest(label=expectation.label):
                found = judge_behaviour(base_verdict(expectation), FakeRun(values_for(model, picks)), expectation)
                self.assertEqual(found.status, 'ok', found.explanation)
        haste = expectations[0]
        found = judge_behaviour(base_verdict(haste), FakeRun(values_for(model, picks, broken=str(HASTE))), haste)
        self.assertEqual(found.status, 'alert')

    def test_a_trial_without_exactly_one_aura_or_a_control_pick_alerts(self):
        _, expectations = built()
        model = expectations[0].model
        haste = expectations[0]
        for picks in ([str(HASTE)] + [str(HASTE)] * 20, [None] + [None] + [str(HASTE)] * 19):
            with self.subTest(picks=picks[:2]):
                found = judge_behaviour(base_verdict(haste), FakeRun(values_for(model, picks)), haste)
                self.assertEqual(found.status, 'alert')

    def test_a_pick_never_seen_is_unmeasured(self):
        _, expectations = built()
        model = expectations[0].model
        found = judge_behaviour(base_verdict(expectations[0]),
                                FakeRun(values_for(model, [None] + [str(CRIT)] * 20)), expectations[0])
        self.assertEqual(found.status, 'unmeasured')

    def test_the_verdict_is_behaviour_evidence_for_an_empowerment(self):
        from coverage import BEHAVIOUR, DATA, verdict_evidence
        _, expectations = built()
        model = expectations[0].model
        cycle = [str(HASTE), str(HEALING), str(CRIT), str(ARMOR)]
        found = judge_behaviour(base_verdict(expectations[0]),
                                FakeRun(values_for(model, [None] + [cycle[index % 4] for index in range(20)])),
                                expectations[0])
        self.assertEqual(verdict_evidence(found, '@ext::ext@', {},
                                          promise="Healing done by Loa's Brew now applies a random empowerment."),
                         BEHAVIOUR)
        self.assertEqual(verdict_evidence(found, '@ext::ext@', {}), DATA)

    def test_refused_inputs(self):
        for changes in ({'trials': 5}, {'control_trials': 0}, {'picks': ENTRY['picks'][:1]},
                        {'picks': [ENTRY['picks'][0], ENTRY['picks'][0]]},
                        {'picks': [{**ENTRY['picks'][0], 'reads': [{'metric': 'aura', 'ratio': 2, 'tolerance': 1}]},
                                   ENTRY['picks'][1]]},
                        {'picks': [{**ENTRY['picks'][0], 'reads': [{'metric': 'melee_crit_chance', 'gain': 3,
                                                                    'ratio': 1, 'tolerance': 0.1}]},
                                   ENTRY['picks'][1]]},
                        {'picks': [{**ENTRY['picks'][0], 'reads': [{'metric': 'melee_crit_chance', 'gain': 0.01,
                                                                    'tolerance': 0.01}]},
                                   ENTRY['picks'][1]]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                built(**changes)


if __name__ == '__main__':
    unittest.main()
