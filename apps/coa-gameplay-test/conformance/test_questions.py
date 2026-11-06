from dataclasses import asdict
from pathlib import Path
import shutil
import tempfile
import unittest

from compare import DbcTooltips, Verdict, compare, tooltip_value_question, write_outputs
from procs import proc_status_expectation, wilson_interval
from profile import DBC_DIR
from questions import (DATA_ISSUE, QUESTIONS_FILE, READINGS_QUESTION, SERVER_BEHAVIOUR, TEXT_QUESTION, TOOLTIP_VALUE,
                       questions, write_questions)
from test_compare import CLASS_FILE, FakeTooltips, Workspace, assert_step, expectation
from test_procs import PROC_KEY, READINGS, proc_expectation, proc_steps, templar_proc
from test_stack import (BASE, BASE_MEANS, PALADIN, PALADIN_MEANS, delta_expectation, dps_expectation, pass_steps,
                        source_expectation)
from test_triggers import templar_trigger
from tooltip import Displayed
from triggers import BASELINE_ATTEMPTS, TRIGGER_CHECK, TRIGGER_TRIALS, trigger_label, trigger_measurements
from values import Expectation

SCOURGEBANE = 92111
PALADIN_TRAINING_PROC = 504808
BLADE_SERMON = (572548, 572554)
ARGENT_BLADE = 807268
SILVERHAND_INCANTATION = 801465
HEAVENS_FINEST = 806516
HEAVENS_FINEST_STACK = 805390
SCHEDULED = 273
ARGENT_BLADE_TEXT = ('Crush an enemy with argent fervor, dealing $s2% Weapon Damage plus '
                     '${$AP*0.4725+$sph*1.35+$m1+0}, healing you equal to the damage dealt, and unleashes '
                     '|cffffffffScourgebane|r, dealing ${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25} Holy damage.')
ARGENT_BLADE_ENTRY = '${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}'
SILVERHAND_TEXT = ('Chant a silverhand incantation and toss a holy hammer at your target.\r\n\r\nUpon reaching your '
                   'target you deal ${$m1+$ppl1+$AP*2} Holy damage to all nearby enemies.')
SILVERHAND_ENTRY = '${$m1+$ppl1+$AP*2}'


def class_fields():
    fields = {}
    for entry in CLASS_FILE['procs'] + CLASS_FILE['triggers']:
        fields[(entry['aura'], 'SpellName[enUS]')] = entry['name']
        fields[(entry['aura'], 'Description[enUS]')] = entry['tooltip']
    fields.update({(ARGENT_BLADE, 'SpellName[enUS]'): 'Argent Blade',
                   (ARGENT_BLADE, 'Description[enUS]'): ARGENT_BLADE_TEXT,
                   (SILVERHAND_INCANTATION, 'SpellName[enUS]'): 'Silverhand Incantation',
                   (SILVERHAND_INCANTATION, 'Description[enUS]'): SILVERHAND_TEXT,
                   (801832, 'SpellName[enUS]'): 'Scourgebane'})
    return fields


def reader(*values, fields=None):
    return FakeTooltips(values, fields={**class_fields(), **(fields or {})})


def chance_reader():
    return reader(Displayed('$520007h', 20.0, None, 'chance_pct'))


def heavens_finest_expectation():
    model = {'part': 0, 'parts': 1, 'scheduled_attempts': SCHEDULED, 'part_attempts': SCHEDULED,
             'baseline_attempts': BASELINE_ATTEMPTS, 'minimum_trials': TRIGGER_TRIALS, 'per_trigger': 1,
             'trigger': {'action': 'cast', 'spell': ARGENT_BLADE, 'target': 'dummy'},
             'observe_spell': HEAVENS_FINEST_STACK, 'observe_metric': 'spell_cast_count',
             'trial_metric': 'spell_damage_count', 'measurements': trigger_measurements(HEAVENS_FINEST)}
    return Expectation(trigger_label(HEAVENS_FINEST), TRIGGER_CHECK, HEAVENS_FINEST, HEAVENS_FINEST, None,
                       'Damaging abilities', 'trigger rule', model)


def heavens_finest_steps(events):
    labels = trigger_measurements(HEAVENS_FINEST)
    return [assert_step(labels['baseline_trials'], str(BASELINE_ATTEMPTS)), assert_step(labels['without'], '0'),
            assert_step(labels['aura'], '1'), assert_step(labels['trials'], str(BASELINE_ATTEMPTS + SCHEDULED)),
            assert_step(labels['events'], str(events))]


def status_entry(workspace, aura):
    (workspace.root / 'out').mkdir(parents=True, exist_ok=True)
    workspace.scenarios.append({'key': f'conformance-templar-proc-{aura}', 'file': None, 'sha256': None,
                                'kind': 'proc', 'spell_id': aura, 'spell_name': templar_proc(aura)['name'],
                                'rank_id': aura, 'tokens': [],
                                'expectations': [asdict(proc_status_expectation(templar_proc(aura)))]})


class QuestionTest(unittest.TestCase):
    def setUp(self):
        self.workspace = Workspace()
        self.out = Path(tempfile.mkdtemp(prefix='conformance-questions-'))

    def tearDown(self):
        self.workspace.close()
        shutil.rmtree(self.out, ignore_errors=True)

    def status_entry(self, aura):
        status_entry(self.workspace, aura)

    def verdicts(self, tooltips):
        manifest, results = self.workspace.manifest()
        return compare(manifest, results, tooltips=tooltips)

    def scourgebane_verdicts(self):
        self.workspace.scenario(PROC_KEY, 'proc', [proc_expectation(minimum=1699, readings=READINGS)],
                                steps=proc_steps(2554, 525, strikes=525), spell=SCOURGEBANE, name='Scourgebane',
                                rank=SCOURGEBANE)
        return self.verdicts(chance_reader())

    def unreadable_verdicts(self, spell, name, entry, tooltips):
        label = f'{spell} effect_value #0'
        unreadable = Expectation(label, 'effect_value', spell, spell, None, entry, 'unreadable: ' + entry)
        self.workspace.scenario(f'conformance-templar-value-{spell}', 'value', [unreadable], steps=[], spell=spell,
                                name=name, rank=spell)
        return self.verdicts(tooltips)

    def test_one_entry_per_tooltip(self):
        for aura in BLADE_SERMON:
            self.status_entry(aura)
        items = questions(self.verdicts(reader()), reader())
        self.assertEqual(len(items), 1)
        self.assertEqual(items[0].spells, tuple((aura, 'Blade Sermon') for aura in BLADE_SERMON))
        self.assertEqual(items[0].kind, TEXT_QUESTION)
        self.assertEqual(items[0].question, templar_proc(BLADE_SERMON[0])['question'])

    def test_readings_carry_numbers(self):
        items = questions(self.scourgebane_verdicts(), chance_reader())
        self.assertEqual(len(items), 1)
        item = items[0]
        self.assertEqual((item.kind, item.spells, item.measured), (READINGS_QUESTION, ((SCOURGEBANE, 'Scourgebane'),),
                                                                   525.0))
        self.assertEqual([reading['name'] for reading in item.readings],
                         ['auto attacks only', 'every direct damage event'])
        for reading, trials, status in zip(item.readings, (2554, 3079), ('ok', 'alert')):
            self.assertEqual((reading['procs'], reading['trials'], reading['status']), (525.0, trials, status))
            self.assertAlmostEqual(reading['rate'], 525 / trials)
            self.assertEqual((reading['low'], reading['high']), wilson_interval(525, trials))
        self.assertIn('20%', item.question)
        self.assertIn('Direct damage dealt', item.question)
        self.assertEqual(item.labels, ('92111 proc_rate',))

    def test_text_question_uses_the_class_file(self):
        self.status_entry(PALADIN_TRAINING_PROC)
        items = questions(self.verdicts(reader()), reader())
        self.assertEqual([item.question for item in items], [templar_proc(PALADIN_TRAINING_PROC)['question']])
        self.assertEqual(items[0].spells, ((PALADIN_TRAINING_PROC, 'Paladin Training'),))

    def test_markdown_entry(self):
        listed = self.scourgebane_verdicts()
        passing = Verdict('705295 trigger_count', 'ok', 273.0, 273.0, 272.0, 274.0, 'ok', 'key', 705295, 705295,
                          TRIGGER_CHECK, {'question': {'kind': SERVER_BEHAVIOUR, 'question': 'Never asked?',
                                                       'readings': [], 'measured': 273.0}})
        path = write_questions(questions(listed + [passing], chance_reader()), self.out)
        self.assertEqual(path, self.out / QUESTIONS_FILE)
        lines = path.read_text(encoding='utf-8').splitlines()
        self.assertEqual(lines[0], '# Questions for players')
        start = lines.index('## Scourgebane (92111)')
        entry = lines[start:]
        self.assertIn('> Direct damage dealt now has a $520007h% chance to strike an enemy with Scourgebane, dealing '
                      'an additional $801832s2% Weapon damage plus ${$801832m1*$<scalingbp>+$SP*.25+$AP*.25} '
                      'Holyflame Damage.', entry)
        self.assertTrue(any(line.startswith('- auto attacks only: 525 procs in 2554 trials') for line in entry))
        self.assertTrue(any(line.startswith('- every direct damage event: 525 procs in 3079 trials')
                            for line in entry))
        self.assertTrue(any(line.startswith('Question: With Scourgebane learned') for line in entry))
        self.assertNotIn('Never asked?', '\n'.join(lines))
        self.assertTrue(all(line.isascii() for line in lines))

    def test_undefined_variable_is_a_data_issue(self):
        verdict, = self.unreadable_verdicts(ARGENT_BLADE, 'Argent Blade', ARGENT_BLADE_ENTRY, reader())
        self.assertEqual(verdict.status, 'unreadable')
        item, = questions([verdict], reader())
        self.assertEqual((item.kind, item.spells), (DATA_ISSUE, ((ARGENT_BLADE, 'Argent Blade'),)))
        self.assertIn('$<scalingbp>', item.question)
        self.assertIn('unleashes Scourgebane, dealing ___ Holy damage.', item.question)

    def test_defined_variable_is_no_data_issue(self):
        tooltips = reader(fields={(ARGENT_BLADE, 'SpellDescriptionVariableID'): 182})
        verdict, = self.unreadable_verdicts(ARGENT_BLADE, 'Argent Blade', ARGENT_BLADE_ENTRY, tooltips)
        self.assertEqual(verdict.status, 'unreadable')
        self.assertEqual(questions([verdict], tooltips), [])

    def test_per_level_token_asks_for_the_number_shown(self):
        entry = SILVERHAND_ENTRY + ' [EffectRealPointsPerLevel[0] of spell 801465]'
        verdict, = self.unreadable_verdicts(SILVERHAND_INCANTATION, 'Silverhand Incantation', entry, reader())
        item, = questions([verdict], reader())
        self.assertEqual(item.kind, TOOLTIP_VALUE)
        self.assertIn('Upon reaching your target you deal ___ Holy damage to all nearby enemies.', item.question)
        self.assertIn('$ppl1', item.question)
        self.assertIn('level 60', item.question)
        self.assertEqual(tooltip_value_question('Silverhand Incantation', 60, SILVERHAND_ENTRY, SILVERHAND_TEXT),
                         verdict.detail['question'])

    def test_server_behaviour_is_its_own_section(self):
        self.workspace.scenario('conformance-templar-trigger-806516-part-1', 'trigger', [heavens_finest_expectation()],
                                steps=heavens_finest_steps(150), spell=HEAVENS_FINEST, name="Heaven's Finest",
                                rank=HEAVENS_FINEST)
        manifest, results = self.workspace.manifest()
        verdicts = compare(manifest, results, tooltips=reader())
        self.assertEqual(verdicts[0].status, 'alert')
        item, = questions(verdicts, reader())
        self.assertEqual((item.kind, item.question, item.measured),
                         (SERVER_BEHAVIOUR, templar_trigger(HEAVENS_FINEST)['question'], 150.0))
        write_outputs(manifest, results, verdicts, self.out, tooltips=reader())
        lines = (self.out / QUESTIONS_FILE).read_text(encoding='utf-8').splitlines()
        self.assertLess(lines.index('# Server behaviour to confirm'), lines.index("## Heaven's Finest (806516)"))

    def test_trigger_that_matches_its_tooltip_asks_nothing(self):
        self.workspace.scenario('conformance-templar-trigger-806516-part-1', 'trigger', [heavens_finest_expectation()],
                                steps=heavens_finest_steps(SCHEDULED), spell=HEAVENS_FINEST, name="Heaven's Finest",
                                rank=HEAVENS_FINEST)
        verdicts = self.verdicts(reader())
        self.assertEqual(verdicts[0].status, 'ok')
        self.assertIsNone(verdicts[0].detail)
        self.assertEqual(questions(verdicts, reader()), [])

    def test_talent_readings_ask_the_change_of_a_hit(self):
        for config, index, means, delta in ((BASE, 0, BASE_MEANS, None), (PALADIN, 1, PALADIN_MEANS,
                                                                          delta_expectation())):
            for number, mean in enumerate(means):
                expectations = [dps_expectation(config, index), source_expectation(config, index)]
                expectations += [delta] if delta else []
                self.workspace.scenario(f'conformance-templar-stack-{config}-pass-{number + 1}', 'stack', expectations,
                                        steps=pass_steps(40, mean))
        tooltips = reader(Displayed('$s1', 20.0, 0, 'percent'),
                          fields={(520009, 'SpellName[enUS]'): 'Paladin Training',
                                  (520009, 'Description[enUS]'): 'Increases the damage of Argent Blade by $s1%.'})
        verdict = next(verdict for verdict in self.verdicts(tooltips) if verdict.check == 'talent_delta')
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        self.assertEqual(verdict.detail['config'], PALADIN)
        item, = questions([verdict], tooltips)
        self.assertEqual([(reading['name'], reading['expected'], reading['status']) for reading in item.readings],
                         [('multiplies', 20.0, 'ok'), ('adds', 25.0, 'alert')])
        self.assertIn('Argent Blade', item.question)
        self.assertIn('20% or by 25%', item.question)

    def test_opposite_sign_asks_whether_the_value_raises_or_lowers(self):
        label = '1001 effect_value e0 #0'
        token = Displayed('${$m1*2}', 10.0, 0, 'flat')
        value = expectation(label, 'effect_value', token.text, 'read flat', 0)
        self.workspace.scenario('conformance-templar-value-1001', 'value', [value], [token.text],
                                [assert_step(label, '-10')])
        tooltips = reader(token, fields={(1001, 'SpellName[enUS]'): 'Test Strike',
                                         (1001, 'Description[enUS]'): 'Deals ${$m1*2} damage.'})
        verdict, = self.verdicts(tooltips)
        self.assertEqual(verdict.status, 'ambiguous_tooltip')
        item, = questions([verdict], tooltips)
        self.assertEqual(item.kind, READINGS_QUESTION)
        self.assertEqual([reading['expected'] for reading in item.readings], [10.0, -10.0])
        self.assertIn('-10', item.question)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClientTooltipTest(unittest.TestCase):
    def test_blade_sermon_entries_share_their_client_tooltip(self):
        tooltips = DbcTooltips(DBC_DIR)
        workspace = Workspace()
        try:
            for aura in BLADE_SERMON:
                status_entry(workspace, aura)
            manifest, results = workspace.manifest()
            item, = questions(compare(manifest, results, tooltips=tooltips), tooltips)
        finally:
            workspace.close()
        self.assertEqual([spell for spell, _ in item.spells], list(BLADE_SERMON))

    def test_class_file_questions_quote_client_numbers(self):
        tooltips = DbcTooltips(DBC_DIR)
        self.assertEqual(tooltips.spell_field(HEAVENS_FINEST_STACK, 'StackAmount'), 6)
        self.assertIn('12 sec, stacking 6 times', templar_trigger(HEAVENS_FINEST)['question'])
        self.assertIn('8%', templar_proc(PALADIN_TRAINING_PROC)['question'])
        self.assertEqual(tooltips.spell_field(PALADIN_TRAINING_PROC, 'ProcChance'), 8)


if __name__ == '__main__':
    unittest.main()
