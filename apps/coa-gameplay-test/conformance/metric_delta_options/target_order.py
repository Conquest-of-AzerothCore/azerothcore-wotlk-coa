from dataclasses import replace
from math import dist

NAME = 'target_order'
ORDER = 41
FIELDS = {'spell', 'events', 'centre', 'casts'}
CENTRES = ('dummy', 'caster')
DISTANCE_RESOLUTION_YD = 0.01
EXPIRE_WAIT_LABEL = 'let the first effect fully expire'
RUN_DEFAULT_TIMEOUT_MS = 90000
PLAIN = {'critical': False, 'resisted': False, 'blocked': False}
READS = (('total', 'spell_damage_total', PLAIN), ('plain', 'spell_damage_count', PLAIN),
         ('struck', 'spell_damage_count', {}))


def positive(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != FIELDS or not all(positive(raw[key]) for key in
                                                                  ('spell', 'events', 'casts')) \
            or raw['centre'] not in CENTRES:
        raise ValueError(f'target_order is {{"spell": hit spell, "events": hits per target, "centre": one of '
                         f'{list(CENTRES)}, "casts": treatment casts}}, positive integers, not {raw!r}')
    return dict(raw)


def area_names(spec) -> list[str]:
    from metric_delta_options.area_dummies import area_dummy_id
    distances = dict(spec.options).get('area_dummies')
    return [area_dummy_id(index) for index in range(len(distances))]


def check(spec, order):
    if order is None:
        return
    distances = dict(spec.options).get('area_dummies')
    if not isinstance(distances, tuple) or len(distances) < 2:
        raise ValueError(f'{spec.spell} target_order needs a plain area_dummies list of at least 2 distances')
    if spec.target != 'dummy':
        raise ValueError(f'{spec.spell} target_order strikes the dummy and the area dummies, not {spec.target}')


def creatures(spec) -> list[str]:
    return ['dummy', *area_names(spec)]


def read_label(spec, cast: int, creature: str, read: str) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, "after")} order {cast} {creature} {read}'


def damage_reads(spec, spell: int, cast: int, targets: list[str]) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(read_label(spec, cast, creature, read), CASTER, metric, spell=spell, target=creature,
                        **filters)
            for creature in targets for read, metric, filters in READS]


def position_reads(spec, cast: int, units: list[str]) -> list[dict]:
    from profile import measurement
    return [measurement(read_label(spec, cast, unit, f'position {axis}'), unit, f'position_{axis}')
            for unit in units for axis in 'xyz']


def treatment_block(spec, steps: list[dict]) -> tuple[int, int, list[dict]]:
    from behaviours import metric_delta_label
    labels = [step.get('label') for step in steps]
    after = labels.index(metric_delta_label(spec, 'after'))
    waits = [index for index in range(after) if labels[index] == EXPIRE_WAIT_LABEL]
    if not waits:
        raise ValueError(f'{spec.spell} {NAME} repeats the treatment phase, so it needs expire_ms')
    end = after
    while end + 1 < len(steps) and str(labels[end + 1]).startswith(metric_delta_label(spec, 'after')):
        end += 1
    return waits[-1], end, steps[waits[-1]:after]


def cover_waits(scenario: dict):
    from hits import TIMEOUT_MARGIN_MS
    waited = sum(step['ms'] for step in scenario['steps'] if step.get('action') == 'wait')
    scenario['timeout_ms'] = max(scenario.get('timeout_ms', RUN_DEFAULT_TIMEOUT_MS), waited + TIMEOUT_MARGIN_MS)


def fixtures(class_file: dict, spec, order: dict, scenario: dict):
    from profile import CASTER
    steps = scenario['steps']
    start, end, block = treatment_block(spec, steps)
    targets = creatures(spec)
    read_units = units(targets, CASTER if order['centre'] == CASTER else 'dummy')
    added = damage_reads(spec, order['spell'], 1, targets) + position_reads(spec, 1, read_units)
    for cast in range(2, order['casts'] + 1):
        added += [dict(step) for step in block] + damage_reads(spec, order['spell'], cast, targets) \
                 + position_reads(spec, cast, read_units)
    scenario['steps'] = (steps[:start] + damage_reads(spec, order['spell'], 0, targets) + steps[start:end + 1]
                         + added + steps[end + 1:])
    cover_waits(scenario)
    scenario['contract'] += (f' The treatment phase is cast {order["casts"]} times; after each cast the damage of '
                             f'{order["spell"]} on each of {targets} is read without critical, resisted or blocked '
                             f'hits, with its hit count and every position; per cast the targets are ordered by their '
                             f'measured distance from the {order["centre"]} (a cast whose distances lie within '
                             f'{DISTANCE_RESOLUTION_YD:g} yd of each other is void), each must be struck '
                             f'{order["events"]} times, and the mean damage per distance rank, over the casts where '
                             f'that target took no critical, resisted or blocked hit, must fall strictly from the '
                             f'nearest to the farthest.')


def units(targets: list[str], centre: str) -> list[str]:
    return [*targets, *([centre] if centre not in targets else [])]


def model(spec, order: dict) -> dict:
    from profile import CASTER
    targets = creatures(spec)
    centre = order['centre'] if order['centre'] == CASTER else 'dummy'
    return {NAME: {**order, 'targets': targets, 'centre_unit': centre,
                   'base': {creature: {read: read_label(spec, 0, creature, read) for read, _, _ in READS}
                            for creature in targets},
                   'casts_reads': [{creature: {read: read_label(spec, cast, creature, read) for read, _, _ in READS}
                                    for creature in targets} for cast in range(1, order['casts'] + 1)],
                   'positions': [{unit: [read_label(spec, cast, unit, f'position {axis}') for axis in 'xyz']
                                  for unit in units(targets, centre)} for cast in range(1, order['casts'] + 1)]}}


def per_cast(values: dict, base: dict, reads: list[dict]) -> list[dict]:
    rows, previous = [], base
    for cast in reads:
        rows.append({creature: {read: values[label] - values[previous[creature][read]]
                                for read, label in labels.items()} for creature, labels in cast.items()})
        previous = cast
    return rows


def ranked_means(rows: list[list[tuple[str, float, float | None]]]) -> list[list[float]]:
    ranks: list[list[float]] = []
    for row in rows:
        for rank, (_, _, damage) in enumerate(row):
            while len(ranks) <= rank:
                ranks.append([])
            if damage is not None:
                ranks[rank].append(damage)
    return ranks


def verdict(verdict, run, order: dict):
    from compare import missing_measurement
    labels = [label for creature in order['base'].values() for label in creature.values()] + \
             [label for cast in order['casts_reads'] for creature in cast.values() for label in creature.values()] + \
             [label for cast in order['positions'] for triple in cast.values() for label in triple]
    values = run.values
    missing = next((label for label in labels if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    casts = per_cast(values, order['base'], order['casts_reads'])
    wrong = [(index + 1, creature, row[creature]['struck']) for index, row in enumerate(casts)
             for creature in order['targets'] if row[creature]['struck'] != order['events']]
    if wrong:
        return replace(verdict, status='alert', explanation=f'{order["spell"]} must strike each target '
                                                            f'{order["events"]} times per cast, read (cast, target, '
                                                            f'hits) {wrong}')
    ordered, void = [], []
    for index, (row, positions) in enumerate(zip(casts, order['positions'])):
        centre = [values[label] for label in positions[order['centre_unit']]]
        distances = sorted((dist(centre, [values[label] for label in positions[creature]]), creature)
                           for creature in order['targets'])
        if any(far - near <= DISTANCE_RESOLUTION_YD for (near, _), (far, _) in zip(distances, distances[1:])):
            void.append(index + 1)
            continue
        ordered.append([(creature, round(distance, 2), row[creature]['total']
                         if row[creature]['plain'] == order['events'] else None) for distance, creature in distances])
    if not ordered:
        return replace(verdict, status='unmeasured', explanation=f'every cast void: two measured distances from the '
                                                                 f'{order["centre"]} within '
                                                                 f'{DISTANCE_RESOLUTION_YD:g} yd (casts {void})')
    ranks = ranked_means(ordered)
    if any(not damages for damages in ranks):
        empty = [rank + 1 for rank, damages in enumerate(ranks) if not damages]
        return replace(verdict, status='unmeasured', explanation=f'distance ranks {empty} took a critical, '
                                                                 f'resisted or blocked hit in every measured cast')
    means = [sum(damages) / len(damages) for damages in ranks]
    falling = all(high > low for high, low in zip(means, means[1:]))
    lead = (f'mean plain damage of {order["spell"]} per distance rank from the {order["centre"]} '
            f'{[round(mean, 2) for mean in means]} over {[len(damages) for damages in ranks]} casts; first measured '
            f'cast (target, distance yd, damage) {ordered[0]}; void casts {void}; judged strictly falling: '
            f'{"falling" if falling else "not falling"}')
    if verdict.status != 'ok':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    return replace(verdict, status='ok' if falling else 'alert', explanation=f'{verdict.explanation}; {lead}')
