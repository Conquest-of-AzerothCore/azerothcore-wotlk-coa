from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import MAX_SCENARIO_MS, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'summon_ritual'
ORDER = 64
METRIC = 'summon_pending'
FIRST, SECOND, FARAWAY = 'first', 'second', 'faraway'
DEFAULT_LOCATION = {'map': 0, 'x': -9458.0, 'y': 42.0, 'z': 55.5}
DEFAULT_FARAWAY_LOCATION = {'map': 0, 'x': -9100.0, 'y': 400.0, 'z': 93.0}
DEFAULT_TELEPORT_WAIT_MS = 2000
DEFAULT_RITUAL_WAIT_MS = 1000
DEFAULT_STONE_WAIT_MS = 7000
DEFAULT_PORTAL_WAIT_MS = 1500
DEFAULT_SUMMON_WAIT_MS = 7000
MIN_WAIT_MS = 100
MIN_FARAWAY_DISTANCE_YD = 50.0
FIELDS = frozenset({'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'ritual_entry', 'stone_entry',
                    'portal_entry', 'location', 'faraway_location', 'teleport_wait_ms', 'ritual_wait_ms',
                    'stone_wait_ms', 'portal_wait_ms', 'summon_wait_ms', 'cast_power', 'observe_source'})


@dataclass(frozen=True)
class RitualLocation:
    map_id: int
    x: float
    y: float
    z: float

    def as_dict(self) -> dict:
        return {'map': self.map_id, 'x': self.x, 'y': self.y, 'z': self.z}


@dataclass(frozen=True)
class SummonRitualSpec:
    spell: int
    name: str
    quote: str
    ritual_entry: int
    stone_entry: int | None
    portal_entry: int | None
    location: RitualLocation
    faraway_location: RitualLocation
    teleport_wait_ms: int = DEFAULT_TELEPORT_WAIT_MS
    ritual_wait_ms: int = DEFAULT_RITUAL_WAIT_MS
    stone_wait_ms: int = DEFAULT_STONE_WAIT_MS
    portal_wait_ms: int = DEFAULT_PORTAL_WAIT_MS
    summon_wait_ms: int = DEFAULT_SUMMON_WAIT_MS
    cast_power: int | None = None
    label_suffix: str = KIND

    @property
    def direct(self) -> bool:
        return self.stone_entry is None and self.portal_entry is None


def positive_int(value, field_name: str, spell: int) -> int:
    if type(value) is not int or value < 1:
        raise ValueError(f'{spell} {KIND} {field_name} must be a positive int, not {value!r}')
    return value


def parse_location(raw: dict, field_name: str, spell: int) -> RitualLocation:
    if not isinstance(raw, dict) or set(raw) != {'map', 'x', 'y', 'z'}:
        raise ValueError(f'{spell} {KIND} {field_name} must have keys map, x, y, z, not {raw!r}')
    map_id = raw['map']
    if type(map_id) is not int or map_id < 0:
        raise ValueError(f'{spell} {KIND} {field_name}.map must be a non-negative int, not {map_id!r}')
    coords = []
    for axis in ('x', 'y', 'z'):
        value = raw[axis]
        if type(value) not in (int, float):
            raise ValueError(f'{spell} {KIND} {field_name}.{axis} must be a number, not {value!r}')
        coords.append(float(value))
    return RitualLocation(map_id, coords[0], coords[1], coords[2])


def summon_ritual_spec(entry: dict) -> SummonRitualSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields {sorted(unknown)}')
    spell = positive_int(entry['spell'], 'spell', int(entry['spell']) if isinstance(entry.get('spell'), int) else 0)
    ritual_entry = positive_int(entry['ritual_entry'], 'ritual_entry', spell)
    stone_raw = entry.get('stone_entry')
    portal_raw = entry.get('portal_entry')
    if (stone_raw is None) != (portal_raw is None):
        raise ValueError(f'{spell} {KIND} stone_entry and portal_entry must both be set or both omitted')
    if stone_raw is None:
        stone_entry = None
        portal_entry = None
    else:
        stone_entry = positive_int(stone_raw, 'stone_entry', spell)
        portal_entry = positive_int(portal_raw, 'portal_entry', spell)
        if len({ritual_entry, stone_entry, portal_entry}) != 3:
            raise ValueError(f'{spell} {KIND} ritual_entry, stone_entry and portal_entry must be distinct')
    location = parse_location(entry.get('location', DEFAULT_LOCATION), 'location', spell)
    faraway = parse_location(entry.get('faraway_location', DEFAULT_FARAWAY_LOCATION), 'faraway_location', spell)
    if location.map_id != faraway.map_id:
        raise ValueError(f'{spell} {KIND} location and faraway_location must share the same map')
    if math.hypot(faraway.x - location.x, faraway.y - location.y) < MIN_FARAWAY_DISTANCE_YD:
        raise ValueError(f'{spell} {KIND} faraway_location must be at least {MIN_FARAWAY_DISTANCE_YD:g} yd from '
                         f'location')
    waits = {}
    for field_name, default in (('teleport_wait_ms', DEFAULT_TELEPORT_WAIT_MS),
                                ('ritual_wait_ms', DEFAULT_RITUAL_WAIT_MS),
                                ('stone_wait_ms', DEFAULT_STONE_WAIT_MS),
                                ('portal_wait_ms', DEFAULT_PORTAL_WAIT_MS),
                                ('summon_wait_ms', DEFAULT_SUMMON_WAIT_MS)):
        value = entry.get(field_name, default)
        if type(value) is not int or value < MIN_WAIT_MS:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= {MIN_WAIT_MS}, not {value!r}')
        waits[field_name] = value
    cast_power = entry.get('cast_power')
    if cast_power is not None and (type(cast_power) is not int or cast_power < 0):
        raise ValueError(f'{spell} {KIND} cast_power must be a non-negative int, not {cast_power!r}')
    return SummonRitualSpec(spell, entry['name'], entry['quote'], ritual_entry, stone_entry, portal_entry,
                            location, faraway, waits['teleport_wait_ms'], waits['ritual_wait_ms'],
                            waits['stone_wait_ms'], waits['portal_wait_ms'], waits['summon_wait_ms'],
                            cast_power, entry.get('label_suffix', KIND))


def mark(spec: SummonRitualSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def direct_summon_scenario(class_file: dict, spec: SummonRitualSpec, entry, facts) -> tuple[dict, list[Expectation]]:
    reads = {
        'pre_ritual': mark(spec, 'pre ritual'),
        'pre_summon': mark(spec, 'pre summon'),
        'cast_failure': mark(spec, 'cast failure'),
        'ritual_created': mark(spec, 'ritual created'),
        'summon_before_click': mark(spec, 'summon before click'),
        'summon_final': mark(spec, 'summon final'),
    }
    power_steps = ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}]
                   if spec.cast_power is not None else [])
    steps = (base_steps(class_file)
             + [{'action': 'group', 'actor': CASTER, 'target': ally} for ally in (FIRST, FARAWAY)]
             + [{'action': 'teleport', 'actor': FARAWAY, **spec.faraway_location.as_dict()},
                {'action': 'wait', 'label': f'{KIND} teleport settle', 'ms': spec.teleport_wait_ms},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                measurement(reads['pre_ritual'], CASTER, 'owned_gameobject_count', entry=spec.ritual_entry),
                measurement(reads['pre_summon'], FARAWAY, METRIC),
                {'action': 'select', 'actor': CASTER, 'target': FARAWAY}]
             + power_steps
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
                measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell),
                {'action': 'wait', 'label': f'{KIND} ritual spawn', 'ms': spec.ritual_wait_ms},
                measurement(reads['ritual_created'], CASTER, 'owned_gameobject_count', entry=spec.ritual_entry),
                measurement(reads['summon_before_click'], FARAWAY, METRIC),
                {'action': 'use_nearby_gameobject', 'actor': FIRST, 'entry': spec.ritual_entry, 'owner': CASTER},
                {'action': 'wait', 'label': f'{KIND} summon complete', 'ms': spec.summon_wait_ms},
                measurement(reads['summon_final'], FARAWAY, METRIC)])
    players = [player_fixture(class_file), *({**player_fixture(class_file), 'id': ally}
                                             for ally in (FIRST, FARAWAY))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon ritual',
        'contract': (f'Three grouped party members ({CASTER}, {FIRST}, {FARAWAY}) with {FARAWAY} teleported '
                     f'to {spec.faraway_location.as_dict()}. Control reads before casting {spec.spell} verify 0 '
                     f'ritual ({spec.ritual_entry}) objects and {METRIC} == 0 on {FARAWAY}. {CASTER} selects '
                     f'{FARAWAY} and casts {spec.spell} to place ritual {spec.ritual_entry} ({METRIC} stays 0 on '
                     f'{FARAWAY}); {FIRST} clicks ritual {spec.ritual_entry} and {FARAWAY} must read {METRIC} == 1.'),
        'players': players,
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'spell': spec.spell,
             'ritual_entry': spec.ritual_entry, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def summon_ritual_scenario(class_file: dict, spec: SummonRitualSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    facts = facts_of(records, spec.spell)
    if spec.direct:
        return direct_summon_scenario(class_file, spec, entry, facts)
    reads = {
        'pre_ritual': mark(spec, 'pre ritual'),
        'pre_stone': mark(spec, 'pre stone'),
        'pre_portal': mark(spec, 'pre portal'),
        'pre_summon': mark(spec, 'pre summon'),
        'cast_failure': mark(spec, 'cast failure'),
        'ritual_created': mark(spec, 'ritual created'),
        'stone_created': mark(spec, 'stone created'),
        'summon_after_stone': mark(spec, 'summon after stone'),
        'portal_created': mark(spec, 'portal created'),
        'summon_after_portal': mark(spec, 'summon after portal'),
        'summon_final': mark(spec, 'summon final'),
    }
    power_steps = ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}]
                   if spec.cast_power is not None else [])
    steps = (base_steps(class_file)
             + [{'action': 'group', 'actor': CASTER, 'target': ally} for ally in (FIRST, SECOND, FARAWAY)]
             + [{'action': 'teleport', 'actor': FARAWAY, **spec.faraway_location.as_dict()},
                {'action': 'wait', 'label': f'{KIND} teleport settle', 'ms': spec.teleport_wait_ms},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                measurement(reads['pre_ritual'], CASTER, 'owned_gameobject_count', entry=spec.ritual_entry),
                measurement(reads['pre_stone'], CASTER, 'owned_gameobject_count', entry=spec.stone_entry),
                measurement(reads['pre_portal'], FIRST, 'owned_gameobject_count', entry=spec.portal_entry),
                measurement(reads['pre_summon'], FARAWAY, METRIC)]
             + power_steps
             + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell},
                measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell),
                {'action': 'wait', 'label': f'{KIND} ritual spawn', 'ms': spec.ritual_wait_ms},
                measurement(reads['ritual_created'], CASTER, 'owned_gameobject_count', entry=spec.ritual_entry),
                {'action': 'use_nearby_gameobject', 'actor': FIRST, 'entry': spec.ritual_entry, 'owner': CASTER},
                {'action': 'use_nearby_gameobject', 'actor': SECOND, 'entry': spec.ritual_entry, 'owner': CASTER},
                {'action': 'wait', 'label': f'{KIND} stone carve', 'ms': spec.stone_wait_ms},
                measurement(reads['stone_created'], CASTER, 'owned_gameobject_count', entry=spec.stone_entry),
                measurement(reads['summon_after_stone'], FARAWAY, METRIC),
                {'action': 'select', 'actor': FIRST, 'target': FARAWAY},
                {'action': 'use_nearby_gameobject', 'actor': FIRST, 'entry': spec.stone_entry, 'owner': CASTER},
                {'action': 'wait', 'label': f'{KIND} portal open', 'ms': spec.portal_wait_ms},
                measurement(reads['portal_created'], FIRST, 'owned_gameobject_count', entry=spec.portal_entry),
                measurement(reads['summon_after_portal'], FARAWAY, METRIC),
                {'action': 'use_nearby_gameobject', 'actor': SECOND, 'entry': spec.portal_entry, 'owner': FIRST},
                {'action': 'wait', 'label': f'{KIND} summon complete', 'ms': spec.summon_wait_ms},
                measurement(reads['summon_final'], FARAWAY, METRIC)])
    players = [player_fixture(class_file), *({**player_fixture(class_file), 'id': ally}
                                             for ally in (FIRST, SECOND, FARAWAY))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon ritual',
        'location': spec.location.as_dict(),
        'contract': (f'Four grouped party members ({CASTER}, {FIRST}, {SECOND}, {FARAWAY}) with {FARAWAY} teleported '
                     f'to {spec.faraway_location.as_dict()}. Control reads before casting {spec.spell} verify 0 '
                     f'ritual ({spec.ritual_entry}), stone ({spec.stone_entry}), portal ({spec.portal_entry}) objects '
                     f'and {METRIC} == 0 on {FARAWAY}. {CASTER} casts {spec.spell} to place ritual '
                     f'{spec.ritual_entry}; {FIRST} and {SECOND} click it to carve stone {spec.stone_entry} '
                     f'({METRIC} stays 0 on {FARAWAY}); {FIRST} selects {FARAWAY} and clicks stone '
                     f'{spec.stone_entry} to open portal {spec.portal_entry} ({METRIC} stays 0 on {FARAWAY}); '
                     f'{SECOND} clicks portal {spec.portal_entry} and {FARAWAY} must read {METRIC} == 1.'),
        'players': players,
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'spell': spec.spell,
             'ritual_entry': spec.ritual_entry, 'stone_entry': spec.stone_entry, 'portal_entry': spec.portal_entry,
             'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def direct_summon_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    val = run.values

    def require_present(*keys: str) -> str | None:
        return next((reads[key] for key in keys if val.get(reads[key]) is None), None)

    missing = require_present('pre_ritual', 'pre_summon', 'cast_failure', 'ritual_created')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    pre = {key: val[reads[key]] for key in ('pre_ritual', 'pre_summon')}
    if any(value != 0 for value in pre.values()):
        return replace(base, status='unmeasured', detail={'metric': METRIC, 'pre': pre},
                       explanation=f'pre-cast baseline not clean: {pre}')
    cast_failure = val[reads['cast_failure']]
    if cast_failure != 0:
        return replace(base, status='alert', measured=0.0, expected=1.0,
                       detail={'metric': METRIC, 'cast_failure': cast_failure},
                       explanation=f'ritual cast {model["spell"]} failed with cast_failure={cast_failure:g}')
    ritual = val[reads['ritual_created']]
    if ritual != 1:
        return replace(base, status='alert', measured=ritual, expected=1.0,
                       detail={'metric': METRIC, 'ritual_created': ritual},
                       explanation=f'{model["spell"]} created {ritual:g} ritual object(s) of entry '
                                   f'{model["ritual_entry"]}, expected 1')
    missing = require_present('summon_before_click')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    before_click = val[reads['summon_before_click']]
    if before_click != 0:
        return replace(base, status='alert', measured=before_click, expected=0.0,
                       detail={'metric': METRIC, 'summon_before_click': before_click},
                       explanation=f'{FARAWAY} read {METRIC}={before_click:g} before {FIRST} clicked ritual '
                                   f'{model["ritual_entry"]}')
    missing = require_present('summon_final')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    final = val[reads['summon_final']]
    detail = {'metric': METRIC, 'ritual_created': ritual, 'summon_before': pre['pre_summon'],
              'summon_before_click': before_click, 'summon_final': final}
    if final != 1:
        return replace(base, status='alert', measured=final, expected=1.0, detail=detail,
                       explanation=f'completing ritual {model["ritual_entry"]} left {FARAWAY} with '
                                   f'{METRIC}={final:g}, expected 1')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'ritual {model["ritual_entry"]} (0->1) -> {FARAWAY} {METRIC}: 0 -> 0 -> 1')


def summon_ritual_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model.get('stone_entry') is None:
        return direct_summon_verdict(base, run, model)
    reads = model['reads']
    val = run.values

    def require_present(*keys: str) -> str | None:
        return next((reads[key] for key in keys if val.get(reads[key]) is None), None)

    missing = require_present('pre_ritual', 'pre_stone', 'pre_portal', 'pre_summon', 'cast_failure', 'ritual_created')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    pre = {key: val[reads[key]] for key in ('pre_ritual', 'pre_stone', 'pre_portal', 'pre_summon')}
    if any(value != 0 for value in pre.values()):
        return replace(base, status='unmeasured', detail={'metric': METRIC, 'pre': pre},
                       explanation=f'pre-cast baseline not clean: {pre}')
    cast_failure = val[reads['cast_failure']]
    if cast_failure != 0:
        return replace(base, status='alert', measured=0.0, expected=1.0,
                       detail={'metric': METRIC, 'cast_failure': cast_failure},
                       explanation=f'ritual cast {model["spell"]} failed with cast_failure={cast_failure:g}')
    ritual = val[reads['ritual_created']]
    if ritual != 1:
        return replace(base, status='alert', measured=ritual, expected=1.0,
                       detail={'metric': METRIC, 'ritual_created': ritual},
                       explanation=f'{model["spell"]} created {ritual:g} ritual object(s) of entry '
                                   f'{model["ritual_entry"]}, expected 1')
    missing = require_present('stone_created', 'summon_after_stone')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    stone, after_stone = val[reads['stone_created']], val[reads['summon_after_stone']]
    if stone != 1:
        return replace(base, status='alert', measured=stone, expected=1.0,
                       detail={'metric': METRIC, 'ritual_created': ritual, 'stone_created': stone},
                       explanation=f'completing ritual {model["ritual_entry"]} created {stone:g} stone object(s) of '
                                   f'entry {model["stone_entry"]}, expected 1')
    if after_stone != 0:
        return replace(base, status='alert', measured=after_stone, expected=0.0,
                       detail={'metric': METRIC, 'summon_after_stone': after_stone},
                       explanation=f'{FARAWAY} read {METRIC}={after_stone:g} right after stone creation, before '
                                   f'portal completion')
    missing = require_present('portal_created', 'summon_after_portal')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    portal, after_portal = val[reads['portal_created']], val[reads['summon_after_portal']]
    if portal != 1:
        return replace(base, status='alert', measured=portal, expected=1.0,
                       detail={'metric': METRIC, 'stone_created': stone, 'portal_created': portal},
                       explanation=f'using stone {model["stone_entry"]} created {portal:g} portal object(s) of entry '
                                   f'{model["portal_entry"]}, expected 1')
    if after_portal != 0:
        return replace(base, status='alert', measured=after_portal, expected=0.0,
                       detail={'metric': METRIC, 'summon_after_portal': after_portal},
                       explanation=f'{FARAWAY} read {METRIC}={after_portal:g} before {SECOND} clicked portal '
                                   f'{model["portal_entry"]}')
    missing = require_present('summon_final')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    final = val[reads['summon_final']]
    detail = {'metric': METRIC, 'ritual_created': ritual, 'stone_created': stone, 'portal_created': portal,
              'summon_before': pre['pre_summon'], 'summon_after_stone': after_stone,
              'summon_after_portal': after_portal, 'summon_final': final}
    if final != 1:
        return replace(base, status='alert', measured=final, expected=1.0, detail=detail,
                       explanation=f'completing portal {model["portal_entry"]} left {FARAWAY} with '
                                   f'{METRIC}={final:g}, expected 1')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'ritual {model["ritual_entry"]} (0->1) -> stone {model["stone_entry"]} (0->1) -> '
                               f'portal {model["portal_entry"]} (0->1) -> {FARAWAY} {METRIC}: 0 -> 0 -> 0 -> 1')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_ritual_scenario(class_file, summon_ritual_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: summon_ritual_verdict}
