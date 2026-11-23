from dataclasses import dataclass
from pathlib import Path

NAME = 'after_trigger_casts'
ORDER = 28
UNITS = ('caster', 'dummy')


@dataclass(frozen=True)
class AfterTriggerCast:
    spell: int
    target: str
    destination_unit: str | None
    delay_ms: int
    in_before: bool = False
    reset_cooldown: bool = True


def parse(raw) -> tuple[AfterTriggerCast, ...]:
    if not isinstance(raw, list) or not raw:
        raise ValueError(f'after_trigger_casts is a non-empty list of casts, not {raw!r}')
    casts = []
    for item in raw:
        if not isinstance(item, dict) or not {'spell', 'delay_ms'} <= set(item) \
                or set(item) - {'spell', 'target', 'destination_unit', 'delay_ms', 'in_before', 'reset_cooldown'} \
                or type(item['spell']) is not int or item['spell'] < 1 \
                or type(item['delay_ms']) is not int or item['delay_ms'] < 0 \
                or item.get('target', 'caster') not in UNITS \
                or item.get('destination_unit', 'caster') not in UNITS \
                or type(item.get('in_before', False)) is not bool \
                or type(item.get('reset_cooldown', True)) is not bool:
            raise ValueError(f'after_trigger_casts item is {{"spell": id, "delay_ms": n, optional "target" and '
                             f'"destination_unit" of {UNITS}, optional booleans "in_before" and '
                             f'"reset_cooldown"}}, not {item!r}')
        casts.append(AfterTriggerCast(item['spell'], item.get('target', 'caster'), item.get('destination_unit'),
                                      item['delay_ms'], item.get('in_before', False),
                                      item.get('reset_cooldown', True)))
    return tuple(casts)


def check(spec, casts):
    if casts is None:
        return
    from behaviours import TARGET
    units = {unit for cast in casts for unit in (cast.target, cast.destination_unit) if unit is not None}
    if TARGET in units and TARGET not in (spec.target, spec.measure_actor, spec.fields.get('target')):
        raise ValueError(f'{spec.spell} after_trigger_casts names the dummy without the dummy in its scenario')
    if spec.attack_swings:
        raise ValueError(f'{spec.spell} after_trigger_casts follows a trigger cast, not attack swings')
    if any(cast.in_before for cast in casts) and (not spec.cast_in_before or spec.trigger_only_after):
        raise ValueError(f'{spec.spell} after_trigger_casts repeats a cast in the control phase only when that phase '
                         f'casts the trigger')


def cast_label(cast: AfterTriggerCast) -> str:
    return f'after the trigger, cast {cast.spell}'


def after_trigger_steps(spec, casts: tuple[AfterTriggerCast, ...], after: bool) -> list[dict]:
    from profile import CASTER
    steps = []
    for cast in casts:
        if not after and not cast.in_before:
            continue
        step = {'action': 'cast', 'label': cast_label(cast), 'actor': CASTER, 'spell': cast.spell,
                'target': cast.target}
        if cast.destination_unit is not None:
            step['destination_unit'] = cast.destination_unit
        steps.append({'action': 'wait', 'label': f'before the cast of {cast.spell}', 'ms': cast.delay_ms})
        if cast.reset_cooldown:
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': cast.spell})
        steps.append(step)
    return steps


def fixtures(class_file: dict, spec, casts: tuple[AfterTriggerCast, ...], scenario: dict):
    from profile import DBC_DIR
    from tooltip import Records
    from values import dataset, facts_of, required_aura_steps
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    auras = {cast_label(cast): required_aura_steps(facts_of(records, cast.spell)) for cast in casts}
    steps = []
    for step in scenario['steps']:
        if step.get('action') == 'cast' and step.get('label') in auras:
            steps += auras[step['label']]
        steps.append(step)
    scenario['steps'] = steps
    described = '; '.join(f'{cast.spell} at the {cast.target}'
                          + (f' with the {cast.destination_unit}\'s position as its destination'
                             if cast.destination_unit else '') + f' {cast.delay_ms} ms after the previous step'
                          for cast in casts)
    if not any(cast.in_before or not cast.reset_cooldown for cast in casts):
        scenario['contract'] += (f' In the treatment phase only, after the cast of {spec.trigger_spell} the caster '
                                 f'casts {described}, each a real cast with its cooldown reset.')
        return
    phases = '; '.join(f'{cast.spell}: ' + ('both phases' if cast.in_before else 'the treatment phase only')
                       + (', its cooldown reset first' if cast.reset_cooldown else ', its cooldown left running')
                       for cast in casts)
    scenario['contract'] += (f' After the cast of {spec.trigger_spell} the caster casts {described}, each a real '
                             f'cast ({phases}).')
