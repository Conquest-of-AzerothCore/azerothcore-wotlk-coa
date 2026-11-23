import math
from dataclasses import replace

NAME = 'stack_feed'
ORDER = 32
KEYS = {'aura', 'cap', 'window_ms', 'trials', 'source'}
OPTIONAL_KEYS = {'refeed_auras'}
READS = ('count', 'stacks', 'clock')
RESIDUAL_LIMIT = 0.0005
TRIAL_SEPARATION_MS = 1000


def positive_int(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not KEYS <= set(raw) <= KEYS | OPTIONAL_KEYS:
        raise ValueError(f'stack_feed is {{"aura", "cap", "window_ms", "trials", "source"[, "refeed_auras"]}}, '
                         f'not {raw!r}')
    for key in ('aura', 'cap', 'window_ms', 'trials'):
        if not positive_int(raw[key]):
            raise ValueError(f'stack_feed {key} is a positive integer, not {raw[key]!r}')
    if not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError('stack_feed source cites the stack cap and the duration of the aura')
    refeed = raw.get('refeed_auras', [])
    if not isinstance(refeed, list) or not all(
            isinstance(pair, list) and len(pair) == 2 and all(positive_int(value) for value in pair)
            for pair in refeed):
        raise ValueError(f'stack_feed refeed_auras is [[aura, stacks], ...], not {refeed!r}')
    return {**{key: raw[key] for key in KEYS}, 'refeed_auras': tuple(tuple(pair) for pair in refeed)}


def check(spec, value):
    if value is None:
        return
    if spec.metric != 'aura_stacks' or spec.fields.get('spell') != value['aura']:
        raise ValueError(f'{spec.spell} stack_feed reads the aura_stacks of its own aura {value["aura"]}')
    if spec.expected != value['cap'] or spec.before_expected != 0:
        raise ValueError(f'{spec.spell} stack_feed expects the cap {value["cap"]} after and 0 in the control')
    if not spec.setup_casts or spec.attack_swings or spec.gate_timing != 'between' or spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} stack_feed feeds through setup_casts in the plain treatment phase')
    if not 0 < spec.setup_wait_ms < value['window_ms'] or not 0 < spec.wait_ms < value['window_ms']:
        raise ValueError(f'{spec.spell} stack_feed polls inside the {value["window_ms"]} ms window')


def label(spec, trial: int, poll: int, read: str) -> str:
    return f'{spec.spell} stack_feed t{trial} p{poll} {read}'


def poll_steps(spec, value: dict, trial: int, poll: int) -> list[dict]:
    from behaviours import CASTER
    from profile import measurement
    return [measurement(label(spec, trial, poll, 'count'), spec.measure_actor, 'aura_apply_count',
                        spell=value['aura']),
            measurement(label(spec, trial, poll, 'stacks'), spec.measure_actor, spec.metric, **spec.fields),
            measurement(label(spec, trial, poll, 'clock'), CASTER, 'game_time_ms')]


def refeed_steps(value: dict) -> list[dict]:
    from behaviours import CASTER
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
            for aura, stacks in value['refeed_auras']]


def polls(spec) -> int:
    return len(spec.setup_casts) + 1


def phase_steps(spec, value: dict, after: bool) -> list[dict]:
    return poll_steps(spec, value, 1, 0) if after else []


def setup_cast_steps(spec, value: dict, index: int, after: bool) -> list[dict]:
    if not after:
        return []
    return refeed_steps(value) + poll_steps(spec, value, 1, index + 1)


def relabeled(step: dict, spec, trial: int) -> dict:
    prefix = f'{spec.spell} stack_feed t1 '
    found = step.get('label')
    if isinstance(found, str) and found.startswith(prefix):
        return {**step, 'label': f'{spec.spell} stack_feed t{trial} {found[len(prefix):]}'}
    return step


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, metric_delta_label
    from metric_delta_options.monotone import EXPIRE_WAIT_LABEL
    steps = scenario['steps']
    after_label = metric_delta_label(spec, AFTER)
    after = next(index for index, step in enumerate(steps) if step.get('label') == after_label)
    final = poll_steps(spec, value, 1, polls(spec))
    steps = steps[:after + 1] + final + steps[after + 1:]
    start = max(index for index, step in enumerate(steps[:after]) if step.get('label') == EXPIRE_WAIT_LABEL)
    block = steps[start:after + 1 + len(final)]
    separation = value['window_ms'] + TRIAL_SEPARATION_MS
    added = []
    for trial in range(2, value['trials'] + 1):
        for step in block:
            if step.get('label') == after_label:
                continue
            if step.get('label') == EXPIRE_WAIT_LABEL:
                step = {**step, 'ms': max(step['ms'], separation)}
            added.append(relabeled(step, spec, trial))
    end = after + 1 + len(final)
    scenario['steps'] = steps[:end] + added + steps[end:]
    refeed = (f'; after every feed cast the fixtures {[list(pair) for pair in value["refeed_auras"]]} are set again '
              f'so the feed is not starved' if value['refeed_auras'] else '')
    scenario['contract'] += (
        f' Stack feed: {value["trials"]} treatment trials, each started with {value["aura"]} absent and separated by '
        f'{separation} ms; at the start, after every feed cast and at the end the {spec.measure_actor}\'s '
        f'aura_apply_count of {value["aura"]} (every new stack and refresh), its stacks and the game time are read'
        f'{refeed}. A trial is valid with at least {value["cap"] + 1} counted applications, no span between two '
        f'application brackets or from the last one to the end read of {value["window_ms"]} ms or more, and the aura '
        f'present at the end; an invalid trial is void, never a pass or a fail. A valid trial passes when the most '
        f'stacks read equal the cap {value["cap"]} and no read exceeds it ({value["source"]}); the control arm without '
        f'the talent reads 0. Residual: v^N with v the voided share of the N trials of a run must be at most '
        f'{RESIDUAL_LIMIT:.2%}.')


def model(spec, value: dict) -> dict:
    from behaviours import BEFORE, metric_delta_label
    labels = [[{read: label(spec, trial, poll, read) for read in READS} for poll in range(polls(spec) + 1)]
              for trial in range(1, value['trials'] + 1)]
    return {NAME: {'aura': value['aura'], 'cap': value['cap'], 'window_ms': value['window_ms'],
                   'source': value['source'], 'labels': labels, 'control_label': metric_delta_label(spec, BEFORE)}}


def finite(values: dict, name: str) -> float | None:
    found = values.get(name)
    return float(found) if found is not None and math.isfinite(float(found)) else None


def judged_trial(values: dict, labels: list[dict], cap: int, window: int) -> tuple[str, str, int, float]:
    reads = [{read: finite(values, poll[read]) for read in READS} for poll in labels]
    above = [(poll['stacks'], found['stacks']) for poll, found in zip(labels, reads)
             if found['stacks'] is not None and found['stacks'] > cap]
    if above:
        label, most = max(above, key=lambda pair: pair[1])
        ends = (reads[0]['count'], reads[-1]['count'])
        applications = int(ends[1] - ends[0]) if None not in ends else 0
        return 'alert', f'{label} read {most:g} stacks, above the cap {cap}, before any void check', applications, most
    missing = [poll[read] for poll, found in zip(labels, reads) for read in READS if found[read] is None]
    if missing:
        return 'void', f'{missing[0]} missing', 0, 0.0
    counts = [found['count'] for found in reads]
    stacks = [found['stacks'] for found in reads]
    clocks = [found['clock'] for found in reads]
    applications = int(counts[-1] - counts[0])
    if stacks[0] != 0:
        return 'void', f'{stacks[0]:g} stacks before the first feed cast', applications, 0.0
    if applications < cap + 1:
        return 'void', f'{applications} applications, fewer than {cap + 1}', applications, 0.0
    rises = [index for index in range(1, len(reads)) if counts[index] > counts[index - 1]]
    spans = [clocks[later] - clocks[earlier - 1] for earlier, later in zip(rises, rises[1:])]
    spans.append(clocks[-1] - clocks[rises[-1] - 1])
    if max(spans) >= window:
        return 'void', f'a span of {max(spans):g} ms without a bracketed application (window {window} ms)', \
            applications, 0.0
    if stacks[-1] == 0:
        return 'void', 'the aura is gone at the end read', applications, 0.0
    most = max(stacks)
    text = f'{applications} applications, stacks {"/".join(f"{value:g}" for value in stacks)}, most {most:g}'
    return ('ok' if most == cap else 'alert'), text, applications, most


def verdict(verdict, run, recorded: dict):
    from compare import missing_measurement
    control_label = recorded['control_label']
    control = finite(run.values, control_label)
    if control is None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, control_label))
    cap, window = recorded['cap'], recorded['window_ms']
    trials = [judged_trial(run.values, labels, cap, window) for labels in recorded['labels']]
    voided = sum(status == 'void' for status, *_ in trials)
    total = len(trials)
    share = voided / total
    residual = share ** total
    applications = sum(count for status, _, count, _ in trials if status != 'void')
    casts = (len(recorded['labels'][0]) - 1) * (total - voided)
    rate = f', {applications / casts:.2f} applications per feed cast in valid trials' if casts else ''
    lines = '; '.join(f't{index} {status}: {text}' for index, (status, text, *_) in enumerate(trials, 1))
    summary = (f'control {control:g} (expected 0); {lines}; void rate v = {voided}/{total}, residual v^N = '
               f'{residual:.6f} (limit {RESIDUAL_LIMIT}){rate} ({recorded["source"]})')
    detail = {**(verdict.detail or {}), 'stack_feed': {'voided': voided, 'trials': total, 'residual': residual}}
    statuses = {status for status, *_ in trials}
    if control != 0 or 'alert' in statuses:
        status = 'alert'
    elif 'ok' in statuses:
        status = 'ok'
    else:
        status = 'unmeasured'
    most = max((found for status, _, _, found in trials if status != 'void'), default=None)
    return replace(verdict, status=status, measured=verdict.measured if most is None else most, detail=detail,
                   explanation=summary)
