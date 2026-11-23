import unittest

from compare import compare
from proc_critical import KEY, SUPPRESSOR, control_hits, critical_rating
from procs import PROC_CHECK, proc_scenario
from profile import DBC_DIR
from test_compare import CLASS_FILE, Workspace, assert_step
from test_procs import PROC_KEY, chance_reader, proc_expectation, proc_steps, templar_proc

VINDICATION_OATH = 805332
CRITICAL = {'rating': 'melee', 'source': 'test: only a critical hit rolls'}
def control_reads(moment: str) -> dict:
    return {'events': [f'92111 proc critical control {moment} events 0'],
            'crits': [f'92111 proc critical control {moment} crits 801832'],
            'hits': [f'92111 proc critical control {moment} hits 801832']}


CONTROL = {'start': control_reads('start'), 'end': control_reads('end'), 'minimum_hits': 9,
           'source': CRITICAL['source']}


def critical_entry(**changes) -> dict:
    return {**templar_proc(VINDICATION_OATH), KEY: CRITICAL, **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CriticalTrialsScenarioTest(unittest.TestCase):
    def test_trials_count_critical_hits_and_part_one_holds_the_control_arm(self):
        scenario, [expectation] = proc_scenario(CLASS_FILE, critical_entry(), 0)
        reads = {step['label']: step for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertTrue(reads[f'{VINDICATION_OATH} proc trials']['critical'])
        self.assertEqual(scenario['players'][0]['melee_crit_rating'], 100000)
        control = expectation.model[KEY]
        for moment in ('start', 'end'):
            self.assertFalse(any(reads[label]['critical'] for label in control[moment]['hits']))
            self.assertTrue(all(reads[label]['critical'] for label in control[moment]['crits']))
        suppressed = [step for step in scenario['steps'] if step['action'] == 'set_aura' and step['spell'] == SUPPRESSOR
                      and step.get('amount') is not None]
        self.assertEqual(len(suppressed), 2 * control_hits(expectation.model['chance_pct']))
        labels = [step.get('label') for step in scenario['steps']]
        first_cast = next(index for index, step in enumerate(scenario['steps']) if step.get('spell') == SUPPRESSOR)
        self.assertLess(labels.index(control['start']['events'][0]), first_cast)
        self.assertLess(labels.index(control['end']['events'][0]), labels.index(f'{VINDICATION_OATH} proc trials'))
        self.assertIn(KEY, expectation.rule)

    def test_later_parts_have_no_control_arm(self):
        plan_parts = proc_scenario(CLASS_FILE, critical_entry(), 0)[1][0].model['parts']
        if plan_parts < 2:
            self.skipTest('a single part')
        scenario, [expectation] = proc_scenario(CLASS_FILE, critical_entry(), 1)
        self.assertNotIn(KEY, expectation.model)
        self.assertFalse(any(step.get('spell') == SUPPRESSOR for step in scenario['steps']))

    def test_an_entry_without_the_key_is_unchanged(self):
        plain = templar_proc(VINDICATION_OATH)
        scenario, [expectation] = proc_scenario(CLASS_FILE, plain, 0)
        self.assertNotIn(KEY, expectation.model)
        self.assertFalse(any('critical' in step for step in scenario['steps']))
        self.assertEqual(proc_scenario(CLASS_FILE, {**plain, KEY: None}, 0)[0], scenario)

    def test_refused_inputs(self):
        for raw in ({'rating': 'ranged', 'source': 'x'}, {'rating': 'spell', 'source': ' '}, {'rating': 'spell'},
                    'spell'):
            with self.subTest(raw=raw), self.assertRaisesRegex(ValueError, KEY):
                critical_rating(critical_entry(**{KEY: raw}))
        for changes in ({'trigger': {'action': 'attack', 'spell': 0}}, {'trial_casts': True}):
            with self.subTest(changes=changes), self.assertRaisesRegex(ValueError, KEY):
                critical_rating(critical_entry(**changes))


class CriticalControlVerdictTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def verdict(self, events=0, crits=0, hits=9, drop=None):
        expectation = proc_expectation()
        expectation.model[KEY] = CONTROL
        start, end = CONTROL['start'], CONTROL['end']
        reads = {start['events'][0]: 2, start['crits'][0]: 20, start['hits'][0]: 0, end['events'][0]: 2 + events,
                 end['crits'][0]: 20 + crits, end['hits'][0]: hits}
        if drop:
            reads.pop(drop)
        steps = proc_steps(1699, 340) + [assert_step(label, str(value)) for label, value in reads.items()]
        self.workspace.scenario(PROC_KEY, 'proc', [expectation], steps=steps)
        manifest, results = self.workspace.manifest()
        [verdict] = [verdict for verdict in compare(manifest, results, tooltips=chance_reader())
                     if verdict.check == PROC_CHECK]
        return verdict

    def test_a_met_control_keeps_the_rate_verdict(self):
        verdict = self.verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('critical control: 9 non-critical hits', verdict.explanation)

    def test_a_non_critical_proc_alerts(self):
        self.assertEqual(self.verdict(events=1).status, 'alert')

    def test_a_control_that_crits_or_lacks_hits_is_unmeasured(self):
        for reads in ({'crits': 1}, {'hits': 8}, {'drop': CONTROL['end']['hits'][0]}):
            with self.subTest(reads=reads):
                self.assertEqual(self.verdict(**reads).status, 'unmeasured')


if __name__ == '__main__':
    unittest.main()
