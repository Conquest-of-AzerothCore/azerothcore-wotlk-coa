from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from kinds.cast_period import cast_period_label
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'aura_window'
ORDER = 10


AURA_WINDOW_STEP_OVERHEAD_MS = 9


@dataclass(frozen=True)
class AuraWindowSpec:
    spell: int
    name: str
    quote: str
    trigger_spell: int
    aura: int
    control_ms: int
    treatment_ms: int
    control_windows: tuple[tuple[int, int], tuple[int, int]]
    treatment_windows: tuple[tuple[int, int], tuple[int, int]]
    trigger_power: int | None = None
    poll_ms: int = 5
    label_suffix: str = 'aura_window'


def aura_window_spec(entry: dict) -> AuraWindowSpec:
    windows = lambda raw: tuple((int(low), int(high)) for low, high in raw)
    spec = AuraWindowSpec(entry['spell'], entry['name'], entry['quote'], int(entry['trigger_spell']),
                          int(entry['aura']), int(entry['control_ms']), int(entry['treatment_ms']),
                          windows(entry['control_windows']), windows(entry['treatment_windows']),
                          entry.get('trigger_power'), int(entry.get('poll_ms', 5)),
                          entry.get('label_suffix', 'aura_window'))
    for (start_low, start_high), (end_low, end_high) in (spec.control_windows, spec.treatment_windows):
        if not 0 <= start_low < start_high < end_low < end_high:
            raise ValueError(f'{spec.spell} aura_window polls the start window, then the end window, after the cast')
    return spec


def aura_window_scenario(class_file: dict, spec: AuraWindowSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aura_window', spec.quote, float(spec.treatment_ms))
    facts = facts_of(records, spec.trigger_spell)
    reads = {}

    def phase(name: str, windows) -> list[dict]:
        power = spec.trigger_power if spec.trigger_power is not None else facts.mana_cost
        steps = [{'action': 'wait', 'label': f'{name} before the cast', 'ms': GCD_WAIT_MS},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                 measurement(cast_period_label(spec, f'{name} cast'), CASTER, 'game_time_ms'),
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET}]
        rows, elapsed = [], 0
        for low, high in windows:
            gap = max(1, low - elapsed - AURA_WINDOW_STEP_OVERHEAD_MS)
            steps.append({'action': 'wait', 'label': f'{name} to the window', 'ms': gap})
            elapsed += gap + AURA_WINDOW_STEP_OVERHEAD_MS
            while elapsed <= high:
                index = len(rows)
                row = [cast_period_label(spec, f'{name} {index} time'), cast_period_label(spec, f'{name} {index} aura')]
                steps += [measurement(row[0], CASTER, 'game_time_ms'),
                          measurement(row[1], TARGET, 'aura', spell=spec.aura, caster=CASTER),
                          {'action': 'wait', 'label': f'{name} poll', 'ms': spec.poll_ms}]
                rows.append(row)
                elapsed += spec.poll_ms + AURA_WINDOW_STEP_OVERHEAD_MS
        reads[name] = {'cast': cast_period_label(spec, f'{name} cast'), 'rows': rows}
        return steps + [{'action': 'wait', 'label': f'{name} settle', 'ms': 1500}]

    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}]
             + phase('control', spec.control_windows) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + phase('treatment', spec.treatment_windows))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura window',
        'contract': (f'{spec.trigger_spell} cast at the dummy without {spec.spell} (control) and with it learned; '
                     f'aura {spec.aura} on the dummy and the game time are read every {spec.poll_ms} ms over a start and '
                     f'an end window of each cast; the aura\'s stamped duration must be {spec.control_ms} ms without '
                     f'and {spec.treatment_ms} ms with it, each inside the G-19 band.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': 'aura_window', 'metric': 'aura', 'quote': entry.quote, 'reads': reads,
             'expected': {'control': spec.control_ms, 'treatment': spec.treatment_ms}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.aura, None, str(spec.treatment_ms), prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def aura_window_bracket(run, phase: dict) -> tuple[float, float] | str:
    rows = [(run.values[time], run.values[present]) for time, present in phase['rows']]
    first = next((index for index, (_, present) in enumerate(rows) if present), None)
    if first is None or first == 0:
        return 'the aura is never seen applied inside the start window' if first is None else \
            'the aura is already on at the first read of the start window'
    gone = next((index for index in range(first + 1, len(rows)) if not rows[index][1]), None)
    if gone is None:
        return 'the aura is still on at the last read of the end window'
    if any(not present for _, present in rows[first:gone]):
        return 'the aura is absent between its start and its end'
    if not rows[gone - 1][1] or rows[gone - 1][0] == rows[first][0]:
        return 'the start and the end fall in the same window'
    return rows[gone - 1][0] - rows[first][0], rows[gone][0] - rows[first - 1][0]


def aura_window_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for phase in model['reads'].values() for row in phase['rows'] for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    parts, ok = [], True
    for name, phase in model['reads'].items():
        bracket = aura_window_bracket(run, phase)
        if isinstance(bracket, str):
            return replace(base, status='unmeasured', explanation=f'{name}: {bracket}')
        expected = float(model['expected'][name])
        band = bonus_band(expected)
        inside = expected - band <= bracket[0] and bracket[1] <= expected + band
        ok = ok and inside
        parts.append(f'{name} lasted between {bracket[0]:g} and {bracket[1]:g} ms against {expected:g} +- {band:g}')
    low, high = aura_window_bracket(run, model['reads']['treatment'])
    expected = float(model['expected']['treatment'])
    return replace(base, status='ok' if ok else 'alert', measured=(low + high) / 2, expected=expected,
                   low=expected - bonus_band(expected), high=expected + bonus_band(expected),
                   explanation='; '.join(parts) + ' (stamped game time, first read with the aura to the first without)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return aura_window_scenario(class_file, aura_window_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta "
            f"{entry.get('label_suffix', 'aura_window')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: aura_window_verdict}
