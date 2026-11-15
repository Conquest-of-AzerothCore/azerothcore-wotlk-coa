from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'cooldown_clear_time'
ORDER = 32

READS = ('result', 'time', 'events')


@dataclass(frozen=True)
class CooldownClearSpec:
    spell: int
    name: str
    quote: str
    raise_spell: int
    minion_entry: int
    observe_spell: int
    observe_power: int
    cooldown_ms: int
    expected_cut_ms: float
    first_attempt_ms: int
    last_attempt_ms: int
    attempt_step_ms: int
    settle_ms: int = 3000
    label_suffix: str = 'clear_time'


def cooldown_clear_spec(entry: dict) -> CooldownClearSpec:
    spec = CooldownClearSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['raise_spell']),
                             int(entry['minion_entry']), int(entry['observe_spell']), int(entry['observe_power']),
                             int(entry['cooldown_ms']), float(entry['expected_cut_ms']),
                             int(entry['first_attempt_ms']), int(entry['last_attempt_ms']),
                             int(entry['attempt_step_ms']), int(entry.get('settle_ms', 3000)),
                             entry.get('label_suffix', 'clear_time'))
    if not 0 < spec.first_attempt_ms < spec.last_attempt_ms < spec.cooldown_ms or spec.attempt_step_ms < 250:
        raise ValueError(f'{spec.spell} cooldown_clear_time attempts inside the cooldown, every 250 ms or more')
    if (spec.last_attempt_ms - spec.first_attempt_ms) // spec.attempt_step_ms > 200:
        raise ValueError(f'{spec.spell} cooldown_clear_time makes at most 200 attempts')
    return spec


def clear_label(spec: CooldownClearSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def cooldown_clear_scenario(class_file: dict, spec: CooldownClearSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_cut_ms)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in (spec.raise_spell, spec.observe_spell)])
    steps += hit_ratio_cast(records, spec.raise_spell, CASTER, CASTER)
    steps += [{'action': 'wait', 'label': 'raise settle', 'ms': spec.settle_ms},
              {'action': 'assert', 'label': f'SETUP: the {spec.minion_entry} minion is raised', 'actor': CASTER,
               'metric': 'owned_creature_count', 'entry': spec.minion_entry, 'equals': 1},
              {'action': 'attack', 'actor': CASTER, 'target': TARGET}]
    steps += hit_ratio_cast(records, spec.observe_spell, CASTER, CASTER, spec.observe_power)[:-1]
    steps += [measurement(clear_label(spec, 'primed result'), CASTER, 'cast_failure', spell=spec.observe_spell),
              {'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
              measurement(clear_label(spec, 'learned time'), CASTER, 'game_time_ms'),
              measurement(clear_label(spec, 'learned events'), CASTER, 'owned_creature_damage_count',
                          entry=spec.minion_entry),
              {'action': 'wait', 'label': 'cut window', 'ms': spec.first_attempt_ms}]
    attempts = []
    for moment in range(spec.first_attempt_ms, spec.last_attempt_ms + 1, spec.attempt_step_ms):
        labels = [clear_label(spec, f'attempt {moment} {read}') for read in READS]
        steps += [{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.observe_power},
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.observe_spell, 'target': CASTER},
                  measurement(labels[0], CASTER, 'cast_failure', spell=spec.observe_spell),
                  measurement(labels[1], CASTER, 'game_time_ms'),
                  measurement(labels[2], CASTER, 'owned_creature_damage_count', entry=spec.minion_entry),
                  {'action': 'wait', 'label': 'attempt spacing', 'ms': spec.attempt_step_ms}]
        attempts.append(labels)
    steps.append({'action': 'stop_attack', 'actor': CASTER})
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cooldown clear time',
        'contract': (f'Creature {spec.minion_entry} (raised by {spec.raise_spell}) attacks the dummy with the caster. '
                     f'{spec.observe_spell} ({spec.cooldown_ms} ms cooldown) is cast, then {spec.spell} is learned. '
                     f'From {spec.first_attempt_ms} to {spec.last_attempt_ms} ms after the learn it is attempted '
                     f'every {spec.attempt_step_ms} ms, with the game time and the creature\'s damage events. The '
                     f'last refusal and the first cast bracket the cut per event, (cooldown - elapsed) / events, '
                     f'which must lie inside the G-19 band of {spec.expected_cut_ms:g} ms.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'cast_failure', 'quote': entry.quote, 'attempts': attempts,
             'primed': clear_label(spec, 'primed result'), 'start': [clear_label(spec, f'learned {read}')
                                                                    for read in ('time', 'events')],
             'cooldown_ms': spec.cooldown_ms, 'expected': spec.expected_cut_ms}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, f'{spec.expected_cut_ms:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def cooldown_clear_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [model['primed'], *model['start'], *(label for row in model['attempts'] for label in row)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    if run.values[model['primed']] != 0:
        return replace(base, status='unmeasured', explanation='the priming cast was refused')
    start_time, start_events = (run.values[label] for label in model['start'])
    rows = [[run.values[label] for label in row] for row in model['attempts']]
    first = next((index for index, row in enumerate(rows) if row[0] == 0), None)
    if first is None or first == 0:
        where = 'no attempt was cast' if first is None else 'the first attempt was already cast'
        return replace(base, status='unmeasured', explanation=f'{where}: the attempts do not bracket the clear time')
    cooldown = float(model['cooldown_ms'])

    def cut(row: list[float]) -> float | None:
        events = row[2] - start_events
        return (cooldown - (row[1] - start_time)) / events if events > 0 else None

    low, high = cut(rows[first]), cut(rows[first - 1])
    if low is None or high is None:
        return replace(base, status='unmeasured', explanation='no damage event before the bracketing attempts')
    expected = float(model['expected'])
    band = bonus_band(expected)
    inside = expected - band <= low and high <= expected + band
    outside = high < expected - band or low > expected + band
    status = 'ok' if inside else 'alert' if outside else 'unmeasured'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'refused at {rows[first - 1][1] - start_time:g} ms after '
                               f'{rows[first - 1][2] - start_events:g} events, cast at '
                               f'{rows[first][1] - start_time:g} ms after {rows[first][2] - start_events:g}: '
                               f'{low:.1f} to {high:.1f} ms per event against {expected:g} +- {band:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_clear_scenario(class_file, cooldown_clear_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'clear_time')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: cooldown_clear_verdict}
