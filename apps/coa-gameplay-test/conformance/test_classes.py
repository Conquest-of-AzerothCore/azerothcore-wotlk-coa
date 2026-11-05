from pathlib import Path
import struct
import tempfile
import unittest

from classes import ClassSpell, DataSet, advancement_levels, class_spells
import schemas

DBC_DIR = Path('/srv/coa/server-data/dbc')
HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'

TEMPLAR_CLASS_ID = 19
TEMPLAR_SPELL_IDS = 172
TEMPLAR_SPELL_IDS_WITH_RANKS = 221
SHARED_CLASS_TYPE = 12
ARGENT_BLADE = 804929
ARGENT_BLADE_RANKS = (804929, 807263, 807264, 807265, 807266, 807267, 807268)

SPELL_RECORD_BYTES = 936
ADVANCEMENT_RECORD_BYTES = 692
CLASS_TYPE_RECORD_BYTES = 92
PASSIVE = 0x40


def wdbc(rows, fields, size, strings):
    return struct.pack('<4s4I', b'WDBC', len(rows), fields, size, len(strings)) + b''.join(rows) + strings


def write_fixture(directory: Path, header: Path):
    registry = schemas.registry()
    offsets = {table: {column.name: column.offset for column in registry[table].columns}
               for table in ('Spell', 'CharacterAdvancement', 'CharacterAdvancementClassTypes')}
    names = {100: 'Alpha', 101: 'Beta', 200: 'Gamma', 300: 'Delta', 400: 'Epsilon', 500: 'Zeta'}
    strings, name_offset = b'\0', {}
    for spell_id, name in names.items():
        name_offset[spell_id] = len(strings)
        strings += name.encode() + b'\0'

    def spell(spell_id, attributes):
        row = bytearray(SPELL_RECORD_BYTES)
        struct.pack_into('<I', row, offsets['Spell']['Id'], spell_id)
        struct.pack_into('<I', row, offsets['Spell']['Attributes'], attributes)
        struct.pack_into('<I', row, offsets['Spell']['SpellName[enUS]'], name_offset[spell_id])
        return bytes(row)

    def advancement(identity, class_type, level, *rank_spells):
        row = bytearray(ADVANCEMENT_RECORD_BYTES)
        struct.pack_into('<I', row, offsets['CharacterAdvancement']['ID'], identity)
        struct.pack_into('<I', row, offsets['CharacterAdvancement']['ClassType'], class_type)
        struct.pack_into('<I', row, offsets['CharacterAdvancement']['RequiredLevel'], level)
        for slot, spell_id in enumerate(rank_spells):
            struct.pack_into('<I', row, offsets['CharacterAdvancement'][f'RankSpell[{slot}]'], spell_id)
        return bytes(row)

    def class_type(identity, class_id, custom):
        row = bytearray(CLASS_TYPE_RECORD_BYTES)
        struct.pack_into('<I', row, offsets['CharacterAdvancementClassTypes']['ID'], identity)
        struct.pack_into('<I', row, offsets['CharacterAdvancementClassTypes']['ClassID'], class_id)
        struct.pack_into('<I', row, offsets['CharacterAdvancementClassTypes']['CustomClass'], custom)
        return bytes(row)

    spells = [spell(100, 0), spell(101, 0), spell(200, PASSIVE), spell(300, 0), spell(400, 0), spell(500, 0)]
    advancements = [advancement(1, 5, 10, 100, 101), advancement(2, 5, 20, 200), advancement(3, 6, 30, 300),
                    advancement(4, 7, 40, 400), advancement(5, 8, 50, 500)]
    class_types = [class_type(5, 19, 1), class_type(6, 19, 0), class_type(7, 20, 1), class_type(8, 10, 0)]
    (directory / 'Spell.dbc').write_bytes(wdbc(spells, 234, SPELL_RECORD_BYTES, strings))
    (directory / 'CharacterAdvancement.dbc').write_bytes(wdbc(advancements, 179, ADVANCEMENT_RECORD_BYTES, b'\0'))
    (directory / 'CharacterAdvancementClassTypes.dbc').write_bytes(
        wdbc(class_types, 23, CLASS_TYPE_RECORD_BYTES, b'\0'))
    header.write_text('\n'.join([
        'inline constexpr std::array<Rank, 5> Ranks =', '{{',
        '    { 19, 200, 201, 30 },', '    { 19, 200, 202, 58 },', '    { 19, 200, 203, 64 },',
        '    { 19, 999, 998, 12 },', '    { 20, 400, 401, 10 },', '}};', '']), encoding='utf-8')


class FixtureClassSpellTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name)
        self.header = self.directory / 'progression.h'
        write_fixture(self.directory, self.header)

    def tearDown(self):
        self.temp.cleanup()

    def test_only_custom_class_types_of_the_class_are_listed(self):
        spells = class_spells(self.directory, 19, self.header)
        self.assertEqual([spell.spell_id for spell in spells], [100, 101, 200])
        self.assertEqual([spell.spell_id for spell in class_spells(self.directory, 20, self.header)], [400])

    def test_non_custom_class_id_is_rejected(self):
        with self.assertRaises(ValueError):
            class_spells(self.directory, 10, self.header)

    def test_ranks_follow_the_progression_header_in_order(self):
        spells = {spell.spell_id: spell for spell in class_spells(self.directory, 19, self.header)}
        self.assertEqual(spells[200].ranks, (200, 201, 202, 203))
        self.assertEqual(spells[100].ranks, (100,))
        self.assertEqual({spell.spell_id: spell.ranks for spell in class_spells(self.directory, 20, self.header)},
                         {400: (400, 401)})

    def test_max_rank_depends_on_the_character_level(self):
        by_level = {level: {spell.spell_id: spell.max_rank
                            for spell in class_spells(self.directory, 19, self.header, level)}
                    for level in (20, 30, 57, 58, 60, 64)}
        self.assertEqual([by_level[level][200] for level in (20, 30, 57, 58, 60, 64)],
                         [200, 201, 201, 202, 202, 203])
        self.assertEqual(by_level[60][100], 100)

    def test_fields_come_from_the_dbc_records(self):
        spells = {spell.spell_id: spell for spell in class_spells(self.directory, 19, self.header)}
        self.assertEqual(spells[200], ClassSpell(200, 'Gamma', (200, 201, 202, 203), 202, 20, True))
        self.assertEqual(spells[101], ClassSpell(101, 'Beta', (101,), 101, 10, False))


@unittest.skipUnless(DBC_DIR.is_dir(), f'client DBC set not found at {DBC_DIR}')
class ClientDbcClassSpellTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.templar = class_spells(DBC_DIR, TEMPLAR_CLASS_ID, HEADER)

    def test_templar_has_the_documented_number_of_spell_ids(self):
        self.assertEqual(len(self.templar), TEMPLAR_SPELL_IDS)
        self.assertEqual(len({spell.spell_id for spell in self.templar}), TEMPLAR_SPELL_IDS)
        self.assertEqual(sum(len(spell.ranks) for spell in self.templar), TEMPLAR_SPELL_IDS_WITH_RANKS)

    def test_argent_blade_ranks_come_from_the_progression_header(self):
        blade = next(spell for spell in self.templar if spell.spell_id == ARGENT_BLADE)
        self.assertEqual(blade.name, 'Argent Blade')
        self.assertEqual(blade.ranks, ARGENT_BLADE_RANKS)
        self.assertEqual(blade.max_rank, 807268)
        self.assertFalse(blade.passive)

    def test_shared_class_type_spells_are_never_returned_for_a_coa_class(self):
        shared = set(class_spells_of_class_type(SHARED_CLASS_TYPE))
        self.assertTrue(shared)
        for class_id in (12, TEMPLAR_CLASS_ID, 32):
            listed = {spell.spell_id for spell in class_spells(DBC_DIR, class_id, HEADER)}
            self.assertFalse(listed & shared, class_id)

    def test_passive_flag_is_present_for_some_but_not_all_spells(self):
        passives = [spell for spell in self.templar if spell.passive]
        self.assertTrue(passives)
        self.assertLess(len(passives), len(self.templar))


def class_spells_of_class_type(class_type: int):
    return advancement_levels(DataSet(DBC_DIR), {class_type})


if __name__ == '__main__':
    unittest.main()
