from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_band
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset

KIND = 'cooldown_tick_cut'
ORDER = 48

TICK_CUT_METRIC = 'cooldown_tick_cut_pct'
PHASE_SETTLE_MS = 500
CAST_SETTLE_MS = 100
MIN_READS = 3
MAX_READS = 20


@dataclass(frozen=True)
class CooldownTickCutSpec:
    spell: int
    name: str
    quote: str
    cooled_spell: int
    phase_aura: int
    expected_pct: float
    reads: int = 4
    amplitude_effect: int = 0
    cast_power: int | None = None
    label_suffix: str = 'tick_cut'


def cooldown_tick_cut_spec(entry: dict) -> CooldownTickCutSpec:
    spec = CooldownTickCutSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['cooled_spell']),
                               int(entry['phase_aura']), float(entry['expected_pct']), int(entry.get('reads', 4)),
                               int(entry.get('amplitude_effect', 0)), entry.get('cast_power'),
                               entry.get('label_suffix', 'tick_cut'))
    if not MIN_READS <= spec.reads <= MAX_READS or spec.amplitude_effect not in (0, 1, 2):
        raise ValueError(f'{spec.spell} cooldown_tick_cut reads {MIN_READS} to {MAX_READS} times the cooldown of '
                         f'one aura effect 0-2')
    if not 0 <= spec.expected_pct < 100:
        raise ValueError(f'{spec.spell} cooldown_tick_cut expects a cut per tick of 0 to 100%, not '
                         f'{spec.expected_pct:g}')
    return spec


def tick_label(spec: CooldownTickCutSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def amplitude_ms(records: Records, spec: CooldownTickCutSpec) -> int:
    amplitude = int(records.field('Spell', spec.spell, f'EffectAmplitude[{spec.amplitude_effect}]'))
    if amplitude <= 0:
        raise ValueError(f'{spec.spell} cooldown_tick_cut effect {spec.amplitude_effect} has no periodic amplitude')
    return amplitude


def cooldown_tick_cut_scenario(class_file: dict, spec: CooldownTickCutSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_pct)
    amplitude = amplitude_ms(records, spec)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in (spec.cooled_spell, spec.spell)]
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.phase_aura, 'stacks': 1},
                {'action': 'wait', 'label': 'phase settle', 'ms': PHASE_SETTLE_MS}])
    steps += hit_ratio_cast(records, spec.cooled_spell, CASTER, TARGET, spec.cast_power)[:-1]
    steps.append({'action': 'wait', 'label': 'cast settle', 'ms': CAST_SETTLE_MS})
    reads = []
    for index in range(spec.reads):
        labels = [tick_label(spec, f'read {index} {name}') for name in ('time', 'cooldown')]
        steps += [measurement(labels[0], CASTER, 'game_time_ms'),
                  measurement(labels[1], CASTER, 'cooldown_ms', spell=spec.cooled_spell)]
        if index + 1 < spec.reads:
            steps.append({'action': 'wait', 'label': f'tick interval {index}', 'ms': amplitude})
        reads.append(labels)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cooldown tick cut',
        'contract': (f'{spec.spell} is learned with {spec.phase_aura} on the caster, then {spec.cooled_spell} is '
                     f'cast at the dummy and its remaining cooldown is read {spec.reads} times, {amplitude} ms apart '
                     f'(the amplitude of {spec.spell} effect {spec.amplitude_effect}), each read with the game time. '
                     f'Each interval of exactly one amplitude holds exactly one tick wherever it falls, so the cut '
                     f'per tick is bracketed by r2 / (r1 - D) and (r2 + D) / r1 with no tick epoch; every bracket '
                     f'must lie inside the G-19 band of {spec.expected_pct:g}%.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': TICK_CUT_METRIC, 'quote': entry.quote, 'reads': reads,
             'amplitude_ms': amplitude, 'expected': spec.expected_pct}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, f'{spec.expected_pct:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def interval_bracket(first: float, second: float, elapsed: float) -> tuple[float, float]:
    ends = (100.0 * (1.0 - (second + elapsed) / first), 100.0 * (1.0 - second / (first - elapsed)))
    return min(ends), max(ends)


def cooldown_tick_cut_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for pair in model['reads'] for label in pair]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = [[run.values[label] for label in pair] for pair in model['reads']]
    amplitude = float(model['amplitude_ms'])
    brackets = []
    for (time1, first), (time2, second) in zip(rows, rows[1:]):
        elapsed = time2 - time1
        if elapsed != amplitude:
            return replace(base, status='unmeasured',
                           explanation=f'an interval lasted {elapsed:g} ms, not one amplitude of {amplitude:g} ms')
        if first <= elapsed or second <= 0:
            return replace(base, status='unmeasured',
                           explanation=f'the cooldown ran out during the reads ({first:g} then {second:g} ms)')
        brackets.append(interval_bracket(first, second, elapsed))
    expected = float(model['expected'])
    band = bonus_band(expected)
    inside = all(expected - band <= low and high <= expected + band for low, high in brackets)
    outside = any(high < expected - band or low > expected + band for low, high in brackets)
    status = 'ok' if inside else 'alert' if outside else 'unmeasured'
    measured = sum((low + high) / 2 for low, high in brackets) / len(brackets)
    text = ', '.join(f'{low:.2f} to {high:.2f}' for low, high in brackets)
    return replace(base, status=status, measured=measured, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'cut per tick {text}% over {len(brackets)} intervals against {expected:g} +- {band:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_tick_cut_scenario(class_file, cooldown_tick_cut_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'tick_cut')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: cooldown_tick_cut_verdict}
METRIC_EVIDENCE = {TICK_CUT_METRIC: 'event'}
