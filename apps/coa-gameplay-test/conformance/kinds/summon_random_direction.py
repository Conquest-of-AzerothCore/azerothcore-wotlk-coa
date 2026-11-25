from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, describe_failures, failure_reasons, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'summon_random_direction'
ORDER = 60
X_METRIC = 'owned_creature_copy_x'
Y_METRIC = 'owned_creature_copy_y'
METRIC_EVIDENCE = {X_METRIC: 'event', Y_METRIC: 'event'}
MIN_COPIES_OBSERVED = 24
SECTORS = 8
DEFAULT_MIN_SECTORS = 5
DEFAULT_MAX_RESULTANT = 0.65
DEFAULT_START_WAIT_MS = 50
PAIR_RUNS = 2
FIELDS = frozenset({
    'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'trigger_spell', 'entry', 'copies',
    'casts', 'parts', 'duration_spell', 'start_wait_ms', 'run_ms', 'despawn_wait_ms', 'min_run_yd',
    'max_resultant', 'min_sectors', 'cast_power', 'observe_source'})


@dataclass(frozen=True)
class SummonRandomDirectionSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    entry: int
    copies: int
    casts: int
    parts: int
    duration_spell: int
    start_wait_ms: int
    run_ms: int
    despawn_wait_ms: int
    min_run_yd: float
    max_resultant: float
    min_sectors: int
    cast_power: int | None
    label_suffix: str


def summon_random_direction_spec(entry: dict) -> SummonRandomDirectionSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(unknown)}')
    spell = int(entry['spell'])
    trigger_spell = int(entry.get('trigger_spell', spell))
    creature_entry = entry['entry']
    copies = entry['copies']
    casts = entry['casts']
    parts = entry.get('parts', 1)
    for name, value in (('entry', creature_entry), ('copies', copies), ('casts', casts), ('parts', parts)):
        if isinstance(value, bool) or not isinstance(value, int) or value < 1:
            raise ValueError(f'{spell} {KIND} {name} must be a positive integer')
    if copies < 2:
        raise ValueError(f'{spell} {KIND} copies must be >= 2')
    if casts * copies * parts < MIN_COPIES_OBSERVED:
        raise ValueError(f'{spell} {KIND} observes {casts * copies * parts} copies, below minimum '
                         f'{MIN_COPIES_OBSERVED}')
    duration_spell = entry.get('duration_spell', spell)
    if isinstance(duration_spell, bool) or not isinstance(duration_spell, int) or duration_spell < 1:
        raise ValueError(f'{spell} {KIND} duration_spell must be a positive spell id')
    start_wait_ms = entry.get('start_wait_ms', DEFAULT_START_WAIT_MS)
    run_ms = entry['run_ms']
    despawn_wait_ms = entry['despawn_wait_ms']
    for name, value in (('start_wait_ms', start_wait_ms), ('run_ms', run_ms), ('despawn_wait_ms', despawn_wait_ms)):
        if isinstance(value, bool) or not isinstance(value, int) or value < 1:
            raise ValueError(f'{spell} {KIND} {name} must be a positive integer')
    min_run_yd = entry['min_run_yd']
    if isinstance(min_run_yd, bool) or not isinstance(min_run_yd, (int, float)) or min_run_yd <= 0:
        raise ValueError(f'{spell} {KIND} min_run_yd must be positive')
    max_resultant = entry.get('max_resultant', DEFAULT_MAX_RESULTANT)
    if isinstance(max_resultant, bool) or not isinstance(max_resultant, (int, float)) or not 0 < max_resultant < 1:
        raise ValueError(f'{spell} {KIND} max_resultant must lie strictly in (0, 1)')
    min_sectors = entry.get('min_sectors', DEFAULT_MIN_SECTORS)
    if (isinstance(min_sectors, bool) or not isinstance(min_sectors, int)
            or not DEFAULT_MIN_SECTORS <= min_sectors <= SECTORS):
        raise ValueError(f'{spell} {KIND} min_sectors must be in {DEFAULT_MIN_SECTORS}..{SECTORS}')
    cast_power = entry.get('cast_power')
    if cast_power is not None and (isinstance(cast_power, bool) or not isinstance(cast_power, int) or cast_power < 0):
        raise ValueError(f'{spell} {KIND} cast_power must be a non-negative integer')
    return SummonRandomDirectionSpec(
        spell, entry['name'], entry['quote'], trigger_spell, creature_entry, copies, casts, parts,
        duration_spell, start_wait_ms, run_ms, despawn_wait_ms, float(min_run_yd), float(max_resultant),
        min_sectors, cast_power, entry.get('label_suffix', KIND))


def mark(spec: SummonRandomDirectionSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def false_fail_bound(total_copies: int, max_resultant: float, min_sectors: int) -> float:
    rayleigh = math.exp(-total_copies * max_resultant * max_resultant)
    sector_miss = math.comb(SECTORS, min_sectors - 1) * ((min_sectors - 1) / SECTORS) ** total_copies
    return min(1.0, rayleigh + sector_miss)


def summon_random_direction_scenario(class_file: dict,
                                     spec: SummonRandomDirectionSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.copies))
    duration_ms = int(records.duration_ms(spec.duration_spell) or 0)
    if duration_ms <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs a positive duration on duration_spell {spec.duration_spell}')
    if spec.start_wait_ms + spec.run_ms >= duration_ms:
        raise ValueError(f'{spec.spell} {KIND} reads at {spec.start_wait_ms + spec.run_ms} ms, not strictly before '
                         f'{duration_ms} ms duration')
    if spec.start_wait_ms + spec.run_ms + spec.despawn_wait_ms <= duration_ms:
        raise ValueError(f'{spec.spell} {KIND} despawn_wait_ms must carry past {duration_ms} ms duration')
    trigger_facts = facts_of(records, spec.trigger_spell)
    control_label = mark(spec, 'control count')
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                measurement(control_label, CASTER, 'owned_creature_count', entry=spec.entry)])
    casts_model = []
    for cast_idx in range(1, spec.casts + 1):
        pre_label = mark(spec, f'cast {cast_idx} pre count')
        start_count = mark(spec, f'cast {cast_idx} start count')
        end_count = mark(spec, f'cast {cast_idx} end count')
        steps.append(measurement(pre_label, CASTER, 'owned_creature_count', entry=spec.entry))
        if spec.cast_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': trigger_facts.power_type,
                          'value': spec.cast_power})
        steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER},
                  {'action': 'wait', 'label': f'cast {cast_idx} start settle', 'ms': spec.start_wait_ms},
                  measurement(start_count, CASTER, 'owned_creature_count', entry=spec.entry)]
        start_coords = []
        for copy_idx in range(spec.copies):
            lx = mark(spec, f'cast {cast_idx} copy {copy_idx} start x')
            ly = mark(spec, f'cast {cast_idx} copy {copy_idx} start y')
            steps += [measurement(lx, CASTER, X_METRIC, entry=spec.entry, index=copy_idx),
                      measurement(ly, CASTER, Y_METRIC, entry=spec.entry, index=copy_idx)]
            start_coords.append({'x': lx, 'y': ly})
        steps += [{'action': 'wait', 'label': f'cast {cast_idx} run window', 'ms': spec.run_ms},
                  measurement(end_count, CASTER, 'owned_creature_count', entry=spec.entry)]
        end_coords = []
        for copy_idx in range(spec.copies):
            lx = mark(spec, f'cast {cast_idx} copy {copy_idx} end x')
            ly = mark(spec, f'cast {cast_idx} copy {copy_idx} end y')
            steps += [measurement(lx, CASTER, X_METRIC, entry=spec.entry, index=copy_idx),
                      measurement(ly, CASTER, Y_METRIC, entry=spec.entry, index=copy_idx)]
            end_coords.append({'x': lx, 'y': ly})
        steps.append({'action': 'wait', 'label': f'cast {cast_idx} despawn', 'ms': spec.despawn_wait_ms})
        casts_model.append({'pre': pre_label, 'start_count': start_count, 'end_count': end_count,
                            'start': start_coords, 'end': end_coords})

    total_copies = spec.casts * spec.copies * spec.parts
    ff_run = false_fail_bound(total_copies, spec.max_resultant, spec.min_sectors)
    ff_pair = min(1.0, PAIR_RUNS * ff_run)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon random direction',
        'contract': (f'Multi-copy movement and random-direction proof for {spec.trigger_spell} summoning '
                     f'{spec.copies} copies of entry {spec.entry} (duration {duration_ms} ms from '
                     f'{spec.duration_spell}). Uncast control requires owned_creature_count == 0. Across '
                     f'{spec.casts} cast(s)/part x {spec.parts} part(s) ({total_copies} total copies), reads '
                     f'GUID-sorted (x, y) at +{spec.start_wait_ms} ms and +{spec.start_wait_ms + spec.run_ms} ms '
                     f'(< {duration_ms} ms), then waits {spec.despawn_wait_ms} ms for despawn. Every copy must '
                     f'displace >= {spec.min_run_yd:g} yd during the {spec.run_ms} ms run window; across all '
                     f'{total_copies} movement bearings, mean resultant length R <= {spec.max_resultant:g} and '
                     f'occupied 45-deg sectors >= {spec.min_sectors}/{SECTORS}. Uniform-direction false-fail upper '
                     f'bound: {ff_run:.1e}/run, {ff_pair:.1e} per 2-run pair (<= 1.0e-3).'),
        'players': [player_fixture(class_file)],
        'steps': steps}
    model = {
        'kind': KIND, 'metric': X_METRIC, 'quote': entry.quote, 'copies': spec.copies, 'parts': spec.parts,
        'min_run_yd': spec.min_run_yd, 'max_resultant': spec.max_resultant, 'min_sectors': spec.min_sectors,
        'control': control_label, 'casts': casts_model}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell, None,
                              f'{spec.copies} running copies', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def summon_random_direction_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    expected_parts = int(model.get('parts', 1))
    if len(runs) != expected_parts:
        return replace(base, status='unmeasured',
                       explanation=f'received {len(runs)} part(s), expected {expected_parts}')
    copies = int(model['copies'])
    min_run_yd = float(model['min_run_yd'])
    max_resultant = float(model['max_resultant'])
    min_sectors = int(model['min_sectors'])
    distances = []
    angles = []
    sectors = set()
    for part_index, run in enumerate(runs, 1):
        refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                            in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
        if refused:
            return replace(base, status='unmeasured', explanation=f'part {part_index}: refused casts {refused}')
        ctrl = run.values.get(model['control'])
        if ctrl is None:
            return replace(base, status='unmeasured', explanation=missing_measurement(run, model['control']))
        if ctrl != 0:
            return replace(base, status='alert', measured=ctrl, expected=0.0,
                           explanation=f'part {part_index}: uncast control had {ctrl:g} copies (expected 0)')
        for cast_index, cast in enumerate(model['casts'], 1):
            for key in ('pre', 'start_count', 'end_count'):
                if run.values.get(cast[key]) is None:
                    return replace(base, status='unmeasured', explanation=missing_measurement(run, cast[key]))
            if run.values[cast['pre']] != 0:
                return replace(base, status='unmeasured',
                               explanation=f'part {part_index} cast {cast_index}: leftover {run.values[cast["pre"]]:g} '
                                           f'copies before cast')
            sc, ec = run.values[cast['start_count']], run.values[cast['end_count']]
            if sc != copies or ec != copies:
                return replace(base, status='alert', measured=min(sc, ec), expected=float(copies),
                               explanation=f'part {part_index} cast {cast_index}: copy count start={sc:g}, end={ec:g} '
                                           f'against expected {copies}')
            for copy_idx in range(copies):
                coords = []
                for moment in ('start', 'end'):
                    for axis in ('x', 'y'):
                        label_name = cast[moment][copy_idx][axis]
                        val = run.values.get(label_name)
                        if val is None or not math.isfinite(val):
                            return replace(base, status='unmeasured',
                                           explanation=f'part {part_index} cast {cast_index} copy {copy_idx}: '
                                                       f'missing/non-finite {label_name}')
                        coords.append(float(val))
                x0, y0, x1, y1 = coords
                dx, dy = x1 - x0, y1 - y0
                dist = math.hypot(dx, dy)
                distances.append(dist)
                if dist < min_run_yd:
                    return replace(base, status='alert', measured=dist, expected=min_run_yd,
                                   detail={'metric': X_METRIC, 'min_distance_yd': dist, 'observed': len(distances)},
                                   explanation=f'part {part_index} cast {cast_index} copy {copy_idx}: moved only '
                                               f'{dist:.2f} yd (< {min_run_yd:g} yd)')
                angle = math.atan2(dy, dx) % (2.0 * math.pi)
                angles.append(angle)
                sectors.add(int(angle / (2.0 * math.pi) * SECTORS) % SECTORS)
    total = len(angles)
    resultant = math.hypot(sum(math.cos(a) for a in angles), sum(math.sin(a) for a in angles)) / total
    occupied = len(sectors)
    min_dist = min(distances)
    max_dist = max(distances)
    detail = {'metric': X_METRIC, 'observed': total, 'min_distance_yd': round(min_dist, 3),
              'max_distance_yd': round(max_dist, 3), 'resultant': round(resultant, 4),
              'occupied_sectors': occupied, 'sectors': sorted(sectors), 'parts': len(runs)}
    if resultant > max_resultant:
        return replace(base, status='alert', measured=resultant, expected=max_resultant, low=0.0, high=max_resultant,
                       detail=detail,
                       explanation=f'{total} copies ran {min_dist:.2f}..{max_dist:.2f} yd, but mean resultant '
                                   f'R={resultant:.4f} > {max_resultant:g} (directional bias / fixed direction); '
                                   f'sectors {occupied}/{SECTORS}')
    if occupied < min_sectors:
        return replace(base, status='alert', measured=float(occupied), expected=float(min_sectors),
                       low=float(min_sectors), high=float(SECTORS), detail=detail,
                       explanation=f'{total} copies ran {min_dist:.2f}..{max_dist:.2f} yd (R={resultant:.4f}), '
                                   f'but occupied only {occupied}/{SECTORS} sectors (< {min_sectors}, fixed fan or '
                                   f'discrete directions)')
    return replace(base, status='ok', measured=resultant, expected=0.0, low=0.0, high=max_resultant, detail=detail,
                   explanation=f'control 0; {total} copies ran {min_dist:.2f}..{max_dist:.2f} yd '
                               f'(>= {min_run_yd:g} yd), R={resultant:.4f} <= {max_resultant:g}, '
                               f'{occupied}/{SECTORS} sectors (>= {min_sectors})')


def summon_random_direction_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return summon_random_direction_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_random_direction_scenario(class_file, summon_random_direction_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_random_direction_single_verdict}
POOLED_JUDGE = summon_random_direction_verdict
