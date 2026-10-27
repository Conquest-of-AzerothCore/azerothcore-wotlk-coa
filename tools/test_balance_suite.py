import json
from pathlib import Path
import sys
import tempfile
import unittest

import balance_suite

ROOT = Path(__file__).resolve().parents[1]
BALANCE_DIR = ROOT / 'apps/coa-gameplay-test/balance'
GAMEPLAY_TEST_DIR = ROOT / 'apps/coa-gameplay-test'
if str(GAMEPLAY_TEST_DIR) not in sys.path:
    sys.path.insert(0, str(GAMEPLAY_TEST_DIR))
import batch  # noqa: E402
import run as gameplay_run  # noqa: E402

KNOWN_GROUPS = {'tank', 'healer', 'dps', 'dps-support'}
KNOWN_ARMORS = {'cloth', 'leather', 'mail', 'plate'}
KNOWN_STATS = {'strength', 'agility', 'intellect'}

OWNER_ROLE_DECISIONS = {
    25: 'healer',
    6: 'healer',
    31: 'healer',
    35: 'dps',
    57: 'tank',
}

DPS_SUPPORT_IDS = {3, 13, 20, 29, 58}


def load_catalog():
    return json.loads((BALANCE_DIR / 'catalog.json').read_text())


def load_dungeons():
    return json.loads((BALANCE_DIR / 'dungeons.json').read_text())


def load_gear():
    return json.loads((BALANCE_DIR / 'gear.json').read_text())


class CatalogTests(unittest.TestCase):
    def test_catalog_has_70_specs(self):
        catalog = load_catalog()
        self.assertEqual(len(catalog['specs']), 70)
        ids = [spec['spec_id'] for spec in catalog['specs']]
        self.assertEqual(len(ids), len(set(ids)))

    def test_groups_are_known(self):
        catalog = load_catalog()
        for spec in catalog['specs']:
            self.assertIn(spec['group'], KNOWN_GROUPS)
            self.assertIn(spec['armor'], KNOWN_ARMORS)
            self.assertIn(spec['primary_stat'], KNOWN_STATS)

    def test_owner_role_decisions_hold(self):
        catalog = load_catalog()
        by_id = {spec['spec_id']: spec for spec in catalog['specs']}
        for spec_id, group in OWNER_ROLE_DECISIONS.items():
            self.assertEqual(by_id[spec_id]['group'], group, spec_id)
        for spec_id in DPS_SUPPORT_IDS:
            self.assertEqual(by_id[spec_id]['group'], 'dps-support', spec_id)

    def test_every_level_has_talents(self):
        catalog = load_catalog()
        for spec in catalog['specs']:
            for level in ('20', '40', '60'):
                entries = spec['talents'][level]
                self.assertTrue(entries, (spec['spec_id'], level))
                for entry in entries:
                    self.assertEqual(len(entry), 2)
                    self.assertIsInstance(entry[0], int)
                    self.assertIsInstance(entry[1], int)
                    self.assertGreater(entry[1], 0)


class GearTests(unittest.TestCase):
    def test_every_armor_stat_pair_has_gear_at_each_level(self):
        catalog = load_catalog()
        gear = load_gear()
        pairs = {(spec['armor'], spec['primary_stat']) for spec in catalog['specs']}
        for level in ('20', '40', '60'):
            level_gear = gear['gear'][level]
            for armor, stat in pairs:
                key = f'{armor}/{stat}'
                self.assertIn(key, level_gear, (level, key))
                items = level_gear[key]
                self.assertTrue(items)
                for row in items:
                    self.assertIn('item', row)
                    self.assertIn('slot', row)
                    self.assertIsInstance(row['item'], int)
                    self.assertIsInstance(row['slot'], int)


class DungeonTests(unittest.TestCase):
    def test_dungeons_cover_20_40_60_with_3_elites_and_a_boss(self):
        dungeons = load_dungeons()
        for level in ('20', '40', '60'):
            row = dungeons['levels'][level]
            self.assertEqual(row['player_level'], int(level))
            self.assertIsInstance(row['map'], int)
            location = row['location']
            for axis in ('x', 'y', 'z', 'o'):
                self.assertIn(axis, location)
            self.assertEqual(len(row['elites']), 3)
            for elite in row['elites']:
                self.assertIsInstance(elite['entry'], int)
                self.assertIsInstance(elite['level'], int)
            self.assertIsInstance(row['boss']['entry'], int)
            self.assertIsInstance(row['boss']['level'], int)


FIXTURE_LEVELS = (20, 40, 60)

FIXTURE_CATALOG = {
    'version': 1,
    'specs': [
        {
            'class_id': 23, 'class_name': 'Necromancer', 'spec_id': 35, 'spec_name': 'Animation', 'group': 'dps',
            'armor': 'cloth', 'primary_stat': 'intellect',
            'talents': {'20': [[29244, 1]], '40': [[29244, 1], [33775, 1]], '60': [[29244, 1], [33775, 1]]},
            'kit': {'opener': [680388, 500971],
                    'upkeep': [{'spell': 500971, 'when': 'owned_below', 'value': 1, 'target': 'self'}]},
        },
        {
            'class_id': 18, 'class_name': 'Guardian', 'spec_id': 57, 'spec_name': 'Domination', 'group': 'tank',
            'armor': 'plate', 'primary_stat': 'strength',
            'talents': {'20': [[4001, 1]], '40': [[4001, 1]], '60': [[4001, 1]]},
        },
        {
            'class_id': 13, 'class_name': 'Witch Doctor', 'spec_id': 6, 'spec_name': 'Brewing', 'group': 'healer',
            'armor': 'mail', 'primary_stat': 'intellect',
            'talents': {'20': [[5001, 1]], '40': [[5001, 1]], '60': [[5001, 1]]},
        },
    ],
}

FIXTURE_DUNGEONS = {
    'levels': {
        str(level): {
            'map': 189, 'location': {'x': 1.0, 'y': 2.0, 'z': 3.0, 'o': 0.0}, 'player_level': level,
            'elites': [{'entry': 4286, 'level': level - 4}] * 3,
            'boss': {'entry': 3975, 'level': level - 3},
        } for level in FIXTURE_LEVELS
    },
}

FIXTURE_GEAR = {
    'gear': {
        str(level): {
            'cloth/intellect': [{'item': 1, 'slot': 4}],
            'plate/strength': [{'item': 2, 'slot': 4}],
            'mail/intellect': [{'item': 3, 'slot': 4}],
        } for level in FIXTURE_LEVELS
    },
}


def balance_result(statuses):
    steps = [{'action': 'wait', 'label': 'wait'}]
    for stage, outcome, duration, ttk, ttd, pets_owned, damage_pets in statuses:
        balance = {
            'stage': stage, 'outcome': outcome, 'duration_s': str(duration),
            'health_pct_end': '55.0',
            'damage_done_player': '1000', 'damage_done_pets': str(damage_pets),
            'damage_taken_player': '500', 'damage_taken_pets': '0',
            'healing_done_player': '0', 'healing_done_pets': '0',
            'pets_owned_start': str(pets_owned), 'pets_alive_end': str(pets_owned),
            'enemies': [],
        }
        if ttk is not None:
            balance['ttk_s'] = str(ttk)
        if ttd is not None:
            balance['ttd_s'] = str(ttd)
        steps.append({'action': 'balance_stage', 'label': stage, 'balance': balance, 'cap_s': 120})
    return {'status': 'passed', 'message': 'All assertions passed', 'steps': steps}


def write_case(cases_dir, case_id, result):
    case_dir = cases_dir / case_id
    case_dir.mkdir(parents=True, exist_ok=True)
    (case_dir / 'result.json').write_text(json.dumps(result), encoding='utf-8')


def make_row(group, level, stage, dps=100.0, dtps=10.0, hps=0.0, outcome='win', ttk_s=10.0, ttd_s=None,
             cap_s=120.0, spec_id=1, pets_missing=False):
    return {
        'spec_id': spec_id, 'class_id': 1, 'class_name': 'Class', 'spec_name': 'Spec', 'group': group,
        'armor': 'cloth', 'primary_stat': 'intellect', 'level': level, 'stage': stage,
        'white_received_pct_max_health': 5.0, 'outcome': outcome, 'duration_s': 10.0, 'cap_s': cap_s,
        'ttk_s': ttk_s, 'ttd_s': ttd_s, 'health_pct_end': 50.0,
        'damage_done_player': dps * 10.0, 'damage_done_pets': 0.0,
        'damage_taken_player': dtps * 10.0, 'damage_taken_pets': 0.0,
        'healing_done_player': hps * 10.0, 'healing_done_pets': 0.0,
        'pets_owned_start': 0, 'pets_alive_end': 0,
        'dps': dps, 'dtps': dtps, 'hps': hps, 'pet_share': 0.0,
        'pets_missing': pets_missing,
    }


class GenerateScenariosTests(unittest.TestCase):
    def test_generates_one_scenario_per_spec_and_level(self):
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp)
            paths = balance_suite.generate_scenarios(FIXTURE_CATALOG, FIXTURE_DUNGEONS, FIXTURE_GEAR,
                                                       list(FIXTURE_LEVELS), out_dir)
            self.assertEqual(len(paths), 9)
            ids = {path.stem for path in paths}
            expected = {balance_suite.scenario_id(spec['spec_id'], level)
                        for spec in FIXTURE_CATALOG['specs'] for level in FIXTURE_LEVELS}
            self.assertEqual(ids, expected)

            scenario = json.loads((out_dir / f"{balance_suite.scenario_id(35, 40)}.json").read_text())
            actions = [step['action'] for step in scenario['steps']]
            self.assertEqual(actions[0], 'wait')
            self.assertEqual(actions[1], 'specialization')
            self.assertIn('advancement_rank', actions)
            self.assertIn('equip', actions)
            white_index = actions.index('balance_white')
            stage_steps = [step for step in scenario['steps'] if step['action'] == 'balance_stage']
            self.assertEqual([step['stage'] for step in stage_steps], ['elite_1', 'elite_2', 'elite_3', 'boss'])
            self.assertLess(white_index, actions.index('balance_stage'))
            self.assertEqual(scenario['players'][0]['class'], 23)
            self.assertEqual(scenario['players'][0]['solo'], True)

    def test_generated_scenario_passes_run_py_schema_validation(self):
        non_healer_specs = [spec for spec in FIXTURE_CATALOG['specs'] if spec['group'] != 'healer']
        catalog = {'specs': non_healer_specs}
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp)
            paths = balance_suite.generate_scenarios(catalog, FIXTURE_DUNGEONS, FIXTURE_GEAR,
                                                       list(FIXTURE_LEVELS), out_dir)
            self.assertTrue(paths)
            for path in paths:
                scenario = json.loads(path.read_text())
                gameplay_run.validate(scenario)
                assertions = sum(step['action'] == 'assert' for step in scenario['steps'])
                self.assertGreater(assertions, 0)


class HarvestTests(unittest.TestCase):
    def test_harvest_reads_stage_records(self):
        catalog = {'specs': [FIXTURE_CATALOG['specs'][0]]}
        with tempfile.TemporaryDirectory() as tmp:
            verify_output = Path(tmp)
            cases_dir = verify_output / 'gameplay' / 'exploratory'
            statuses = [
                ('elite_1', 'win', 10.0, 10.0, None, 1, 50.0),
                ('elite_2', 'win', 20.0, 20.0, None, 1, 50.0),
                ('elite_3', 'loss', 15.0, None, 15.0, 1, 50.0),
                ('boss', 'timeout', 120.0, None, None, 1, 50.0),
            ]
            write_case(cases_dir, balance_suite.scenario_id(35, 40), balance_result(statuses))
            rows = balance_suite.harvest(verify_output, catalog)
            self.assertEqual(len(rows), len(balance_suite.LEVELS) * len(balance_suite.STAGES))
            level_rows = [row for row in rows if row['level'] == 40]
            self.assertEqual(len(level_rows), 4)
            elite1 = next(row for row in level_rows if row['stage'] == 'elite_1')
            self.assertEqual(elite1['outcome'], 'win')
            self.assertAlmostEqual(elite1['ttk_s'], 10.0)
            self.assertAlmostEqual(elite1['dps'], (1000.0 + 50.0) / 10.0)
            self.assertAlmostEqual(elite1['pet_share'], 50.0 / 1050.0)

    def test_failed_case_becomes_error_row(self):
        catalog = {'specs': [FIXTURE_CATALOG['specs'][0]]}
        with tempfile.TemporaryDirectory() as tmp:
            verify_output = Path(tmp)
            cases_dir = verify_output / 'gameplay' / 'exploratory'
            statuses = [('elite_1', 'win', 10.0, 10.0, None, 1, 50.0)]
            result = balance_result(statuses)
            result['status'] = 'failed'
            result['message'] = 'the character crashed mid-stage'
            write_case(cases_dir, balance_suite.scenario_id(35, 60), result)
            rows = balance_suite.harvest(verify_output, catalog)
            by_level = [row for row in rows if row['level'] == 60]
            errors = [row for row in by_level if row['outcome'] == 'error']
            self.assertEqual(len(errors), 3)
            for row in errors:
                self.assertEqual(row['message'], 'the character crashed mid-stage')
            missing_case = [row for row in rows if row['level'] == 20]
            self.assertTrue(all(row['outcome'] == 'error' for row in missing_case))
            self.assertEqual(missing_case[0]['message'], 'no result.json')

    def test_harvest_reads_the_real_exploratory_placement(self):
        with tempfile.TemporaryDirectory() as tmp:
            scenario_path = Path(tmp) / f'{balance_suite.scenario_id(35, 40)}.json'
            scenario_path.write_text('{}', encoding='utf-8')
            key = batch.exploratory_key(scenario_path, set())
            self.assertEqual(key, balance_suite.scenario_id(35, 40))

    def test_harvest_only_iterates_given_catalog_and_levels(self):
        catalog = {'specs': [FIXTURE_CATALOG['specs'][0], FIXTURE_CATALOG['specs'][1]]}
        with tempfile.TemporaryDirectory() as tmp:
            verify_output = Path(tmp)
            rows = balance_suite.harvest(verify_output, catalog, [40])
            self.assertEqual(len(rows), len(catalog['specs']) * len(balance_suite.STAGES))
            self.assertTrue(all(row['level'] == 40 for row in rows))


class CompareTests(unittest.TestCase):
    def test_median_and_ratio_per_group_level_stage(self):
        rows = [make_row('dps', 40, 'elite_1', dps=value) for value in (90.0, 100.0, 110.0)]
        enriched = balance_suite.compare(rows, 1.5)
        for row in enriched:
            self.assertEqual(row['median_dps'], 100.0)
            self.assertAlmostEqual(row['ratio_dps'], row['dps'] / 100.0)

    def test_flags_outside_threshold_only(self):
        rows = [make_row('dps', 40, 'elite_1', dps=value) for value in (100.0, 100.0, 100.0, 1000.0)]
        enriched = balance_suite.compare(rows, 1.5)
        flagged = [row for row in enriched if row['flag_dps']]
        self.assertEqual(len(flagged), 1)
        self.assertEqual(flagged[0]['dps'], 1000.0)

    def test_small_group_is_not_flagged(self):
        rows = [make_row('tank', 40, 'elite_1', dps=100.0), make_row('tank', 40, 'elite_1', dps=1000.0)]
        enriched = balance_suite.compare(rows, 1.5)
        self.assertTrue(all(row['ratio_dps'] is not None for row in enriched))
        self.assertTrue(all(not row['flag_dps'] for row in enriched))
        self.assertEqual(enriched[0]['n'], 2)

    def test_outcome_majority_flag(self):
        rows = [make_row('dps', 40, 'elite_1', outcome='win', spec_id=1),
                make_row('dps', 40, 'elite_1', outcome='win', spec_id=2),
                make_row('dps', 40, 'elite_1', outcome='loss', ttk_s=None, ttd_s=5.0, spec_id=3)]
        enriched = balance_suite.compare(rows, 1.5)
        by_outcome = {row['spec_id']: row['flag_outcome'] for row in enriched}
        self.assertFalse(by_outcome[1])
        self.assertFalse(by_outcome[2])
        self.assertTrue(by_outcome[3])

    def test_timeout_counts_cap_for_ttd(self):
        rows = [
            make_row('dps', 40, 'boss', outcome='loss', ttk_s=None, ttd_s=20.0, spec_id=1),
            make_row('dps', 40, 'boss', outcome='loss', ttk_s=None, ttd_s=40.0, spec_id=2),
            make_row('dps', 40, 'boss', outcome='timeout', ttk_s=None, ttd_s=None, cap_s=120.0, spec_id=3),
        ]
        enriched = balance_suite.compare(rows, 1.5)
        self.assertEqual(enriched[0]['median_ttd_s'], 40.0)

    def test_pets_missing_flag(self):
        rows = [make_row('dps', 40, 'elite_1', spec_id=1, pets_missing=True),
                make_row('dps', 40, 'elite_1', spec_id=2),
                make_row('dps', 40, 'elite_1', spec_id=3)]
        enriched = balance_suite.compare(rows, 1.5)
        flagged = {row['spec_id']: row['pets_missing'] for row in enriched}
        self.assertTrue(flagged[1])
        self.assertFalse(flagged[2])

    def test_tank_rule_flags(self):
        rows = [
            make_row('tank', 40, 'elite_2', outcome='win', dps=50.0, ttd_s=None, spec_id=1),
            make_row('tank', 40, 'elite_2', outcome='loss', ttk_s=None, ttd_s=5.0, dps=1200.0, spec_id=2),
            make_row('tank', 40, 'elite_2', outcome='loss', ttk_s=None, ttd_s=90.0, dps=10.0, spec_id=3),
            make_row('dps', 40, 'elite_2', outcome='loss', ttk_s=None, ttd_s=60.0, dps=500.0, spec_id=4),
            make_row('dps', 40, 'elite_2', outcome='loss', ttk_s=None, ttd_s=70.0, dps=600.0, spec_id=5),
            make_row('healer', 40, 'elite_2', outcome='loss', ttk_s=None, ttd_s=80.0, dps=50.0, spec_id=6),
        ]
        enriched = balance_suite.compare(rows, 1.5)
        by_id = {row['spec_id']: row for row in enriched}
        self.assertTrue(by_id[1]['tank_clears'])
        self.assertFalse(by_id[2]['tank_clears'])
        self.assertTrue(by_id[2]['tank_dies_early'])
        self.assertFalse(by_id[3]['tank_dies_early'])
        self.assertTrue(by_id[2]['tank_dps_high'])
        self.assertFalse(by_id[3]['tank_dps_high'])


class ReportTests(unittest.TestCase):
    def test_csv_has_one_row_per_spec_level_stage(self):
        rows = [make_row('dps', 40, stage, spec_id=spec_id)
                for spec_id in (1, 2) for stage in balance_suite.STAGES]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'report.csv'
            balance_suite.write_csv(rows, path)
            import csv as csv_module
            with path.open(encoding='utf-8') as stream:
                reader = list(csv_module.DictReader(stream))
            self.assertEqual(len(reader), len(rows))

    def test_html_marks_flagged_cells(self):
        rows = [make_row('dps', 40, 'elite_1', dps=value, spec_id=index)
                for index, value in enumerate((100.0, 100.0, 100.0, 1000.0))]
        enriched = balance_suite.compare(rows, 1.5)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'report.html'
            balance_suite.write_html(enriched, path)
            text = path.read_text(encoding='utf-8')
            self.assertIn('class="flagged"', text)

    def test_write_report_honors_filtered_catalog_and_levels(self):
        catalog = {'specs': [FIXTURE_CATALOG['specs'][0]]}
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp)
            rows = balance_suite.write_report(output, balance_suite.DEFAULT_THRESHOLD, catalog, [40])
            self.assertEqual(len(rows), len(balance_suite.STAGES))
            self.assertTrue(all(row['level'] == 40 for row in rows))
            self.assertTrue(all(row['outcome'] == 'error' for row in rows))


if __name__ == '__main__':
    unittest.main()
