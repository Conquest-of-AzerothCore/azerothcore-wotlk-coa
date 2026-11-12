from pathlib import Path
import json
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from profile import skill_label, spell_power_label, stat_label
import scaffold


SHARED_DEFINES_FIXTURE = '\n'.join([
    'enum Classes',
    '{',
    '    CLASS_WARRIOR        = 1,  // TITLE Warrior',
    '    CLASS_BARBARIAN      = 12, // TITLE Barbarian',
    '    CLASS_MONK           = 19, // TITLE Templar',
    '};',
    '',
])

LIVE_BASELINE_FIXTURE = '\n'.join([
    'struct Proficiency',
    '{',
    '    std::uint8_t ClassId;',
    '    std::uint16_t SkillId;',
    '    std::uint32_t SpellId;',
    '};',
    '',
    'inline constexpr std::array<Proficiency, 6> Proficiencies =',
    '{{',
    '    {19, 54, 198},',
    '    {19, 43, 201},',
    '    {19, 136, 227},',
    '    {12, 44, 196},',
    '    {19, 999, 999999},',
    '}};',
    '',
])

MAIN_ITEM_ROW = {'entry': 2495, 'dmg_min1': 6.5625, 'dmg_max1': 10.9375, 'delay': 2500, 'InventoryType': 17}
ALTERNATE_ITEM_ROW = {'entry': 2259, 'dmg_min1': 3.45, 'dmg_max1': 5.75, 'delay': 2000, 'InventoryType': 21}
DAGGER_ITEM_ROW = {'entry': 777, 'dmg_min1': 1.0, 'dmg_max1': 2.0, 'delay': 1500, 'InventoryType': 13}


class ClassTitleTest(unittest.TestCase):
    def test_title_is_read_from_the_comment_of_the_matching_class_id(self):
        self.assertEqual(scaffold.class_title(SHARED_DEFINES_FIXTURE, 19), 'Templar')
        self.assertEqual(scaffold.class_title(SHARED_DEFINES_FIXTURE, 12), 'Barbarian')

    def test_unknown_class_id_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.class_title(SHARED_DEFINES_FIXTURE, 99)


class ClassProficienciesTest(unittest.TestCase):
    def test_rows_of_the_class_are_sorted_by_skill_then_spell(self):
        self.assertEqual(scaffold.class_proficiencies(LIVE_BASELINE_FIXTURE, 19),
                         [(43, 201), (54, 198), (136, 227), (999, 999999)])

    def test_rows_of_another_class_do_not_leak_in(self):
        self.assertEqual(scaffold.class_proficiencies(LIVE_BASELINE_FIXTURE, 12), [(44, 196)])

    def test_duplicate_rows_are_deduplicated(self):
        text = LIVE_BASELINE_FIXTURE.replace('{19, 54, 198},', '{19, 54, 198},\n    {19, 54, 198},')
        self.assertEqual(scaffold.class_proficiencies(text, 19).count((54, 198)), 1)

    def test_class_with_no_row_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.class_proficiencies(LIVE_BASELINE_FIXTURE, 20)

    def test_missing_array_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.class_proficiencies('no proficiencies here', 19)


class SelectWeaponRowsTest(unittest.TestCase):
    def test_main_is_the_lowest_skill_row_that_resolves_a_subclass(self):
        rows = [(43, 201), (54, 198), (136, 227)]
        main, alternate = scaffold.select_weapon_rows(rows, {201: 7, 198: 4, 227: 10})
        self.assertEqual(main, (43, 201, 7))
        self.assertEqual(alternate, (54, 198, 4))

    def test_rows_with_no_resolvable_subclass_are_skipped(self):
        rows = [(43, 201), (54, 198)]
        main, alternate = scaffold.select_weapon_rows(rows, {198: 4})
        self.assertEqual(main, (54, 198, 4))
        self.assertIsNone(alternate)

    def test_alternate_is_none_when_every_resolved_row_shares_the_main_subclass(self):
        rows = [(43, 201), (54, 198)]
        main, alternate = scaffold.select_weapon_rows(rows, {201: 7, 198: 7})
        self.assertEqual(main, (43, 201, 7))
        self.assertIsNone(alternate)

    def test_no_resolvable_row_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.select_weapon_rows([(43, 201)], {})


class NormalizedSpeedTest(unittest.TestCase):
    def test_two_hand_inventory_type_is_3_3(self):
        self.assertEqual(scaffold.normalized_speed(17, 10), 3.3)

    def test_ranged_inventory_types_are_2_8(self):
        for inventory_type in (15, 25, 26):
            self.assertEqual(scaffold.normalized_speed(inventory_type, 2), 2.8)

    def test_one_hand_non_dagger_is_2_4(self):
        for inventory_type in (13, 21, 22):
            self.assertEqual(scaffold.normalized_speed(inventory_type, 7), 2.4)

    def test_one_hand_dagger_is_1_7(self):
        self.assertEqual(scaffold.normalized_speed(13, scaffold.DAGGER_SUBCLASS), 1.7)

    def test_unsupported_inventory_type_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.normalized_speed(23, 7)


class WeaponEntryTest(unittest.TestCase):
    def test_entry_matches_the_item_row_and_subclass(self):
        entry = scaffold.weapon_entry(MAIN_ITEM_ROW, 10)
        self.assertEqual(entry, {'item': 2495, 'slot': 15, 'subclass': 10, 'min_damage': 6.5625,
                                 'max_damage': 10.9375, 'speed_ms': 2500, 'inventory_type': 17,
                                 'normalized_speed': 3.3})

    def test_skill_line_is_only_set_when_given(self):
        entry = scaffold.weapon_entry(ALTERNATE_ITEM_ROW, 4, skill_line=54)
        self.assertEqual(entry['skill_line'], 54)
        self.assertNotIn('skill_line', scaffold.weapon_entry(MAIN_ITEM_ROW, 10))


class LowestRaceTest(unittest.TestCase):
    def test_lowest_of_several_races(self):
        self.assertEqual(scaffold.lowest_race([4, 1, 7]), 1)

    def test_no_race_is_rejected(self):
        with self.assertRaises(scaffold.ScaffoldError):
            scaffold.lowest_race([])


class SqlTextTest(unittest.TestCase):
    def test_playercreateinfo_sql_is_scoped_to_the_class(self):
        self.assertEqual(scaffold.playercreateinfo_sql(19),
                         "SELECT JSON_OBJECT('race', race) FROM playercreateinfo WHERE class = 19;")

    def test_item_candidate_sql_excludes_bonus_stats_and_procs(self):
        sql = scaffold.item_candidate_sql(10)
        self.assertIn('subclass = 10', sql)
        self.assertIn('class = 2', sql)
        self.assertIn('Quality = 1', sql)
        self.assertIn('ItemLevel > 0', sql)
        for slot in range(1, 11):
            self.assertIn(f'stat_type{slot} = 0', sql)
        for slot in range(1, 6):
            self.assertIn(f'spellid_{slot} = 0', sql)
        self.assertIn('ORDER BY ItemLevel, entry LIMIT 1', sql)


class BuildClassFileTest(unittest.TestCase):
    def test_mandatory_fields_and_defaults(self):
        class_file = scaffold.build_class_file(19, 'Templar', 1, (43, 201, 7), MAIN_ITEM_ROW, [70, 71, 72])
        self.assertEqual(class_file['class_id'], 19)
        self.assertEqual(class_file['name'], 'Templar')
        self.assertEqual(class_file['race'], 1)
        self.assertEqual(class_file['level'], scaffold.CHARACTER_LEVEL)
        self.assertEqual(class_file['weapon']['item'], 2495)
        self.assertEqual(class_file['weapon']['subclass'], 7)
        self.assertEqual(class_file['skill_lines'], [70, 71, 72])
        self.assertEqual(class_file['ratings'], scaffold.REFERENCE_RATINGS)
        self.assertEqual(class_file['reference_stats'], {})
        self.assertEqual(class_file['alternate_weapons'], [])
        for field in scaffold.EMPTY_LIST_FIELDS:
            self.assertEqual(class_file[field], [], field)

    def test_alternate_weapon_is_added_when_resolved(self):
        class_file = scaffold.build_class_file(19, 'Templar', 1, (43, 201, 7), MAIN_ITEM_ROW, [70],
                                               alternate=(54, 198, 4), alternate_item_row=ALTERNATE_ITEM_ROW)
        self.assertEqual(class_file['alternate_weapons'],
                         [scaffold.weapon_entry(ALTERNATE_ITEM_ROW, 4, skill_line=54)])

    def test_alternate_without_a_resolved_item_row_is_dropped(self):
        class_file = scaffold.build_class_file(19, 'Templar', 1, (43, 201, 7), MAIN_ITEM_ROW, [70],
                                               alternate=(54, 198, 4), alternate_item_row=None)
        self.assertEqual(class_file['alternate_weapons'], [])

    def test_a_schema_field_is_never_missing(self):
        class_file = scaffold.build_class_file(19, 'Templar', 1, (43, 201, 7), MAIN_ITEM_ROW, [70])
        from profile import CLASSES_DIR
        templar = json.loads((CLASSES_DIR / 'templar.json').read_text(encoding='utf-8'))
        self.assertEqual(set(class_file), set(templar))


class NakedScenarioTest(unittest.TestCase):
    def test_scenario_validates_and_matches_base_steps(self):
        class_file = {'class_id': 19, 'name': 'Templar', 'race': 1, 'level': 60,
                      'weapon': scaffold.weapon_entry(MAIN_ITEM_ROW, 7), 'skill_lines': [43]}
        scenario = scaffold.naked_scenario(class_file)
        self.assertEqual(scenario['players'], [{'id': 'caster', 'race': 1, 'class': 19, 'level': 60}])
        labels = [step['label'] for step in scenario['steps'] if step.get('action') == 'assert']
        self.assertIn('attack_power', labels)
        self.assertIn(skill_label(43), labels)


class ReferenceStatsFromResultTest(unittest.TestCase):
    def test_only_the_reference_stats_fields_are_kept(self):
        class_file = {'skill_lines': [70, 71]}
        result = {'steps': [
            {'label': 'attack_power', 'actual': '313'},
            {'label': 'ranged_attack_power', 'actual': '182'},
            *[{'label': spell_power_label(school), 'actual': '0'} for school in range(1, 7)],
            *[{'label': stat_label(stat), 'actual': str(10 + stat)} for stat in range(5)],
            {'label': skill_label(70), 'actual': '300'},
            {'label': skill_label(71), 'actual': '300'},
            {'label': 'weapon_damage_min', 'actual': '62.455'},
            {'label': 'known_aura 887007', 'actual': '1'},
        ]}
        stats = scaffold.reference_stats_from_result(result, class_file)
        self.assertEqual(stats['attack_power'], 313)
        self.assertEqual(stats['ranged_attack_power'], 182)
        self.assertEqual(stats[skill_label(70)], 300)
        self.assertEqual(stats[skill_label(71)], 300)
        self.assertNotIn('weapon_damage_min', stats)
        self.assertNotIn('known_aura 887007', stats)

    def test_a_skill_line_absent_from_the_result_is_skipped(self):
        class_file = {'skill_lines': [70, 136]}
        result = {'steps': [
            {'label': 'attack_power', 'actual': '313'},
            {'label': 'ranged_attack_power', 'actual': '182'},
            *[{'label': spell_power_label(school), 'actual': '0'} for school in range(1, 7)],
            *[{'label': stat_label(stat), 'actual': '10'} for stat in range(5)],
            {'label': skill_label(70), 'actual': '300'},
        ]}
        stats = scaffold.reference_stats_from_result(result, class_file)
        self.assertIn(skill_label(70), stats)
        self.assertNotIn(skill_label(136), stats)


class LocalSelectTest(unittest.TestCase):
    def test_query_runs_against_the_connection_named_by_the_config_without_leaking_the_password(self):
        import tempfile
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'server.conf'
            config.write_text('WorldDatabaseInfo = "127.0.0.1;3306;fixture_user;fixture_secret;world"\n')
            commands = []

            def database(command, *, input, **kwargs):
                commands.append((command, input))
                self.assertNotIn('fixture_secret', ' '.join(command))
                return SimpleNamespace(returncode=0, stdout='{"race": 1}\n{"race": 3}\n', stderr='')

            with patch.object(scaffold.subprocess, 'run', side_effect=database):
                rows = scaffold.local_select(config, 'mysql', scaffold.playercreateinfo_sql(19))
            self.assertEqual(rows, [{'race': 1}, {'race': 3}])
            self.assertEqual(len(commands), 1)
            self.assertEqual(commands[0][1], scaffold.playercreateinfo_sql(19))

    def test_a_nonzero_exit_is_a_scaffold_error(self):
        import tempfile
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'server.conf'
            config.write_text('WorldDatabaseInfo = "127.0.0.1;3306;user;secret;world"\n')
            with patch.object(scaffold.subprocess, 'run',
                             return_value=SimpleNamespace(returncode=1, stdout='', stderr='boom')):
                with self.assertRaises(scaffold.ScaffoldError):
                    scaffold.local_select(config, 'mysql', 'SELECT 1;')


if __name__ == '__main__':
    unittest.main()
