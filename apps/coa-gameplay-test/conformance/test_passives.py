from collections import Counter
import json
from pathlib import Path
import shutil
import struct
import sys
import tempfile
import unittest

import compare
from classes import PROGRESSION_HEADER as HEADER, ClassSpell, class_spells, table_rows
from passives import (ALIASED_REASON_MARKER, AURA_STATE_METRIC, FAMILIES, MAX_SPELLMOD, PARRY_CHANCE, PASSIVE_DELTA,
                      PHRASES, STAT_EXACT_METRIC, STAT_METRIC, MetricPlan, NotModelled, PassiveTarget,
                      active_class_ranks, classify, crit_plans, effect_override, family_of, literal_token,
                      named_targets, own_token, passive_effects, passive_scenario, reference_spell, stat_after_token)
from procs import proc_scenario
from profile import CASTER, load_class_file, spell_power_label, stat_label
from tooltip import Displayed, Records
from values import TARGET, dataset
import schemas

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

DBC_DIR = Path('/srv/coa/server-data/dbc')

TEMPLAR_CLASS_ID = 19
TEMPLAR_PASSIVES = 145
TEMPLAR_PASSIVE_EFFECTS = 234
TEMPLAR_FAMILY_COUNTS = {'P1': 71, 'P2': 51, 'P3': 9, 'P4': 4, 'P5': 76, 'P6': 21, 'P7': 2}
TEMPLAR_FAMILY_NAME = 25
LEVEL = 60

PALADIN_TRAINING = 520009
ARGENT_BLADE_AT_60 = 807268
RIGHTEOUS_LUNGE_AT_60 = 570233
HOLY_MASTER = 504810
PATIENCE = 712678
INTERDICT = 560116
SACRED_RESTRAINT = 102208
LIBERTY = 705266
LIBRAMS = (801461, 801466, 805423)
CONDEMNATION = 704175
OATH_CONDEMN = 804922
GRACEFUL_FIGHTER = 705303
FINAL_PRAYER = 705268
JUSTICAR_OF_THE_LIGHT = 707663
JUSTICE = 712437
SPIRITUAL_ABDICATOR = 803219
AGGRAMARS_RAGE = 561346
STURDY = 681009
BLESSED_PADDING = 301311
CALL_OF_THE_MONASTERY = 560550
LIGHTS_CHOSEN = 301310
BLESSED_STRIKES = 704180
CHAKRA_OF_LIGHT = (803159, 803844)
DEEP_SECRETS = 705263
PIOUS_SWEEP = 520034
TEMPLARS_MIGHT = 705291
MARK_OF_AGGRAMAR = 804928
FURY_OF_AGGRAMAR = 801480
TRANQUIL_CIRCLE = 801205
TRANQUIL_CIRCLE_INCOMPLETE = 524667
PIOUS_SWEEP_DEV_SPELL = 521052
WRONGLY_NAMED_CHASTISE = 503141
TESTAMENT_OF_FAITH = 501606
TESTAMENT_OF_FORTITUDE = 500678
JUDICATOR = 706359
BELLS_OF_LIGHT = 801204
ASCETIC_ABDICATION = 500699
FINESSE = 705271
PIOUS = 706431
SERENDIPITY = 300929
SACRED_STYLE = 705278
TEMPLE_GUARDIAN_HEAL = 803792
RECKONING_AT_60 = 572741
CRUSADERS_BRAND = 300513
MARTIAL_TRAINING = 806525
SCARLET_HAMMER = (500752, 807035)
CHASTISE = 503141
UPHEAVE = 520442
PURE_FOCUS = 705253
SCOURGEBANE_IN_MASK = 520007
ARGENT_KNIGHT = 300512
RIGHTEOUS_TEMPEST = 807274
RIGHTEOUS_TEMPEST_HELPERS = (570205,)
GRACE_OF_AMANTHUL = 301059
SACRED_SWING_AT_60 = 572769
SACRED_CANDLE = 300501
CONDEMN_AT_60 = 567539
FORTIFIED_BODY = 300515
HOLY_UPHEAVAL = 572547
RIGHTEOUS_UPHEAVAL_AT_60 = 807764
RIGHTEOUS_UPHEAVAL_GENERIC_RANK = 572027
LIGHTKEEPER = 560835
LIGHTKEEPER_PARRY = 561016
LIGHTKEEPER_BURST = 561277
MIGHT_OF_AGGRAMAR = 803163
MIGHT_OF_AGGRAMAR_STACK = 803164
STAT_COUNT = 5
LIBERTY_OP = 11
SPELL_MODIFIER_BASE = 1000
CONDEMNATION_OP = 40
MODEL_KEYS = {'family', 'effect', 'aura', 'metric', 'fields', 'relation', 'source_label', 'before_label',
              'after_label', 'exact_before_label', 'exact_after_label', 'aura_state_label', 'target', 'named',
              'in_mask', 'points', 'judged', 'aura_label'}
MAGIC_SCHOOLS = [1, 2, 3, 4, 5, 6]
NO_NAMED_TARGET = 'unmodelled: the tooltip names none of the spells the class mask affects ('

SPELL_RECORD_BYTES = 936
SPELL_FIELDS = 234
PASSIVE = 0x40
APPLY_AURA = 6
FIXTURE_SPELL = 900001
FIXTURE_AURA = 999
ALIASED_FIXTURE_SPELL = 900002
ALIASED_AURA = 133


def templar_passive(spell_id: int) -> ClassSpell:
    return ClassSpell(spell_id, '', (spell_id,), spell_id, 1, True)


def effect_of(effects, index: int):
    return next(effect for effect in effects if effect.effect == index)


def plan_named(effect, metric: str) -> MetricPlan:
    return next(plan for plan in effect.plans if plan.metric == metric)


def target_ids(effect, named: bool, in_mask: bool) -> set[int]:
    return {target.spell_id for target in effect.targets if target.named == named and target.in_mask == in_mask}


def write_spell_fixture(directory: Path):
    offsets = {column.name: column.offset for column in schemas.registry()['Spell'].columns}
    strings = b'\0'
    name_offset = len(strings)
    strings += b'Fixture Passive\0'
    description_offset = len(strings)
    strings += b'Grants $s1 of something.\0'
    row = bytearray(SPELL_RECORD_BYTES)
    for field, value in (('Id', FIXTURE_SPELL), ('Attributes', PASSIVE), ('Effect[0]', APPLY_AURA),
                         ('EffectApplyAuraName[0]', FIXTURE_AURA), ('EffectBasePoints[0]', 4),
                         ('EffectDieSides[0]', 1), ('SpellName[enUS]', name_offset),
                         ('Description[enUS]', description_offset), ('SpellFamilyName', TEMPLAR_FAMILY_NAME)):
        struct.pack_into('<i', row, offsets[field], value)
    header = struct.pack('<4s4I', b'WDBC', 1, SPELL_FIELDS, SPELL_RECORD_BYTES, len(strings))
    (directory / 'Spell.dbc').write_bytes(header + bytes(row) + strings)


def write_aliased_token_fixture(directory: Path):
    offsets = {column.name: column.offset for column in schemas.registry()['Spell'].columns}
    strings = b'\0'
    name_offset = len(strings)
    strings += b'Aliased Fixture Passive\0'
    description_offset = len(strings)
    strings += b'Increases your maximum health by $s1%. Also increases your maximum health by $s1%.\0'
    row = bytearray(SPELL_RECORD_BYTES)
    for field, value in (('Id', ALIASED_FIXTURE_SPELL), ('Attributes', PASSIVE),
                         ('Effect[0]', APPLY_AURA), ('EffectApplyAuraName[0]', ALIASED_AURA),
                         ('EffectBasePoints[0]', 5), ('EffectDieSides[0]', 1),
                         ('Effect[1]', APPLY_AURA), ('EffectApplyAuraName[1]', ALIASED_AURA),
                         ('EffectBasePoints[1]', 9), ('EffectDieSides[1]', 1),
                         ('SpellName[enUS]', name_offset), ('Description[enUS]', description_offset),
                         ('SpellFamilyName', TEMPLAR_FAMILY_NAME)):
        struct.pack_into('<i', row, offsets[field], value)
    header = struct.pack('<4s4I', b'WDBC', 1, SPELL_FIELDS, SPELL_RECORD_BYTES, len(strings))
    (directory / 'Spell.dbc').write_bytes(header + bytes(row) + strings)


P5_FIXTURE_SPELL = 900003
P5_FIXTURE_AURA = 42


def write_p5_fixture(directory: Path):
    offsets = {column.name: column.offset for column in schemas.registry()['Spell'].columns}
    strings = b'\0'
    name_offset = len(strings)
    strings += b'Fixture Proc\0'
    description_offset = len(strings)
    strings += b'Triggers something.\0'
    row = bytearray(SPELL_RECORD_BYTES)
    for field, value in (('Id', P5_FIXTURE_SPELL), ('Attributes', PASSIVE), ('Effect[0]', APPLY_AURA),
                         ('EffectApplyAuraName[0]', P5_FIXTURE_AURA), ('Effect[1]', APPLY_AURA),
                         ('EffectApplyAuraName[1]', P5_FIXTURE_AURA), ('SpellName[enUS]', name_offset),
                         ('Description[enUS]', description_offset), ('SpellFamilyName', TEMPLAR_FAMILY_NAME)):
        struct.pack_into('<i', row, offsets[field], value)
    header = struct.pack('<4s4I', b'WDBC', 1, SPELL_FIELDS, SPELL_RECORD_BYTES, len(strings))
    (directory / 'Spell.dbc').write_bytes(header + bytes(row) + strings)


class TriggerLinkTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        write_p5_fixture(self.directory)

    def tearDown(self):
        self.temp.cleanup()

    def effects_with(self, class_file_extra: dict, verdicts=None):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory),
                      **class_file_extra}
        return passive_effects(class_file, ClassSpell(P5_FIXTURE_SPELL, 'Fixture Proc', (P5_FIXTURE_SPELL,),
                                                       P5_FIXTURE_SPELL, 2, True), verdicts)

    def test_p5_effect_links_to_existing_trigger_entry(self):
        effects = self.effects_with({'triggers': [{'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Proc',
                                                    'kind': None}]})
        effect = effect_of(effects, 0)
        self.assertTrue(effect.reason.startswith('unmodelled: checked by triggers entry'), effect.reason)
        self.assertNotEqual(effect.reason, 'unmodelled: proc or trigger effect without a trigger entry')

    def test_p5_link_reports_the_live_verdict_status_not_a_recorded_one(self):
        label = f'{P5_FIXTURE_SPELL} trigger_count'
        effects = self.effects_with({'triggers': [{'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Proc', 'kind': None,
                                                    'status': 'ok'}]}, verdicts={label: 'alert'})
        effect = effect_of(effects, 0)
        self.assertIn(f'"{label}" (status alert)', effect.reason)
        self.assertNotIn('status ok', effect.reason)

    def test_p5_link_without_a_live_verdict_falls_back_to_the_recorded_status(self):
        label = f'{P5_FIXTURE_SPELL} trigger_count'
        effects = self.effects_with({'triggers': [{'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Proc', 'kind': None,
                                                    'status': 'ok'}]}, verdicts={})
        effect = effect_of(effects, 0)
        self.assertIn(f'"{label}" (status ok)', effect.reason)

    def test_p5_effect_without_any_entry_keeps_generic_reason(self):
        effects = self.effects_with({})
        effect = effect_of(effects, 0)
        self.assertEqual(effect.reason, 'unmodelled: proc or trigger effect without a trigger entry')

    def test_p5_links_prefer_matching_effect_index(self):
        effects = self.effects_with({'triggers': [
            {'aura': P5_FIXTURE_SPELL, 'effect': 0, 'name': 'Fixture Proc Zero', 'kind': None},
            {'aura': P5_FIXTURE_SPELL, 'effect': 1, 'name': 'Fixture Proc One', 'kind': None}]})
        effect0 = effect_of(effects, 0)
        effect1 = effect_of(effects, 1)
        self.assertIn('"Fixture Proc Zero"', effect0.reason)
        self.assertIn('"Fixture Proc One"', effect1.reason)

    def test_p5_link_to_cooldown_delta_entry_uses_its_cooldown_label(self):
        effects = self.effects_with({'triggers': [{'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Cooldown',
                                                    'kind': 'cooldown_delta', 'observe_spell': 999}]})
        effect = effect_of(effects, 0)
        self.assertIn(f'"{P5_FIXTURE_SPELL} trigger_cooldown_delta"', effect.reason)

    def test_p5_link_to_duration_delta_entry_uses_its_duration_label_not_the_plain_trigger_label(self):
        effects = self.effects_with({'triggers': [{'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Duration',
                                                    'kind': 'duration_delta', 'observe_spell': 999}]})
        effect = effect_of(effects, 0)
        self.assertIn(f'"{P5_FIXTURE_SPELL} trigger_duration_delta"', effect.reason)
        self.assertNotIn(f'"{P5_FIXTURE_SPELL} trigger_count"', effect.reason)

    def test_p5_link_to_two_cooldown_delta_entries_sharing_an_aura_disambiguates_each_by_observe_spell(self):
        effects = self.effects_with({'triggers': [
            {'aura': P5_FIXTURE_SPELL, 'effect': 0, 'name': 'Fixture Cooldown A', 'kind': 'cooldown_delta',
             'observe_spell': 10},
            {'aura': P5_FIXTURE_SPELL, 'effect': 1, 'name': 'Fixture Cooldown B', 'kind': 'cooldown_delta',
             'observe_spell': 20}]})
        effect0 = effect_of(effects, 0)
        effect1 = effect_of(effects, 1)
        self.assertIn(f'"{P5_FIXTURE_SPELL} trigger_cooldown_delta 10"', effect0.reason)
        self.assertIn(f'"{P5_FIXTURE_SPELL} trigger_cooldown_delta 20"', effect1.reason)

    def test_p5_link_to_two_proc_entries_sharing_an_aura_disambiguates_each_by_proc_spell(self):
        effects = self.effects_with({'procs': [
            {'aura': P5_FIXTURE_SPELL, 'effect': 0, 'name': 'Fixture Proc A', 'proc_spell': 10,
             'trigger': {'action': 'attack', 'spell': 0}},
            {'aura': P5_FIXTURE_SPELL, 'effect': 1, 'name': 'Fixture Proc B', 'proc_spell': 20,
             'trigger': {'action': 'attack', 'spell': 0}}]})
        effect0 = effect_of(effects, 0)
        effect1 = effect_of(effects, 1)
        self.assertIn(f'"{P5_FIXTURE_SPELL} proc_rate 10"', effect0.reason)
        self.assertIn(f'"{P5_FIXTURE_SPELL} proc_rate 20"', effect1.reason)

    def test_p5_link_to_two_proc_entries_sharing_aura_and_proc_spell_disambiguates_by_trigger(self):
        effects = self.effects_with({'procs': [
            {'aura': P5_FIXTURE_SPELL, 'effect': 0, 'name': 'Fixture Proc Attack', 'proc_spell': 10,
             'trigger': {'action': 'attack', 'spell': 0}},
            {'aura': P5_FIXTURE_SPELL, 'effect': 0, 'name': 'Fixture Proc Cast', 'proc_spell': 10,
             'trigger': {'action': 'cast', 'spell': 30}}]})
        effect = effect_of(effects, 0)
        self.assertIn(f'"{P5_FIXTURE_SPELL} proc_rate 10 attack"', effect.reason)
        self.assertIn(f'"{P5_FIXTURE_SPELL} proc_rate 10 30"', effect.reason)
        self.assertIn('"Fixture Proc Attack"', effect.reason)
        self.assertIn('"Fixture Proc Cast"', effect.reason)

    def test_p5_links_to_every_candidate_when_none_disambiguates_by_effect(self):
        effects = self.effects_with({'procs': [
            {'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Proc Attack', 'proc_spell': 10,
             'trigger': {'action': 'attack', 'spell': 0}},
            {'aura': P5_FIXTURE_SPELL, 'name': 'Fixture Proc Cast', 'proc_spell': 10,
             'trigger': {'action': 'cast', 'spell': 30}}]})
        effect = effect_of(effects, 0)
        self.assertIn('"Fixture Proc Attack"', effect.reason)
        self.assertIn('"Fixture Proc Cast"', effect.reason)


class FamilyTest(unittest.TestCase):
    def test_dummy_effect_is_scripted_whatever_its_aura(self):
        self.assertEqual(family_of(3, 42), 'P6')
        self.assertEqual(family_of(6, 42), 'P5')

    def test_aura_family_table(self):
        self.assertEqual(family_of(6, 107), 'P1')
        self.assertEqual(family_of(65, 166), 'P2')
        self.assertEqual(family_of(6, 229), 'P4')
        self.assertEqual(family_of(6, 999), 'unknown')
        self.assertEqual(set(FAMILIES.values()), {'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'})

    def test_max_spellmod_matches_spell_defines(self):
        self.assertEqual(MAX_SPELLMOD, 32)


class PhraseTest(unittest.TestCase):
    def test_stat_after_token(self):
        text = 'Increases your Stamina by $s1, plus an additional amount equal to $s1% of your Agility.'
        self.assertEqual(stat_after_token(text, '$s1'), 'Agility')
        self.assertEqual(stat_after_token('your parry rating by $s1% of Agility', '$s1'), 'Agility')
        self.assertEqual(stat_after_token('Holy spell damage by $s1% of your attack power', '$s1'), 'attack power')
        self.assertIsNone(stat_after_token('Increases your Stamina by $s1.', '$s1'))

    def test_every_phrase_list_names_its_quantity(self):
        for quantity, phrases in PHRASES.items():
            self.assertTrue(phrases, quantity)


class FixturePassiveTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        write_spell_fixture(self.directory)

    def tearDown(self):
        self.temp.cleanup()

    def test_unknown_aura_is_unmodelled(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory)}
        effects = passive_effects(class_file, ClassSpell(FIXTURE_SPELL, 'Fixture Passive', (FIXTURE_SPELL,),
                                                         FIXTURE_SPELL, 1, True))
        self.assertEqual(len(effects), 1)
        effect = effects[0]
        self.assertEqual((effect.family, effect.aura), ('unknown', FIXTURE_AURA))
        self.assertEqual(effect.reason, 'unmodelled: aura 999 has no passive measurement')
        self.assertEqual(effect.plans, ())

    def test_unmodelled_effects_override_forces_unmodelled_even_with_a_checkable_plan(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory),
                      'unmodelled_effects': [{'spell': FIXTURE_SPELL, 'effect': 0, 'reason': 'test reason'}]}
        effects = passive_effects(class_file, ClassSpell(FIXTURE_SPELL, 'Fixture Passive', (FIXTURE_SPELL,),
                                                         FIXTURE_SPELL, 1, True))
        effect = effects[0]
        self.assertEqual(effect.reason, 'unmodelled: test reason')
        self.assertEqual(effect.plans, ())

    def test_unmodelled_effects_override_without_a_match_keeps_the_generic_outcome(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory),
                      'unmodelled_effects': [{'spell': FIXTURE_SPELL + 1, 'effect': 0, 'reason': 'test reason'}]}
        effects = passive_effects(class_file, ClassSpell(FIXTURE_SPELL, 'Fixture Passive', (FIXTURE_SPELL,),
                                                         FIXTURE_SPELL, 1, True))
        effect = effects[0]
        self.assertEqual(effect.reason, 'unmodelled: aura 999 has no passive measurement')


class LiteralTokenTest(unittest.TestCase):
    def test_literal_token_resolves_a_textual_percent_claim(self):
        class_file = {'literal_tokens': [{'spell': FINAL_PRAYER, 'effect': 0,
                                          'quote': 'Doubles the healing done to you', 'value': 100}]}
        token = literal_token(class_file, {FINAL_PRAYER}, 0,
                              'Doubles the healing done to you by Testament of Fortitude.')
        self.assertEqual(token.text, 'Doubles the healing done to you')
        self.assertEqual(token.value, 100.0)
        self.assertEqual(token.effect_index, 0)

    def test_literal_token_without_a_matching_entry_returns_none(self):
        class_file = {'literal_tokens': [{'spell': FINAL_PRAYER, 'effect': 0,
                                          'quote': 'Doubles the healing done to you', 'value': 100}]}
        self.assertIsNone(literal_token(class_file, {FINAL_PRAYER}, 1, 'anything'))
        self.assertIsNone(literal_token(class_file, {999999}, 0, 'anything'))

    def test_literal_token_requires_the_quote_in_the_tooltip(self):
        class_file = {'literal_tokens': [{'spell': FINAL_PRAYER, 'effect': 0,
                                          'quote': 'Doubles the healing done to you', 'value': 100}]}
        with self.assertRaises(ValueError):
            literal_token(class_file, {FINAL_PRAYER}, 0, 'Grants $s1% of one thing.')


class OwnTokenTest(unittest.TestCase):
    def test_own_token_skips_a_radius_token_at_the_same_effect_index(self):
        values = [Displayed('$a1', 40.0, 0, 'radius_yards'), Displayed('$s1', 6.0, 0, 'percent')]
        token = own_token(values, 0)
        self.assertEqual(token.text, '$s1')
        self.assertEqual(token.kind, 'percent')

    def test_own_token_returns_none_without_a_value_bearing_token(self):
        values = [Displayed('$a1', 40.0, 0, 'radius_yards'), Displayed('$h', 20.0, 0, 'chance_pct')]
        self.assertIsNone(own_token(values, 0))


class AliasedTokenFixtureTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        write_aliased_token_fixture(self.directory)

    def tearDown(self):
        self.temp.cleanup()

    def effects(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory)}
        return passive_effects(class_file, ClassSpell(ALIASED_FIXTURE_SPELL, 'Aliased Fixture Passive',
                                                       (ALIASED_FIXTURE_SPELL,), ALIASED_FIXTURE_SPELL, 1, True))

    def test_second_effect_follows_the_first_effects_own_value(self):
        effects = self.effects()
        first, second = effect_of(effects, 0), effect_of(effects, 1)
        self.assertEqual(first.points, 6.0)
        self.assertEqual(second.points, 6.0)
        self.assertNotEqual(second.points, 10.0)
        self.assertEqual(second.token.text, '$s1')
        self.assertEqual(second.reason, 'token $s1 reused from effect 0; expected value follows effect 0, '
                         'not own points')
        self.assertTrue(second.plans)

    def test_second_effect_without_a_reused_token_stays_unmodelled(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory)}
        dbc = dataset(self.directory)
        records = Records(dbc)
        text = 'Grants $s1% of one thing.'
        values = [Displayed('$s1', 6.0, 0, 'percent')]
        effect = classify(class_file, records, ALIASED_FIXTURE_SPELL, ALIASED_FIXTURE_SPELL, 1, [0, 1], text, values)
        self.assertEqual(effect.reason, 'unmodelled: no own token and no sibling token with equal points')
        self.assertEqual(effect.plans, ())

    def test_second_effect_stays_unmodelled_when_the_reuse_is_within_the_first_effects_own_sentence(self):
        class_file = {'class_id': TEMPLAR_CLASS_ID, 'level': LEVEL, 'dbc_dir': str(self.directory)}
        dbc = dataset(self.directory)
        records = Records(dbc)
        text = 'Increases your maximum health by $s1%, further increasing by $s1% past 50% health.'
        values = [Displayed('$s1', 6.0, 0, 'percent'), Displayed('$s1', 6.0, 0, 'percent')]
        effect = classify(class_file, records, ALIASED_FIXTURE_SPELL, ALIASED_FIXTURE_SPELL, 1, [0, 1], text, values)
        self.assertEqual(effect.reason, 'unmodelled: no own token and no sibling token with equal points')
        self.assertEqual(effect.plans, ())


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class TemplarPassiveTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.class_file = load_class_file(TEMPLAR_CLASS_ID)

    def effects(self, spell_id: int):
        return passive_effects(self.class_file, templar_passive(spell_id))

    def test_templar_family_counts(self):
        passives = [spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER) if spell.passive]
        self.assertEqual(len(passives), TEMPLAR_PASSIVES)
        families = Counter(effect.family for spell in passives for effect in passive_effects(self.class_file, spell))
        self.assertEqual(sum(families.values()), TEMPLAR_PASSIVE_EFFECTS)
        self.assertEqual(dict(families), TEMPLAR_FAMILY_COUNTS)

    def test_effect_notes_close_scripted_effects_already_covered_elsewhere(self):
        for spell_id, index in ((300529, 1), (705263, 1), (705272, 1), (705274, 1), (705283, 1), (705287, 1),
                                (705298, 1), (805420, 1), (806516, 0)):
            effect = effect_of(self.effects(spell_id), index)
            self.assertTrue(effect.reason.startswith('closed: '), (spell_id, index, effect.reason))
            self.assertIn('round4 scripted-script-aura investigation', effect.reason)

    def test_effect_notes_reclassify_without_closing(self):
        effect = effect_of(self.effects(804930), 0)
        self.assertTrue(effect.reason.startswith('unmodelled: '), effect.reason)
        self.assertFalse(effect.reason.startswith('closed: '), effect.reason)
        self.assertNotEqual(effect.reason, 'unmodelled: scripted or crowd-control effect', effect.reason)
        self.assertIn('round4 scripted-script-aura investigation', effect.reason)

    def test_effect_notes_defer_the_effects_this_item_cannot_check(self):
        for spell_id, index in ((92109, 0), (300520, 0)):
            effect = effect_of(self.effects(spell_id), index)
            self.assertTrue(effect.reason.startswith('unmodelled: deferred: '), (spell_id, index, effect.reason))

    def test_fortified_body_effect_0_token_is_its_own_percent_not_its_radius(self):
        effect = effect_of(self.effects(300515), 0)
        self.assertEqual(effect.token.text, '$s1')
        self.assertEqual(effect.points, 6.0)

    def test_pious_sweep_effect_0_targets_chastise_not_the_raw_class_mask(self):
        effect = effect_of(self.effects(520034), 0)
        self.assertEqual([target.spell_id for target in effect.targets], [503141])
        self.assertTrue(effect.targets[0].named)

    def test_courage_movement_speed_aura_is_measured(self):
        for spell_id, percent in ((707754, 10), (712466, 20)):
            effect = effect_of(self.effects(spell_id), 0)
            self.assertEqual(effect.aura, 31)
            self.assertFalse(effect.reason, (spell_id, effect.reason))
            plan = plan_named(effect, 'run_speed_rate')
            self.assertEqual(plan.relation, 'scale')
            self.assertEqual(effect.points, float(percent))

    def test_effect_notes_no_own_token_entries_stay_unmodelled(self):
        for spell_id, index in ((704175, 2), (705268, 1), (712437, 0), (803219, 0)):
            effect = effect_of(self.effects(spell_id), index)
            self.assertTrue(effect.reason.startswith('unmodelled: no own token'), (spell_id, index, effect.reason))
            self.assertFalse(effect.reason.startswith('closed: '), (spell_id, index, effect.reason))

    def test_effect_notes_without_an_entry_keep_the_generic_reason(self):
        self.assertEqual(effect_of(self.effects(706323), 1).reason, 'unmodelled: scripted or crowd-control effect')

    def test_effect_notes_round5_close_a_dead_effect(self):
        for spell_id in (92109, 803149):
            effect = effect_of(self.effects(spell_id), 1)
            self.assertTrue(effect.reason.startswith('unmodelled: closed: '), (spell_id, effect.reason))
            self.assertNotEqual(effect.reason, 'unmodelled: scripted or crowd-control effect', (spell_id, effect.reason))
            self.assertIn('effect zeroed at load', effect.reason)
        self.assertIn('twin of the 92109 effect-1 finding', effect_of(self.effects(803149), 1).reason)

    def test_effect_notes_round5_reclassify_without_closing(self):
        effect = effect_of(self.effects(804897), 2)
        self.assertTrue(effect.reason.startswith('unmodelled: reclassify: '), effect.reason)
        self.assertFalse(effect.reason.startswith('closed: '), effect.reason)
        self.assertNotEqual(effect.reason, 'unmodelled: scripted or crowd-control effect', effect.reason)

    def test_lightkeeper_effects_link_to_their_own_disambiguated_proc_entry_not_each_others(self):
        parry_entry = next(entry for entry in self.class_file['procs']
                           if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == LIGHTKEEPER_PARRY)
        burst_entry = next(entry for entry in self.class_file['procs']
                           if entry['aura'] == LIGHTKEEPER and entry['proc_spell'] == LIGHTKEEPER_BURST)
        [parry_expectation] = proc_scenario(self.class_file, parry_entry)[1]
        [burst_expectation] = proc_scenario(self.class_file, burst_entry)[1]
        effect0 = effect_of(self.effects(LIGHTKEEPER), 0)
        effect1 = effect_of(self.effects(LIGHTKEEPER), 1)
        self.assertIn(f'"{parry_expectation.label}"', effect0.reason)
        self.assertIn(f'"{burst_expectation.label}"', effect1.reason)
        self.assertNotIn(f'"{burst_expectation.label}"', effect0.reason)
        self.assertNotIn(f'"{parry_expectation.label}"', effect1.reason)

    def test_might_of_aggramar_effect_links_to_both_its_proc_entries(self):
        entries = [entry for entry in self.class_file['procs'] if entry['aura'] == MIGHT_OF_AGGRAMAR]
        self.assertEqual(len(entries), 2)
        expectations = [proc_scenario(self.class_file, entry)[1][0] for entry in entries]
        effect = effect_of(self.effects(MIGHT_OF_AGGRAMAR), 0)
        for expectation in expectations:
            self.assertIn(f'"{expectation.label}"', effect.reason)

    def test_aggramars_rage_crit_effect_judges_holy_spell_crit_on_both_ranks(self):
        for spell_id in (560650, 561346):
            effect = effect_of(self.effects(spell_id), 0)
            plan = plan_named(effect, 'spell_crit_chance')
            self.assertEqual((plan.fields, plan.relation, plan.judged), ({'school': 1}, 'add', True))
            self.assertEqual(effect.family, 'P2')
            self.assertEqual(effect.reason, '')

    def test_unmodelled_effects_mark_patiences_scripted_effects_on_interdict(self):
        for index in (0, 1):
            effect = effect_of(self.effects(PATIENCE), index)
            self.assertTrue(effect.reason.startswith('unmodelled: round4 alert-triage: '), (index, effect.reason))
            self.assertEqual(effect.plans, ())
            self.assertEqual(effect.family, 'P1')

    def test_named_targets_follow_the_tooltip(self):
        effect = effect_of(self.effects(PALADIN_TRAINING), 0)
        self.assertEqual({target.spell_id for target in effect.targets if target.named},
                         {ARGENT_BLADE_AT_60, RIGHTEOUS_LUNGE_AT_60})
        self.assertEqual(target_ids(effect, True, True), {ARGENT_BLADE_AT_60, RIGHTEOUS_LUNGE_AT_60})
        self.assertIn(HOLY_MASTER, target_ids(effect, False, True))
        plan = plan_named(effect, 'spell_modifier')
        self.assertEqual((plan.fields['op'], plan.fields['base'], plan.relation, plan.judged),
                         (0, 1000, 'spell_mod_pct', True))
        self.assertEqual(effect.reason, '')

    def test_named_targets_without_the_mask(self):
        records = Records(dataset(DBC_DIR))
        targets = named_targets(records, TEMPLAR_FAMILY_NAME, 'Righteous Lunge and Argent Blade', LEVEL)
        self.assertEqual({target.spell_id for target in targets}, {ARGENT_BLADE_AT_60, RIGHTEOUS_LUNGE_AT_60})
        self.assertTrue(all(isinstance(target, PassiveTarget) and target.named for target in targets))

    def test_spell_name_inside_a_longer_proper_noun_is_not_named(self):
        records = Records(dataset(DBC_DIR))
        blessed_strikes = named_targets(records, TEMPLAR_FAMILY_NAME,
                                        'Reduces the Energy cost of your Oath Breakers by $s1.', LEVEL)
        self.assertFalse(any(target.named for target in blessed_strikes))
        chakra = named_targets(records, TEMPLAR_FAMILY_NAME,
                               'Oath Breakers now heal allies around the target', LEVEL)
        self.assertFalse(any(target.named for target in chakra))

    def test_name_inside_a_per_trigger_counter_clause_is_not_named(self):
        records = Records(dataset(DBC_DIR))
        text = 'Increases the effectiveness Righteous Upheaval gains per trigger of Zealotry by $s1%.'
        targets = named_targets(records, TEMPLAR_FAMILY_NAME, text, LEVEL)
        self.assertEqual({target.spell_id for target in targets}, {RIGHTEOUS_UPHEAVAL_GENERIC_RANK})
        self.assertNotIn('Zealotry', {target.name for target in targets})

    def test_holy_upheaval_targets_righteous_upheaval_not_the_counted_zealotry(self):
        effect = effect_of(self.effects(HOLY_UPHEAVAL), 0)
        self.assertEqual({target.spell_id for target in effect.targets if target.named}, {RIGHTEOUS_UPHEAVAL_AT_60})
        self.assertEqual(effect.reason, '')

    def test_passive_targets_override_fixes_named_but_wrong_mask_targets(self):
        pious_sweep = effect_of(self.effects(PIOUS_SWEEP), 1)
        self.assertEqual(target_ids(pious_sweep, True, True), {TRANQUIL_CIRCLE})
        self.assertNotIn(WRONGLY_NAMED_CHASTISE, {target.spell_id for target in pious_sweep.targets})
        self.assertNotIn(TRANQUIL_CIRCLE_INCOMPLETE, {target.spell_id for target in pious_sweep.targets})
        self.assertIn(PIOUS_SWEEP_DEV_SPELL, target_ids(pious_sweep, False, True))
        self.assertEqual(pious_sweep.reason, '')
        templars_might = effect_of(self.effects(TEMPLARS_MIGHT), 0)
        self.assertEqual(target_ids(templars_might, True, True), {CONDEMN_AT_60})
        self.assertEqual(templars_might.reason, '')

    def test_passive_targets_override_resolves_category_unmodelled_effects(self):
        blessed_strikes = effect_of(self.effects(BLESSED_STRIKES), 0)
        self.assertEqual(blessed_strikes.reason, '')
        self.assertTrue({target.spell_id for target in blessed_strikes.targets if target.named})
        deep_secrets = effect_of(self.effects(DEEP_SECRETS), 0)
        self.assertEqual(deep_secrets.reason, '')
        self.assertIn(TESTAMENT_OF_FORTITUDE, target_ids(deep_secrets, True, True))
        mark_of_aggramar = effect_of(self.effects(MARK_OF_AGGRAMAR), 0)
        self.assertEqual(mark_of_aggramar.reason, '')
        self.assertIn(TESTAMENT_OF_FAITH, target_ids(mark_of_aggramar, True, True))
        self.assertIn(ASCETIC_ABDICATION, target_ids(mark_of_aggramar, False, True))
        for chakra in CHAKRA_OF_LIGHT:
            effect = effect_of(self.effects(chakra), 1)
            self.assertEqual(effect.reason, '')
            self.assertIn(TESTAMENT_OF_FAITH, target_ids(effect, True, True))
            self.assertIn(ASCETIC_ABDICATION, target_ids(effect, False, True))

    def test_fury_of_aggramar_names_every_libram(self):
        all_librams = {803893, 805423, 801463, 801461, 801466}
        effectiveness = effect_of(self.effects(FURY_OF_AGGRAMAR), 1)
        self.assertEqual(target_ids(effectiveness, True, True), all_librams)
        self.assertEqual(effectiveness.reason, '')
        cooldown = effect_of(self.effects(FURY_OF_AGGRAMAR), 2)
        self.assertEqual(target_ids(cooldown, True, True), all_librams)
        self.assertEqual(cooldown.reason, '')

    def test_named_target_outside_the_mask_is_kept(self):
        effect = effect_of(self.effects(PATIENCE), 0)
        self.assertIn(INTERDICT, target_ids(effect, True, False))
        self.assertIn(SACRED_RESTRAINT, target_ids(effect, False, True))
        self.assertTrue(effect.reason.startswith('unmodelled: round4 alert-triage: '), effect.reason)

    def test_in_mask_namesakes_are_the_targets_of_a_named_spell(self):
        effect = effect_of(self.effects(PURE_FOCUS), 0)
        self.assertEqual({target.spell_id for target in effect.targets if target.named}, {SCOURGEBANE_IN_MASK})
        self.assertEqual(target_ids(effect, True, True), {SCOURGEBANE_IN_MASK})

    def test_same_name_mask_helpers_are_measured(self):
        effect = effect_of(self.effects(ARGENT_KNIGHT), 0)
        self.assertEqual(target_ids(effect, True, True), set(RIGHTEOUS_TEMPEST_HELPERS))
        self.assertNotIn(RIGHTEOUS_TEMPEST, {target.spell_id for target in effect.targets})

    def test_condemn_belongs_to_the_effect_whose_mask_holds_it(self):
        effects = passive_effects(self.class_file, templar_passive(CONDEMNATION))
        self.assertFalse(any(target.named for target in effect_of(effects, 0).targets))
        self.assertTrue(effect_of(effects, 0).reason.startswith(NO_NAMED_TARGET))
        self.assertEqual(target_ids(effect_of(effects, 1), True, True), {CONDEMN_AT_60})

    def test_a_spell_in_a_sibling_mask_belongs_to_the_sibling_effect(self):
        effects = self.effects(GRACE_OF_AMANTHUL)
        self.assertIn(RIGHTEOUS_LUNGE_AT_60, target_ids(effect_of(effects, 0), True, True))
        sacred_swing = effect_of(effects, 1)
        self.assertNotIn(RIGHTEOUS_LUNGE_AT_60, {target.spell_id for target in sacred_swing.targets})
        self.assertIn(SACRED_SWING_AT_60, target_ids(sacred_swing, True, True))

    def test_duration_reduction_starts_above_the_zero_clamp(self):
        effect = effect_of(self.effects(SACRED_CANDLE), 1)
        self.assertEqual(plan_named(effect, 'spell_modifier').fields, {'op': 1, 'base': SPELL_MODIFIER_BASE + 30000})
        cooldown = effect_of(self.effects(SACRED_CANDLE), 0)
        self.assertEqual(plan_named(cooldown, 'spell_modifier').fields['base'], SPELL_MODIFIER_BASE)

    def test_category_targets(self):
        effect = effect_of(self.effects(LIBERTY), 0)
        self.assertEqual(effect.token.text, '$/1000;s1')
        self.assertEqual(plan_named(effect, 'spell_modifier').fields['op'], 11)
        self.assertTrue(set(LIBRAMS) <= target_ids(effect, False, True))
        self.assertFalse(any(target.named for target in effect.targets))
        self.assertEqual(effect.reason, '')

    def test_passive_targets_override_the_tooltip_match(self):
        class_file = dict(self.class_file, passive_targets=[
            {'spell': CONDEMNATION, 'effect': 0, 'targets': [OATH_CONDEMN],
             'tooltip_words': 'critical strike chance gained through Condemn'}])
        effect = effect_of(passive_effects(class_file, templar_passive(CONDEMNATION)), 0)
        self.assertEqual(target_ids(effect, True, True), {OATH_CONDEMN})
        self.assertFalse(target_ids(effect, True, False))

    def test_passive_targets_must_quote_the_tooltip(self):
        class_file = dict(self.class_file, passive_targets=[
            {'spell': CONDEMNATION, 'effect': 0, 'targets': [OATH_CONDEMN], 'tooltip_words': 'Oath: Condemn'}])
        with self.assertRaises(ValueError):
            passive_effects(class_file, templar_passive(CONDEMNATION))

    def test_spell_modifier_operation_beyond_max_spellmod(self):
        effect = effect_of(self.effects(CONDEMNATION), 1)
        self.assertEqual(effect.plans, ())
        self.assertEqual(effect.reason, 'unmodelled: SpellModOp 40 is not below MAX_SPELLMOD 32')

    def test_final_prayer_effect_0_is_modelled_via_literal_token(self):
        effect = effect_of(self.effects(FINAL_PRAYER), 0)
        self.assertEqual(effect.reason, '')
        self.assertEqual(effect.token.text, 'Doubles the healing done to you')
        value_plan = plan_named(effect, 'spell_effect_value')
        self.assertEqual(value_plan.fields, {'effect': 0})
        modifier_plan = plan_named(effect, 'spell_modifier')
        self.assertEqual(modifier_plan.fields['op'], 3)

    def test_final_prayer_effect_1_stays_unmodelled_with_evidence(self):
        effect = effect_of(self.effects(FINAL_PRAYER), 1)
        self.assertTrue(effect.reason.startswith('unmodelled: no own token'), effect.reason)
        self.assertIn('801478', effect.reason)
        self.assertIn('behaviour_ratio', effect.reason)

    def test_final_prayer_effect_0_targets_exclude_the_sibling_named_spell(self):
        effect = effect_of(self.effects(FINAL_PRAYER), 0)
        targets = {target.spell_id for target in effect.targets}
        self.assertFalse({TESTAMENT_OF_FAITH, 801478} & targets)
        self.assertIn(TESTAMENT_OF_FORTITUDE, target_ids(effect, True, True))

    def test_modifier_targets_excludes_a_non_p1_sibling_that_already_claims_the_name(self):
        records = Records(dataset(DBC_DIR))
        text = 'Doubles the healing done to you by Testament of Fortitude and Testament of Faith.'
        values = [Displayed('Doubles the healing done to you', 100.0, 0, 'percent')]
        class_file = {'level': LEVEL}
        with_claim = classify(class_file, records, FINAL_PRAYER, FINAL_PRAYER, 0, [0, 1], text, values)
        self.assertNotIn(TESTAMENT_OF_FAITH, {target.spell_id for target in with_claim.targets})
        self.assertNotIn(801478, {target.spell_id for target in with_claim.targets})
        without_claim = classify(class_file, records, FINAL_PRAYER, FINAL_PRAYER, 0, [0], text, values)
        self.assertIn(TESTAMENT_OF_FAITH, {target.spell_id for target in without_claim.targets})

    def test_justicar_removes_cooldown_is_modelled_via_literal_token(self):
        effect = effect_of(self.effects(JUSTICAR_OF_THE_LIGHT), 0)
        self.assertEqual(effect.reason, '')
        self.assertEqual(effect.token.text, 'Removes the cooldown from Benediction')
        modifier_plan = plan_named(effect, 'spell_modifier')
        self.assertEqual(modifier_plan.fields, {'op': 11, 'base': SPELL_MODIFIER_BASE})

    def test_condemnation_effect_2_stays_unmodelled_with_evidence(self):
        effect = effect_of(self.effects(CONDEMNATION), 2)
        self.assertTrue(effect.reason.startswith('unmodelled: no own token'), effect.reason)
        self.assertIn('SPELL_AURA_ABILITY_PERIODIC_CRIT', effect.reason)

    def test_justice_effect_0_stays_unmodelled_with_evidence(self):
        effect = effect_of(self.effects(JUSTICE), 0)
        self.assertTrue(effect.reason.startswith('unmodelled: no own token'), effect.reason)
        self.assertIn('SPELL_AURA_MOD_SILENCE', effect.reason)

    def test_spiritual_abdicator_effect_0_stays_unmodelled_with_evidence(self):
        effect = effect_of(self.effects(SPIRITUAL_ABDICATOR), 0)
        self.assertTrue(effect.reason.startswith('unmodelled: no own token'), effect.reason)
        self.assertIn('704409', effect.reason)

    def test_graceful_fighter_and_holy_warstaff_dead_effects_stay_unmodelled_plainly(self):
        self.assertEqual(effect_of(self.effects(GRACEFUL_FIGHTER), 2).reason,
                         'unmodelled: no own token and no sibling token with equal points')
        self.assertEqual(effect_of(self.effects(705307), 0).reason,
                         'unmodelled: no own token and no sibling token with equal points')

    def test_rating_from_stat_reads_the_tooltip_stat(self):
        effects = self.effects(GRACEFUL_FIGHTER)
        parry = plan_named(effect_of(effects, 0), 'combat_rating')
        self.assertEqual((parry.fields, parry.relation, parry.source), ({'rating': 3}, 'share', 'stat 1'))
        dodge = plan_named(effect_of(effects, 1), 'combat_rating')
        self.assertEqual((dodge.fields, dodge.relation, dodge.source), ({'rating': 2}, 'share', 'stat 3'))
        self.assertTrue(effect_of(effects, 2).reason.startswith('unmodelled: no own token'))

    def test_shared_token_judges_a_sibling_with_equal_points(self):
        energy = effect_of(self.effects(STURDY), 1)
        self.assertEqual((energy.token.text, energy.token.effect_index), ('$s1', 0))
        plan = plan_named(energy, 'max_power')
        self.assertEqual((plan.fields, plan.relation), ({'power': 3}, 'scale'))
        self.assertEqual(energy.reason, '')

    def test_crit_phrase_selects_the_school(self):
        plans = crit_plans('Increases your Holy critical strike chance by $s1% and your expertise by $s2.')
        plan, quantity = plans[0]
        self.assertEqual((plan.fields, plan.relation), ({'school': 1}, 'add'))
        self.assertEqual(quantity, 'Holy critical strike chance')
        expertise = plan_named(effect_of(self.effects(AGGRAMARS_RAGE), 1), 'expertise')
        self.assertEqual(expertise.relation, 'add')

    def test_aggramars_rage_crit_effect_is_no_longer_in_unmodelled_effects(self):
        self.assertFalse(any(entry['spell'] in (560650, AGGRAMARS_RAGE) and entry['effect'] == 0
                             for entry in self.class_file['unmodelled_effects']))

    def test_generic_crit_phrase_judges_melee_and_measures_spell_crit(self):
        effect = effect_of(self.effects(FINESSE), 0)
        melee = plan_named(effect, 'melee_crit_chance_refreshed')
        self.assertEqual((melee.relation, melee.judged), ('add', True))
        spell_crit = [plan for plan in effect.plans if plan.metric == 'spell_crit_chance']
        self.assertEqual([plan.fields['school'] for plan in spell_crit], MAGIC_SCHOOLS)
        self.assertFalse(any(plan.judged for plan in spell_crit))
        self.assertEqual(effect.reason, '')

    def test_effect_carries_its_signed_points_beside_a_shared_token(self):
        effects = self.effects(PALADIN_TRAINING)
        cost = effect_of(effects, 1)
        self.assertEqual((cost.token.text, cost.token.value, cost.token.effect_index), ('$s1', 20.0, 0))
        self.assertEqual(cost.points, -20.0)
        self.assertEqual(effect_of(effects, 0).points, 20.0)

    def test_aliased_token_follows_the_owning_effects_value(self):
        effects = self.effects(FORTIFIED_BODY)
        healing, health = effect_of(effects, 0), effect_of(effects, 1)
        self.assertEqual(healing.points, 6.0)
        self.assertEqual((health.token.text, health.token.effect_index), ('$s1', 0))
        self.assertEqual(health.points, 6.0)
        self.assertNotEqual(health.points, 10.0)
        self.assertEqual(health.reason, 'token $s1 reused from effect 0; expected value follows effect 0, '
                         'not own points')
        self.assertEqual(plan_named(health, 'max_health').relation, 'scale')

    def test_rating_mask_gives_one_plan_per_rating(self):
        effect = effect_of(self.effects(LIGHTS_CHOSEN), 1)
        self.assertEqual(sorted(plan.fields['rating'] for plan in effect.plans), [8, 10])
        self.assertEqual({plan.source for plan in effect.plans}, {'stat 3'})

    def test_quantity_missing_from_the_tooltip_is_unmodelled(self):
        effect = effect_of(self.effects(CALL_OF_THE_MONASTERY), 1)
        self.assertEqual(effect.reason, 'unmodelled: the tooltip does not name ranged attack power')
        self.assertEqual(effect.plans, ())

    def test_mail_armor_contribution_is_modelled_via_the_class_file_override(self):
        for spell_id in (301311, 301360):
            effect = effect_of(self.effects(spell_id), 0)
            self.assertEqual(effect.reason, '')
            reference, delta = effect.plans
            self.assertEqual((reference.metric, reference.fields, reference.judged),
                             ('item_armor_by_subclass', {'subclass': 3}, False))
            self.assertEqual((delta.metric, delta.relation, delta.source),
                             ('armor', 'share', f'{spell_id} e0 item_armor_by_subclass 3 before'))

    def test_mail_armor_is_out_of_scope_without_a_class_file_override(self):
        class_file = {**self.class_file, 'item_armor_subclass_effects': []}
        effect = effect_of(passive_effects(class_file, templar_passive(BLESSED_PADDING)), 0)
        self.assertEqual(effect.reason, 'closed: mail armor is out of scope')

    def test_other_out_of_scope_auras_stay_unmodelled(self):
        for spell_id, index, aura in ((706323, 0, 59), (705276, 0, 122), (560833, 0, 110)):
            effect = effect_of(self.effects(spell_id), index)
            self.assertEqual(effect.aura, aura)
            self.assertTrue(effect.reason.startswith('unmodelled: '), (spell_id, index, effect.reason))
            self.assertFalse(effect.reason.startswith('closed: '), (spell_id, index, effect.reason))

    def test_every_custom_class_classifies(self):
        classes = sorted({fields['ClassID'] for _, fields in table_rows(
            dataset(DBC_DIR), 'CharacterAdvancementClassTypes', ['ClassID', 'CustomClass'])
            if fields['CustomClass'] == 1})
        self.assertTrue(classes)
        for class_id in classes:
            class_file = {'class_id': class_id, 'level': LEVEL}
            for spell in class_spells(DBC_DIR, class_id, HEADER):
                if spell.passive:
                    for effect in passive_effects(class_file, spell):
                        self.assertTrue(effect.reason == '' or effect.reason.startswith('unmodelled: ')
                                        or effect.reason.startswith('closed: ')
                                        or ALIASED_REASON_MARKER in effect.reason,
                                        (class_id, spell.spell_id, effect.effect, effect.reason))


def labelled(steps: list[dict], suffix: str) -> list[dict]:
    return [step for step in steps if step.get('label', '').endswith(suffix)]


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class PassiveScenarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.class_file = load_class_file(TEMPLAR_CLASS_ID)

    def scenario(self, spell_id: int):
        return passive_scenario(self.class_file, templar_passive(spell_id))

    def test_blessed_padding_equips_its_mail_chest_at_the_class_level(self):
        for spell_id in (301311, 301360):
            scenario, _ = self.scenario(spell_id)
            self.assertEqual([player['level'] for player in scenario['players']], [self.class_file['level']])
            self.assertIn({'action': 'equip', 'actor': 'caster', 'item': 30298, 'slot': 4}, scenario['steps'])

    def test_item_armor_subclass_item_must_be_wearable_at_the_class_level(self):
        seeded = {'spell': BLESSED_PADDING, 'effect': 0, 'subclass': 3, 'item': 1065932, 'slot': 4}
        for entry, message in (({**seeded, 'required_level': self.class_file['level'] + 20}, 'requires level 80'),
                               ({**seeded, 'required_level': 60, 'level': 80}, 'cannot set its own level'),
                               (seeded, 'needs the RequiredLevel')):
            class_file = {**self.class_file, 'item_armor_subclass_effects': [entry]}
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, message):
                passive_scenario(class_file, templar_passive(BLESSED_PADDING))
        class_file = {**self.class_file, 'item_armor_subclass_effects': [{**seeded, 'required_level': 60}]}
        scenario, _ = passive_scenario(class_file, templar_passive(BLESSED_PADDING))
        self.assertEqual(scenario['players'][0]['level'], 60)
        self.assertIn({'action': 'add_item', 'actor': 'caster', 'item': 1065932}, scenario['steps'])

    def test_passive_scenario_measures_before_and_after_learn(self):
        scenario, expectations = self.scenario(PIOUS)
        steps = scenario['steps']
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': PIOUS})
        aura = steps[learn + 1]
        self.assertEqual((aura['label'], aura['metric'], aura['spell']), (f'{PIOUS} aura_present', 'aura', PIOUS))
        before = [step for step in steps[:learn] if step.get('label', '').endswith(' before')]
        after = [step for step in steps[learn + 2:] if step.get('label', '').endswith(' after')]
        plain_before = [step for step in before if step['metric'] == 'stat']
        plain_after = [step for step in after if step['metric'] == 'stat']
        self.assertEqual([(step['metric'], step['stat']) for step in plain_before],
                         [('stat', stat) for stat in range(STAT_COUNT)])
        self.assertEqual([step['label'] for step in plain_before],
                         [f'{PIOUS} e0 stat {stat} before' for stat in range(5)])
        self.assertEqual([step['label'].removesuffix(' after') for step in plain_after],
                         [step['label'].removesuffix(' before') for step in plain_before])
        exact_before = [step for step in before if step['metric'] == STAT_EXACT_METRIC]
        exact_after = [step for step in after if step['metric'] == STAT_EXACT_METRIC]
        self.assertEqual([step['label'] for step in exact_before],
                         [f'{PIOUS} e0 stat {stat} exact before' for stat in range(5)])
        self.assertEqual([step['label'] for step in exact_after],
                         [f'{PIOUS} e0 stat {stat} exact after' for stat in range(5)])
        self.assertEqual(len(steps), learn + 2 + len(after))
        self.assertIs(run.validate(scenario), scenario)
        self.assertEqual([expectation.check for expectation in expectations], [PASSIVE_DELTA] * STAT_COUNT)
        model = expectations[0].model
        self.assertEqual(set(model), MODEL_KEYS)
        self.assertEqual((model['before_label'], model['after_label'], model['aura_label']),
                         (f'{PIOUS} e0 stat 0 before', f'{PIOUS} e0 stat 0 after', f'{PIOUS} aura_present'))
        self.assertEqual((model['family'], model['metric'], model['relation'], model['points'], model['judged']),
                         ('P2', 'stat', 'scale', 5.0, True))
        self.assertEqual(expectations[0].label, f'{PIOUS} e0 stat 0')
        self.assertEqual(expectations[0].displayed, '$s1')

    def test_spell_modifier_steps(self):
        scenario, expectations = self.scenario(LIBERTY)
        targets = {target.spell_id for target in effect_of(self.effects(LIBERTY), 0).targets}
        for suffix in (' before', ' after'):
            modifiers = [step for step in labelled(scenario['steps'], suffix) if step['metric'] == 'spell_modifier']
            self.assertEqual(sorted(step['spell'] for step in modifiers), sorted(targets))
            self.assertTrue(all((step['op'], step['base']) == (LIBERTY_OP, SPELL_MODIFIER_BASE)
                                for step in modifiers))
        model = next(expectation.model for expectation in expectations if expectation.model['target'] == LIBRAMS[0])
        self.assertEqual((model['named'], model['in_mask'], model['relation']), (False, True, 'spell_mod_flat'))
        self.assertEqual(model['before_label'], f'{LIBERTY} e0 spell_modifier {LIBRAMS[0]} before')
        run.validate(scenario)

    def test_no_step_for_unmodelled_effects(self):
        class_file = dict(self.class_file, passive_targets=[
            {'spell': CONDEMNATION, 'effect': 0, 'targets': [OATH_CONDEMN],
             'tooltip_words': 'critical strike chance gained through Condemn'}])
        scenario, expectations = passive_scenario(class_file, templar_passive(CONDEMNATION))
        self.assertFalse([step for step in scenario['steps']
                          if step.get('metric') == 'spell_modifier' and step['op'] == CONDEMNATION_OP])
        effect_1 = [expectation for expectation in expectations if expectation.effect_index == 1]
        self.assertEqual([expectation.check for expectation in effect_1], ['unmodelled'])
        self.assertEqual(effect_1[0].rule, 'unmodelled: SpellModOp 40 is not below MAX_SPELLMOD 32')
        run.validate(scenario)

    def test_effect_value_consumer_skips_targets_without_the_effect(self):
        scenario, expectations = self.scenario(MARTIAL_TRAINING)
        records = Records(dataset(DBC_DIR))
        values = [step for step in scenario['steps'] if step.get('metric') == 'spell_effect_value']
        self.assertTrue(values)
        for step in values:
            self.assertTrue(records.field('Spell', step['spell'], f'Effect[{step["effect"]}]'), step)
        skipped = [expectation for expectation in expectations if expectation.check == 'unmodelled'
                   and expectation.model and expectation.model['metric'] == 'spell_effect_value']
        for expectation in skipped:
            self.assertFalse(records.field('Spell', expectation.model['target'],
                                           f'Effect[{expectation.model["fields"]["effect"]}]'))
            self.assertTrue(expectation.rule.startswith('unmodelled: target '), expectation.rule)

    def test_pious_sweep_modifier_targets_tranquil_circle_not_chastise(self):
        scenario, expectations = self.scenario(PIOUS_SWEEP)
        modifiers = {step['spell'] for step in scenario['steps'] if step.get('metric') == 'spell_modifier'}
        self.assertNotIn(WRONGLY_NAMED_CHASTISE, modifiers)
        self.assertNotIn(TRANQUIL_CIRCLE_INCOMPLETE, modifiers)
        self.assertIn(TRANQUIL_CIRCLE, modifiers)
        values = {step['spell'] for step in scenario['steps'] if step.get('metric') == 'spell_effect_value'}
        self.assertIn(TRANQUIL_CIRCLE, values)
        self.assertNotIn(WRONGLY_NAMED_CHASTISE, values)
        self.assertNotIn(TRANQUIL_CIRCLE_INCOMPLETE, values)
        labels = {expectation.label for expectation in expectations}
        self.assertNotIn(f'{PIOUS_SWEEP} e1 spell_modifier {WRONGLY_NAMED_CHASTISE}', labels)
        self.assertNotIn(f'{PIOUS_SWEEP} e1 spell_modifier {TRANQUIL_CIRCLE_INCOMPLETE}', labels)
        self.assertIn(f'{PIOUS_SWEEP} e1 spell_modifier {TRANQUIL_CIRCLE}', labels)
        run.validate(scenario)

    def test_templars_might_modifier_targets_condemn_not_its_named_abilities(self):
        scenario, expectations = self.scenario(TEMPLARS_MIGHT)
        modifiers = [step for step in scenario['steps'] if step.get('metric') == 'spell_modifier']
        self.assertEqual({step['spell'] for step in modifiers}, {CONDEMN_AT_60})
        labels = {expectation.label for expectation in expectations}
        self.assertIn(f'{TEMPLARS_MIGHT} e0 spell_modifier {CONDEMN_AT_60}', labels)
        self.assertNotIn(f'{TEMPLARS_MIGHT} e0 spell_modifier {WRONGLY_NAMED_CHASTISE}', labels)
        run.validate(scenario)

    def test_spell_power_cost_skips_targets_with_no_plain_cost(self):
        scenario, expectations = self.scenario(BLESSED_STRIKES)
        costs = {step['spell'] for step in scenario['steps'] if step.get('metric') == 'spell_power_cost'}
        self.assertNotIn(501567, costs)
        self.assertNotIn(572741, costs)
        self.assertNotIn(704573, costs)
        self.assertIn(503141, costs)
        skipped = {expectation.model['target']: expectation.rule for expectation in expectations
                  if expectation.check == 'unmodelled' and expectation.model
                  and expectation.model.get('metric') == 'spell_power_cost'}
        for spell_id in (501567, 572741, 704573):
            self.assertEqual(skipped[spell_id], f'closed: target {spell_id} has no power cost to modify')
        run.validate(scenario)

    def test_spell_metrics_use_an_active_class_spell_of_the_school(self):
        scenario, expectations = self.scenario(SERENDIPITY)
        damage = next(step for step in scenario['steps'] if step.get('metric') == 'spell_damage_done')
        self.assertEqual((damage['spell'], damage['target']), (RECKONING_AT_60, TARGET))
        cost = next(step for step in scenario['steps'] if step.get('metric') == 'spell_power_cost')
        self.assertEqual(cost['spell'], CRUSADERS_BRAND)
        self.assertEqual([creature['id'] for creature in scenario['creatures']], [TARGET])
        self.assertIn(f'{SERENDIPITY} e0 spell_damage_done {RECKONING_AT_60}',
                      [expectation.label for expectation in expectations])
        run.validate(scenario)

    def test_physical_damage_done_is_measured_on_the_weapon_damage(self):
        _, expectations = self.scenario(SERENDIPITY)
        physical = next(entry for entry in expectations if entry.model.get('metric') == 'weapon_damage_min')
        self.assertEqual((physical.label, physical.model['fields'], physical.model['relation']),
                         (f'{SERENDIPITY} e0 weapon_damage_min 0', {'hand': 0}, 'ratio'))
        self.assertNotIn('melee_damage_done', [entry.model.get('metric') for entry in expectations])

    def test_healing_is_measured_against_an_extra_spell_heal_reference(self):
        scenario, expectations = self.scenario(SACRED_STYLE)
        taken = next(step for step in scenario['steps'] if step.get('metric') == 'spell_healing_taken')
        done = next(step for step in scenario['steps'] if step.get('metric') == 'spell_healing_done')
        self.assertEqual(taken['spell'], TEMPLE_GUARDIAN_HEAL)
        self.assertEqual(done['spell'], TEMPLE_GUARDIAN_HEAL)
        labels = {expectation.label for expectation in expectations}
        self.assertIn(f'{SACRED_STYLE} e0 spell_healing_taken {TEMPLE_GUARDIAN_HEAL}', labels)
        self.assertIn(f'{SACRED_STYLE} e1 spell_healing_done {TEMPLE_GUARDIAN_HEAL}', labels)
        run.validate(scenario)

    def test_reference_spell_searches_extra_spells_for_a_heal_effect(self):
        rank_id = reference_spell(self.class_file, Records(dataset(DBC_DIR)), 'spell_healing_taken', 2)
        self.assertEqual(rank_id, TEMPLE_GUARDIAN_HEAL)
        extra_spells = tuple(entry['spell'] for entry in self.class_file['extra_spells'])
        self.assertIn(TEMPLE_GUARDIAN_HEAL, active_class_ranks(DBC_DIR, self.class_file['class_id'],
                                                        self.class_file['level'], extra_spells))
        self.assertNotIn(TEMPLE_GUARDIAN_HEAL, active_class_ranks(DBC_DIR, self.class_file['class_id'],
                                                          self.class_file['level']))

    def test_reference_spell_still_unmodelled_without_a_matching_school_mask(self):
        with self.assertRaises(NotModelled):
            reference_spell(self.class_file, Records(dataset(DBC_DIR)), 'spell_healing_taken', 0)

    def test_points_only_effect_override_keeps_the_spell_dbc_misc_value(self):
        class_file = {'effect_overrides': [{'spell': UPHEAVE, 'effect': 0, 'base_points': 9, 'citation': 'points'}]}
        self.assertIsNone(effect_override(class_file, {UPHEAVE}, 0))
        self.assertEqual(effect_override(self.class_file, {UPHEAVE}, 0), 15)

    def test_dummy_target_brings_the_dummy(self):
        scenario, _ = self.scenario(UPHEAVE)
        crit = [step for step in scenario['steps'] if step.get('metric') == 'spell_critical_damage']
        self.assertTrue(crit and all(step['target'] == TARGET for step in crit))
        self.assertEqual([creature['id'] for creature in scenario['creatures']], [TARGET])

    def test_aliased_token_judges_against_the_owning_effects_value(self):
        _, expectations = self.scenario(FORTIFIED_BODY)
        expectation = next(entry for entry in expectations if entry.model and entry.model.get('metric')
                           == 'max_health')
        self.assertEqual(expectation.model['points'], 6.0)
        tooltips = compare.DbcTooltips(DBC_DIR)
        manifest = {'class_file': self.class_file, 'level': LEVEL}
        entry = {'key': 'aliased-token-test', 'spell_name': 'Fortified Body',
                 'expectations': [{'check': PASSIVE_DELTA, 'model': expectation.model,
                                   'displayed': expectation.displayed}]}
        before = 1000.0
        base_values = {'attack_power': 0.0, 'ranged_attack_power': 0.0,
                       **{spell_power_label(school): 0.0 for school in range(1, 7)},
                       **{stat_label(stat): 0.0 for stat in range(STAT_COUNT)},
                       expectation.model['aura_label']: 1.0, expectation.model['before_label']: before}

        def verdict_for(after: float):
            values = {**base_values, expectation.model['after_label']: after}
            run = compare.Run('aliased-token-test', 'ok', '', values, [], None)
            return compare.judge_passive(manifest, entry, run, expectation, tooltips)

        self.assertEqual(verdict_for(before * 1.06).status, 'ok')
        self.assertEqual(verdict_for(before * 1.10).status, 'alert')

    def test_parry_chance_probe_primes_can_parry_before_the_baseline(self):
        scenario, _ = self.scenario(JUDICATOR)
        steps = scenario['steps']
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': JUDICATOR})
        before = next(index for index, step in enumerate(steps) if step.get('label', '').endswith(' before'))
        priming = steps[before - 2:before]
        self.assertEqual([(step['action'], step['spell'], step['stacks']) for step in priming],
                         [('set_aura', JUDICATOR, 1), ('set_aura', JUDICATOR, 0)])
        self.assertTrue(all(step['actor'] == CASTER for step in priming))
        self.assertLess(before, learn)
        self.assertTrue(any(step.get('metric') == PARRY_CHANCE for step in steps[before:]))
        run.validate(scenario)

    def test_stat_probe_adds_a_parallel_exact_measurement(self):
        scenario, expectations = self.scenario(BELLS_OF_LIGHT)
        model = next(expectation.model for expectation in expectations
                    if expectation.model and expectation.model.get('metric') == STAT_METRIC
                    and expectation.model['fields'] == {'stat': 3})
        self.assertEqual(model['exact_before_label'], f'{BELLS_OF_LIGHT} e2 {STAT_METRIC} 3 exact before')
        self.assertEqual(model['exact_after_label'], f'{BELLS_OF_LIGHT} e2 {STAT_METRIC} 3 exact after')
        exact = [step for step in scenario['steps'] if step.get('metric') == STAT_EXACT_METRIC]
        labels = {step['label'] for step in exact}
        self.assertIn(model['exact_before_label'], labels)
        self.assertIn(model['exact_after_label'], labels)
        self.assertTrue(any(step['stat'] == 3 for step in exact))
        run.validate(scenario)

    def test_versus_aura_state_probe_adds_an_aura_state_measurement(self):
        scenario, expectations = self.scenario(PIOUS_SWEEP)
        model = next(expectation.model for expectation in expectations
                    if expectation.model and expectation.model.get('metric') == 'spell_damage_done')
        self.assertIsNotNone(model['aura_state_label'])
        state_steps = [step for step in scenario['steps'] if step.get('metric') == AURA_STATE_METRIC]
        self.assertEqual(len(state_steps), 1)
        state_step = state_steps[0]
        self.assertEqual((state_step['label'], state_step['target'], state_step['aura_state']),
                         (model['aura_state_label'], TARGET, 23))
        steps = scenario['steps']
        learn = steps.index({'action': 'learn', 'actor': 'caster', 'spell': PIOUS_SWEEP})
        self.assertLess(steps.index(state_step), learn)
        run.validate(scenario)

    def test_every_templar_passive_scenario_validates(self):
        passives = [spell for spell in class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER) if spell.passive]
        records = Records(dataset(DBC_DIR))
        for spell in passives:
            scenario, expectations = passive_scenario(self.class_file, spell)
            self.assertEqual(len({expectation.label for expectation in expectations}), len(expectations), spell)
            if scenario is None:
                self.assertTrue(all(expectation.check == 'unmodelled' for expectation in expectations), spell)
                continue
            run.validate(scenario)
            for step in scenario['steps']:
                if step.get('metric') == 'spell_modifier':
                    self.assertLess(step['op'], MAX_SPELLMOD)
                if step.get('metric') == 'spell_effect_value':
                    self.assertTrue(records.field('Spell', step['spell'], f'Effect[{step["effect"]}]'), step)
            labels = {step.get('label') for step in scenario['steps']}
            for expectation in expectations:
                if expectation.check == PASSIVE_DELTA:
                    self.assertIn(expectation.model['before_label'], labels)
                    self.assertIn(expectation.model['after_label'], labels)

    def effects(self, spell_id: int):
        return passive_effects(self.class_file, templar_passive(spell_id))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class GeneratePassiveTest(unittest.TestCase):
    def setUp(self):
        self.out = Path(tempfile.mkdtemp(prefix='conformance-passive-'))

    def tearDown(self):
        shutil.rmtree(self.out)

    def test_passives_lose_the_hit_placeholder(self):
        from conformance import generate
        manifest = json.loads(generate(TEMPLAR_CLASS_ID, self.out, spells=[PIOUS]).read_text(encoding='utf-8'))
        kinds = [entry['kind'] for entry in manifest['scenarios'] if entry['spell_id'] == PIOUS]
        self.assertNotIn('hit', kinds)
        self.assertEqual(kinds.count('passive'), 1)
        entry = next(entry for entry in manifest['scenarios'] if entry['kind'] == 'passive')
        self.assertEqual(entry['key'], f'conformance-templar-passive-{PIOUS}')
        self.assertTrue((self.out / entry['file']).is_file())

    def test_passive_flag_generates_only_passive_scenarios(self):
        from conformance import main
        self.assertEqual(main(['generate', '--class', str(TEMPLAR_CLASS_ID), '--out', str(self.out),
                               '--passive', str(PIOUS), '--passive', str(LIBERTY)]), 0)
        manifest = json.loads((self.out / 'manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(sorted((entry['kind'], entry['spell_id']) for entry in manifest['scenarios']),
                         [('passive', LIBERTY), ('passive', PIOUS)])

    def test_passive_flag_refuses_an_active_spell(self):
        from conformance import generate
        with self.assertRaises(ValueError):
            generate(TEMPLAR_CLASS_ID, self.out, passives=[RECKONING_AT_60])


if __name__ == '__main__':
    unittest.main()
