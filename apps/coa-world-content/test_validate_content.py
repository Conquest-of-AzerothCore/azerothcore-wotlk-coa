import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_content


def test_duplicate_spawns_flags_co_located_pair():
    rows = [[1, 0, 10, '-100.0', '200.0', '50.0'], [1, 0, 11, '-100.2', '200.1', '50.4']]
    findings, crowded = validate_content.duplicate_spawns(rows, set())
    assert findings == [[1, 10, 11]], findings
    assert crowded == 0


def test_duplicate_spawns_ignores_separated_pair():
    rows = [[1, 0, 10, '-100.0', '200.0', '50.0'], [1, 0, 11, '-104.0', '200.0', '50.0']]
    findings, _ = validate_content.duplicate_spawns(rows, set())
    assert findings == [], findings


def test_duplicate_spawns_ignores_other_map_and_entry():
    rows = [[1, 0, 10, '0.0', '0.0', '0.0'], [1, 1, 11, '0.0', '0.0', '0.0'],
            [2, 0, 12, '0.0', '0.0', '0.0']]
    findings, _ = validate_content.duplicate_spawns(rows, set())
    assert findings == [], findings


def test_duplicate_spawns_skips_pooled_guids():
    rows = [[1, 0, 10, '0.0', '0.0', '0.0'], [1, 0, 11, '0.0', '0.0', '0.0']]
    findings, _ = validate_content.duplicate_spawns(rows, {11})
    assert findings == [], findings


def test_duplicate_spawns_reports_crowded_entries():
    rows = [[1, 0, guid, '0.0', '0.0', '0.0'] for guid in range(validate_content.CROWD_LIMIT + 2)]
    findings, crowded = validate_content.duplicate_spawns(rows, set())
    assert findings == []
    assert crowded == 1


def test_unobtainable_items_accepts_loot_and_vendor():
    datasets = {'obtainable_items': [[55]], 'required_items': [[7, 55]], 'self_supplied_items': []}
    assert validate_content.unobtainable_items(datasets) == []


def test_unobtainable_items_accepts_quest_supplied_item():
    datasets = {'obtainable_items': [], 'required_items': [[7, 55]], 'self_supplied_items': [[7, 55]]}
    assert validate_content.unobtainable_items(datasets) == []


def test_unobtainable_items_rejects_item_supplied_by_another_quest():
    datasets = {'obtainable_items': [], 'required_items': [[7, 55]], 'self_supplied_items': [[8, 55]]}
    assert validate_content.unobtainable_items(datasets) == [[7, 55]]


def test_unobtainable_items_reports_missing_item():
    datasets = {'obtainable_items': [[1]], 'required_items': [[7, 55]], 'self_supplied_items': []}
    assert validate_content.unobtainable_items(datasets) == [[7, 55]]


def test_collect_scopes_to_requested_quests():
    outcomes = {'demo': [['7', '55'], ['9', '66']]}
    report, findings = validate_content.collect({'demo': 0}, outcomes, {7})
    assert report['demo']['findings'] == 1
    assert findings == {'demo:7|55'}


def test_collect_keeps_unscoped_checks_whole():
    outcomes = {'demo': [['7', '55'], ['9', '66']]}
    report, _ = validate_content.collect({'demo': None}, outcomes, {7})
    assert report['demo']['findings'] == 2


def test_sql_checks_cover_every_relation_table():
    names = set(validate_content.sql_checks())
    for entity in ('creature', 'gameobject'):
        for role in ('starter', 'ender'):
            assert f'{entity}-{role}-unspawned' in names
    assert 'quest-unreachable' in names


def main():
    failures = 0
    for name, test in sorted(globals().items()):
        if not name.startswith('test_') or not callable(test):
            continue
        try:
            test()
        except AssertionError as error:
            failures += 1
            print(f'FAIL {name}: {error}')
        else:
            print(f'PASS {name}')
    print('FAILED' if failures else 'OK')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
