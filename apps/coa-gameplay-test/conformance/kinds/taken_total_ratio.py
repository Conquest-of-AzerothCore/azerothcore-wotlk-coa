import math
from dataclasses import dataclass, replace
from fractions import Fraction
from pathlib import Path

from behaviours import (BEHAVIOUR_HIT_RATIO, STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH, TAKEN_HIT_STRIKER_ENTRY,
                        behaviour_entry, hit_ratio_cast, prose_rule, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'taken_total_ratio'
ORDER = 54
METRIC = 'spell_damage_with_resist_total'
STAMINA = 2
STRIKE_WAIT_MS = 300
SETTLE_MS = 500
MAGIC_SUFFIX = 'magic_taken'
BROKEN_SUFFIX = 'physical_after_break'
READS = ('total', 'absorb', 'logs', 'crits')


@dataclass(frozen=True)
class Arm:
    name: str
    strike: str
    barrier: bool = False
    breaker: bool = False


ARMS = (Arm('control', 'physical'), Arm('treatment', 'physical', barrier=True),
        Arm('magic_control', 'magic'), Arm('magic', 'magic', barrier=True),
        Arm('broken', 'physical', barrier=True, breaker=True))


@dataclass(frozen=True)
class TotalRatioSpec:
    spell: int
    name: str
    quote: str
    strike_spell: int
    magic_spell: int
    reduction_effect: int
    absorb_effect: int
    stamina_coefficient: float
    trials: int
    caster_max_health: int
    label_suffix: str


def total_ratio_spec(entry: dict) -> TotalRatioSpec:
    return TotalRatioSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['strike_spell']),
                          int(entry['magic_spell']), int(entry['reduction_effect']), int(entry['absorb_effect']),
                          float(entry['stamina_coefficient']), int(entry['trials']), int(entry['caster_max_health']),
                          entry['label_suffix'])


def labels_of(spell: int, suffix: str) -> dict[str, str]:
    return {name: f'{spell} {BEHAVIOUR_HIT_RATIO} {label}'
            for name, label in (('physical', suffix), ('magic', MAGIC_SUFFIX), ('broken', BROKEN_SUFFIX))}


def mark(spec: TotalRatioSpec, arm: str, index, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_HIT_RATIO} {spec.label_suffix} {arm} {index} {read}'


def strike_reads(spec: TotalRatioSpec, arm: Arm, index) -> list[dict]:
    spell = spec.strike_spell if arm.strike == 'physical' else spec.magic_spell
    strike = {'spell': spell, 'caster': STRIKER, 'target': CASTER}
    return [measurement(mark(spec, arm.name, index, 'total'), CASTER, METRIC, **strike, critical=False),
            measurement(mark(spec, arm.name, index, 'absorb'), CASTER, 'spell_absorb_total', **strike,
                        critical=False),
            measurement(mark(spec, arm.name, index, 'logs'), CASTER, 'spell_log_count', **strike, critical=False),
            measurement(mark(spec, arm.name, index, 'crits'), CASTER, 'spell_log_count', **strike, critical=True)]


def arm_steps(records: Records, spec: TotalRatioSpec, arm: Arm) -> list[dict]:
    steps = [measurement(mark(spec, arm.name, 'start', 'stamina'), CASTER, 'stat', stat=STAMINA)]
    steps += strike_reads(spec, arm, 'start')
    for index in range(1, spec.trials + 1):
        steps.append({'action': 'set_health', 'actor': CASTER, 'value': spec.caster_max_health,
                      'maximum': spec.caster_max_health})
        if arm.barrier:
            steps += hit_ratio_cast(records, spec.spell, CASTER, CASTER)
            steps.append(measurement(mark(spec, arm.name, index, 'held'), CASTER, 'aura', spell=spec.spell))
        if arm.breaker:
            steps += [{'action': 'cast', 'actor': STRIKER, 'spell': spec.magic_spell, 'target': CASTER},
                      {'action': 'wait', 'label': f'{arm.name} break {index}', 'ms': STRIKE_WAIT_MS},
                      measurement(mark(spec, arm.name, index, 'broken'), CASTER, 'aura', spell=spec.spell)]
        strike = spec.strike_spell if arm.strike == 'physical' else spec.magic_spell
        steps += [{'action': 'cast', 'actor': STRIKER, 'spell': strike, 'target': CASTER},
                  {'action': 'wait', 'label': f'{arm.name} strike {index}', 'ms': SETTLE_MS}]
        steps += strike_reads(spec, arm, index)
        if arm.barrier:
            steps.append({'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.spell})
    return steps


def stated(records: Records, spec: TotalRatioSpec, level: int) -> dict:
    reduction = int(records.single_value(spec.spell, spec.reduction_effect, level))
    return {'factor': [100 + reduction, 100], 'reduction_pct': -reduction,
            'absorb_low': records.points(spec.spell, spec.absorb_effect, upper=False, level=level),
            'absorb_high': records.points(spec.spell, spec.absorb_effect, upper=True, level=level),
            'stamina_coefficient': spec.stamina_coefficient}


def total_ratio_scenario(class_file: dict, spec: TotalRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    values = stated(records, spec, int(class_file['level']))
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    for arm in ARMS:
        steps += arm_steps(records, spec, arm)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour taken total ratio',
        'contract': (f'A passive, stationary striker (creature entry {TAKEN_HIT_STRIKER_ENTRY}, level '
                     f'{class_file["level"]}) casts one strike at the caster per trial, {spec.trials} trials per arm '
                     f'{[arm.name for arm in ARMS]}, the caster held at {spec.caster_max_health} health: '
                     f'{spec.strike_spell} in the physical arms, {spec.magic_spell} in the magic arms. The barrier '
                     f'arms cast {spec.spell} before each strike and cancel it after; the broken arm first breaks '
                     f'it with {spec.magic_spell}. Each strike is read from the spell logs the caster receives as '
                     f'its damage plus resisted plus absorbed amount, non-critical strikes only: the treatment total '
                     f'must be {values["reduction_pct"]}% below the control total, within the integer rounding of '
                     f'the multiplier, with part of it absorbed; the magic and broken totals must equal their '
                     f'controls; the magic arm absorbs the barrier\'s stated amount, '
                     f'{values["absorb_low"]:g} to {values["absorb_high"]:g} plus {spec.stamina_coefficient:g} x '
                     f'Stamina.'),
        'players': [player_fixture(class_file)],
        'creatures': [{'id': STRIKER, 'owner': CASTER, 'entry': TAKEN_HIT_STRIKER_ENTRY,
                       'level': class_file['level'], 'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE,
                       'stationary': True, 'spell_hit_bonus': 100}],
        'steps': base_steps(class_file) + steps}
    reads = {arm.name: {mark_name: {read: mark(spec, arm.name, mark_name, read) for read in
                                    (*READS, *(('held',) if arm.barrier and mark_name != 'start' else ()),
                                     *(('broken',) if arm.breaker and mark_name != 'start' else ()))}
                        for mark_name in ('start', *map(str, range(1, spec.trials + 1)))} for arm in ARMS}
    stamina = mark(spec, 'magic', 'start', 'stamina')
    labels = labels_of(spec.spell, spec.label_suffix)
    expectations = []
    for judged, arms, factor in (('physical', ('control', 'treatment'), values['factor']),
                                 ('magic', ('magic_control', 'magic'), [1, 1]),
                                 ('broken', ('control', 'broken'), [1, 1])):
        model = {'kind': KIND, 'judged': judged, 'metric': METRIC, 'quote': entry.quote, 'arms': list(arms),
                 'factor': factor, 'trials': spec.trials, 'reads': {name: reads[name] for name in arms},
                 'stamina': stamina, **{key: values[key] for key in ('absorb_low', 'absorb_high',
                                                                       'stamina_coefficient')}}
        expectations.append(Expectation(labels[judged], BEHAVIOUR_HIT_RATIO, spec.spell, spec.strike_spell
                                        if judged != 'magic' else spec.magic_spell, None,
                                        str(factor[0] / factor[1]), prose_rule(entry.quote, spec.spell), model))
    return timed(scenario, waited_ms(steps)), expectations


def trial_rows(run: Run, reads: dict) -> list[dict] | str:
    rows, previous = [], reads['start']
    for mark_name, labels in reads.items():
        if mark_name == 'start':
            continue
        values = {}
        for read, label in labels.items():
            value = run.values.get(label)
            if value is None:
                return missing_measurement(run, label)
            values[read] = value if read in ('held', 'broken') else value - run.values[previous[read]]
        previous = labels
        values['landed'] = values['logs'] == 1 and values['crits'] == 0
        values['sum'] = values['total'] + values['absorb']
        rows.append(values)
    for label in reads['start'].values():
        if run.values.get(label) is None:
            return missing_measurement(run, label)
    return rows


def band(factor: list[int], control: float) -> tuple[int, int]:
    ratio = Fraction(factor[0], factor[1])
    return math.floor(ratio * int(control)), math.ceil(ratio * (int(control) + 1)) - 1


def total_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    control_name, arm_name = model['arms']
    rows = {}
    for name in model['arms']:
        found = trial_rows(run, model['reads'][name])
        if isinstance(found, str):
            return replace(base, status='unmeasured', explanation=found)
        rows[name] = [row for row in found if row['landed']]
    minimum = max(1, model['trials'] // 2)
    short = [f'{name} landed {len(rows[name])} of {model["trials"]} non-critical strikes' for name in rows
             if len(rows[name]) < minimum]
    if short:
        return replace(base, status='unmeasured', explanation='; '.join(short) + f', each arm needs {minimum}')
    controls = sorted({row['sum'] for row in rows[control_name]})
    absorbed = [row['absorb'] for row in rows[control_name]]
    if len(controls) != 1 or any(absorbed):
        return replace(base, status='unmeasured', explanation=f'{control_name} strikes read totals {controls} and '
                                                              f'absorbed {absorbed}; the control needs one total '
                                                              f'and no absorb')
    control = controls[0]
    low, high = band(model['factor'], control)
    faults = []
    stamina = run.values.get(model['stamina']) if model['judged'] == 'magic' else None
    if model['judged'] == 'magic' and stamina is None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, model['stamina']))
    for index, row in enumerate(rows[arm_name], 1):
        if row.get('held') != 1:
            faults.append(f'trial {index} without the barrier before the strike')
            continue
        if not low <= row['sum'] <= high:
            faults.append(f'trial {index} total {row["sum"]:g} outside {low}..{high}')
        if model['judged'] == 'physical' and not row['absorb']:
            faults.append(f'trial {index} absorbed nothing, the barrier did not hold')
        if model['judged'] == 'broken' and (row.get('broken') != 0 or row['absorb']):
            faults.append(f'trial {index} barrier {row.get("broken"):g} after the break, absorbed {row["absorb"]:g}')
        if model['judged'] == 'magic':
            least = math.floor(model['absorb_low'] + model['stamina_coefficient'] * stamina)
            most = math.ceil(model['absorb_high'] + model['stamina_coefficient'] * stamina)
            if not least <= row['absorb'] <= most:
                faults.append(f'trial {index} absorbed {row["absorb"]:g} outside {least}..{most} '
                              f'(Stamina {stamina:g})')
    sums = [row['sum'] for row in rows[arm_name]]
    measured = sum(sums) / len(sums) / control if control else 0.0
    expected = model['factor'][0] / model['factor'][1]
    return replace(base, status='alert' if faults else 'ok', measured=measured, expected=expected,
                   low=low / control if control else None, high=high / control if control else None,
                   explanation=f'{control_name} total {control:g} per strike; {arm_name} totals {sorted(set(sums))}, '
                               f'absorbed {sorted({row["absorb"] for row in rows[arm_name]})}, stated {low}..{high}'
                               f' (x {expected:g}); ' + ('; '.join(faults[:6]) if faults else
                                                         'every landed strike matches'))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return total_ratio_scenario(class_file, total_ratio_spec(entry))


def label(entry: dict) -> list[str]:
    return list(labels_of(int(entry['spell']), entry['label_suffix']).values())


JUDGES = {BEHAVIOUR_HIT_RATIO: total_ratio_verdict}
