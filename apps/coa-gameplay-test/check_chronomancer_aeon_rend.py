import json
from pathlib import Path
import sys


def observations(folder):
    result = json.loads((folder / 'result.json').read_text())
    summary = json.loads((folder / 'summary.json').read_text())
    scenario = json.loads((folder / 'scenario.json').read_text())
    if result['status'] != 'passed' or summary['status'] != 'passed':
        raise ValueError('Both completed native cohorts are required')
    return {scenario['steps'][int(step['index'])]['save_as']: int(step['actual'])
            for step in result['steps'] if step['action'] == 'snapshot'}


def check(folders):
    values = [observations(folder) for folder in folders]
    if len(values) != 2:
        raise ValueError('Two independent native cohorts are required')
    hits = sum(value['eligible_damage_events'] for value in values)
    triggers = sum(value['native_proc_triggers'] for value in values)
    dispatches = sum(value['native_shard_dispatches'] for value in values)
    if hits < 100:
        raise ValueError(f'Only {hits} actual damage events; at least 100 are required before judging the proc')
    if triggers < 2:
        raise ValueError(f'Only {triggers} native triggers across {hits} damage events; Aeon Rend must fire')
    if dispatches <= 200:
        raise ValueError(f'Only {dispatches} Shards dispatched; at least one native re-strike is required')
    print(f'{hits} native damage events, {triggers} proc triggers, {dispatches} Shard dispatches; original chance 25%')


if __name__ == '__main__':
    check([Path(value) for value in sys.argv[1:]])
