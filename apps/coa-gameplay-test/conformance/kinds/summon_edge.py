import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, ENEMY_PLAYER_SETTLE_MS, TAKEN_HIT_PVP_LOCATION, behaviour_entry,
                        prose_rule, required_aura_steps, waited_ms)
from hits import base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'summon_edge'
ORDER = 49

ROLES = ('ally', 'enemy')
SIDES = ('inside', 'beyond')
EVENT_METRICS = ('spell_energize_count',)
STATE_METRICS = ('aura',)
MINIMUM_MARGIN_YD = 0.25
MAXIMUM_OFFSET_YD = 2.0
CELL_SIZE_YD = 533.3333 / 8
CENTER_CELL = 256
CELL_EDGE_GUARD_YD = 0.05
ENEMY_RACE_DEFAULT = 2
POWER_MANA = 0


@dataclass(frozen=True)
class SummonEdgeSpec:
    spell: int
    name: str
    quote: str
    summon_spell: int
    summon_entry: int
    radius: float
    role: str
    metric: str
    fields: tuple[tuple[str, object], ...]
    inside_yd: float
    beyond_yd: float
    wait_ms: int
    settle_ms: int = 1000
    bearing: float = 0.0
    learn: tuple[int, ...] = ()
    enemy_player_race: int = ENEMY_RACE_DEFAULT
    witness: bool = False
    label_suffix: str = 'summon_edge'


def summon_edge_spec(entry: dict) -> SummonEdgeSpec:
    spec = SummonEdgeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['summon_spell']),
                          int(entry['summon_entry']), float(entry['radius']), entry['role'], entry['metric'],
                          tuple(sorted(dict(entry.get('fields', {})).items())), float(entry['inside_yd']),
                          float(entry['beyond_yd']), int(entry['wait_ms']), int(entry.get('settle_ms', 1000)),
                          float(entry.get('bearing', 0.0)), tuple(int(spell) for spell in entry.get('learn', ())),
                          int(entry.get('enemy_player_race', ENEMY_RACE_DEFAULT)), bool(entry.get('witness', False)),
                          entry.get('label_suffix', 'summon_edge'))
    validate(spec)
    return spec


def validate(spec: SummonEdgeSpec) -> None:
    if spec.role not in ROLES:
        raise ValueError(f'{spec.spell} summon_edge role is one of {ROLES}, not {spec.role!r}')
    if spec.metric not in EVENT_METRICS + STATE_METRICS or 'spell' not in dict(spec.fields):
        raise ValueError(f'{spec.spell} summon_edge reads {EVENT_METRICS + STATE_METRICS} of a spell')
    if not -MAXIMUM_OFFSET_YD <= spec.inside_yd <= -MINIMUM_MARGIN_YD < MINIMUM_MARGIN_YD <= spec.beyond_yd \
            <= MAXIMUM_OFFSET_YD:
        raise ValueError(f'{spec.spell} summon_edge places the inside unit {MINIMUM_MARGIN_YD:g} to '
                         f'{MAXIMUM_OFFSET_YD:g} yd inside the edge and the beyond unit as far beyond it')
    if not 0 < spec.radius <= 100 or spec.wait_ms <= 0 or spec.settle_ms < 0:
        raise ValueError(f'{spec.spell} summon_edge needs a radius in (0, 100] yd and positive waits')
    if spec.witness and spec.metric not in EVENT_METRICS:
        raise ValueError(f'{spec.spell} summon_edge reads a caster witness only for an event metric')


def unit_id(side: str) -> str:
    return f'{side}_unit'


def read_label(spec: SummonEdgeSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def observe_step(spec: SummonEdgeSpec, label: str, unit: str) -> dict:
    fields = dict(spec.fields)
    if spec.metric in EVENT_METRICS:
        return measurement(label, CASTER, spec.metric, **fields, target=unit)
    return measurement(label, unit, spec.metric, **fields)


def geometry_steps(spec: SummonEdgeSpec, moment: str) -> list[dict]:
    steps = [measurement(read_label(spec, f'{moment} centre {axis}'), CASTER, f'owned_creature_position_{axis}',
                         entry=spec.summon_entry) for axis in 'xyz']
    steps.append(measurement(read_label(spec, f'{moment} centre reach'), CASTER, 'owned_creature_combat_reach',
                             entry=spec.summon_entry))
    for side in SIDES:
        unit = unit_id(side)
        steps += [measurement(read_label(spec, f'{moment} {side} {axis}'), unit, f'position_{axis}')
                  for axis in 'xyz']
        steps.append(measurement(read_label(spec, f'{moment} {side} reach'), unit, 'combat_reach'))
    return steps


def window_steps(spec: SummonEdgeSpec, moment: str) -> list[dict]:
    steps = [observe_step(spec, read_label(spec, f'{moment} {side}'), unit_id(side)) for side in SIDES]
    if spec.witness:
        steps.append(observe_step(spec, read_label(spec, f'{moment} witness'), CASTER))
    return steps


def summon_cast_steps(class_file: dict, records: Records, spec: SummonEdgeSpec) -> list[dict]:
    facts = facts_of(records, spec.summon_spell)
    steps = base_mana_steps(class_file, facts)
    if not steps and facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
        steps = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
    steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.summon_spell}]
    steps += [{**step, 'actor': CASTER} for step in required_aura_steps(facts)]
    steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.summon_spell, 'target': CASTER})
    return steps


def summon_edge_scenario(class_file: dict, spec: SummonEdgeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.radius)
    units = [{**player_fixture(class_file), 'id': unit_id(side),
              **({'race': spec.enemy_player_race} if spec.role == 'enemy' else {})} for side in SIDES]
    steps = base_steps(class_file)
    if spec.role == 'ally':
        steps += [{'action': 'group', 'actor': CASTER, 'target': unit_id(side)} for side in SIDES]
    else:
        steps += [{'action': 'pvp', 'actor': actor, 'enabled': True} for actor in (CASTER, *map(unit_id, SIDES))]
        steps.append({'action': 'wait', 'label': 'pvp settle', 'ms': ENEMY_PLAYER_SETTLE_MS})
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell}
              for spell in dict.fromkeys((*spec.learn, spec.summon_spell))]
    steps += summon_cast_steps(class_file, records, spec)
    steps.append({'action': 'wait', 'label': f'{KIND} settle', 'ms': spec.settle_ms})
    for side, offset in zip(SIDES, (spec.inside_yd, spec.beyond_yd)):
        steps.append({'action': 'relocate', 'actor': unit_id(side), 'around_owner': CASTER,
                      'around_entry': spec.summon_entry, 'radius': spec.radius, 'edge_offset': offset,
                      'bearing': spec.bearing})
    if spec.metric in EVENT_METRICS:
        steps += [{'action': 'set_power', 'actor': unit_id(side), 'power': POWER_MANA, 'value': 1} for side in SIDES]
    steps += geometry_steps(spec, 'start')
    steps += window_steps(spec, 'start')
    steps.append({'action': 'wait', 'label': f'{KIND} window', 'ms': spec.wait_ms})
    steps += window_steps(spec, 'end')
    steps += geometry_steps(spec, 'end')
    role_text = ('two ally players grouped with the caster' if spec.role == 'ally'
                 else f'two enemy players of race {spec.enemy_player_race}, all three PvP flagged')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon edge',
        'contract': (f'{spec.summon_spell} summons creature {spec.summon_entry}; {role_text} are then placed on one '
                     f'line from it at the edge of its {spec.radius:g} yd search (radius plus both combat reaches): '
                     f'one {abs(spec.inside_yd):g} yd inside the edge, one {spec.beyond_yd:g} yd beyond it, at the '
                     f'creature\'s height. {spec.metric} {dict(spec.fields)} is read on both over {spec.wait_ms} ms, '
                     f'with the creature\'s and the units\' positions and combat reaches read at the start and the '
                     f'end of the window: the inside unit is reached and the beyond unit is not.'),
        'players': [player_fixture(class_file)] + units,
        'steps': steps}
    if spec.role == 'enemy':
        scenario['location'] = dict(TAKEN_HIT_PVP_LOCATION)
    model = {'kind': KIND, 'metric': spec.metric, 'quote': entry.quote, 'radius': spec.radius,
             'event': spec.metric in EVENT_METRICS, 'witness': spec.witness,
             'reads': {moment: {read: read_label(spec, f'{moment} {read}')
                                for read in (*SIDES, *(('witness',) if spec.witness else ()))}
                       for moment in ('start', 'end')},
             'geometry': {moment: {unit: {read: read_label(spec, f'{moment} {unit} {read}')
                                          for read in ('x', 'y', 'z', 'reach')}
                                   for unit in ('centre', *SIDES)}
                          for moment in ('start', 'end')}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.summon_spell, None, f'{spec.radius:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def cell(value: float) -> int:
    return max(0, int(CENTER_CELL - value / CELL_SIZE_YD))


def near_cell_edge(value: float) -> bool:
    offset = (CENTER_CELL - value / CELL_SIZE_YD) % 1.0
    return min(offset, 1.0 - offset) * CELL_SIZE_YD < CELL_EDGE_GUARD_YD


def visited(centre: float, radius: float, value: float) -> bool:
    return cell(centre + radius) <= cell(value) <= cell(centre - radius) and not any(
        near_cell_edge(point) for point in (centre + radius, centre - radius, value))


def layout_fault(model: dict, values: dict) -> str | None:
    radius = float(model['radius'])
    for moment, units in values.items():
        centre = units['centre']
        for side in SIDES:
            unit = units[side]
            span = math.dist((centre['x'], centre['y'], centre['z']), (unit['x'], unit['y'], unit['z']))
            margin = span - radius - centre['reach'] - unit['reach']
            if (margin > -MINIMUM_MARGIN_YD) if side == 'inside' else (margin < MINIMUM_MARGIN_YD):
                return (f'the {side} unit stood {margin:+.2f} yd from the edge at the {moment} read '
                        f'({span:.2f} yd from the creature, reaches {centre["reach"]:.3f} and {unit["reach"]:.3f})')
            if not all(visited(centre[axis], radius, unit[axis]) for axis in 'xy'):
                return (f'the {side} unit stood in a grid cell the {radius:g} yd search does not visit, or on a cell '
                        f'edge, at the {moment} read')
    return None


def summon_edge_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for moment in model['reads'].values() for label in moment.values()]
    labels += [label for moment in model['geometry'].values() for unit in moment.values() for label in unit.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    geometry = {moment: {unit: {read: float(run.values[label]) for read, label in reads.items()}
                         for unit, reads in units.items()} for moment, units in model['geometry'].items()}
    fault = layout_fault(model, geometry)
    if fault is not None:
        return replace(base, status='unmeasured', explanation=f'layout not held: {fault}')
    reads = {moment: {read: float(run.values[label]) for read, label in labels_.items()}
             for moment, labels_ in model['reads'].items()}
    radius = float(model['radius'])
    if model['event']:
        gained = {read: reads['end'][read] - reads['start'][read] for read in reads['end']}
        if model['witness'] and gained['witness'] < 1:
            return replace(base, status='unmeasured',
                           explanation=f'the creature reached nobody in the window (the caster witness read '
                                       f'{gained["witness"]:g}), so the edge was not tested')
        reached = {side: gained[side] for side in SIDES}
        status = 'ok' if reached['inside'] >= 1 and reached['beyond'] == 0 else 'alert'
        text = (f'{model["metric"]} in the window: {reached["inside"]:g} on the unit inside the {radius:g} yd edge, '
                f'{reached["beyond"]:g} on the unit beyond it' +
                (f', {gained["witness"]:g} on the caster' if model['witness'] else ''))
    else:
        reached = {side: reads['end'][side] for side in SIDES}
        status = 'ok' if reached['inside'] >= 1 and reached['beyond'] == 0 else 'alert'
        text = (f'{model["metric"]} at the end of the window: {reached["inside"]:g} on the unit inside the '
                f'{radius:g} yd edge, {reached["beyond"]:g} on the unit beyond it')
    return replace(base, status=status, measured=radius, expected=radius,
                   explanation=f'{text}; the inside unit must be reached and the beyond unit never')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_edge_scenario(class_file, summon_edge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', 'summon_edge')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_edge_verdict}
