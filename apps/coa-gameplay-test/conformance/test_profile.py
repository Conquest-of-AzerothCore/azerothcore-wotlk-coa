import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from classes import RANK_SLOTS, class_spells, class_type_ids, dataset, table_rows
from hits import Unmodelled, records_of, reference_hit_model, weapon_note
import profile
from profile import (ATTACK_FIELDS, EQUIP_FIELDS, MAIN_HAND, OFF_HAND, RANGED, WEAPON_REQUIREMENT_FIELDS, armed,
                     SERVER_INVENTORY_MASKS, WEAPON_SET_SPELLS, attack_hand, base_steps, check_server_inventory_masks,
                     check_weapon_set_relearns, check_weapon_set_spells, check_weapon_sets, class_file_among,
                     for_entry, load_class_file, load_fixture_class_file, server_requirement, skill_label, unfit_reason,
                     weapon_set_unfit_reason)
from tooltip import DataSet
from values import armed_for, equip_requirement, weapon_requirement

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'
ITEM_RECORD = struct.Struct('<3i')

TEMPLAR_CLASS_ID = 19
WITCH_HUNTER_CLASS_ID = 15
BLACK_KNIGHT, INQUISITION, BOLTSLINGER, HOUNDMASTER = 'Black Knight', 'Inquisition', 'Boltslinger', 'Houndmaster'
TAB_WEAPON_SETS = {39: BOLTSLINGER, 40: HOUNDMASTER, 41: INQUISITION, 94: BLACK_KNIGHT}
SCIMITAR, ZWEIHANDER, HEAVY_CROSSBOW, GUN = 2027, 2529, 15809, 3025
SWORDS_LINE, TWO_HANDED_SWORDS_LINE, CROSSBOWS_LINE, GUNS_LINE = 43, 55, 226, 46
NOCTIS_BLADE = 680615
GRASP_OF_THE_UNDYING_LEECH = 680483
DAMNATION_MAX_RANK = 520217
SHADOWBLAST = 804191
DUSK_BLADE = 802020
WIDE_SWINGS = 681098
GRASP_OF_THE_UNDYING = 707064
ONE_HAND_MASK = 41105
TWO_HAND_MASK = 1378
RANGED_MASK = 262156
DAGGER_MASK = 1 << 15
MELEE, RANGED_CLASS = 2, 3
REQUIRES_MAIN_HAND, REQUIRES_OFF_HAND = 0x400, 0x1000000
LEVEL_60_SKILL = 300
TORMENTOR_RANK_6 = 501349
OFF_HAND_TYPE_MASK = 1 << 22
RANGED_TYPE, RANGED_RIGHT_TYPE = 15, 26
REPAIRED_TORMENTOR_MASK = OFF_HAND_TYPE_MASK | 1 << RANGED_TYPE | 1 << RANGED_RIGHT_TYPE
VALKYRS_GRIP = 707072
SEEDED_SET_SPELL = 900001


def spell(item_class=-1, subclasses=0, inventory_types=0, damage_class=0, attributes_ex3=0):
    fields = dict.fromkeys(WEAPON_REQUIREMENT_FIELDS, 0)
    fields.update({'EquippedItemClass': item_class, 'EquippedItemSubClassMask': subclasses,
                   'EquippedItemInventoryTypeMask': inventory_types, 'DmgClass': damage_class,
                   'AttributesEx3': attributes_ex3})
    return fields


def spec_spell(class_file, name):
    return int(next(spell_id for spell_id, set_name in class_file['spell_weapon_sets'].items() if set_name == name))


def equips(steps):
    return [(step['item'], step['slot']) for step in steps if step['action'] == 'equip']


def learned_before_first_equip(steps):
    first_equip = next(index for index, step in enumerate(steps) if step['action'] in ('add_item', 'equip'))
    return [step['spell'] for step in steps[:first_equip] if step['action'] == 'learn']


def learned(steps):
    return [step['spell'] for step in steps if step['action'] == 'learn']


class WeaponSetChoiceTest(unittest.TestCase):
    def setUp(self):
        self.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)

    def test_a_spell_without_a_weapon_requirement_takes_its_spec_set_and_the_set_skill_lines(self):
        black_knight = armed(self.witch_hunter, spell(), spec_spell(self.witch_hunter, BLACK_KNIGHT))
        self.assertEqual(black_knight['weapon_set'], BLACK_KNIGHT)
        self.assertEqual(black_knight['weapon']['item'], ZWEIHANDER)
        self.assertIn(TWO_HANDED_SWORDS_LINE, black_knight['skill_lines'])
        self.assertEqual(black_knight['reference_stats'][skill_label(TWO_HANDED_SWORDS_LINE)], LEVEL_60_SKILL)
        self.assertEqual(armed(self.witch_hunter, spell(), None)['weapon_set'], HOUNDMASTER)

    def test_the_spell_requirement_wins_over_its_spec_set_in_the_default_then_listed_order(self):
        one_hand = armed(self.witch_hunter, spell(2, ONE_HAND_MASK, damage_class=MELEE),
                         spec_spell(self.witch_hunter, BLACK_KNIGHT))
        self.assertEqual((one_hand['weapon_set'], one_hand['weapon']['item']), (HOUNDMASTER, SCIMITAR))
        two_hand = armed(self.witch_hunter, spell(2, TWO_HAND_MASK, damage_class=MELEE),
                         spec_spell(self.witch_hunter, INQUISITION))
        self.assertEqual((two_hand['weapon_set'], two_hand['weapon']['item']), (BLACK_KNIGHT, ZWEIHANDER))

    def test_a_requirement_no_set_meets_keeps_the_spec_set(self):
        unfit = armed(self.witch_hunter, spell(2, DAGGER_MASK, damage_class=MELEE),
                      spec_spell(self.witch_hunter, BLACK_KNIGHT))
        self.assertEqual(unfit['weapon_set'], BLACK_KNIGHT)

    def test_weapon_is_the_hand_of_the_spell_attack_type(self):
        self.assertEqual(attack_hand(spell(damage_class=MELEE)), MAIN_HAND)
        self.assertEqual(attack_hand(spell(damage_class=MELEE, attributes_ex3=REQUIRES_OFF_HAND)), OFF_HAND)
        self.assertEqual(attack_hand(spell(2, RANGED_MASK, damage_class=RANGED_CLASS)), RANGED)
        self.assertEqual(attack_hand(spell(2, ONE_HAND_MASK, damage_class=RANGED_CLASS)), MAIN_HAND)
        self.assertEqual(attack_hand({name: 0 for name in EQUIP_FIELDS}), MAIN_HAND)
        houndmaster = armed(self.witch_hunter, spell(2, RANGED_MASK, damage_class=RANGED_CLASS), None)
        self.assertEqual((houndmaster['weapon_set'], houndmaster['weapon']['item']), (HOUNDMASTER, GUN))
        boltslinger_melee = armed(self.witch_hunter, spell(damage_class=MELEE),
                                  spec_spell(self.witch_hunter, BOLTSLINGER))
        self.assertEqual((boltslinger_melee['weapon_set'], boltslinger_melee['weapon']['item']),
                         (BOLTSLINGER, SCIMITAR))
        boltslinger_ranged = armed(self.witch_hunter, spell(2, RANGED_MASK, damage_class=RANGED_CLASS),
                                   spec_spell(self.witch_hunter, BOLTSLINGER))
        self.assertEqual((boltslinger_ranged['weapon_set'], boltslinger_ranged['weapon']['item']),
                         (BOLTSLINGER, HEAVY_CROSSBOW))

    def test_a_hand_attribute_needs_that_hand_to_fit(self):
        sets = self.witch_hunter['weapon_sets']
        self.assertIsNone(weapon_set_unfit_reason(sets[BOLTSLINGER], spell(2, RANGED_MASK)))
        self.assertEqual(weapon_set_unfit_reason(sets[BOLTSLINGER], spell(2, RANGED_MASK,
                                                                          attributes_ex3=REQUIRES_MAIN_HAND)),
                         'main_hand: EquippedItemSubClassMask 262156 excludes the reference weapon subclass 7')
        self.assertEqual(weapon_set_unfit_reason(sets[BLACK_KNIGHT], spell(2, TWO_HAND_MASK,
                                                                           attributes_ex3=REQUIRES_OFF_HAND)),
                         'off_hand: EquippedItemClass 2 needs a reference weapon')
        self.assertIsNone(weapon_set_unfit_reason(sets[INQUISITION], spell(2, ONE_HAND_MASK,
                                                                           attributes_ex3=REQUIRES_OFF_HAND)))

    def test_an_armed_set_that_fits_the_next_spell_is_kept_with_that_spell_hand(self):
        black_knight = armed(self.witch_hunter, spell(2, TWO_HAND_MASK, damage_class=MELEE), None)
        self.assertEqual(armed(black_knight, spell(), spec_spell(self.witch_hunter, INQUISITION)), black_knight)
        self.assertEqual(armed(black_knight, spell(2, RANGED_MASK, damage_class=RANGED_CLASS), None)['weapon_set'],
                         HOUNDMASTER)
        houndmaster = armed(self.witch_hunter, spell(damage_class=MELEE), None)
        ranged = armed(houndmaster, spell(2, RANGED_MASK, damage_class=RANGED_CLASS), None)
        self.assertEqual((ranged['weapon_set'], ranged['weapon']['item']), (HOUNDMASTER, GUN))

    def test_an_entry_wears_its_own_spell_set_unless_the_cast_spell_requirement_excludes_it(self):
        inquisition_entry = for_entry(self.witch_hunter, spec_spell(self.witch_hunter, INQUISITION))
        self.assertEqual(inquisition_entry['weapon_set'], INQUISITION)
        cast = armed(inquisition_entry, spell(damage_class=MELEE), spec_spell(self.witch_hunter, BLACK_KNIGHT))
        self.assertEqual((cast['weapon_set'], cast['weapon']['item']), (INQUISITION, SCIMITAR))
        two_hand = armed(inquisition_entry, spell(2, TWO_HAND_MASK, damage_class=MELEE),
                         spec_spell(self.witch_hunter, INQUISITION))
        self.assertEqual(two_hand['weapon_set'], BLACK_KNIGHT)
        self.assertEqual(equips(base_steps(inquisition_entry)), [(SCIMITAR, 15), (SCIMITAR, 16)])
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        self.assertIs(for_entry(templar, NOCTIS_BLADE), templar)

    def test_classes_without_weapon_sets_keep_the_weapon_path(self):
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        self.assertIs(armed(templar, spell(2, TWO_HAND_MASK, damage_class=MELEE), NOCTIS_BLADE), templar)
        self.assertNotIn('weapon_set', armed(templar, spell(2, ONE_HAND_MASK, damage_class=MELEE)))
        self.assertTrue(set(ATTACK_FIELDS).isdisjoint(EQUIP_FIELDS))


class WeaponSetStepsTest(unittest.TestCase):
    def setUp(self):
        self.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)

    def test_base_steps_equip_every_hand_of_the_default_set_and_set_its_skills(self):
        steps = base_steps(self.witch_hunter)
        self.assertEqual(equips(steps), [(SCIMITAR, 15), (SCIMITAR, 16), (GUN, 17)])
        skills = [step['skill'] for step in steps if step['action'] == 'set_skill']
        self.assertIn(SWORDS_LINE, skills)
        self.assertIn(GUNS_LINE, skills)
        self.assertNotIn(CROSSBOWS_LINE, skills)
        self.assertEqual(base_steps(armed(self.witch_hunter, spell(), None)), steps)

    def test_base_steps_of_an_armed_set_equip_only_its_hands(self):
        black_knight = armed(self.witch_hunter, spell(2, TWO_HAND_MASK, damage_class=MELEE), None)
        self.assertEqual(equips(base_steps(black_knight)), [(ZWEIHANDER, 15)])
        boltslinger = armed(self.witch_hunter, spell(), spec_spell(self.witch_hunter, BOLTSLINGER))
        self.assertEqual(equips(base_steps(boltslinger)), [(SCIMITAR, 15), (SCIMITAR, 16), (HEAVY_CROSSBOW, 17)])

    def test_classes_without_weapon_sets_equip_their_weapon(self):
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        self.assertEqual(equips(base_steps(templar)), [(templar['weapon']['item'], 15)])


class WeaponSetSpellsTest(unittest.TestCase):
    def setUp(self):
        self.plain = load_class_file(WITCH_HUNTER_CLASS_ID)
        self.witch_hunter = {**self.plain, WEAPON_SET_SPELLS: {BLACK_KNIGHT: [VALKYRS_GRIP, SEEDED_SET_SPELL]}}

    def test_the_set_spells_are_learned_after_the_settle_and_before_the_set_is_equipped(self):
        black_knight = armed(self.witch_hunter, spell(2, TWO_HAND_MASK, damage_class=MELEE), None)
        steps = base_steps(black_knight)
        self.assertEqual(steps[0]['label'], 'settle')
        self.assertEqual(learned_before_first_equip(steps), [VALKYRS_GRIP, SEEDED_SET_SPELL])
        self.assertEqual(learned(steps), [VALKYRS_GRIP, SEEDED_SET_SPELL])
        self.assertEqual(equips(steps), [(ZWEIHANDER, 15)])

    def test_only_the_scenario_set_learns_its_spells(self):
        self.assertEqual(learned(base_steps(self.witch_hunter)), [])
        for name in (INQUISITION, BOLTSLINGER, HOUNDMASTER):
            with self.subTest(set=name):
                self.assertEqual(learned(base_steps(for_entry(self.witch_hunter, spec_spell(self.witch_hunter, name)))),
                                 [])
        entry = for_entry(self.witch_hunter, spec_spell(self.witch_hunter, BLACK_KNIGHT))
        self.assertEqual(learned(base_steps(entry)), [VALKYRS_GRIP, SEEDED_SET_SPELL])
        cast = armed(entry, spell(damage_class=MELEE), spec_spell(self.witch_hunter, INQUISITION))
        self.assertEqual((cast['weapon_set'], learned(base_steps(cast))),
                         (BLACK_KNIGHT, [VALKYRS_GRIP, SEEDED_SET_SPELL]))
        switched = armed(for_entry(self.witch_hunter, spec_spell(self.witch_hunter, INQUISITION)),
                         spell(2, TWO_HAND_MASK, damage_class=MELEE), None)
        self.assertEqual((switched['weapon_set'], learned(base_steps(switched))),
                         (BLACK_KNIGHT, [VALKYRS_GRIP, SEEDED_SET_SPELL]))

    def test_without_the_field_the_steps_are_unchanged(self):
        for name in self.plain['weapon_sets']:
            with self.subTest(set=name):
                own = for_entry(self.plain, spec_spell(self.plain, name))
                seeded = for_entry(self.witch_hunter, spec_spell(self.witch_hunter, name))
                expected = base_steps(own)
                if name == BLACK_KNIGHT:
                    expected = expected[:1] + [{'action': 'learn', 'actor': 'caster', 'spell': spell_id}
                                               for spell_id in (VALKYRS_GRIP, SEEDED_SET_SPELL)] + expected[1:]
                self.assertEqual(base_steps(seeded), expected)
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        self.assertEqual(learned(base_steps(templar)), [])

    def test_a_mutant_that_learns_every_set_spell_is_caught(self):
        def leaking(class_file, name):
            return [spell_id for spells in class_file.get(WEAPON_SET_SPELLS, {}).values() for spell_id in spells]
        with mock.patch.object(profile, 'weapon_set_spells', leaking):
            leaked = learned(base_steps(for_entry(self.witch_hunter, spec_spell(self.witch_hunter, INQUISITION))))
        self.assertEqual(leaked, [VALKYRS_GRIP, SEEDED_SET_SPELL])
        self.assertNotEqual(leaked, learned(base_steps(for_entry(self.witch_hunter,
                                                                 spec_spell(self.witch_hunter, INQUISITION)))))

    def test_a_key_that_is_not_a_set_or_a_value_that_is_not_spell_ids_is_refused(self):
        check_weapon_set_spells(self.witch_hunter)
        check_weapon_set_spells(self.plain)
        for name, field in (('unknown set', {'Valkyr': [VALKYRS_GRIP]}),
                            ('empty', {BLACK_KNIGHT: []}),
                            ('not a list', {BLACK_KNIGHT: VALKYRS_GRIP}),
                            ('text id', {BLACK_KNIGHT: [str(VALKYRS_GRIP)]}),
                            ('boolean', {BLACK_KNIGHT: [True]}),
                            ('zero', {BLACK_KNIGHT: [0]}),
                            ('twice', {BLACK_KNIGHT: [VALKYRS_GRIP, VALKYRS_GRIP]})):
            with self.subTest(case=name), self.assertRaisesRegex(ValueError, WEAPON_SET_SPELLS):
                check_weapon_set_spells({**self.plain, WEAPON_SET_SPELLS: field})
        templar = load_fixture_class_file(TEMPLAR_CLASS_ID)
        with self.assertRaisesRegex(ValueError, 'not in weapon_sets'):
            check_weapon_set_spells({**templar, WEAPON_SET_SPELLS: {'Valkyr': [VALKYRS_GRIP]}})

    def test_loading_a_class_file_runs_the_check(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'seeded.json'
            path.write_text(json.dumps({**self.plain, WEAPON_SET_SPELLS: {'Valkyr': [1]}}), encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Valkyr is not in weapon_sets'):
                class_file_among([path], WITCH_HUNTER_CLASS_ID)

    def test_a_scenario_that_learns_a_set_spell_again_while_it_is_learned_is_refused(self):
        entry = for_entry(self.witch_hunter, spec_spell(self.witch_hunter, BLACK_KNIGHT))
        relearn = {'action': 'learn', 'actor': 'caster', 'spell': VALKYRS_GRIP}
        unlearn = {'action': 'unlearn', 'actor': 'caster', 'spell': VALKYRS_GRIP}
        steps = base_steps(entry)
        check_weapon_set_relearns(entry, 'seeded', {'steps': steps})
        check_weapon_set_relearns(entry, 'seeded', {'steps': steps + [unlearn, relearn]})
        with self.assertRaisesRegex(ValueError, f'seeded learns {VALKYRS_GRIP} again'):
            check_weapon_set_relearns(entry, 'seeded', {'steps': steps + [relearn]})
        inquisition = for_entry(self.witch_hunter, spec_spell(self.witch_hunter, INQUISITION))
        check_weapon_set_relearns(inquisition, 'seeded', {'steps': base_steps(inquisition) + [relearn]})
        plain = for_entry(self.plain, spec_spell(self.plain, BLACK_KNIGHT))
        check_weapon_set_relearns(plain, 'seeded', {'steps': base_steps(plain) + [relearn, relearn]})


class WeaponSetRelearnWriterTest(unittest.TestCase):
    def test_the_manifest_writer_refuses_a_relearn_before_writing_the_scenario(self):
        from conformance import ManifestWriter
        witch_hunter = {**load_class_file(WITCH_HUNTER_CLASS_ID), WEAPON_SET_SPELLS: {BLACK_KNIGHT: [VALKYRS_GRIP]}}
        entry = for_entry(witch_hunter, spec_spell(witch_hunter, BLACK_KNIGHT))
        relearn = {'action': 'learn', 'actor': 'caster', 'spell': VALKYRS_GRIP}
        with tempfile.TemporaryDirectory() as folder:
            writer = ManifestWriter(witch_hunter, Path(folder))
            with self.assertRaisesRegex(ValueError, f'relearn-seed learns {VALKYRS_GRIP} again'):
                writer.add('relearn-seed', 'passive', None, VALKYRS_GRIP, [],
                           {'steps': base_steps(entry) + [relearn]})
            self.assertEqual((writer.entries, list(Path(folder).rglob('*'))), ([], []))


class WeaponSetCheckTest(unittest.TestCase):
    def setUp(self):
        self.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)

    def test_the_class_file_sets_pass_the_check(self):
        check_weapon_sets(self.witch_hunter)
        self.assertEqual(self.witch_hunter['default_weapon_set'], HOUNDMASTER)
        self.assertEqual(self.witch_hunter['weapon'], self.witch_hunter['weapon_sets'][HOUNDMASTER][MAIN_HAND])

    def test_an_unknown_set_name_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'Shieldbearer'):
            check_weapon_sets({**self.witch_hunter, 'spell_weapon_sets': {str(NOCTIS_BLADE): 'Shieldbearer'}})
        with self.assertRaisesRegex(ValueError, 'Shieldbearer'):
            check_weapon_sets({**self.witch_hunter, 'default_weapon_set': 'Shieldbearer'})

    def test_a_hand_in_the_wrong_slot_or_a_missing_hand_is_refused(self):
        sets = self.witch_hunter['weapon_sets']
        swapped = {**sets, INQUISITION: {**sets[INQUISITION], OFF_HAND: sets[INQUISITION][MAIN_HAND]}}
        with self.assertRaisesRegex(ValueError, 'not in slot 16'):
            check_weapon_sets({**self.witch_hunter, 'weapon_sets': swapped})
        missing = {**sets, BOLTSLINGER: {RANGED: sets[BOLTSLINGER][RANGED]}}
        with self.assertRaisesRegex(ValueError, 'needs the hands'):
            check_weapon_sets({**self.witch_hunter, 'weapon_sets': missing})

    def test_a_weapon_other_than_the_default_main_hand_is_refused(self):
        with self.assertRaisesRegex(ValueError, 'default weapon set main hand'):
            check_weapon_sets({**self.witch_hunter,
                               'weapon': self.witch_hunter['weapon_sets'][BLACK_KNIGHT][MAIN_HAND]})


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class WeaponSetDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.records = records_of(cls.witch_hunter)

    def test_every_set_weapon_subclass_is_the_item_record_subclass(self):
        table = DataSet(DBC_DIR).load('Item')[0]
        items = {item: (item_class, subclass) for item, item_class, subclass
                 in (ITEM_RECORD.unpack_from(table.record(row)) for row in range(table.rows))}
        for name, hands in self.witch_hunter['weapon_sets'].items():
            for hand, weapon in hands.items():
                if weapon is not None:
                    with self.subTest(set=name, hand=hand):
                        self.assertEqual(items[weapon['item']], (2, weapon['subclass']))

    def test_spell_weapon_sets_follow_the_advancement_tab_unless_the_dbc_requirement_excludes_it(self):
        dbc = dataset(DBC_DIR)
        types = class_type_ids(dbc, WITCH_HUNTER_CLASS_ID)
        rank_fields = [f'RankSpell[{slot}]' for slot in range(RANK_SLOTS)]
        tab_of = {fields[field]: fields['Tab']
                  for _, fields in table_rows(dbc, 'CharacterAdvancement', ['ClassType', 'Tab'] + rank_fields)
                  if fields['ClassType'] in types for field in rank_fields if fields[field]}
        expected = {}
        for class_spell in class_spells(DBC_DIR, WITCH_HUNTER_CLASS_ID, HEADER, self.witch_hunter['level'],
                                        self.witch_hunter.get('extra_spells', [])):
            tab = next((tab_of[rank] for rank in class_spell.ranks if rank in tab_of), None)
            if tab in TAB_WEAPON_SETS:
                for rank in class_spell.ranks:
                    expected[str(rank)] = armed_for(
                        {**self.witch_hunter, 'spell_weapon_sets': {str(rank): TAB_WEAPON_SETS[tab]}},
                        self.records, rank)['weapon_set']
        self.assertEqual(self.witch_hunter['spell_weapon_sets'], expected)

    def test_two_handed_and_ranged_spells_take_their_sets_from_the_dbc(self):
        for spell_id in (NOCTIS_BLADE, GRASP_OF_THE_UNDYING_LEECH, WIDE_SWINGS, GRASP_OF_THE_UNDYING):
            with self.subTest(spell=spell_id):
                black_knight = armed_for(self.witch_hunter, self.records, spell_id)
                self.assertEqual(black_knight['weapon_set'], BLACK_KNIGHT)
        damnation = armed_for(self.witch_hunter, self.records, DAMNATION_MAX_RANK)
        self.assertEqual((damnation['weapon_set'], damnation['weapon']['item']), (BOLTSLINGER, HEAVY_CROSSBOW))
        dusk_blade = armed_for(self.witch_hunter, self.records, DUSK_BLADE)
        self.assertEqual((dusk_blade['weapon_set'], equips(base_steps(dusk_blade))),
                         (INQUISITION, [(SCIMITAR, 15), (SCIMITAR, 16)]))

    def test_the_weapon_note_names_a_set_taken_over_the_spec_set(self):
        self.assertEqual(weapon_note(self.witch_hunter, armed_for(self.witch_hunter, self.records, NOCTIS_BLADE),
                                     self.records, NOCTIS_BLADE), '')
        note = weapon_note(self.witch_hunter,
                           armed_for(self.witch_hunter, self.records, GRASP_OF_THE_UNDYING_LEECH),
                           self.records, GRASP_OF_THE_UNDYING_LEECH)
        self.assertTrue(note.startswith(f'; weapon set {BLACK_KNIGHT} ({HOUNDMASTER}: '), note)


def with_masks(class_file, masks):
    return {**class_file, SERVER_INVENTORY_MASKS: masks}


class ServerInventoryMaskCheckTest(unittest.TestCase):
    def setUp(self):
        self.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        self.entry = {'mask': REPAIRED_TORMENTOR_MASK, 'source': 'AscensionClassMechanics.cpp:1006-1019'}

    def test_the_class_file_entry_passes_and_carries_the_repaired_mask(self):
        check_server_inventory_masks(self.witch_hunter)
        self.assertEqual(self.witch_hunter[SERVER_INVENTORY_MASKS][str(TORMENTOR_RANK_6)]['mask'],
                         REPAIRED_TORMENTOR_MASK)
        check_server_inventory_masks({'class_id': 0})

    def test_an_entry_without_a_server_source_is_refused(self):
        for entry in ({'mask': REPAIRED_TORMENTOR_MASK}, {**self.entry, 'source': ' '},
                      {**self.entry, 'source': 7}):
            with self.subTest(entry=entry), self.assertRaisesRegex(ValueError, 'mask and source|server source'):
                check_server_inventory_masks(with_masks(self.witch_hunter, {'1': entry}))

    def test_an_entry_with_an_extra_field_or_a_mask_that_is_not_a_positive_integer_is_refused(self):
        cases = ({**self.entry, 'reason': 'x'}, {**self.entry, 'mask': 0}, {**self.entry, 'mask': True},
                 {**self.entry, 'mask': '71335936'})
        for entry in cases:
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                check_server_inventory_masks(with_masks(self.witch_hunter, {'1': entry}))

    def test_an_absent_entry_keeps_the_dbc_requirement_and_a_mask_dropping_dbc_bits_is_refused(self):
        requirement = spell(2, RANGED_MASK, OFF_HAND_TYPE_MASK)
        self.assertIs(server_requirement({'class_id': 0}, TORMENTOR_RANK_6, requirement), requirement)
        self.assertIs(server_requirement(self.witch_hunter, 1, requirement), requirement)
        self.assertEqual(server_requirement(self.witch_hunter, TORMENTOR_RANK_6, requirement)
                         ['EquippedItemInventoryTypeMask'], REPAIRED_TORMENTOR_MASK)
        dropping = with_masks(self.witch_hunter, {str(TORMENTOR_RANK_6): {**self.entry, 'mask': 1 << RANGED_TYPE}})
        with self.assertRaisesRegex(ValueError, 'drops bits of the DBC mask 4194304'):
            server_requirement(dropping, TORMENTOR_RANK_6, requirement)


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ServerInventoryMaskDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.witch_hunter = load_class_file(WITCH_HUNTER_CLASS_ID)
        cls.records = records_of(cls.witch_hunter)
        cls.without = {key: value for key, value in cls.witch_hunter.items() if key != SERVER_INVENTORY_MASKS}
        cls.mutant = with_masks(cls.witch_hunter, {str(TORMENTOR_RANK_6): {
            'mask': OFF_HAND_TYPE_MASK | 1 << RANGED_TYPE, 'source': 'mutant without INVTYPE_RANGEDRIGHT'}})

    def crossbow(self, class_file):
        return armed_for(class_file, self.records, TORMENTOR_RANK_6)['weapon']

    def test_the_raw_dbc_mask_excludes_the_boltslinger_crossbow(self):
        weapon = self.crossbow(self.without)
        self.assertEqual((weapon['item'], weapon['inventory_type']), (HEAVY_CROSSBOW, RANGED_RIGHT_TYPE))
        self.assertEqual(equip_requirement(self.records, TORMENTOR_RANK_6)['EquippedItemInventoryTypeMask'],
                         OFF_HAND_TYPE_MASK)
        self.assertEqual(unfit_reason(weapon, equip_requirement(self.records, TORMENTOR_RANK_6, self.without)),
                         'EquippedItemInventoryTypeMask 4194304 excludes the reference weapon inventory type 26')

    def test_the_server_repaired_mask_fits_the_crossbow_and_the_mutant_stays_unmodelled(self):
        weapon = self.crossbow(self.witch_hunter)
        self.assertEqual(weapon['item'], HEAVY_CROSSBOW)
        self.assertEqual(weapon_requirement(self.records, TORMENTOR_RANK_6, self.witch_hunter)
                         ['EquippedItemInventoryTypeMask'], REPAIRED_TORMENTOR_MASK)
        self.assertIsNone(unfit_reason(weapon, equip_requirement(self.records, TORMENTOR_RANK_6, self.witch_hunter)))
        unsplit = {key: value for key, value in self.witch_hunter.items() if key != 'rank_hit_effects'}
        with self.assertRaises(Unmodelled) as passed:
            reference_hit_model(unsplit, TORMENTOR_RANK_6)
        self.assertEqual(str(passed.exception), "effects of several hit models: ['periodic_damage', 'school']")
        for class_file, mask in ((self.without, OFF_HAND_TYPE_MASK), (self.mutant, OFF_HAND_TYPE_MASK | 1 << 15)):
            with self.subTest(mask=mask), self.assertRaises(Unmodelled) as raised:
                reference_hit_model(class_file, TORMENTOR_RANK_6)
            self.assertEqual(str(raised.exception),
                             f'EquippedItemInventoryTypeMask {mask} excludes the reference weapon inventory type 26')


class OffHandGrantTests(unittest.TestCase):
    WEAPON = {'item': 30754, 'slot': 16, 'subclass': 4, 'min_damage': 51.63, 'max_damage': 82.65, 'speed_ms': 1800,
              'inventory_type': 13, 'normalized_speed': 2.4, 'skill_line': 54}

    def test_grants_are_learned_before_the_off_hand_is_equipped(self):
        steps = profile.off_hand_steps(30754, (707072,))
        self.assertEqual([(step['action'], step.get('spell', step.get('item'))) for step in steps],
                         [('learn', 707072), ('add_item', 30754), ('equip', 30754)])

    def test_mutant_without_grants_the_steps_are_today_s(self):
        self.assertEqual(profile.off_hand_steps(30754), profile.off_hand_steps(30754, ()))
        self.assertNotIn('learn', [step['action'] for step in profile.off_hand_steps(30754)])

    def test_off_hand_grants_are_a_list_of_spell_ids(self):
        class_file = {'off_hand_weapons': [{**self.WEAPON, 'grants': [707072]}]}
        self.assertEqual(profile.off_hand_weapon(class_file, 30754)['grants'], [707072])
        for grants in (707072, [0], ['707072'], [True]):
            with self.subTest(grants=grants), self.assertRaisesRegex(ValueError, 'grants'):
                profile.off_hand_weapon({'off_hand_weapons': [{**self.WEAPON, 'grants': grants}]}, 30754)


if __name__ == '__main__':
    unittest.main()
