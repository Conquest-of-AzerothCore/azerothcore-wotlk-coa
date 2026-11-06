from collections import Counter
from pathlib import Path
import struct
import tempfile
import unittest

from classes import PROGRESSION_HEADER as HEADER, ClassSpell, class_spells, table_rows
from passives import (FAMILIES, MAX_SPELLMOD, PHRASES, MetricPlan, PassiveTarget, family_of, named_targets,
                      passive_effects, stat_after_token)
from profile import load_class_file
from tooltip import Records
from values import dataset
import schemas

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
AGGRAMARS_RAGE = 561346
STURDY = 681009
BLESSED_PADDING = 301311
CALL_OF_THE_MONASTERY = 560550
LIGHTS_CHOSEN = 301310
BLESSED_STRIKES = 704180
CHAKRA_OF_LIGHT = (803159, 803844)
DEEP_SECRETS = 705263
FINESSE = 705271
MAGIC_SCHOOLS = [1, 2, 3, 4, 5, 6]
NO_NAMED_TARGET = 'unmodelled: the tooltip names none of the spells the class mask affects ('

SPELL_RECORD_BYTES = 936
SPELL_FIELDS = 234
PASSIVE = 0x40
APPLY_AURA = 6
FIXTURE_SPELL = 900001
FIXTURE_AURA = 999


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
        blessed_strikes = effect_of(self.effects(BLESSED_STRIKES), 0)
        self.assertNotIn('Oath', {target.name for target in blessed_strikes.targets if target.named})
        self.assertFalse(any(target.named for target in blessed_strikes.targets))
        self.assertTrue(blessed_strikes.reason.startswith(NO_NAMED_TARGET))
        for chakra in CHAKRA_OF_LIGHT:
            effect = effect_of(self.effects(chakra), 1)
            self.assertFalse(any(target.named for target in effect.targets))
            self.assertTrue(effect.reason.startswith(NO_NAMED_TARGET), effect.reason)
        self.assertTrue(effect_of(self.effects(DEEP_SECRETS), 0).reason.startswith(NO_NAMED_TARGET))

    def test_named_target_outside_the_mask_is_kept(self):
        effect = effect_of(self.effects(PATIENCE), 0)
        self.assertIn(INTERDICT, target_ids(effect, True, False))
        self.assertIn(SACRED_RESTRAINT, target_ids(effect, False, True))
        self.assertEqual(effect.reason, '')

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
        effects = self.effects(AGGRAMARS_RAGE)
        crit = plan_named(effect_of(effects, 0), 'spell_crit_chance')
        self.assertEqual((crit.fields, crit.relation), ({'school': 1}, 'add'))
        expertise = plan_named(effect_of(effects, 1), 'expertise')
        self.assertEqual(expertise.relation, 'add')

    def test_generic_crit_phrase_judges_melee_and_measures_spell_crit(self):
        effect = effect_of(self.effects(FINESSE), 0)
        melee = plan_named(effect, 'melee_crit_chance')
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

    def test_rating_mask_gives_one_plan_per_rating(self):
        effect = effect_of(self.effects(LIGHTS_CHOSEN), 1)
        self.assertEqual(sorted(plan.fields['rating'] for plan in effect.plans), [8, 10])
        self.assertEqual({plan.source for plan in effect.plans}, {'stat 3'})

    def test_quantity_missing_from_the_tooltip_is_unmodelled(self):
        effect = effect_of(self.effects(CALL_OF_THE_MONASTERY), 1)
        self.assertEqual(effect.reason, 'unmodelled: the tooltip does not name ranged attack power')
        self.assertEqual(effect.plans, ())

    def test_mail_armor_is_out_of_scope(self):
        effect = effect_of(self.effects(BLESSED_PADDING), 0)
        self.assertEqual(effect.reason, 'unmodelled: mail armor is out of scope')

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
                        self.assertTrue(effect.reason == '' or effect.reason.startswith('unmodelled: '),
                                        (class_id, spell.spell_id, effect.effect, effect.reason))


if __name__ == '__main__':
    unittest.main()
