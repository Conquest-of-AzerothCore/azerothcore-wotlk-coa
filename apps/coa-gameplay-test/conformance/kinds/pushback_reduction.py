from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, CONDITION_CONTRAST, LEARNED_CONTRAST, OWN_CAST_CONTRAST, STRIKER,
                        STRIKER_DISTANCE, STRIKER_HEALTH, TAKEN_HIT_STRIKER_ENTRY, behaviour_entry, hit_ratio_cast,
                        prose_rule, waited_ms)
from bonus import bonus_band
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'pushback_reduction'
ORDER = 7


PUSHBACK_PHASES = ('unhit', 'hit', 'reduced')
PUSHBACK_LEARNED_PHASES = ('unhit', 'hit', 'reduced_unhit', 'reduced')
PUSHBACK_POLL_MS = 1
PUSHBACK_CASTER_HEALTH = 100000


@dataclass(frozen=True)
class PushbackReductionSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    cast_power: int
    reducer_spell: int
    reducer_wait_ms: int
    strike_spell: int
    strike_at_ms: int
    windows: tuple[tuple[int, int], ...]
    expected_pct: float
    label_suffix: str = ''
    reducer_learn: bool = False
    repeats: int = 1


def pushback_phases(spec: PushbackReductionSpec) -> tuple[str, ...]:
    return PUSHBACK_LEARNED_PHASES if spec.reducer_learn else PUSHBACK_PHASES


def pushback_contrast(spec: PushbackReductionSpec) -> str:
    if spec.reducer_learn:
        return LEARNED_CONTRAST
    return OWN_CAST_CONTRAST if spec.reducer_spell == spec.spell else CONDITION_CONTRAST


def pushback_label(spec: PushbackReductionSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA}' + (f' {spec.label_suffix}' if spec.label_suffix else '')


def pushback_mark(spec: PushbackReductionSpec, phase: str, mark: str) -> str:
    return f'{pushback_label(spec)} {phase} {mark}'


def pushback_reduction_scenario(class_file: dict, spec: PushbackReductionSpec) -> tuple[dict, list[Expectation]]:
    phases = pushback_phases(spec)
    if len(spec.windows) != len(phases) or any(not 0 < low < high for low, high in spec.windows):
        raise ValueError(f'{spec.spell} pushback_reduction polls one window (start, end) after the cast start per '
                         f'phase {phases}')
    if not 0 < spec.strike_at_ms < min(low for low, _ in spec.windows):
        raise ValueError(f'{spec.spell} pushback_reduction strikes inside the cast, before every polled window')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'pushback_reduction', spec.quote, spec.expected_pct)
    facts = facts_of(records, spec.cast_spell)
    windows = dict(zip(phases, spec.windows))
    polls = {}

    def phase(kind: str, sample: int = 0) -> list[dict]:
        name = f'{kind} {sample}' if sample else kind
        low, high = windows[kind]
        steps = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
                 {'action': 'set_health', 'actor': CASTER, 'value': PUSHBACK_CASTER_HEALTH,
                  'maximum': PUSHBACK_CASTER_HEALTH},
                 measurement(pushback_mark(spec, name, 'start'), CASTER, 'game_time_ms'),
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET}]
        waited = 0
        if kind in ('hit', 'reduced'):
            steps += [{'action': 'wait', 'label': f'{name} before the strike', 'ms': spec.strike_at_ms},
                      measurement(pushback_mark(spec, name, 'strikes'), CASTER, 'spell_damage_count',
                                  spell=spec.strike_spell, caster=STRIKER, target=CASTER),
                      measurement(pushback_mark(spec, name, 'strike'), CASTER, 'game_time_ms'),
                      {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                      measurement(pushback_mark(spec, name, 'struck'), CASTER, 'game_time_ms')]
            waited = spec.strike_at_ms
        steps.append({'action': 'wait', 'label': f'{name} to the window', 'ms': low - waited})
        marks = []
        for index in range((high - low) // PUSHBACK_POLL_MS + 1):
            casting, time = pushback_mark(spec, name, f'{index} casting'), pushback_mark(spec, name, f'{index} at')
            steps += [measurement(time, CASTER, 'game_time_ms'), measurement(casting, CASTER, 'casting'),
                      {'action': 'wait', 'label': f'{name} poll', 'ms': PUSHBACK_POLL_MS}]
            marks.append([time, casting])
        polls[name] = marks
        return steps + [{'action': 'wait', 'label': f'{name} settle', 'ms': GCD_WAIT_MS},
                        measurement(pushback_mark(spec, name, 'after strikes'), CASTER, 'spell_damage_count',
                                    spell=spec.strike_spell, caster=STRIKER, target=CASTER)]

    def repeated(kind: str) -> list[dict]:
        if spec.repeats == 1:
            return phase(kind)
        return [step for sample in range(1, spec.repeats + 1) for step in phase(kind, sample)]

    if spec.repeats < 1:
        raise ValueError(f'{spec.spell} pushback_reduction repeats each cast at least once')
    learned = (spec.cast_spell,) if spec.reducer_learn else (spec.cast_spell, spec.reducer_spell)
    reducer = ([{'action': 'learn', 'actor': CASTER, 'spell': spec.reducer_spell}] if spec.reducer_learn
               else hit_ratio_cast(records, spec.reducer_spell, CASTER, CASTER))
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
             + repeated('unhit') + repeated('hit') + reducer
             + [{'action': 'wait', 'label': 'reducer', 'ms': spec.reducer_wait_ms}]
             + (repeated('reduced_unhit') if spec.reducer_learn else []) + repeated('reduced'))
    striker = {'id': STRIKER, 'owner': CASTER, 'entry': TAKEN_HIT_STRIKER_ENTRY, 'level': class_file['level'],
               'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour pushback reduction'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': (f'Three casts of {spec.cast_spell} at the dummy in one scenario: unhit; hit once by the '
                     f'striker\'s {spec.strike_spell} {spec.strike_at_ms} ms into the cast; and the same after a real '
                     f'{spec.reducer_spell}. Each cast start, each strike and every poll of the caster\'s casting '
                     f'state are stamped in game time; a cast ends between its last casting and its first idle poll. '
                     f'The reduction (reduced end - unhit end) / (hit end - unhit end), bracketed by the polls, must '
                     f'remove {spec.expected_pct:g}% of the pushback within the G-19 band; the two strikes must land '
                     f'at the same game-time offset into their casts within the poll brackets, else the reading is '
                     f'invalid.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file), striker],
        'steps': steps}
    model = {'kind': 'pushback_reduction', 'metric': 'casting', 'contrast': pushback_contrast(spec),
             'quote': entry.quote, 'expected_pct': spec.expected_pct,
             'band': bonus_band(spec.expected_pct),
             'phases': ({name: pushback_phase_model(spec, name, name, polls) for name in phases}
                        if spec.repeats == 1 else {})}
    if spec.repeats > 1:
        model['samples'] = {kind: [pushback_phase_model(spec, kind, f'{kind} {sample}', polls)
                                   for sample in range(1, spec.repeats + 1)] for kind in phases}
        scenario['contract'] += (f' Each of the casts is repeated {spec.repeats} times; the judge takes the mean '
                                 f'bracket middle of each kind of cast and its 99% interval.')
    expectation = Expectation(pushback_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.cast_spell, None,
                              str(spec.expected_pct), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def pushback_phase_model(spec: PushbackReductionSpec, kind: str, name: str, polls: dict) -> dict:
    return {'start': pushback_mark(spec, name, 'start'), 'polls': polls[name],
            **({'strike': pushback_mark(spec, name, 'strike'), 'struck': pushback_mark(spec, name, 'struck'),
                'strikes': [pushback_mark(spec, name, 'strikes'), pushback_mark(spec, name, 'after strikes')]}
               if kind in ('hit', 'reduced') else {})}


def pushback_reduction_spec(entry: dict) -> PushbackReductionSpec:
    return PushbackReductionSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                                 int(entry['cast_power']), int(entry['reducer_spell']),
                                 int(entry.get('reducer_wait_ms', 1600)), int(entry['strike_spell']),
                                 int(entry['strike_at_ms']),
                                 tuple((int(low), int(high)) for low, high in entry['windows']),
                                 float(entry['expected_pct']), entry.get('label_suffix', ''),
                                 bool(entry.get('reducer_learn', False)), int(entry.get('repeats', 1)))


def pushback_end_bracket(run: Run, phase: dict) -> tuple[float, float] | str:
    start = run.values.get(phase['start'])
    if start is None:
        return missing_measurement(run, phase['start'])
    last_casting, first_idle = None, None
    for time_label, casting_label in phase['polls']:
        at, casting = run.values.get(time_label), run.values.get(casting_label)
        if at is None or casting is None:
            return missing_measurement(run, time_label if at is None else casting_label)
        if casting >= 0.5:
            if first_idle is not None:
                return f'the caster casts again at {at - start:g} ms after an idle poll'
            last_casting = at
        elif first_idle is None:
            first_idle = at
    if last_casting is None or first_idle is None:
        return 'the polls do not hold both the cast and its end'
    return last_casting - start, first_idle - start


def pushback_strike_offsets(run: Run, phase: dict) -> tuple[float, float] | str:
    labels = [phase['start'], phase['strike'], phase['struck'], *phase['strikes']]
    values = [run.values.get(label) for label in labels]
    if None in values:
        return missing_measurement(run, labels[values.index(None)])
    start, strike, struck, before, after = values
    if after - before != 1:
        return f'{after - before:g} strikes landed during the cast, not 1'
    return strike - start, struck - start


def behaviour_pushback_samples_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    means, spreads, offsets, widths, skipped = {}, {}, [], [], []
    for kind, samples in model['samples'].items():
        middles = []
        for index, phase in enumerate(samples, 1):
            if 'strike' in phase:
                found = pushback_strike_offsets(run, phase)
                if isinstance(found, str):
                    skipped.append(f'{kind} {index}: {found}')
                    continue
            bracket = pushback_end_bracket(run, phase)
            if isinstance(bracket, str):
                return replace(base, status='unmeasured', explanation=f'{kind} {index}: {bracket}')
            middles.append((bracket[0] + bracket[1]) / 2)
            widths.append(bracket[1] - bracket[0])
            if 'strike' in phase:
                offsets += list(found)
        if len(middles) < max(2, len(samples) // 2):
            return replace(base, status='unmeasured', explanation=f'{kind}: {len(middles)} of {len(samples)} casts '
                                                                  f'valid ({"; ".join(skipped)})')
        means[kind] = sum(middles) / len(middles)
        spreads[kind] = (sum((middle - means[kind]) ** 2 for middle in middles) / (len(middles) - 1)
                         / len(middles))
    if max(offsets) - min(offsets) > max(widths):
        return replace(base, status='unmeasured', explanation=f'invalid: the strikes land {min(offsets):g} to '
                                                              f'{max(offsets):g} ms into their casts, more than the '
                                                              f'poll bracket {max(widths):g} ms apart')
    base_kind = 'reduced_unhit' if 'reduced_unhit' in means else 'unhit'
    full = means['hit'] - means['unhit']
    if full <= 0:
        return replace(base, status='alert', explanation=f'the mean hit cast ends {means["hit"]:g} ms, no later '
                                                         f'than the unhit cast {means["unhit"]:g} ms')
    kept = means['reduced'] - means[base_kind]
    measured = (1 - kept / full) * 100
    variance = (spreads['reduced'] + spreads[base_kind]) / full ** 2 + \
        (kept / full ** 2) ** 2 * (spreads['hit'] + spreads['unhit'])
    half = 2.576 * math.sqrt(variance) * 100
    expected, band = float(model['expected_pct']), float(model['band'])
    low, high = expected - band, expected + band
    if low - 1e-9 <= measured - half and measured + half <= high + 1e-9:
        status, reason = 'ok', 'the 99% interval lies inside the band'
    elif measured + half < low or measured - half > high:
        status, reason = 'alert', 'the 99% interval lies outside the band'
    else:
        status, reason = 'measured', 'the 99% interval crosses a band edge: effect present, not final'
    count = len(next(iter(model['samples'].values())))
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   detail={'mean_ends_ms': means, 'interval': [measured - half, measured + half]},
                   explanation=f'{count} casts of each kind; mean cast ends (bracket middles) after the start in '
                               f'game time: {", ".join(f"{kind} {value:.2f}" for kind, value in means.items())} ms; '
                               f'strikes {min(offsets):g} to {max(offsets):g} ms into their casts; the pushback falls '
                               f'by {measured:.4g}% (99% interval {measured - half:.4g} to {measured + half:.4g}) '
                               f'against the stated {expected:g}%, band {low:g} to {high:g}: {reason}'
                               + (f'; invalid hit casts left out: {"; ".join(skipped)}' if skipped else ''))


def behaviour_pushback_reduction_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model.get('samples'):
        return behaviour_pushback_samples_verdict(base, run, model)
    ends, strikes = {}, {}
    for name, phase in model['phases'].items():
        bracket = pushback_end_bracket(run, phase)
        if isinstance(bracket, str):
            return replace(base, status='unmeasured', explanation=f'{name}: {bracket}')
        ends[name] = bracket
        if 'strike' in phase:
            labels = [phase['start'], phase['strike'], phase['struck'], *phase['strikes']]
            values = [run.values.get(label) for label in labels]
            if None in values:
                return replace(base, explanation=missing_measurement(run, labels[values.index(None)]))
            start, strike, struck, before, after = values
            if after - before != 1:
                return replace(base, status='unmeasured',
                               explanation=f'{name}: {after - before:g} strikes landed during the cast, not 1')
            strikes[name] = (strike - start, struck - start)
    width = max(high - low for low, high in ends.values())
    offsets = [offset for pair in strikes.values() for offset in pair]
    if max(offsets) - min(offsets) > width:
        return replace(base, status='unmeasured',
                       explanation=f'invalid: the strikes land {strikes} ms into their casts, more than the poll '
                                   f'bracket {width:g} ms apart')
    (unhit_low, unhit_high), (hit_low, hit_high), (reduced_low, reduced_high) = (
        ends['unhit'], ends['hit'], ends['reduced'])
    base_low, base_high = ends.get('reduced_unhit', ends['unhit'])
    middle = lambda bracket: (bracket[0] + bracket[1]) / 2
    if hit_low <= unhit_high:
        return replace(base, status='alert', explanation=f'the hit cast ends {ends["hit"]} ms, no later than the '
                                                         f'unhit cast {ends["unhit"]} ms: no pushback to reduce')
    reduction = lambda reduced, reduced_base, unhit, hit: (1 - (reduced - reduced_base) / (hit - unhit)) * 100
    if 'reduced_unhit' in ends:
        lowest = reduction(reduced_high, base_low, unhit_high, hit_low)
        highest = reduction(reduced_low, base_high, unhit_low, hit_high)
    else:
        lowest = reduction(reduced_high, unhit_low, unhit_low, hit_low)
        highest = reduction(reduced_low, unhit_high, unhit_high, hit_high)
    measured = reduction(middle(ends['reduced']), middle(ends.get('reduced_unhit', ends['unhit'])),
                         middle(ends['unhit']), middle(ends['hit']))
    expected, band = float(model['expected_pct']), float(model['band'])
    low, high = expected - band, expected + band
    if low - 1e-9 <= lowest and highest <= high + 1e-9:
        status, reason = 'ok', 'the whole bracketed reduction lies inside the band'
    elif highest < low or lowest > high:
        status, reason = 'alert', 'the whole bracketed reduction lies outside the band'
    else:
        status, reason = 'measured', 'the bracketed reduction crosses a band edge: effect present, not final'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   detail={'ends_ms': ends, 'strikes_ms': strikes, 'reduction_range': [lowest, highest]},
                   explanation=f'cast ends after the start in game time: unhit {ends["unhit"]}, hit {ends["hit"]}, '
                               f'reduced {ends["reduced"]} ms (last casting, first idle poll); strikes at '
                               f'{strikes} ms; the pushback falls by {lowest:.4g}% to {highest:.4g}% '
                               f'({measured:.4g}% at the bracket middles) against the stated {expected:g}%, band '
                               f'{low:g} to {high:g}: {reason}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return pushback_reduction_scenario(class_file, pushback_reduction_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta"
            + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')]


JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_pushback_reduction_verdict}
