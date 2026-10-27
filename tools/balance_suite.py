import argparse
from collections import Counter, defaultdict
import csv
import html
import json
from pathlib import Path
import statistics
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / 'apps/coa-gameplay-test/balance/catalog.json'
DUNGEONS_PATH = ROOT / 'apps/coa-gameplay-test/balance/dungeons.json'
GEAR_PATH = ROOT / 'apps/coa-gameplay-test/balance/gear.json'

LEVELS = (20, 40, 60)
STAGES = ('elite_1', 'elite_2', 'elite_3', 'boss')
GROUPS = ('tank', 'healer', 'dps', 'dps-support')
RATIO_METRICS = ('dps', 'dtps', 'hps')
FLAG_KEYS = ('flag_dps', 'flag_dtps', 'flag_hps', 'flag_ttk_s', 'flag_ttd_s', 'flag_outcome', 'pets_missing',
             'tank_clears', 'tank_dies_early', 'tank_dps_high')
DEFAULT_THRESHOLD = 1.5
DEFAULT_WHITE_SWINGS = 20
FALLBACK_SPELL = 6603
CAP_S_SECONDS = 120

CLASS_RACE = {
    12: 1, 13: 1, 14: 2, 15: 1, 16: 1, 17: 2, 18: 1, 19: 1, 20: 1, 21: 1,
    22: 1, 23: 1, 24: 1, 25: 1, 26: 4, 27: 1, 28: 1, 29: 4, 30: 1, 31: 2, 32: 1,
}


def scenario_id(spec_id, level):
    return f'balance-{spec_id}-{level}'


def driver_role(spec):
    if spec['group'] == 'tank':
        return 'tank'
    if spec['group'] == 'healer':
        return 'healer'
    return 'ranged' if spec['primary_stat'] == 'intellect' else 'melee'


def gear_key(spec):
    return f"{spec['armor']}/{spec['primary_stat']}"


def stage_enemies(dungeon, stage):
    if stage == 'boss':
        boss = dungeon['boss']
        return [{'entry': boss['entry'], 'level': boss['level'], 'count': 1}]
    count = {'elite_1': 1, 'elite_2': 2, 'elite_3': 3}[stage]
    return [{'entry': elite['entry'], 'level': elite['level'], 'count': 1} for elite in dungeon['elites'][:count]]


def build_player(spec, level):
    role = driver_role(spec)
    player = {
        'id': 'fighter',
        'race': CLASS_RACE[spec['class_id']],
        'class': spec['class_id'],
        'level': level,
        'role': role,
        'rotation': [FALLBACK_SPELL],
        'rotation_assist': True,
        'solo': True,
        'group': spec['group'],
    }
    if role == 'healer':
        player['heal_spell'] = FALLBACK_SPELL
    if spec.get('kit'):
        player['kit'] = spec['kit']
    return player


def build_steps(spec, level, dungeon, gear_items):
    actor_id = 'fighter'
    steps = [
        {'action': 'wait', 'label': 'Let login and stat updates settle', 'ms': 3000},
        {'action': 'specialization', 'label': 'specialization', 'actor': actor_id, 'id': spec['spec_id']},
    ]
    for entry, rank in spec['talents'][str(level)]:
        steps.append({'action': 'advancement_rank', 'label': 'advancement_rank', 'actor': actor_id,
                       'entry': entry, 'rank': rank})
    for row in gear_items:
        steps.append({'action': 'equip', 'label': 'equip', 'actor': actor_id,
                       'item': row['item'], 'slot': row['slot']})
    first_elite = dungeon['elites'][0]
    steps.append({'action': 'balance_white', 'label': 'balance_white', 'actor': actor_id,
                  'entry': first_elite['entry'], 'level': first_elite['level'], 'swings': DEFAULT_WHITE_SWINGS})
    for stage in STAGES:
        steps.append({'action': 'balance_stage', 'label': stage, 'actor': actor_id, 'stage': stage,
                       'enemies': stage_enemies(dungeon, stage), 'cap_s': CAP_S_SECONDS})
    return steps


def build_scenario(spec, level, dungeon, gear_items):
    location = dungeon['location']
    return {
        'schema': 1,
        'name': f"Balance suite: {spec['class_name']} {spec['spec_name']} at level {level}",
        'timeout_ms': 240000,
        'location': {'map': dungeon['map'], 'x': location['x'], 'y': location['y'], 'z': location['z'],
                      'o': location['o'], 'ignore_access': True},
        'players': [build_player(spec, level)],
        'steps': build_steps(spec, level, dungeon, gear_items),
    }


def generate_scenarios(catalog, dungeons, gear, levels, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for spec in catalog['specs']:
        for level in levels:
            dungeon = dungeons['levels'][str(level)]
            gear_items = gear['gear'][str(level)][gear_key(spec)]
            scenario = build_scenario(spec, level, dungeon, gear_items)
            path = out_dir / f'{scenario_id(spec["spec_id"], level)}.json'
            path.write_text(json.dumps(scenario, indent=2), encoding='utf-8')
            paths.append(path)
    return paths


def run_suite(scenarios, output, jobs, lanes):
    command = [sys.executable, '-B', str(ROOT / 'tools/verify_all.py'), '--stages', 'gameplay',
               '--scenario', *(str(path) for path in scenarios),
               '--gameplay-jobs', str(jobs), '--gameplay-lanes', str(lanes),
               '--output', str(Path(output) / 'verify')]
    return subprocess.run(command, cwd=ROOT).returncode


def find_stage_step(steps, stage):
    for step in steps:
        if step.get('action') == 'balance_stage':
            balance = step.get('balance')
            if balance and balance.get('stage') == stage:
                return step
    return None


def find_white_step(steps):
    for step in steps:
        if step.get('action') == 'balance_white' and step.get('balance_white'):
            return step
    return None


def white_received_pct_max_health(steps):
    white_step = find_white_step(steps)
    if not white_step:
        return None
    player = white_step['balance_white'].get('received', {}).get('player')
    if not player:
        return None
    return float(player.get('avg_normal_hit_pct_max_health', 0.0))


def kit_has_owned_below_rule(spec):
    kit = spec.get('kit') or {}
    rules = list(kit.get('upkeep') or []) + list(kit.get('defensives') or [])
    return any(rule.get('when') == 'owned_below' for rule in rules)


def pets_missing(spec, balance):
    if not kit_has_owned_below_rule(spec):
        return False
    return int(float(balance['pets_owned_start'])) == 0 or int(float(balance['damage_done_pets'])) == 0


def load_case_result(cases_dir, case_id):
    result_path = cases_dir / case_id / 'result.json'
    if not result_path.is_file():
        return None, 'no result.json'
    try:
        result = json.loads(result_path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as error:
        return None, str(error)
    return result, result.get('message', 'case failed')


def harvest_row(spec, level, stage, step, white_pct):
    balance = step['balance']
    outcome = balance['outcome']
    damage_done_player = float(balance['damage_done_player'])
    damage_done_pets = float(balance['damage_done_pets'])
    damage_taken_player = float(balance['damage_taken_player'])
    damage_taken_pets = float(balance['damage_taken_pets'])
    healing_done_player = float(balance['healing_done_player'])
    healing_done_pets = float(balance['healing_done_pets'])
    duration_s = float(balance['duration_s'])
    total_damage_done = damage_done_player + damage_done_pets
    total_damage_taken = damage_taken_player + damage_taken_pets
    total_healing = healing_done_player + healing_done_pets
    return {
        'spec_id': spec['spec_id'], 'class_id': spec['class_id'], 'class_name': spec['class_name'],
        'spec_name': spec['spec_name'], 'group': spec['group'], 'armor': spec['armor'],
        'primary_stat': spec['primary_stat'], 'level': level, 'stage': stage,
        'white_received_pct_max_health': white_pct,
        'outcome': outcome,
        'duration_s': duration_s,
        'cap_s': float(step.get('cap_s', CAP_S_SECONDS)),
        'ttk_s': float(balance['ttk_s']) if 'ttk_s' in balance else None,
        'ttd_s': float(balance['ttd_s']) if 'ttd_s' in balance else None,
        'health_pct_end': float(balance['health_pct_end']),
        'damage_done_player': damage_done_player, 'damage_done_pets': damage_done_pets,
        'damage_taken_player': damage_taken_player, 'damage_taken_pets': damage_taken_pets,
        'healing_done_player': healing_done_player, 'healing_done_pets': healing_done_pets,
        'pets_owned_start': int(float(balance['pets_owned_start'])),
        'pets_alive_end': int(float(balance['pets_alive_end'])),
        'dps': total_damage_done / duration_s if duration_s > 0 else 0.0,
        'dtps': total_damage_taken / duration_s if duration_s > 0 else 0.0,
        'hps': total_healing / duration_s if duration_s > 0 else 0.0,
        'pet_share': damage_done_pets / total_damage_done if total_damage_done > 0 else 0.0,
        'pets_missing': pets_missing(spec, balance),
    }


def error_row(spec, level, stage, message, white_pct):
    return {
        'spec_id': spec['spec_id'], 'class_id': spec['class_id'], 'class_name': spec['class_name'],
        'spec_name': spec['spec_name'], 'group': spec['group'], 'armor': spec['armor'],
        'primary_stat': spec['primary_stat'], 'level': level, 'stage': stage,
        'white_received_pct_max_health': white_pct,
        'outcome': 'error', 'message': message,
    }


def harvest(verify_output, catalog, levels=LEVELS):
    cases_dir = Path(verify_output) / 'gameplay' / 'exploratory'
    rows = []
    for spec in catalog['specs']:
        for level in levels:
            case_id = scenario_id(spec['spec_id'], level)
            result, message = load_case_result(cases_dir, case_id)
            steps = result.get('steps', []) if result else []
            white_pct = white_received_pct_max_health(steps)
            for stage in STAGES:
                step = find_stage_step(steps, stage)
                if step is None:
                    rows.append(error_row(spec, level, stage, message, white_pct))
                else:
                    rows.append(harvest_row(spec, level, stage, step, white_pct))
    return rows


def effective_ttk(row):
    return row['ttk_s'] if row['outcome'] == 'win' else None


def effective_ttd(row):
    if row['outcome'] == 'loss':
        return row['ttd_s']
    if row['outcome'] == 'timeout':
        return row.get('cap_s')
    return None


def median_or_none(values):
    return statistics.median(values) if values else None


def group_summaries(valid_rows):
    groups = defaultdict(list)
    for row in valid_rows:
        groups[(row['group'], row['level'], row['stage'])].append(row)
    summaries = {}
    for key, members in groups.items():
        summary = {metric: median_or_none([member[metric] for member in members]) for metric in RATIO_METRICS}
        summary['ttk_s'] = median_or_none([value for value in (effective_ttk(member) for member in members)
                                            if value is not None])
        summary['ttd_s'] = median_or_none([value for value in (effective_ttd(member) for member in members)
                                            if value is not None])
        summary['majority_outcome'] = Counter(member['outcome'] for member in members).most_common(1)[0][0]
        summary['n'] = len(members)
        summaries[key] = summary
    return summaries


def ratio_and_flag(value, median, threshold, flaggable):
    if value is None or not median:
        return None, False
    ratio = value / median
    flagged = flaggable and (ratio > threshold or ratio < 1 / threshold)
    return ratio, bool(flagged)


def apply_tank_rules(row, dps_group_medians, tank_combined_ttd_medians):
    key = (row['level'], row['stage'])
    row['tank_clears'] = row['outcome'] == 'win' and row['stage'] in ('elite_2', 'elite_3', 'boss')
    combined_median = tank_combined_ttd_medians.get(key)
    ttd = effective_ttd(row)
    row['tank_dies_early'] = bool(combined_median is not None and ttd is not None and ttd < combined_median)
    dps_median = dps_group_medians.get(key)
    row['tank_dps_high'] = bool(dps_median is not None and row['dps'] >= dps_median)


def compare(rows, threshold):
    valid_rows = [row for row in rows if row['outcome'] != 'error']
    summaries = group_summaries(valid_rows)
    dps_group_medians = {(level, stage): summary['dps']
                          for (group, level, stage), summary in summaries.items() if group == 'dps'}
    tank_combined_ttd = defaultdict(list)
    for row in valid_rows:
        if row['group'] not in ('dps', 'healer'):
            continue
        ttd = effective_ttd(row)
        if ttd is not None:
            tank_combined_ttd[(row['level'], row['stage'])].append(ttd)
    tank_combined_ttd_medians = {key: statistics.median(values) for key, values in tank_combined_ttd.items()}

    out = []
    for row in rows:
        enriched = dict(row)
        if row['outcome'] == 'error':
            out.append(enriched)
            continue
        key = (row['group'], row['level'], row['stage'])
        summary = summaries[key]
        flaggable = summary['n'] >= 3
        for metric in RATIO_METRICS:
            ratio, flagged = ratio_and_flag(row[metric], summary[metric], threshold, flaggable)
            enriched[f'median_{metric}'] = summary[metric]
            enriched[f'ratio_{metric}'] = ratio
            enriched[f'flag_{metric}'] = flagged
        ratio_ttk, flag_ttk = ratio_and_flag(effective_ttk(row), summary['ttk_s'], threshold, flaggable)
        enriched['median_ttk_s'] = summary['ttk_s']
        enriched['ratio_ttk_s'] = ratio_ttk
        enriched['flag_ttk_s'] = flag_ttk
        ratio_ttd, flag_ttd = ratio_and_flag(effective_ttd(row), summary['ttd_s'], threshold, flaggable)
        enriched['median_ttd_s'] = summary['ttd_s']
        enriched['ratio_ttd_s'] = ratio_ttd
        enriched['flag_ttd_s'] = flag_ttd
        enriched['n'] = summary['n']
        enriched['flag_outcome'] = bool(flaggable and row['outcome'] != summary['majority_outcome'])
        enriched['pets_missing'] = bool(row.get('pets_missing'))
        if row['group'] == 'tank':
            apply_tank_rules(enriched, dps_group_medians, tank_combined_ttd_medians)
        if row['group'] == 'dps-support':
            dps_median = dps_group_medians.get((row['level'], row['stage']))
            enriched['ratio_dps_vs_dps'] = row['dps'] / dps_median if dps_median else None
        out.append(enriched)
    return out


def write_csv(rows, path):
    path = Path(path)
    fieldnames = []
    seen = set()
    for row in rows:
        for key in row:
            if key not in seen:
                seen.add(key)
                fieldnames.append(key)
    with path.open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames, restval='')
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def format_number(value, digits=1):
    return '-' if value is None else format(value, f'.{digits}f')


def format_stage_cell(row):
    if row is None:
        return '<td class="missing">-</td>'
    group = html.escape(str(row.get('group', '')))
    if row['outcome'] == 'error':
        message = html.escape(str(row.get('message', '')))
        return f'<td class="error" data-group="{group}">error: {message}</td>'
    flagged = any(row.get(key) for key in FLAG_KEYS)
    classes = 'flagged' if flagged else ''
    text = (f"{row['outcome']} dps={format_number(row.get('dps'), 0)} dtps={format_number(row.get('dtps'), 0)} "
            f"ttk={format_number(row.get('ttk_s'))} ttd={format_number(row.get('ttd_s'))}")
    return f'<td class="{classes}" data-group="{group}">{html.escape(text)}</td>'


def pivot_by_level_and_spec(rows):
    by_level = defaultdict(dict)
    for row in rows:
        spec_rows = by_level[row['level']].setdefault(row['spec_id'], {'info': row, 'stages': {}})
        spec_rows['stages'][row['stage']] = row
    return by_level


def write_html(rows, path):
    path = Path(path)
    by_level = pivot_by_level_and_spec(rows)
    parts = [
        '<!doctype html>',
        '<html><head><meta charset="utf-8"><title>CoA PvE balance suite</title>',
        '<style>',
        'body { font-family: sans-serif; }',
        'table { border-collapse: collapse; margin-bottom: 24px; }',
        'th, td { border: 1px solid #888; padding: 4px 8px; font-family: monospace; font-size: 12px; }',
        '.flagged { background: #f8d7a0; }',
        '.error { background: #f5a0a0; }',
        '.missing { color: #999; }',
        '</style></head><body>',
        '<label>Filter group: <select id="group-filter" onchange="',
        "var g=this.value;document.querySelectorAll('[data-group]').forEach(function(cell){",
        "cell.closest('tr').style.display=(g==='all'||cell.dataset.group===g)?'':'none';});",
        '">',
        '<option value="all">all</option>',
    ]
    for group in GROUPS:
        parts.append(f'<option value="{group}">{group}</option>')
    parts.append('</select></label>')
    for level in sorted(by_level):
        parts.append(f'<h2>Level {level}</h2>')
        parts.append('<table><thead><tr><th>Spec</th><th>Group</th><th>White received %</th>')
        for stage in STAGES:
            parts.append(f'<th>{stage}</th>')
        parts.append('</tr></thead><tbody>')
        for spec_id in sorted(by_level[level]):
            entry = by_level[level][spec_id]
            info = entry['info']
            group = html.escape(str(info['group']))
            parts.append('<tr>')
            parts.append(f"<td>{html.escape(str(info['class_name']))} {html.escape(str(info['spec_name']))}</td>")
            parts.append(f'<td data-group="{group}">{group}</td>')
            white = info.get('white_received_pct_max_health')
            parts.append(f'<td>{format_number(white, 2)}</td>')
            for stage in STAGES:
                parts.append(format_stage_cell(entry['stages'].get(stage)))
            parts.append('</tr>')
        parts.append('</tbody></table>')
    parts.append('</body></html>')
    path.write_text('\n'.join(parts), encoding='utf-8')


def load_json(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def select_specs(catalog, spec_ids):
    if not spec_ids:
        return catalog
    wanted = {int(value) for value in spec_ids.split(',')}
    return {**catalog, 'specs': [spec for spec in catalog['specs'] if spec['spec_id'] in wanted]}


def write_report(output, threshold, catalog=None, levels=LEVELS):
    if catalog is None:
        catalog = load_json(CATALOG_PATH)
    rows = harvest(Path(output) / 'verify', catalog, levels)
    rows = compare(rows, threshold)
    write_csv(rows, Path(output) / 'report.csv')
    write_html(rows, Path(output) / 'report.html')
    return rows


def cli_run(args):
    global CAP_S_SECONDS
    CAP_S_SECONDS = args.cap_s
    catalog = select_specs(load_json(CATALOG_PATH), args.specs)
    dungeons = load_json(DUNGEONS_PATH)
    gear = load_json(GEAR_PATH)
    levels = [int(value) for value in args.levels.split(',')]
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    scenarios = generate_scenarios(catalog, dungeons, gear, levels, output / 'scenarios')
    returncode = run_suite(scenarios, output, args.jobs, args.lanes)
    write_report(output, args.threshold, catalog, levels)
    return returncode


def cli_report(args):
    write_report(args.output, args.threshold)
    return 0


def build_parser():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command', required=True)

    run_parser = subparsers.add_parser('run')
    run_parser.add_argument('--output', required=True)
    run_parser.add_argument('--jobs', type=int, default=4)
    run_parser.add_argument('--lanes', type=int, default=15)
    run_parser.add_argument('--levels', default=','.join(str(level) for level in LEVELS))
    run_parser.add_argument('--specs')
    run_parser.add_argument('--cap-s', type=int, default=CAP_S_SECONDS)
    run_parser.add_argument('--threshold', type=float, default=DEFAULT_THRESHOLD)
    run_parser.set_defaults(func=cli_run)

    report_parser = subparsers.add_parser('report')
    report_parser.add_argument('--output', required=True)
    report_parser.add_argument('--threshold', type=float, default=DEFAULT_THRESHOLD)
    report_parser.set_defaults(func=cli_report)

    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
