from dataclasses import dataclass, replace

NAME = 'refusable_target_casts'
SPELL_CAST_OK = 255
ORDER = 27
JUDGED_MOMENTS = ('before', 'after')
MAX_SPELL_CAST_RESULT = 254


@dataclass(frozen=True)
class RefusableCasts:
    spells: tuple[int, ...]
    refusal: int
    delay_ms: int


def parse(raw) -> RefusableCasts:
    if not isinstance(raw, dict) or set(raw) != {'spells', 'refusal', 'delay_ms'} \
            or not isinstance(raw['spells'], list) or not raw['spells'] \
            or not all(type(spell) is int and spell > 0 for spell in raw['spells']) \
            or len(set(raw['spells'])) != len(raw['spells']) \
            or type(raw['refusal']) is not int or not 1 <= raw['refusal'] <= MAX_SPELL_CAST_RESULT \
            or type(raw['delay_ms']) is not int or raw['delay_ms'] < 0:
        raise ValueError(f'refusable_target_casts is {{"spells": [distinct ids], "refusal": SpellCastResult 1..'
                         f'{MAX_SPELL_CAST_RESULT}, "delay_ms": n}}, not {raw!r}')
    return RefusableCasts(tuple(raw['spells']), raw['refusal'], raw['delay_ms'])


def check(spec, casts):
    if casts is None:
        return
    from behaviours import TARGET
    if spec.target != TARGET or spec.attack_swings or spec.target_casts or not spec.cast_in_before \
            or spec.gate_timing != 'between' or spec.trigger_only_after:
        raise ValueError(f'{spec.spell} refusable_target_casts needs the dummy as the trigger target, a trigger cast in '
                         f'both phases (cast_in_before, gate_timing between) and no target_casts')


def after_trigger_steps(spec, casts: RefusableCasts, after: bool) -> list[dict]:
    from behaviours import TARGET
    steps = [{'action': 'wait', 'label': 'before the dummy casts', 'ms': casts.delay_ms}]
    for spell in casts.spells:
        steps.append({'action': 'cast', 'label': f'the dummy casts {spell}, refusal {casts.refusal} allowed',
                      'actor': TARGET, 'spell': spell, 'target': TARGET, 'allowed_refusal': casts.refusal})
    return steps


def result_label(label: str, spell: int) -> str:
    return f'{label} cast result {spell}'


def fixtures(class_file: dict, spec, casts: RefusableCasts, scenario: dict):
    from behaviours import TARGET, metric_delta_label
    from profile import measurement
    judged = {metric_delta_label(spec, moment) for moment in JUDGED_MOMENTS}
    steps = []
    for step in scenario['steps']:
        steps.append(step)
        if step.get('action') == 'assert' and step.get('label') in judged:
            steps += [measurement(result_label(step['label'], spell), TARGET, 'creature_cast_result', spell=spell)
                      for spell in casts.spells]
    scenario['steps'] = steps
    scenario['contract'] += (f' {casts.delay_ms} ms after each trigger cast the dummy casts {list(casts.spells)} at '
                             f'itself (triggered); a refusal with SpellCastResult {casts.refusal} is accepted and '
                             f'recorded, any other refusal fails the scenario. The result of each cast is read after '
                             f'each judged reading.')


def model(spec, casts: RefusableCasts) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {'refusal': casts.refusal,
                   'results': {moment: [result_label(metric_delta_label(spec, moment), spell)
                                        for spell in casts.spells] for moment in JUDGED_MOMENTS}}}


def verdict(verdict, run, casts: dict):
    readings = {moment: [run.values.get(label) for label in labels] for moment, labels in casts['results'].items()}
    if any(value is None for values in readings.values() for value in values):
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; a dummy cast result is '
                                                                 f'missing')
    if any(value != SPELL_CAST_OK for value in readings['before']):
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the control phase dummy cast was refused '
                                   f'({readings["before"]}), so the control is not the stated arm')
    results = ', '.join(f'{value:g}' for value in readings['after'])
    return replace(verdict, explanation=f'{verdict.explanation}; dummy cast results: control {SPELL_CAST_OK} (cast OK), treatment {results} '
                                        f'(refusal {casts["refusal"]} allowed)')
