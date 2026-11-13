from dataclasses import dataclass, replace
from pathlib import Path

from bonus import bonus_band
from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, reagent_steps, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import TARGET, Expectation, dataset, facts_of, required_aura_steps

CAST_PERIOD_METRIC = 'owned_creature_spell_cast_count'
CAST_PERIOD_MINIMUM_CASTS = 3


@dataclass(frozen=True)
class CastPeriodSpec:
    spell: int
    name: str
    quote: str
    setup_spell: int
    setup_wait_ms: int
    trigger_spell: int
    entry: int
    cast_spell: int
    expected_ms: int
    control_ms: int
    window_ms: int
    poll_ms: int = 100
    label_suffix: str = 'cast_period'


def cast_period_spec(entry: dict) -> CastPeriodSpec:
    spec = CastPeriodSpec(entry['spell'], entry['name'], entry['quote'], int(entry['setup_spell']),
                          int(entry['setup_wait_ms']), int(entry['trigger_spell']), int(entry['entry']),
                          int(entry['cast_spell']), int(entry['expected_ms']), int(entry['control_ms']),
                          int(entry['window_ms']), int(entry.get('poll_ms', 100)),
                          entry.get('label_suffix', 'cast_period'))
    if spec.poll_ms < 25 or spec.poll_ms * 2 > spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period polls at least every 25 ms and at most half the period')
    if spec.window_ms < CAST_PERIOD_MINIMUM_CASTS * spec.expected_ms or spec.control_ms < 2 * spec.expected_ms:
        raise ValueError(f'{spec.spell} cast_period needs a window of {CAST_PERIOD_MINIMUM_CASTS} periods and a '
                         f'control of two')
    return spec


def cast_period_label(spec: CastPeriodSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast_period_scenario(class_file: dict, spec: CastPeriodSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'cast_period', spec.quote, float(spec.expected_ms))
    counted = {'spell': spec.cast_spell, 'entry': spec.entry}

    def cast(spell: int, target: str) -> list[dict]:
        facts = facts_of(records, spell)
        steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
        if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
            steps.insert(0, {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
        return (steps + required_aura_steps(facts) + reagent_steps(records, spell)
                + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target}])

    control = cast_period_label(spec, 'control')
    start = cast_period_label(spec, 'start')
    reads = []
    polls = []
    for index in range(spec.window_ms // spec.poll_ms + 1):
        labels = [cast_period_label(spec, f'{index} time'), cast_period_label(spec, f'{index} casts')]
        polls += [measurement(labels[0], CASTER, 'game_time_ms'),
                  measurement(labels[1], CASTER, CAST_PERIOD_METRIC, **counted),
                  {'action': 'wait', 'label': 'cast period poll', 'ms': spec.poll_ms}]
        reads.append(labels)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.setup_spell,
                                                                                 spec.trigger_spell)]
             + cast(spec.setup_spell, CASTER) + [{'action': 'wait', 'label': 'summon', 'ms': spec.setup_wait_ms},
                                                  {'action': 'wait', 'label': 'uncommanded control',
                                                   'ms': spec.control_ms},
                                                  measurement(control, CASTER, CAST_PERIOD_METRIC, **counted),
                                                  measurement(start, CASTER, 'game_time_ms')]
             + cast(spec.trigger_spell, TARGET) + polls)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cast period',
        'contract': (f'A real {spec.setup_spell} cast raises creature {spec.entry}; uncommanded for {spec.control_ms} '
                     f'ms (control) it must cast no {spec.cast_spell}. Then {spec.trigger_spell} at the dummy, and '
                     f'every {spec.poll_ms} ms over {spec.window_ms} ms the game time and the creature\'s casts of '
                     f'{spec.cast_spell} are read; the first and the last cast are bracketed in game time and the '
                     f'period (last - first) / (casts - 1) must lie inside {spec.expected_ms} ms +- the G-19 band.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'cast_period', 'metric': CAST_PERIOD_METRIC, 'quote': entry.quote,
             'expected_ms': spec.expected_ms, 'band_ms': bonus_band(float(spec.expected_ms)), 'reads': reads,
             'control_label': control, 'start_label': start}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.cast_spell, None, str(spec.expected_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def cast_period_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [model['control_label'], model['start_label'], *(label for pair in model['reads'] for label in pair)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    control = run.values[model['control_label']]
    times = [run.values[pair[0]] for pair in model['reads']]
    casts = [run.values[pair[1]] for pair in model['reads']]
    expected, band = float(model['expected_ms']), float(model['band_ms'])
    if control != 0:
        return replace(base, status='alert', measured=control, expected=0.0,
                       explanation=f'the control read before the trigger counts {control:g} (expected none)')
    count = int(casts[-1])
    if count < CAST_PERIOD_MINIMUM_CASTS or casts[0] != 0:
        return replace(base, status='unmeasured' if casts[0] == 0 else 'alert', measured=float(count),
                       explanation=f'{count:g} casts in the window, {casts[0]:g} at its first read: the period needs '
                                   f'at least {CAST_PERIOD_MINIMUM_CASTS} casts after a read of none')
    if any(later - earlier > 1 for earlier, later in zip(casts, casts[1:])) or casts != sorted(casts):
        return replace(base, status='alert', measured=float(count),
                       explanation='two casts fell between two reads, or the count fell: the polls do not bracket '
                                   'each cast')
    first = next(index for index, value in enumerate(casts) if value >= 1)
    last = casts.index(count)
    low = (times[last - 1] - times[first]) / (count - 1)
    high = (times[last] - times[first - 1]) / (count - 1)
    start = run.values[model['start_label']]
    status = 'ok' if expected - band <= low and high <= expected + band else 'alert'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'{count} casts; the first in ({times[first - 1] - start:g}, {times[first] - start:g}] '
                               f'ms of game time after the command, the last in ({times[last - 1] - start:g}, '
                               f'{times[last] - start:g}]: a period between {low:.1f} and {high:.1f} ms against '
                               f'{expected:g} +- {band:g} (G-19); none in the control read before the trigger')
