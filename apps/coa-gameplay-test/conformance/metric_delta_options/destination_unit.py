NAME = 'destination_unit'
ORDER = 46
UNITS = ('caster', 'dummy')


def parse(raw) -> str:
    if raw not in UNITS:
        raise ValueError(f'destination_unit must be one of {UNITS}, not {raw!r}')
    return raw


def check(spec, destination):
    if destination is None:
        return
    from behaviours import TARGET
    if spec.attack_swings or spec.trigger_item is not None:
        raise ValueError(f'{spec.spell} destination_unit applies to a cast trigger, not attack swings or items')
    if destination == TARGET and not spec.select_dummy and TARGET not in (
            spec.target, spec.measure_actor, spec.fields.get('target')):
        raise ValueError(f'{spec.spell} destination_unit {TARGET!r} needs the dummy in its scenario')


def fixtures(class_file: dict, spec, destination: str, scenario: dict):
    from profile import CASTER
    applied = 0
    for step in scenario['steps']:
        if step.get('action') == 'cast' and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell:
            step['destination_unit'] = destination
            applied += 1
    if not applied:
        raise ValueError(f'{spec.spell} destination_unit found no trigger cast of {spec.trigger_spell}')
    scenario['contract'] += f' Each cast of {spec.trigger_spell} targets the {destination}\'s ground position.'
