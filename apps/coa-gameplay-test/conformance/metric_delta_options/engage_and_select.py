from dataclasses import dataclass

NAME = 'engage_and_select'
ORDER = 29


@dataclass(frozen=True)
class EngageAndSelect:
    spell: int
    gap_ms: int
    select_before: str
    select_after: str


def parse(raw) -> EngageAndSelect:
    keys = {'spell', 'gap_ms', 'select_before', 'select_after'}
    if not isinstance(raw, dict) or set(raw) != keys or type(raw['spell']) is not int or raw['spell'] < 1 \
            or type(raw['gap_ms']) is not int or raw['gap_ms'] < 0 \
            or not all(isinstance(raw[key], str) for key in ('select_before', 'select_after')) \
            or raw['select_before'] == raw['select_after']:
        raise ValueError(f'engage_and_select is {{"spell": id, "gap_ms": n, "select_before": unit, "select_after": '
                         f'unit}} with two different selected units, not {raw!r}')
    return EngageAndSelect(raw['spell'], raw['gap_ms'], raw['select_before'], raw['select_after'])


def engaged_units(spec) -> list[str]:
    from behaviours import TARGET
    from metric_delta_options.area_dummies import area_dummy_id
    distances = dict(spec.options).get('area_dummies') or ()
    return [area_dummy_id(index) for index in range(len(distances))] + [TARGET]


def check(spec, engage):
    if engage is None:
        return
    units = engaged_units(spec)
    if len(units) < 2:
        raise ValueError(f'{spec.spell} engage_and_select needs area_dummies beside the dummy')
    if engage.select_before not in units or engage.select_after not in units:
        raise ValueError(f'{spec.spell} engage_and_select selects one of {units}')
    if spec.trigger_only_after or not spec.cast_in_before or spec.attack_swings:
        raise ValueError(f'{spec.spell} engage_and_select engages and selects in both phases')


def after_trigger_steps(spec, engage: EngageAndSelect, after: bool) -> list[dict]:
    from profile import CASTER
    selected = engage.select_after if after else engage.select_before
    steps = [{'action': 'select', 'actor': CASTER, 'target': selected}]
    for unit in engaged_units(spec):
        steps += [{'action': 'wait', 'label': f'before engaging {unit}', 'ms': engage.gap_ms},
                  {'action': 'reset_cooldown', 'actor': CASTER, 'spell': engage.spell},
                  {'action': 'cast', 'label': f'engage {unit}', 'actor': CASTER, 'spell': engage.spell,
                   'target': unit}]
    return steps


def fixtures(class_file: dict, spec, engage: EngageAndSelect, scenario: dict):
    units = engaged_units(spec)
    scenario['contract'] += (f' After each trigger cast the caster selects {engage.select_before} in the control '
                             f'phase and {engage.select_after} in the treatment phase, then casts {engage.spell} at '
                             f'{", ".join(units)} ({engage.gap_ms} ms apart, each a real cast with its cooldown '
                             f'reset), so the caster is in combat with every dummy in both phases and only the '
                             f'selection differs.')
