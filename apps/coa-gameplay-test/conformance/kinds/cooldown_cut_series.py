from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from bonus import bonus_band
from compare import CONTRAST, Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, armed_for, dataset

KIND = 'cooldown_cut_series'
ORDER = 48

METRIC = 'cooldown_cut_series'
CONTROL = 'control'
TREATMENT = 'treatment'
AMOUNT = 'amount'
PERIOD = 'period'
TARGETS = (CASTER, TARGET)
MINIMUM_STEP_MS = 25
MAXIMUM_READS = 400
MINIMUM_TICKS = 3
DEFAULT_JITTER_MS = 20
CONTROL_CUT_SHARE = 0.02


@dataclass(frozen=True)
class SeriesCast:
    spell: int
    target: str
    wait_ms: int


@dataclass(frozen=True)
class CooldownSeriesSpec:
    spell: int
    name: str
    quote: str
    talent: int
    gated_spell: int
    learn: tuple[int, ...]
    casts: tuple[SeriesCast, ...]
    reads: int
    step_ms: int
    expected_pct: float
    expected_period_ms: float
    pct_source: tuple[int, int] | None
    period_source: tuple[int, int] | None
    cast_power: int
    dummy_distance: float | None
    clear_auras: tuple[int, ...]
    min_ticks: int
    jitter_ms: int
    label_suffix: str


def series_cast(raw) -> SeriesCast:
    if not isinstance(raw, dict) or set(raw) != {'spell', 'target', 'wait_ms'}:
        raise ValueError(f'{KIND} cast {raw!r} is {{"spell", "target", "wait_ms"}}')
    cast = SeriesCast(int(raw['spell']), str(raw['target']), int(raw['wait_ms']))
    if cast.target not in TARGETS or cast.wait_ms < 0:
        raise ValueError(f'{KIND} cast {raw!r} targets one of {TARGETS} and waits a non-negative time')
    return cast


def effect_source(raw) -> tuple[int, int] | None:
    if raw is None:
        return None
    spell, effect = raw
    if not 0 <= int(effect) < 3:
        raise ValueError(f'{KIND} source {raw!r} names a spell and an effect 0-2')
    return int(spell), int(effect)


def cooldown_series_spec(entry: dict) -> CooldownSeriesSpec:
    spell = int(entry['spell'])
    series = entry['series']
    spec = CooldownSeriesSpec(
        spell, entry['name'], entry['quote'], int(entry.get('talent', spell)), int(entry['gated_spell']),
        tuple(int(value) for value in entry.get('learn', ())), tuple(series_cast(raw) for raw in entry['casts']),
        int(series['reads']), int(series['step_ms']), float(entry['expected_pct']),
        float(entry['expected_period_ms']), effect_source(entry.get('pct_source')),
        effect_source(entry.get('period_source')), int(entry['cast_power']), entry.get('dummy_distance'),
        tuple(int(value) for value in entry.get('clear_auras', ())), int(entry.get('min_ticks', MINIMUM_TICKS)),
        int(entry.get('jitter_ms', DEFAULT_JITTER_MS)), entry.get('label_suffix', 'cooldown_cut'))
    if spec.talent in spec.learn:
        raise ValueError(f'{spell} {KIND} learns {spec.talent} only between the control and the treatment')
    if spec.gated_spell not in {cast.spell for cast in spec.casts}:
        raise ValueError(f'{spell} {KIND} casts its gated spell {spec.gated_spell} in every arm to start the cooldown')
    if not 0 < spec.expected_pct < 100 or spec.expected_period_ms <= 0:
        raise ValueError(f'{spell} {KIND} states a cut between 0 and 100% and a positive period')
    if spec.step_ms < MINIMUM_STEP_MS or not 0 < spec.reads <= MAXIMUM_READS or spec.min_ticks < 2:
        raise ValueError(f'{spell} {KIND} reads at most {MAXIMUM_READS} times, every {MINIMUM_STEP_MS} ms or more, '
                         f'and judges at least two ticks')
    if spec.reads * spec.step_ms < (spec.min_ticks - 1) * spec.expected_period_ms + 2 * spec.step_ms:
        raise ValueError(f'{spell} {KIND} reads {spec.reads * spec.step_ms} ms, too short for {spec.min_ticks} ticks '
                         f'of {spec.expected_period_ms:g} ms')
    if spec.step_ms * 2 >= spec.expected_period_ms or spec.jitter_ms < 0:
        raise ValueError(f'{spell} {KIND} reads at least twice per period, with a non-negative jitter')
    return spec


def series_label(spec: CooldownSeriesSpec, judge: str = AMOUNT) -> str:
    suffix = spec.label_suffix if judge == AMOUNT else f'{spec.label_suffix}_{judge}'
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {suffix}'


def read_label(spec: CooldownSeriesSpec, role: str, index: int, read: str) -> str:
    return f'{series_label(spec)} {role} read {index} {read}'


def checked_sources(records: Records, spec: CooldownSeriesSpec) -> None:
    if spec.pct_source is not None:
        stated = records.points(*spec.pct_source, upper=False)
        if abs(stated) != spec.expected_pct:
            raise ValueError(f'{spec.spell} {KIND} expects {spec.expected_pct:g}%, but {spec.pct_source} states '
                             f'{stated:g}')
    if spec.period_source is not None:
        stated = records.amplitude_ms(*spec.period_source)
        if stated != spec.expected_period_ms:
            raise ValueError(f'{spec.spell} {KIND} expects {spec.expected_period_ms:g} ms, but {spec.period_source} '
                             f'ticks every {stated:g} ms')


def cooldown_series_scenario(class_file: dict, spec: CooldownSeriesSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_pct)
    checked_sources(records, spec)
    for cast in spec.casts:
        class_file = armed_for(class_file, records, cast.spell)

    def arm(role: str) -> tuple[list[dict], list[tuple[str, str]]]:
        steps = []
        for cast in spec.casts:
            steps += hit_ratio_cast(records, cast.spell, CASTER, cast.target, spec.cast_power)[:-1]
            steps.append({'action': 'wait', 'label': f'{role} after {cast.spell}', 'ms': cast.wait_ms})
        reads = []
        for index in range(spec.reads):
            labels = (read_label(spec, role, index, 'cooldown'), read_label(spec, role, index, 'time'))
            steps += [measurement(labels[0], CASTER, 'cooldown_ms', spell=spec.gated_spell),
                      measurement(labels[1], CASTER, 'game_time_ms'),
                      {'action': 'wait', 'ms': spec.step_ms}]
            reads.append(labels)
        steps += [{'action': 'cancel_aura', 'actor': CASTER, 'spell': aura} for aura in spec.clear_auras]
        return steps, reads

    learned = dict.fromkeys((*spec.learn, *(cast.spell for cast in spec.casts)))
    control, control_reads = arm(CONTROL)
    treatment, treatment_reads = arm(TREATMENT)
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
             + control + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}] + treatment)
    casts = ', '.join(f'{cast.spell} at the {cast.target} then {cast.wait_ms} ms' for cast in spec.casts)
    cleared = f', then cancels {list(spec.clear_auras)}' if spec.clear_auras else ''
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cooldown cut series',
        'contract': (f'Each arm casts {casts}, then reads the remaining cooldown of {spec.gated_spell} and the game '
                     f'time {spec.reads} times, every {spec.step_ms} ms{cleared}; the caster\'s power is set to '
                     f'{spec.cast_power} before every cast. Control without {spec.talent}: the cooldown falls by the '
                     f'elapsed game time alone. Treatment with it learned: each tick cuts the cooldown by an amount '
                     f'c = before - after - elapsed between two reads, c / before bracketing the cut share (floor '
                     f'rounding), which must lie inside the G-19 band of {spec.expected_pct:g}%; the tick times, '
                     f'bracketed by the reads around them, give the period, which must lie inside the G-19 band of '
                     f'{spec.expected_period_ms:g} ms, at least {spec.min_ticks} ticks.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file) if spec.dummy_distance is None
                      else creature_fixture(class_file, float(spec.dummy_distance))],
        'steps': steps}
    shared = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'jitter_ms': spec.jitter_ms,
              'min_ticks': spec.min_ticks, 'arms': {CONTROL: control_reads, TREATMENT: treatment_reads}}
    expectations = [
        Expectation(series_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.gated_spell, None,
                    f'{spec.expected_pct:g}%', prose_rule(entry.quote, spec.spell),
                    {**shared, 'judge': AMOUNT, 'expected': spec.expected_pct,
                     'band': bonus_band(spec.expected_pct)}),
        Expectation(series_label(spec, PERIOD), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.gated_spell, None,
                    f'{spec.expected_period_ms:g} ms', prose_rule(entry.quote, spec.spell),
                    {**shared, 'judge': PERIOD, 'expected': spec.expected_period_ms,
                     'band': bonus_band(spec.expected_period_ms)})]
    return timed(scenario, waited_ms(steps)), expectations


def arm_series(run: Run, reads: list[list[str]]) -> list[tuple[float, float]] | str:
    values = []
    for labels in reads:
        found = [run.values.get(label) for label in labels]
        if any(value is None for value in found):
            return missing_measurement(run, labels[found.index(None)])
        values.append((float(found[0]), float(found[1])))
    return values


def pairs_of(series: list[tuple[float, float]]) -> list[dict]:
    return [{'before': before, 'after': after, 'start': start, 'end': end, 'elapsed': end - start,
             'excess': before - after - (end - start)}
            for (before, start), (after, end) in zip(series, series[1:]) if before > 0 and after > 0]


def control_problem(pairs: list[dict], jitter: float) -> tuple[str, str] | None:
    for pair in pairs:
        if pair['excess'] > max(jitter, CONTROL_CUT_SHARE * pair['before']):
            return 'alert', (f'without the talent the cooldown fell by {pair["excess"]:g} ms more than the '
                             f'{pair["elapsed"]:g} ms elapsed at {pair["before"]:g} ms left')
        if abs(pair['excess']) > jitter:
            return 'unmeasured', (f'without the talent the cooldown fell by {pair["before"] - pair["after"]:g} ms '
                                  f'over {pair["elapsed"]:g} ms of game time, beyond the {jitter:g} ms jitter')
    return None


def ticks_of(pairs: list[dict], jitter: float) -> tuple[list[dict], str | None]:
    ticks = []
    for pair in pairs:
        if pair['excess'] > jitter:
            ticks.append(pair)
        elif pair['excess'] < -jitter:
            return ticks, (f'the cooldown fell by {pair["before"] - pair["after"]:g} ms over {pair["elapsed"]:g} ms '
                           f'of game time, less than the time elapsed')
    return ticks, None


def share_bracket(tick: dict, jitter: float) -> tuple[float, float]:
    low = (tick['excess'] - jitter) / tick['before'] * 100
    high = (tick['excess'] + jitter + 1) / max(1.0, tick['before'] - tick['elapsed'] - jitter) * 100
    return low, high


def period_bracket(ticks: list[dict]) -> tuple[float, float]:
    count = len(ticks) - 1
    return (ticks[-1]['start'] - ticks[0]['end']) / count, (ticks[-1]['end'] - ticks[0]['start']) / count


def gap_bracket(first: dict, second: dict) -> tuple[float, float]:
    return second['start'] - first['end'], second['end'] - first['start']


def judged(base: Verdict, status: str, measured: float | None, low: float, high: float, detail: dict,
           explanation: str) -> Verdict:
    return replace(base, status=status, measured=measured, low=low, high=high, detail=detail,
                   explanation=explanation)


def cooldown_series_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    expected, band, jitter = float(model['expected']), float(model['band']), float(model['jitter_ms'])
    base = replace(base, expected=expected, low=expected - band, high=expected + band)
    series = {}
    for role in (CONTROL, TREATMENT):
        values = arm_series(run, model['arms'][role])
        if isinstance(values, str):
            return replace(base, status='unmeasured', explanation=values)
        series[role] = pairs_of(values)
    problem = control_problem(series[CONTROL], jitter)
    if problem is not None:
        return replace(base, status=problem[0], explanation=f'control: {problem[1]}')
    if len(series[CONTROL]) < model['min_ticks']:
        return replace(base, status='unmeasured', explanation=f'control: only {len(series[CONTROL])} read pairs with '
                                                             f'the cooldown running')
    ticks, problem = ticks_of(series[TREATMENT], jitter)
    if problem is not None:
        return replace(base, status='unmeasured', explanation=f'treatment: {problem}')
    detail = {CONTRAST: LEARNED_CONTRAST, 'ticks': [{key: tick[key] for key in ('before', 'excess', 'start', 'end')}
                                                    for tick in ticks]}
    control = f'control: the cooldown fell by the elapsed time alone over {len(series[CONTROL])} read pairs'
    if len(ticks) < model['min_ticks']:
        status = 'alert' if not ticks else 'unmeasured'
        return replace(base, status=status, detail=detail,
                       explanation=f'{control}; treatment: {len(ticks)} cuts, fewer than {model["min_ticks"]}')
    if model['judge'] == AMOUNT:
        brackets = [share_bracket(tick, jitter) for tick in ticks]
        low, high = min(low for low, _ in brackets), max(high for _, high in brackets)
        outside = any(high < expected - band or low > expected + band for low, high in brackets)
        inside = all(expected - band <= low and high <= expected + band for low, high in brackets)
        status = 'alert' if outside else 'ok' if inside else 'unmeasured'
        shown = '; '.join(f'{tick["excess"]:g} of {tick["before"]:g} ms ({bracket[0]:.2f} to {bracket[1]:.2f}%)'
                          for tick, bracket in zip(ticks, brackets))
        return judged(base, status, sum(low + high for low, high in brackets) / (2 * len(brackets)), low, high,
                      detail, f'{control}; treatment: {len(ticks)} cuts: {shown}; against {expected:g} +- {band:g}%')
    low, high = period_bracket(ticks)
    gaps = [gap_bracket(first, second) for first, second in zip(ticks, ticks[1:])]
    irregular = next((gap for gap in gaps if gap[1] < expected - band or gap[0] > expected + band), None)
    if irregular is not None:
        return judged(base, 'alert', (low + high) / 2, low, high, detail,
                      f'{control}; treatment: two cuts {irregular[0]:g} to {irregular[1]:g} ms apart against '
                      f'{expected:g} +- {band:g} ms')
    inside = expected - band <= low and high <= expected + band
    outside = high < expected - band or low > expected + band
    status = 'alert' if outside else 'ok' if inside else 'unmeasured'
    return judged(base, status, (low + high) / 2, low, high, detail,
                  f'{control}; treatment: {len(ticks)} cuts, period {low:.1f} to {high:.1f} ms against {expected:g} '
                  f'+- {band:g} ms')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_series_scenario(class_file, cooldown_series_spec(entry))


def label(entry: dict) -> list[str]:
    suffix = entry.get('label_suffix', 'cooldown_cut')
    return [f"{entry['spell']} behaviour_metric_delta {suffix}",
            f"{entry['spell']} behaviour_metric_delta {suffix}_{PERIOD}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: cooldown_series_verdict}
METRIC_EVIDENCE = {METRIC: 'event'}
