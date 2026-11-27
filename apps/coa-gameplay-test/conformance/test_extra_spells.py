import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import batch_commands
import class_map
import conformance
from classes import CHARACTER_LEVEL, dataset
from extra_spells import (ExtraSpellsError, STOCK_GENERIC_SPELLS, audit_extra_lines, audit_extra_spells,
                          class_spells_table, felsworn_rifts, live_baseline_spells, log_events,
                          server_candidates, taught_abilities, trainer_spells, validate_excluded_extra_spells)
from profile import DBC_DIR, FIXTURE_CLASSES_DIR, class_file_paths
from tooltip import PASSIVE_ATTRIBUTE

WDBC_HEADER = struct.Struct('<4s4I')
SPELL_FIELDS = 234
SPELL_BYTES = SPELL_FIELDS * 4
ADVANCEMENT_FIELDS = 179
ADVANCEMENT_BYTES = 692
CLASS_TYPE_FIELDS = 23
CLASS_TYPE_BYTES = 92
REPOSITORY = HERE.parents[2]


def pack_wdbc(fields: int, record_size: int, rows: list[dict[int, int | str]], string_cols: set[int]) -> bytes:
    body = bytearray(len(rows) * record_size)
    strings = bytearray(b'\x00')
    offsets = {'': 0}
    for row_index, values in enumerate(rows):
        base = row_index * record_size
        for col, raw in values.items():
            if col in string_cols:
                text = str(raw)
                if text not in offsets:
                    offsets[text] = len(strings)
                    strings.extend(text.encode('utf-8') + b'\x00')
                encoded = offsets[text]
            else:
                encoded = int(raw)
            struct.pack_into('<I', body, base + col * 4, encoded)
    return WDBC_HEADER.pack(b'WDBC', len(rows), fields, record_size, len(strings)) + bytes(body) + bytes(strings)


def write_dbc_fixture(directory: Path, spells: list[dict[int, int | str]],
                      advancements: list[dict[int, int]] | None = None,
                      class_id: int = 24, class_type_id: int = 30) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    string_cols = {136, 153, 170}
    (directory / 'Spell.dbc').write_bytes(pack_wdbc(SPELL_FIELDS, SPELL_BYTES, spells, string_cols))
    ca_rows = advancements if advancements is not None else []
    (directory / 'CharacterAdvancement.dbc').write_bytes(
        pack_wdbc(ADVANCEMENT_FIELDS, ADVANCEMENT_BYTES, ca_rows, set()))
    class_types = [{0: class_type_id, 2: class_id, 4: 1}]
    (directory / 'CharacterAdvancementClassTypes.dbc').write_bytes(
        pack_wdbc(CLASS_TYPE_FIELDS, CLASS_TYPE_BYTES, class_types, set()))
    return directory


DEFAULT_CLASS_SPELLS_H = 'inline constexpr std::array<ClassSpell, 0> ClassSpells = {};\n'
DEFAULT_LIVE_BASELINE_H = 'inline constexpr std::array<Spell, 0> Spells = {};\n'
DEFAULT_TAUGHT_H = 'inline constexpr std::array<TaughtAbility, 0> TaughtAbilities = {};\n'
DEFAULT_COMPAT_CPP = 'constexpr std::array<FelswornRiftGrant, 0> FelswornHordeCapitalRifts = {};\n'


def write_source_tree(root: Path, *, progression: str = '', class_spells_h: str = DEFAULT_CLASS_SPELLS_H,
                      live_baseline_h: str = DEFAULT_LIVE_BASELINE_H, taught_h: str = DEFAULT_TAUGHT_H,
                      compat_cpp: str = DEFAULT_COMPAT_CPP, base_sql: str = '',
                      updates_world: dict[str, str] | None = None,
                      pending_world: dict[str, str] | None = None) -> Path:
    coa = root / 'src/server/coa'
    coa.mkdir(parents=True, exist_ok=True)
    (coa / 'AscensionSpellProgressionData.h').write_text(progression, encoding='utf-8')
    (coa / 'AscensionCustomClassData.h').write_text(class_spells_h, encoding='utf-8')
    (coa / 'AscensionLiveBaselineData.h').write_text(live_baseline_h, encoding='utf-8')
    (coa / 'AscensionTaughtAbilityData.h').write_text(taught_h, encoding='utf-8')
    (coa / 'AscensionCompat.cpp').write_text(compat_cpp, encoding='utf-8')
    base_path = root / 'data/sql/base/db_world/trainer_spell.sql'
    base_path.parent.mkdir(parents=True, exist_ok=True)
    base_path.write_text(base_sql, encoding='utf-8')
    for sub, entries in (('db_world', updates_world or {}), ('pending_db_world', pending_world or {})):
        folder = root / 'data/sql/updates' / sub
        folder.mkdir(parents=True, exist_ok=True)
        for filename, content in entries.items():
            (folder / filename).write_text(content, encoding='utf-8')
    return root


class SourceParsersTest(unittest.TestCase):
    def test_parses_cpp_tables_and_skips_unrelated_arrays(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = write_source_tree(
                Path(tmp),
                class_spells_h=(
                    'inline constexpr std::array<ClassSpell, 1> LegacyGeneratedClassSpells = {{\n'
                    '    { 24, 1, 999999 },\n'
                    '}};\n'
                    'inline constexpr std::array<ClassSpell, 1> ObsoleteSpells = {{\n'
                    '    { 24, 1, 999998 },\n'
                    '}};\n'
                    'inline constexpr std::array<ClassSpell, 3> ClassSpells = {{\n'
                    '    { 24, 10, 1001 },\n'
                    '    { 24, 5, 1001 },\n'
                    '    { 19, 1, 2001 },\n'
                    '}};\n'
                ),
                live_baseline_h=(
                    'inline constexpr std::array<Spell, 2> Spells = {{\n'
                    '    { 24, 0, 1002 },\n'
                    '    { 24, 1, 1003 },\n'
                    '}};\n'
                ),
                taught_h=(
                    'inline constexpr std::array<TaughtAbility, 3> TaughtAbilities = {{\n'
                    '    { 24, 1, 12, 500, 1004 },\n'
                    '    { 24, 2, 8, 501, 1004 },\n'
                    '    { 24, 1, 70, 502, 1005 },\n'
                    '}};\n'
                ),
                compat_cpp=(
                    'constexpr std::array<FelswornRiftGrant, 1> FelswornHordeCapitalRifts = {{\n'
                    '    { 1006, 40 },\n'
                    '}};\n'
                ),
            )
            self.assertEqual(class_spells_table(root), {24: {1001: 5}, 19: {2001: 1}})
            self.assertEqual(live_baseline_spells(root), {24: {1002}})
            self.assertEqual(taught_abilities(root), {24: {1004: (8, 501), 1005: (70, 502)}})
            self.assertEqual(felsworn_rifts(root), {1006: 40})

            c_24 = server_candidates(root, 24, level=60)
            self.assertEqual(sorted(c_24), [1001, 1002, 1004])
            self.assertNotIn(999999, c_24)
            self.assertNotIn(1003, c_24)
            self.assertNotIn(1005, c_24)
            self.assertNotIn(1006, c_24)

            c_14 = server_candidates(root, 14, level=60)
            self.assertIn(1006, c_14)

    def test_trainer_sql_replay_handles_insert_replace_delete_and_select(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = write_source_tree(
                Path(tmp),
                base_sql=(
                    'INSERT INTO `trainer_spell` VALUES '
                    '(900024, 3001, 10, 0, 0, 0, 0, 0, 4, 0),'
                    '(900024, 3002, 10, 0, 0, 0, 0, 0, 6, 0),'
                    '(900001, 3003, 10, 0, 0, 0, 0, 0, 1, 0);\n'
                ),
                updates_world={
                    '2026_01_01_00_world.sql': (
                        'DELETE FROM `trainer_spell` WHERE `TrainerId` = 900024 AND `SpellId` = 3002 '
                        'OR (`TrainerId` = 900024 AND `SpellId` = 9999);\n'
                        'INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) VALUES '
                        '(900024, 3004, 20), (900024, 3005, 65);\n'
                    ),
                },
                pending_world={
                    '2026_02_01_00_world.sql': (
                        'REPLACE INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) VALUES '
                        '(900024, 3001, 12);\n'
                        'INSERT IGNORE INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) '
                        'SELECT 900024, 3006, 1 FROM `trainer_spell` LIMIT 1;\n'
                    ),
                },
            )
            by_class = trainer_spells(root)
            self.assertEqual(by_class, {24: {3001: 12, 3004: 20, 3005: 65, 3006: 1}})
            candidates = server_candidates(root, 24, level=60)
            self.assertEqual(candidates, {
                3001: ['trainer_spell(L12)'],
                3004: ['trainer_spell(L20)'],
                3006: ['trainer_spell(L1)'],
            })

    def test_trainer_sql_replay_copies_columns_with_where_and_rejects_other_table(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = write_source_tree(
                Path(tmp),
                base_sql=(
                    'INSERT INTO `trainer_spell` VALUES '
                    '(900024, 3004, 10, 0, 0, 0, 0, 0, 20, 0),'
                    '(900019, 3004, 10, 0, 0, 0, 0, 0, 20, 0),'
                    '(900024, 3005, 10, 0, 0, 0, 0, 0, 30, 0);\n'
                ),
                pending_world={
                    '2026_02_02_00_world.sql': (
                        'INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, '
                        '`ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)\n'
                        'SELECT `TrainerId`, 3007, 0, 0, 0, 0, 0, 0, 5, 0 FROM `trainer_spell` '
                        'WHERE `SpellId` = 3004;\n'
                    ),
                },
            )
            self.assertEqual(trainer_spells(root), {24: {3004: 20, 3005: 30, 3007: 5}, 19: {3004: 20, 3007: 5}})

        with tempfile.TemporaryDirectory() as tmp:
            bad_root = write_source_tree(
                Path(tmp),
                pending_world={
                    '2026_02_03_00_world.sql': (
                        'INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) '
                        'SELECT `TrainerId`, `SpellId`, `ReqLevel` FROM `other_table`;\n'
                    ),
                },
            )
            with self.assertRaises(ExtraSpellsError):
                trainer_spells(bad_root)

    def test_importing_class_map_does_not_import_classes_module(self):
        script = (
            f'import sys; sys.path.insert(0, {str(HERE)!r}); '
            'import class_map; '
            'assert "classes" not in sys.modules, "classes imported at module load"; '
            'assert "extra_spells" not in sys.modules, "extra_spells imported at module load"'
        )
        result = subprocess.run([sys.executable, '-c', script], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_log_events_counts_casts_separately_from_other_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            csv = Path(tmp) / 'events.csv'
            csv.write_text('SPELL_CAST_SUCCESS,700,3\nSPELL_CAST_START,700,2\nSPELL_AURA_APPLIED,700,9\n\n',
                           encoding='utf-8')
            casts, others = log_events(csv)
            self.assertEqual(casts[700], 5)
            self.assertEqual(others[700], 9)
            self.assertEqual(log_events(Path(tmp) / 'missing.csv'), ({}, {}))
            with self.assertRaises(ExtraSpellsError):
                log_events(Path(tmp) / 'missing.csv', required=True)

    def test_cpp_literals_empty_arrays_and_malformed_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = write_source_tree(
                Path(tmp),
                class_spells_h=(
                    'inline constexpr std::array<ClassSpell, 2> ClassSpells = {{\n'
                    '    { 0x18u, 0X0Au, 0x3e9UL },\n'
                    '    { 24U, 5LL, 1001ULL },\n'
                    '}};\n'
                ),
                live_baseline_h='inline constexpr std::array<Spell, 1> Spells = {{ { 0x18, 0U, 0x3eaL } }};\n',
                taught_h='inline constexpr std::array<TaughtAbility, 1> TaughtAbilities = {{ { 24u, 1U, 0x8, 500UL, 1004u } }};\n',
                compat_cpp='constexpr std::array<FelswornRiftGrant, 1> FelswornHordeCapitalRifts = {{ { 0x3eeU, 0x28u } }};\n',
            )
            self.assertEqual(class_spells_table(root, required=True), {24: {1001: 5}})
            self.assertEqual(live_baseline_spells(root, required=True), {24: {1002}})
            self.assertEqual(taught_abilities(root, required=True), {24: {1004: (8, 500)}})
            self.assertEqual(felsworn_rifts(root, required=True), {1006: 40})

            empty_root = write_source_tree(
                Path(tmp) / 'empty',
                class_spells_h='inline constexpr std::array<ClassSpell, 0> ClassSpells = {{}};\n',
                live_baseline_h='inline constexpr std::array<Spell, 0> Spells = {};\n',
                taught_h='inline constexpr std::array<TaughtAbility, 0> TaughtAbilities = {{}};\n',
                compat_cpp='constexpr std::array<FelswornRiftGrant, 0> FelswornHordeCapitalRifts = {};\n',
            )
            self.assertEqual(class_spells_table(empty_root, required=True), {})
            self.assertEqual(live_baseline_spells(empty_root, required=True), {})
            self.assertEqual(taught_abilities(empty_root, required=True), {})
            self.assertEqual(felsworn_rifts(empty_root, required=True), {})

            bad_root = write_source_tree(
                Path(tmp) / 'bad',
                class_spells_h='inline constexpr std::array<ClassSpell, 1> ClassSpells = {{ { 24, BAD, 1001 } }};\n',
            )
            with self.assertRaises(ExtraSpellsError):
                class_spells_table(bad_root, required=True)

    def test_trainer_where_precedence_non_class_retention_ignore_and_update(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = write_source_tree(
                Path(tmp),
                base_sql=(
                    'INSERT INTO `trainer_spell` VALUES '
                    '(900024, 3001, 10, 0, 0, 0, 0, 0, 4, 0),'
                    '(900024, 3002, 10, 0, 0, 0, 0, 0, 6, 0),'
                    '(900019, 3001, 10, 0, 0, 0, 0, 0, 4, 0),'
                    '(900019, 3002, 10, 0, 0, 0, 0, 0, 6, 0),'
                    '(200001, 4001, 10, 0, 0, 0, 0, 0, 15, 0);\n'
                ),
                updates_world={
                    '2026_01_01_00_world.sql': (
                        'DELETE FROM `trainer_spell` WHERE (`TrainerId` = 900024 OR `TrainerId` = 900019) '
                        'AND `SpellId` = 3002;\n'
                        'INSERT IGNORE INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) VALUES '
                        '(900024, 3001, 99), (900024, 3009, 10);\n'
                        'INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) '
                        'SELECT 900024, `SpellId`, `ReqLevel` FROM `trainer_spell` '
                        'WHERE `TrainerId` = 200001 AND `ReqLevel` IN (15, 20);\n'
                        'INSERT IGNORE INTO `trainer_spell` (`TrainerId`, `SpellId`, `ReqLevel`) '
                        'SELECT 900024, 3009, 55 FROM `trainer_spell` WHERE `TrainerId` = 200001;\n'
                    ),
                },
                pending_world={
                    '2026_02_01_00_world.sql': (
                        'UPDATE `trainer_spell` SET `ReqSkillRank` = 75, `MoneyCost` = 100 '
                        'WHERE `TrainerId` = 900024 AND `SpellId` = 3001;\n'
                        'UPDATE `trainer_spell` SET `ReqLevel` = 22 '
                        'WHERE `TrainerId` = 900024 AND `SpellId` = 4001;\n'
                    ),
                },
            )
            self.assertEqual(trainer_spells(root), {
                24: {3001: 4, 3009: 10, 4001: 22},
                19: {3001: 4},
            })

        for name, sql in (
            ('bad_update_expr', 'UPDATE `trainer_spell` SET `ReqLevel` = `ReqLevel` + 1 WHERE `SpellId` = 3001;\n'),
            ('bad_update_pk', 'UPDATE `trainer_spell` SET `SpellId` = 9999 WHERE `SpellId` = 3001;\n'),
            ('bad_where', 'DELETE FROM `trainer_spell` WHERE `MoneyCost` = 10;\n'),
            ('truncate', 'TRUNCATE TABLE `trainer_spell`;\n'),
        ):
            with self.subTest(case=name), tempfile.TemporaryDirectory() as tmp:
                bad_root = write_source_tree(Path(tmp), pending_world={'2026_02_02_world.sql': sql})
                with self.assertRaises(ExtraSpellsError):
                    trainer_spells(bad_root)


class ValidationAndAuditTest(unittest.TestCase):
    def test_validate_excluded_extra_spells_rejects_bad_entries(self):
        bad_inputs = [
            {},
            ['bad'],
            [{'spell': True, 'name': 'x', 'reason': 'y'}],
            [{'spell': 0, 'name': 'x', 'reason': 'y'}],
            [{'spell': 10, 'name': '', 'reason': 'y'}],
            [{'spell': 10, 'name': 'x', 'reason': '   '}],
            [{'spell': 10, 'name': 'x', 'reason': 'r'}, {'spell': 10, 'name': 'x', 'reason': 'r2'}],
            [{'spell': 100, 'name': 'ca', 'reason': 'already ca'}],
            [{'spell': 200, 'name': 'ex', 'reason': 'already extra'}],
        ]
        for bad in bad_inputs:
            with self.subTest(bad=bad):
                with self.assertRaises(ExtraSpellsError):
                    validate_excluded_extra_spells(bad, {100}, {200})

    def test_audit_extra_spells_classifies_all_buckets_and_resilient_constitution(self):
        self.assertNotIn(552011, STOCK_GENERIC_SPELLS)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            dbc_dir = write_dbc_fixture(
                root / 'dbc',
                spells=[
                    {0: 100, 38: 1, 136: 'CA Base'},
                    {0: 101, 38: 10, 136: 'CA Base', 170: 'Uses @s:103:0@ inside.'},
                    {0: 102, 38: 1, 136: 'Extra Covered'},
                    {0: 103, 38: 1, 136: 'Pulled Subspell'},
                    {0: 104, 38: 1, 136: 'Excluded Buff'},
                    {0: 6603, 38: 1, 136: 'Attack'},
                    {0: 105, 38: 1, 136: 'CA Base', 153: 'Rank 2'},
                    {0: 106, 4: PASSIVE_ATTRIBUTE, 38: 1, 136: 'Unaccounted Passive'},
                    {0: 107, 4: PASSIVE_ATTRIBUTE, 38: 1, 136: 'Unaccounted Passive'},
                    {0: 552011, 4: PASSIVE_ATTRIBUTE, 38: 1, 136: 'Resilient Constitution'},
                ],
                advancements=[{0: 1, 5: 100, 26: 1, 32: 30}],
                class_id=24,
                class_type_id=30,
            )
            write_source_tree(
                root,
                progression='{ 24, 100, 101, 10 },\n{ 24, 106, 107, 15 },\n',
                class_spells_h=(
                    'inline constexpr std::array<ClassSpell, 10> ClassSpells = {{\n'
                    '    { 24, 1, 100 },\n'
                    '    { 24, 10, 101 },\n'
                    '    { 24, 1, 102 },\n'
                    '    { 24, 1, 103 },\n'
                    '    { 24, 1, 104 },\n'
                    '    { 24, 1, 6603 },\n'
                    '    { 24, 12, 105 },\n'
                    '    { 24, 1, 106 },\n'
                    '    { 24, 15, 107 },\n'
                    '    { 24, 1, 552011 },\n'
                    '}};\n'
                ),
            )
            events = root / 'logs.csv'
            events.write_text('SPELL_CAST_SUCCESS,106,4\nSPELL_AURA_APPLIED,107,7\nSPELL_CAST_START,105,2\n',
                              encoding='utf-8')
            class_file = {
                'class_id': 24,
                'name': 'synthetic',
                'level': 60,
                'extra_spells': [{'spell': 102, 'name': 'Extra Covered'}],
                'excluded_extra_spells': [{'spell': 104, 'name': 'Excluded Buff', 'reason': 'hidden buff'}],
            }
            report = audit_extra_spells(class_file, dbc_dir, root, log_events_path=events)
            self.assertEqual(report['counts'], {
                'advancement': 1,
                'extra_spells': 1,
                'covered_candidates': 3,
                'excluded': 1,
                'stock_generic': 1,
                'unchained_ranks': 1,
                'unaccounted': 2,
                'missing_dbc': 0,
            })
            self.assertEqual([row['spell'] for row in report['excluded']], [104])
            self.assertEqual([row['spell'] for row in report['stock_generic']], [6603])
            self.assertEqual(report['unchained_ranks'], [{
                'spell': 105, 'name': 'CA Base', 'rank': 'Rank 2', 'covered_as': [101],
                'sources': ['ClassSpells(L12)'], 'log_casts': 2, 'log_other_events': 0,
            }])
            unaccounted = {row['spell']: row for row in report['unaccounted']}
            self.assertEqual(set(unaccounted), {106, 552011})
            self.assertEqual(unaccounted[106]['max_rank'], 107)
            self.assertEqual(unaccounted[106]['ranks'], 2)
            self.assertTrue(unaccounted[106]['passive'])
            self.assertEqual(unaccounted[106]['log_casts'], 4)
            self.assertEqual(unaccounted[106]['log_other_events'], 7)
            text = '\n'.join(audit_extra_lines(report))
            self.assertIn('UNACCOUNTED\t552011', text)
            self.assertIn('UNCHAINED_RANK\t105', text)

    def test_audit_extra_spells_raises_for_missing_source_root_files_and_arrays(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            dbc_dir = write_dbc_fixture(
                root / 'dbc',
                spells=[{0: 100, 38: 1, 136: 'CA Spell'}],
                advancements=[{0: 1, 5: 100, 26: 1, 32: 30}],
                class_id=24,
                class_type_id=30,
            )
            class_file = {'class_id': 24, 'name': 'synthetic', 'level': 60, 'extra_spells': []}

            with self.assertRaises(ExtraSpellsError):
                audit_extra_spells(class_file, dbc_dir, root / 'missing_root')

            required_files = [
                'src/server/coa/AscensionCustomClassData.h',
                'src/server/coa/AscensionLiveBaselineData.h',
                'src/server/coa/AscensionTaughtAbilityData.h',
                'data/sql/base/db_world/trainer_spell.sql',
            ]
            for relative in required_files:
                with self.subTest(missing_file=relative):
                    tree = write_source_tree(root / f'file_{Path(relative).stem}')
                    (tree / relative).unlink()
                    with self.assertRaises(ExtraSpellsError):
                        audit_extra_spells(class_file, dbc_dir, tree)

            missing_arrays = [
                ('class_spells_h', ''),
                ('live_baseline_h', ''),
                ('taught_h', ''),
            ]
            for field, value in missing_arrays:
                with self.subTest(missing_array=field):
                    tree = write_source_tree(root / f'array_{field}', **{field: value})
                    with self.assertRaises(ExtraSpellsError):
                        audit_extra_spells(class_file, dbc_dir, tree)

            felsworn_dbc = write_dbc_fixture(
                root / 'dbc_felsworn',
                spells=[{0: 100, 38: 1, 136: 'CA Spell'}],
                advancements=[{0: 1, 5: 100, 26: 1, 32: 20}],
                class_id=14,
                class_type_id=20,
            )
            felsworn_file = {'class_id': 14, 'name': 'felsworn', 'level': 60, 'extra_spells': []}
            missing_compat = write_source_tree(root / 'missing_compat')
            (missing_compat / 'src/server/coa/AscensionCompat.cpp').unlink()
            with self.assertRaises(ExtraSpellsError):
                audit_extra_spells(felsworn_file, felsworn_dbc, missing_compat)
            empty_compat = write_source_tree(root / 'empty_compat', compat_cpp='')
            with self.assertRaises(ExtraSpellsError):
                audit_extra_spells(felsworn_file, felsworn_dbc, empty_compat)


class ExtraSpellsCliAndGateTest(unittest.TestCase):
    def _fixture(self, tmp: str):
        root = Path(tmp)
        dbc_dir = write_dbc_fixture(
            root / 'dbc',
            spells=[
                {0: 100, 38: 1, 136: 'CA Spell'},
                {0: 500200, 38: 1, 136: 'Missing Base'},
            ],
            advancements=[{0: 1, 5: 100, 26: 1, 32: 30}],
            class_id=24,
            class_type_id=30,
        )
        write_source_tree(
            root,
            class_spells_h='inline constexpr std::array<ClassSpell, 1> ClassSpells = {{\n    { 24, 1, 500200 },\n}};\n',
        )
        class_file = {'class_id': 24, 'name': 'synthetic', 'level': 60, 'extra_spells': []}
        class_path = root / 'synthetic.json'
        class_path.write_text(json.dumps(class_file), encoding='utf-8')
        return root, dbc_dir, class_path, class_file

    def test_audit_extra_cli_strict_and_non_strict_exit_codes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root, dbc_dir, class_path, _ = self._fixture(tmp)
            out_path = root / 'report.json'
            with mock.patch.object(batch_commands, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch('sys.stdout'), mock.patch('sys.stderr'):
                code_lax = conformance.main([
                    'audit-extra', '--class', '24', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root), '--out', str(out_path),
                ])
                code_strict = conformance.main([
                    'audit-extra', '--class', '24', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root), '--strict',
                ])
                code_mismatch = conformance.main([
                    'audit-extra', '--class', '19', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root),
                ])
            self.assertEqual(code_lax, 0)
            self.assertEqual(code_strict, 2)
            self.assertEqual(code_mismatch, 2)
            self.assertEqual(json.loads(out_path.read_text(encoding='utf-8'))['counts']['unaccounted'], 1)

    def test_ledger_gate_refuses_unaccounted_and_allows_override(self):
        with tempfile.TemporaryDirectory() as tmp:
            root, dbc_dir, _, class_file = self._fixture(tmp)
            ledger_out = root / 'out_clauses.json'
            with mock.patch.object(conformance, 'load_class_file', return_value=class_file), \
                 mock.patch.object(conformance, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch.object(conformance, 'ledger') as mock_ledger, \
                 mock.patch('sys.stderr') as fake_err, mock.patch('sys.stdout'):
                refused = conformance.main([
                    'ledger', '--class', '24', '--out', str(ledger_out), '--source-root', str(root),
                ])
                self.assertEqual(refused, 2)
                mock_ledger.assert_not_called()
                self.assertFalse(ledger_out.exists())
                fake_err.write.assert_called()

            fake_written = mock.Mock(entries=[{'spell': 100, 'kind': 'claim'}], unlabelled={})
            with mock.patch.object(conformance, 'load_class_file', return_value=class_file), \
                 mock.patch.object(conformance, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch.object(conformance, 'ledger', return_value=fake_written) as mock_ledger, \
                 mock.patch.object(conformance, 'clause_coverage'), \
                 mock.patch.object(conformance, 'write_ledger') as mock_write, \
                 mock.patch('sys.stdout'):
                allowed = conformance.main([
                    'ledger', '--class', '24', '--out', str(ledger_out), '--source-root', str(root),
                    '--allow-unaccounted-extra',
                ])
            self.assertEqual(allowed, 0)
            mock_ledger.assert_called_once()
            mock_write.assert_called_once_with(fake_written.entries, ledger_out)

    def test_ledger_gate_uses_local_progression_header_for_non_default_source_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root, dbc_dir, _, class_file = self._fixture(tmp)
            (root / 'src/server/coa/AscensionSpellProgressionData.h').write_text(
                '{ 24, 100, 500200, 10 },\n', encoding='utf-8')
            local_progression = root / 'local_progression.h'
            local_progression.write_text('', encoding='utf-8')
            ledger_out = root / 'out_clauses.json'
            with mock.patch.object(conformance, 'PROGRESSION_HEADER', local_progression), \
                 mock.patch.object(conformance, 'load_class_file', return_value=class_file), \
                 mock.patch.object(conformance, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch.object(conformance, 'ledger') as mock_ledger, \
                 mock.patch('sys.stderr'), mock.patch('sys.stdout'):
                code = conformance.main([
                    'ledger', '--class', '24', '--out', str(ledger_out), '--source-root', str(root),
                ])
            self.assertEqual(code, 2)
            mock_ledger.assert_not_called()

    def test_audit_extra_cli_strict_fails_on_missing_source_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root, dbc_dir, class_path, _ = self._fixture(tmp)
            with mock.patch.object(batch_commands, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch('sys.stdout'), mock.patch('sys.stderr'):
                code = conformance.main([
                    'audit-extra', '--class', '24', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root / 'does_not_exist'), '--strict',
                ])
            self.assertEqual(code, 2)

    def test_audit_extra_cli_rejects_malformed_class_file_and_missing_log_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            root, dbc_dir, class_path, _ = self._fixture(tmp)
            for label, payload in (
                ('list', '[]'),
                ('null', 'null'),
                ('missing_id', '{}'),
                ('bool_id', '{"class_id": true}'),
                ('str_id', '{"class_id": "24"}'),
            ):
                bad_path = root / f'bad_{label}.json'
                bad_path.write_text(payload, encoding='utf-8')
                with self.subTest(payload=label), \
                     mock.patch.object(batch_commands, 'server_dbc_dir', return_value=dbc_dir), \
                     mock.patch('sys.stdout'), mock.patch('sys.stderr'):
                    code = conformance.main([
                        'audit-extra', '--class', '24', '--class-file', str(bad_path),
                        '--dbc-dir', str(dbc_dir), '--source-root', str(root),
                    ])
                self.assertEqual(code, 2)

            with mock.patch.object(batch_commands, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch('sys.stdout'), mock.patch('sys.stderr'):
                missing_logs = conformance.main([
                    'audit-extra', '--class', '24', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root),
                    '--log-events', str(root / 'no_such.csv'),
                ])
            self.assertEqual(missing_logs, 2)

    def test_missing_dbc_and_unranked_same_name_fail_strict_and_ledger_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'src root'
            dbc_dir = write_dbc_fixture(
                Path(tmp) / 'dbc dir',
                spells=[
                    {0: 100, 38: 1, 136: 'Shared Name'},
                    {0: 105, 38: 1, 136: 'Shared Name', 153: ''},
                ],
                advancements=[{0: 1, 5: 100, 26: 1, 32: 30}],
                class_id=24,
                class_type_id=30,
            )
            write_source_tree(
                root,
                class_spells_h=(
                    'inline constexpr std::array<ClassSpell, 2> ClassSpells = {{\n'
                    '    { 24, 1, 105 },\n'
                    '    { 24, 1, 999888 },\n'
                    '}};\n'
                ),
            )
            class_file = {'class_id': 24, 'name': 'synthetic', 'level': 60, 'extra_spells': []}
            class_path = Path(tmp) / 'synthetic.json'
            class_path.write_text(json.dumps(class_file), encoding='utf-8')
            report = audit_extra_spells(class_file, dbc_dir, root)
            self.assertEqual(report['unchained_ranks'], [])
            self.assertEqual([entry['spell'] for entry in report['unaccounted']], [105])
            self.assertEqual(report['missing_dbc'], [{'spell': 999888, 'sources': ['ClassSpells(L1)']}])
            self.assertEqual(report['counts']['missing_dbc'], 1)
            lines = '\n'.join(audit_extra_lines(report))
            self.assertIn('MISSING_DBC\t999888\tClassSpells(L1)', lines)

            with mock.patch.object(batch_commands, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch('sys.stdout'), mock.patch('sys.stderr'):
                strict_code = conformance.main([
                    'audit-extra', '--class', '24', '--class-file', str(class_path),
                    '--dbc-dir', str(dbc_dir), '--source-root', str(root), '--strict',
                ])
            self.assertEqual(strict_code, 2)

            err_chunks = []
            ledger_out = Path(tmp) / 'out_clauses.json'
            with mock.patch.object(conformance, 'load_class_file', return_value=class_file), \
                 mock.patch.object(conformance, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch.object(conformance, 'ledger') as mock_ledger, \
                 mock.patch('sys.stderr.write', side_effect=err_chunks.append), mock.patch('sys.stdout'):
                refused = conformance.main([
                    'ledger', '--class', '24', '--out', str(ledger_out),
                    '--source-root', str(root), '--dbc-dir', str(dbc_dir),
                ])
            self.assertEqual(refused, 2)
            mock_ledger.assert_not_called()
            err_text = ''.join(err_chunks)
            self.assertIn(f"--source-root '{root}'", err_text)
            self.assertIn(f"--dbc-dir '{dbc_dir}'", err_text)

            write_source_tree(
                root,
                class_spells_h='inline constexpr std::array<ClassSpell, 1> ClassSpells = {{ { 24, 1, 100 } }};\n',
            )
            fake_written = mock.Mock(entries=[{'spell': 100, 'kind': 'claim'}], unlabelled={})
            with mock.patch.object(conformance, 'load_class_file', return_value=class_file), \
                 mock.patch.object(conformance, 'server_dbc_dir', return_value=dbc_dir), \
                 mock.patch.object(conformance, 'ledger', return_value=fake_written) as mock_ledger, \
                 mock.patch.object(conformance, 'clause_coverage'), \
                 mock.patch.object(conformance, 'write_ledger'), \
                 mock.patch('sys.stdout'):
                ok = conformance.main([
                    'ledger', '--class', '24', '--out', str(ledger_out),
                    '--source-root', str(root), '--dbc-dir', str(dbc_dir),
                ])
            self.assertEqual(ok, 0)
            mock_ledger.assert_called_once_with(class_file, dbc_dir, {}, root / 'data' / 'sql' / 'updates')


@unittest.skipUnless(DBC_DIR.is_dir(), 'server DBCs unavailable')
class RealDbcAndCrossClassGuardTest(unittest.TestCase):
    def test_frozen_necromancer_fixture_is_clean(self):
        necro = json.loads((FIXTURE_CLASSES_DIR / 'necromancer.json').read_text(encoding='utf-8'))
        report = audit_extra_spells(necro, DBC_DIR, REPOSITORY)
        self.assertEqual(report['unaccounted'], [])
        self.assertEqual(report['unchained_ranks'], [])

    def test_frozen_templar_fixture_matches_known_gaps(self):
        templar = json.loads((FIXTURE_CLASSES_DIR / 'templar.json').read_text(encoding='utf-8'))
        report = audit_extra_spells(templar, DBC_DIR, REPOSITORY)
        self.assertEqual({entry['spell'] for entry in report['unaccounted']},
                         {552011, 560963, 562226, 572629, 572630, 680306, 807729})
        self.assertEqual({entry['spell'] for entry in report['unchained_ranks']},
                         {803793, 803794, 803795, 803796})

    def test_cross_class_guard_excluded_extra_spells_are_well_formed(self):
        dbc = dataset(DBC_DIR)
        from classes import class_type_ids, advancement_levels
        for path in class_file_paths():
            class_file = json.loads(path.read_text(encoding='utf-8'))
            class_id = int(class_file['class_id'])
            ca_ids = set(advancement_levels(dbc, class_type_ids(dbc, class_id)))
            extra_ids = {entry['spell'] for entry in class_file.get('extra_spells', [])}
            with self.subTest(class_file=path.name):
                validate_excluded_extra_spells(class_file.get('excluded_extra_spells', []), ca_ids, extra_ids)

    def test_class_map_base_candidates_includes_taught_and_felsworn_rifts(self):
        candidates = class_map.base_candidates(REPOSITORY)
        self.assertEqual(candidates[15][578118], 0)
        self.assertEqual(candidates[14][535598], 26)


if __name__ == '__main__':
    unittest.main()
