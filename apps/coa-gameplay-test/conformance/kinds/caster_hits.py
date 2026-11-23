from dataclasses import dataclass
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of, required_aura_steps

KIND = 'caster_hits'
ORDER = 11
METRIC = 'spell_damage_count'
SECOND_CASTER = 'caster2'
MAX_DUMMY_DISTANCE_YD = 10.0
POSITION_TOLERANCE_YD = 0.5
POSITION_WITHIN_MS = 2000
SELF = 'self'
CAST_TARGETS = frozenset({TARGET, SELF})


@dataclass(frozen=True)
class CasterHitsSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    hit_spell: int
    casters: int
    trials: int
    hits_per_cast: int
    dummy_distance: float
    trial_position: tuple[int, float, float, float, float]
    cast_power: int
    gap_ms: int
    settle_ms: int
    caster_auras: tuple[tuple[int, int], ...] = ()
    label_suffix: str = 'caster_hits'
    cast_target: str = TARGET


def caster_hits_spec(entry: dict) -> CasterHitsSpec:
    where = entry['trial_position']
    spec = CasterHitsSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                          int(entry['hit_spell']), int(entry['casters']), int(entry['trials']),
                          int(entry['hits_per_cast']), float(entry['dummy_distance']),
                          (int(where['map']), float(where['x']), float(where['y']), float(where['z']),
                           float(where.get('o', 0.0))),
                          int(entry['cast_power']), int(entry.get('gap_ms', 0)), int(entry['settle_ms']),
                          tuple((int(spell), int(stacks)) for spell, stacks in entry.get('caster_auras', ())),
                          entry.get('label_suffix', 'caster_hits'), entry.get('cast_target', TARGET))
    if spec.casters not in (1, 2):
        raise ValueError(f'{spec.spell} caster_hits casts from one or two casters, not {spec.casters}')
    if spec.trials < 2 or spec.hits_per_cast < 1:
        raise ValueError(f'{spec.spell} caster_hits needs at least two trials and one hit per cast')
    if not 0 < spec.dummy_distance <= MAX_DUMMY_DISTANCE_YD:
        raise ValueError(f'{spec.spell} caster_hits places the dummy {spec.dummy_distance:g} yd away, outside '
                         f'(0, {MAX_DUMMY_DISTANCE_YD:g}]')
    if spec.casters == 2 and not 0 < spec.gap_ms < spec.settle_ms:
        raise ValueError(f'{spec.spell} caster_hits casts the second caster a positive gap_ms after the first, '
                         f'inside settle_ms')
    if spec.cast_target not in CAST_TARGETS:
        raise ValueError(f'{spec.spell} caster_hits casts at {sorted(CAST_TARGETS)}, not {spec.cast_target!r}')
    if spec.cast_spell == spec.hit_spell:
        raise ValueError(f'{spec.spell} caster_hits counts a hit spell other than the cast spell')
    return spec


def actors(spec: CasterHitsSpec) -> list[str]:
    return [CASTER, SECOND_CASTER][:spec.casters]


def hits_label(spec: CasterHitsSpec, actor: str, trial: int, moment: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {actor} {spec.hit_spell} hits trial {trial} {moment}'


def expectation_label(spec: CasterHitsSpec, actor: str, trial: int) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {actor} #{trial}'


def location(spec: CasterHitsSpec) -> dict:
    map_id, x, y, z, orientation = spec.trial_position
    return {'map': map_id, 'x': x, 'y': y, 'z': z, 'o': orientation}


def relocate(spec: CasterHitsSpec, actor: str, trial: int) -> list[dict]:
    spot = location(spec)
    return [{'action': 'teleport', 'actor': actor, **spot}] + [
        {'action': 'assert', 'label': f'{spec.spell} {spec.label_suffix} SETUP position {actor} {trial} {axis}',
         'actor': actor, 'metric': f'position_{axis}', 'min': spot[axis] - POSITION_TOLERANCE_YD,
         'max': spot[axis] + POSITION_TOLERANCE_YD, 'within_ms': POSITION_WITHIN_MS} for axis in ('x', 'y')] + [
        measurement(f'{spec.spell} {spec.label_suffix} dummy position {actor} {trial} {axis}', TARGET,
                    f'position_{axis}') for axis in ('x', 'y') if actor == CASTER]


def reads(spec: CasterHitsSpec, trial: int, moment: str) -> list[dict]:
    return [measurement(hits_label(spec, actor, trial, moment), actor, METRIC, spell=spec.hit_spell, target=TARGET)
            for actor in actors(spec)]


def trial_steps(records: Records, spec: CasterHitsSpec, trial: int) -> list[dict]:
    facts = facts_of(records, spec.cast_spell)
    steps = [step for actor in actors(spec) for step in relocate(spec, actor, trial)]
    steps += [{'action': 'set_aura', 'actor': actor, 'spell': spell, 'stacks': stacks}
              for actor in actors(spec) for spell, stacks in spec.caster_auras]
    steps += reads(spec, trial, 'before')
    for actor in actors(spec):
        steps += [{'action': 'set_power', 'actor': actor, 'power': facts.power_type, 'value': spec.cast_power},
                  {'action': 'reset_cooldown', 'actor': actor, 'spell': spec.cast_spell}]
        steps += [{**step, 'actor': actor} for step in required_aura_steps(facts)]
    for index, actor in enumerate(actors(spec)):
        if index:
            steps.append({'action': 'wait', 'label': f'second caster gap {trial}', 'ms': spec.gap_ms})
        steps.append({'action': 'cast', 'actor': actor, 'spell': spec.cast_spell,
                      'target': actor if spec.cast_target == SELF else TARGET})
    steps.append({'action': 'wait', 'label': f'settle {trial}', 'ms': spec.settle_ms})
    return steps + reads(spec, trial, 'after')


def caster_hits_scenario(class_file: dict, spec: CasterHitsSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.hits_per_cast))
    players = [player_fixture(class_file)]
    if spec.casters == 2:
        players.append({**player_fixture(class_file), 'id': SECOND_CASTER})
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': actor, 'spell': spec.cast_spell}
                                      for actor in actors(spec)]
    for trial in range(1, spec.trials + 1):
        steps += trial_steps(records, spec, trial)
    steps += [{'action': 'set_aura', 'actor': actor, 'spell': spell, 'stacks': 0}
              for actor in actors(spec) for spell, _ in spec.caster_auras]
    who = ('one caster' if spec.casters == 1 else
           f'two casters of the class, the second {spec.gap_ms} ms after the first')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour caster hits',
        'contract': (f'{spec.trials} trials; each trial teleports {who} to {list(spec.trial_position)}, with the '
                     f'dummy {spec.dummy_distance:g} yd ahead, and casts {spec.cast_spell} at the '
                     f'{"caster itself" if spec.cast_target == SELF else "dummy"} with '
                     f'{spec.cast_power} power (caster auras {list(spec.caster_auras)}); every caster\'s own '
                     f'{spec.hit_spell} hits on the dummy ({METRIC}) are read before the casts and {spec.settle_ms} '
                     f'ms after them, and each trial must add exactly {spec.hits_per_cast} per caster. No hit before '
                     f'the first cast.'),
        'players': players,
        'creatures': [creature_fixture(class_file, spec.dummy_distance)],
        'steps': steps,
        'location': location(spec)}
    expectations = []
    for actor in actors(spec):
        for trial in range(1, spec.trials + 1):
            model = {'kind': 'metric_delta', 'before_label': hits_label(spec, actor, trial, 'before'),
                     'after_label': hits_label(spec, actor, trial, 'after'),
                     'before_expected': float((trial - 1) * spec.hits_per_cast),
                     'expected': float(trial * spec.hits_per_cast), 'metric': METRIC, 'quote': entry.quote}
            expectations.append(Expectation(expectation_label(spec, actor, trial), BEHAVIOUR_METRIC_DELTA,
                                            spec.spell, spec.hit_spell, None, str(trial * spec.hits_per_cast),
                                            prose_rule(entry.quote, spec.spell), model))
    return timed(scenario, waited_ms(steps)), expectations


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return caster_hits_scenario(class_file, caster_hits_spec(entry))


def label(entry: dict) -> list[str]:
    spec = caster_hits_spec(entry)
    return [expectation_label(spec, actor, trial) for actor in actors(spec) for trial in range(1, spec.trials + 1)]
