from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT,
                        behaviour_entry, prose_rule, waited_ms)
from bonus import bonus_band
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'summon_lifetime'
ORDER = 8


SUMMON_LIFETIME_POLL_MS = 25
SUMMON_LIFETIME_BASELINE_MARGIN_MS = 1000


@dataclass(frozen=True)
class SummonLifetimeSpec:
    spell: int
    name: str
    quote: str
    talent: int
    trigger_spell: int
    stop_ms: int
    entry: int
    expected_ms: int
    spawn_window: tuple[int, int]
    end_window: tuple[int, int]
    cast_power: int | None = None
    label_suffix: str = ''
    baseline_count: int = 0
    baseline_ms: int | None = None
    roll_source: str = ''


def summon_lifetime_mark(spec: SummonLifetimeSpec, phase: str, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA}' + (f' {spec.label_suffix}' if spec.label_suffix else '') + \
        f' {phase} {mark}'


def summon_lifetime_scenario(class_file: dict, spec: SummonLifetimeSpec) -> tuple[dict, list[Expectation]]:
    (spawn_low, spawn_high), (end_low, end_high) = spec.spawn_window, spec.end_window
    if not 0 < spawn_low < spawn_high < spec.stop_ms < end_low < end_high:
        raise ValueError(f'{spec.spell} summon_lifetime polls the spawn, stops the trigger, then polls the end, in '
                         f'that order after the cast')
    if (spec.baseline_count > 0) != (spec.baseline_ms is not None) or spec.baseline_count < 0 or (
            spec.baseline_ms is not None and spec.baseline_ms <= end_high):
        raise ValueError(f'{spec.spell} summon_lifetime sets baseline_count and baseline_ms together, the baseline '
                         f'creatures outliving the end window')
    if spec.roll_source and not spec.baseline_count:
        raise ValueError(f'{spec.spell} summon_lifetime names a roll_source only with a baseline')
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'summon_lifetime', spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    count = {'entry': spec.entry}
    polls = {}

    def cast(phase: str) -> list[dict]:
        power = spec.cast_power if spec.cast_power is not None else facts.mana_cost
        return [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                measurement(summon_lifetime_mark(spec, phase, 'start'), CASTER, 'game_time_ms'),
                {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET}]

    def stop() -> list[dict]:
        return [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.trigger_spell, 'stacks': 0, 'target': TARGET,
                 'caster': CASTER}]

    def poll(window: str, low: int, high: int) -> list[dict]:
        steps, marks = [], []
        for index in range((high - low) // SUMMON_LIFETIME_POLL_MS + 1):
            at = summon_lifetime_mark(spec, window, f'{index} at')
            present = summon_lifetime_mark(spec, window, f'{index} count')
            steps += [measurement(at, CASTER, 'game_time_ms'), measurement(present, CASTER, 'owned_creature_count',
                                                                           **count),
                      {'action': 'wait', 'label': f'{window} poll', 'ms': SUMMON_LIFETIME_POLL_MS}]
            marks.append([at, present])
        polls[window] = marks
        return steps

    def baseline_expiry_steps() -> list[dict]:
        if not spec.baseline_count:
            return []
        return [{'action': 'wait', 'label': 'let the control baseline expire',
                 'ms': spec.baseline_ms - spec.stop_ms - GCD_WAIT_MS + SUMMON_LIFETIME_BASELINE_MARGIN_MS},
                measurement(summon_lifetime_mark(spec, 'control', 'expired count'), CASTER, 'owned_creature_count',
                            **count)]

    def pre_cast_steps() -> list[dict]:
        if not spec.baseline_count:
            return []
        return [measurement(summon_lifetime_mark(spec, 'treatment', 'pre count'), CASTER, 'owned_creature_count',
                            **count)]

    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                                       {'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.talent,
                                        'op': FORCED_CHANCE_OP, 'percent': FORCED_CHANCE_PERCENT}]
             + cast('control') + [{'action': 'wait', 'label': 'control trigger', 'ms': spec.stop_ms}] + stop()
             + [{'action': 'wait', 'label': 'control settle', 'ms': GCD_WAIT_MS},
                measurement(summon_lifetime_mark(spec, 'control', 'count'), CASTER, 'owned_creature_count', **count)]
             + baseline_expiry_steps()
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
             + pre_cast_steps() + cast('treatment') + [{'action': 'wait', 'label': 'to the spawn window', 'ms': spawn_low}]
             + poll('spawn', spawn_low, spawn_high))
    polled = spawn_low + len(polls['spawn']) * SUMMON_LIFETIME_POLL_MS
    steps += ([{'action': 'wait', 'label': 'to the trigger stop', 'ms': max(1, spec.stop_ms - polled)}] + stop()
              + [{'action': 'wait', 'label': 'to the end window', 'ms': end_low - max(spec.stop_ms, polled + 1)}]
              + poll('end', end_low, end_high)
              + [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                 measurement(summon_lifetime_mark(spec, 'treatment', 'released'), CASTER, 'spell_mod_mutants')])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour summon lifetime'
                + (f' {spec.label_suffix}' if spec.label_suffix else ''),
        'contract': (f'A forcing fixture raises the roll of {spec.talent} by {FORCED_CHANCE_PERCENT}% (a '
                     f'SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant, removed at the end and read gone). Control: '
                     f'{spec.trigger_spell} cast at the dummy without {spec.talent}, its aura removed {spec.stop_ms} '
                     f'ms later: no creature {spec.entry}. Treatment: the same cast with {spec.talent} learned; the '
                     f'owned creature {spec.entry} count is polled with game-time stamps every '
                     f'{SUMMON_LIFETIME_POLL_MS} ms in {spec.spawn_window} and {spec.end_window} ms after the cast, '
                     f'the trigger aura removed at {spec.stop_ms} ms so one creature is summoned; its lifetime, '
                     f'bracketed by the polls, must be {spec.expected_ms} ms within the G-19 band.'
                     + baseline_contract(spec)),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.baseline_count:
        polls['spawn'] = [[summon_lifetime_mark(spec, 'treatment', 'start'),
                           summon_lifetime_mark(spec, 'treatment', 'pre count')], *polls['spawn']]
    model = {'kind': 'summon_lifetime', 'metric': 'owned_creature_count', 'quote': entry.quote,
             'expected_ms': spec.expected_ms,
             'band': bonus_band(float(spec.expected_ms)), 'polls': polls,
             'starts': {phase: summon_lifetime_mark(spec, phase, 'start') for phase in ('control', 'treatment')},
             'control': summon_lifetime_mark(spec, 'control', 'count'),
             'released': summon_lifetime_mark(spec, 'treatment', 'released')}
    if spec.baseline_count:
        model['baseline'] = {'count': spec.baseline_count, 'ms': spec.baseline_ms,
                             'expired': summon_lifetime_mark(spec, 'control', 'expired count')}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA}'
                              + (f' {spec.label_suffix}' if spec.label_suffix else ''), BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.trigger_spell, None, str(spec.expected_ms),
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def baseline_contract(spec: SummonLifetimeSpec) -> str:
    if not spec.baseline_count:
        return ''
    return (f' The trigger itself summons {spec.baseline_count} creatures {spec.entry} for {spec.baseline_ms} ms: the '
            f'control must read exactly {spec.baseline_count}, and none once they expired (read '
            f'{SUMMON_LIFETIME_BASELINE_MARGIN_MS} ms past their lifetime, before the talent is learned); the '
            f'treatment count reads 0 right before the cast, the talent\'s creature is present while the count reads '
            f'{spec.baseline_count + 1} and gone once it reads {spec.baseline_count}, and a count that holds '
            f'{spec.baseline_count + 1} through the end window or reads {spec.baseline_count} at its first poll '
            f'brackets a lifetime past that window\'s edge.'
            + (f' The talent\'s roll is made in {spec.roll_source}, which the forcing modifier does not reach, so '
               f'parts that roll no summon are left out of the pool.' if spec.roll_source else ''))


def summon_lifetime_spec(entry: dict) -> SummonLifetimeSpec:
    return SummonLifetimeSpec(entry['spell'], entry['name'], entry['quote'], int(entry['talent']),
                              int(entry['trigger_spell']), int(entry['stop_ms']), int(entry['entry']),
                              int(entry['expected_ms']), tuple(int(value) for value in entry['spawn_window']),
                              tuple(int(value) for value in entry['end_window']), entry.get('cast_power'),
                              entry.get('label_suffix', ''), int(entry.get('baseline_count', 0)),
                              None if entry.get('baseline_ms') is None else int(entry['baseline_ms']),
                              str(entry.get('roll_source', '')))


def summon_lifetime_edge(run: Run, polls: list, start: float, rising: bool,
                         baseline: float = 0.0) -> tuple[float, float, float] | str:
    before, after, most = None, None, 0.0
    for time_label, count_label in polls:
        at, count = run.values.get(time_label), run.values.get(count_label)
        if at is None or count is None:
            return missing_measurement(run, time_label if at is None else count_label)
        most = max(most, count - baseline)
        present = count >= baseline + 0.5
        if after is None:
            if present == rising:
                after = at - start
            else:
                before = at - start
        elif present != rising:
            return f'the count turns back at {at - start:g} ms after its edge'
    if before is None or after is None:
        return 'the polls do not hold the edge'
    return before, after, most


def baseline_edges(run: Run, model: dict, start: float):
    count = float(model['baseline']['count'])
    spawn = summon_lifetime_edge(run, model['polls']['spawn'], start, True, count)
    end = summon_lifetime_edge(run, model['polls']['end'], start, False, count)
    if isinstance(spawn, str) or not isinstance(end, str) or end != 'the polls do not hold the edge':
        return spawn, end
    marks = model['polls']['end']
    first, last = run.values[marks[0][0]] - start, run.values[marks[-1][0]] - start
    readings = {run.values[count_label] for _, count_label in marks}
    if readings == {count + 1}:
        return spawn, (last, math.inf, 1.0)
    if readings == {count}:
        return spawn, (-math.inf, first, 1.0)
    return spawn, end


def baseline_failure(run: Run, model: dict) -> str | None:
    baseline = model['baseline']
    count = float(baseline['count'])
    expired = run.values.get(baseline['expired'])
    if expired is None:
        return missing_measurement(run, baseline['expired'])
    if expired != 0:
        return f'{expired:g} baseline creatures left {baseline["ms"]} ms after the control cast'
    pre = run.values.get(model['polls']['spawn'][0][1])
    if pre != 0:
        return f'{pre:g} creatures right before the treatment cast'
    stray = sorted({run.values[count_label] for _, count_label in model['polls']['end']} - {count, count + 1})
    if stray:
        return f'the end window reads {stray}, neither the baseline {count:g} nor one more'
    return None


def finite(value: float) -> float | None:
    return None if math.isinf(value) else value


def bounded_text(lowest: float, highest: float) -> str:
    if math.isinf(highest):
        return f'at least {lowest:g}'
    if math.isinf(lowest):
        return f'at most {highest:g}'
    return f'{lowest:g} to {highest:g}'


def behaviour_summon_lifetime_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [model['control'], model['released'], *model['starts'].values()]
    values = [run.values.get(label) for label in labels]
    if None in values:
        return replace(base, explanation=missing_measurement(run, labels[values.index(None)]))
    control, released = values[0], values[1]
    start = run.values[model['starts']['treatment']]
    baseline = model.get('baseline')
    if baseline:
        spawn, end = baseline_edges(run, model, start)
    else:
        spawn = summon_lifetime_edge(run, model['polls']['spawn'], start, True)
        end = summon_lifetime_edge(run, model['polls']['end'], start, False)
    for name, edge in (('spawn', spawn), ('end', end)):
        if isinstance(edge, str):
            return replace(base, status='unmeasured', explanation=f'{name}: {edge}')
    failure = baseline_failure(run, model) if baseline else None
    if failure is not None:
        return replace(base, status='unmeasured', explanation=failure)
    expected_control = float(baseline['count']) if baseline else 0.0
    if spawn[2] != 1 or end[2] != 1:
        return replace(base, status='unmeasured', explanation=f'{spawn[2]:g} and {end[2]:g} creatures at most in the '
                                                              f'windows, not one')
    lowest, highest = end[0] - spawn[1], end[1] - spawn[0]
    expected, band = float(model['expected_ms']), float(model['band'])
    low, high = expected - band, expected + band
    one_sided = math.isinf(lowest) or math.isinf(highest)
    measured = highest if math.isinf(lowest) else lowest if math.isinf(highest) else (lowest + highest) / 2
    if control != expected_control or released != 0:
        status, reason = 'alert', (f'the control counts {control:g} (expected {expected_control:g}) and '
                                   f'{released:g} forcing modifiers remain')
    elif low - 1e-9 <= lowest and highest <= high + 1e-9:
        status, reason = 'ok', 'the whole bracketed lifetime lies inside the band'
    elif highest < low or lowest > high:
        status, reason = 'alert', 'the whole bracketed lifetime lies outside the band'
    elif one_sided:
        return replace(base, status='unmeasured', explanation=f'end: the count does not change in the end window, so '
                                                              f'the lifetime is only bounded on one side, '
                                                              f'{bounded_text(lowest, highest)} ms, and that bound '
                                                              f'reaches the band {low:g} to {high:g}')
    else:
        status, reason = 'measured', 'the bracketed lifetime crosses a band edge: effect present, not final'
    control_text = (f'the control counts the {expected_control:g} baseline creatures and none once they expired; '
                    if baseline else 'no creature in the control; ')
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   detail={'spawn_ms': spawn[:2], 'end_ms': [finite(end[0]), finite(end[1])],
                           'lifetime_range': [finite(lowest), finite(highest)]},
                   explanation=f'{control_text}in game time after the treatment cast the creature '
                               f'appears in ({spawn[0]:g}, {spawn[1]:g}] ms and is gone in ({end[0]:g}, {end[1]:g}] '
                               f'ms: a lifetime of {bounded_text(lowest, highest)} ms against the stated '
                               f'{expected:g} ms, '
                               f'band {low:g} to {high:g}: {reason}')


def behaviour_summon_lifetime_pooled_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    judged, empty = [], 0
    for run in runs:
        start = run.values.get(model['starts']['treatment'])
        counts = [run.values.get(count) for _, count in model['polls']['spawn']]
        baseline = float(model['baseline']['count']) if model.get('baseline') else 0.0
        if start is not None and None not in counts and not any(count >= baseline + 0.5 for count in counts):
            control, released = run.values.get(model['control']), run.values.get(model['released'])
            if control != baseline or released != 0:
                return replace(base, status='alert', explanation=f'{run.key}: the control summoned {control} and '
                                                                 f'{released} forcing modifiers remain')
            empty += 1
            continue
        judged.append(behaviour_summon_lifetime_verdict(base, run, model))
    if not judged:
        return replace(base, status='unmeasured', explanation=f'no part of {len(runs)} summoned the creature')
    worst = next((verdict for verdict in judged if verdict.status != 'ok'), None)
    ranges = [verdict.detail['lifetime_range'] for verdict in judged if verdict.detail]
    bounded = len(ranges) == len(judged) and all(None not in edges for edges in ranges)
    lowest = min(edges[0] for edges in ranges) if bounded else None
    highest = max(edges[1] for edges in ranges) if bounded else None
    summary = (f'{len(judged)} of {len(runs)} parts summoned the creature ({empty} rolled no summon on their one '
               f'tick); lifetimes {lowest:g} to {highest:g} ms' if lowest is not None else
               f'{len(judged)} of {len(runs)} parts summoned the creature')
    if worst is not None:
        return replace(worst, explanation=f'{summary}; a part reads {worst.status}: {worst.explanation}')
    first = judged[0]
    return replace(first, low=first.low, high=first.high, measured=(lowest + highest) / 2,
                   detail={**(first.detail or {}), 'lifetime_range': [lowest, highest], 'parts_summoned': len(judged),
                           'parts': len(runs)},
                   explanation=f'{summary}, against the stated {first.expected:g} ms, band {first.low:g} to '
                               f'{first.high:g}: every summoned part lies inside the band')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return summon_lifetime_scenario(class_file, summon_lifetime_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta"
            + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')]


JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_summon_lifetime_verdict}


POOLED_JUDGE = behaviour_summon_lifetime_pooled_verdict
