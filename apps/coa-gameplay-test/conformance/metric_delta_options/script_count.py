from pathlib import Path
from typing import NamedTuple
import re

NAME = 'script_count'
ORDER = 26
READ_METRIC = 'aura_script_value'
EVIDENCE_METRIC = 'aura_script_count'
NOUNS = ('attack', 'charge', 'stack')
SETTER = 'set_aura'
DRIVER_ACTIONS = frozenset({'cast', 'learn', 'assert', 'reset_cooldown'})
ABSENT = 'absent'
DIFFERENT = 'different'
METRIC_EVIDENCE = {READ_METRIC: 'readback', EVIDENCE_METRIC: 'state'}
STATE_PROMISES = {EVIDENCE_METRIC: r'attacks?|charges?|stacks?'}
LANDED_METRIC = 'melee_damage_count'
SWING_NOUN = 'attack'


class Counted(NamedTuple):
    noun: str
    swings: int = 0


def parse(raw) -> Counted:
    if not isinstance(raw, dict) or not {'noun'} <= set(raw) <= {'noun', 'swings'} or raw['noun'] not in NOUNS \
            or ('swings' in raw and (type(raw['swings']) is not int or raw['swings'] < 1)):
        raise ValueError(f'script_count is {{"noun": one of {list(NOUNS)}, "swings": a positive swing interval '
                         f'count (optional)}}, not {raw!r}')
    return Counted(raw['noun'], raw.get('swings', 0))


def read_aura(spec) -> int:
    return int(spec.fields.get('spell', 0))


def driver(spec) -> str | None:
    if not spec.cast_in_before or spec.trigger_only_after:
        return ABSENT
    gate = spec.gate_spell if spec.gate_spell is not None else spec.spell
    return DIFFERENT if gate != spec.trigger_spell else None


def stated_count(spec, noun: str) -> str | None:
    if re.search(rf'\$\w+\s+(?:\w+\s+)?{noun}s?\b', spec.quote) is None:
        return f'quote {spec.quote!r} states no $ count of {noun}s'
    return None


def counted_read(spec, noun: str) -> str | None:
    if spec.metric != READ_METRIC or not read_aura(spec):
        return f'reads {READ_METRIC} of a named aura spell, not {spec.metric} {spec.fields}'
    if spec.evidence_metric is not None:
        return f'stamps {EVIDENCE_METRIC} itself, not the entry evidence_metric {spec.evidence_metric}'
    if spec.expected_ratio is not None or spec.after_at_least is not None or spec.after_at_most is not None:
        return 'judges the count exactly, without a ratio, a floor or a ceiling'
    return None


def plain_layout(spec, noun: str) -> str | None:
    if spec.setup_only_after or spec.gate_timing != 'between' or spec.attack_swings or spec.gate_cast \
            or spec.forced_chance is not None or spec.trigger_item is not None:
        return (f'reads the count around a real cast of {spec.trigger_spell} in the plain with/without layout, without '
                f'setup_only_after, a start gate, swings, a gate cast, a forced chance or a trigger item')
    return None


def contrast_arm(spec, noun: str) -> str | None:
    if driver(spec) is None:
        return (f'needs a before arm without the driving cast of {spec.trigger_spell} (cast_in_before false) or with '
                f'it under another gate spell than the trigger')
    gap = abs(spec.expected - spec.before_expected)
    if gap == 0 or (spec.tolerance or 0) >= gap / 2:
        return (f'needs a before reading {spec.before_expected:g} apart from {spec.expected:g} by more than twice its '
                f'tolerance {spec.tolerance or 0:g}')
    return None


def swing_window(spec, counted: Counted) -> str | None:
    if not counted.swings:
        return None
    if counted.noun != SWING_NOUN:
        return f'counts swings only for the noun {SWING_NOUN!r}, not {counted.noun!r}'
    cast_arms = [spec.expected] + ([spec.before_expected] if driver(spec) != ABSENT else [])
    if counted.swings + 1 >= min(cast_arms):
        return (f'swings {counted.swings} intervals, up to {counted.swings + 1} landed attacks, which is not below '
                f'the least counted reading {min(cast_arms):g} of a cast arm, so the aura may end inside the window')
    return None


def spec_refusal(spec, counted: Counted) -> str | None:
    noun = counted.noun
    return (stated_count(spec, noun) or counted_read(spec, noun) or plain_layout(spec, noun)
            or contrast_arm(spec, noun) or swing_window(spec, counted))


def check(spec, counted):
    if counted is None:
        if spec.evidence_metric == EVIDENCE_METRIC:
            raise ValueError(f'{spec.spell} names evidence_metric {EVIDENCE_METRIC} without the {NAME} opt-in')
        return
    refusal = spec_refusal(spec, counted)
    if refusal is not None:
        raise ValueError(f'{spec.spell} {NAME} {refusal}')


def named_aura(spec, records) -> str | None:
    aura = read_aura(spec)
    name = records.field('Spell', aura, 'SpellName[enUS]')
    if aura != spec.spell and (not name or name not in spec.quote):
        return f'reads aura {aura} ({name!r}), which is neither the entry spell nor named in the quote'
    return None


def no_setter(spec, steps: list[dict]) -> str | None:
    aura = read_aura(spec)
    for step in steps:
        if step.get('action') == SETTER:
            return f'sets aura {step.get("spell")} with {SETTER}: the count is driven by real play only'
        if step.get('spell') == aura and step.get('action') not in DRIVER_ACTIONS:
            return f'writes the read aura {aura} with {step.get("action")}: the count is driven by real play only'
    return None


def real_cast(spec, steps: list[dict]) -> str | None:
    from behaviours import metric_delta_label
    labels = [step.get('label') for step in steps]
    before = labels.index(metric_delta_label(spec, 'before'))
    after = labels.index(metric_delta_label(spec, 'after'))

    def casts(window: list[dict]) -> bool:
        return any(step.get('action') == 'cast' and step.get('spell') == spec.trigger_spell for step in window)

    if not casts(steps[before:after]):
        return f'has no real cast of {spec.trigger_spell} between its before and after readings'
    if driver(spec) == ABSENT and casts(steps[:before]):
        return f'casts {spec.trigger_spell} before its before reading, so the driving cast is not absent'
    return None


def scenario_refusal(spec, steps: list[dict], records) -> str | None:
    return named_aura(spec, records) or no_setter(spec, steps) or real_cast(spec, steps)


def moment(after: bool) -> str:
    return 'after' if after else 'before'


def cast_count_label(label: str) -> str:
    return f'{label} cast count'


def cast_landed_label(label: str) -> str:
    return f'{label} cast landed'


def landed_label(label: str) -> str:
    return f'{label} landed'


def after_trigger_steps(spec, counted: Counted, after: bool) -> list[dict]:
    from behaviours import metric_delta_label
    from profile import measurement
    from values import TARGET
    if not counted.swings:
        return []
    label = metric_delta_label(spec, moment(after))
    return [measurement(cast_count_label(label), spec.measure_actor, spec.metric, **spec.fields),
            measurement(cast_landed_label(label), spec.measure_actor, LANDED_METRIC),
            {'action': 'attack', 'actor': spec.measure_actor, 'target': TARGET},
            {'action': 'wait', 'label': SWING_WAIT_LABEL, 'ms': 0},
            {'action': 'stop_attack', 'actor': spec.measure_actor}]


SWING_WAIT_LABEL = 'counted swings'


def counted_moments(spec) -> tuple[str, ...]:
    return ('after',) if driver(spec) == ABSENT else ('before', 'after')


def swing_fixtures(class_file: dict, spec, counted: Counted, scenario: dict):
    from behaviours import metric_delta_label
    from hits import creature_fixture
    from procs import swing_interval
    from profile import measurement
    judged = {metric_delta_label(spec, name) for name in counted_moments(spec)}
    window = counted.swings * swing_interval(class_file)
    steps = []
    for step in scenario['steps']:
        if step.get('action') == 'wait' and step.get('label') == SWING_WAIT_LABEL:
            step = {**step, 'ms': window}
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            steps.append(measurement(landed_label(step['label']), step['actor'], LANDED_METRIC))
    scenario['steps'] = steps
    scenario.setdefault('creatures', [creature_fixture(class_file)])
    scenario['contract'] += (f' After each real cast of {spec.trigger_spell} the caster reads the count and its '
                             f'{LANDED_METRIC}, auto-attacks the dummy for {counted.swings} swing intervals '
                             f'({window} ms), stops, '
                             f'and reads both again: each counted reading is the count plus the attacks landed since '
                             f'the cast, valid only with at least one landed attack and a count strictly below the '
                             f'one read at the cast, and equal to it (one count per landed attack).')


def fixtures(class_file: dict, spec, counted: Counted, scenario: dict):
    from behaviours import dataset
    from profile import DBC_DIR
    from tooltip import Records
    refusal = scenario_refusal(spec, scenario['steps'], Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR)))))
    if refusal is not None:
        raise ValueError(f'{spec.spell} {NAME} {refusal}')
    scenario['contract'] += (f' The {READ_METRIC} of aura {read_aura(spec)} is the {counted.noun} count the quote '
                             f'states, driven by real casts only; the before arm reads it with the driving cast '
                             f'{driver(spec)}, so it is judged as {EVIDENCE_METRIC}.')
    if counted.swings:
        swing_fixtures(class_file, spec, counted, scenario)


def model(spec, counted: Counted) -> dict:
    found = {'noun': counted.noun, 'aura': read_aura(spec), 'driver': driver(spec)}
    if counted.swings:
        from behaviours import metric_delta_label
        found['swings'] = {'count': counted.swings,
                           'readings': [metric_delta_label(spec, name) for name in counted_moments(spec)]}
    return {'evidence_metric': EVIDENCE_METRIC, NAME: found}


def counted_reading(values: dict, label: str) -> float | None:
    reads = [values.get(name) for name in (label, cast_count_label(label), cast_landed_label(label),
                                           landed_label(label))]
    if None in reads:
        return None
    count, cast_count, cast_landed, landed = reads
    gained = landed - cast_landed
    if gained < 1 or count >= cast_count or count + gained != cast_count:
        return None
    return count + gained


def run_values(values: dict, found: dict) -> dict:
    swings = found.get('swings')
    if swings is None:
        return values
    out = dict(values)
    for label in swings['readings']:
        out[label] = counted_reading(values, label)
    return {label: value for label, value in out.items() if value is not None}
