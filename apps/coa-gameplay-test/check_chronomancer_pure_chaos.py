import json
from pathlib import Path
import sys


def check(folder):
    result = json.loads((folder / 'result.json').read_text())
    summary = json.loads((folder / 'summary.json').read_text())
    scenario = json.loads((folder / 'scenario.json').read_text())
    if result['status'] != 'passed' or summary['status'] != 'passed':
        raise ValueError('A completed native scenario is required')
    values = {scenario['steps'][int(step['index'])]['save_as']: float(step['actual'])
              for step in result['steps'] if step['action'] == 'snapshot'}
    actors = [player['id'] for player in scenario['players']]
    if len(actors) != 8:
        raise ValueError('Eight independent normal Incarnation windows are required')
    durations = [values[f'parent_start_{actor}'] for actor in actors]
    if any(not 17500 <= duration <= 18000 for duration in durations):
        raise ValueError('Chaos Fusion must extend the original parent to 18 seconds')
    checkpoints = [values[f'checkpoint_parent_{index}'] for index in range(24)]
    gaps = [durations[0] - checkpoints[0],
            *(earlier - later for earlier, later in zip(checkpoints, checkpoints[1:]))]
    if checkpoints[-1] <= 0 or any(not 0 <= gap <= 1000 for gap in gaps):
        raise ValueError('Aura observation checkpoints must remain inside Incarnation and at most one second apart')
    if 1000 + 2 * len(actors) * float(result['max_step_ms']) >= 3000:
        raise ValueError('Observation cadence must resolve the original three-second Time Loop')
    trials = sum(values[f'{kind}_trials_{actor}'] for actor in actors for kind in ('periodic', 'melee'))
    if trials < 200 or trials != int(trials):
        raise ValueError(f'At least 200 real damage events inside Incarnation are required; observed {trials:g}')
    procs = sum(values[f'procs_{actor}'] for actor in actors)
    shards = sum(values[f'shards_{actor}'] for actor in actors)
    if procs < 1 or shards < 1:
        raise ValueError('Native Pure Chaos procs and automatic Chromatic Shard casts are required')
    observations = [(values[f'loop_{actor}_{index}'], values[f'loop_duration_{actor}_{index}'])
                    for actor in actors for index in range(24)]
    if any(present not in (0, 1) or not 0 <= duration <= 3000 for present, duration in observations):
        raise ValueError('Time Loop must retain its original three-second duration')
    stable = sum(present == 1 and duration > 2 * float(result['max_step_ms'])
                 for present, duration in observations)
    if not stable:
        raise ValueError('No checkpoint observed a real self-cast Time Loop aura')
    zero_probability = 0.9**trials
    if zero_probability >= 1e-9:
        raise ValueError('The measured 10 percent experiment has insufficient eligible trials')
    print(f'{trials:g} eligible native damage events; {procs:g} Pure Chaos procs; '
          f'{shards:g} automatic Shard casts; {stable} stable Time Loop observations; '
          f'maximum checkpoint gap {max(gaps):g} ms; '
          f'zero-proc probability at the original 10 percent chance {zero_probability:g}')


if __name__ == '__main__':
    check(Path(sys.argv[1]))
