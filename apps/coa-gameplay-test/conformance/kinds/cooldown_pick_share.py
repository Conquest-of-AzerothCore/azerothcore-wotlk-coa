from dataclasses import dataclass, replace
from math import comb
from pathlib import Path
from statistics import median

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'cooldown_pick_share'
ORDER = 40
SHARE_ALPHA = 0.001
CONTROL = 'control'
TREATMENT = 'treatment'


@dataclass(frozen=True)
class CooldownPickSpec:
    spell: int
    name: str
    quote: str
    command_spell: int
    command_power: int
    command_gap_ms: int
    commands: int
    pool: tuple[int, ...]
    cut_ms: float
    tolerance_ms: float
    cycles: int
    control_cycles: int
    zombie_entry: int
    mana: int
    settle_ms: int
    expire_ms: int
    label_suffix: str = 'pick_share'


def cooldown_pick_spec(entry: dict) -> CooldownPickSpec:
    spec = CooldownPickSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['command_spell']),
                            int(entry['command_power']), int(entry.get('command_gap_ms', 1600)),
                            int(entry['commands']), tuple(int(spell) for spell in entry['pool']),
                            float(entry['cut_ms']), float(entry.get('tolerance_ms', 100)), int(entry['cycles']),
                            int(entry.get('control_cycles', 1)), int(entry['zombie_entry']), int(entry['mana']),
                            int(entry.get('settle_ms', 300)), int(entry.get('expire_ms', 15500)),
                            entry.get('label_suffix', 'pick_share'))
    if len(spec.pool) < 2 or spec.cycles < 1 or spec.control_cycles < 1 or spec.commands < 2:
        raise ValueError(f'{spec.spell} {KIND} needs a pool of two or more spells, cycles, control cycles and '
                         f'two or more Commands per cycle')
    if spec.command_gap_ms < 1500 or spec.tolerance_ms <= 0 or spec.cut_ms <= 2 * spec.tolerance_ms:
        raise ValueError(f'{spec.spell} {KIND} spaces Commands by the global cooldown and needs a cut above twice '
                         f'its tolerance')
    return spec


def pick_label(spec: CooldownPickSpec, phase: str, cycle: int, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {phase} {cycle} {read}'


def command_steps(spec: CooldownPickSpec) -> list[dict]:
    return [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.command_spell},
            {'action': 'set_power', 'actor': CASTER, 'power': 6, 'value': spec.command_power},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.command_spell, 'target': TARGET},
            {'action': 'wait', 'label': 'Command gap', 'ms': spec.command_gap_ms}]


def cycle_steps(records: Records, spec: CooldownPickSpec, phase: str, cycle: int) -> tuple[list[dict], dict]:
    def label(read: str) -> str:
        return pick_label(spec, phase, cycle, read)

    steps = []
    for spell in spec.pool:
        steps += hit_ratio_cast(records, spell, CASTER, CASTER, spec.mana)
        steps.append(measurement(label(f'prime {spell}'), CASTER, 'cast_failure', spell=spell))
    for _ in range(spec.commands - 1):
        steps += command_steps(spec)
    steps += [measurement(label(f'pre {spell}'), CASTER, 'cooldown_ms', spell=spell) for spell in spec.pool]
    steps += command_steps(spec)[:-1]
    steps.append({'action': 'wait', 'label': 'cut settle', 'ms': spec.settle_ms})
    steps += [measurement(label(f'post {spell}'), CASTER, 'cooldown_ms', spell=spell) for spell in spec.pool]
    steps.append(measurement(label('zombie'), CASTER, 'owned_creature_count', entry=spec.zombie_entry))
    steps.append({'action': 'wait', 'label': 'summons expire', 'ms': spec.expire_ms})
    row = {'phase': phase, 'prime': [label(f'prime {spell}') for spell in spec.pool],
           'pre': [label(f'pre {spell}') for spell in spec.pool],
           'post': [label(f'post {spell}') for spell in spec.pool], 'zombie': label('zombie')}
    return steps, row


def cooldown_pick_scenario(class_file: dict, spec: CooldownPickSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(len(spec.pool)))
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (*spec.pool, spec.command_spell)])
    rows = []
    for cycle in range(1, spec.control_cycles + 1):
        cycle_part, row = cycle_steps(records, spec, CONTROL, cycle)
        steps += cycle_part
        rows.append(row)
    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
    for cycle in range(1, spec.cycles + 1):
        cycle_part, row = cycle_steps(records, spec, TREATMENT, cycle)
        steps += cycle_part
        rows.append(row)
    pool = ', '.join(str(spell) for spell in spec.pool)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cooldown pick share',
        'contract': (f'The pool {pool} is learned and every cycle primes each of them with a real cast (cooldown '
                     f'reset first), then gives {spec.commands} Commands {spec.command_spell} at the dummy '
                     f'{spec.command_gap_ms} ms apart. The cooldowns of the pool are read before and '
                     f'{spec.settle_ms} ms after the last Command. A drop beyond the elapsed time (the median drop) '
                     f'of {spec.cut_ms:g} +- {spec.tolerance_ms:g} ms is a pick. {spec.control_cycles} control '
                     f'cycle(s) before {spec.spell} is learned pick nothing; each of the {spec.cycles} cycles after '
                     f'it picks exactly one spell. Pooled over the parts, every spell is picked and each count lies '
                     f'inside the two-sided {1 - SHARE_ALPHA:g} binomial band of a uniform pick.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'cooldown_ms', 'quote': entry.quote, 'pool': list(spec.pool), 'rows': rows,
             'cut_ms': spec.cut_ms, 'tolerance_ms': spec.tolerance_ms, 'expected': float(len(spec.pool))}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, f'{len(spec.pool)}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def share_band(trials: int, choices: int, alpha: float = SHARE_ALPHA) -> tuple[int, int]:
    chance = 1 / choices
    masses = [comb(trials, count) * chance ** count * (1 - chance) ** (trials - count) for count in range(trials + 1)]
    low, below = 0, masses[0]
    while low < trials and below <= alpha / 2:
        low += 1
        below += masses[low]
    high, above = trials, masses[trials]
    while high > 0 and above <= alpha / 2:
        high -= 1
        above += masses[high]
    return low, high


def classify_cycles(run, model: dict) -> tuple[list[int | None], list[str], str | None]:
    from compare import missing_measurement
    picks, phases = [], []
    cut, tolerance = float(model['cut_ms']), float(model['tolerance_ms'])
    for row in model['rows']:
        labels = [*row['prime'], *row['pre'], *row['post'], row['zombie']]
        missing = next((label for label in labels if run.values.get(label) is None), None)
        if missing is not None:
            return [], [], missing_measurement(run, missing)
        if any(run.values[label] != 0 for label in row['prime']):
            return [], [], f'{run.key}: a priming cast of the pool was refused in {row["prime"][0].rsplit(" ", 1)[0]}'
        pre = [run.values[label] for label in row['pre']]
        if min(pre) <= cut + tolerance:
            return [], [], f'{run.key}: a pool cooldown ran out before the cut could land ({min(pre):g} ms left)'
        drops = [before - run.values[after] for before, after in zip(pre, row['post'])]
        elapsed = median(drops)
        extra = [drop - elapsed for drop in drops]
        cut_at = [index for index, value in enumerate(extra) if abs(value - cut) <= tolerance]
        untouched = [index for index, value in enumerate(extra) if abs(value) <= tolerance]
        if len(untouched) == len(extra):
            picks.append(None)
        elif len(cut_at) == 1 and len(untouched) == len(extra) - 1:
            picks.append(cut_at[0])
        else:
            picks.append(-1)
        phases.append(row['phase'])
        if row['phase'] == CONTROL and run.values[row['zombie']] != 0:
            picks[-1] = -1
    return picks, phases, None


def pick_share_verdict(base, runs: list, model: dict):
    pool = model['pool']
    control, treatment = [], []
    for run in runs:
        picks, phases, problem = classify_cycles(run, model)
        if problem is not None:
            return replace(base, status='unmeasured', explanation=problem)
        control += [pick for pick, phase in zip(picks, phases) if phase == CONTROL]
        treatment += [pick for pick, phase in zip(picks, phases) if phase == TREATMENT]
    counts = [treatment.count(index) for index in range(len(pool))]
    low, high = share_band(len(treatment), len(pool))
    shares = ', '.join(f'{spell} {count}' for spell, count in zip(pool, counts))
    faults = []
    if any(pick is not None for pick in control):
        faults.append(f'{sum(pick is not None for pick in control)} of {len(control)} control cycles cut a cooldown '
                      f'or summoned')
    if any(pick is None or pick < 0 for pick in treatment):
        faults.append(f'{sum(pick is None or pick < 0 for pick in treatment)} of {len(treatment)} cycles did not '
                      f'cut exactly one cooldown by {model["cut_ms"]:g} +- {model["tolerance_ms"]:g} ms')
    if any(count == 0 for count in counts):
        faults.append('a spell of the pool was never picked')
    if any(not low <= count <= high for count in counts):
        faults.append(f'a count lies outside the uniform band {low}..{high}')
    picked = float(sum(count > 0 for count in counts))
    explanation = (f'{len(control)} control cycles, {len(treatment)} cycles with the talent; picks {shares} against '
                   f'a uniform band {low}..{high} of {len(treatment)}')
    return replace(base, status='alert' if faults else 'ok', measured=picked, expected=float(len(pool)),
                   low=float(len(pool)), high=float(len(pool)),
                   detail={'counts': dict(zip(map(str, pool), counts)), 'band': [low, high],
                           'cycles': len(treatment), 'parts': len(runs)},
                   explanation=explanation + (': ' + '; '.join(faults) if faults else ': every cycle cut exactly '
                                              'one cooldown and every spell was picked inside the band'))


def pick_share_single_verdict(base, run, model: dict):
    return pick_share_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_pick_scenario(class_file, cooldown_pick_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'pick_share')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: pick_share_single_verdict}


POOLED_JUDGE = pick_share_verdict
