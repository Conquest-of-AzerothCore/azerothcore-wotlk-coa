import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from coverage import metric_evidence
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

STRIKES = 20


def deflect_entry(**changes) -> dict:
    entry = next(entry for entry in load_class_file(15)['behaviours']
                 if entry.get('spell') == 681453 and entry.get('variant') == 'pavise_deflect')
    return {**entry, **changes}


def readings(model: dict, front: int = 0, outside: int = STRIKES, behind: int = 0, control: int = STRIKES,
             auras=(1, 0, 1), behind_x: float = 6.0, present=1) -> dict:
    arcs = model['deflect_arcs']
    shield = model['shield_after_learn']
    values = {model['before_label']: control, model['after_label']: control + front + outside + behind,
              shield['before_label']: shield['item'], shield['after_label']: shield['item']}
    landed = control
    for arm, count, aura, (caster_x, caster_y) in zip(('front', 'outside', 'behind'), (front, outside, behind), auras,
                                                     ((0.0, 0.0), (0.0, 8.0), (behind_x, 0.0))):
        landed += count
        values[arcs['labels'][arm]] = landed
        values[arcs['auras'][arm]] = aura
        values.update(dict(zip(arcs['positions'][arm].values(), (0.0, caster_x, caster_y, 3.0, 0.0))))
    if present is not None and 'present' in arcs:
        values[arcs['present']] = present
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DeflectArcsTests(unittest.TestCase):
    def judged(self, entry: dict | None = None, **reads):
        _, [expectation] = behaviour_scenario(load_class_file(15), entry or deflect_entry())
        return judge_behaviour(base_verdict(expectation), FakeRun(readings(expectation.model, **reads)), expectation)

    def test_the_arms_follow_the_front_strikes_and_the_behind_arm_recasts_the_trigger(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), deflect_entry())
        run.validate(scenario)
        steps = scenario['steps']
        labels = [step.get('label') for step in steps]
        arcs = expectation.model['deflect_arcs']
        front, outside, behind = (labels.index(arcs['labels'][arm]) for arm in ('front', 'outside', 'behind'))
        moves = [index for index, step in enumerate(steps) if step['action'] == 'relocate']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 520865]
        strikes = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['actor'] == 'striker']
        self.assertEqual(len(strikes), 4 * STRIKES)
        self.assertEqual([steps[index]['dy'] for index in moves], [8, -8])
        self.assertLess(front, moves[0])
        self.assertLess(moves[0], outside)
        self.assertEqual(len(casts), 2)
        self.assertLess(moves[1], casts[1])
        self.assertLess(casts[1], behind)
        self.assertEqual(metric_evidence()['avoidance_samples'], 'readback')

    def test_no_front_strike_landing_with_every_control_and_outside_strike_landing_is_ok(self):
        verdict = self.judged()
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('; from behind with the aura 0 of 20 (aura 1, striker in front: False)', verdict.explanation)
        self.assertNotIn('recorded, not judged', verdict.explanation)

    def pending(self) -> dict:
        entry = deflect_entry()
        return {**entry, 'deflect_arcs': {**entry['deflect_arcs'], 'owner_question': 'Q-wh-45'}}

    def test_the_generated_contract_names_the_arms_and_judges_the_behind_arm(self):
        scenario, _ = behaviour_scenario(load_class_file(15), deflect_entry())
        for text in ('control', 'front', 'outside', 'behind', 'creature 50519 counted on the caster',
                     'the behind arm lands at most 1 of 20.'):
            self.assertIn(text, scenario['contract'])
        self.assertNotIn('recorded, not judged', scenario['contract'])
        entry = deflect_entry()
        plain = {key: value for key, value in entry['deflect_arcs'].items() if key != 'present_entry'}
        scenario, [expectation] = behaviour_scenario(load_class_file(15), {**entry, 'deflect_arcs': plain})
        self.assertIn('Deflect arms', scenario['contract'])
        self.assertNotIn('present', expectation.model['deflect_arcs'])
        self.assertEqual(self.judged({**entry, 'deflect_arcs': plain}).status, 'ok')

    def test_an_owner_question_records_the_behind_arm_without_judging_it(self):
        scenario, _ = behaviour_scenario(load_class_file(15), self.pending())
        self.assertIn('The behind arm is recorded, not judged, pending owner question Q-wh-45.', scenario['contract'])
        verdict = self.judged(self.pending(), behind=STRIKES)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertIn('recorded, not judged: from behind with the aura 20 of 20', verdict.explanation)
        self.assertEqual(self.judged(self.pending(), auras=(1, 0, 0), behind_x=0.0).status, 'ok')

    def test_the_outside_arm_reads_the_pavise_count_and_needs_it_present(self):
        scenario, [expectation] = behaviour_scenario(load_class_file(15), deflect_entry())
        label = expectation.model['deflect_arcs']['present']
        reads = [step for step in scenario['steps'] if step.get('label') == label]
        self.assertEqual([(step['metric'], step['entry']) for step in reads], [('owned_creature_count', 50519)])
        verdict = self.judged(present=1)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('creature counted in the outside arm: 1', verdict.explanation)
        self.assertIn('which must read 1 (still present)', scenario['contract'])

    def test_a_pavise_gone_or_unread_in_the_outside_arm_alerts(self):
        for present, shown in ((0, '0'), (2, '2'), (None, 'missing')):
            with self.subTest(present=present):
                verdict = self.judged(present=present)
                self.assertEqual(verdict.status, 'alert', verdict.explanation)
                self.assertIn(f'creature counted in the outside arm: {shown}', verdict.explanation)
                self.assertIn('the outside arm must count the creature once', verdict.explanation)

    def test_the_option_refuses_a_malformed_present_entry_or_question(self):
        entry = deflect_entry()
        for changes in ({'present_entry': 0}, {'present_entry': '50519'}, {'owner_question': ''}, {'unknown': 1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), {**entry, 'deflect_arcs': {**entry['deflect_arcs'], **changes}})

    def test_a_pavise_letting_strikes_through_from_behind_alerts(self):
        self.assertEqual(self.judged(behind=1).status, 'ok')
        for behind in (2, 10, STRIKES):
            with self.subTest(behind=behind):
                verdict = self.judged(behind=behind)
                self.assertEqual(verdict.status, 'alert', verdict.explanation)
                self.assertIn('the behind arm must land at most 1 of 20', verdict.explanation)

    def test_a_behind_arm_without_the_aura_or_with_the_striker_in_front_is_unmeasured(self):
        self.assertEqual(self.judged(auras=(1, 0, 0)).status, 'unmeasured')
        self.assertEqual(self.judged(behind_x=0.0).status, 'unmeasured')

    def test_a_server_deflecting_half_the_front_strikes_alerts(self):
        self.assertEqual(self.judged(front=10).status, 'alert')

    def test_a_pavise_deflecting_outside_its_radius_alerts(self):
        verdict = self.judged(outside=0, auras=(1, 0, 1))
        self.assertEqual(verdict.status, 'alert', verdict.explanation)

    def test_a_missing_aura_or_a_striker_out_of_the_front_leaves_the_entry_unmeasured(self):
        self.assertEqual(self.judged(auras=(0, 0, 1)).status, 'unmeasured')
        self.assertEqual(self.judged(auras=(1, 1, 1)).status, 'unmeasured')

    def test_the_option_refuses_an_entry_without_a_strike_after_the_trigger(self):
        entry = deflect_entry()
        for changes in ({'strike': {**entry['strike'], 'after_trigger_ms': None}},
                        {'deflect_arcs': {**entry['deflect_arcs'], 'outside': [0, 0]}},
                        {'deflect_arcs': {**entry['deflect_arcs'], 'settle_ms': 0}}, {'expected_gain': 1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_class_file(15), {**entry, **changes})


if __name__ == '__main__':
    unittest.main()
