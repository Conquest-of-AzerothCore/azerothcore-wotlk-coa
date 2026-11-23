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

ROLES = ('ally', 'enemy', 'owner')
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
    owner_side: str | None = None
    cell_search: bool = True


def summon_edge_spec(entry: dict) -> SummonEdgeSpec:
    spec = SummonEdgeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['summon_spell']),
                          int(entry['summon_entry']), float(entry['radius']), entry['role'], entry['metric'],
                          tuple(sorted(dict(entry.get('fields', {})).items())), float(entry['inside_yd']),
                          float(entry['beyond_yd']), int(entry['wait_ms']), int(entry.get('settle_ms', 1000)),
                          float(entry.get('bearing', 0.0)), tuple(int(spell) for spell in entry.get('learn', ())),
                          int(entry.get('enemy_player_race', ENEMY_RACE_DEFAULT)), bool(entry.get('witness', False)),
                          entry.get('label_suffix', 'summon_edge'), entry.get('owner_side'),
                          entry.get('cell_search', True))
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
    if spec.witness and (spec.metric not in EVENT_METRICS or spec.role == 'owner'):
        raise ValueError(f'{spec.spell} summon_edge reads a caster witness only for an event metric on other units')
    if (spec.role == 'owner') != (spec.owner_side in SIDES) or type(spec.cell_search) is not bool:
        raise ValueError(f'{spec.spell} summon_edge places the caster itself (role owner) on exactly one side of '
                         f'{SIDES}, named by owner_side, and cell_search is a boolean')


def placed_sides(spec: SummonEdgeSpec) -> tuple[str, ...]:
    return (spec.owner_side,) if spec.role == 'owner' else SIDES


def unit_id(spec: SummonEdgeSpec, side: str) -> str:
    return CASTER if spec.role == 'owner' else f'{side}_unit'


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
    for side in placed_sides(spec):
        unit = unit_id(spec, side)
        steps += [measurement(read_label(spec, f'{moment} {side} {axis}'), unit, f'position_{axis}')
                  for axis in 'xyz']
        steps.append(measurement(read_label(spec, f'{moment} {side} reach'), unit, 'combat_reach'))
    return steps


def window_steps(spec: SummonEdgeSpec, moment: str) -> list[dict]:
    steps = [observe_step(spec, read_label(spec, f'{moment} {side}'), unit_id(spec, side))
             for side in placed_sides(spec)]
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
    sides = placed_sides(spec)
    units = [] if spec.role == 'owner' else [
        {**player_fixture(class_file), 'id': unit_id(spec, side),
         **({'race': spec.enemy_player_race} if spec.role == 'enemy' else {})} for side in sides]
    steps = base_steps(class_file)
    if spec.role == 'ally':
        steps += [{'action': 'group', 'actor': CASTER, 'target': unit_id(spec, side)} for side in sides]
    elif spec.role == 'enemy':
        steps += [{'action': 'pvp', 'actor': actor, 'enabled': True}
                  for actor in (CASTER, *(unit_id(spec, side) for side in sides))]
        steps.append({'action': 'wait', 'label': 'pvp settle', 'ms': ENEMY_PLAYER_SETTLE_MS})
    steps += [{'action': 'learn', 'actor': CASTER, 'spell': spell}
              for spell in dict.fromkeys((*spec.learn, spec.summon_spell))]
    steps += summon_cast_steps(class_file, records, spec)
    steps.append({'action': 'wait', 'label': f'{KIND} settle', 'ms': spec.settle_ms})
    for side, offset in zip(SIDES, (spec.inside_yd, spec.beyond_yd)):
        if side not in sides:
            continue
        steps.append({'action': 'relocate', 'actor': unit_id(spec, side), 'around_owner': CASTER,
                      'around_entry': spec.summon_entry, 'radius': spec.radius, 'edge_offset': offset,
                      'bearing': spec.bearing})
    if spec.metric in EVENT_METRICS:
        steps += [{'action': 'set_power', 'actor': unit_id(spec, side), 'power': POWER_MANA, 'value': 1}
                  for side in sides]
    steps += geometry_steps(spec, 'start')
    steps += window_steps(spec, 'start')
    steps.append({'action': 'wait', 'label': f'{KIND} window', 'ms': spec.wait_ms})
    steps += window_steps(spec, 'end')
    steps += geometry_steps(spec, 'end')
    if spec.role == 'owner':
        offset = spec.inside_yd if spec.owner_side == 'inside' else spec.beyond_yd
        layout = (f'the caster itself is then placed {abs(offset):g} yd {spec.owner_side} the edge of its '
                  f'{spec.radius:g} yd reach (radius plus both combat reaches), at the height of the creature. '
                  f'{spec.metric} {dict(spec.fields)} is read on the caster')
    else:
        role_text = ('two ally players grouped with the caster' if spec.role == 'ally'
                     else f'two enemy players of race {spec.enemy_player_race}, all three PvP flagged')
        layout = (f'{role_text} are then placed on one line from it at the edge of its {spec.radius:g} yd search '
                  f'(radius plus both combat reaches): one {abs(spec.inside_yd):g} yd inside the edge, one '
                  f'{spec.beyond_yd:g} yd beyond it, at the height of the creature. {spec.metric} '
                  f'{dict(spec.fields)} is read on both')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon edge',
        'contract': (f'{spec.summon_spell} summons creature {spec.summon_entry}; {layout} over {spec.wait_ms} ms, '
                     f'with the positions and combat reaches of the creature and the placed units read at the start '
                     f'and the end of the window: a unit inside the edge is reached and a unit beyond it is not.'),
        'players': [player_fixture(class_file)] + units,
        'steps': steps}
    if spec.role == 'enemy':
        scenario['location'] = dict(TAKEN_HIT_PVP_LOCATION)
    model = {'kind': KIND, 'metric': spec.metric, 'quote': entry.quote, 'radius': spec.radius,
             'event': spec.metric in EVENT_METRICS, 'witness': spec.witness, 'sides': list(sides),
             'cell_search': spec.cell_search,
             'reads': {moment: {read: read_label(spec, f'{moment} {read}')
                                for read in (*sides, *(('witness',) if spec.witness else ()))}
                       for moment in ('start', 'end')},
             'geometry': {moment: {unit: {read: read_label(spec, f'{moment} {unit} {read}')
                                          for read in ('x', 'y', 'z', 'reach')}
                                   for unit in ('centre', *sides)}
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
        for side in model['sides']:
            unit = units[side]
            span = math.dist((centre['x'], centre['y'], centre['z']), (unit['x'], unit['y'], unit['z']))
            margin = span - radius - centre['reach'] - unit['reach']
            if (margin > -MINIMUM_MARGIN_YD) if side == 'inside' else (margin < MINIMUM_MARGIN_YD):
                return (f'the {side} unit stood {margin:+.2f} yd from the edge at the {moment} read '
                        f'({span:.2f} yd from the creature, reaches {centre["reach"]:.3f} and {unit["reach"]:.3f})')
            if model['cell_search'] and not all(visited(centre[axis], radius, unit[axis]) for axis in 'xy'):
                return (f'the {side} unit stood in a grid cell the {radius:g} yd search does not visit, or on a cell '
                        f'edge, at the {moment} read')
    return None


def described(reached: dict[str, float], radius: float) -> str:
    return ', '.join(f'{value:g} on the unit {side} the {radius:g} yd edge' for side, value in reached.items())


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
        reached = {side: gained[side] for side in model['sides']}
        text = f'{model["metric"]} in the window: ' + described(reached, radius) + (
            f', {gained["witness"]:g} on the caster' if model['witness'] else '')
    else:
        reached = {side: reads['end'][side] for side in model['sides']}
        text = f'{model["metric"]} at the end of the window: ' + described(reached, radius)
    status = 'ok' if all((value >= 1) if side == 'inside' else (value == 0) for side, value in reached.items()) \
        else 'alert'
    return replace(base, status=status, measured=radius, expected=radius,
                   explanation=f'{text}; a unit inside must be reached and a unit beyond never')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_edge_scenario(class_file, summon_edge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', 'summon_edge')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_edge_verdict}
