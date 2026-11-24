from dataclasses import asdict, replace
import hashlib
import json
import math
from pathlib import Path
import shutil
from statistics import fmean, pstdev
import sys
import tempfile
import unittest
from unittest import mock

from block_value import BLOCK_VALUE_LABEL, BLOCK_VALUE_TERMS
from compare import (ALERT_COLUMNS, CONFORMANT, DATA_ONLY, EFFECT_VALUE_SCOPE, ENGINE_ROUNDING, NOT_MEASURED,
                     PER_LEVEL_ROUNDING, PER_LEVEL_UNMODELLED, per_level_loss, per_level_unmodelled,
                     PERCENT_POINT_METRICS,
                     magnitude_excluded,
                     BuildMismatch, DbcTooltips, ScenarioDrift, Verdict, evaluate,
                     alert_rows, banded_status, compare, delta_margin, log_query_of, measured_values,
                     observation_lines, owner_fallback, question_detail, read_verdicts, resolve_linked_statuses,
                     apply_value_links, resolve_base_roll_links, SUPERSEDED_BY, judge_expectation, resolve_superseded,
                     write_outputs)
from behaviours import BEHAVIOUR_METRIC_DELTA
from bonus_data import BonusRow, BonusTable
from hits import HitModel, Modifier
from profile import DBC_DIR, FIXTURE_CLASSES_DIR, load_fixture_class_file
from classes import class_spells
from tooltip import CasterStats, Displayed, Readout, Unreadable, read_tooltip
from values import (GAP_CLOSER_DISTANCE, GAP_CLOSER_MARGIN_YD, NOMINAL_MELEE_RANGE_YD, Expectation,
                    effect_modifier_label,
                    calc_amount_hooks_label, mean_samples, sample_labels, structure_stats, value_scenario)

sys.path.append(str(Path(__file__).resolve().parents[1]))
import batch

CLASS_FILE = json.loads((FIXTURE_CLASSES_DIR / 'templar.json').read_text(encoding='utf-8'))
RANK = 1001
FIXED_POINTS = (0, 1)
ROLLS = range(100, 110)
RIGHTEOUS_UPHEAVAL = 501562
FINAL_PRAYER = 705268
SPELL = 1000
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'
SCOURGEBANE = 92111
IRON_PENANCE = 523712
KEEPING_THE_OATH = 92109
ZEALOTRY_PASSIVE = 92108
VALUE_KEY = 'conformance-templar-value-1001'
HIT_KEY = 'conformance-templar-hit-1001'
CLASS_TUNING = Modifier(spell_id=887007, effect_index=0, aura=341, percent=-20, applies_to='damage', school_mask=127)
HIT_LABELS = {'armor': 'target armor', 'view_level': 'target view_level', 'total': '1001 hit_mean total',
              'count': '1001 hit_mean count'}
PERIODIC_TOTAL_LABEL = '1001 effect_value #0'
PERIODIC_TOTAL_LABELS = {'total': f'{PERIODIC_TOTAL_LABEL} total', 'count': f'{PERIODIC_TOTAL_LABEL} count'}
BASE_ACTUALS = {'attack_power': '313', 'ranged_attack_power': '182', 'spell_power 1': '0', 'spell_power 2': '0',
                'spell_power 3': '0', 'spell_power 4': '0', 'spell_power 5': '0', 'spell_power 6': '0',
                'stat 0': '81', 'stat 1': '132', 'stat 2': '79', 'stat 3': '32', 'stat 4': '50',
                'weapon_damage_min': '62.455360412597656', 'known_aura 887007': '1', 'probe_aura 92111': '0',
                'skill 70': '300', 'skill 71': '300', 'skill 72': '300', 'skill 136': '300'}
STAFFGUARD, STAFFGUARD_TOKEN = 705295, '${$706583m1+$STA*.3}'
STAFFGUARD_HEALTH_AT_RANK_ZERO, STAFFGUARD_HEALTH_AT_LEVEL_60 = 125, 305
WORKSPACE_COMMIT = '801527e9aaa4'
WORKSPACE_BUILD = 'e' * 64


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


def periodic_total_model_record(minimum_hits=4, hits_per_cast=10):
    return {'kind': 'periodic_damage', 'school_mask': 2, 'weapon': None, 'modifiers': [],
            'hits_per_cast': hits_per_cast, 'reference': {'mean': 100.0, 'sigma': 5.0, 'tooltip_mean': 1000.0,
                                                          'casts_needed': 1},
            'minimum_hits': minimum_hits, 'scheduled_casts': 6, 'measurements': PERIODIC_TOTAL_LABELS}


def calc_amount_hook_steps(expectations, steps, hooks):
    if hooks is None:
        return []
    present = {step.get('label') for step in steps}
    return [assert_step(calc_amount_hooks_label(entry.label), hooks) for entry in expectations
            if entry.check == 'effect_value' and entry.rule.startswith('read ')
            and calc_amount_hooks_label(entry.label) not in present]


class Workspace:
    def __init__(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-compare-'))
        self.scenarios = []
        self.runs = {}
        self.cast_failures = {}
        self.builds = {}

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def scenario(self, key, kind, expectations, tokens=(), steps=(), recorded_hash=None, spell=SPELL,
                 name='Test Strike', rank=RANK, clock='real', hooks='0', build=None):
        path = self.root / 'out' / 'scenarios' / f'{key}.json'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({'name': key}, indent=2) + '\n', encoding='utf-8')
        sha = hashlib.sha256(path.read_bytes()).hexdigest()
        self.scenarios.append({'key': key, 'file': f'scenarios/{key}.json', 'sha256': sha, 'kind': kind,
                               'spell_id': spell, 'spell_name': name, 'rank_id': rank,
                               'tokens': list(tokens), 'expectations': [asdict(entry) for entry in expectations]})
        if steps is not None:
            self.runs[key] = (list(steps) + calc_amount_hook_steps(expectations, steps, hooks), recorded_hash or sha,
                              clock)
        if build is not None:
            self.builds[key] = build

    def rename_run(self, key, folder):
        steps, recorded_hash, clock = self.runs.pop(key)
        self.runs[folder] = (steps, recorded_hash, clock)
        if key in self.builds:
            self.builds[folder] = self.builds.pop(key)

    def manifest(self, known_modifiers=None, **base_overrides):
        manifest = {'schema': 1, 'class_id': CLASS_FILE['class_id'], 'class_name': CLASS_FILE['name'],
                    'level': CLASS_FILE['level'], 'class_file': CLASS_FILE, 'scenarios': self.scenarios,
                    'known_modifiers': known_modifiers if known_modifiers is not None else
                    [{**asdict(CLASS_TUNING), 'base_points': -1, 'real_points_per_level': -0.4}]}
        path = self.root / 'out' / 'manifest.json'
        path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
        results = self.root / 'stamp'
        for key, (steps, recorded_hash, clock) in self.runs.items():
            directory = results / 'gameplay' / 'exploratory' / key
            directory.mkdir(parents=True)
            base = [assert_step(label, actual) for label, actual in {**BASE_ACTUALS, **base_overrides}.items()]
            every = [{'index': str(index), **step} for index, step in enumerate(base + steps)]
            commit, binary = self.builds.get(key, (WORKSPACE_COMMIT, WORKSPACE_BUILD))
            result = {'schema': '1', 'run_id': f'run-{key}', 'scenario': key, 'status': 'passed',
                      'message': 'All assertions passed', 'max_step_ms': '25', 'steps': every,
                      'server_version': f'AzerothCore rev. {commit} 2026-11-10 11:09:47 +0100 (test branch)'}
            if key in self.cast_failures:
                result['cast_failures'] = self.cast_failures[key]
            (directory / 'result.json').write_text(json.dumps(result), encoding='utf-8')
            summary = {'scenario_sha256': recorded_hash, 'binary_sha256': binary}
            if clock == 'simulated':
                summary['simulation'] = {'pace': 'accelerated'}
            (directory / 'summary.json').write_text(json.dumps(summary), encoding='utf-8')
        return path, results


class FakeTooltips:
    def __init__(self, tokens, points=None, fields=None, unscaled=None):
        self.tokens = tokens
        self.points = points or {}
        self.fields = fields or {}
        self.unscaled = unscaled

    def spell_field(self, spell_id, name):
        return self.fields.get((spell_id, name), 0)

    def read(self, rank_id, caster, forced=None, unscaled=False):
        tokens = self.unscaled if unscaled and self.unscaled else self.tokens
        values = tokens(caster, forced) if callable(tokens) else list(tokens)
        return Readout(values, [])

    def effect_points(self, spell_id, effect):
        return self.points.get((spell_id, effect), FIXED_POINTS)

    def first_effect(self, rank_id):
        return 0


class BonusTooltips(FakeTooltips):
    def __init__(self, tokens, points=None, fields=None, modifiers=None, first_ranks=None):
        super().__init__(tokens, points, fields)
        self.modifiers = modifiers or []
        self.first_ranks = first_ranks or {}

    def coefficient_modifiers(self, spell_id):
        return self.modifiers

    def first_rank(self, spell_id):
        return self.first_ranks.get(spell_id)


def rolled_reads_needed():
    values = [roll + 313 * 0.45 for roll in ROLLS]
    return values, mean_samples(values)


def constant_reader(*values, points=None):
    return FakeTooltips(values, points)


def reference_hit(class_file, expectation, measured):
    return HitModel(kind='weapon', mean=543.2, sigma=1.72, tooltip_mean=746.33, modifiers=(CLASS_TUNING,),
                    displayed=('$s2', '${$AP*0.4725+$sph*1.35+$m1+0}'))


PERIODIC_TOTAL_TOKEN = '${($d*1000/$T1)*($m1+0+$SP*.2+$AP*0.1)}'


def periodic_reference_hit(class_file, expectation, measured):
    return HitModel(kind='periodic_damage', mean=100.0, sigma=5.0, tooltip_mean=1000.0, hits_per_cast=10,
                    displayed=(PERIODIC_TOTAL_TOKEN,))


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
        self.assertEqual(self.effect_verdict('9949', token).status, 'tolerated')

    def test_a_deviation_within_five_percent_is_tolerated_not_an_alert(self):
        token = Displayed('${$m1*10}', 10000.0, 0, 'flat')
        verdict = self.effect_verdict('10400', token)
        self.assertEqual(verdict.status, 'tolerated')
        self.assertIn('tolerated', verdict.explanation)

    def test_a_deviation_beyond_five_percent_is_still_an_alert(self):
        token = Displayed('${$m1*10}', 10000.0, 0, 'flat')
        self.assertEqual(self.effect_verdict('10600', token).status, 'alert')

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

    def test_expanded_unsigned_token_takes_the_sign_of_the_referenced_spell(self):
        label = '1001 effect_value 2002e1 #0'
        token = Displayed('$s2', 50.0, None, 'percent', 2002)
        reader = constant_reader(token, points={(2002, 1): (-51, 1), (RANK, 1): (49, 1)})
        item = expectation(label, 'effect_value', '$s2', 'read percent', model={'effect_spell': 2002, 'effect': 1})
        verdicts = self.value_run([item], ['$s2'], [assert_step(label, '-50')], reader)
        self.assertEqual((verdicts[label].status, verdicts[label].expected), ('ok', -50.0))

    def per_tick_verdict(self, read, ticks=6):
        label = '1001 effect_value 2002e0 #0'
        text = '${($d*1000/$T1)*($m1+0+$SP*.05)}'
        model = {'effect_spell': 2002, 'effect': 0, **({'ticks': ticks} if ticks else {})}
        item = expectation(label, 'effect_value', text, 'read flat', model=model)
        reader = constant_reader(Displayed(text, 54.0, None, 'flat', 2002))
        return self.value_run([item], [text], [assert_step(label, read)], reader)[label]

    def test_a_per_tick_foreign_total_is_judged_against_its_per_tick_part(self):
        verdict = self.per_tick_verdict('9')
        self.assertEqual((verdict.status, verdict.expected), ('ok', 9.0))
        self.assertIn('divided by its 6 ticks', verdict.explanation)

    def test_a_per_tick_foreign_total_read_above_its_per_tick_part_alerts(self):
        verdict = self.per_tick_verdict('34')
        self.assertEqual((verdict.status, verdict.expected), ('alert', 9.0))

    def test_seeded_mutant_reading_the_whole_total_per_tick_alerts(self):
        verdict = self.per_tick_verdict('54')
        self.assertEqual((verdict.status, verdict.expected), ('alert', 9.0))

    def test_one_point_off_per_tick_alerts_as_six_points_off_the_total(self):
        for read in ('8', '10'):
            verdict = self.per_tick_verdict(read)
            self.assertEqual((verdict.status, verdict.expected), ('alert', 9.0), read)
            self.fresh()
        verdict = self.per_tick_verdict('9')
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('|measured x 6 - total|', verdict.explanation)

    def test_a_per_tick_per_level_term_is_the_total_term_divided_by_its_ticks(self):
        text = '${($d*1000/$T1)*($m1+0)}'
        label = '1001 effect_value e0 #0'
        fields = {(RANK, 'EffectRealPointsPerLevel[0]'): 1.085, (RANK, 'BaseLevel'): 22, (RANK, 'SpellLevel'): 22,
                  (RANK, 'MaxLevel'): 30}
        reader = FakeTooltips(lambda caster, forced: [Displayed(text, 6 * 60.58, 0, 'flat')], {(RANK, 0): (51, 1)},
                              fields, lambda caster, forced: [Displayed(text, 6 * 51.9, 0, 'flat')])
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'effect_spell': RANK, 'effect': 0,
                                                                         'ticks': 6})
        steps = [assert_step(label, '59')] + [assert_step(effect_modifier_label(label, op), '1000')
                                              for op in ('all', 0)]
        verdict = self.value_run([item], [text], steps, reader)[label]
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING]['truncated_to'], 8.0)

    def test_an_unlisted_total_token_keeps_its_undivided_expectation(self):
        verdict = self.per_tick_verdict('54', ticks=None)
        self.assertEqual((verdict.status, verdict.expected), ('ok', 54.0))

    def rolled_verdict(self, reads, value_of_roll=lambda roll: roll, samples=None):
        text = '${$m1+0+$AP*0.45}'
        label = '1001 effect_value e0 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else 100
            return [Displayed(text, value_of_roll(roll) + caster.ap * 0.45, 0, 'flat')]

        labels = sample_labels(label, samples or len(reads))
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': samples or len(reads)})
        steps = [assert_step(name, str(read)) for name, read in zip(labels, reads)]
        return self.value_run([item], [text], steps, FakeTooltips(tokens, {(RANK, 0): (99, 10)}))[label]

    def bonus_verdict(self, row, reads=None, modifiers=(), spell_level=0, row_spell=RANK, first_ranks=None):
        text = '${$m1+0+$AP*0.55+$sps*1}'
        label = '1001 effect_value e0 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else 100
            return [Displayed(text, roll + caster.ap * 0.55 + caster.sp_by_school[5], 0, 'flat')]

        reads = reads or [ROLLS[index % len(ROLLS)] for index in range(20)]
        labels = sample_labels(label, len(reads))
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': len(reads)})
        steps = [assert_step(name, str(read)) for name, read in zip(labels, reads)]
        reader = BonusTooltips(tokens, {(RANK, 0): (99, 10)},
                               {(RANK, 'Effect[0]'): 2, (RANK, 'SchoolMask'): 32, (RANK, 'SpellLevel'): spell_level,
                                (RANK, 'MaxLevel'): 80, (RANK, 'DmgClass'): 1}, modifiers=list(modifiers),
                               first_ranks=first_ranks)
        table = BonusTable({row_spell: row} if row else {})
        with mock.patch('compare.bonus_table', return_value=table):
            verdict = self.value_run([item], [text], steps, reader)[label]
        self.fresh()
        return verdict

    def test_bare_calc_value_reads_plus_the_bonus_data_terms_are_ok(self):
        verdict = self.bonus_verdict(BonusRow(RANK, 1.0, 0.0, 0.55, 0.0, 'rev_bonus.sql'))
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('spell_bonus_data 1001 (rev_bonus.sql)', verdict.explanation)
        self.assertEqual(verdict.detail['bonus_data']['ap_term'], 172.0)
        self.assertAlmostEqual(verdict.detail['bonus_data']['ap_formula'], 313 * 0.55, places=3)
        self.assertEqual(verdict.detail['bonus_data']['truncated_terms'], 1)
        self.assertIn('terms modelled from spell_bonus_data, not observed', verdict.explanation)
        self.assertIn('int32 172 (Unit.cpp:9885)', verdict.explanation)

    def test_reads_more_than_one_below_per_truncated_term_alert(self):
        row = BonusRow(RANK, 1.0, 0.0, 0.55, 0.0, 'rev.sql')
        lowered = [ROLLS[index % len(ROLLS)] - 2 for index in range(20)]
        self.assertEqual(self.bonus_verdict(row, reads=lowered).status, 'alert')
        self.assertEqual(self.bonus_verdict(row, reads=[read + 1 for read in lowered]).status, 'ok')

    def test_a_rank_without_its_own_row_reads_its_first_ranks_row(self):
        row = BonusRow(1000, 1.0, 0.0, 0.55, 0.0, 'rev_first.sql')
        verdict = self.bonus_verdict(row, row_spell=1000, first_ranks={RANK: 1000})
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('spell_bonus_data 1000 (rev_first.sql), the first rank of 1001', verdict.explanation)
        self.assertIn('SpellMgr.cpp:1010-1016', verdict.explanation)
        self.assertEqual(verdict.detail['bonus_data']['first_rank_of'], RANK)

    def test_a_first_ranks_row_without_the_chain_or_without_its_terms_alerts(self):
        row = BonusRow(1000, 1.0, 0.0, 0.55, 0.0, 'rev_first.sql')
        self.assertEqual(self.bonus_verdict(row, row_spell=1000).status, 'alert')
        self.assertEqual(self.bonus_verdict(row, row_spell=1000, first_ranks={RANK: 999}).status, 'alert')
        mutant = BonusRow(1000, 1.0, 0.0, 0.0, 0.0, 'mutant.sql')
        self.assertEqual(self.bonus_verdict(mutant, row_spell=1000, first_ranks={RANK: 1000}).status, 'alert')

    def test_a_rank_with_its_own_row_keeps_it_over_its_first_rank(self):
        own = self.bonus_verdict(BonusRow(RANK, 1.0, 0.0, 0.55, 0.0, 'rev_bonus.sql'), first_ranks={RANK: 1000})
        self.assertEqual(own.status, 'ok')
        self.assertNotIn('first_rank_of', own.detail['bonus_data'])

    def test_a_row_without_its_attack_power_coefficient_alerts(self):
        self.assertEqual(self.bonus_verdict(BonusRow(RANK, 1.0, 0.0, 0.0, 0.0, 'mutant.sql')).status, 'alert')

    def test_a_zero_row_keeps_the_verdict_without_a_row(self):
        zero = self.bonus_verdict(BonusRow(RANK, 0.0, 0.0, 0.0, 0.0, 'zero.sql'))
        absent = self.bonus_verdict(None)
        self.assertEqual(asdict(zero), asdict(absent))
        self.assertEqual(zero.status, 'alert')
        self.assertNotIn('bonus_data', zero.detail)

    def test_a_periodic_row_or_an_attack_power_coefficient_modifier_is_not_measured(self):
        periodic = self.bonus_verdict(BonusRow(RANK, 0.0, 0.3, 0.0, 0.0, 'dot.sql'))
        modified = self.bonus_verdict(BonusRow(RANK, 1.0, 0.0, 0.55, 0.0, 'rev.sql'), modifiers=[(700001, 'ap')])
        self.assertEqual([periodic.status, modified.status], [NOT_MEASURED] * 2)
        self.assertIn('periodic terms', periodic.explanation)
        self.assertIn('700001', modified.explanation)

    def test_a_spell_power_modifier_or_a_level_penalty_without_spell_power_keeps_the_model(self):
        row = BonusRow(RANK, 1.0, 0.0, 0.55, 0.0, 'rev.sql')
        self.assertEqual(self.bonus_verdict(row, modifiers=[(700001, 'sp')]).status, 'ok')
        self.assertEqual(self.bonus_verdict(row, spell_level=10).status, 'ok')

    def test_an_unreadable_bonus_table_is_not_measured_rather_than_passed(self):
        reads = [ROLLS[index % len(ROLLS)] for index in range(20)]
        text = '${$m1+0+$AP*0.55+$sps*1}'
        label = '1001 effect_value e0 #0'
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': len(reads)})
        steps = [assert_step(name, str(read)) for name, read in zip(sample_labels(label, len(reads)), reads)]
        reader = BonusTooltips(lambda caster, forced: [Displayed(text, (forced[2] if forced else 100) + 172.15, 0,
                                                                 'flat')], {(RANK, 0): (99, 10)}, {})
        with mock.patch('compare.bonus_table', return_value=BonusTable({}, 'rev_x.sql: REPLACE')):
            verdict = self.value_run([item], [text], steps, reader)[label]
        self.assertEqual(verdict.status, NOT_MEASURED)
        self.assertIn('rev_x.sql: REPLACE', verdict.explanation)

    def test_reads_of_a_rolled_effect_follow_the_hit_mean_rule(self):
        values, needed = rolled_reads_needed()
        self.assertEqual(needed, math.ceil((2.576 * pstdev(values) / (0.01 * fmean(values))) ** 2))
        self.assertEqual(needed, 10)

    def test_uniform_reads_of_a_rolled_effect_at_the_needed_count_are_ok(self):
        values, needed = rolled_reads_needed()
        verdict = self.rolled_verdict([math.trunc(values[index % len(values)]) for index in range(needed)])
        half = 2.576 * pstdev(values) / math.sqrt(needed)
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.low, fmean(values) - half - 1)
        self.assertAlmostEqual(verdict.high, fmean(values) + half)

    def test_reads_at_the_low_end_of_the_roll_are_outside_the_interval_but_tolerated(self):
        values, needed = rolled_reads_needed()
        reads = [math.trunc(min(values)) + 1] * needed
        verdict = self.rolled_verdict(reads)
        self.assertEqual(verdict.status, 'tolerated')
        self.assertIn('tolerated', verdict.explanation)

    def test_a_roll_offset_beyond_five_percent_is_still_an_alert(self):
        values, needed = rolled_reads_needed()
        offset = fmean(values) * 0.5
        reads = [math.trunc(values[index % len(values)] + offset) for index in range(needed)]
        self.assertEqual(self.rolled_verdict(reads).status, 'alert')

    def block_rolled_verdict(self, reads, block):
        text = '${$m1+0+$AP*0.45}'
        label = '1001 effect_value e0 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else 100
            return [Displayed(text, roll + caster.ap * 0.45, 0, 'flat')]

        reader = FakeTooltips(tokens, {(RANK, 0): (99, 10)})
        reader.class_file = {BLOCK_VALUE_TERMS: [{'spell': SPELL, 'effect': 0, 'source': 'seeded code term'}]}
        labels = sample_labels(label, len(reads))
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': len(reads)})
        steps = [assert_step(name, str(read)) for name, read in zip(labels, reads)]
        if block is not None:
            steps.append(assert_step(BLOCK_VALUE_LABEL, str(block)))
        return self.value_run([item], [text], steps, reader)[label]

    def test_a_listed_block_value_is_added_to_every_roll_before_the_truncation(self):
        values, needed = rolled_reads_needed()
        reads = [math.trunc(values[index % len(values)] + 11) for index in range(needed)]
        verdict = self.block_rolled_verdict(reads, 11)
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('plus the read block value 11 on effect 0 (seeded code term)', verdict.explanation)
        self.assertAlmostEqual(verdict.expected, fmean(values) + 11)

    def test_seeded_reads_without_the_listed_block_value_alert(self):
        values, needed = rolled_reads_needed()
        reads = [math.trunc(values[index % len(values)]) for index in range(needed)]
        self.assertEqual(self.block_rolled_verdict(reads, 11).status, 'alert')

    def test_a_listed_block_value_the_run_does_not_read_is_unmeasured(self):
        values, needed = rolled_reads_needed()
        verdict = self.block_rolled_verdict([math.trunc(value) for value in values][:needed], None)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn("reads no 'block_value'", verdict.explanation)

    def narrow_roll_verdict(self, read, fraction):
        text = '${$803153m1+$803153ppl1+$AP*0.25+$sph*.25}'
        label = '1001 effect_value e0 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else 55
            return [Displayed(text, 334.0 + fraction + roll, 0, 'flat')]

        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': 1})
        return self.value_run([item], [text], [assert_step(label, str(read))],
                              FakeTooltips(tokens, {(RANK, 0): (53, 3)}))[label]

    def test_a_read_one_below_the_range_that_truncation_reproduces_is_known_engine_rounding(self):
        verdict = self.narrow_roll_verdict(388, 0.25)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail[ENGINE_ROUNDING], [388.25])
        self.assertIn('known engine rounding, int32 truncation: 388.25 truncates to 388', verdict.explanation)

    def test_seeded_read_one_below_that_truncation_does_not_reproduce_is_a_deviation(self):
        verdict = self.narrow_roll_verdict(387, 0.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertNotIn(ENGINE_ROUNDING, verdict.detail)

    def test_seeded_read_one_above_the_range_is_a_deviation(self):
        verdict = self.narrow_roll_verdict(391, 0.25)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('outside the formula range', verdict.explanation)

    def test_a_read_inside_the_range_names_no_rounding(self):
        verdict = self.narrow_roll_verdict(389, 0.25)
        self.assertEqual(verdict.status, 'ok')
        self.assertNotIn(ENGINE_ROUNDING, verdict.detail)

    def per_level_verdict(self, reads, rate=1.085, modifiers=(1000, 1000), tooltip_per_level=8.68,
                          points=(101, 7), rest=251.965, levels=(22, 22, 30)):
        text = '${$m2+0+$AP*0.805+$sph*0.85}'
        label = '1001 effect_value e0 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else points[0] + 1
            return [Displayed(text, roll + tooltip_per_level + rest, 0, 'flat')]

        def unscaled(caster, forced):
            roll = forced[2] if forced else points[0] + 1
            return [Displayed(text, roll + rest, 0, 'flat')]

        fields = {(RANK, 'EffectRealPointsPerLevel[0]'): rate, (RANK, 'BaseLevel'): levels[0],
                  (RANK, 'SpellLevel'): levels[1], (RANK, 'MaxLevel'): levels[2]}
        item = expectation(label, 'effect_value', text, 'read flat', 0, {'samples': len(reads)})
        labels = sample_labels(label, len(reads))
        steps = [assert_step(name, str(read)) for name, read in zip(labels, reads)]
        if modifiers is not None:
            steps += [assert_step(effect_modifier_label(label, op), str(value))
                      for op, value in zip(('all', 0), modifiers)]
        reader = FakeTooltips(tokens, {(RANK, 0): points}, fields, unscaled)
        return self.value_run([item], [text], steps, reader)[label]

    def fixed_per_level_verdict(self, read, tooltip, unscaled_value, modifiers=(1000, 1000)):
        text = '${$m2+0}'
        label = '1001 effect_value e0 #0'
        fields = {(RANK, 'EffectRealPointsPerLevel[0]'): 1.085, (RANK, 'BaseLevel'): 22, (RANK, 'SpellLevel'): 22,
                  (RANK, 'MaxLevel'): 30}
        reader = FakeTooltips(lambda caster, forced: [Displayed(text, tooltip, 0, 'flat')], {(RANK, 0): (51, 1)},
                              fields, lambda caster, forced: [Displayed(text, unscaled_value, 0, 'flat')])
        item = expectation(label, 'effect_value', text, 'read flat', 0)
        steps = [assert_step(label, str(read))] + [assert_step(effect_modifier_label(label, op), str(value))
                                                   for op, value in zip(('all', 0), modifiers)]
        return self.value_run([item], [text], steps, reader)[label]

    def test_seeded_cancelled_term_mutant_one_below_the_tooltip_set_alerts(self):
        tooltip_set = [float(read) for read in range(164, 175)] * 3
        options = {'rate': 0.975, 'tooltip_per_level': 0.0, 'points': (74, 11), 'rest': 89.205,
                   'levels': (18, 18, 26)}
        self.assertEqual(self.per_level_verdict(tooltip_set, **options).status, 'ok')
        self.fresh()
        verdict = self.per_level_verdict([read - 1 for read in tooltip_set], **options)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING], PER_LEVEL_UNMODELLED)
        self.assertIn('the tooltip adds 0 per level where stock CalcValue adds 7.8', verdict.explanation)

    def test_a_loss_that_leaves_the_integer_set_unchanged_names_no_per_level_rounding(self):
        verdict = self.per_level_verdict([362, 363, 364, 365, 366, 367] * 3, rate=1.0025, tooltip_per_level=8.02)
        self.assertEqual(verdict.status, 'ok')
        self.assertNotIn(PER_LEVEL_ROUNDING, verdict.detail)

    def test_a_spell_the_dbc_set_lacks_has_no_per_level_term(self):
        class Lacking(FakeTooltips):
            def spell_field(self, spell_id, name):
                raise Unreadable

        self.assertIsNone(per_level_loss(Lacking([]), RANK, 0, 60))

    def test_a_fixed_value_with_a_per_level_loss_is_judged_by_the_engine_computation(self):
        self.assertEqual(self.fixed_per_level_verdict(60, 60.58, 51.9).status, 'ok')
        self.fresh()
        verdict = self.fixed_per_level_verdict(59, 60.58, 51.9)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING]['truncated_to'], 8.0)
        self.fresh()
        self.assertEqual(self.fixed_per_level_verdict(58, 60.58, 51.9).status, 'alert')

    def test_seeded_fixed_value_one_below_that_no_engine_computation_explains_alerts(self):
        verdict = self.fixed_per_level_verdict(41, 42.0, 42.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING], PER_LEVEL_UNMODELLED)
        self.fresh()
        self.assertEqual(self.fixed_per_level_verdict(42, 42.0, 42.0).status, 'ok')
        self.fresh()
        self.assertEqual(self.fixed_per_level_verdict(59, 60.58, 51.9, modifiers=(900, 1000)).status, 'alert')

    def test_reads_the_per_level_truncation_reproduces_are_known_engine_rounding(self):
        reads = [361, 362, 363, 365, 366, 367, 362, 366, 364, 363, 361, 367, 365, 366, 362, 364, 363, 366, 365, 364]
        verdict = self.per_level_verdict(reads)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING]['engine_range'], [361.0, 367.0])
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING]['truncated_to'], 8.0)
        self.assertIn('per-level term truncated before the sum (SpellInfo.cpp:497)', verdict.explanation)

    def test_an_effect_modifier_leaves_a_low_read_an_unmodelled_alert(self):
        reads = [361, 362, 363, 365, 366, 367, 362, 366, 364, 363, 361, 367, 365, 366, 362, 364, 363, 366, 365, 364]
        for modifiers in ((1100, 1000), (1000, 1050), (900, 1000), None):
            verdict = self.per_level_verdict(reads, modifiers=modifiers)
            self.assertEqual(verdict.status, 'alert')
            self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING], PER_LEVEL_UNMODELLED)
            self.assertIn(PER_LEVEL_UNMODELLED, verdict.explanation)
            self.fresh()

    def test_a_level_clamp_unlike_stock_leaves_a_low_read_an_unmodelled_alert(self):
        reads = [361, 362, 363, 365, 366, 367, 362, 366, 364, 363, 361, 367, 365, 366, 362, 364, 363, 366, 365, 364]
        verdict = self.per_level_verdict(reads, rate=0.6)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('where stock CalcValue adds 4.8', verdict.explanation)

    def test_a_low_read_both_truncations_reproduce_is_named_by_the_per_level_term(self):
        verdict = self.per_level_verdict([362, 365, 367])
        self.assertEqual(verdict.detail[PER_LEVEL_ROUNDING]['engine_range'], [361.0, 367.0])
        self.assertNotIn(ENGINE_ROUNDING, verdict.detail)

    def test_seeded_low_read_the_per_level_truncation_does_not_explain_alerts(self):
        reads = [361, 362, 363, 365, 366, 367, 362, 366, 364, 363, 361, 367, 365, 366, 362, 364, 363, 366, 365, 364]
        self.assertEqual(self.per_level_verdict(reads, rate=1.0).status, 'alert')
        self.fresh()
        self.assertEqual(self.per_level_verdict([360] + reads[1:]).status, 'alert')

    def test_an_alert_of_a_hit_with_a_per_level_loss_says_the_engine_computation_is_not_modelled(self):
        fields = {(RANK, 'EffectRealPointsPerLevel[0]'): 1.085, (RANK, 'BaseLevel'): 22, (RANK, 'SpellLevel'): 22,
                  (RANK, 'MaxLevel'): 30}
        reader = FakeTooltips([], fields=fields)
        alert = Verdict('1001 hit_mean', 'alert', 360.0, 365.0, 363.0, 367.0, 'mean out of band', 'k', 1001, RANK,
                        'hit_mean')
        labelled = per_level_unmodelled(alert, reader, RANK, 60)
        self.assertEqual(labelled.status, 'alert')
        self.assertEqual(labelled.detail[PER_LEVEL_ROUNDING], PER_LEVEL_UNMODELLED)
        self.assertIn(PER_LEVEL_UNMODELLED, labelled.explanation)
        self.assertIs(per_level_unmodelled(replace(alert, status='ok'), reader, RANK, 60).status, 'ok')
        self.assertEqual(per_level_unmodelled(alert, FakeTooltips([]), RANK, 60), alert)

    def test_one_read_of_a_rolled_effect_inside_its_roll_range_is_measured(self):
        verdict = self.rolled_verdict([248])
        self.assertEqual(verdict.status, 'measured')
        self.assertIn('needs 10 reads', verdict.explanation)

    def spell_power_roll_verdict(self, count, flagged=True):
        text = '${$m3+0+$sps*.175}'
        label = '1001 effect_value e2 #0'

        def tokens(caster, forced):
            roll = forced[2] if forced else 61
            return [Displayed(text, roll + caster.sp_by_school[6] * 0.175, 2, 'flat')]

        item = expectation(label, 'effect_value', text, 'read flat', 2, {'samples': count})
        steps = [assert_step(name, str(61 + index % 12)) for index, name in enumerate(sample_labels(label, count))]
        reader = FakeTooltips(tokens, {(RANK, 2): (60, 12)})
        reader.class_file = {'effect_overrides': [{'spell': 1001, 'effect': 2, 'citation': 'seeded',
                                                   **({'placeholder_sample_count': True} if flagged else {})}]}
        return self.value_run([item], [text], steps, reader)[label]

    def test_a_rolled_effect_is_judged_at_the_reads_its_generation_sized(self):
        values = [roll + 0.175 for roll in range(61, 73)]
        self.assertEqual((mean_samples(list(range(61, 73))), mean_samples(values)), (179, 178))
        verdict = self.spell_power_roll_verdict(178)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['reads_needed'], 178)

    def test_an_unflagged_rolled_effect_keeps_the_count_of_its_measured_stats(self):
        verdict = self.spell_power_roll_verdict(178, flagged=False)
        self.assertEqual(verdict.status, 'measured')
        self.assertEqual(verdict.detail['reads_needed'], 179)
        self.assertIn('needs 179 reads', verdict.explanation)

    BASE_ROLL_LABEL = '1001 effect_value 1002e2 #0'
    BASE_ROLL_HIT = '1002 script_hit 1003 strike'
    BASE_ROLL_CONTRAST = '1002 script_hit 1003 strike_rap'

    def base_roll_verdict(self, measured='56', flagged=True, links=True, term=0.15):
        text = '${$m3*$<scalingbp>+$RAP*0.15}'

        def tokens(caster, forced):
            return [Displayed(text, 56.2835 + caster.rap * term, 2, 'flat')]

        item = expectation(self.BASE_ROLL_LABEL, 'effect_value', text, 'read flat', None,
                           {'effect_spell': 1002, 'effect': 2})
        reader = FakeTooltips(tokens)
        override = {'spell': 1002, 'effect': 2, 'citation': 'seeded'}
        if flagged:
            override['base_roll_only'] = True
        if links:
            override.update({'power_term_label': self.BASE_ROLL_HIT, 'contrast_label': self.BASE_ROLL_CONTRAST})
        reader.class_file = {'effect_overrides': [override]}
        return self.value_run([item], [text], [assert_step(self.BASE_ROLL_LABEL, measured)], reader)[
            self.BASE_ROLL_LABEL]

    def unlinked_base_roll_verdict(self, **options):
        with mock.patch('compare.resolve_base_roll_links', side_effect=lambda verdicts: verdicts):
            return self.base_roll_verdict(**options)

    def linked_hit(self, label, status, check='hit_mean'):
        return Verdict(label, status, None, None, None, None, '', check=check)

    def test_an_unflagged_power_token_is_judged_on_its_full_value(self):
        verdict = self.base_roll_verdict(flagged=False)
        self.assertEqual(verdict.status, 'alert')
        self.assertAlmostEqual(verdict.expected, 56.2835 + 182 * 0.15)
        self.assertNotIn('base_roll_only', verdict.detail)

    def test_a_base_roll_only_token_is_judged_on_its_base_and_shows_the_full_value_and_term(self):
        verdict = self.unlinked_base_roll_verdict()
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 56.2835)
        detail = verdict.detail['base_roll_only']
        self.assertAlmostEqual(detail['full_value'], 56.2835 + 182 * 0.15)
        self.assertAlmostEqual(detail['power_term'], 182 * 0.15)
        self.assertAlmostEqual(detail['judged_base'], 56.2835)
        self.assertEqual((detail['power_term_label'], detail['contrast_label']),
                         (self.BASE_ROLL_HIT, self.BASE_ROLL_CONTRAST))
        for words in ('full value 83.5835', 'power term 27.3', 'judged base 56.2835', self.BASE_ROLL_CONTRAST):
            self.assertIn(words, verdict.explanation)

    def test_a_base_roll_only_token_off_its_base_is_an_alert(self):
        self.assertEqual(self.unlinked_base_roll_verdict(measured='83').status, 'alert')

    def test_a_base_roll_only_token_with_its_passing_hit_label_and_contrast_is_accepted(self):
        verdicts = [self.unlinked_base_roll_verdict(), self.linked_hit(self.BASE_ROLL_HIT, 'ok'),
                    self.linked_hit(self.BASE_ROLL_CONTRAST, 'ok')]
        self.assertEqual(resolve_base_roll_links(verdicts)[0].status, 'ok')

    def test_a_refused_base_roll_is_accepted_again_from_its_own_read_once_its_links_pass(self):
        refused = self.base_roll_verdict()
        self.assertEqual(refused.detail['base_roll_only']['read_status'], 'ok')
        verdicts = [refused, self.linked_hit(self.BASE_ROLL_HIT, 'ok'), self.linked_hit(self.BASE_ROLL_CONTRAST, 'ok')]
        accepted = resolve_base_roll_links(verdicts, {self.BASE_ROLL_LABEL})[0]
        self.assertEqual(accepted.status, 'ok')
        self.assertNotIn('not accepted', accepted.explanation)
        verdicts[2] = self.linked_hit(self.BASE_ROLL_CONTRAST, 'alert')
        again = resolve_base_roll_links(resolve_base_roll_links(verdicts))[0]
        self.assertEqual(again.status, 'alert')
        self.assertEqual(again.explanation.count('not accepted'), 1)
        self.assertEqual(resolve_base_roll_links(verdicts, set())[0], refused)

    def test_a_base_roll_only_token_without_a_named_hit_label_is_an_alert(self):
        verdict = self.base_roll_verdict(links=False)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('names no power_term_label and no contrast_label', verdict.explanation)

    CARRIER_TEXT = '${$m1+0+$AP*0.159426}'

    def carrier_verdicts(self, measured='28', aura=227, term=0.159426):
        def tokens(caster, forced):
            return [Displayed(self.CARRIER_TEXT, 28 + caster.ap * term, 0, 'flat')]

        labels = {'effect_value': '1001 effect_value e0 #0', 'aura_amount': '1001 aura_amount e0 #0'}
        items = [expectation(label, check, self.CARRIER_TEXT, 'read flat', 0) for check, label in labels.items()]
        reader = FakeTooltips(tokens, fields={(RANK, 'EffectApplyAuraName[0]'): aura})
        steps = [assert_step(label, measured) for label in labels.values()]
        verdicts = self.value_run(items, [self.CARRIER_TEXT], steps, reader)
        return [verdicts[label] for label in labels.values()]

    def test_an_aura_227_carrier_amount_is_judged_on_its_token_without_power(self):
        for verdict in self.carrier_verdicts():
            self.assertEqual(verdict.status, 'ok')
            self.assertAlmostEqual(verdict.expected, 28)
            detail = verdict.detail['trigger_with_value']
            self.assertAlmostEqual(detail['full_value'], 28 + 313 * 0.159426)
            self.assertAlmostEqual(detail['power_term'], 313 * 0.159426)
            self.assertIn('SpellAuraEffects.cpp:6566', verdict.explanation)

    def test_an_aura_227_carrier_amount_holding_the_power_term_is_an_alert(self):
        for verdict in self.carrier_verdicts(measured=str(round(28 + 313 * 0.159426, 2))):
            self.assertEqual(verdict.status, 'alert')

    def test_mutant_an_aura_227_carrier_judged_on_its_full_token_alerts(self):
        with mock.patch('compare.judge_trigger_with_value', return_value=None):
            for verdict in self.carrier_verdicts():
                self.assertEqual(verdict.status, 'alert')
                self.assertAlmostEqual(verdict.expected, 28 + 313 * 0.159426)

    def test_another_aura_keeps_its_full_token(self):
        for verdict in self.carrier_verdicts(aura=226):
            self.assertEqual(verdict.status, 'alert')
            self.assertNotIn('trigger_with_value', verdict.detail or {})

    def test_an_aura_227_carrier_without_a_power_term_keeps_its_plain_judgement(self):
        for verdict in self.carrier_verdicts(term=0.0):
            self.assertEqual(verdict.status, 'ok')
            self.assertNotIn('trigger_with_value', verdict.detail or {})
            self.assertIn('read with the measured stats', verdict.explanation)

    def test_a_base_roll_only_token_whose_hit_labels_are_not_in_the_comparison_is_an_alert(self):
        verdict = self.base_roll_verdict()
        self.assertEqual(verdict.status, 'alert')
        self.assertIn(f'contrast_label "{self.BASE_ROLL_CONTRAST}" is not in this comparison', verdict.explanation)
        self.assertIn('the base roll read alone would be ok', verdict.explanation)

    def test_a_base_roll_only_token_whose_contrast_is_missing_or_failing_is_an_alert(self):
        raw = self.unlinked_base_roll_verdict()
        hit = self.linked_hit(self.BASE_ROLL_HIT, 'ok')
        for contrast in ([], [self.linked_hit(self.BASE_ROLL_CONTRAST, 'alert')],
                         [self.linked_hit(self.BASE_ROLL_CONTRAST, 'unmeasured')],
                         [self.linked_hit(self.BASE_ROLL_CONTRAST, 'ok', check='effect_value')]):
            with self.subTest(contrast=contrast):
                self.assertEqual(resolve_base_roll_links([raw, hit, *contrast])[0].status, 'alert')

    def test_a_base_roll_only_token_without_a_power_term_is_an_alert(self):
        verdict = self.unlinked_base_roll_verdict(term=0.0)
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('holds no power term', verdict.explanation)

    def test_fewer_reads_than_generation_sized_stay_measured(self):
        verdict = self.spell_power_roll_verdict(177)
        self.assertEqual(verdict.status, 'measured')
        self.assertIn('needs 178 reads', verdict.explanation)

    def test_reads_missing_from_the_run_leave_a_rolled_effect_measured(self):
        _, needed = rolled_reads_needed()
        self.assertEqual(self.rolled_verdict([245] * (needed - 1), samples=needed).status, 'measured')

    def test_rolled_effect_value_carries_the_spread_of_its_roll(self):
        self.assertEqual(self.rolled_verdict([248]).detail,
                         {'reads': 1, 'reads_needed': 10, 'roll_spread': 9, 'scope': EFFECT_VALUE_SCOPE,
                          'calc_amount_hooks': 0})

    def test_unreadable_value_of_a_rolled_first_effect_carries_the_spread_of_its_roll(self):
        label = '1001 effect_value #1'
        verdicts = self.value_run([expectation(label, 'effect_value', '$x1', 'unreadable: $x1')], [],
                                  [assert_step(label, '173')], constant_reader(points={(RANK, 0): (99, 10)}))
        self.assertEqual((verdicts[label].status, verdicts[label].detail), ('unreadable', {'roll_spread': 9}))

    def test_fixed_effect_value_has_no_roll_spread(self):
        self.assertEqual(self.effect_verdict('568').detail, {'scope': EFFECT_VALUE_SCOPE, 'calc_amount_hooks': 0})

    def test_rolled_effect_in_a_non_monotone_expression_is_unmodelled(self):
        verdict = self.rolled_verdict([248], lambda roll: (roll - 104) ** 2)
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertIn('monotone', verdict.explanation)

    def test_signed_expression_of_the_opposite_sign_is_an_ambiguous_tooltip(self):
        self.assertEqual(self.effect_verdict('-100', Displayed('${$m1*2}', 100.0, 0, 'flat')).status,
                         'ambiguous_tooltip')

    def test_foreign_rolled_effect_is_read_with_the_rolls_of_the_referenced_spell(self):
        label = '1001 effect_value 2002e0 #0'
        text = '${$2002m1+0}'
        forced_spells = set()

        def tokens(caster, forced):
            if forced:
                forced_spells.add(forced[0])
            return [Displayed(text, forced[2] if forced else 100, None, 'flat', 2002)]

        reader = FakeTooltips(tokens, {(2002, 0): (99, 10)})
        needed = mean_samples(list(ROLLS))
        item = expectation(label, 'effect_value', text, 'read flat',
                           model={'effect_spell': 2002, 'effect': 0, 'samples': needed})
        uniform = [assert_step(name, str(ROLLS[index % len(ROLLS)]))
                   for index, name in enumerate(sample_labels(label, needed))]
        verdicts = self.value_run([item], [text], uniform, reader)
        self.assertEqual((verdicts[label].status, verdicts[label].detail),
                         ('ok', {'reads': needed, 'reads_needed': needed, 'roll_spread': 9,
                                 'scope': EFFECT_VALUE_SCOPE, 'calc_amount_hooks': 0}))
        self.assertEqual(forced_spells, {2002})
        self.fresh()
        shifted = [assert_step(name, '125') for name in sample_labels(label, needed)]
        verdicts = self.value_run([item], [text], shifted, reader)
        self.assertEqual(verdicts[label].status, 'alert')

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

    def test_cooldown_window_of_a_cast_time_spell_starts_when_the_cast_completes(self):
        label = '1001 cooldown_ms'
        cast_wait = {'action': 'wait', 'label': 'cast time', 'status': 'completed', 'elapsed_ms': '2500'}
        steps = [plain_step('cast'), cast_wait, assert_step('1001 cast_failure', '0')]

        def cooldown(actual):
            self.fresh()
            verdicts = self.value_run([expectation(label, 'cooldown_ms', '5000', 'max(RecoveryTime, '
                                                   'CategoryRecoveryTime)')], [],
                                      steps + [assert_step(label, actual)], constant_reader())
            return verdicts[label]

        within = cooldown('4430')
        self.assertEqual((within.status, within.low, within.high), ('ok', 4425.0, 5000.0))
        self.assertEqual(cooldown('4000').status, 'alert')

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

    def test_foreign_aura_grant_duration_on_the_ally_matches_the_duration_token(self):
        label = '1001 aura_duration_ms 2002 #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0'),
                 plain_step('reset_cooldown'), plain_step('cast'), assert_step('1001 cast_failure 2002 #0', '0'),
                 assert_step(label, '19988')]
        verdicts = self.value_run(
            [expectation(label, 'aura_duration_ms', '$2002d', 'read duration_ms')],
            ['$2002d'], steps, constant_reader(Displayed('$2002d', 20000.0, None, 'duration_ms', 2002)))
        self.assertEqual((verdicts[label].status, verdicts[label].low), ('ok', 19950.0))

    def test_foreign_aura_grant_duration_missing_on_the_ally_is_an_alert(self):
        label = '1001 aura_duration_ms 2002 #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0'),
                 plain_step('reset_cooldown'), plain_step('cast'), assert_step('1001 cast_failure 2002 #0', '0'),
                 assert_step(label, '0')]
        verdicts = self.value_run(
            [expectation(label, 'aura_duration_ms', '$2002d', 'read duration_ms')],
            ['$2002d'], steps, constant_reader(Displayed('$2002d', 20000.0, None, 'duration_ms', 2002)))
        self.assertEqual(verdicts[label].status, 'alert')

    def test_effect_radius_is_read_from_spellradius(self):
        label = '1001 effect_radius e0 #0'
        token = Displayed('$a1', 40.0, 0, 'radius_yards')
        verdicts = self.value_run([expectation(label, 'effect_radius', '$a1', 'read radius_yards', 0)], ['$a1'],
                                  [assert_step(label, '40')], constant_reader(token))
        self.assertEqual(verdicts[label].status, 'ok')

    def test_effect_radius_outside_the_tolerance_is_an_alert(self):
        label = '1001 effect_radius e0 #0'
        token = Displayed('$a1', 40.0, 0, 'radius_yards')
        verdicts = self.value_run([expectation(label, 'effect_radius', '$a1', 'read radius_yards', 0)], ['$a1'],
                                  [assert_step(label, '30')], constant_reader(token))
        self.assertEqual(verdicts[label].status, 'alert')

    def test_aura_amplitude_reads_the_period_token_again(self):
        label = '1001 aura_amplitude_ms e0 #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0'), assert_step('1001 aura_present', '1'),
                 assert_step(label, '1000')]
        verdicts = self.value_run([expectation(label, 'aura_amplitude_ms', '$t1', 'read amplitude_ms', 0)], ['$t1'],
                                  steps, constant_reader(Displayed('$t1', 1000.0, 0, 'amplitude_ms')))
        self.assertEqual(verdicts[label].status, 'ok')

    def test_aura_amplitude_outside_the_tolerance_is_an_alert(self):
        label = '1001 aura_amplitude_ms e0 #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '0'), assert_step('1001 aura_present', '1'),
                 assert_step(label, '800')]
        verdicts = self.value_run([expectation(label, 'aura_amplitude_ms', '$t1', 'read amplitude_ms', 0)], ['$t1'],
                                  steps, constant_reader(Displayed('$t1', 1000.0, 0, 'amplitude_ms')))
        self.assertEqual(verdicts[label].status, 'alert')

    def test_aura_amplitude_after_a_failed_cast_is_unmeasured(self):
        label = '1001 aura_amplitude_ms e0 #0'
        steps = [plain_step('cast'), assert_step('1001 cast_failure', '22')]
        verdicts = self.value_run([expectation(label, 'aura_amplitude_ms', '$t1', 'read amplitude_ms', 0)], ['$t1'],
                                  steps, constant_reader(Displayed('$t1', 1000.0, 0, 'amplitude_ms')))
        self.assertEqual(verdicts[label].status, 'unmeasured')

    def test_own_max_stacks_is_read_from_stackamount(self):
        label = '1001 max_stacks 1001 #0'
        token = Displayed('$u', 3.0, None, 'count')
        verdicts = self.value_run([expectation(label, 'max_stacks', '$u', 'read count')], ['$u'],
                                  [assert_step(label, '3')], constant_reader(token))
        self.assertEqual(verdicts[label].status, 'ok')

    def test_own_max_stacks_mismatch_is_an_alert(self):
        label = '1001 max_stacks 1001 #0'
        token = Displayed('$u', 3.0, None, 'count')
        verdicts = self.value_run([expectation(label, 'max_stacks', '$u', 'read count')], ['$u'],
                                  [assert_step(label, '2')], constant_reader(token))
        self.assertEqual(verdicts[label].status, 'alert')

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

    def gap_closer_verdict(self, measured):
        label = '1001 hit_mean gap_closer_distance'
        self.workspace.scenario(VALUE_KEY, 'value',
                                [Expectation(label, GAP_CLOSER_DISTANCE, SPELL, RANK, None,
                                            str(NOMINAL_MELEE_RANGE_YD),
                                            'gap-closer effect must bring the caster within '
                                            f'{NOMINAL_MELEE_RANGE_YD} yd of ally')], [], [])
        return {verdict.label: verdict for verdict in self.verdicts(constant_reader(), **{label: measured})}[label]

    def test_gap_closer_distance_within_the_margin_of_melee_range_is_ok(self):
        margin = NOMINAL_MELEE_RANGE_YD + GAP_CLOSER_MARGIN_YD
        verdict = self.gap_closer_verdict(str(margin - 0.1))
        self.assertEqual((verdict.status, verdict.expected, verdict.high), ('ok', NOMINAL_MELEE_RANGE_YD, margin))

    def test_gap_closer_distance_beyond_the_margin_is_an_alert(self):
        margin = NOMINAL_MELEE_RANGE_YD + GAP_CLOSER_MARGIN_YD
        verdict = self.gap_closer_verdict(str(margin + 0.1))
        self.assertEqual(verdict.status, 'alert')

    def test_unreadable_unmeasurable_and_unmodelled_rules_are_never_ok(self):
        entries = [expectation('1001 effect_value #1', 'effect_value', '$?s1[a][b]', 'unreadable: $?s1[a][b]'),
                   expectation('1001 effect_value #2', 'effect_value', '$h', 'unmeasurable: chance_pct token'),
                   expectation('1001 hit_mean', 'unmodelled', '', 'unmodelled: passive spell is never cast'),
                   expectation('1001 effect_value #0', 'effect_value', '', 'unreadable: tooltip without value')]
        verdicts = self.value_run(entries, [], [assert_step('1001 effect_value #1', '3')], constant_reader())
        self.assertEqual([verdicts[entry.label].status for entry in entries],
                         ['unreadable', 'unmodelled', 'unmodelled', 'unreadable'])

    def test_generic_rule_is_judged_unmodelled_not_unreadable(self):
        entries = [expectation('1001 effect_value #0', 'effect_value', '',
                               'generic: tooltip has no $ token to check')]
        verdicts = self.value_run(entries, [], [], constant_reader())
        self.assertEqual(verdicts['1001 effect_value #0'].status, 'unmodelled')

    def test_closed_rule_wins_over_the_unmodelled_check(self):
        label = '1001 hit_mean'
        entries = [expectation(label, 'unmodelled', '', 'closed: mail armor is out of scope')]
        verdicts = self.value_run(entries, [], [], constant_reader())
        self.assertEqual(verdicts[label].status, 'closed')
        self.assertEqual(verdicts[label].explanation, 'closed: mail armor is out of scope')

    def test_closed_verdicts_are_excluded_from_alert_rows(self):
        label = '1001 hit_mean'
        entries = [expectation(label, 'unmodelled', '', 'closed: mail armor is out of scope')]
        self.workspace.scenario(VALUE_KEY, 'value', entries, [], [])
        verdicts = self.verdicts(constant_reader())
        self.assertEqual(alert_rows(verdicts), ['\t'.join(ALERT_COLUMNS)])

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_unreadable_portion_is_counted_in_the_report(self):
        entries = [expectation('1001 effect_value #0', 'effect_value', '$?s1[a][b]', 'unreadable: $?s1[a][b]')]
        self.workspace.scenario(VALUE_KEY, 'value', entries, [], [])
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=constant_reader(), hit_model=reference_hit)
        out = self.workspace.root / 'report'
        write_outputs(manifest, results, verdicts, out)
        report = (out / 'report.md').read_text(encoding='utf-8')
        self.assertIn('| unreadable | 1 |', report)
        self.assertRegex(report, r'\| 1000 \| Test Strike \| 0 \| 0 \| 0 \| 1 \| 0 \| 0 \| 0 \| 0 \| 0 \| 0 \|')
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

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_hit_mean_inside_the_99_percent_interval_is_ok(self):
        verdict = self.hit_verdict('2172', '4')
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.measured, 543.0)
        self.assertAlmostEqual(verdict.high - verdict.expected, 2.576 * 1.72 / 2)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_hit_mean_outside_the_99_percent_interval_is_an_alert(self):
        verdict = self.hit_verdict('4074', '4')
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1018.5))
        self.assertIn('746.33', verdict.explanation)

    def periodic_verdict(self, total, count, hits_per_cast=10, minimum_hits=4):
        label = PERIODIC_TOTAL_LABEL
        entry = expectation(label, 'periodic_total', PERIODIC_TOTAL_TOKEN, 'periodic_damage hit', 0,
                            periodic_total_model_record(minimum_hits, hits_per_cast))
        steps = [assert_step(PERIODIC_TOTAL_LABELS['total'], total), assert_step(PERIODIC_TOTAL_LABELS['count'], count)]
        self.workspace.scenario(HIT_KEY, 'periodic_total', [entry], [], steps)
        return {verdict.label: verdict for verdict in self.verdicts(hit_model=periodic_reference_hit)}[label]

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_periodic_total_with_a_zeroed_effect_is_an_alert(self):
        verdict = self.periodic_verdict('0', '40')
        self.assertEqual((verdict.status, verdict.measured), ('alert', 0.0))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_periodic_total_inside_the_99_percent_interval_is_ok(self):
        verdict = self.periodic_verdict('4000', '40')
        self.assertEqual((verdict.status, verdict.measured, verdict.expected), ('ok', 1000.0, 1000.0))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_periodic_total_scales_the_hit_mean_result_by_its_tick_count(self):
        base = self.hit_verdict('2172', '4')
        self.fresh()
        ticks = 10
        label = '1001 periodic_total'
        record = {**hit_model_record(4), 'hits_per_cast': ticks, 'measurements': PERIODIC_TOTAL_LABELS}
        entry = expectation(label, 'periodic_total', '$s2 | ${$AP*0.4725+$sph*1.35+$m1+0}', 'weapon hit', 0, record)
        steps = [assert_step(PERIODIC_TOTAL_LABELS['total'], '2172'), assert_step(PERIODIC_TOTAL_LABELS['count'], '4')]
        self.workspace.scenario(HIT_KEY, 'hit', [entry], [], steps)
        scaled = {verdict.label: verdict for verdict in self.verdicts()}[label]
        self.assertEqual(scaled.status, base.status)
        for attr in ('measured', 'expected', 'low', 'high'):
            self.assertAlmostEqual(getattr(scaled, attr), getattr(base, attr) * ticks)

    def fail_casts(self, key, spell, *reasons):
        self.workspace.cast_failures[key] = [{'cast_count': str(count), 'spell': str(spell), 'reason': reason,
                                              'actor': 'caster'} for count, reason in enumerate(reasons, start=1)]

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_hit_mean_without_any_usable_hit_after_failed_casts_is_unmeasured(self):
        self.fail_casts(HIT_KEY, RANK, '22', '22')
        verdict = self.hit_verdict('0', '0')
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertEqual(verdict.explanation, 'no usable hit; failed casts: 2 x SPELL_FAILED_CASTER_AURASTATE (22)')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_hit_mean_after_a_failed_cast_is_judged_on_the_usable_hits(self):
        self.fail_casts(HIT_KEY, RANK, '22')
        verdict = self.hit_verdict('4074', '4')
        self.assertEqual((verdict.status, verdict.measured), ('alert', 1018.5))
        self.assertIn('failed casts: 1 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_failed_casts_that_leave_too_few_hits_are_insufficient_trials_naming_them(self):
        self.fail_casts(HIT_KEY, RANK, '22', '22', '22')
        verdict = self.hit_verdict('543', '1')
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('failed casts: 3 x SPELL_FAILED_CASTER_AURASTATE (22)', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_failed_cast_of_another_spell_or_rank_leaves_the_hit_mean_judged(self):
        for other in (9999, RANK + 1):
            self.fresh()
            self.fail_casts(HIT_KEY, other, '22')
            verdict = self.hit_verdict('2172', '4')
            self.assertEqual(verdict.status, 'ok')
            self.assertNotIn('failed', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_fewer_usable_hits_than_the_minimum_are_insufficient_trials(self):
        self.assertEqual(self.hit_verdict('543', '1').status, 'insufficient_trials')

    def hit_part(self, part, total, count, armor='528', steps=True):
        label = '1001 hit_mean'
        record = {**hit_model_record(4), 'part': part, 'parts': 2}
        entry = expectation(label, 'hit_mean', '$s2 | ${$AP*0.4725+$sph*1.35+$m1+0}', 'weapon hit', 0, record)
        measured = [assert_step('target armor', armor), assert_step('target view_level', '60'),
                    assert_step(HIT_LABELS['total'], total), assert_step(HIT_LABELS['count'], count)]
        self.workspace.scenario(f'{HIT_KEY}-part-{part + 1}', 'hit', [entry], [], measured if steps else None)

    def hit_verdicts(self, hit_model=reference_hit):
        return [verdict for verdict in self.verdicts(hit_model=hit_model) if verdict.label == '1001 hit_mean']

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_parts_are_summed(self):
        self.hit_part(0, '1086', '2')
        self.hit_part(1, '1086', '2')
        verdicts = self.hit_verdicts()
        self.assertEqual(len(verdicts), 1)
        verdict = verdicts[0]
        self.assertEqual((verdict.status, verdict.measured, verdict.scenario), ('ok', 543.0, HIT_KEY + '-part-1'))
        self.assertAlmostEqual(verdict.high - verdict.expected, 2.576 * 1.72 / 2)
        self.assertIn('4 usable hits', verdict.explanation)
        self.assertIn('2 of 2 parts', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_parts_pool_the_model_of_each_part(self):
        def by_armor(class_file, entry, measured):
            mean = 543.2 if measured['target armor'] == 528 else 540.0
            return HitModel(kind='weapon', mean=mean, sigma=1.72, tooltip_mean=746.33, modifiers=(CLASS_TUNING,),
                            displayed=('$s2', '${$AP*0.4725+$sph*1.35+$m1+0}'))

        self.hit_part(0, '1086', '2', armor='528')
        self.hit_part(1, '1080', '2', armor='562')
        verdict, = self.hit_verdicts(by_armor)
        self.assertAlmostEqual(verdict.expected, (2 * 543.2 + 2 * 540.0) / 4)
        self.assertAlmostEqual(verdict.high - verdict.expected, 2.576 * math.sqrt(4 * 1.72 ** 2) / 4)
        self.assertEqual((verdict.status, verdict.measured), ('ok', 541.5))

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_a_part_without_result_leaves_too_few_hits(self):
        self.hit_part(0, '1086', '2')
        self.hit_part(1, '1086', '2', steps=False)
        verdict, = self.hit_verdicts()
        self.assertEqual(verdict.status, 'insufficient_trials')
        self.assertIn('1 of 2 parts', verdict.explanation)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_changed_hit_tokens_are_an_alert(self):
        def other_tokens(class_file, entry, measured):
            return HitModel(kind='weapon', mean=543.2, sigma=1.72, tooltip_mean=746.33, displayed=('$s2',))

        label = '1001 hit_mean'
        entry = expectation(label, 'hit_mean', '$s2 | $s1', 'weapon hit', 0, hit_model_record(1))
        steps = [assert_step(HIT_LABELS['total'], '543'), assert_step(HIT_LABELS['count'], '1')]
        self.workspace.scenario(HIT_KEY, 'hit', [entry], [], steps)
        verdict = {verdict.label: verdict for verdict in self.verdicts(hit_model=other_tokens)}[label]
        self.assertEqual(verdict.status, 'alert')


def passive_expectation(rank, effect, metric, relation, displayed, points, target=None, named=None, in_mask=None,
                        source_label=None, judged=True, fields=None, aura=None, exact=False, aura_state=False):
    qualifier = target if target is not None else ' '.join(str(value) for value in (fields or {}).values())
    label = ' '.join(str(part) for part in (rank, f'e{effect}', metric, qualifier) if part != '')
    model = {'family': 'P1' if named is not None else 'P2', 'effect': effect, 'aura': aura, 'metric': metric,
             'fields': {**(fields or {}), **({'spell': target} if target else {})}, 'relation': relation,
             'source_label': source_label, 'before_label': f'{label} before', 'after_label': f'{label} after',
             'exact_before_label': f'{label} exact before' if exact else None,
             'exact_after_label': f'{label} exact after' if exact else None,
             'aura_state_label': f'{label} aura_state' if aura_state else None,
             'target': target, 'named': named, 'in_mask': in_mask, 'points': points, 'judged': judged,
             'aura_label': f'{rank} aura_present'}
    return Expectation(label, 'passive_delta', rank, rank, effect, displayed, relation, model)


def delta_steps(entry, before, after):
    return [assert_step(entry.model['before_label'], before), assert_step(entry.model['after_label'], after)]


LIBERTY, AGGRAMARS_RAGE, SOLEMN_SOLDIER, PATIENCE, PIOUS = 705266, 561346, 572555, 712678, 706431
CHIVALRIC, SERENDIPITY, GRACEFUL_FIGHTER, PIOUS_SWEEP, PALADIN_TRAINING = 705272, 300929, 705303, 520034, 520009
LIBRAM_OF_TENACITY, RECKONING, INTERDICT, SACRED_RESTRAINT = 801461, 572741, 560116, 102208
SCOURGEBANE_PASSIVE, HOLY_EDGE, SCARLET_HAMMER = 92111, 707853, 807035
HOLY_UPHEAVAL, ZEALOTRY, JUDICATOR, CALL_OF_THE_MONASTERY, PARAGON = 572547, 500008, 706359, 560550, 706357
BELLS_OF_LIGHT, ZEALOTRY_PASSIVE = 801204, 92108
LEGACY, SCOURGEBANE_DAMAGE, TEMPLARS_MIGHT, RIGHTEOUS_LUNGE, CONDEMN = 806522, 801832, 705291, 570233, 567539
UPHEAVE = 520442
BLESSED_PADDING = 301311
STURDY = 681009
FURY_OF_AGGRAMAR, LIBRAM_OF_CONSECRATION, LIBRAM_OF_FERVOR = 801480, 803893, 805423
SPELL_NAMES = {(RECKONING, 'SpellName[enUS]'): 'Reckoning', (INTERDICT, 'SpellName[enUS]'): 'Interdict',
               (SACRED_RESTRAINT, 'SpellName[enUS]'): 'Sacred Restraint', (RECKONING, 'SchoolMask'): 2}


class CalcAmountAndBuildTest(unittest.TestCase):
    LABEL = '1001 effect_value e0 #0'
    TOKEN = Displayed('${$m1*1.1}', 568.9, 0, 'flat')

    def setUp(self):
        self.workspace = Workspace()
        self.paths = None

    def tearDown(self):
        self.workspace.close()

    def fresh(self):
        self.workspace.close()
        self.workspace = Workspace()
        self.paths = None

    def value(self, actual, hooks='0', key=VALUE_KEY, build=None, label=LABEL):
        self.workspace.scenario(key, 'value', [expectation(label, 'effect_value', self.TOKEN.text, 'read flat', 0)],
                                [self.TOKEN.text], [assert_step(label, actual)], hooks=hooks, build=build)

    def evaluated(self, build=None):
        self.paths = self.paths or self.workspace.manifest()
        manifest, results = self.paths
        return evaluate(manifest, results, tooltips=constant_reader(self.TOKEN), hit_model=reference_hit, build=build)

    def verdict(self, build=None, label=LABEL):
        return next(verdict for verdict in self.evaluated(build).verdicts if verdict.label == label)

    def test_a_hooked_effect_read_is_not_measured_whatever_calc_value_reads(self):
        for actual, calc_value_status in (('305', 'alert'), ('568', 'ok')):
            self.fresh()
            self.value(actual, hooks='1')
            verdict = self.verdict()
            self.assertEqual((verdict.status, verdict.detail['calc_value_status']), (NOT_MEASURED, calc_value_status))
            self.assertNotIn(NOT_MEASURED, CONFORMANT)

    def test_an_unhooked_wrong_read_still_alerts(self):
        self.value('305')
        verdict = self.verdict()
        self.assertEqual((verdict.status, verdict.detail['calc_amount_hooks']), ('alert', 0))

    def test_a_read_without_a_hook_reading_is_unmeasured_not_judged(self):
        self.value('305', hooks=None)
        verdict = self.verdict()
        self.assertEqual((verdict.status, verdict.detail['calc_value_status']), ('unmeasured', 'alert'))

    def test_not_measured_stays_out_of_the_alerts_and_is_listed_in_the_report(self):
        self.value('305', hooks='1')
        manifest, results = self.workspace.manifest()
        comparison = evaluate(manifest, results, tooltips=constant_reader(self.TOKEN), hit_model=reference_hit)
        out = self.workspace.root / 'report'
        write_outputs(manifest, results, comparison.verdicts, out, tooltips=constant_reader(self.TOKEN))
        self.assertEqual(alert_rows(comparison.verdicts), ['\t'.join(ALERT_COLUMNS)])
        report = (out / 'report.md').read_text(encoding='utf-8')
        self.assertIn(f'## Not measured: CalcValue reads of effects whose amount a CalcAmount hook sets\n\n'
                      f'- `{self.LABEL}`', report)
        self.assertIn(f'- Build judged: commit {WORKSPACE_COMMIT}, worldserver sha256 {WORKSPACE_BUILD}', report)

    def test_a_rule_only_verdict_is_selected_without_a_run_and_an_unrun_measurement_is_not(self):
        self.value('568')
        for key, label, rule in (('conformance-templar-value-1002', '1002 effect_value #0', 'closed: no value'),
                                 ('conformance-templar-value-1003', '1003 effect_value #0', 'read flat')):
            self.workspace.scenario(key, 'value', [expectation(label, 'effect_value', self.TOKEN.text, rule, 0)],
                                    [self.TOKEN.text], None)
            self.workspace.scenarios[-1]['file'] = None
        manifest, results = self.workspace.manifest()

        def selection():
            comparison = evaluate(manifest, results, tooltips=constant_reader(self.TOKEN), hit_model=reference_hit)
            return {verdict.label: (verdict.status, verdict.runs, verdict.selected) for verdict in comparison.verdicts}

        self.assertEqual(selection(), {self.LABEL: ('ok', [f'run-{VALUE_KEY}'], True),
                                       '1002 effect_value #0': ('closed', [], True),
                                       '1003 effect_value #0': ('alert', [], False)})
        with mock.patch('compare.rule_only_labels', return_value=set()):
            self.assertFalse(selection()['1002 effect_value #0'][2])

    def test_every_verdict_carries_the_build_and_the_run_that_produced_it(self):
        self.value('305')
        self.workspace.scenario('conformance-templar-value-1002', 'value',
                                [expectation('1002 effect_value #0', 'effect_value', '', 'closed: no value')], [], None)
        self.workspace.scenarios[-1]['file'] = None
        manifest, results = self.workspace.manifest()
        comparison = evaluate(manifest, results, tooltips=constant_reader(self.TOKEN), hit_model=reference_hit)
        by_label = {verdict.label: verdict for verdict in comparison.verdicts}
        measured = by_label[self.LABEL]
        self.assertEqual((measured.status, measured.server_commit, measured.build, measured.runs),
                         ('alert', WORKSPACE_COMMIT, WORKSPACE_BUILD, [f'run-{VALUE_KEY}']))
        static = by_label['1002 effect_value #0']
        self.assertEqual((static.server_commit, static.build, static.runs), (WORKSPACE_COMMIT, WORKSPACE_BUILD, []))
        out = self.workspace.root / 'out'
        write_outputs(manifest, results, comparison.verdicts, out, tooltips=constant_reader(self.TOKEN))
        header, stored = read_verdicts(out)
        self.assertEqual((header['build'], header['server_commit']), (WORKSPACE_BUILD, WORKSPACE_COMMIT))
        self.assertEqual(stored, comparison.verdicts)
        row = (out / 'alerts.tsv').read_text(encoding='utf-8').splitlines()[1].split('\t')
        self.assertEqual(row[-3:], [WORKSPACE_COMMIT, WORKSPACE_BUILD, f'run-{VALUE_KEY}'])

    def test_runs_of_two_builds_are_refused_unless_the_judged_build_is_named(self):
        other = ('0123456789ab', 'f' * 64)
        self.value('568')
        self.value('305', key='conformance-templar-value-1003', build=other, label='1003 effect_value e0 #0')
        with self.assertRaises(BuildMismatch):
            self.evaluated()
        for wanted in (WORKSPACE_BUILD, WORKSPACE_COMMIT[:7]):
            comparison = self.evaluated(wanted)
            labels = {verdict.label for verdict in comparison.verdicts}
            self.assertIn(self.LABEL, labels)
            self.assertNotIn('1003 effect_value e0 #0', labels)
            self.assertEqual(list(comparison.other_build), ['conformance-templar-value-1003'])
            self.assertEqual(comparison.build.binary_sha256, WORKSPACE_BUILD)
        comparison = self.evaluated(other[1])
        self.assertEqual([verdict.status for verdict in comparison.verdicts if verdict.label.startswith('1003')],
                         ['alert'])
        self.assertEqual({verdict.build for verdict in comparison.verdicts}, {other[1]})

    def test_a_modified_tree_keeps_its_marker_and_matches_only_a_marked_commit(self):
        self.value('568', build=('90d75d6925a2+', WORKSPACE_BUILD))
        self.assertEqual(self.evaluated().build.server_commit, '90d75d6925a2+')
        self.assertEqual(self.evaluated('90d75d6+').other_build, {})
        self.assertEqual(list(self.evaluated('90d75d6').other_build), [VALUE_KEY])

    def test_a_named_build_must_be_a_sha256_or_a_commit(self):
        self.value('568')
        with self.assertRaises(BuildMismatch):
            self.evaluated('not-a-build')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GameplayClockGateTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def expectation(self):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 0.0,
                 'before_expected': 1.0, 'metric': 'aura', 'gameplay_clock': 'real'}
        return Expectation('500678 behaviour_dispel_removal 55095', BEHAVIOUR_METRIC_DELTA, SPELL, RANK, None, '0',
                           'prose: "remove 1 disease effect from yourself" (500678)', model)

    def verdict_of(self, clock):
        item = self.expectation()
        self.workspace.scenario('clock-gate', 'behaviour', [item],
                                steps=[assert_step('before', '1'), assert_step('after', '0')], clock=clock)
        manifest, results = self.workspace.manifest()
        verdicts = {verdict.label: verdict for verdict in compare(manifest, results)}
        return verdicts[item.label]

    def test_a_simulated_run_of_a_real_clock_only_scenario_is_unmeasured_not_a_false_pass(self):
        self.assertEqual(self.verdict_of('simulated').status, 'unmeasured')

    def test_a_real_clock_run_of_a_real_clock_only_scenario_is_judged_normally(self):
        self.assertEqual(self.verdict_of('real').status, 'ok')


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class HealAbsorbReadTest(unittest.TestCase):
    def verdict_of(self, before, after):
        model = {'kind': 'metric_delta', 'before_label': 'before', 'after_label': 'after', 'expected': 99.0,
                 'before_expected': 0.0, 'tolerance': 0, 'metric': 'spell_heal_absorb_total'}
        item = Expectation('561201 behaviour_metric_delta heal_absorb', BEHAVIOUR_METRIC_DELTA, SPELL, RANK, None,
                           '99', 'prose: "absorbs the next 99 healing on the target" (561201)', model)
        workspace = Workspace()
        self.addCleanup(workspace.close)
        workspace.scenario('heal-absorb', 'behaviour', [item],
                           steps=[assert_step('before', before), assert_step('after', after)])
        manifest, results = workspace.manifest()
        return {verdict.label: verdict for verdict in compare(manifest, results)}[item.label]

    def test_the_absorbed_healing_of_the_learned_arm_passes(self):
        self.assertEqual(self.verdict_of('0', '99').status, 'ok')

    def test_a_skipped_absorb_field_or_the_landed_heal_read_in_its_place_alerts(self):
        for after in ('0', '1401'):
            with self.subTest(after=after):
                self.assertEqual(self.verdict_of('0', after).status, 'alert')

    def test_an_absorb_in_the_not_learned_control_alerts(self):
        self.assertEqual(self.verdict_of('99', '99').status, 'alert')


class PassiveDeltaTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def passive_run(self, rank, measured, tokens, aura='1', fields=None, name='Passive', points=None,
                    known_modifiers=None, extra_steps=(), **base_overrides):
        self.workspace.close()
        self.workspace = Workspace()
        steps = [step for entry, (before, after) in measured.items() if before is not None
                 for step in delta_steps(entry, before, after)]
        steps += list(extra_steps)
        steps.insert(len(steps) // 2, assert_step(f'{rank} aura_present', aura))
        self.workspace.scenario(f'conformance-templar-passive-{rank}', 'passive', list(measured), [], steps,
                                spell=rank, name=name, rank=rank)
        manifest, results = self.workspace.manifest(known_modifiers=known_modifiers, **base_overrides)
        reader = FakeTooltips(tokens, points, fields={**SPELL_NAMES, **(fields or {})})
        return {verdict.label: verdict for verdict in compare(manifest, results, tooltips=reader,
                                                              hit_model=reference_hit)}

    def single(self, entry, before, after, tokens, **options):
        return self.passive_run(entry.rank_id, {entry: (before, after)}, tokens, **options)[entry.label]

    def test_flat_modifier_delta(self):
        entry = passive_expectation(LIBERTY, 0, 'spell_modifier', 'spell_mod_flat', '$/1000;s1', -30000.0,
                                    LIBRAM_OF_TENACITY, named=False, in_mask=True, fields={'op': 11, 'base': 1000})
        token = [Displayed('$/1000;s1', 30000.0, 0, 'duration_ms')]
        within = self.single(entry, '1000', '-29000', token)
        self.assertEqual((within.status, within.measured, within.expected), ('ok', -30000.0, -30000.0))
        self.assertAlmostEqual(within.high - within.expected, 150.0)
        self.assertEqual(self.single(entry, '1000', '-28800', token).status, 'tolerated')
        self.assertEqual(self.single(entry, '1000', '-19000', token).status, 'alert')

    def test_divided_token_outside_a_duration_expects_the_undivided_points(self):
        entry = passive_expectation(AGGRAMARS_RAGE, 1, 'expertise', 'add', '$/10;s2', 10.0)
        verdict = self.single(entry, '4000', '4010', [Displayed('$/10;s2', 1.0, 1, 'flat')])
        self.assertEqual((verdict.status, verdict.expected), ('ok', 10.0))

    def test_percent_point_delta_has_no_one_point_floor(self):
        entry = passive_expectation(AGGRAMARS_RAGE, 0, 'spell_crit_chance', 'add', '$s1', 6.0,
                                    fields={'school': 1})
        token = [Displayed('$s1', 6.0, 0, 'percent')]
        within = self.single(entry, '2.8592', '8.8592', token)
        self.assertEqual(within.status, 'ok')
        self.assertAlmostEqual(within.high - within.expected, 0.01)
        self.assertEqual(self.single(entry, '2.8592', '8.8792', token).status, 'alert')
        self.assertEqual(self.single(entry, '2.8592', '7.8592', token).status, 'alert')

    def test_crit_chance_consumer_has_no_one_point_floor(self):
        entry = passive_expectation(705284, 0, 'spell_done_crit_chance', 'add', '$s1', 6.0, RECKONING, named=True,
                                    in_mask=True, fields={'target': 'dummy'})
        token = [Displayed('$s1', 6.0, 0, 'percent')]
        self.assertEqual(self.single(entry, '5', '11', token).status, 'ok')
        self.assertEqual(self.single(entry, '5', '10', token).status, 'alert')

    def test_haste_divides(self):
        entry = passive_expectation(SOLEMN_SOLDIER, 0, 'attack_time_ms', 'haste', '$s1', 10.0, fields={'hand': 0})
        token = [Displayed('$s1', 10.0, 0, 'percent')]
        divided = self.single(entry, '2500', '2272.73', token)
        self.assertEqual(divided.status, 'ok')
        self.assertAlmostEqual(divided.expected, 2500 / 1.1 - 2500)
        self.assertEqual(divided.detail, {'metric': 'attack_time_ms'})
        self.assertEqual(self.single(entry, '2500', '2250', token).status, 'alert')

    def ranged_cast_time_entry(self, haste=True):
        entry = passive_expectation(PATIENCE, 1, 'spell_cast_time_ms', 'add', '$/1000;S2', 500.0, LIBRAM_OF_TENACITY,
                                    named=True, in_mask=True)
        if haste:
            entry.model['ranged_haste'] = {'before': f'{entry.label} ranged attack_time_ms before',
                                           'after': f'{entry.label} ranged attack_time_ms after',
                                           'base_ms': 2100, 'item': 15809}
        return entry

    def ranged_cast_time(self, entry, after, haste_reads=('1826.087', '1826.087')):
        token = [Displayed('$/1000;S2', 500.0, 1, 'duration_ms')]
        extra = [assert_step(entry.model['ranged_haste'][moment], read)
                 for moment, read in zip(('before', 'after'), haste_reads) if read is not None] \
            if 'ranged_haste' in entry.model else []
        return self.single(entry, '2173', after, token, name='Patience', extra_steps=extra)

    def test_ranged_haste_after_a_flat_cast_time_modifier_scales_the_expected_delta(self):
        entry = self.ranged_cast_time_entry()
        verdict = self.ranged_cast_time(entry, '2608')
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.expected, 500 * 1826.087 / 2100, places=2)
        self.assertIn('ranged haste multiplies the flat', verdict.explanation)

    def test_a_seeded_unhasted_flat_delta_alerts_under_ranged_haste(self):
        self.assertEqual(self.ranged_cast_time(self.ranged_cast_time_entry(), '2673').status, 'alert')

    def test_a_missing_ranged_haste_read_is_not_judged_ok(self):
        verdict = self.ranged_cast_time(self.ranged_cast_time_entry(), '2608', haste_reads=('1826.087', None))
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('ranged attack_time_ms after', verdict.explanation)

    def test_without_the_haste_model_the_flat_points_are_expected(self):
        entry = self.ranged_cast_time_entry(haste=False)
        self.assertEqual(self.ranged_cast_time(entry, '2608').status, 'alert')
        self.assertEqual(self.ranged_cast_time(entry, '2673').status, 'ok')

    def test_override_naming_every_target_judges_each_one_ok(self):
        libram_a, libram_b = (
            passive_expectation(FURY_OF_AGGRAMAR, 1, 'spell_modifier', 'spell_mod_pct', '$s2', 100.0, target, True,
                                True, fields={'op': 12, 'base': 1000})
            for target in (LIBRAM_OF_CONSECRATION, LIBRAM_OF_FERVOR))
        token = [Displayed('$s2', 100.0, 1, 'percent')]
        verdicts = self.passive_run(FURY_OF_AGGRAMAR, {libram_a: ('1000', '2000'), libram_b: ('1000', '2000')},
                                    token, name='Fury of Aggramar')
        self.assertEqual(verdicts[libram_a.label].status, 'ok')
        self.assertEqual(verdicts[libram_b.label].status, 'ok')
        wrong = self.passive_run(FURY_OF_AGGRAMAR, {libram_a: ('1000', '2000'), libram_b: ('1000', '1500')}, token,
                                 name='Fury of Aggramar')
        self.assertEqual(wrong[libram_a.label].status, 'ok')
        self.assertEqual(wrong[libram_b.label].status, 'alert')

    def test_named_target_outside_the_mask(self):
        interdict, restraint = (
            passive_expectation(PATIENCE, 0, 'spell_modifier', 'spell_mod_flat', '$/1000;s1', 2000.0, target, named,
                                in_mask, fields={'op': 1, 'base': 1000})
            for target, named, in_mask in ((INTERDICT, True, False), (SACRED_RESTRAINT, False, True)))
        token = [Displayed('$/1000;s1', 2000.0, 0, 'duration_ms')]
        verdicts = self.passive_run(PATIENCE, {interdict: ('1000', '1000'), restraint: ('1000', '3000')}, token,
                                    name='Patience')
        self.assertEqual(verdicts[interdict.label].status, 'ambiguous_tooltip')
        self.assertEqual(verdicts[interdict.label].detail['question']['kind'], 'text')
        self.assertEqual(verdicts[restraint.label].status, 'measured')
        verdicts = self.passive_run(PATIENCE, {interdict: ('1000', '1000'), restraint: ('1000', '1000')}, token)
        self.assertEqual((verdicts[interdict.label].status, verdicts[restraint.label].status), ('alert', 'measured'))
        verdicts = self.passive_run(PATIENCE, {interdict: ('1000', '3000'), restraint: ('1000', '1000')}, token)
        self.assertEqual(verdicts[interdict.label].status, 'ok')

    def test_mask_spell_beside_an_unmodelled_named_target_is_unmodelled(self):
        named = passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'add', '$s1', 10.0, ZEALOTRY, True,
                                    True, fields={'effect': 0})
        rule = f'unmodelled: target {ZEALOTRY} has no effect 0'
        named = replace(named, check='unmodelled', rule=rule,
                        model={**named.model, 'before_label': None, 'after_label': None})
        masked = passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'add', '$s1', 10.0, RECKONING, False,
                                     True, fields={'effect': 0})
        verdicts = self.passive_run(HOLY_UPHEAVAL, {named: (None, None), masked: ('100', '110')},
                                    [Displayed('$s1', 10.0, 0, 'flat')],
                                    fields={(ZEALOTRY, 'SpellName[enUS]'): 'Zealotry'})
        self.assertEqual(verdicts[named.label].status, 'unmodelled')
        self.assertEqual(verdicts[masked.label].status, 'unmodelled')
        self.assertIn(f'Zealotry {ZEALOTRY} ({rule})', verdicts[masked.label].explanation)

    def test_named_mask_spell_matches_an_outside_named_spell(self):
        outside, inside = (
            passive_expectation(TEMPLARS_MIGHT, 0, 'spell_modifier', 'spell_mod_flat', '$s1', 6.0, target, True,
                                in_mask, fields={'op': 12, 'base': 1000})
            for target, in_mask in ((RIGHTEOUS_LUNGE, False), (CONDEMN, True)))
        names = {(RIGHTEOUS_LUNGE, 'SpellName[enUS]'): 'Righteous Lunge', (CONDEMN, 'SpellName[enUS]'): 'Condemn'}
        token = [Displayed('$s1', 6.0, 0, 'percent')]
        verdicts = self.passive_run(TEMPLARS_MIGHT, {outside: ('1000', '1000'), inside: ('1000', '1006')}, token,
                                    name="Templar's Might", fields=names)
        self.assertEqual(verdicts[inside.label].status, 'ok')
        self.assertEqual(verdicts[outside.label].status, 'ambiguous_tooltip')

    def test_namesake_of_a_moving_spell_is_measured(self):
        moving, namesake = (
            passive_expectation(LEGACY, 1, 'spell_modifier', 'spell_mod_pct', '$s2', 25.0, target, True, False,
                                fields={'op': 15, 'base': 1000})
            for target in (SCOURGEBANE_DAMAGE, SCOURGEBANE_PASSIVE))
        names = {(SCOURGEBANE_DAMAGE, 'SpellName[enUS]'): 'Scourgebane',
                 (SCOURGEBANE_PASSIVE, 'SpellName[enUS]'): 'Scourgebane'}
        verdicts = self.passive_run(LEGACY, {moving: ('1000', '1250'), namesake: ('1000', '1000')},
                                    [Displayed('$s2', 25.0, 1, 'percent')], fields=names)
        self.assertEqual(verdicts[moving.label].status, 'ok')
        self.assertEqual(verdicts[namesake.label].status, 'measured')
        self.assertIn('namesake', verdicts[namesake.label].explanation)

    def test_change_below_the_resolution_of_a_truncated_stat_is_unmeasured(self):
        entry = passive_expectation(BELLS_OF_LIGHT, 2, 'stat', 'scale', '$s1', 3.0, fields={'stat': 3})
        verdict = self.single(entry, '32', '32', [Displayed('$s1', 3.0, 0, 'percent')])
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('truncates', verdict.explanation)
        self.assertEqual(self.single(entry, '132', '135', [Displayed('$s1', 3.0, 0, 'percent')]).status, 'ok')

    def test_a_fractional_stat_delta_the_one_point_floor_alone_accepts_is_data_only(self):
        entry = passive_expectation(705250, 0, 'stat', 'scale', '$s1', 5.0, fields={'stat': 1})
        token = [Displayed('$s1', 5.0, 0, 'percent')]
        floored = self.single(entry, '132', '138', token)
        self.assertEqual((floored.status, floored.measured), ('ok', 6.0))
        self.assertAlmostEqual(floored.expected, 6.6)
        self.assertIn('wider than the 5% band', floored.detail[DATA_ONLY])
        exact = self.single(entry, '120', '126', token)
        self.assertEqual(exact.status, 'ok')
        self.assertNotIn(DATA_ONLY, exact.detail)
        wide = self.single(entry, '1320', '1385', token)
        self.assertEqual(wide.status, 'ok')
        self.assertNotIn(DATA_ONLY, wide.detail)
        missing = self.single(entry, '132', '132', token)
        self.assertEqual(missing.status, 'alert')
        self.assertNotIn(DATA_ONLY, missing.detail)

    def test_a_run_speed_rate_delta_takes_the_hundredth_point_floor_in_rate_units(self):
        entry = passive_expectation(712466, 0, 'run_speed_rate', 'scale', '$s1', 20.0)
        token = [Displayed('$s1', 20.0, 0, 'percent')]
        stated = self.single(entry, '1', '1.2000000476837158', token)
        self.assertEqual(stated.status, 'ok')
        self.assertAlmostEqual(stated.high - stated.expected, 1e-4)
        self.assertNotIn(DATA_ONLY, stated.detail)
        self.assertEqual(self.single(entry, '1', '1.1900000572204590', token).status, 'alert')
        self.assertEqual(self.single(entry, '1', '1', token).status, 'alert')

    def test_run_speed_rate_readings_of_ten_and_twenty_percent_are_judged_alike(self):
        token = {10.0: [Displayed('$s1', 10.0, 0, 'percent')], 20.0: [Displayed('$s1', 20.0, 0, 'percent')]}
        readings = {10.0: '1.1000000238418579', 20.0: '1.2000000476837158'}
        for percent, reading in readings.items():
            with self.subTest(percent=percent):
                entry = passive_expectation(707754, 0, 'run_speed_rate', 'scale', '$s1', percent)
                verdict = self.single(entry, '1', reading, token[percent])
                self.assertEqual(verdict.status, 'ok')
                self.assertNotIn(DATA_ONLY, verdict.detail)

    def test_exact_stat_reading_judges_a_sub_point_delta(self):
        entry = passive_expectation(BELLS_OF_LIGHT, 2, 'stat', 'scale', '$s1', 3.0, fields={'stat': 3}, exact=True)
        token = [Displayed('$s1', 3.0, 0, 'percent')]
        genuine = [assert_step(entry.model['exact_before_label'], '32'),
                  assert_step(entry.model['exact_after_label'], '32.96')]
        verdict = self.passive_run(entry.rank_id, {entry: ('32', '32')}, token, extra_steps=genuine)[entry.label]
        self.assertEqual(verdict.status, 'ok')
        self.assertAlmostEqual(verdict.measured, 0.96)
        self.assertIn('the integer stat the game uses read 32 before and 32 after', verdict.detail[DATA_ONLY])
        absent = [assert_step(entry.model['exact_before_label'], '32'),
                 assert_step(entry.model['exact_after_label'], '32')]
        missing = self.passive_run(entry.rank_id, {entry: ('32', '32')}, token, extra_steps=absent)[entry.label]
        self.assertEqual(missing.status, 'alert')

    def test_damage_versus_an_established_aura_state_is_judged(self):
        entry = passive_expectation(PIOUS_SWEEP, 0, 'spell_damage_done', 'ratio', '$s1', 25.0, 572027,
                                    fields={'target': 'dummy'}, aura_state=True)
        fields = {(PIOUS_SWEEP, 'EffectApplyAuraName[0]'): 303, (PIOUS_SWEEP, 'EffectMiscValue[0]'): 23}
        token = [Displayed('$s1', 25.0, 0, 'percent')]
        established = [assert_step(entry.model['aura_state_label'], '1')]
        ok = self.passive_run(entry.rank_id, {entry: ('800', '1000')}, token, fields=fields,
                              extra_steps=established)[entry.label]
        self.assertEqual(ok.status, 'ok')
        missing_bonus = self.passive_run(entry.rank_id, {entry: ('800', '800')}, token, fields=fields,
                                         extra_steps=established)[entry.label]
        self.assertEqual(missing_bonus.status, 'alert')

    def test_damage_versus_an_unestablished_aura_state_is_unmeasured_with_a_sharper_reason(self):
        entry = passive_expectation(PIOUS_SWEEP, 0, 'spell_damage_done', 'ratio', '$s1', 25.0, 572027,
                                    fields={'target': 'dummy'}, aura_state=True)
        fields = {(PIOUS_SWEEP, 'EffectApplyAuraName[0]'): 303, (PIOUS_SWEEP, 'EffectMiscValue[0]'): 23}
        token = [Displayed('$s1', 25.0, 0, 'percent')]
        unestablished = [assert_step(entry.model['aura_state_label'], '0')]
        verdict = self.passive_run(entry.rank_id, {entry: ('800', '800')}, token, fields=fields,
                                   extra_steps=unestablished)[entry.label]
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('is not set on the dummy', verdict.explanation)

    def test_a_namesake_without_a_change_shows_nothing(self):
        moving, still = (
            passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'scale', '$s1', 100.0, target, True, False,
                                fields={'effect': 0})
            for target in (ZEALOTRY, ZEALOTRY_PASSIVE))
        names = {(ZEALOTRY, 'SpellName[enUS]'): 'Zealotry', (ZEALOTRY_PASSIVE, 'SpellName[enUS]'): 'Zealotry'}
        verdicts = self.passive_run(HOLY_UPHEAVAL, {moving: ('0', '0'), still: ('10', '10')},
                                    [Displayed('$s1', 100.0, 0, 'percent')], fields=names)
        self.assertEqual(verdicts[moving.label].status, 'unmeasured')
        self.assertEqual(verdicts[still.label].status, 'alert')

    def test_zero_delta_is_never_ok(self):
        entry = passive_expectation(HOLY_EDGE, 0, 'spell_modifier', 'spell_mod_flat', '$s1', 1.0, SCARLET_HAMMER,
                                    named=True, in_mask=True, fields={'op': 17, 'base': 1000})
        token = [Displayed('$s1', 1.0, 0, 'flat')]
        self.assertEqual(self.single(entry, '1000', '1000', token).status, 'alert')
        self.assertEqual(self.single(entry, '1000', '1001', token).status, 'ok')

    def test_zero_delta_outside_the_mask_is_never_ok(self):
        outside = passive_expectation(HOLY_EDGE, 0, 'spell_modifier', 'spell_mod_flat', '$s1', 1.0, SCOURGEBANE_PASSIVE,
                                      named=True, in_mask=False, fields={'op': 17, 'base': 1000})
        verdict = self.single(outside, '1000', '1000', [Displayed('$s1', 1.0, 0, 'flat')])
        self.assertEqual(verdict.status, 'alert')

    def test_scale_of_a_zero_before_value_is_unmeasured(self):
        entry = passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'scale', '$s1', 100.0, ZEALOTRY,
                                    named=True, in_mask=True, fields={'effect': 0})
        verdict = self.single(entry, '0', '0', [Displayed('$s1', 100.0, 0, 'percent')])
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('multiplies the before value 0', verdict.explanation)

    def test_scale_of_a_zero_before_value_on_a_named_target_stays_unmeasured(self):
        entry = passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'scale', '$s1', 100.0, ZEALOTRY,
                                    named=True, in_mask=True, fields={'effect': 0})
        verdict = self.single(entry, '0', '0', [Displayed('$s1', 100.0, 0, 'percent')])
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('multiplies the before value 0', verdict.explanation)

    def test_scale_of_a_zero_before_value_on_a_collateral_mask_target_is_measured_not_judged(self):
        moving, collateral = (
            passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'scale', '$s1', 100.0, target, named,
                                True, fields={'effect': 0})
            for target, named in ((ZEALOTRY, True), (RECKONING, False)))
        token = [Displayed('$s1', 100.0, 0, 'percent')]
        verdicts = self.passive_run(HOLY_UPHEAVAL, {moving: ('100', '200'), collateral: ('0', '0')}, token)
        self.assertEqual(verdicts[moving.label].status, 'ok')
        self.assertEqual(verdicts[collateral.label].status, 'measured')
        self.assertIn('reported, not judged', verdicts[collateral.label].explanation)

    def test_zero_before_collateral_target_without_a_moving_sibling_can_still_alert(self):
        collateral = passive_expectation(HOLY_UPHEAVAL, 0, 'spell_effect_value', 'scale', '$s1', 100.0,
                                         RECKONING, named=False, in_mask=True, fields={'effect': 0})
        verdict = self.single(collateral, '0', '50', [Displayed('$s1', 100.0, 0, 'percent')])
        self.assertEqual(verdict.status, 'alert')

    def test_parry_without_parry_before_the_learn_is_unmeasured(self):
        entry = passive_expectation(JUDICATOR, 0, 'parry_chance', 'add', '$s1', 3.0)
        verdict = self.single(entry, '0', '8', [Displayed('$s1', 3.0, 0, 'percent')])
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('cannot parry', verdict.explanation)
        self.assertEqual(self.single(entry, '5', '8', [Displayed('$s1', 3.0, 0, 'percent')]).status, 'ok')

    def test_two_scale_effects_on_one_quantity_are_judged_together(self):
        party, own = (passive_expectation(CALL_OF_THE_MONASTERY, effect, 'attack_power', 'scale', '$s1', 5.0)
                      for effect in (0, 2))
        token = [Displayed('$s1', 5.0, 0, 'percent')]
        verdicts = self.passive_run(CALL_OF_THE_MONASTERY, {party: ('313', '345.0825'), own: ('313', '345.0825')},
                                    token)
        for entry in (party, own):
            self.assertEqual(verdicts[entry.label].status, 'ok')
            self.assertAlmostEqual(verdicts[entry.label].expected, 313 * 1.05 * 1.05 - 313)
            self.assertIn('also holds effect', verdicts[entry.label].explanation)
        verdicts = self.passive_run(CALL_OF_THE_MONASTERY, {party: ('313', '328.65'), own: ('313', '328.65')}, token)
        self.assertEqual({verdicts[entry.label].status for entry in (party, own)}, {'alert'})

    def test_add_and_share_effects_on_one_quantity_sum(self):
        flat = passive_expectation(PARAGON, 0, 'stat', 'add', '$s1', 10.0, fields={'stat': 2})
        share = passive_expectation(PARAGON, 1, 'stat', 'share', '$s1', 10.0, source_label='stat 1',
                                    fields={'stat': 2})
        verdicts = self.passive_run(PARAGON, {flat: ('79', '102'), share: ('79', '102')},
                                    [Displayed('$s1', 10.0, 0, 'percent')])
        for entry in (flat, share):
            self.assertEqual((verdicts[entry.label].status, verdicts[entry.label].expected), ('ok', 23.2))

    def test_absent_passive_aura_is_unmeasured(self):
        entries = [passive_expectation(PIOUS, 0, 'stat', 'scale', '$s1', 5.0, fields={'stat': stat})
                   for stat in range(5)]
        fields = {(PIOUS, 'EquippedItemClass'): -1, (PIOUS, 'Stances'): 0, (PIOUS, 'CasterAuraSpell'): 0}
        verdicts = self.passive_run(PIOUS, {entry: ('81', '81') for entry in entries},
                                    [Displayed('$s1', 5.0, 0, 'percent')], aura='0', fields=fields)
        self.assertEqual({verdicts[entry.label].status for entry in entries}, {'unmeasured'})
        for entry in entries:
            self.assertIn('passive aura 706431 absent after learn', verdicts[entry.label].explanation)
            self.assertIn('EquippedItemClass -1', verdicts[entry.label].explanation)

    def test_crit_damage_direct_aura_gives_only_the_whole_reading(self):
        entry = passive_expectation(CHIVALRIC, 0, 'spell_critical_damage', 'crit_damage', '$s1', 15.0, RECKONING,
                                    fields={'target': 'dummy'}, aura=163)
        verdict = self.single(entry, '2000', '2300', [Displayed('$s1', 15.0, 0, 'percent')], name='Chivalric')
        self.assertEqual((verdict.status, verdict.expected), ('ok', 300.0))
        alert = self.single(entry, '2000', '2150', [Displayed('$s1', 15.0, 0, 'percent')], name='Chivalric')
        self.assertEqual(alert.status, 'alert')

    def test_crit_damage_spell_modifier_consumer_gives_only_the_bonus_reading(self):
        entry = passive_expectation(UPHEAVE, 0, 'spell_critical_damage', 'crit_damage', '$s1', 20.0, RECKONING,
                                    named=True, in_mask=True, fields={'target': 'dummy'}, aura=108)
        verdict = self.single(entry, '2000', '2200', [Displayed('$s1', 20.0, 0, 'percent')], name='Upheave!')
        self.assertEqual((verdict.status, verdict.expected), ('ok', 200.0))
        alert = self.single(entry, '2000', '2300', [Displayed('$s1', 20.0, 0, 'percent')], name='Upheave!')
        self.assertEqual(alert.status, 'alert')

    def test_composition_with_a_known_modifier_of_the_same_aura_is_ambiguous(self):
        entry = passive_expectation(SERENDIPITY, 0, 'spell_damage_done', 'composition', '$s1', 3.0, RECKONING,
                                    fields={'target': 'dummy'}, aura=79)
        same_aura = {**asdict(CLASS_TUNING), 'aura': 79, 'base_points': -1, 'real_points_per_level': -0.4}
        verdict = self.single(entry, '800', '824', [Displayed('$s1', 3.0, 0, 'percent')], name='Serendipity',
                              fields={(RECKONING, 'Effect[0]'): 2}, points={(RECKONING, 0): (165, 49)},
                              known_modifiers=[same_aura])
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        readings = verdict.detail['question']['readings']
        self.assertEqual([(reading['name'], reading['status']) for reading in readings],
                         [('multiplies', 'ok'), ('adds', 'alert')])
        self.assertAlmostEqual(readings[0]['expected'], 824.0)
        self.assertAlmostEqual(readings[1]['expected'], 830.0)
        self.assertIn('887007 (-20% damage)', readings[1]['meaning'])
        self.assertIn('887007 (-20% damage)', verdict.detail['question']['conditions'])

    def test_composition_with_a_known_modifier_of_a_different_aura_is_unambiguous(self):
        entry = passive_expectation(SERENDIPITY, 0, 'spell_damage_done', 'composition', '$s1', 3.0, RECKONING,
                                    fields={'target': 'dummy'}, aura=79)
        verdict = self.single(entry, '800', '824', [Displayed('$s1', 3.0, 0, 'percent')], name='Serendipity',
                              fields={(RECKONING, 'Effect[0]'): 2}, points={(RECKONING, 0): (165, 49)})
        self.assertEqual((verdict.status, verdict.expected), ('ok', 24.0))
        alert = self.single(entry, '800', '830', [Displayed('$s1', 3.0, 0, 'percent')], name='Serendipity',
                            fields={(RECKONING, 'Effect[0]'): 2}, points={(RECKONING, 0): (165, 49)})
        self.assertEqual(alert.status, 'alert')

    def test_composition_without_the_known_aura_has_one_reading(self):
        entry = passive_expectation(SERENDIPITY, 0, 'spell_damage_done', 'composition', '$s1', 3.0, RECKONING,
                                    fields={'target': 'dummy'}, aura=79)
        verdict = self.single(entry, '1000', '1030', [Displayed('$s1', 3.0, 0, 'percent')],
                              **{'known_aura 887007': '0'})
        self.assertEqual((verdict.status, verdict.detail), ('ok', {'metric': 'spell_damage_done'}))

    def test_share_uses_the_measured_source(self):
        entry = passive_expectation(GRACEFUL_FIGHTER, 0, 'combat_rating', 'share', '$s1', 20.0,
                                    source_label='stat 1', fields={'rating': 3})
        token = [Displayed('$s1', 20.0, 0, 'percent')]
        verdict = self.single(entry, '0', '26', token)
        self.assertEqual((verdict.status, verdict.expected), ('ok', 26.4))
        moved = self.single(entry, '0', '26', token, **{'stat 1': '150'})
        self.assertEqual((moved.status, moved.expected), ('alert', 30.0))

    def test_share_against_an_item_armor_subclass_reference_bands_by_deviation(self):
        source_label = f'{BLESSED_PADDING} e0 item_armor_by_subclass 3'
        entry = passive_expectation(BLESSED_PADDING, 0, 'armor', 'share', '$s1', 50.0,
                                    source_label=source_label, fields={})
        token = [Displayed('$s1', 50.0, 0, 'percent')]
        ok = self.single(entry, '5000', '5802', token, **{source_label: '1604'})
        self.assertEqual((ok.status, ok.expected), ('ok', 802.0))
        one_above = self.single(entry, '5000', '5803', token, **{source_label: '1604'})
        self.assertEqual((one_above.status, one_above.high), ('alert', 802.0))
        alert = self.single(entry, '5000', '5850', token, **{source_label: '1604'})
        self.assertEqual((alert.status, alert.expected), ('alert', 802.0))

    def test_seeded_stat_reading_off_by_more_than_its_rounding_is_an_alert(self):
        source_label = f'{BLESSED_PADDING} e0 item_armor_by_subclass 3'
        entry = passive_expectation(BLESSED_PADDING, 0, 'armor', 'share', '$s1', 50.0,
                                    source_label=source_label, fields={})
        token = [Displayed('$s1', 50.0, 0, 'percent')]
        inside_the_old_relative_margin = self.single(entry, '5000', '5805', token, **{source_label: '1604'})
        inside_the_old_tolerated_tier = self.single(entry, '5000', '5834', token, **{source_label: '1604'})
        self.assertEqual(inside_the_old_relative_margin.status, 'alert')
        self.assertEqual(inside_the_old_tolerated_tier.status, 'alert')
        self.assertIn('as the engine truncates the armor reading', inside_the_old_tolerated_tier.explanation)
        self.assertEqual(banded_status(834.0, 802.0 - 4.01, 802.0 + 4.01, 802.0), 'tolerated')

    def sturdy_energy(self, before, after):
        entry = passive_expectation(STURDY, 1, 'max_power', 'scale', '$s1', 5.0, fields={'power': 3})
        return self.single(entry, before, after, [Displayed('$s1', 5.0, 1, 'percent')], name='Sturdy')

    def test_seeded_one_below_reproduced_by_the_float_emulation_is_known_engine_rounding(self):
        verdict = self.sturdy_energy('100', '104')
        self.assertEqual((verdict.status, verdict.measured, verdict.expected), ('ok', 4.0, 5.0))
        self.assertEqual(verdict.detail[ENGINE_ROUNDING], 104.99999237060547)
        self.assertIn('known engine rounding', verdict.explanation)
        self.assertIn('also follows from +4%', verdict.detail[DATA_ONLY])
        separated = self.sturdy_energy('120', '125')
        self.assertEqual((separated.status, separated.detail[ENGINE_ROUNDING]), ('ok', 125.99999237060547))
        self.assertNotIn(DATA_ONLY, separated.detail)

    def test_seeded_four_percent_mutant_one_below_an_exact_float_result_is_an_alert(self):
        verdict = self.sturdy_energy('80', '83')
        self.assertEqual((verdict.status, verdict.expected), ('alert', 4.0))
        self.assertNotIn(ENGINE_ROUNDING, verdict.detail)
        self.assertEqual(self.sturdy_energy('80', '84').status, 'ok')

    def test_seeded_one_above_or_two_below_a_percent_derived_stat_is_an_alert(self):
        for after in ('106', '103'):
            verdict = self.sturdy_energy('100', after)
            self.assertEqual(verdict.status, 'alert')
            self.assertNotIn(ENGINE_ROUNDING, verdict.detail)
        self.assertEqual(self.sturdy_energy('100', '105').status, 'ok')

    def test_seeded_one_below_on_a_metric_outside_the_percent_path_never_takes_the_engine_rounding(self):
        damage = passive_expectation(SERENDIPITY, 0, 'weapon_damage_min', 'ratio', '$s1', 5.0, fields={'hand': 0})
        dealt = self.single(damage, '100', '104', [Displayed('$s1', 5.0, 0, 'percent')])
        self.assertEqual(dealt.status, 'alert')
        self.assertNotIn(ENGINE_ROUNDING, dealt.detail)
        power = passive_expectation(CALL_OF_THE_MONASTERY, 0, 'attack_power', 'scale', '$s1', 5.0)
        attack = self.single(power, '100', '104', [Displayed('$s1', 5.0, 0, 'percent')])
        self.assertNotIn(ENGINE_ROUNDING, attack.detail)
        self.assertIn('the rounding of a deterministic attack_power reading', attack.explanation)

    def test_shared_token_takes_the_sign_of_the_effect_points(self):
        entry = passive_expectation(PALADIN_TRAINING, 1, 'spell_power_cost', 'scale', '$s1', -20.0, 570233,
                                    named=True, in_mask=True)
        verdict = self.single(entry, '40', '32', [Displayed('$s1', 20.0, 0, 'percent')])
        self.assertEqual((verdict.status, verdict.expected), ('ok', -8.0))

    def test_unjudged_plan_is_measured(self):
        entry = passive_expectation(AGGRAMARS_RAGE, 0, 'spell_crit_chance', 'add', '$s1', 6.0, judged=False,
                                    fields={'school': 2})
        verdict = self.single(entry, '2.8592', '2.8592', [Displayed('$s1', 6.0, 0, 'percent')])
        self.assertEqual((verdict.status, verdict.measured), ('measured', 0.0))

    def test_damage_versus_an_aura_state_the_scenario_does_not_establish_is_unmeasured(self):
        entry = passive_expectation(PIOUS_SWEEP, 0, 'spell_damage_done', 'ratio', '$s1', 25.0, 572027,
                                    fields={'target': 'dummy'})
        fields = {(PIOUS_SWEEP, 'EffectApplyAuraName[0]'): 303, (PIOUS_SWEEP, 'EffectMiscValue[0]'): 23}
        verdict = self.single(entry, '800', '800', [Displayed('$s1', 25.0, 0, 'percent')], fields=fields)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('aura state 23', verdict.explanation)

    def test_token_missing_from_the_measured_reading_is_an_alert(self):
        entry = passive_expectation(SOLEMN_SOLDIER, 0, 'attack_time_ms', 'haste', '$s1', 10.0, fields={'hand': 0})
        verdict = self.single(entry, '2500', '2272.73', [Displayed('$s2', 10.0, 1, 'flat')])
        self.assertEqual(verdict.status, 'alert')
        self.assertIn('$s1', verdict.explanation)

    def test_missing_after_measurement_is_an_alert(self):
        entry = passive_expectation(SOLEMN_SOLDIER, 0, 'attack_time_ms', 'haste', '$s1', 10.0, fields={'hand': 0})
        verdicts = self.passive_run(SOLEMN_SOLDIER, {entry: (None, None)}, [Displayed('$s1', 10.0, 0, 'percent')])
        self.assertEqual(verdicts[entry.label].status, 'alert')

    @unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
    def test_report_counts_passive_verdicts_per_family(self):
        entry = passive_expectation(SOLEMN_SOLDIER, 0, 'attack_time_ms', 'haste', '$s1', 10.0, fields={'hand': 0})
        unmodelled = Expectation(f'{SOLEMN_SOLDIER} e2', 'unmodelled', SOLEMN_SOLDIER, SOLEMN_SOLDIER, 2, '',
                                 'unmodelled: scripted or crowd-control effect', {'family': 'P6', 'effect': 2})
        self.workspace.scenario('conformance-templar-passive-572555', 'passive', [entry, unmodelled], [],
                                [assert_step(entry.model['before_label'], '2500'),
                                 assert_step(entry.model['aura_label'], '1'),
                                 assert_step(entry.model['after_label'], '2272.73')],
                                spell=SOLEMN_SOLDIER, name='Solemn Soldier', rank=SOLEMN_SOLDIER)
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=FakeTooltips([Displayed('$s1', 10.0, 0, 'percent')]),
                           hit_model=reference_hit)
        out = self.workspace.root / 'report'
        write_outputs(manifest, results, verdicts, out)
        report = (out / 'report.md').read_text(encoding='utf-8')
        self.assertIn('## Passives', report)
        self.assertRegex(report, r'\| P2 \| 1 \| 0 \| 0 \| 0 \| 0 \| 0 \| 0 \| 0 \| 0 \| 0 \|')
        self.assertRegex(report, r'\| P6 \| 0 \| 0 \| 0 \| 0 \| 1 \| 0 \| 0 \| 0 \| 0 \| 0 \|')


class QuestionDetailTest(unittest.TestCase):
    def test_question_detail_keeps_the_readings_and_the_measurement(self):
        readings = [{'name': 'whole', 'expected': 2300.0, 'status': 'ok'}]
        self.assertEqual(question_detail('readings', 'Which?', readings, 2300.0),
                         {'kind': 'readings', 'question': 'Which?', 'readings': readings, 'measured': 2300.0})

    def test_percent_point_metrics_take_the_hundredth_floor(self):
        self.assertEqual(delta_margin('melee_crit_chance_refreshed', 1.0), 0.01)
        self.assertEqual(delta_margin('attack_time_ms', 1.0), 1.0)
        self.assertEqual(delta_margin('weapon_damage_min', 1.87), 0.01)
        self.assertEqual(delta_margin('spell_modifier', -30000.0), 150.0)
        self.assertEqual(delta_margin('armor', 1631.0), 1.0)
        self.assertEqual(delta_margin('spell_crit_chance', 600.0), 0.01)
        self.assertAlmostEqual(delta_margin('run_speed_rate', 0.2), 1e-4)
        self.assertAlmostEqual(delta_margin('run_speed_rate', 2.4), 1e-4)
        self.assertEqual(PERCENT_POINT_METRICS, frozenset({'melee_crit_chance', 'melee_crit_chance_refreshed',
                                                           'spell_crit_chance', 'melee_hit_chance', 'spell_hit_chance',
                                                           'parry_chance', 'dodge_chance', 'spell_done_crit_chance'}))


class OwnerFallbackTest(unittest.TestCase):
    def test_a_single_status_passes_through_untouched(self):
        self.assertEqual(owner_fallback({'ok'}, None), 'ok')
        self.assertEqual(owner_fallback({'alert'}, 'coa-history query: none'), 'alert')

    def test_disagreeing_readings_without_a_recorded_log_query_stay_ambiguous(self):
        self.assertEqual(owner_fallback({'ok', 'alert'}, None), 'ambiguous_tooltip')
        self.assertEqual(owner_fallback({'ok', 'alert'}, ''), 'ambiguous_tooltip')

    def test_disagreeing_readings_with_a_recorded_log_query_settle_on_the_reading_applied(self):
        self.assertEqual(owner_fallback({'ok', 'alert'}, 'coa-history query: none'), 'ok')

    def test_a_recorded_log_query_alerts_when_the_server_applies_neither_reading(self):
        self.assertEqual(owner_fallback({'alert', 'unmeasured'}, 'coa-history query: none'), 'alert')

    def test_log_query_of_reads_the_class_files_log_queries_dict(self):
        manifest = {'class_file': {'log_queries': {'706325 proc_rate': 'coa-history query: none'}}}
        self.assertEqual(log_query_of(manifest, '706325 proc_rate'), 'coa-history query: none')
        self.assertIsNone(log_query_of(manifest, 'unregistered label'))
        self.assertIsNone(log_query_of({'class_file': {}}, '706325 proc_rate'))


class BandedStatusTest(unittest.TestCase):
    def test_inside_the_band_is_ok(self):
        self.assertEqual(banded_status(1002.0, 995.0, 1005.0, 1000.0), 'ok')

    def test_a_four_percent_deviation_outside_the_band_is_tolerated(self):
        self.assertEqual(banded_status(1040.0, 995.0, 1005.0, 1000.0), 'tolerated')

    def test_a_six_percent_deviation_is_still_an_alert(self):
        self.assertEqual(banded_status(1060.0, 995.0, 1005.0, 1000.0), 'alert')

    def test_exactly_five_percent_is_tolerated_not_an_alert(self):
        self.assertEqual(banded_status(1050.0, 995.0, 1005.0, 1000.0), 'tolerated')

    def test_a_zero_expected_value_never_tolerates_a_nonzero_measurement(self):
        self.assertEqual(banded_status(1.0, 0.0, 0.0, 0.0), 'alert')


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

    def test_literal_token_entries_are_read_alongside_the_dollar_tokens(self):
        tooltips = DbcTooltips(DBC_DIR, CLASS_FILE)
        caster = CasterStats(level=60, ap=100.0, rap=0.0, sp_by_school={school: 0.0 for school in range(1, 7)},
                             stats={stat: 0.0 for stat in range(5)})
        values = tooltips.read(FINAL_PRAYER, caster).values
        literal = next(value for value in values if value.text == 'Doubles the healing done to you')
        self.assertEqual((literal.value, literal.effect_index), (100.0, 0))

    def test_effect_override_base_points_replace_the_spell_dbc_points_of_patience(self):
        override = {'spell': PATIENCE, 'effect': 1, 'base_points': 4999, 'citation': 'contract'}
        rewritten = {'effect_overrides': [override]}
        self.assertEqual(DbcTooltips(DBC_DIR).effect_points(PATIENCE, 1), (-5001, 1))
        self.assertEqual(DbcTooltips(DBC_DIR, rewritten).effect_points(PATIENCE, 1), (4999, 1))
        self.assertEqual(DbcTooltips(DBC_DIR, rewritten).effect_points(PATIENCE, 0), (1999, 1))

    def test_literal_token_entries_are_absent_for_a_spell_without_one(self):
        tooltips = DbcTooltips(DBC_DIR, CLASS_FILE)
        caster = CasterStats(level=60, ap=100.0, rap=0.0, sp_by_school={school: 0.0 for school in range(1, 7)},
                             stats={stat: 0.0 for stat in range(5)})
        values = tooltips.read(RIGHTEOUS_UPHEAVAL, caster).values
        self.assertFalse(any(value.text == 'Doubles the healing done to you' for value in values))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GeneratedTokenTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spells = {spell.spell_id: spell for spell in class_spells(DBC_DIR, CLASS_FILE['class_id'], HEADER)}
        cls.tooltips = DbcTooltips(DBC_DIR)

    def setUp(self):
        self.workspace = Workspace()

    def tearDown(self):
        self.workspace.close()

    def judged(self, spell_id, displayed, actual, hooks='0'):
        self.workspace.close()
        self.workspace = Workspace()
        spell = self.spells[spell_id]
        scenario, expectations, _ = value_scenario(CLASS_FILE, spell, spell_id)
        item = next(item for item in expectations if item.displayed == displayed)
        tokens = [value.text for value in read_tooltip(self.tooltips.dbc, spell_id, structure_stats(CLASS_FILE)).values]
        self.workspace.scenario(f'conformance-templar-value-{spell_id}', 'value', expectations, tokens,
                                [assert_step(item.label, actual)], spell=spell_id, name=spell.name, rank=spell_id,
                                hooks=hooks)
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=self.tooltips, hit_model=reference_hit)
        return next(verdict for verdict in verdicts if verdict.label == item.label)

    def test_own_seconds_token_is_judged_in_ms(self):
        verdict = self.judged(LIBERTY, '$/1000;s1', '-30000')
        self.assertEqual((verdict.status, verdict.expected), ('ok', -30000.0))
        self.assertEqual(self.judged(LIBERTY, '$/1000;s1', '-30').status, 'alert')

    def test_foreign_value_token_is_judged_against_the_referenced_spell(self):
        verdict = self.judged(SCOURGEBANE, '$801832s2', '50')
        self.assertEqual((verdict.status, verdict.expected), ('ok', 50.0))
        self.assertEqual(self.judged(SCOURGEBANE, '$801832s2', '5').status, 'alert')

    def test_foreign_level_scaled_token_disabled_by_a_server_correction_is_unmodelled(self):
        stamina = float(BASE_ACTUALS['stat 2'])
        verdict = self.judged(STAFFGUARD, STAFFGUARD_TOKEN, str(STAFFGUARD_HEALTH_AT_RANK_ZERO + 0.3 * stamina))
        self.assertEqual(verdict.status, 'unmodelled')
        self.assertIn('disabled by a server correction', verdict.explanation)
        self.assertEqual(self.judged(STAFFGUARD, STAFFGUARD_TOKEN,
                                     str(STAFFGUARD_HEALTH_AT_LEVEL_60 + 0.3 * stamina)).status, 'unmodelled')

    def test_foreign_stack_token_is_judged_exactly(self):
        verdict = self.judged(IRON_PENANCE, '$523713u', '10')
        self.assertEqual((verdict.status, verdict.expected, verdict.low, verdict.high), ('ok', 10.0, 10.0, 10.0))
        self.assertEqual(self.judged(IRON_PENANCE, '$523713u', '11').status, 'alert')

    def test_expanded_token_is_judged_against_the_referenced_spell(self):
        verdict = self.judged(ZEALOTRY_PASSIVE, '$s2', '80')
        self.assertEqual((verdict.status, verdict.expected), ('ok', 80.0))
        self.assertEqual(self.judged(ZEALOTRY_PASSIVE, '$s2', '8').status, 'alert')

    def test_foreign_duration_token_is_judged_against_the_referenced_duration(self):
        verdict = self.judged(KEEPING_THE_OATH, '$803237d', '8000')
        self.assertEqual((verdict.check, verdict.status, verdict.expected), ('spell_duration', 'ok', 8000.0))
        self.assertIn('before script hooks', verdict.detail['scope'])
        self.assertIn('OnCalcMaxDuration', verdict.detail['scope'])
        self.assertEqual(self.judged(KEEPING_THE_OATH, '$803237d', '8040').status, 'ok')
        self.assertEqual(self.judged(KEEPING_THE_OATH, '$803237d', '8041').status, 'tolerated')
        self.assertEqual(self.judged(KEEPING_THE_OATH, '$803237d', '9000').status, 'alert')


def fixture_generate(class_id: int, out: Path, **options) -> Path:
    from conformance import generate
    with mock.patch('conformance.load_class_file', load_fixture_class_file):
        return generate(class_id, out, **options)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GenerateTest(unittest.TestCase):
    def test_manifest_hashes_and_keys_match_what_the_runner_records(self):
        out = Path(tempfile.mkdtemp(prefix='conformance-generate-'))
        try:
            manifest_path = fixture_generate(CLASS_FILE['class_id'], out, spells=[804929])
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

    def test_long_hit_is_written_in_parts_that_share_its_label(self):
        out = Path(tempfile.mkdtemp(prefix='conformance-generate-'))
        try:
            manifest = json.loads(fixture_generate(CLASS_FILE['class_id'], out, spells=[RIGHTEOUS_UPHEAVAL]).read_text(
                encoding='utf-8'))
            hits = [entry for entry in manifest['scenarios'] if entry['kind'] == 'hit']
            self.assertEqual([entry['key'] for entry in hits],
                             ['conformance-templar-hit-572027-part-1', 'conformance-templar-hit-572027-part-2'])
            for entry in hits:
                self.assertTrue(entry['file'])
                self.assertIn('572027 hit_mean', [item['label'] for item in entry['expectations']
                                                  if item['check'] == 'hit_mean'])
        finally:
            shutil.rmtree(out)


SUPERSEDING = ['572027 hit_mean gate stacks 0', '572027 hit_mean gate']
SUPERSEDED_ENTRY = {'spell': 572027, 'reason': 'seeded: its hits land on the debuff it applies',
                    'replaced_by': SUPERSEDING, 'ruling': 'seeded mentor decision D-1'}


def superseded_generate(out: Path, entries) -> dict:
    from conformance import generate

    def listed(class_id):
        return {**load_fixture_class_file(class_id), 'superseded_hits': entries}

    with mock.patch('conformance.load_class_file', listed):
        return json.loads(generate(CLASS_FILE['class_id'], out, spells=[RIGHTEOUS_UPHEAVAL]).read_text(
            encoding='utf-8'))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class SupersededHitTest(unittest.TestCase):
    def test_a_superseded_hit_is_a_closed_record_without_a_scenario_naming_its_replacements(self):
        out = Path(tempfile.mkdtemp(prefix='conformance-superseded-'))
        try:
            manifest = superseded_generate(out, [SUPERSEDED_ENTRY])
            [entry] = [entry for entry in manifest['scenarios'] if entry['kind'] == 'hit']
            [item] = entry['expectations']
            self.assertEqual((entry['key'], entry['file'], item['label'], item['check']),
                             ('conformance-templar-hit-572027', None, '572027 hit_mean', 'unmodelled'))
            self.assertEqual(item['rule'], 'closed: no check needed: seeded: its hits land on the debuff it applies')
            self.assertEqual(item['model'], {SUPERSEDED_BY: SUPERSEDING})
            verdict = judge_expectation(manifest, entry, None, Expectation(**item), None, None, None)
            self.assertEqual((verdict.status, verdict.detail), ('closed', {SUPERSEDED_BY: SUPERSEDING}))
        finally:
            shutil.rmtree(out)

    def test_mutant_without_the_key_the_plain_hit_is_generated_as_before(self):
        out = Path(tempfile.mkdtemp(prefix='conformance-superseded-'))
        try:
            manifest = superseded_generate(out, [])
            hits = [entry for entry in manifest['scenarios'] if entry['kind'] == 'hit']
            self.assertEqual([entry['key'] for entry in hits],
                             ['conformance-templar-hit-572027-part-1', 'conformance-templar-hit-572027-part-2'])
            self.assertTrue(all(entry['file'] for entry in hits))
        finally:
            shutil.rmtree(out)

    def test_an_entry_without_its_replacing_labels_is_refused(self):
        for broken in ({key: value for key, value in SUPERSEDED_ENTRY.items() if key != 'replaced_by'},
                       {**SUPERSEDED_ENTRY, 'replaced_by': []},
                       {**SUPERSEDED_ENTRY, 'replaced_by': ['572027 hit_mean']},
                       {**SUPERSEDED_ENTRY, 'reason': ' '},
                       {**SUPERSEDED_ENTRY, 'unknown_key': 1}):
            out = Path(tempfile.mkdtemp(prefix='conformance-superseded-'))
            try:
                with self.subTest(broken=sorted(broken)), self.assertRaises(ValueError):
                    superseded_generate(out, [broken])
            finally:
                shutil.rmtree(out)


    def test_mutant_a_class_other_than_27_without_a_mentor_ruling_is_refused(self):
        without = {key: value for key, value in SUPERSEDED_ENTRY.items() if key != 'ruling'}
        for broken in (without, {**SUPERSEDED_ENTRY, 'ruling': ''}, {**SUPERSEDED_ENTRY, 'ruling': 'the author says so'},
                       {**SUPERSEDED_ENTRY, 'ruling': 17}):
            out = Path(tempfile.mkdtemp(prefix='conformance-superseded-'))
            try:
                with self.subTest(ruling=broken.get('ruling')), self.assertRaisesRegex(ValueError, 'ruling'):
                    superseded_generate(out, [broken])
            finally:
                shutil.rmtree(out)

    def test_class_27_needs_no_ruling_and_a_ruling_is_accepted_elsewhere(self):
        from conformance import superseded_hit

        without = {key: value for key, value in SUPERSEDED_ENTRY.items() if key != 'ruling'}
        for class_id, entry in ((27, without), (27, SUPERSEDED_ENTRY), (23, SUPERSEDED_ENTRY)):
            with self.subTest(class_id=class_id, ruling='ruling' in entry):
                self.assertEqual(superseded_hit({'class_id': class_id, 'superseded_hits': [entry]}, 572027), entry)


class ResolveSupersededTest(unittest.TestCase):
    def closed(self):
        return Verdict('572027 hit_mean', 'closed', None, None, None, None, 'closed: no check needed: seeded',
                       check='unmodelled', detail={SUPERSEDED_BY: SUPERSEDING})

    def test_a_superseded_hit_stays_closed_only_with_every_replacement_ok(self):
        resolved = resolve_superseded([self.closed(), verdict(SUPERSEDING[0], 'ok'), verdict(SUPERSEDING[1], 'ok')])
        self.assertEqual(resolved[0].status, 'closed')
        self.assertIn(f'replaced by "{SUPERSEDING[0]}" (ok), "{SUPERSEDING[1]}" (ok)', resolved[0].explanation)

    def test_mutant_a_missing_replacement_alerts(self):
        resolved = resolve_superseded([self.closed(), verdict(SUPERSEDING[0], 'ok')])
        self.assertEqual(resolved[0].status, 'alert')
        self.assertIn(f'"{SUPERSEDING[1]}" (missing)', resolved[0].explanation)

    def test_mutant_an_alerting_or_unmeasured_replacement_alerts(self):
        for status in ('alert', 'unmeasured', 'tolerated'):
            with self.subTest(status=status):
                resolved = resolve_superseded([self.closed(), verdict(SUPERSEDING[0], status),
                                               verdict(SUPERSEDING[1], 'ok')])
                self.assertEqual(resolved[0].status, 'alert')

    def test_a_closed_verdict_without_replacements_is_left_alone(self):
        plain = Verdict('1 hit_mean', 'closed', None, None, None, None, 'closed: no check needed: x')
        self.assertEqual(resolve_superseded([plain]), [plain])


def verdict(label: str, status: str) -> Verdict:
    return Verdict(label, status, None, None, None, None, '')


def linked_verdict(label: str, reference: str, referenced_status: str) -> Verdict:
    explanation = (f'unmodelled: checked by triggers entry "Fixture Proc" '
                   f'(verdict "{reference}" (status {referenced_status}))')
    return Verdict(label, 'unmodelled', None, None, None, None, explanation, check='unmodelled')


class ResolveLinkedStatusesTest(unittest.TestCase):
    def test_a_link_to_a_conformant_live_verdict_becomes_closed_not_unmodelled(self):
        resolved = resolve_linked_statuses([linked_verdict('1 e0', '2 proc_rate', 'alert'),
                                            verdict('2 proc_rate', 'ok')])
        self.assertEqual(resolved[0].status, 'closed')
        self.assertIn('(status ok)', resolved[0].explanation)

    def test_a_link_to_an_alerting_live_verdict_stays_unmodelled_not_closed(self):
        resolved = resolve_linked_statuses([linked_verdict('1 e0', '2 proc_rate', 'ok'),
                                            verdict('2 proc_rate', 'alert')])
        self.assertEqual(resolved[0].status, 'unmodelled')
        self.assertIn('(status alert)', resolved[0].explanation)
        self.assertNotIn('(status ok)', resolved[0].explanation)

    def test_a_tolerated_live_verdict_also_counts_as_conformant(self):
        resolved = resolve_linked_statuses([linked_verdict('1 e0', '2 proc_rate', 'ok'),
                                            verdict('2 proc_rate', 'tolerated')])
        self.assertEqual(resolved[0].status, 'closed')

    def test_a_missing_referenced_label_leaves_the_row_unmodelled(self):
        resolved = resolve_linked_statuses([linked_verdict('1 e0', '2 proc_rate', 'ok')])
        self.assertEqual(resolved[0].status, 'unmodelled')
        self.assertIn('(status unmodelled)', resolved[0].explanation)

    def test_a_resolved_link_records_its_own_status_and_resolves_again_from_it(self):
        first = resolve_linked_statuses([linked_verdict('1 e0', '2 proc_rate', 'ok'), verdict('2 proc_rate', 'ok')])
        self.assertEqual((first[0].status, first[0].detail['linked_from']), ('closed', 'unmodelled'))
        again = resolve_linked_statuses([first[0], verdict('2 proc_rate', 'alert')], {'1 e0'})
        self.assertEqual((again[0].status, again[0].detail['linked_from']), ('unmodelled', 'unmodelled'))
        self.assertIn('(status alert)', again[0].explanation)
        self.assertEqual(resolve_linked_statuses([first[0], verdict('2 proc_rate', 'alert')], set())[0], first[0])

    def test_an_unrelated_verdict_passes_through_unchanged(self):
        plain = verdict('1 e0', 'ok')
        resolved = resolve_linked_statuses([plain])
        self.assertEqual(resolved[0], plain)


VALUE_LINKS = {'value_links': [{'label': '1 effect_value #1', 'checked_by': ['1 behaviour_metric_delta rate'],
                                 'arithmetic': '$h = ProcChance 5, the rate band 3%..7%'}]}


def value_verdict(status: str = 'unmodelled') -> Verdict:
    return Verdict('1 effect_value #1', status, None, None, None, None, 'unmeasurable: chance_pct token',
                   check='effect_value')


class ApplyValueLinksTest(unittest.TestCase):
    def linked(self, measuring_status: str, value_status: str = 'unmodelled') -> Verdict:
        verdicts = [value_verdict(value_status), verdict('1 behaviour_metric_delta rate', measuring_status)]
        return resolve_linked_statuses(apply_value_links(verdicts, VALUE_LINKS))[0]

    def test_a_passing_measuring_label_closes_the_linked_value_label(self):
        resolved = self.linked('ok')
        self.assertEqual(resolved.status, 'closed')
        self.assertIn('"1 behaviour_metric_delta rate" (status ok)', resolved.explanation)
        self.assertIn('ProcChance 5', resolved.explanation)

    def test_a_failing_measuring_label_fails_the_linked_value_label_with_it(self):
        resolved = self.linked('alert')
        self.assertEqual(resolved.status, 'alert')
        self.assertIn('(status alert)', resolved.explanation)

    def test_a_not_measured_hooked_value_label_follows_its_link(self):
        self.assertEqual(self.linked('ok', 'not_measured').status, 'closed')
        self.assertEqual(self.linked('alert', 'not_measured').status, 'alert')

    def test_an_ambiguous_sign_value_label_follows_its_link(self):
        self.assertEqual(self.linked('ok', 'ambiguous_tooltip').status, 'closed')
        self.assertEqual(self.linked('alert', 'ambiguous_tooltip').status, 'alert')

    def test_an_unlinked_ambiguous_value_label_keeps_its_status(self):
        verdicts = [replace(value_verdict('ambiguous_tooltip'), label='2 effect_value #1'),
                    verdict('1 behaviour_metric_delta rate', 'ok')]
        self.assertEqual(resolve_linked_statuses(apply_value_links(verdicts, VALUE_LINKS))[0].status,
                         'ambiguous_tooltip')

    def test_a_missing_measuring_label_leaves_the_value_label_unmodelled(self):
        resolved = resolve_linked_statuses(apply_value_links([value_verdict()], VALUE_LINKS))[0]
        self.assertEqual(resolved.status, 'unmodelled')

    def test_an_already_judged_value_label_is_not_relinked(self):
        verdicts = [value_verdict('ok'), verdict('1 behaviour_metric_delta rate', 'alert')]
        self.assertEqual(resolve_linked_statuses(apply_value_links(verdicts, VALUE_LINKS))[0].status, 'ok')

    def test_a_class_file_without_value_links_changes_nothing(self):
        verdicts = [value_verdict(), verdict('1 behaviour_metric_delta rate', 'ok')]
        self.assertEqual(apply_value_links(verdicts, {}), verdicts)


class ObservationLinesTest(unittest.TestCase):
    def test_empty_without_any_player_observations(self):
        self.assertEqual(observation_lines({}, []), [])

    def test_shows_the_current_status_of_the_corroborated_verdict(self):
        class_file = {'player_observations': [
            {'spell': 706325, 'name': 'Condemnation', 'date': '2026-11-07', 'citation': 'player report 2026-11-07',
             'claim': 'Zealotry procs on each damage tick, not once per cast.',
             'corroborates': '706325 proc_rate'}]}
        lines = observation_lines(class_file, [verdict('706325 proc_rate', 'ambiguous_tooltip')])
        self.assertIn('## Player observations', lines)
        row = next(line for line in lines if line.startswith('| 706325 |'))
        self.assertIn('706325 proc_rate', row)
        self.assertIn('ambiguous_tooltip', row)

    def test_a_corroborates_label_absent_from_this_run_is_reported_rather_than_silently_matched(self):
        class_file = {'player_observations': [
            {'spell': 92111, 'name': 'Scourgebane', 'date': '2026-11-07', 'citation': 'player report 2026-11-07',
             'claim': 'Argent Blade procs Scourgebane.', 'corroborates': '92111 proc_rate 804929'}]}
        lines = observation_lines(class_file, [verdict('92111 proc_rate', 'ambiguous_tooltip')])
        row = next(line for line in lines if line.startswith('| 92111 |'))
        self.assertIn('label not in this run', row)


class MagnitudeExcludedTest(unittest.TestCase):
    def test_two_parts_widen_the_band_by_the_half_width_of_their_mean(self):
        excluded, note = magnitude_excluded(0.475, 0.525, [0.49, 0.51, 0.50])
        self.assertLess(excluded[0], 0.475)
        self.assertGreater(excluded[1], 0.525)
        self.assertAlmostEqual(0.475 - excluded[0], excluded[1] - 0.525)
        self.assertIn('excludes a ratio below', note)

    def test_one_part_states_only_the_band(self):
        excluded, note = magnitude_excluded(0.475, 0.525, [0.5])
        self.assertIsNone(excluded)
        self.assertIn('1 part gives no sampling interval', note)


class ShareNeighbourTest(unittest.TestCase):
    def verdict(self, measured: float, expected: float) -> Verdict:
        return Verdict('1 e1 combat_rating 24', 'ok', measured, expected, expected - 1, expected + 1, '', 'key', 1, 1,
                       'passive_delta')

    def test_an_integer_share_a_one_percent_neighbour_also_explains_is_data(self):
        from types import SimpleNamespace
        from compare import share_neighbour_reason
        model = {'relation': 'share', 'source_label': 'stat 3'}
        small = share_neighbour_reason(self.verdict(16.0, 16.0), model, SimpleNamespace(values={'stat 3': 32.0}),
                                       'combat_rating')
        self.assertIn('+51%', small)
        large = share_neighbour_reason(self.verdict(150.0, 150.0), model, SimpleNamespace(values={'stat 3': 300.0}),
                                       'combat_rating')
        self.assertIsNone(large)
        scaled = share_neighbour_reason(self.verdict(16.0, 16.0), {'relation': 'scale'},
                                        SimpleNamespace(values={}), 'combat_rating')
        self.assertIsNone(scaled)


class EngineAmountBandTests(unittest.TestCase):
    STATED = {'bonus': 15, 'parts': [10], 'truncated': True, 'band': True}

    def reading(self, ratio: float, half_ratio: float) -> str:
        from bonus import Bonus
        from compare import engine_amount_band_reading
        found = Bonus((ratio - 1) * 100, half_ratio * 100, (1.11 / 1.10 - 1) * 100, 40)
        return engine_amount_band_reading(found, self.STATED).status

    def test_a_ratio_under_the_exact_step_is_inside_the_amount_band(self):
        self.assertEqual(self.reading(1.0082, 0.0008), 'ok')
        self.assertEqual(self.reading(1.0091, 0.0008), 'ok')

    def test_no_talent_and_a_doubled_talent_alert(self):
        self.assertEqual(self.reading(1.0, 0.0008), 'alert')
        self.assertEqual(self.reading(1.12 / 1.10, 0.0008), 'alert')

    def test_an_interval_across_a_band_edge_is_not_judged(self):
        self.assertEqual(self.reading(1.0046, 0.0008), 'insufficient_trials')


class BandedRateTests(unittest.TestCase):
    EXPECTED = 0.15

    def judged(self, procs: float, trials: float) -> str:
        from compare import banded_rate, rate_judgement
        status, low, high, why = rate_judgement(procs, trials, 1, self.EXPECTED)
        return banded_rate(status, low, high, self.EXPECTED, why)[0]

    def test_an_interval_inside_the_band_that_excludes_the_exact_chance_is_ok(self):
        from procs import wilson_interval
        low, high = wilson_interval(2213, 15573)
        self.assertTrue(0.13 < low and high < 0.15)
        self.assertEqual(self.judged(2213, 15573), 'ok')

    def test_an_interval_across_a_band_edge_that_excludes_the_chance_alerts(self):
        from procs import wilson_interval
        low, high = wilson_interval(2000, 15573)
        self.assertTrue(low < 0.13 < high < 0.15)
        self.assertEqual(self.judged(2000, 15573), 'alert')

    def test_an_interval_holding_the_chance_across_a_band_edge_stays_measured(self):
        self.assertEqual(self.judged(300, 2000), 'measured')

    def test_an_interval_wholly_outside_the_band_alerts(self):
        self.assertEqual(self.judged(1500, 15573), 'alert')


class BetweenPartIntervalTests(unittest.TestCase):
    PARTS, TRIALS = 55, 300

    def parts(self, chances: list[float], seed: int) -> list[tuple[float, float]]:
        import random
        draw = random.Random(seed)
        return [(float(sum(draw.random() < chances[index % len(chances)] for _ in range(self.TRIALS))),
                 float(self.TRIALS)) for index in range(self.PARTS)]

    def widths(self, chances: list[float], seed: int) -> tuple[float, float]:
        from compare import between_part_interval
        from procs import wilson_interval
        parts = self.parts(chances, seed)
        low, high = between_part_interval(parts)
        wilson = wilson_interval(sum(events for events, _ in parts), self.PARTS * self.TRIALS)
        return high - low, wilson[1] - wilson[0]

    def test_seeded_binomial_parts_give_about_the_wilson_width(self):
        for seed in (1, 2, 3):
            with self.subTest(seed=seed):
                between, wilson = self.widths([0.15], seed)
                self.assertLess(abs(between / wilson - 1), 0.25)

    def test_seeded_overdispersed_parts_widen_the_interval(self):
        for seed in (1, 2, 3):
            with self.subTest(seed=seed):
                between, wilson = self.widths([0.10, 0.20], seed)
                self.assertGreater(between / wilson, 1.8)

    def test_a_pooled_banded_rate_is_judged_on_the_between_part_interval(self):
        from compare import between_part_judgement
        binomial = self.parts([0.15], 4)
        spread = self.parts([0.10, 0.20], 4)
        self.assertEqual(between_part_judgement(binomial, 1, 0.15)[0], 'ok')
        status, low, high, why = between_part_judgement(spread, 1, 0.15)
        self.assertIn('between-part', why)
        self.assertGreater(high - low, 0.02)

    def test_seeded_nine_parts_keep_the_wilson_interval(self):
        from compare import between_part_judgement
        from procs import wilson_interval
        parts = self.parts([0.10, 0.20], 5)[:9]
        status, low, high, why = between_part_judgement(parts, 1, 0.15)
        self.assertEqual((low, high), wilson_interval(sum(events for events, _ in parts), 9 * self.TRIALS))
        self.assertIn('Wilson', why)

    def test_seeded_ten_parts_take_the_between_part_t_interval(self):
        from compare import between_part_interval, between_part_judgement
        parts = self.parts([0.10, 0.20], 5)[:10]
        status, low, high, why = between_part_judgement(parts, 1, 0.15)
        self.assertEqual((low, high), between_part_interval(parts))
        self.assertIn('t over 10 parts', why)

    def test_one_part_has_no_between_part_interval(self):
        from compare import between_part_interval
        self.assertIsNone(between_part_interval([(10.0, 100.0)]))


class BetweenPartHitRatioTests(unittest.TestCase):
    CASTS = 20

    def model(self) -> dict:
        reads = {arm: [[f'{arm} {index} total', f'{arm} {index} count'] for index in range(self.CASTS + 1)]
                 for arm in ('control', 'treatment')}
        return {'kind': 'hit_ratio', 'reads': reads, 'minimum_hits': 1, 'trials': self.CASTS, 'expected': 1.0,
                'expected_bonus': 0.0, 'expected_delta': 20.0, 'rate': 'critical', 'parts': 2}

    def part(self, model: dict, shares: dict[str, float]):
        values = {}
        for arm, reads in model['reads'].items():
            for index, (total, count) in enumerate(reads):
                values[total] = index * 4 * shares[arm] + (index % 2) * 0.5
                values[count] = index * 4.0
        return type('Part', (), {'values': values, 'key': 'part', 'status': 'completed', 'message': ''})()

    def test_overdispersed_parts_widen_a_pooled_rate_interval(self):
        from compare import behaviour_hit_ratio_verdict
        model = self.model()
        base = Verdict('x', 'alert', None, None, None, None, '')
        steady = [self.part(model, {'control': 0.05, 'treatment': 0.25}) for _ in range(10)]
        spread = [self.part(model, {'control': 0.05, 'treatment': 0.25 + (0.04 if index % 2 else -0.04)})
                  for index in range(10)]
        narrow = behaviour_hit_ratio_verdict(base, steady, model).detail['bonus']['half']
        wide = behaviour_hit_ratio_verdict(base, spread, model)
        self.assertIn('between-part variance', wide.explanation)
        self.assertGreater(wide.detail['bonus']['half'], 2 * narrow)

    def test_nine_pooled_rate_parts_keep_the_per_cast_interval(self):
        from compare import behaviour_hit_ratio_verdict
        model = self.model()
        base = Verdict('x', 'alert', None, None, None, None, '')
        spread = [self.part(model, {'control': 0.05, 'treatment': 0.25 + (0.04 if index % 2 else -0.04)})
                  for index in range(9)]
        verdict = behaviour_hit_ratio_verdict(base, spread, model)
        self.assertNotIn('between-part variance', verdict.explanation)
        self.assertIn('per-cast interval', verdict.explanation)


if __name__ == '__main__':
    unittest.main()
