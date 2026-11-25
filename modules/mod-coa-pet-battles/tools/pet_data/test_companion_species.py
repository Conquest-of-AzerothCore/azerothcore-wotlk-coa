import collections
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import companion_species

BEAST, FLYING, MECHANICAL = 7, 2, 9
SIX = ((0, 1), (0, 10), (1, 2), (1, 15), (2, 4), (2, 20))
RETAIL_NAMES = {1: 'Bite', 2: 'Howl', 3: 'Leap', 4: 'Roar', 5: 'Pounce', 6: 'Rest', 7: 'Zap', 8: 'Shock',
                9: 'Bolt', 10: 'Spin', 11: 'Saw', 12: 'Fix', 13: 'Odd', 14: 'Gust'}


def kit_rows(kit, abilities):
    return [(kit, slot, level, ability) for (slot, level), ability in zip(SIX, abilities)]


def presentation(species, slot, option, level, ability, name, icon='Icon'):
    return (species, slot, option, level, ability, name, RETAIL_NAMES[ability], icon, f'{name} tip', 100 + ability,
            0, 'melee', 0, 0, 1, 0)


def make_tables():
    presentations = [presentation(7001, slot, 1 + (level > 9), level, ability, RETAIL_NAMES[ability])
                     for (_, slot, level, ability) in kit_rows(500, range(1, 7))]
    presentations[0] = presentation(7001, 0, 1, 1, 1, 'Bite')
    presentations += [presentation(7000, 0, 1, 1, 1, 'Chomp'), presentation(7000, 0, 2, 10, 2, 'Roar'),
                      presentation(7002, 0, 2, 10, 2, 'Roar'), presentation(7003, 0, 2, 10, 2, 'Yell')]
    presentations = [row for row in presentations if not (row[0] == 7001 and row[4] == 2)]
    presentations += [presentation(7002, slot, 1 + (level > 9), level, ability, f'Mech {ability}')
                      for (_, slot, level, ability) in kit_rows(1000002, range(7, 13))]
    presentations += [presentation(7000, slot, 1 + (level > 9), level, ability, f'Old {ability}')
                      for (_, slot, level, ability) in kit_rows(1000001, range(1, 7))[2:]]
    return {
        'coa_pet_ability': [(a, RETAIL_NAMES[a], BEAST, 0, '', 0) for a in range(1, 14)],
        'coa_pet_presentation': presentations,
        'coa_pet_kit': [(500, 'Prairie Pup', BEAST, 0, 0, 0), (501, 'Grey Wolf', BEAST, 0, 0, 0),
                        (1000001, 'Old Pup', BEAST, 1, 1, 1), (1000002, 'Bot', MECHANICAL, 0, 0, 0)],
        'coa_pet_kit_ability': kit_rows(500, range(1, 7)) + kit_rows(501, range(1, 7))[:3]
        + kit_rows(1000001, range(1, 7)) + kit_rows(1000002, range(7, 13)),
        'coa_pet_species': [(7000, 'Old Pup', 1000001, 0, 1, 0, 1, 1, 'Icon_Beast', 0.0),
                            (7001, 'Prairie Pup', 500, 1, 0, 0, 0, 1, 'Icon_Beast', 0.0),
                            (7002, 'Bot', 1000002, 1, 0, 0, 1, 1, 'Icon_Mech', 0.0),
                            (7003, 'Wolf', 501, 1, 0, 0, 0, 1, 'Icon_Wolf', 0.0)],
    }


def make_retail():
    species = {500: ('Prairie Pup', BEAST, range(1, 7)), 501: ('Grey Wolf', BEAST, range(1, 7)),
               502: ('Forest Cat', BEAST, (1, 2, 3, 4, 5, 6)), 503: ('Gear Bot', MECHANICAL, range(7, 13)),
               504: ('Odd Pup', BEAST, (13, 2, 3, 4, 5, 6)), 505: ('Fivepet', BEAST, range(1, 6)),
               506: ('Sky Hawk', FLYING, (14, 2, 3, 4, 5, 6))}
    links = [{'BattlePetSpeciesID': str(sid), 'SlotEnum': str(slot), 'RequiredLevel': str(level),
              'BattlePetAbilityID': str(ability)}
             for sid, (_, _, abilities) in species.items() for (slot, level), ability in zip(SIX, abilities)]
    links.append({'BattlePetSpeciesID': '500', 'SlotEnum': '-1', 'RequiredLevel': '0', 'BattlePetAbilityID': '99'})
    return {
        'species': [{'ID': str(sid), 'CreatureID': str(90000 + sid), 'PetTypeEnum': str(family)}
                    for sid, (_, family, _) in species.items()],
        'creatures': {str(90000 + sid): name for sid, (name, _, _) in species.items()},
        'links': links,
        'abilities': {str(a): {'ID': str(a), 'Name_lang': name} for a, name in RETAIL_NAMES.items()},
        'states': {'18': 'Stat_Power', '19': 'Stat_Stamina', '20': 'Stat_Speed', '40': 'Mod_Other'},
        'species_states': [{'BattlePetSpeciesID': '502', 'BattlePetStateID': '18', 'Value': '50'},
                           {'BattlePetSpeciesID': '502', 'BattlePetStateID': '19', 'Value': '-50'},
                           {'BattlePetSpeciesID': '502', 'BattlePetStateID': '40', 'Value': '9'}],
    }


def row(spell, creature, name, rule, family, kit='', source=''):
    return {'spell': str(spell), 'creature': str(creature), 'name': name, 'rule': rule, 'family': family,
            'kit': kit, 'source': source}


class DealingTest(unittest.TestCase):
    def setUp(self):
        self.tables = make_tables()
        self.retail = make_retail()
        self.qualifying = companion_species.qualifying_abilities(self.tables)
        self.kits = companion_species.retail_kits(self.retail, self.qualifying)
        self.pools = companion_species.pools(self.kits, self.tables)

    def test_only_kits_with_six_presented_abilities_are_dealt(self):
        self.assertEqual(self.qualifying, set(range(1, 13)))
        self.assertEqual(sorted(self.kits), [500, 501, 502, 503])
        self.assertEqual(self.kits[502].rows, ((0, 1, 1), (0, 10, 2), (1, 2, 3), (1, 15, 4), (2, 4, 5), (2, 20, 6)))
        self.assertEqual(self.kits[502].kind, 'cat')

    def test_existing_kit_with_other_rows_is_not_dealt(self):
        self.assertEqual([kit.species for kit in self.pools['Beast']], [500, 502])
        self.assertEqual([kit.species for kit in self.pools['Mechanical']], [503])

    def test_kit_stats_come_from_retail_states(self):
        self.assertEqual(self.kits[502].stats, (50, 0, -50))
        self.assertEqual(self.kits[503].stats, (0, 0, 0))

    def test_same_kind_is_preferred_then_family(self):
        dealt = companion_species.deal([(10, 'Tiny Pup', 'Beast'), (11, 'Zork', 'Beast')], self.pools)
        self.assertEqual(dealt, {10: 500, 11: 500})
        dealt = companion_species.deal([(10, 'Spotted Cat', 'Beast'), (11, 'Tabby Cat', 'Beast')], self.pools)
        self.assertEqual(dealt, {10: 502, 11: 502})

    def test_dealing_is_round_robin_and_deterministic(self):
        companions = [(12, 'Zork C', 'Beast'), (10, 'Zork A', 'Beast'), (11, 'Zork B', 'Beast')]
        first = companion_species.deal(companions, self.pools)
        self.assertEqual(first, {10: 500, 11: 502, 12: 500})
        self.assertEqual(companion_species.deal(list(reversed(companions)), self.pools), first)

    def test_empty_family_pool_raises(self):
        with self.assertRaisesRegex(ValueError, 'no kits for family Flying'):
            companion_species.deal([(10, 'Sky Hawk', 'Flying')], self.pools)


class GenerateTest(unittest.TestCase):
    def generate(self, proposal):
        return companion_species.generate(proposal, make_tables(), make_retail())

    def species_row(self, generated, entry):
        return next(r for r in generated.tables['coa_pet_species'] if r[0] == entry)

    def test_rule1_uses_its_retail_kit_and_adds_it(self):
        generated = self.generate([row(1, 60000, 'Gear Bot', '1 retail pet', 'Mechanical', '503 (new retail kit)',
                                       'retail species 503')])
        self.assertEqual(self.species_row(generated, 60000), (60000, 'Gear Bot', 503, 0, 1, 0, 1, 1, 'Icon_Mech', 0.0))
        self.assertEqual(generated.tables['coa_pet_kit'], [(503, 'Gear Bot', MECHANICAL, 0, 0, 0)])
        self.assertEqual(generated.tables['coa_pet_kit_ability'], kit_rows(503, range(7, 13)))

    def test_rule1_falls_back_when_retail_kit_not_dealable(self):
        generated = self.generate([row(1, 60000, 'Odd Pup', '1 retail pet', 'Beast', '504 (new retail kit)',
                                       'retail species 504')])
        self.assertEqual(self.species_row(generated, 60000)[2], 500)
        self.assertIn('retail species 504', generated.notes[60000])

    def test_existing_identical_kit_is_reused_without_insert(self):
        generated = self.generate([row(1, 60000, 'Tiny Pup', '4 keyword', 'Beast')])
        self.assertEqual(self.species_row(generated, 60000)[2], 500)
        self.assertEqual(generated.tables['coa_pet_kit'], [])
        self.assertEqual(generated.tables['coa_pet_kit_ability'], [])

    def test_new_dealt_kit_carries_retail_name_family_and_stats(self):
        generated = self.generate([row(1, 60000, 'House Cat', '3 original creature', 'Beast')])
        self.assertEqual(generated.tables['coa_pet_kit'], [(502, 'Forest Cat', BEAST, 50, 0, -50)])

    def test_rule2_copies_matched_species_kit_icon_and_presentation(self):
        generated = self.generate([row(1, 60000, 'New Pup', '2 same model', 'Humanoid', '1000001 (existing)',
                                       'species 7000 Old Pup')])
        self.assertEqual(self.species_row(generated, 60000), (60000, 'New Pup', 1000001, 0, 1, 0, 1, 1, 'Icon_Beast', 0.0))
        source = sorted(r for r in make_tables()['coa_pet_presentation'] if r[0] == 7000)
        copied = sorted(r for r in generated.tables['coa_pet_presentation'] if r[0] == 60000)
        self.assertEqual(copied, [(60000,) + r[1:] for r in source])

    def test_rule2_with_an_incomplete_kit_is_dealt_instead(self):
        generated = self.generate([row(1, 60000, 'New Wolf', '2 same model', 'Beast', '501 (existing)',
                                       'species 7003 Wolf')])
        self.assertEqual(self.species_row(generated, 60000)[2], 500)
        self.assertIn('species 7003', generated.notes[60000])
        self.assertEqual(len([r for r in generated.tables['coa_pet_presentation'] if r[0] == 60000]), 6)

    def test_two_spells_one_creature_make_one_species_two_companions(self):
        generated = self.generate([row(1, 60000, 'Zork', '5 picked', 'Beast'),
                                   row(2, 60000, 'Zork', '5 picked', 'Beast')])
        self.assertEqual([r[0] for r in generated.tables['coa_pet_species']], [60000])
        self.assertEqual(generated.tables['coa_pet_companion'], [(1, 60000), (2, 60000)])

    def test_presentation_prefers_retail_name_then_most_common(self):
        generated = self.generate([row(1, 60000, 'Tiny Pup', '4 keyword', 'Beast')])
        rows = {r[4]: r for r in generated.tables['coa_pet_presentation'] if r[0] == 60000}
        self.assertEqual(len(rows), 6)
        self.assertEqual(rows[1][1:8], (0, 1, 1, 1, 'Bite', 'Bite', 'Icon'))
        self.assertEqual(rows[2][1:7], (0, 2, 10, 2, 'Roar', 'Howl'))
        self.assertEqual(rows[2][8:], ('Roar tip', 102, 0, 'melee', 0, 0, 1, 0))

    def test_standins_are_sequential_from_9850000_in_creature_order(self):
        generated = self.generate([row(1, 60002, 'Zork B', '5 picked', 'Beast'),
                                   row(2, 60000, 'Zork A', '5 picked', 'Beast'),
                                   row(3, 70000, 'Zork C', '5 picked', 'Beast')])
        self.assertEqual(generated.tables['coa_pet_standin'], [(60000, 9850000), (60002, 9850001), (70000, 9850002)])

    def test_species_icon_is_the_most_common_icon_of_the_family(self):
        generated = self.generate([row(1, 60000, 'Zork', '5 picked', 'Beast')])
        self.assertEqual(self.species_row(generated, 60000)[8], 'Icon_Beast')


class SqlTest(unittest.TestCase):
    COLUMNS = ['entry', 'name', 'faction', 'minlevel', 'maxlevel', 'type', 'AIName', 'ScriptName', 'npcflag']

    def setUp(self):
        self.generated = companion_species.generate(
            [row(1, 60002, 'Gear Bot', '1 retail pet', 'Mechanical', '503 (new retail kit)', 'retail species 503'),
             row(2, 60000, 'Zork', '5 picked', 'Beast'), row(3, 60000, 'Zork', '5 picked', 'Beast')],
            make_tables(), make_retail())
        self.sql = companion_species.companion_sql(self.generated, self.COLUMNS, '-- test header')
        self.statements = [s.strip() for s in self.sql.split(';\n') if s.strip() and not s.startswith('--')]

    def test_sql_never_deletes_creature_templates(self):
        self.assertNotIn('DELETE FROM `creature_template`', self.sql)
        self.assertNotRegex(self.sql, r'DELETE FROM `creature_template`\s+WHERE')

    def test_sql_never_touches_the_offset_range(self):
        self.assertNotIn('BETWEEN', self.sql)
        self.assertNotRegex(self.sql, r'\b98[0-4]\d{4}\b')

    def test_every_delete_is_keyed_to_generated_ids(self):
        deletes = [s for s in self.sql.splitlines() if s.startswith('DELETE')]
        self.assertTrue(deletes)
        for line in deletes:
            self.assertRegex(line, r'^DELETE FROM `\w+` WHERE `\w+` IN \([0-9, ]+\);$')
        self.assertIn('DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9850000, 9850001);', deletes)
        self.assertIn('DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (9850000, 9850001);', deletes)

    def test_sql_round_trips_through_sql_reader(self):
        import sql_reader
        import tempfile
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'companions.sql'
            path.write_text(self.sql, encoding='utf-8')
            tables = sql_reader.read([path])
        for name in companion_species.GENERATED_TABLES:
            self.assertEqual([tuple(r) for r in tables.get(name, [])], [tuple(r) for r in self.generated.tables[name]],
                             name)

    def test_standin_copy_uses_level_60_faction_35_and_mapped_entry(self):
        insert = next(s for s in self.statements if s.startswith('INSERT INTO `creature_template` '))
        self.assertIn('`m`.`standin` AS `entry`', insert)
        self.assertIn('35 AS `faction`', insert)
        self.assertIn('60 AS `minlevel`', insert)
        self.assertIn("'' AS `AIName`", insert)
        self.assertIn('0 AS `npcflag`', insert)
        self.assertIn('ROW(60000, 9850000), ROW(60002, 9850001)', insert)
        self.assertIn('ON DUPLICATE KEY UPDATE', insert)


class SourceCreatureTest(unittest.TestCase):
    def test_missing_source_creatures_are_refused(self):
        generated = companion_species.generate([row(1, 60000, 'Zork', '5 picked', 'Beast'),
                                                row(2, 60002, 'Zork B', '5 picked', 'Beast')],
                                               make_tables(), make_retail())
        with self.assertRaisesRegex(ValueError, r'source creatures missing from creature_template: \[60002\]'):
            companion_species.check_sources(generated, {60000})
        companion_species.check_sources(generated, {60000, 60002})


class GeneratedFileTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import sql_reader
        cls.existing = sql_reader.read(companion_species.pet_sql_paths())
        cls.generated = sql_reader.read([companion_species.GENERATED_SQL])
        cls.accepted = [r for r in companion_species.read_proposal(companion_species.PROPOSAL)
                        if r['rule'].startswith(companion_species.ACCEPTED_RULES)]

    def test_generated_file_covers_every_accepted_proposal_row(self):
        self.assertEqual(len(self.accepted), 1324)
        self.assertEqual(sorted(tuple(r) for r in self.generated['coa_pet_companion']),
                         sorted((int(r['spell']), int(r['creature'])) for r in self.accepted))
        self.assertEqual(sorted(r[0] for r in self.generated['coa_pet_species']),
                         sorted({int(r['creature']) for r in self.accepted}))

    def test_generated_species_have_six_presented_abilities_from_the_ability_table(self):
        abilities = {r[0] for r in self.existing['coa_pet_ability']}
        kit_rows = collections.Counter(r[0] for r in self.existing['coa_pet_kit_ability'] + self.generated['coa_pet_kit_ability'])
        presented = collections.defaultdict(list)
        for r in self.generated['coa_pet_presentation']:
            presented[r[0]].append(r[4])
        for species in self.generated['coa_pet_species']:
            self.assertEqual(kit_rows[species[2]], 6, species)
            self.assertEqual(len(presented[species[0]]), 6, species)
            self.assertTrue(set(presented[species[0]]) <= abilities, species)

    def test_generated_standins_are_unique_and_in_range(self):
        entries = [r[1] for r in self.generated['coa_pet_standin']]
        self.assertEqual(len(entries), len(set(entries)))
        self.assertTrue(all(9850000 <= entry <= 9899999 for entry in entries))
        self.assertEqual(sorted(r[0] for r in self.generated['coa_pet_standin']),
                         sorted(r[0] for r in self.generated['coa_pet_species']))

    def test_generated_file_adds_no_existing_species(self):
        existing = {r[0] for r in self.existing['coa_pet_species']}
        self.assertFalse(existing & {r[0] for r in self.generated['coa_pet_species']})
        existing_kits = {r[0] for r in self.existing['coa_pet_kit']}
        self.assertFalse(existing_kits & {r[0] for r in self.generated['coa_pet_kit']})


if __name__ == '__main__':
    unittest.main()
