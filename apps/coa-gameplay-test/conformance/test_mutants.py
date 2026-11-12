import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from compare import Verdict
from mutants import (ACTIVE_METRIC, MANIFEST_KEY, Mutant, MutantError, contamination, load_mutants, mutate,
                     mutated_scenarios)

LABEL = '1000001 behaviour_count'
OTHER = '1000002 trigger_count'


def scenario(first_label='settle'):
    return {'schema': 1, 'name': 'mutant sample', 'players': [{'id': 'caster', 'race': 1, 'class': 19, 'level': 60}],
            'steps': [{'action': 'wait', 'label': first_label, 'ms': 5000},
                      {'action': 'learn', 'actor': 'caster', 'spell': 1000001},
                      {'action': 'assert', 'label': 'reading', 'actor': 'caster', 'metric': 'aura', 'spell': 1000001,
                       'min': 0}]}


def verdict(label, status, scenario_key):
    return Verdict(label, status, 1.0, 1.0, 1.0, 1.0, '', scenario_key, 1000001, 1000001, 'behaviour_count')


class LoadTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.directory, True)

    def write(self, document) -> Path:
        path = self.directory / 'mutants.json'
        path.write_text(json.dumps(document), encoding='utf-8')
        return path

    def test_a_mutant_reads_its_label_spell_op_and_factor(self):
        mutants = load_mutants(self.write([{'label': LABEL, 'spell': 1000001, 'op': 'effect2', 'factor': 2.0}]))
        self.assertEqual(mutants, [Mutant(LABEL, 1000001, 'effect2', 2.0)])

    def test_the_step_is_a_player_scoped_percent_modifier_of_the_native_op(self):
        self.assertEqual(Mutant(LABEL, 1000001, 'effect2', 2.0).step(),
                         {'action': 'spell_mod_mutant', 'actor': 'caster', 'spell': 1000001, 'op': 12, 'percent': 100})
        self.assertEqual(Mutant(LABEL, 1000001, 'chance_of_success', 0.0).step()['percent'], -100)
        self.assertEqual(Mutant(LABEL, 1000001, 'chance_of_success', 0.0).step()['op'], 18)
        self.assertEqual(Mutant(LABEL, 1000001, 'jump_targets', 2.0).step()['op'], 17)
        self.assertEqual(Mutant(LABEL, 1000001, 'duration', 2.0).step()['op'], 1)

    def test_seeded_wrong_percent_is_not_the_factor_itself(self):
        self.assertNotEqual(Mutant(LABEL, 1000001, 'effect1', 2.0).percent, 200)
        self.assertNotEqual(Mutant(LABEL, 1000001, 'effect1', 0.0).percent, 0)

    def test_small_factors_inside_a_tolerance_are_refused(self):
        good = {'label': LABEL, 'spell': 1000001, 'op': 'effect1', 'factor': 2.0}
        for factor in (0.8, 1.2, 0.9, 1.0, 1.5, True):
            with self.subTest(factor=factor), self.assertRaises(MutantError):
                load_mutants(self.write([{**good, 'factor': factor}]))

    def test_refusals(self):
        good = {'label': LABEL, 'spell': 1000001, 'op': 'effect1', 'factor': 2.0}
        for document in ([], {}, [{**good, 'op': 'damage'}], [{**good, 'op': 3}], [{**good, 'spell': 0}],
                         [{**good, 'spell': '1000001'}], [{**good, 'label': ''}], [{**good, 'extra': 1}],
                         [good, good]):
            with self.subTest(document=document), self.assertRaises(MutantError):
                load_mutants(self.write(document))


class MutateTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.directory, True)
        (self.directory / 'scenarios').mkdir()

    def manifest(self, scenarios: dict[str, tuple[dict, list[str]]]) -> Path:
        entries = []
        for key, (document, labels) in scenarios.items():
            text = json.dumps(document, indent=2) + '\n'
            (self.directory / 'scenarios' / f'{key}.json').write_text(text, encoding='utf-8')
            entries.append({'key': key, 'file': f'scenarios/{key}.json',
                            'sha256': hashlib.sha256(text.encode('utf-8')).hexdigest(),
                            'expectations': [{'label': label} for label in labels]})
        path = self.directory / 'manifest.json'
        path.write_text(json.dumps({'class_id': 19, 'scenarios': entries}), encoding='utf-8')
        return path

    def test_the_mutant_follows_the_settle_wait_and_the_scenario_ends_by_checking_it_is_still_active(self):
        path = self.manifest({'a-learned': (scenario(), [LABEL]), 'b': (scenario(), [OTHER])})
        before = (self.directory / 'scenarios' / 'b.json').read_text(encoding='utf-8')
        mutate(path, [Mutant(LABEL, 1000001, 'effect2', 2.0), Mutant(LABEL, 1000003, 'duration', 0.0)])
        manifest = json.loads(path.read_text(encoding='utf-8'))
        text = (self.directory / 'scenarios' / 'a-learned.json').read_text(encoding='utf-8')
        steps = json.loads(text)['steps']
        self.assertEqual([step['action'] for step in steps],
                         ['wait', 'spell_mod_mutant', 'spell_mod_mutant', 'learn', 'assert', 'assert'])
        self.assertEqual((steps[-1]['metric'], steps[-1]['equals']), (ACTIVE_METRIC, 2))
        entry = next(entry for entry in manifest['scenarios'] if entry['key'] == 'a-learned')
        self.assertEqual(entry['sha256'], hashlib.sha256(text.encode('utf-8')).hexdigest())
        self.assertEqual((self.directory / 'scenarios' / 'b.json').read_text(encoding='utf-8'), before)
        self.assertEqual([item['percent'] for item in manifest[MANIFEST_KEY]], [100, -100])
        self.assertEqual(mutated_scenarios(manifest), {'a-learned'})

    def test_a_mutant_whose_label_no_scenario_carries_is_refused(self):
        path = self.manifest({'b': (scenario(), [OTHER])})
        with self.assertRaisesRegex(MutantError, 'no generated scenario'):
            mutate(path, [Mutant(LABEL, 1000001, 'effect2', 2.0)])

    def test_a_scenario_without_the_settle_wait_first_is_refused(self):
        path = self.manifest({'a': (scenario('other'), [LABEL])})
        with self.assertRaisesRegex(MutantError, 'settle'):
            mutate(path, [Mutant(LABEL, 1000001, 'effect2', 2.0)])

    def test_a_manifest_is_mutated_once(self):
        path = self.manifest({'a': (scenario(), [LABEL])})
        mutate(path, [Mutant(LABEL, 1000001, 'effect2', 2.0)])
        with self.assertRaisesRegex(MutantError, 'already mutated'):
            mutate(path, [Mutant(LABEL, 1000001, 'effect2', 2.0)])


class ContaminationTests(unittest.TestCase):
    def test_an_unmutated_scenario_keeping_its_status_class_is_clean(self):
        baseline = [[verdict(OTHER, 'ok', 'b'), verdict(LABEL, 'ok', 'a')]] * 2
        mutant = [[verdict(OTHER, 'tolerated', 'b'), verdict(LABEL, 'alert', 'a')]] * 2
        self.assertEqual(contamination(baseline, mutant, {'a'}), [])

    def test_seeded_unmutated_alert_is_contamination(self):
        baseline = [[verdict(OTHER, 'ok', 'b')]] * 2
        mutant = [[verdict(OTHER, 'ok', 'b')], [verdict(OTHER, 'alert', 'b')]]
        changed = contamination(baseline, mutant, {'a'})
        self.assertEqual([(item['label'], item['baseline'], item['mutant']) for item in changed],
                         [(OTHER, ['ok', 'ok'], ['ok', 'alert'])])

    def test_an_unmutated_label_missing_from_the_mutant_runs_is_contamination(self):
        baseline = [[verdict(OTHER, 'ok', 'b')]] * 2
        changed = contamination(baseline, [[], []], set())
        self.assertEqual(changed[0]['mutant'], [None, None])

    def test_insufficient_trials_is_not_judged_and_not_contamination(self):
        baseline = [[verdict(OTHER, 'ok', 'b')]] * 2
        mutant = [[verdict(OTHER, 'insufficient_trials', 'b')], [verdict(OTHER, 'ok', 'b')]]
        self.assertEqual(contamination(baseline, mutant, set()), [])


if __name__ == '__main__':
    unittest.main()
