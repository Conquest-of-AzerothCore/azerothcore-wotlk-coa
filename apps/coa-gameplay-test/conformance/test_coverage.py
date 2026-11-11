import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest import mock

from compare import Verdict, evaluate, write_verdicts
from conformance import DIFF_EXIT, main
from coverage import COVERAGE_FILE, clause_coverage, coverage, write_coverage
from hits import NEVER_CAST, NO_HIT_EFFECT, UNMODELLED
from passives import PASSIVE_DELTA
from procs import PROC_CHECK
from profile import DbcSetMismatch, load_class_file, server_dbc_dir, spell_dbc_sha256
from triggers import TRIGGER_CHECK

CLASS = {'class_id': 19, 'class_name': 'Templar', 'level': 60}
CLASS_AURA = 887007
ARGENT_BLADE = 807268
SACRED_SWING = 572769
SERENDIPITY = 300929
FERVENT_CASTIGATION = 707606
SERVER_SHA = 'a' * 64
CLIENT_SHA = 'b' * 64


def verdict(label, status, spell, scenario, check, explanation=''):
    measured = None if status in ('unmodelled', 'unreadable') else 1.0
    return Verdict(label, status, measured, measured, measured, measured, explanation, scenario, spell, spell, check)


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
        proven, total, unproven = clause_coverage(clauses, [value(ARGENT_BLADE)])
        self.assertEqual((proven, total, unproven), (1, 1, []))

    def test_a_tolerated_verdict_counts_as_proven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value #0']}]
        proven, _, unproven = clause_coverage(clauses, [value(ARGENT_BLADE, 'tolerated')])
        self.assertEqual((proven, unproven), (1, []))

    def test_an_alerting_label_leaves_the_claim_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value #0']}]
        proven, total, unproven = clause_coverage(clauses, [value(ARGENT_BLADE, 'alert')])
        self.assertEqual((proven, total), (0, 1))
        self.assertEqual(unproven[0]['clause'], 'deals extra damage')

    def test_a_claim_with_no_labels_is_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim', 'labels': []}]
        proven, total, unproven = clause_coverage(clauses, [value(ARGENT_BLADE)])
        self.assertEqual((proven, total, len(unproven)), (0, 1, 1))

    def test_no_claim_entries_are_excluded_from_the_total(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'Level 10 Passive', 'kind': 'no_claim',
                   'reason': 'a level-gate label', 'labels': []}]
        proven, total, unproven = clause_coverage(clauses, [])
        self.assertEqual((proven, total, unproven), (0, 0, []))

    def test_an_ordinal_free_label_matches_the_real_ordinal_suffixed_verdict(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #1', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        proven, total, unproven = clause_coverage(clauses, verdicts)
        self.assertEqual((proven, total, unproven), (1, 1, []))

    def test_an_ordinal_free_label_needs_every_matching_occurrence_conformant(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage twice', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #1', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value'),
                   verdict(f'{ARGENT_BLADE} effect_value 801832e1 #2', 'alert', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        proven, total, unproven = clause_coverage(clauses, verdicts)
        self.assertEqual((proven, total), (0, 1))

    def test_an_ordinal_free_label_with_no_matching_verdict_is_unproven(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1']}]
        proven, total, unproven = clause_coverage(clauses, [])
        self.assertEqual((proven, total), (0, 1))

    def test_a_label_already_carrying_an_ordinal_is_not_expanded(self):
        clauses = [{'spell': ARGENT_BLADE, 'clause': 'deals extra damage', 'kind': 'claim',
                   'labels': [f'{ARGENT_BLADE} effect_value 801832e1 #1']}]
        verdicts = [verdict(f'{ARGENT_BLADE} effect_value 801832e1 #10', 'ok', ARGENT_BLADE,
                           f'conformance-templar-value-{ARGENT_BLADE}', 'effect_value')]
        proven, total, unproven = clause_coverage(clauses, verdicts)
        self.assertEqual((proven, total), (0, 1))


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

    def test_verdicts_record_the_set_of_their_manifest(self):
        out = self.root / 'out'
        out.mkdir()
        path = write_verdicts({**CLASS, 'spell_dbc_sha256': SERVER_SHA}, out / 'manifest.json', self.root / 'results',
                              [value(ARGENT_BLADE)], out)
        self.assertEqual(json.loads(path.read_text(encoding='utf-8'))['spell_dbc_sha256'], SERVER_SHA)


if __name__ == '__main__':
    unittest.main()
