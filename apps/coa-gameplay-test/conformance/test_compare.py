from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

from compare import DbcTooltips, ScenarioDrift, compare, measured_values, read_verdicts, write_outputs
from hits import HitModel, Modifier
from profile import CLASSES_DIR, DBC_DIR
from tooltip import CasterStats, Displayed, Readout
from values import Expectation

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch

CLASS_FILE = json.loads((CLASSES_DIR / 'templar.json').read_text(encoding='utf-8'))
RANK = 1001
FIXED_POINTS = (0, 1)
RIGHTEOUS_UPHEAVAL = 501562
SPELL = 1000
VALUE_KEY = 'conformance-templar-value-1001'
HIT_KEY = 'conformance-templar-hit-1001'
CLASS_TUNING = Modifier(spell_id=887007, effect_index=0, aura=341, percent=-20, applies_to='damage', school_mask=127)
HIT_LABELS = {'armor': 'target armor', 'view_level': 'target view_level', 'total': '1001 hit_mean total',
              'count': '1001 hit_mean count'}
BASE_ACTUALS = {'attack_power': '313', 'ranged_attack_power': '182', 'spell_power 1': '0', 'spell_power 2': '0',
                'spell_power 3': '0', 'spell_power 4': '0', 'spell_power 5': '0', 'spell_power 6': '0',
                'stat 0': '81', 'stat 1': '132', 'stat 2': '79', 'stat 3': '32', 'stat 4': '50',
                'weapon_damage_min': '62.455360412597656', 'known_aura 887007': '1', 'probe_aura 92111': '0'}


def expectation(label, check, displayed, rule, effect=None, model=None):
    return Expectation(label, check, SPELL, RANK, effect, displayed, rule, model)


def assert_step(label, actual):
    return {'action': 'assert', 'label': label, 'actual': actual, 'status': 'passed', 'elapsed_ms': '0'}


def plain_step(action):
    return {'action': action, 'label': action, 'status': 'completed', 'elapsed_ms': '0'}


def hit_model_record(minimum_hits=4):
    return {'kind': 'weapon', 'school_mask': 1, 'weapon': None, 'modifiers': [asdict(CLASS_TUNING)],
            'hits_per_cast': 1, 'reference': {'mean': 543.2, 'sigma': 1.72, 'tooltip_mean': 746.33,
                                              'casts_needed': 1},
            'minimum_hits': minimum_hits, 'scheduled_casts': 6, 'measurements': HIT_LABELS}


class Workspace:
    def __init__(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-compare-'))
        self.scenarios = []
        self.runs = {}
        self.cast_failures = {}

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def scenario(self, key, kind, expectations, tokens=(), steps=(), recorded_hash=None):
        path = self.root / 'out' / 'scenarios' / f'{key}.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({'name': key}, indent=2) + '\n', encoding='utf-8')
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        self.scenarios.append({'key': key, 'file': f'scenarios/{key}.json', 'sha256': sha, 'kind': kind,
                               'spell_id': SPELL, 'spell_name': 'Test Strike', 'rank_id': RANK,
                               'tokens': list(tokens), 'expectations': [asdict(entry) for entry in expectations]})
        if steps is not None:
            self.runs[key] = (list(steps), recorded_hash or sha)

    def rename_run(self, key, folder):
        steps, recorded_hash = self.runs.pop(key)
        self.runs[folder] = (steps, recorded_hash)

    def manifest(self, **base_overrides):
        manifest = {'schema': 1, 'class_id': CLASS_FILE['class_id'], 'class_name': CLASS_FILE['name'],
                    'level': CLASS_FILE['level'], 'class_file': CLASS_FILE, 'scenarios': self.scenarios,
                    'known_modifiers': [{**asdict(CLASS_TUNING), 'base_points': -1, 'real_points_per_level': -0.4}]}
        path = self.root / 'out' / 'manifest.json'
        path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
        results = self.root / 'stamp'
        for key, (steps, recorded_hash) in self.runs.items():
            directory = results / 'gameplay' / 'exploratory' / key
            directory.mkdir(parents=True)
            base = [assert_step(label, actual) for label, actual in {**BASE_ACTUALS, **base_overrides}.items()]
            every = [{'index': str(index), **step} for index, step in enumerate(base + steps)]
            result = {'schema': '1', 'scenario': key, 'status': 'passed', 'message': 'All assertions passed',
                      'max_step_ms': '25', 'steps': every}
            if key in self.cast_failures:
                result['cast_failures'] = self.cast_failures[key]
            (directory / 'result.json').write_text(json.dumps(result), encoding='utf-8')
            (directory / 'summary.json').write_text(json.dumps({'scenario_sha256': recorded_hash}), encoding='utf-8')
        return path, results


class FakeTooltips:
    def __init__(self, tokens, points=None):
        self.tokens = tokens
        self.points = points or {}

    def read(self, rank_id, caster, forced=None):
        values = self.tokens(caster, forced) if callable(self.tokens) else list(self.tokens)
        return Readout(values, [])

    def effect_points(self, spell_id, effect):
        return self.points.get((spell_id, effect), FIXED_POINTS)

    def first_effect(self, rank_id):
        return 0


def constant_reader(*values, points=None):
    return FakeTooltips(values, points)


def reference_hit(class_file, expectation, measured):
    return HitModel(kind='weapon', mean=543.2, sigma=1.72, tooltip_mean=746.33, modifiers=(CLASS_TUNING,),
                    displayed=('$s2', '${$AP*0.4725+$sph*1.35+$m1+0}'))


class CompareTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def fresh(self):
        self.workspace.close()
        self.workspace = Workspace()

    def verdicts(self, reader=None, hit_model=reference_hit, **base_overrides):
        manifest, results = self.workspace.manifest(**base_overrides)
        return compare(manifest, results, tooltips=reader, hit_model=hit_model)

    def value_run(self, expectations, tokens, steps, reader):
        self.workspace.scenario(VALUE_KEY, 'value', expectations, tokens, steps)
        return {verdict.label: verdict for verdict in self.verdicts(reader)}

    def effect_verdict(self, actual, token=Displayed('${$m1*1.1}', 568.9, 0, 'flat'), reader=None):
        label = '1001 effect_value e0 #0'
        verdicts = self.value_run([expectation(label, 'effect_value', token.text, 'read flat', 0)], [token.text],
                                  [assert_step(label, actual)], reader or constant_reader(token))
        return verdicts[label]

    def test_deterministic_effect_within_the_rounding_tolerance_is_ok(self):
        verdict = self.effect_verdict('568')
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual((verdict.measured, verdict.expected), (568.0, 568.9))
        self.assertAlmostEqual(verdict.low, 568.9 - 0.005 * 568.9)

    def test_deterministic_effect_outside_the_tolerance_is_an_alert(self):
        self.assertEqual(self.effect_verdict('600').status, 'alert')

    def test_tolerance_is_half_a_percent_of_a_large_value(self):
        token = Displayed('${$m1*10}', 10000.0, 0, 'flat')
        self.assertEqual(self.effect_verdict('9951', token).status, 'ok')
        self.fresh()
        self.assertEqual(self.effect_verdict('9949', token).status, 'alert')

    def test_unsigned_token_takes_the_sign_of_its_dbc_points(self):
        token = Displayed('$s1', 50.0, 0, 'percent')
        verdict = self.effect_verdict('-50', token, constant_reader(token, points={(RANK, 0): (-51, 1)}))
        self.assertEqual((verdict.status, verdict.expected), ('ok', -50.0))

    def test_unsigned_token_of_the_opposite_sign_to_its_dbc_points_is_an_alert(self):
        token = Displayed('$s1', 50.0, 0, 'percent')
        verdict = self.effect_verdict('-50', token, constant_reader(token, points={(RANK, 0): (49, 1)}))
        self.assertEqual((verdict.status, verdict.expected), ('alert', 50.0))

    def test_unsigned_token_of_another_spell_takes_the_sign_of_that_spell(self):
        token = Displayed('$/10;2002s1', 5.0, None, 'flat')
        verdict = self.effect_verdict('-50', token, constant_reader(token, points={(2002, 0): (-51, 1)}))
        self.assertEqual((verdict.status, verdict.expected), ('ok', -50.0))

    def rolled_verdict(self, actual, value_of_roll):
        text = '${$m1+0+$AP*0.45}'

        def tokens(caster, forced):
            roll = forced[2] if forced else 100
            return [Displayed(text, value_of_roll(roll) + caster.ap * 0.45, 0, 'flat')]

        return self.effect_verdict(actual, Displayed(text, 0.0, 0, 'flat'),
                                   FakeTooltips(tokens, {(RANK, 0): (99, 10)}))

    def test_rolled_effect_inside_the_propagated_roll_interval_is_ok(self):
        verdict = self.rolled_verdict('248', lambda roll: roll)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.low, 100 + 313 * 0.45 - max(1, 0.005 * (100 + 313 * 0.45)))
        self.assertAlmostEqual(verdict.high, 109 + 313 * 0.45 + max(1, 0.005 * (109 + 313 * 0.45)))

    def test_rolled_effect_outside_the_propagated_roll_interval_is_an_alert(self):
        self.assertEqual(self.rolled_verdict('255', lambda roll: roll).status, 'alert')

    def test_rolled_effect_value_carries_the_spread_of_its_roll(self):
        self.assertEqual(self.rolled_verdict('248', lambda roll: roll).detail, {'roll_spread': 9})

    def test_unreadable_value_of_a_rolled_first_effect_carries_the_spread_of_its_roll(self):
        label = '1001 effect_value #1'
        verdicts = self.value_run([expectation(label, 'effect_value', '$x1', 'unreadable: $x1')], [],
                                  [assert_step(label, '173')], constant_reader(points={(RANK, 0): (99, 10)}))
        self.assertEqual((verdicts[label].status, verdicts[label].detail), ('unreadable', {'roll_spread': 9}))

    def test_fixed_effect_value_has_no_roll_spread(self):
        self.assertIsNone(self.effect_verdict('568').detail)

    def test_rolled_effect_in_a_non_monotone_expression_is_unmodelled(self):
        verdict = self.rolled_verdict('248', lambda roll: (roll - 104) ** 2)
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertIn('monotone', verdict.explanation)

    def test_signed_expression_of_the_opposite_sign_is_an_ambiguous_tooltip(self):
        self.assertEqual(self.effect_verdict('-100', Displayed('${$m1*2}', 100.0, 0, 'flat')).status,
                         'ambiguous_tooltip')

    def test_divided_token_expects_the_undivided_effect_points(self):
        self.assertEqual(self.effect_verdict('50', Displayed('$/10;s1', 5.0, 0, 'flat')).status, 'ok')

    def test_caster_stat_token_is_read_again_with_the_measured_stats(self):
        label = '1001 effect_value e0 #0'
        text = '${$AP*0.4725+$sph*1.35+$m1+0}'

        reader = FakeTooltips(lambda caster, forced: [Displayed(text, 421 + caster.ap * 0.4725, 0, 'flat')])
        verdicts = self.value_run([expectation(label, 'effect_value', text, 'read flat', 0)], [text],
                                  [assert_step(label, '568')], reader)
        self.assertEqual(verdicts[label].status, 'ok')
        self.assertAlmostEqual(verdicts[label].expected, 421 + 313 * 0.4725)

    def test_tokens_that_change_with_the_measured_stats_are_an_alert_for_the_spell(self):
        label = '1001 effect_value e0 #0'
        verdicts = self.value_run([expectation(label, 'effect_value', '$s1', 'read flat', 0)], ['$s1', '$s2'],
                                  [assert_step(label, '50')], constant_reader(Displayed('$s1', 50.0, 0, 'flat')))
        self.assertEqual(verdicts[label].status, 'alert')
        self.assertIn('tokens', verdicts[label].explanation)

    def test_cooldown_is_judged_one_sided_within_the_elapsed_step_bound(self):
        label = '1001 cooldown_ms'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0')]

        def cooldown(actual):
            self.fresh()
            verdicts = self.value_run([expectation(label, 'cooldown_ms', '5000', 'max(RecoveryTime, '
                                                   'CategoryRecoveryTime)')], [],
                                      steps + [assert_step(label, actual)], constant_reader())
            return verdicts[label]

        within = cooldown('4994')
        self.assertEqual((within.status, within.low, within.high), ('ok', 4950.0, 5000.0))
        self.assertEqual(cooldown('5001').status, 'alert')
        self.assertEqual(cooldown('4949').status, 'alert')

    def test_failed_cast_leaves_the_checks_after_it_unmeasured_and_judges_the_values_before_it(self):
        token = Displayed('$s1', 50.0, 0, 'flat')
        entries = [expectation('1001 effect_value e0 #0', 'effect_value', '$s1', 'read flat', 0),
                   expectation('1001 power_cost', 'power_cost', '20', 'ManaCost divisor 1'),
                   expectation('1001 aura_amount e0 #0', 'aura_amount', '$s1', 'read flat', 0),
                   expectation('1001 aura_duration_ms #1', 'aura_duration_ms', '$d', 'read duration_ms'),
                   expectation('1001 cooldown_ms', 'cooldown_ms', '20000', 'max(RecoveryTime, CategoryRecoveryTime)')]
        steps = [assert_step('1001 effect_value e0 #0', '50'), assert_step('1001 power_cost', '20'),
                 plain_step('cast'), assert_step('1001 cast_failure', '22'),
                 assert_step('1001 aura_amount e0 #0', '0'), assert_step('1001 aura_duration_ms #1', '0'),
                 assert_step('1001 cooldown_ms', '0')]
        reader = constant_reader(token, Displayed('$d', 20000.0, None, 'duration_ms'))
        verdicts = self.value_run(entries, ['$s1', '$d'], steps, reader)
        self.assertEqual([verdicts[entry.label].status for entry in entries],
                         ['ok', 'ok', 'unmeasured', 'unmeasured', 'unmeasured'])
        self.assertEqual(verdicts['1001 cooldown_ms'].explanation, 'cast failed: SPELL_FAILED_CASTER_AURASTATE (22)')

    def cooldown_after_failure(self, key_failures, tokens=('$s1',), step_failure='0'):
        token = Displayed('$s1', 50.0, 0, 'flat')
        entries = [expectation('1001 aura_amount e0 #0', 'aura_amount', '$s1', 'read flat', 0),
                   expectation('1001 cooldown_ms', 'cooldown_ms', '5000', 'max(RecoveryTime, CategoryRecoveryTime)')]
        steps = [plain_step('cast'), assert_step('1001 cast_failure', step_failure),
                 assert_step('1001 aura_amount e0 #0', '50'), assert_step('1001 cooldown_ms', '4994')]
        if key_failures:
            self.fail_casts(VALUE_KEY, *key_failures)
        return self.value_run(entries, list(tokens), steps, constant_reader(token))

    def test_failed_cast_never_masks_tooltip_token_drift(self):
        verdicts = self.cooldown_after_failure(None, ('$s1', '$s2'), '22')
        self.assertEqual(verdicts['1001 aura_amount e0 #0'].status, 'alert')
        self.assertIn('tokens', verdicts['1001 aura_amount e0 #0'].explanation)
        self.assertEqual(verdicts['1001 cooldown_ms'].status, 'unmeasured')

    def test_recorded_reason_zero_is_not_a_failed_cast(self):
        verdicts = self.cooldown_after_failure((RANK, '0'))
        self.assertEqual([verdicts[label].status for label in ('1001 aura_amount e0 #0', '1001 cooldown_ms')],
                         ['ok', 'ok'])

    def test_failed_cast_of_another_rank_leaves_the_value_checks_judged(self):
        verdicts = self.cooldown_after_failure((RANK + 1, '22'))
        self.assertEqual(verdicts['1001 cooldown_ms'].status, 'ok')

    def test_aura_duration_reads_the_duration_token_again(self):
        label = '1001 aura_duration_ms #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0'), assert_step('1001 aura_present', '1'),
                 assert_step(label, '19988')]
        verdicts = self.value_run([expectation(label, 'aura_duration_ms', '$d', 'read duration_ms')], ['$d'], steps,
                                  constant_reader(Displayed('$d', 20000.0, None, 'duration_ms')))
        self.assertEqual((verdicts[label].status, verdicts[label].low), ('ok', 19925.0))

    def test_power_cost_is_compared_in_the_client_display_unit(self):
        label = '1001 power_cost'
        verdicts = self.value_run([expectation(label, 'power_cost', '15', 'ManaCost divisor 10')], [],
                                  [assert_step(label, '150')], constant_reader())
        self.assertEqual((verdicts[label].status, verdicts[label].measured), ('ok', 15.0))

    def test_known_aura_absent_is_an_alert(self):
        label = 'known_aura 887007'
        self.workspace.scenario(VALUE_KEY, 'value', [Expectation(label, 'known_aura', 887007, 887007, None, '887007',
                                                                 'reference profile aura')], [], [])
        verdict = {verdict.label: verdict for verdict in self.verdicts(constant_reader(), **{label: '0'})}[label]
        self.assertEqual(verdict.status, 'alert')

    def test_unreadable_unmeasurable_and_unmodelled_rules_are_never_ok(self):
        entries = [expectation('1001 effect_value #1', 'effect_value', '$?s1[a][b]', 'unreadable: $?s1[a][b]'),
                   expectation('1001 effect_value #2', 'effect_value', '$h', 'unmeasurable: chance_pct token'),
                   expectation('1001 hit_mean', 'unmodelled', '', 'unmodelled: passive spell is never cast'),
                   expectation('1001 effect_value #0', 'effect_value', '', 'unreadable: tooltip without value')]
        verdicts = self.value_run(entries, [], [assert_step('1001 effect_value #1', '3')], constant_reader())
        self.assertEqual([verdicts[entry.label].status for entry in entries],
                         ['unreadable', 'unmodelled', 'unmodelled', 'unreadable'])

    def test_unreadable_portion_is_counted_in_the_report(self):
        entries = [expectation('1001 effect_value #0', 'effect_value', '$?s1[a][b]', 'unreadable: $?s1[a][b]')]
        self.workspace.scenario(VALUE_KEY, 'value', entries, [], [])
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=constant_reader(), hit_model=reference_hit)
        out = self.workspace.root / 'report'
        write_outputs(manifest, results, verdicts, out)
        report = (out / 'report.md').read_text(encoding='utf-8')
        self.assertIn('| unreadable | 1 |', report)
        self.assertRegex(report, r'\| 1000 \| Test Strike \| 0 \| 0 \| 1 \| 0 \| 0 \| 0 \| 0 \|')
        self.assertIn('887007', report)
        alerts = (out / 'alerts.tsv').read_text(encoding='utf-8').splitlines()
        self.assertEqual(len(alerts), 2)
        self.assertIn('unreadable', alerts[1])
        header, stored = read_verdicts(out)
        self.assertEqual(stored, verdicts)
        self.assertEqual((header['class_id'], header['class_name'], header['level']),
                         (CLASS_FILE['class_id'], CLASS_FILE['name'], CLASS_FILE['level']))

    def test_scenario_hash_mismatch_is_an_error_without_verdicts(self):
        label = '1001 effect_value e0 #0'
        token = Displayed('$s1', 50.0, 0, 'flat')
        self.workspace.scenario(VALUE_KEY, 'value', [expectation(label, 'effect_value', '$s1', 'read flat', 0)],
                                ['$s1'], [assert_step(label, '50')], recorded_hash='0' * 64)
        manifest, results = self.workspace.manifest()
        with self.assertRaises(ScenarioDrift):
            compare(manifest, results, tooltips=constant_reader(token), hit_model=reference_hit)

    def test_result_in_another_folder_is_found_by_its_scenario_hash(self):
        label = '1001 effect_value e0 #0'
        self.workspace.scenario(VALUE_KEY, 'value', [expectation(label, 'effect_value', '$s1', 'read flat', 0)],
                                ['$s1'], [assert_step(label, '50')])
        self.workspace.rename_run(VALUE_KEY, 'renamed-file')
        verdicts = self.verdicts(constant_reader(Displayed('$s1', 50.0, 0, 'flat')))
        self.assertEqual([(verdict.status, verdict.scenario) for verdict in verdicts], [('ok', VALUE_KEY)])

    def test_scenario_without_result_gives_no_verdict(self):
        label = '1001 effect_value e0 #0'
        self.workspace.scenario(VALUE_KEY, 'value', [expectation(label, 'effect_value', '$s1', 'read flat', 0)],
                                ['$s1'], None)
        self.assertEqual(self.verdicts(constant_reader()), [])

    def hit_verdict(self, total, count, minimum_hits=4):
        label = '1001 hit_mean'
        entry = expectation(label, 'hit_mean', '$s2 | ${$AP*0.4725+$sph*1.35+$m1+0}', 'weapon hit', 0,
                            hit_model_record(minimum_hits))
        steps = [assert_step('target armor', '528'), assert_step('target view_level', '60'),
                 assert_step(HIT_LABELS['total'], total), assert_step(HIT_LABELS['count'], count)]
        self.workspace.scenario(HIT_KEY, 'hit', [entry], [], steps)
        return {verdict.label: verdict for verdict in self.verdicts()}[label]

    def test_hit_mean_inside_the_99_percent_interval_is_ok(self):
        verdict = self.hit_verdict('2172', '4')
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 543.0)
        self.assertAlmostEqual(verdict.high - verdict.expected, 2.576 * 1.72 / 2)

    def test_hit_mean_outside_the_99_percent_interval_is_an_alert(self):
        verdict = self.hit_verdict('4074', '4')
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1018.5))
        self.assertIn('746.33', verdict.explanation)

    def fail_casts(self, key, spell, *reasons):
        self.workspace.cast_failures[key] = [{'cast_count': str(count), 'spell': str(spell), 'reason': reason,
                                              'actor': 'caster'} for count, reason in enumerate(reasons, start=1)]

    def test_hit_mean_without_any_usable_hit_after_failed_casts_is_unmeasured(self):
        self.fail_casts(HIT_KEY, RANK, '22', '22')
        verdict = self.hit_verdict('0', '0')
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertEqual(verdict.explanation, 'no usable hit; failed casts: 2 x SPELL_FAILED_CASTER_AURASTATE (22)')

    def test_hit_mean_after_a_failed_cast_is_judged_on_the_usable_hits(self):
        self.fail_casts(HIT_KEY, RANK, '22')
        verdict = self.hit_verdict('4074', '4')
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1018.5))
        self.assertIn('failed casts: 1 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    def test_failed_casts_that_leave_too_few_hits_are_insufficient_trials_naming_them(self):
        self.fail_casts(HIT_KEY, RANK, '22', '22', '22')
        verdict = self.hit_verdict('543', '1')
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('failed casts: 3 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    def test_failed_cast_of_another_spell_or_rank_leaves_the_hit_mean_judged(self):
        for other in (9999, RANK + 1):
            self.fresh()
            self.fail_casts(HIT_KEY, other, '22')
            verdict = self.hit_verdict('2172', '4')
            self.assertEqual(verdict.status, 'ok')
            self.assertNotIn('failed', verdict.explanation)

    def test_fewer_usable_hits_than_the_minimum_are_insufficient_trials(self):
        self.assertEqual(self.hit_verdict('543', '1').status, 'insufficient_trials')

    def test_changed_hit_tokens_are_an_alert(self):
        def other_tokens(class_file, entry, measured):
            return HitModel(kind='weapon', mean=543.2, sigma=1.72, tooltip_mean=746.33, displayed=('$s2',))

        label = '1001 hit_mean'
        entry = expectation(label, 'hit_mean', '$s2 | $s1', 'weapon hit', 0, hit_model_record(1))
        steps = [assert_step(HIT_LABELS['total'], '543'), assert_step(HIT_LABELS['count'], '1')]
        self.workspace.scenario(HIT_KEY, 'hit', [entry], [], steps)
        verdict = {verdict.label: verdict for verdict in self.verdicts(hit_model=other_tokens)}[label]
        self.assertEqual(verdict.status, 'alert')


class MeasuredValuesTest(unittest.TestCase):
    def test_harness_actual_strings_become_numbers(self):
        values = measured_values({'steps': [assert_step('weapon_damage_min', '62.455360412597656'),
                                            assert_step('1001 aura_amount e0 #0', '-50'), plain_step('cast')]})
        self.assertEqual(values, {'weapon_damage_min': 62.455360412597656, '1001 aura_amount e0 #0': -50.0})

    def test_non_numeric_actual_is_an_error(self):
        with self.assertRaises(ValueError):
            measured_values({'steps': [assert_step('attack_power', 'n/a')]})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class DbcTooltipsTest(unittest.TestCase):
    def test_forced_roll_replaces_the_rolled_points_of_righteous_upheaval_in_its_expression(self):
        tooltips = DbcTooltips(DBC_DIR)
        caster = CasterStats(level=60, ap=100.0, rap=0.0, sp_by_school={school: 0.0 for school in range(1, 7)},
                             stats={stat: 0.0 for stat in range(5)})
        self.assertEqual(tooltips.effect_points(RIGHTEOUS_UPHEAVAL, 0), (71, 32))
        self.assertEqual(tooltips.read(RIGHTEOUS_UPHEAVAL, caster).values[0].value, 72 + 45)
        self.assertEqual(tooltips.read(RIGHTEOUS_UPHEAVAL, caster, (RIGHTEOUS_UPHEAVAL, 0, 7)).values[0].value, 7 + 45)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateTest(unittest.TestCase):
    def test_manifest_hashes_and_keys_match_what_the_runner_records(self):
        from conformance import generate
        out = Path(tempfile.mkdtemp(prefix='conformance-generate-'))
        try:
            manifest_path = generate(CLASS_FILE['class_id'], out, spells=[804929])
            manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            written = [entry for entry in manifest['scenarios'] if entry['file']]
            self.assertTrue(written)
            for entry in written:
                path = out / entry['file']
                scenario = json.loads(path.read_text(encoding='utf-8'))
                recorded = hashlib.sha256((json.dumps(scenario, indent=2) + '\n').encode('utf-8')).hexdigest()
                self.assertEqual(entry['sha256'], recorded)
                self.assertEqual(batch.exploratory_key(path, set()), entry['key'])
            kinds = {entry['kind'] for entry in manifest['scenarios']}
            self.assertEqual(kinds, {'value', 'hit'})
            self.assertEqual([(modifier['spell_id'], modifier['aura'], modifier['percent'])
                              for modifier in manifest['known_modifiers']], [(887007, 341, -20), (887007, 136, -20)])
        finally:
            shutil.rmtree(out)


if __name__ == '__main__':
    unittest.main()
