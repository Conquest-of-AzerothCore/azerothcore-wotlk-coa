from dataclasses import dataclass, replace
import math

NAME = 'after_window_tick'
ORDER = 41
KEYS = {'wait_ms', 'count_metric', 'expected', 'tolerance', 'min_ticks', 'source', 'hold_aura'}
REQUIRED_KEYS = KEYS - {'hold_aura'}
HOLD_AURA_KEYS = {'actor', 'spell', 'stacks'}


@dataclass(frozen=True)
class AfterWindowTick:
    wait_ms: int
    count_metric: str
    expected: float
    tolerance: float
    min_ticks: int
    source: str
    hold_aura: tuple[str, int, int] | None = None


def finite_number(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value)


def parse(raw) -> AfterWindowTick:
    if not isinstance(raw, dict) or not REQUIRED_KEYS <= set(raw) <= KEYS:
        raise ValueError(f'after_window_tick is {sorted(REQUIRED_KEYS)} with optional hold_aura, not {raw!r}')
    if (type(raw['wait_ms']) is not int or raw['wait_ms'] <= 0
            or not isinstance(raw['count_metric'], str) or not raw['count_metric']
            or not finite_number(raw['expected']) or raw['expected'] <= 0
            or not finite_number(raw['tolerance']) or raw['tolerance'] < 0
            or type(raw['min_ticks']) is not int or raw['min_ticks'] < 1
            or not isinstance(raw['source'], str) or not raw['source'].strip()):
        raise ValueError(f'after_window_tick has invalid field values: {raw!r}')
    hold_aura = None
    if 'hold_aura' in raw:
        aura = raw['hold_aura']
        if (not isinstance(aura, dict) or set(aura) != HOLD_AURA_KEYS
                or not isinstance(aura['actor'], str) or not aura['actor']
                or type(aura['spell']) is not int or aura['spell'] <= 0
                or type(aura['stacks']) is not int or aura['stacks'] < 0):
            raise ValueError(f'after_window_tick hold_aura is {{actor, spell > 0, stacks >= 0}}, not {aura!r}')
        hold_aura = (aura['actor'], aura['spell'], aura['stacks'])
    return AfterWindowTick(raw['wait_ms'], raw['count_metric'], float(raw['expected']), float(raw['tolerance']),
                           raw['min_ticks'], raw['source'], hold_aura)


def check(spec, window: AfterWindowTick | None):
    if window is None:
        return
    from coverage import READBACK, metric_evidence
    from profile import CASTER
    from values import TARGET
    if spec.expiry_wait_ms is not None or spec.attack_swings:
        raise ValueError(f'{spec.spell} after_window_tick runs after a cast after-reading without expiry or swings')
    if window.count_metric == spec.metric:
        raise ValueError(f'{spec.spell} after_window_tick count_metric must differ from {spec.metric}')
    evidence = metric_evidence().get(window.count_metric)
    if evidence is None or evidence == READBACK:
        raise ValueError(f'{spec.spell} after_window_tick count_metric {window.count_metric!r} needs a non-readback '
                         f'METRIC_EVIDENCE row')
    if window.hold_aura is not None:
        ally = dict(spec.options).get('ally_arm')
        dummy = spec.select_dummy or TARGET in (spec.target, spec.measure_actor, spec.fields.get('target'))
        units = {CASTER, *(ally.ally_ids if ally is not None else ()), *((TARGET,) if dummy else ())}
        if window.hold_aura[0] not in units:
            raise ValueError(f'{spec.spell} after_window_tick hold_aura actor {window.hold_aura[0]!r} not in '
                             f'{sorted(units)}')


def labels(spec) -> dict[str, str]:
    from behaviours import metric_delta_label
    base = f'{metric_delta_label(spec, "after")} {NAME}'
    return {'start_total': f'{base} start total', 'start_count': f'{base} start count',
            'end_total': f'{base} end total', 'end_count': f'{base} end count',
            'hold_aura': f'{base} hold aura'}


def fixtures(class_file: dict, spec, window: AfterWindowTick, scenario: dict):
    from behaviours import METRIC_DELTA_UNTIMED_WAIT_MS, metric_delta_label
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import measurement
    names = labels(spec)
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    insert_at = after + 1
    while insert_at < len(steps) and steps[insert_at].get('action') == 'assert':
        insert_at += 1
    added = [
        measurement(names['start_total'], spec.measure_actor, spec.metric, **spec.fields),
        measurement(names['start_count'], spec.measure_actor, window.count_metric, **spec.fields),
        {'action': 'wait', 'label': 'after window tick wait', 'ms': window.wait_ms},
        measurement(names['end_total'], spec.measure_actor, spec.metric, **spec.fields),
        measurement(names['end_count'], spec.measure_actor, window.count_metric, **spec.fields),
    ]
    if window.hold_aura is not None:
        actor, spell, _ = window.hold_aura
        added.append(measurement(names['hold_aura'], actor, 'aura_stacks', spell=spell))
    scenario['steps'] = steps[:insert_at] + added + steps[insert_at:]
    waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
    if 'timeout_ms' in scenario or waited > METRIC_DELTA_UNTIMED_WAIT_MS:
        timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)
    hold_text = (f' while {window.hold_aura[0]} holds {window.hold_aura[2]} stacks of {window.hold_aura[1]}'
                 if window.hold_aura is not None else '')
    scenario['contract'] += (f' After-window tick check: right after the after reading, {spec.metric} and '
                             f'{window.count_metric} are read before and after a {window.wait_ms} ms wait'
                             f'{hold_text}; at least {window.min_ticks} tick(s) must land and the per-tick mean '
                             f'must match {window.expected:g} within {window.tolerance:g} ({window.source}).')


def model(spec, window: AfterWindowTick) -> dict:
    names = labels(spec)
    entry = {'wait_ms': window.wait_ms, 'count_metric': window.count_metric, 'expected': window.expected,
             'tolerance': window.tolerance, 'min_ticks': window.min_ticks, 'source': window.source,
             'start_total': names['start_total'], 'start_count': names['start_count'],
             'end_total': names['end_total'], 'end_count': names['end_count']}
    if window.hold_aura is not None:
        entry['hold_aura'] = {'actor': window.hold_aura[0], 'spell': window.hold_aura[1],
                              'stacks': window.hold_aura[2], 'label': names['hold_aura']}
    return {NAME: entry}


def verdict(verdict, run, window: dict):
    from compare import missing_measurement
    if verdict.status == 'unmeasured':
        return verdict
    needed = [window['start_total'], window['start_count'], window['end_total'], window['end_count']]
    if 'hold_aura' in window:
        needed.append(window['hold_aura']['label'])
    missing = next((label for label in needed if run.values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured',
                       explanation=f'{verdict.explanation}; after_window_tick: {missing_measurement(run, missing)}')
    notes = []
    off = False
    if 'hold_aura' in window:
        hold = window['hold_aura']
        stacks = run.values[hold['label']]
        if abs(stacks - hold['stacks']) > 1e-6:
            off = True
            notes.append(f'hold aura {hold["spell"]} on {hold["actor"]} read {stacks:g} stacks '
                         f'(expected {hold["stacks"]})')
        else:
            notes.append(f'hold aura {hold["spell"]} on {hold["actor"]} stayed at {stacks:g} stacks')
    ticks = run.values[window['end_count']] - run.values[window['start_count']]
    gain = run.values[window['end_total']] - run.values[window['start_total']]
    if ticks <= 0:
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; after_window_tick: {ticks:g} ticks landed '
                                   f'(expected at least {window["min_ticks"]}) ({window["source"]})')
    if ticks < window['min_ticks']:
        return replace(verdict, status='alert' if off or verdict.status == 'alert' else 'unmeasured',
                       explanation=f'{verdict.explanation}; after_window_tick: only {ticks:g} tick(s) landed, '
                                   f'below min_ticks {window["min_ticks"]} ({window["source"]})')
    per_tick = gain / ticks
    held = abs(per_tick - window['expected']) <= window['tolerance']
    off = off or not held
    notes.append(f'per-tick mean {gain:g} / {ticks:g} = {per_tick:.4g} (expected {window["expected"]:g} '
                 f'+- {window["tolerance"]:g}): {"ok" if held else "off"} ({window["source"]})')
    return replace(verdict, status='alert' if off else verdict.status,
                   explanation=f'{verdict.explanation}; after_window_tick: {"; ".join(notes)}')
