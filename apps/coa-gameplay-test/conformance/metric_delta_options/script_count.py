from pathlib import Path
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
METRIC_EVIDENCE = {EVIDENCE_METRIC: 'state'}
STATE_PROMISES = {EVIDENCE_METRIC: r'attacks?|charges?|stacks?'}


def parse(raw) -> str:
    if not isinstance(raw, dict) or set(raw) != {'noun'} or raw['noun'] not in NOUNS:
        raise ValueError(f'script_count is {{"noun": one of {list(NOUNS)}}}, not {raw!r}')
    return raw['noun']


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


def spec_refusal(spec, noun: str) -> str | None:
    return stated_count(spec, noun) or counted_read(spec, noun) or plain_layout(spec, noun) or contrast_arm(spec, noun)


def check(spec, noun):
    if noun is None:
        if spec.evidence_metric == EVIDENCE_METRIC:
            raise ValueError(f'{spec.spell} names evidence_metric {EVIDENCE_METRIC} without the {NAME} opt-in')
        return
    refusal = spec_refusal(spec, noun)
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


def fixtures(class_file: dict, spec, noun: str, scenario: dict):
    from behaviours import dataset
    from profile import DBC_DIR
    from tooltip import Records
    refusal = scenario_refusal(spec, scenario['steps'], Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR)))))
    if refusal is not None:
        raise ValueError(f'{spec.spell} {NAME} {refusal}')
    scenario['contract'] += (f' The {READ_METRIC} of aura {read_aura(spec)} is the {noun} count the quote states, '
                             f'driven by real casts only; the before arm reads it with the driving cast '
                             f'{driver(spec)}, so it is judged as {EVIDENCE_METRIC}.')


def model(spec, noun: str) -> dict:
    return {'evidence_metric': EVIDENCE_METRIC,
            NAME: {'noun': noun, 'aura': read_aura(spec), 'driver': driver(spec)}}
