import ast
from dataclasses import replace
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest import mock

from behaviours import (BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_AGGRO_REDIRECT, BEHAVIOUR_CAST_APPLIES_AURA,
                        BEHAVIOUR_CAST_COMBAT, BEHAVIOUR_CAST_CONDITION, BEHAVIOUR_CAST_GATE,
                        BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_FIXED_COUNT, BEHAVIOUR_HEAL_BLOCK, BEHAVIOUR_IMMUNITY,
                        BEHAVIOUR_INTERNAL_COOLDOWN, BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_METRIC_RATIO_DELTA,
                        BEHAVIOUR_MOUNT_GRANT, BEHAVIOUR_PARTY_STAT_RATIO, BEHAVIOUR_THREAT_SLOPE, CONDITION_CONTRAST,
                        LEARNED_CONTRAST)
from compare import DATA_ONLY, NOT_MEASURED, Verdict, evaluate, judge_behaviour, observed, read_verdicts, write_verdicts
from conformance import DIFF_EXIT, main
from coverage import (BEHAVIOUR, BY_METRIC, CONSUMED, COVERAGE_FILE, DATA, EFFECTIVENESS_OF, EVENT, EVIDENCE, K3,
                      METRIC_EVIDENCE, NOT_CONSUMED, READBACK, STATE, STATE_PROMISES, UNPROVEN, Consumption,
                      EvidenceError, acting,
                      clause_coverage, clause_coverage_lines, coverage, TOOL_GAP, TOOL_GAP_ACCEPTED, TOOL_GAP_PENDING,
                      NO_BEHAVIOUR_ROUTE, NO_ROUTE_NOT_DATA, NO_ROUTE_PENDING, NO_ROUTE_TERMINAL,
                      fragment_entries, load_clauses, read_fragment, require_claims, states_value, write_coverage,
                      write_fragment)
from expiry import BEHAVIOUR_EXPIRY
from profile import (CLASSES_DIR, DBC_DIR, DbcSetMismatch, class_file_paths, ledger_consumption_path, load_class_file,
                     server_dbc_dir, spell_dbc_sha256)
from hits import NEVER_CAST, NO_HIT_EFFECT, UNMODELLED
from passives import PASSIVE_DELTA, POWER_NAMES, RATING_NAMES
from procs import PROC_CHECK
from triggers import TRIGGER_CHECK
from values import GAP_CLOSER_DISTANCE, Expectation

CLASS = {'class_id': 19, 'class_name': 'Templar', 'level': 60}
CLASS_AURA = 887007
ARGENT_BLADE = 807268
SACRED_SWING = 572769
SERENDIPITY = 300929
FERVENT_CASTIGATION = 707606


def verdict(label, status, spell, scenario, check, explanation=''):
    measured = None if status in ('unmodelled', 'unreadable') else 1.0
    return Verdict(label, status, measured, measured, measured, measured, explanation, scenario, spell, spell, check,
                   build=BUILD)


def value(spell, status='ok', check='effect_value'):
    return verdict(f'{spell} {check} #0', status, spell, f'conformance-templar-value-{spell}', check)


def known_aura(rank):
    return verdict(f'known_aura {CLASS_AURA}', 'ok', CLASS_AURA, f'conformance-templar-value-{rank}', 'known_aura')


def placeholder(spell):
    return verdict(f'{spell} hit_mean', 'unmodelled', spell, f'conformance-templar-hit-{spell}', 'unmodelled',
                   UNMODELLED + NEVER_CAST)


def hit(spell, status='ok', explanation=''):
    return verdict(f'{spell} hit_mean', status, spell, f'conformance-templar-hit-{spell}', 'hit_mean', explanation)


def passive(spell, status='ok'):
    return verdict(f'{spell} passive_delta #0', status, spell, f'conformance-templar-passive-{spell}', PASSIVE_DELTA)


def proc(aura, status='ok'):
    return verdict(f'proc_rate {aura}', status, aura, f'conformance-templar-proc-{aura}-part-1', PROC_CHECK)


def trigger(aura, status='alert'):
    return verdict(f'trigger_count {aura}', status, aura, f'conformance-templar-trigger-{aura}-part-1',
                   TRIGGER_CHECK)


def phase_one_set(passives: int) -> list[Verdict]:
    verdicts = []
    for spell in range(1000, 1000 + passives):
        verdicts += [value(spell), known_aura(spell), placeholder(spell)]
    return verdicts + [value(ARGENT_BLADE), known_aura(ARGENT_BLADE), hit(ARGENT_BLADE)]


class CoverageTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-coverage-'))

    def tearDown(self):
        shutil.rmtree(self.root)

    def compare_output(self, name, verdicts, header=CLASS):
        out = self.root / name
        out.mkdir()
        write_verdicts(header, out / 'manifest.json', self.root / 'stamp', verdicts, out)
        return out

    def test_placeholders_left_out(self):
        result = coverage(CLASS, phase_one_set(145))
        self.assertEqual(result.statuses.get('unmodelled', 0), 0)
        self.assertEqual(result.statuses['ok'], 145 * 2 + 3)
        self.assertEqual((result.passives, result.actives, result.spells), (145, 1, 146))

    def test_judged_spells(self):
        verdicts = [value(ARGENT_BLADE), value(ARGENT_BLADE, 'unmodelled', 'power_cost'),
                    value(SACRED_SWING, 'unmodelled'), value(SACRED_SWING, 'unreadable', 'cooldown_ms')]
        result = coverage(CLASS, verdicts)
        self.assertEqual((result.judged_spells, result.spells), (1, 2))

    def test_known_aura_alone_does_not_judge_a_spell(self):
        result = coverage(CLASS, [known_aura(ARGENT_BLADE), value(ARGENT_BLADE, 'unreadable')])
        self.assertEqual((result.judged_spells, result.spells), (0, 1))

    def test_proc_of_a_class_spell_judges_it_and_counts_as_behaviour(self):
        verdicts = [value(SERENDIPITY, 'unmodelled'), placeholder(SERENDIPITY), proc(SERENDIPITY), proc(92000)]
        result = coverage(CLASS, verdicts)
        self.assertEqual((result.judged_spells, result.spells), (1, 1))
        self.assertEqual((result.passives_with_behaviour, result.passives), (1, 1))

    def test_behaviour_needs_a_judged_behaviour_check(self):
        verdicts = [value(SERENDIPITY), passive(SERENDIPITY, 'unmodelled'),
                    value(FERVENT_CASTIGATION, 'unreadable'), passive(FERVENT_CASTIGATION, 'measured'),
                    trigger(FERVENT_CASTIGATION)]
        result = coverage(CLASS, verdicts)
        self.assertEqual((result.passives_with_behaviour, result.passives), (1, 2))
        self.assertEqual(result.judged_spells, 2)

    def test_actives_with_a_judged_hit_model(self):
        verdicts = [value(ARGENT_BLADE), hit(ARGENT_BLADE), value(SACRED_SWING), hit(SACRED_SWING, 'alert'),
                    value(801443), hit(801443, 'unmodelled'), value(1000), passive(1000)]
        result = coverage(CLASS, verdicts)
        self.assertEqual((result.actives_with_hit, result.actives), (2, 3))
        self.assertEqual(result.passives, 1)

    def test_actives_with_effect_denominator(self):
        verdicts = [value(ARGENT_BLADE), hit(ARGENT_BLADE),
                    value(SACRED_SWING), hit(SACRED_SWING, 'unmodelled', UNMODELLED + NO_HIT_EFFECT +
                                             ' among effects [6]'),
                    value(801443), hit(801443, 'unmodelled', UNMODELLED + 'effect 2 has no readable tooltip value')]
        result = coverage(CLASS, verdicts)
        self.assertEqual(result.actives_with_hit, 1)
        self.assertEqual(result.actives, 3)
        self.assertEqual(result.actives_with_effect, 2)

    def test_coverage_markdown(self):
        before = self.compare_output('before', phase_one_set(2))
        after = self.compare_output('after', [value(1000), passive(1000), value(1001, 'unreadable'),
                                              passive(1001, 'alert'), value(ARGENT_BLADE, 'unreadable'),
                                              hit(ARGENT_BLADE)])
        path = write_coverage(before, after, self.root / 'out')
        text = path.read_text(encoding='utf-8')
        self.assertEqual(path, self.root / 'out' / COVERAGE_FILE)
        self.assertIn('| | before | after | difference |', text)
        self.assertIn('| spells judged | 3 of 3 (100.0%) | 3 of 3 (100.0%) | +0 |', text)
        self.assertIn('| passives with a behaviour check | 0 of 2 (0.0%) | 2 of 2 (100.0%) | +2 |', text)
        self.assertIn('| actives with a hit model | 1 of 1 (100.0%) | 1 of 1 (100.0%) | +0 |', text)
        self.assertIn('| ok | 7 | 3 | -4 |', text)
        self.assertIn('| alert | 0 | 1 | +1 |', text)
        self.assertIn(f'{2} phase-1 placeholders', text)

    def test_coverage_markdown_has_both_denominators(self):
        before = self.compare_output('before', phase_one_set(1))
        after = self.compare_output('after', [value(ARGENT_BLADE), hit(ARGENT_BLADE),
                                              value(SACRED_SWING), hit(SACRED_SWING, 'unmodelled',
                                                                       UNMODELLED + NO_HIT_EFFECT +
                                                                       ' among effects [6]')])
        text = write_coverage(before, after, self.root / 'out').read_text(encoding='utf-8')
        self.assertIn('actives with a hit model |', text)
        self.assertIn('actives with a hit model (of those with an effect) |', text)
        self.assertIn('| actives with a hit model | 1 of 1 (100.0%) | 1 of 2 (50.0%) | +0 |', text)
        self.assertIn('| actives with a hit model (of those with an effect) | 1 of 1 (100.0%) | 1 of 1 (100.0%) | '
                      '+0 |', text)

    def test_coverage_lists_spells_judged_only_on_one_side(self):
        before = self.compare_output('before', [value(ARGENT_BLADE), value(SACRED_SWING, 'unreadable')])
        after = self.compare_output('after', [value(ARGENT_BLADE, 'unreadable'), value(SACRED_SWING)])
        text = write_coverage(before, after, self.root / 'out').read_text(encoding='utf-8')
        self.assertIn(f'## Spells judged before, not after\n\n{ARGENT_BLADE}', text)
        self.assertIn(f'## Spells judged after, not before\n\n{SACRED_SWING}', text)

    def test_coverage_command_writes_into_the_after_directory(self):
        before = self.compare_output('before', [value(ARGENT_BLADE)])
        after = self.compare_output('after', [value(ARGENT_BLADE)])
        self.assertEqual(main(['coverage', '--before', str(before), '--after', str(after)]), 0)
        self.assertTrue((after / COVERAGE_FILE).is_file())

    def test_coverage_command_refuses_other_classes(self):
        before = self.compare_output('before', [value(ARGENT_BLADE)])
        after = self.compare_output('after', [value(ARGENT_BLADE)], {**CLASS, 'class_id': 20})
        self.assertEqual(main(['coverage', '--before', str(before), '--after', str(after)]), DIFF_EXIT)
        self.assertFalse((after / COVERAGE_FILE).exists())


class ClauseCoverageTest(unittest.TestCase):
    def test_a_claim_with_every_label_conformant_is_proven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value #0']}]
        result = clause_coverage(clauses, [value(ARGENT_BLADE)], BUILD)
        self.assertEqual((result.proven, result.total, result.unproven), (1, 1, []))

    def test_a_tolerated_verdict_counts_as_proven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value #0']}]
        result = clause_coverage(clauses, [value(ARGENT_BLADE, 'tolerated')], BUILD)
        self.assertEqual((result.proven, result.unproven), (1, []))

    def test_an_alerting_label_leaves_the_claim_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value #0']}]
        result = clause_coverage(clauses, [value(ARGENT_BLADE, 'alert')], BUILD)
        self.assertEqual((result.proven, result.total), (0, 1))
        self.assertEqual(result.unproven[0]['clause'], 'deals extra damage')

    def test_a_claim_with_no_labels_is_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim', 'labels': []}]
        result = clause_coverage(clauses, [value(ARGENT_BLADE)], BUILD)
        self.assertEqual((result.proven, result.total, len(result.unproven)), (0, 1, 1))

    def test_no_claim_entries_are_excluded_from_the_total(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'Level 10 Passive', 'kind': 'no_claim',
                   'reason': 'a level-gate label', 'labels': []}]
        result = clause_coverage(clauses, [], BUILD)
        self.assertEqual((result.proven, result.total, result.unproven), (0, 0, []))

    def test_an_ordinal_free_label_matches_the_real_ordinal_suffixed_verdict(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #1', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        result = clause_coverage(clauses, verdicts, BUILD)
        self.assertEqual((result.proven, result.total, result.unproven), (1, 1, []))

    def test_an_ordinal_free_label_needs_every_matching_occurrence_conformant(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage twice', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #1', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value'),
                   verdict(f'{ARGENT_BLADE} effect_value 801832e1 #2', 'alert', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        result = clause_coverage(clauses, verdicts, BUILD)
        self.assertEqual((result.proven, result.total), (0, 1))

    def test_an_ordinal_free_label_with_no_matching_verdict_is_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        result = clause_coverage(clauses, [], BUILD)
        self.assertEqual((result.proven, result.total), (0, 1))

    def test_a_label_already_carrying_an_ordinal_is_not_expanded(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1 #1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #10', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        result = clause_coverage(clauses, verdicts, BUILD)
        self.assertEqual((result.proven, result.total), (0, 1))


SERVER_SHA = 'a' * 64
CLIENT_SHA = 'b' * 64
BUILD = 'c' * 64
OTHER_BUILD = 'd' * 64
CODE_MODULES = ('values.py', 'hits.py', 'passives.py', 'procs.py', 'triggers.py', 'behaviours.py', 'stack.py',
                'expiry.py')


def claim(text, *labels, spell=ARGENT_BLADE):
    return {'spell': spell, 'clause': text, 'kind': 'claim', 'labels': list(labels)}


def judged(label, check, metric=None, status='ok', **detail):
    stamp = {**({'metric': metric} if metric else {}), **detail}
    return replace(verdict(label, status, ARGENT_BLADE, f'conformance-templar-value-{ARGENT_BLADE}', check),
                   detail=stamp or None)


def evidence_of(clauses, verdicts, build=BUILD):
    result = clause_coverage(clauses, verdicts, build)
    return [status for _, status in result.evidence], result


class StreamedTextSourceTest(unittest.TestCase):
    def sourced(self, basis: str, clause: str = 'deals damage', dbc_clause: str | None = None) -> dict:
        entry = {**claim(clause, f'{ARGENT_BLADE} hit_mean'),
                 'text_source': {'spell': ARGENT_BLADE, 'file': 'f.sql', 'commit': 'c', 'pr': None, 'basis': basis,
                                 'ruling': None, 'dbc_differs': 'Description'}}
        return {**entry, 'dbc_clause': dbc_clause} if dbc_clause is not None else entry

    def coverage(self, clauses: list[dict]):
        return clause_coverage(clauses, [hit(ARGENT_BLADE)], BUILD, streamed=frozenset({ARGENT_BLADE}))

    def test_a_streamed_spell_without_its_text_source_is_refused(self):
        with self.assertRaises(EvidenceError):
            self.coverage([claim('deals damage', f'{ARGENT_BLADE} hit_mean')])
        with self.assertRaises(EvidenceError):
            self.coverage([self.sourced('guess')])

    def test_a_changed_project_text_is_counted_unproven_and_listed(self):
        changed = self.sourced('align_to_server', 'deals 12 damage', 'deals 10 damage')
        result = self.coverage([changed])
        self.assertEqual(([status for _, status in result.evidence], result.project_text), ([UNPROVEN], [changed]))
        unchanged = self.sourced('align_to_server')
        self.assertEqual([status for _, status in self.coverage([unchanged]).evidence], [BEHAVIOUR])
        ruled = self.sourced('owner_ruling', 'deals 12 damage', 'deals 10 damage')
        self.assertEqual([status for _, status in self.coverage([ruled]).evidence], [BEHAVIOUR])

    def test_a_text_correction_counts_only_when_every_figure_is_the_same(self):
        spelled = self.sourced('text_correction', 'Only occurs once every 0.5 sec.',
                               'Cnly occur once every 0.5 sec.')
        renumbered = self.sourced('text_correction', 'Only occurs once every 0.5 sec.',
                                  'Cnly occur once every 1.5 sec.')
        self.assertEqual([status for _, status in self.coverage([spelled]).evidence], [BEHAVIOUR])
        result = self.coverage([renumbered])
        self.assertEqual(([status for _, status in result.evidence], result.project_text), ([UNPROVEN], [renumbered]))


class EvidenceStatusTest(unittest.TestCase):
    def test_a_readback_proves_data_only(self):
        statuses, result = evidence_of([claim('deals extra damage', f'{ARGENT_BLADE} effect_value #0')],
                                       [value(ARGENT_BLADE)])
        self.assertEqual(statuses, [DATA])
        self.assertEqual((result.proven, result.behaviour, result.data), (1, 0, 1))

    def test_an_observed_hit_proves_behaviour(self):
        statuses, result = evidence_of([claim('deals damage', f'{ARGENT_BLADE} hit_mean')], [hit(ARGENT_BLADE)])
        self.assertEqual(statuses, [BEHAVIOUR])
        self.assertEqual((result.proven, result.behaviour, result.data), (1, 1, 0))

    def test_one_behaviour_label_among_readbacks_makes_the_clause_behaviour(self):
        clauses = [claim('deals extra damage', f'{ARGENT_BLADE} effect_value #0', f'{ARGENT_BLADE} hit_mean')]
        self.assertEqual(evidence_of(clauses, [value(ARGENT_BLADE), hit(ARGENT_BLADE)])[0], [BEHAVIOUR])

    def test_an_alerting_behaviour_label_leaves_the_clause_unproven(self):
        clauses = [claim('deals extra damage', f'{ARGENT_BLADE} effect_value #0', f'{ARGENT_BLADE} hit_mean')]
        statuses, result = evidence_of(clauses, [value(ARGENT_BLADE), hit(ARGENT_BLADE, 'alert')])
        self.assertEqual((statuses, result.proven, result.behaviour), ([UNPROVEN], 0, 0))

    def test_a_promised_stat_in_a_learned_contrast_is_behaviour(self):
        verdicts = [judged('1 e0 armor', PASSIVE_DELTA, 'armor')]
        self.assertEqual(evidence_of([claim('Increases your Armor by $s1%.', '1 e0 armor')], verdicts)[0],
                         [BEHAVIOUR])

    def effectiveness(self, *buff_clauses, named=2):
        martyr = {**claim('Increases the effectiveness of Gift of Zeal by $s2%.', '1 behaviour_metric_delta gift',
                          spell=1), EFFECTIVENESS_OF: named}
        verdicts = [judged('1 behaviour_metric_delta gift', BEHAVIOUR_METRIC_DELTA, 'stat',
                           contrast=LEARNED_CONTRAST)]
        buff = [entry if isinstance(entry, dict) else claim(entry, spell=2) for entry in buff_clauses]
        return evidence_of([martyr, *buff], verdicts)[0][0]

    def test_the_effectiveness_of_a_single_value_buff_promises_that_value(self):
        self.assertEqual(self.effectiveness('Places a Gift on a friendly target, increasing Agility by $s1',
                                            'for $d', 'within $a1 yds'), BEHAVIOUR)

    def test_the_effectiveness_of_a_buff_with_two_values_promises_neither(self):
        self.assertEqual(self.effectiveness('Places a Gift on a friendly target, increasing Agility by $s1',
                                            'and Stamina by $s2', 'for $d'), DATA)

    def test_two_values_in_one_entry_promise_neither(self):
        self.assertEqual(self.effectiveness('Places a Gift on a friendly target, increasing Agility by $s1 and '
                                            'Stamina by $s2', 'for $d'), DATA)

    def test_a_second_value_in_a_no_claim_entry_promises_neither(self):
        second = {'spell': 2, 'clause': 'and Stamina by $s2', 'kind': 'no_claim', 'labels': [], 'reason': 'r'}
        self.assertEqual(self.effectiveness('Places a Gift on a friendly target, increasing Agility by $s1', second,
                                            'for $d'), DATA)

    def test_one_value_named_in_two_entries_is_still_one_value(self):
        self.assertEqual(self.effectiveness('increasing Agility by $s1', 'Agility by $S1 for $d'), BEHAVIOUR)

    def test_a_period_or_stack_count_beside_the_value_is_a_second_value(self):
        self.assertEqual(self.effectiveness('increasing Agility by $s1 every $t1 sec, stacking $u times'), DATA)

    def test_an_effectiveness_clause_without_a_named_subject_stays_data(self):
        self.assertEqual(self.effectiveness('increasing Agility by $s1', named=3), DATA)

    def test_duration_and_range_are_not_stated_values(self):
        for text, stated in (('for $d', False), ('for $803237d', False), ('within $a1 yds', False),
                             ('increasing Agility by $s1', True), ('by 20%', True), ('for ${$m1+1} sec', True),
                             ('a $/1000;s1 sec cast time', True)):
            with self.subTest(text=text):
                self.assertEqual(states_value(text), stated)

    def test_malformed_effectiveness_subjects_are_refused(self):
        cases = {'does not increase': {**claim('Increases your Agility by $s1%.', 'l1'), EFFECTIVENESS_OF: 2},
                 'spell id': {**claim('Increases the effectiveness of Gift of Zeal.', 'l1'), EFFECTIVENESS_OF: '2'},
                 'not a claim entry': {**claim('Increases the effectiveness of Gift of Zeal.', 'l1'),
                                       'kind': 'no_claim', EFFECTIVENESS_OF: 2}}
        for message, clause in cases.items():
            with self.subTest(message=message), self.assertRaisesRegex(EvidenceError, message):
                clause_coverage([clause], [], BUILD)

    def test_spell_damage_promises_the_spell_power_stat(self):
        verdicts = [judged('1 e2 spell_power 1', PASSIVE_DELTA, 'spell_power')]
        promised = claim('Increases your Holy spell damage by $s3% of your Agility.', '1 e2 spell_power 1')
        self.assertEqual(evidence_of([promised], verdicts)[0], [BEHAVIOUR])
        proxy = claim('Increases your Holy damage by $s3%.', '1 e2 spell_power 1')
        self.assertEqual(evidence_of([proxy], verdicts)[0], [DATA])

    def test_a_split_clause_names_the_power_without_its_maximum(self):
        verdicts = [judged('1 e1 max_power 3', PASSIVE_DELTA, 'max_power')]
        promised = claim('and Energy by $s1%', '1 e1 max_power 3')
        self.assertEqual(evidence_of([promised], verdicts)[0], [BEHAVIOUR])
        proxy = claim('Increases your maximum health by $s1%', '1 e1 max_power 3')
        self.assertEqual(evidence_of([proxy], verdicts)[0], [DATA])

    def test_armor_penetration_promises_its_combat_rating(self):
        verdicts = [judged('1 e1 combat_rating 24', PASSIVE_DELTA, 'combat_rating')]
        promised = claim('and your Armor penetration by $s2% of your Intellect', '1 e1 combat_rating 24')
        self.assertEqual(evidence_of([promised], verdicts)[0], [BEHAVIOUR])
        proxy = claim('and your Armor by $s2% of your Intellect', '1 e1 combat_rating 24')
        self.assertEqual(evidence_of([proxy], verdicts)[0], [DATA])

    def test_state_promises_name_every_phrase_of_the_passive_tables(self):
        for metric, names in (('max_power', POWER_NAMES.values()), ('combat_rating', RATING_NAMES.values())):
            for name in names:
                with self.subTest(metric=metric, name=name):
                    self.assertRegex(name, rf'(?i)\b(?:{STATE_PROMISES[metric]})\b')

    def test_immunity_and_threat_slope_checks_are_behaviour(self):
        self.assertEqual(EVIDENCE[BEHAVIOUR_IMMUNITY], BEHAVIOUR)
        self.assertEqual(EVIDENCE[BEHAVIOUR_THREAT_SLOPE], BEHAVIOUR)

    def test_a_promised_stat_the_floor_alone_accepted_is_data(self):
        verdicts = [replace(judged('1 e0 stat 1', PASSIVE_DELTA, 'stat'),
                            detail={'metric': 'stat', DATA_ONLY: 'the 1-point floor is wider than the band'})]
        clauses = [claim('Increases your Agility by $s1%', '1 e0 stat 1')]
        self.assertEqual(evidence_of(clauses, verdicts)[0], [DATA])
        powered = [replace(verdicts[0], detail={'metric': 'stat'})]
        self.assertEqual(evidence_of(clauses, powered)[0], [BEHAVIOUR])

    def test_a_stat_read_as_a_proxy_stays_data(self):
        verdicts = [judged('1 e0 armor', PASSIVE_DELTA, 'armor')]
        self.assertEqual(evidence_of([claim('Reduces Physical damage taken by $s1%.', '1 e0 armor')], verdicts)[0],
                         [DATA])

    def test_a_stat_read_without_a_learned_contrast_stays_data(self):
        verdicts = [judged('1 behaviour_metric_delta', BEHAVIOUR_METRIC_DELTA, 'armor',
                           contrast=CONDITION_CONTRAST)]
        clauses = [claim('increases your Armor by 10%', '1 behaviour_metric_delta')]
        self.assertEqual(evidence_of(clauses, verdicts)[0], [DATA])
        learned = [replace(verdicts[0], detail={'metric': 'armor', 'contrast': LEARNED_CONTRAST})]
        self.assertEqual(evidence_of(clauses, learned)[0], [BEHAVIOUR])

    def test_a_modifier_readback_in_a_learned_contrast_stays_data(self):
        verdicts = [judged('1 e0 spell_modifier 2', PASSIVE_DELTA, 'spell_modifier')]
        clauses = [claim('Increases the damage of Reckoning by $s1%.', '1 e0 spell_modifier 2')]
        self.assertEqual(evidence_of(clauses, verdicts)[0], [DATA])

    def test_an_event_metric_of_a_metric_check_is_behaviour(self):
        verdicts = [judged('1 behaviour_metric_delta', BEHAVIOUR_METRIC_DELTA, 'owned_creature_count',
                           contrast=LEARNED_CONTRAST)]
        self.assertEqual(evidence_of([claim('summons a copy', '1 behaviour_metric_delta')], verdicts)[0],
                         [BEHAVIOUR])

    def test_an_outcome_check_of_round_ten_is_behaviour(self):
        clauses = [claim('acts on the target', '1 outcome')]
        for check in (BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_AGGRO_REDIRECT, BEHAVIOUR_EXPIRY, BEHAVIOUR_CAST_COMBAT,
                      BEHAVIOUR_CAST_CONDITION, BEHAVIOUR_CAST_GATE, BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_FIXED_COUNT,
                      BEHAVIOUR_HEAL_BLOCK, BEHAVIOUR_INTERNAL_COOLDOWN, BEHAVIOUR_METRIC_RATIO_DELTA,
                      BEHAVIOUR_MOUNT_GRANT, GAP_CLOSER_DISTANCE):
            with self.subTest(check=check):
                self.assertEqual(evidence_of(clauses, [judged('1 outcome', check)])[0], [BEHAVIOUR])

    def test_a_remaining_time_readback_after_a_cast_is_data(self):
        clauses = [claim('Applies Sacred Restraint for $102208d.', '1 readback')]
        self.assertEqual(evidence_of(clauses, [judged('1 readback', BEHAVIOUR_CAST_APPLIES_AURA)])[0], [DATA])
        with mock.patch.dict(EVIDENCE, {BEHAVIOUR_CAST_APPLIES_AURA: BEHAVIOUR}):
            self.assertNotEqual(evidence_of(clauses, [judged('1 readback', BEHAVIOUR_CAST_APPLIES_AURA)])[0],
                                [DATA])

    def test_an_expiry_pair_lifts_a_readback_clause_to_behaviour(self):
        clauses = [claim('Applies Sacred Restraint for $102208d.', '1 readback', '1 expiry')]
        verdicts = [judged('1 readback', BEHAVIOUR_CAST_APPLIES_AURA), judged('1 expiry', BEHAVIOUR_EXPIRY)]
        self.assertEqual(evidence_of(clauses, verdicts)[0], [BEHAVIOUR])
        unmeasured = [verdicts[0], judged('1 expiry', BEHAVIOUR_EXPIRY, status='unmeasured')]
        self.assertEqual(evidence_of(clauses, unmeasured)[0], [UNPROVEN])

    def test_a_party_stat_ratio_proves_behaviour_only_for_the_promised_stat(self):
        clauses = [claim('Increases the attack power of all party and raid members $s1%.', '1 party')]
        promised = judged('1 party', BEHAVIOUR_PARTY_STAT_RATIO, 'attack_power')
        probe = judged('1 party', BEHAVIOUR_PARTY_STAT_RATIO, 'spell_damage_done')
        proxy = judged('1 party', BEHAVIOUR_PARTY_STAT_RATIO, 'armor')
        self.assertEqual(evidence_of(clauses, [promised])[0], [BEHAVIOUR])
        self.assertEqual(evidence_of(clauses, [probe])[0], [DATA])
        self.assertEqual(evidence_of(clauses, [proxy])[0], [DATA])

    def test_a_party_stat_ratio_without_its_metric_fails_the_run(self):
        with self.assertRaises(EvidenceError):
            evidence_of([claim('Increases attack power.', '1 party')], [judged('1 party', BEHAVIOUR_PARTY_STAT_RATIO)])

    def test_a_water_walk_read_after_the_cast_is_behaviour(self):
        verdicts = [judged('1 behaviour_aura_presence', BEHAVIOUR_METRIC_DELTA, 'water_walk')]
        clauses = [claim('and granting the ability to walk on water.', '1 behaviour_aura_presence')]
        self.assertEqual(evidence_of(clauses, verdicts)[0], [BEHAVIOUR])

    def test_seeded_wrong_class_of_a_round_ten_check_is_caught(self):
        clauses = [claim('Holds 2 charges.', '1 behaviour_charge_recharge')]
        verdicts = [judged('1 behaviour_charge_recharge', BEHAVIOUR_CHARGE_RECHARGE)]
        with mock.patch.dict(EVIDENCE, {BEHAVIOUR_CHARGE_RECHARGE: DATA}):
            self.assertEqual(evidence_of(clauses, verdicts)[0], [DATA])
        self.assertEqual(evidence_of(clauses, verdicts)[0], [BEHAVIOUR])

    def test_event_time_reads_of_a_metric_check_are_behaviour(self):
        label = '1 behaviour_metric_delta'
        clauses = [claim('Deals Holy damage every 3 sec.', label)]
        for metric in ('event_first_ms', 'event_interval_min_ms', 'event_interval_max_ms',
                       'event_interval_median_ms'):
            with self.subTest(metric=metric):
                self.assertEqual(METRIC_EVIDENCE[metric], EVENT)
                read = judged(label, BEHAVIOUR_METRIC_DELTA, metric, contrast=LEARNED_CONTRAST)
                self.assertEqual(evidence_of(clauses, [read])[0], [BEHAVIOUR])
                with mock.patch.dict(METRIC_EVIDENCE, {metric: READBACK}):
                    self.assertEqual(evidence_of(clauses, [read])[0], [DATA])

    def test_a_damage_taken_probe_without_a_hit_is_a_readback(self):
        label = '1 behaviour_metric_delta damage_taken'
        clauses = [claim('reduces damage taken by an additional 5% per copy', label)]
        for metric in ('melee_damage_taken', 'spell_damage_taken'):
            with self.subTest(metric=metric):
                self.assertEqual(METRIC_EVIDENCE[metric], READBACK)
                read = judged(label, BEHAVIOUR_METRIC_DELTA, metric, contrast=LEARNED_CONTRAST)
                self.assertEqual(evidence_of(clauses, [read])[0], [DATA])
        self.assertEqual(METRIC_EVIDENCE['spell_absorb_total'], EVENT)

    def test_a_threat_read_counts_only_where_the_clause_promises_threat(self):
        label = '1 behaviour_metric_delta'
        read = judged(label, BEHAVIOUR_METRIC_DELTA, 'threat', contrast=LEARNED_CONTRAST)
        self.assertEqual(METRIC_EVIDENCE['threat'], STATE)
        self.assertEqual(evidence_of([claim('dealing High Threat Holy damage', label)], [read])[0], [BEHAVIOUR])
        self.assertEqual(evidence_of([claim('dealing Holy damage', label)], [read])[0], [DATA])

    def test_a_linked_label_takes_the_evidence_of_what_checks_it(self):
        linked = verdict('1 e0 passive', 'closed', 1, 'conformance-templar-passive-1', 'unmodelled',
                         f'checked by "{ARGENT_BLADE} hit_mean" (status ok)')
        clauses = [claim('deals damage', '1 e0 passive')]
        self.assertEqual(evidence_of(clauses, [linked, hit(ARGENT_BLADE)])[0], [BEHAVIOUR])
        readback = replace(linked, explanation=f'checked by "{ARGENT_BLADE} effect_value #0" (status ok)')
        self.assertEqual(evidence_of(clauses, [readback, value(ARGENT_BLADE)])[0], [DATA])

    def test_a_check_closed_by_rule_is_data(self):
        closed = verdict(f'{ARGENT_BLADE} hit_mean', 'closed', ARGENT_BLADE, 'conformance-templar-hit-1', 'hit_mean',
                         'closed: cosmetic')
        self.assertEqual(evidence_of([claim('deals damage', f'{ARGENT_BLADE} hit_mean')], [closed])[0], [DATA])

    def test_an_unknown_check_fails_the_run(self):
        with self.assertRaisesRegex(EvidenceError, 'behaviour_not_in_the_table'):
            clause_coverage([], [judged('1 behaviour_not_in_the_table', 'behaviour_not_in_the_table')], BUILD)

    def test_a_metric_check_without_its_metric_fails(self):
        with self.assertRaisesRegex(EvidenceError, 'no observed metric'):
            clause_coverage([claim('x', '1 e0 armor')], [judged('1 e0 armor', PASSIVE_DELTA)], BUILD)

    def test_an_unknown_metric_fails(self):
        with self.assertRaisesRegex(EvidenceError, 'quest_status'):
            clause_coverage([claim('x', '1 e0 q')], [judged('1 e0 q', PASSIVE_DELTA, 'quest_status')], BUILD)

    def test_seeded_wrong_evidence_class_is_caught(self):
        with mock.patch.dict(EVIDENCE, {'effect_value': BEHAVIOUR}):
            statuses, _ = evidence_of([claim('x', f'{ARGENT_BLADE} effect_value #0')], [value(ARGENT_BLADE)])
        self.assertNotEqual(statuses, [DATA])
        self.assertEqual(evidence_of([claim('x', f'{ARGENT_BLADE} effect_value #0')], [value(ARGENT_BLADE)])[0],
                         [DATA])


def consumed(label, result=CONSUMED, build=BUILD):
    return Consumption(label, K3, ARGENT_BLADE, 0, build, 'k3.json', result)


class ConsumptionTest(unittest.TestCase):
    READBACK = f'{ARGENT_BLADE} effect_value #0'

    def coverage(self, rows, status='ok'):
        return clause_coverage([claim('deals extra damage', self.READBACK)], [value(ARGENT_BLADE, status)], BUILD,
                               rows)

    def test_a_consumed_k3_row_of_the_same_build_promotes_a_readback_to_behaviour(self):
        result = self.coverage([consumed(self.READBACK)])
        self.assertEqual(([status for _, status in result.evidence], result.behaviour), ([BEHAVIOUR], 1))
        self.assertEqual(result.promoted, {self.READBACK})
        self.assertIn('readbacks promoted by a K3 consumption row (the acting reading moved under a server '
                      'mutant): 1', clause_coverage_lines(result))

    def test_seeded_row_of_another_build_promotes_nothing(self):
        result = self.coverage([consumed(self.READBACK, build=OTHER_BUILD)])
        self.assertEqual([status for _, status in result.evidence], [DATA])

    def test_a_not_consumed_row_keeps_the_readback_data_and_is_listed(self):
        result = self.coverage([consumed(self.READBACK, NOT_CONSUMED)])
        self.assertEqual(([status for _, status in result.evidence], result.not_consumed), ([DATA], {self.READBACK}))

    def test_one_not_consumed_row_outranks_a_consumed_row_of_the_same_label(self):
        result = self.coverage([consumed(self.READBACK), consumed(self.READBACK, NOT_CONSUMED)])
        self.assertEqual([status for _, status in result.evidence], [DATA])

    def test_a_consumed_row_never_proves_an_alerting_readback(self):
        result = self.coverage([consumed(self.READBACK)], 'alert')
        self.assertEqual([status for _, status in result.evidence], [UNPROVEN])

    def test_acting_observations_exclude_readbacks_and_data_only_reads(self):
        self.assertTrue(acting(hit(ARGENT_BLADE)))
        self.assertFalse(acting(value(ARGENT_BLADE)))
        self.assertFalse(acting(judged('1 e0 armor', PASSIVE_DELTA, 'armor', **{DATA_ONLY: 'floor'})))
        self.assertFalse(acting(hit(ARGENT_BLADE, 'alert')))

    def test_the_client_visible_set_acts_where_the_detection_predicate_is_a_readback(self):
        self.assertTrue(acting(judged('300513 behaviour_detection client stealth revealed', BEHAVIOUR_METRIC_DELTA,
                                      'nearby_creature_at_client')))
        self.assertFalse(acting(judged('300513 behaviour_detection stealth revealed', BEHAVIOUR_METRIC_DELTA,
                                       'can_detect')))

    def test_consumption_files_are_not_class_files(self):
        self.assertEqual(ledger_consumption_path(CLASSES_DIR / 'templar_clauses.json'),
                         CLASSES_DIR / 'templar_consumption.json')
        self.assertNotIn(CLASSES_DIR / 'templar_consumption.json', class_file_paths())


class EvidenceTablesTest(unittest.TestCase):
    def defined_checks(self) -> set[str]:
        found = set()
        for name in CODE_MODULES:
            tree = ast.parse((Path(__file__).parent / name).read_text(encoding='utf-8'))
            for node in ast.walk(tree):
                if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                    target = node.targets[0].id
                    if target.endswith('_CHECK') or (target.startswith('BEHAVIOUR_') and target != 'BEHAVIOUR_CHECKS'):
                        if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                            found.add(node.value.value)
        return found

    def test_every_check_the_package_defines_has_an_evidence_class(self):
        from hits import HIT_CHECKS
        from stack import STACK_CHECKS
        from values import CHECKS
        checks = self.defined_checks() | set(HIT_CHECKS) | set(STACK_CHECKS) | set(CHECKS)
        self.assertGreater(len(checks), 40)
        self.assertEqual(sorted(checks - EVIDENCE.keys()), [])

    def test_every_metric_of_the_class_checks_has_an_evidence_class(self):
        for path in class_file_paths():
            class_file = load_class_file(json.loads(path.read_text(encoding='utf-8'))['class_id'])
            metrics = {entry.get('metric') or entry.get('observe', {}).get('metric')
                       for entry in class_file.get('behaviours', [])} - {None}
            metrics |= {entry['observe_metric'] for entry in class_file.get('triggers', [])
                        if 'observe_metric' in entry}
            self.assertEqual(sorted(metrics - METRIC_EVIDENCE.keys()), [], path.name)

    @unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
    def test_every_metric_classed_expectation_of_the_class_files_carries_its_metric(self):
        from behaviours import behaviour_scenario
        for path in class_file_paths():
            class_file = load_class_file(json.loads(path.read_text(encoding='utf-8'))['class_id'])
            unstamped = [expectation.label for entry in class_file.get('behaviours', [])
                         for expectations in (behaviour_scenario(class_file, entry)[1],)
                         for expectation in expectations
                         if EVIDENCE[expectation.check] == BY_METRIC
                         and observed(expectation).get('metric') not in METRIC_EVIDENCE]
            self.assertEqual(unstamped, [], path.name)

    def test_every_state_metric_names_its_promise(self):
        states = {metric for metric, kind in METRIC_EVIDENCE.items() if kind == STATE}
        self.assertEqual(states, set(STATE_PROMISES))
        self.assertEqual(METRIC_EVIDENCE['aura'], EVENT)


class StampTest(unittest.TestCase):
    def test_observed_reads_the_model(self):
        expectation = Expectation('1 behaviour_metric_delta', BEHAVIOUR_METRIC_DELTA, 1, 1, None, '1', 'r',
                                         {'metric': 'aura', 'contrast': LEARNED_CONTRAST})
        self.assertEqual(observed(expectation), {'metric': 'aura', 'contrast': LEARNED_CONTRAST})
        trigger = replace(expectation, model={'observe_metric': 'spell_damage_count'})
        self.assertEqual(observed(trigger), {'metric': 'spell_damage_count'})

    def test_judge_behaviour_stamps_even_an_unmeasured_verdict(self):
        expectation = Expectation('1 behaviour_metric_delta', BEHAVIOUR_METRIC_DELTA, 1, 1, None, '1', 'r',
                                         {'metric': 'aura', 'contrast': LEARNED_CONTRAST})
        base = Verdict('1 behaviour_metric_delta', 'alert', None, None, None, None, '', 's', 1, 1,
                       BEHAVIOUR_METRIC_DELTA)
        self.assertEqual(judge_behaviour(base, None, expectation).detail, {'metric': 'aura', 'contrast': 'learned'})


class SpellDbcGuardTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-dbc-guard-'))

    def tearDown(self):
        shutil.rmtree(self.root)

    def dbc_set(self, name, content):
        directory = self.root / name
        directory.mkdir()
        (directory / 'Spell.dbc').write_bytes(content)
        return directory

    def test_a_set_with_another_spell_dbc_is_refused(self):
        server = self.dbc_set('server', b'server')
        client = self.dbc_set('client', b'client')
        copy = self.dbc_set('copy', b'server')
        with mock.patch('profile.DBC_DIR', server):
            self.assertEqual(server_dbc_dir(copy), copy)
            with self.assertRaises(DbcSetMismatch):
                server_dbc_dir(client)
        with self.assertRaises(DbcSetMismatch):
            spell_dbc_sha256(self.root / 'missing')

    def test_a_class_file_pointing_at_another_set_is_refused(self):
        server = self.dbc_set('server', b'server')
        client = self.dbc_set('client', b'client')
        classes = self.root / 'classes'
        classes.mkdir()
        (classes / 'probe.json').write_text(json.dumps({'class_id': 99, 'dbc_dir': str(client)}), encoding='utf-8')
        with mock.patch('profile.DBC_DIR', server), mock.patch('profile.CLASSES_DIR', classes):
            with self.assertRaises(DbcSetMismatch):
                load_class_file(99)
            (classes / 'probe.json').write_text(json.dumps({'class_id': 99, 'dbc_dir': str(server)}),
                                                encoding='utf-8')
            self.assertEqual(load_class_file(99)['class_id'], 99)

    def test_compare_refuses_a_manifest_generated_on_another_set(self):
        manifest = self.root / 'manifest.json'
        manifest.write_text(json.dumps({'spell_dbc_sha256': CLIENT_SHA, 'scenarios': []}), encoding='utf-8')
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            with self.assertRaises(DbcSetMismatch):
                evaluate(manifest, self.root)

    def test_verdicts_record_the_set_and_the_build_of_their_verdicts(self):
        out = self.root / 'out'
        out.mkdir()
        stamped = [replace(value(ARGENT_BLADE), server_commit='801527e9aaa4', runs=['r1'])]
        path = write_verdicts({**CLASS, 'spell_dbc_sha256': SERVER_SHA}, out / 'manifest.json', self.root / 'results',
                              stamped, out)
        document = json.loads(path.read_text(encoding='utf-8'))
        self.assertEqual((document['spell_dbc_sha256'], document['build'], document['server_commit']),
                         (SERVER_SHA, BUILD, '801527e9aaa4'))
        mixed = stamped + [replace(value(SACRED_SWING), build=OTHER_BUILD)]
        document = json.loads(write_verdicts(CLASS, out / 'manifest.json', self.root / 'results', mixed,
                                             out).read_text(encoding='utf-8'))
        self.assertIsNone(document['build'])


class BuildRefusalTest(unittest.TestCase):
    CLAUSES = [claim('deals extra damage', f'{ARGENT_BLADE} effect_value #0')]

    def test_a_proof_from_another_build_is_refused(self):
        with self.assertRaisesRegex(EvidenceError, 'another build'):
            clause_coverage(self.CLAUSES, [value(ARGENT_BLADE)], OTHER_BUILD)

    def test_an_alert_from_another_build_is_refused_too(self):
        verdicts = [value(ARGENT_BLADE), replace(value(SACRED_SWING, 'alert'), build=OTHER_BUILD)]
        with self.assertRaisesRegex(EvidenceError, f'1 verdicts come from another build than {BUILD}.*{SACRED_SWING}'):
            clause_coverage(self.CLAUSES, verdicts, BUILD)

    def test_a_verdict_without_a_build_is_refused(self):
        with self.assertRaisesRegex(EvidenceError, 'another build'):
            clause_coverage(self.CLAUSES, [replace(value(ARGENT_BLADE), build=None)], BUILD)
        with self.assertRaisesRegex(EvidenceError, 'no single build'):
            clause_coverage(self.CLAUSES, [value(ARGENT_BLADE)], None)

    def test_the_same_build_is_judged(self):
        result = clause_coverage(self.CLAUSES, [value(ARGENT_BLADE)], BUILD)
        self.assertEqual((result.proven, result.not_measured), (1, []))

    def test_a_not_measured_read_is_unproven_and_listed(self):
        result = clause_coverage(self.CLAUSES, [value(ARGENT_BLADE, NOT_MEASURED)], BUILD)
        self.assertEqual((result.proven, result.not_measured), (0, [f'{ARGENT_BLADE} effect_value #0']))
        self.assertEqual([status for _, status in result.evidence], [UNPROVEN])
        self.assertIn(f'  {ARGENT_BLADE} effect_value #0', clause_coverage_lines(result))

    def test_spell_coverage_refuses_a_set_holding_another_build(self):
        root = Path(tempfile.mkdtemp(prefix='conformance-build-'))
        self.addCleanup(shutil.rmtree, root)
        before, after = root / 'before', root / 'after'
        for directory in (before, after):
            directory.mkdir()
            write_verdicts(CLASS, directory / 'manifest.json', root / 'stamp', [value(ARGENT_BLADE)], directory)
        self.assertTrue(write_coverage(before, after, root / 'out').is_file())
        header, verdicts = read_verdicts(after)
        document = json.loads((after / 'verdicts.json').read_text(encoding='utf-8'))
        document['verdicts'][0]['build'] = OTHER_BUILD
        (after / 'verdicts.json').write_text(json.dumps(document), encoding='utf-8')
        with self.assertRaisesRegex(EvidenceError, 'another build'):
            write_coverage(before, after, root / 'out')
        self.assertEqual(main(['coverage', '--before', str(before), '--after', str(after)]), DIFF_EXIT)


def declared(text, *claims, spell=ARGENT_BLADE):
    return {'spell': spell, 'clause': text, 'kind': 'claim',
            'claims': [{'claim': words, 'labels': list(labels)} for words, *labels in claims]}


DUTY_CALLS_TEXT = 'increases your damage dealt and movement speed by $560834s1%'


class DeclaredClaimsTest(unittest.TestCase):
    def test_seeded_clause_proven_by_one_of_its_two_claims_is_unproven(self):
        verdicts = [value(ARGENT_BLADE)]
        partial = [declared(DUTY_CALLS_TEXT, ('damage dealt', f'{ARGENT_BLADE} effect_value #0'), ('movement speed',))]
        statuses, result = evidence_of(partial, verdicts)
        self.assertEqual((statuses, result.proven, result.total), ([UNPROVEN], 0, 1))
        self.assertEqual(result.claim_evidence, [[DATA, UNPROVEN]])
        self.assertEqual(evidence_of([claim(DUTY_CALLS_TEXT, f'{ARGENT_BLADE} effect_value #0')], verdicts)[0], [DATA])

    def test_every_claim_proven_closes_the_clause(self):
        clauses = [declared('deals damage for $d', ('deals damage', f'{ARGENT_BLADE} hit_mean'),
                            ('for $d', f'{ARGENT_BLADE} effect_value #0'))]
        statuses, result = evidence_of(clauses, [hit(ARGENT_BLADE), value(ARGENT_BLADE)])
        self.assertEqual((statuses, result.proven, result.behaviour, result.data), ([DATA], 1, 0, 1))
        self.assertEqual(result.claim_evidence, [[BEHAVIOUR, DATA]])

    def test_seeded_mixed_proof_is_data_and_every_claim_in_game_is_behaviour(self):
        mixed = declared('deals damage for $d', ('deals damage', f'{ARGENT_BLADE} hit_mean'),
                         ('for $d', f'{ARGENT_BLADE} effect_value #0'))
        in_game = declared('deals damage for $d', ('deals damage', f'{ARGENT_BLADE} hit_mean'),
                           ('for $d', f'{ARGENT_BLADE} behaviour_expiry'))
        verdicts = [hit(ARGENT_BLADE), value(ARGENT_BLADE),
                    judged(f'{ARGENT_BLADE} behaviour_expiry', BEHAVIOUR_EXPIRY, 'aura')]
        statuses, result = evidence_of([mixed, in_game], verdicts)
        self.assertEqual(statuses, [DATA, BEHAVIOUR])
        self.assertEqual((result.behaviour, result.data), (1, 1))
        with mock.patch('coverage.claims_evidence',
                        lambda found: UNPROVEN if UNPROVEN in found else BEHAVIOUR if BEHAVIOUR in found else DATA):
            self.assertEqual(evidence_of([mixed, in_game], verdicts)[0], [BEHAVIOUR, BEHAVIOUR])

    def test_seeded_alert_on_one_claim_leaves_the_clause_unproven(self):
        clauses = [declared('deals damage for $d', ('deals damage', f'{ARGENT_BLADE} hit_mean'),
                            ('for $d', f'{ARGENT_BLADE} effect_value #0'))]
        statuses, _ = evidence_of(clauses, [hit(ARGENT_BLADE), value(ARGENT_BLADE, 'alert')])
        self.assertEqual(statuses, [UNPROVEN])

    def test_a_claim_promises_a_stat_by_its_own_words(self):
        verdicts = [judged('1 e0 armor', PASSIVE_DELTA, 'armor'), judged('1 e1 armor', PASSIVE_DELTA, 'armor')]
        clauses = [declared('increases your armor and damage dealt', ('armor', '1 e0 armor'),
                            ('damage dealt', '1 e1 armor'))]
        self.assertEqual(evidence_of(clauses, verdicts)[1].claim_evidence, [[BEHAVIOUR, DATA]])

    def test_undeclared_entries_keep_one_claim_of_their_labels(self):
        _, result = evidence_of([claim('deals damage', f'{ARGENT_BLADE} hit_mean')], [hit(ARGENT_BLADE)])
        self.assertEqual(result.claim_evidence, [[BEHAVIOUR]])

    def test_malformed_declarations_are_refused(self):
        cases = {'clause labels': {**declared('x', ('a', 'l1'), ('b', 'l2')), 'labels': ['l1']},
                 'at least 2': declared('x', ('a', 'l1')),
                 'not a claim entry': {**declared('x', ('a', 'l1'), ('b', 'l2')), 'kind': 'no_claim'},
                 'a claim is': {**declared('x', ('a', 'l1')), 'claims': [{'claim': 'a', 'labels': []}, 'b']}}
        for message, clause in cases.items():
            with self.subTest(message=message), self.assertRaisesRegex(EvidenceError, message):
                clause_coverage([clause], [], BUILD)

    def test_an_unproven_declared_clause_lists_each_claim_status(self):
        result = clause_coverage([declared(DUTY_CALLS_TEXT, ('damage dealt', f'{ARGENT_BLADE} effect_value #0'),
                                           ('movement speed',))], [value(ARGENT_BLADE)], BUILD)
        lines = clause_coverage_lines(result)
        self.assertIn("    claim 'damage dealt': data (labels ['807268 effect_value #0'])", lines)
        self.assertIn("    claim 'movement speed': unproven (labels [])", lines)

    def test_every_declared_clause_of_the_class_ledgers_is_well_formed(self):
        for path in sorted(Path(__file__).parent.joinpath('classes').glob('*_clauses.json')):
            with self.subTest(ledger=path.name):
                require_claims(load_clauses(path))


def gapped(text, *agents, ruling=None, labels=()):
    gap = {'reason': 'no fixture forces an off-hand swing',
           'attempts': [{'agent': agent, 'report': f'round/{agent}.md'} for agent in agents]}
    if ruling:
        gap['owner_acceptance'] = {'ruling': ruling}
    return {**claim(text, *labels), TOOL_GAP: gap}


class ToolGapTest(unittest.TestCase):
    def test_one_agents_attempt_is_a_pending_gap_counted_unresolved(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a'), claim('open')], [], BUILD)
        self.assertEqual((result.accepted_tool_gaps, result.pending_tool_gaps, result.resolved), (0, 1, 0))
        self.assertEqual([state for _, state in result.tool_gaps], [TOOL_GAP_PENDING])

    def test_a_second_attempt_by_another_agent_resolves_the_gap(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a', 'arm-b')], [], BUILD)
        self.assertEqual((result.proven, result.accepted_tool_gaps, result.resolved), (0, 1, 1))

    def test_two_attempts_by_the_same_agent_stay_pending(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a', ' arm-a')], [], BUILD)
        self.assertEqual(result.pending_tool_gaps, 1)
        with mock.patch('coverage.MIN_TOOL_GAP_AGENTS', 1):
            seeded = clause_coverage([gapped('off-hand swings trigger', 'arm-a', 'arm-a')], [], BUILD)
        self.assertNotEqual(seeded.pending_tool_gaps, 1)

    def test_an_owner_acceptance_resolves_a_single_attempt(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a', ruling='owner-rulings.md#gaps')], [],
                                 BUILD)
        self.assertEqual((result.accepted_tool_gaps, result.resolved), (1, 1))

    def test_a_proven_clause_is_not_a_tool_gap(self):
        result = clause_coverage([gapped('extra', 'arm-a', labels=(f'{ARGENT_BLADE} effect_value #0',))],
                                 [value(ARGENT_BLADE)], BUILD)
        self.assertEqual((result.proven, result.tool_gaps, result.resolved), (1, [], 1))

    def test_a_malformed_tool_gap_is_refused(self):
        bad = [{**claim('x'), TOOL_GAP: {'reason': 'r', 'attempts': []}},
               {**claim('x'), TOOL_GAP: {'attempts': [{'agent': 'a', 'report': 'r'}]}},
               {**claim('x'), TOOL_GAP: {'reason': 'r', 'attempts': [{'agent': 'a'}]}},
               {**gapped('x', 'a'), 'kind': 'no_claim'},
               {**gapped('x', 'a'), TOOL_GAP: {**gapped('x', 'a')[TOOL_GAP], 'owner_acceptance': {}}}]
        for clause in bad:
            with self.subTest(clause=clause), self.assertRaises(EvidenceError):
                clause_coverage([clause], [], BUILD)

    def test_the_report_counts_both_states_and_lists_the_gaps(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a'),
                                  gapped('cone of 8 yds', 'arm-a', 'arm-b')], [], BUILD)
        lines = clause_coverage_lines(result)
        self.assertIn('tool gaps pending (one agent\'s attempt only, counted unresolved): 1', lines)
        self.assertIn('clauses resolved (proven or accepted tool gap): 1 of 2 (50.0%)', lines)
        self.assertIn(f'  spell {ARGENT_BLADE}: cone of 8 yds: {TOOL_GAP_ACCEPTED} (no fixture forces an off-hand '
                      f'swing; attempts by arm-a, arm-b)', lines)

    def test_fragment_rows_carry_the_gap_and_its_state(self):
        result = clause_coverage([gapped('off-hand swings trigger', 'arm-a')], [], BUILD)
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            entries = fragment_entries(result, {'spell_dbc_sha256': SERVER_SHA, 'results': 'r'})
        self.assertEqual([(entry['evidence'], entry['tool_gap_state']) for entry in entries],
                         [(UNPROVEN, TOOL_GAP_PENDING)])
        self.assertEqual(entries[0][TOOL_GAP]['attempts'][0]['agent'], 'arm-a')


def routeless(text, *agents, labels=(f'{ARGENT_BLADE} effect_value #0',)):
    declared = {'reason': 'a 180 s cooldown leaves no cast-timing pair in one scenario',
                'attempts': [{'agent': agent, 'report': f'round/{agent}.md'} for agent in agents]}
    return {**claim(text, *labels), NO_BEHAVIOUR_ROUTE: declared}


class NoBehaviourRouteTest(unittest.TestCase):
    def test_seeded_one_agent_keeps_the_clause_open_and_a_second_agent_closes_it(self):
        pending = clause_coverage([routeless('reduces the cooldown', 'author')], [value(ARGENT_BLADE)], BUILD)
        terminal = clause_coverage([routeless('reduces the cooldown', 'author', 'route')], [value(ARGENT_BLADE)],
                                   BUILD)
        self.assertEqual([state for _, state in pending.no_routes], [NO_ROUTE_PENDING])
        self.assertEqual((pending.data, pending.terminal_no_route, pending.open_data), (1, 0, 1))
        self.assertEqual([state for _, state in terminal.no_routes], [NO_ROUTE_TERMINAL])
        self.assertEqual((terminal.data, terminal.terminal_no_route, terminal.open_data, terminal.resolved),
                         (1, 1, 0, 1))
        with mock.patch('coverage.MIN_NO_ROUTE_AGENTS', 1):
            seeded = clause_coverage([routeless('reduces the cooldown', 'author')], [value(ARGENT_BLADE)], BUILD)
        self.assertEqual(seeded.terminal_no_route, 1)

    def test_two_attempts_by_the_same_agent_stay_pending(self):
        result = clause_coverage([routeless('reduces the cooldown', 'author', ' author')], [value(ARGENT_BLADE)],
                                 BUILD)
        self.assertEqual(result.terminal_no_route, 0)

    def test_an_unproven_or_behaviour_clause_is_not_closed(self):
        unproven = clause_coverage([routeless('reduces the cooldown', 'author', 'route')], [], BUILD)
        hit_label = f'{ARGENT_BLADE} hit_mean'
        behaviour = clause_coverage([routeless('deals damage', 'author', 'route', labels=(hit_label,))],
                                    [hit(ARGENT_BLADE)], BUILD)
        self.assertEqual([state for _, state in unproven.no_routes], [NO_ROUTE_NOT_DATA])
        self.assertEqual([state for _, state in behaviour.no_routes], [NO_ROUTE_NOT_DATA])
        self.assertEqual((unproven.terminal_no_route, behaviour.terminal_no_route, behaviour.behaviour), (0, 0, 1))

    def test_a_malformed_declaration_is_refused(self):
        bad = [{**claim('x'), NO_BEHAVIOUR_ROUTE: {'reason': 'r', 'attempts': []}},
               {**claim('x'), NO_BEHAVIOUR_ROUTE: {'attempts': [{'agent': 'a', 'report': 'r'}]}},
               {**claim('x'), NO_BEHAVIOUR_ROUTE: {'reason': ' ', 'attempts': [{'agent': 'a', 'report': 'r'}]}},
               {**routeless('x', 'a'), 'kind': 'no_claim'},
               {**routeless('x', 'a'), TOOL_GAP: gapped('x', 'a')[TOOL_GAP]}]
        for clause in bad:
            with self.subTest(clause=clause), self.assertRaises(EvidenceError):
                clause_coverage([clause], [value(ARGENT_BLADE)], BUILD)

    def test_the_report_shows_the_terminal_column_and_lists_the_clauses(self):
        result = clause_coverage([routeless('reduces the cooldown', 'author', 'route'), claim('open')],
                                 [value(ARGENT_BLADE)], BUILD)
        lines = clause_coverage_lines(result)
        self.assertIn('data conformant, no behaviour route (terminal: a stated reason and attempts by two agents, '
                      'closed, not resolved): 1 of 2 (50.0%)', lines)
        self.assertIn('data conformant, still open: 0 of 2 (0.0%)', lines)
        self.assertIn(f'  spell {ARGENT_BLADE}: reduces the cooldown: {NO_ROUTE_TERMINAL} (a 180 s cooldown leaves '
                      f'no cast-timing pair in one scenario; attempts by author, route)', lines)

    def test_fragment_rows_carry_the_declaration_and_its_state(self):
        result = clause_coverage([routeless('reduces the cooldown', 'author', 'route')], [value(ARGENT_BLADE)], BUILD)
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            entries = fragment_entries(result, {'spell_dbc_sha256': SERVER_SHA, 'results': 'r'})
        self.assertEqual([(entry['evidence'], entry['no_behaviour_route_state']) for entry in entries],
                         [(DATA, NO_ROUTE_TERMINAL)])


class FragmentTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix='conformance-fragment-'))
        self.result = clause_coverage([claim('deals damage', f'{ARGENT_BLADE} hit_mean'),
                                       claim('extra', f'{ARGENT_BLADE} effect_value #0'), claim('open')],
                                      [hit(ARGENT_BLADE), value(ARGENT_BLADE)], BUILD)

    def tearDown(self):
        shutil.rmtree(self.root)

    def test_entries_carry_the_computed_evidence_and_the_set(self):
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            entries = fragment_entries(self.result, {'spell_dbc_sha256': SERVER_SHA, 'results': 'r'})
            path = write_fragment(self.root / 'fragment.json', entries)
            self.assertEqual([entry['evidence'] for entry in read_fragment(path)], [BEHAVIOUR, DATA, UNPROVEN])
        self.assertEqual({entry['spell_dbc_sha256'] for entry in entries}, {SERVER_SHA})
        with self.assertRaises(FileExistsError):
            write_fragment(path, entries)

    def test_an_unproven_declared_clause_gives_one_row_per_claim(self):
        result = clause_coverage([declared(DUTY_CALLS_TEXT, ('damage dealt', f'{ARGENT_BLADE} effect_value #0'),
                                           ('movement speed',))], [value(ARGENT_BLADE)], BUILD)
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            entries = fragment_entries(result, {'spell_dbc_sha256': SERVER_SHA, 'results': 'r'})
        self.assertEqual([(entry['claim'], entry['labels'], entry['evidence']) for entry in entries],
                         [('damage dealt', [f'{ARGENT_BLADE} effect_value #0'], DATA),
                          ('movement speed', [], UNPROVEN)])
        self.assertEqual({entry['clause'] for entry in entries}, {DUTY_CALLS_TEXT})
        self.assertFalse(any('claims' in entry for entry in entries))

    def test_a_proven_declared_clause_gives_one_row_with_its_claims(self):
        result = clause_coverage([declared('deals damage for $d', ('deals damage', f'{ARGENT_BLADE} hit_mean'),
                                           ('for $d', f'{ARGENT_BLADE} effect_value #0'))],
                                 [hit(ARGENT_BLADE), value(ARGENT_BLADE)], BUILD)
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            entries = fragment_entries(result, {'spell_dbc_sha256': SERVER_SHA, 'results': 'r'})
        self.assertEqual([entry['evidence'] for entry in entries], [DATA])
        self.assertEqual([claim['evidence'] for claim in entries[0]['claims']], [BEHAVIOUR, DATA])

    def test_verdicts_of_another_set_give_no_fragment(self):
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            for sha in (CLIENT_SHA, None):
                with self.assertRaises(DbcSetMismatch):
                    fragment_entries(self.result, {'spell_dbc_sha256': sha, 'results': 'r'})

    def test_a_fragment_of_another_set_is_refused(self):
        path = self.root / 'fragment.json'
        path.write_text(json.dumps([{**claim('x'), 'evidence': DATA, 'spell_dbc_sha256': CLIENT_SHA}]),
                        encoding='utf-8')
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA):
            with self.assertRaisesRegex(EvidenceError, CLIENT_SHA):
                read_fragment(path)

    def test_coverage_command_prints_both_counts_and_writes_the_fragment(self):
        before = self.root / 'before'
        after = self.root / 'after'
        for directory in (before, after):
            directory.mkdir()
            write_verdicts({**CLASS, 'spell_dbc_sha256': SERVER_SHA}, directory / 'manifest.json', self.root / 'r',
                           [hit(ARGENT_BLADE), value(ARGENT_BLADE)], directory)
        ledger = self.root / 'ledger.json'
        ledger.write_text(json.dumps([claim('deals damage', f'{ARGENT_BLADE} hit_mean'),
                                      claim('extra', f'{ARGENT_BLADE} effect_value #0')]), encoding='utf-8')
        fragment = self.root / 'fragment.json'
        with mock.patch('profile.server_spell_dbc_sha256', return_value=SERVER_SHA), \
                mock.patch('sys.stdout') as stdout:
            code = main(['coverage', '--before', str(before), '--after', str(after), '--clauses', str(ledger),
                         '--fragment', str(fragment)])
        printed = ''.join(call.args[0] for call in stdout.write.call_args_list)
        self.assertEqual(code, 0)
        self.assertIn('behaviour proven: 1 of 2 (50.0%)', printed)
        self.assertIn('data conformant: 1 of 2 (50.0%)', printed)
        self.assertEqual([entry['evidence'] for entry in json.loads(fragment.read_text(encoding='utf-8'))],
                         [BEHAVIOUR, DATA])

    def test_coverage_command_refuses_unknown_checks(self):
        after = self.root / 'after'
        after.mkdir()
        write_verdicts(CLASS, after / 'manifest.json', self.root / 'r', [judged('1 gap', 'behaviour_not_in_the_table')],
                       after)
        ledger = self.root / 'ledger.json'
        ledger.write_text('[]', encoding='utf-8')
        with mock.patch('sys.stderr'):
            self.assertEqual(main(['coverage', '--before', str(after), '--after', str(after), '--clauses',
                                   str(ledger)]), DIFF_EXIT)


if __name__ == '__main__':
    unittest.main()
