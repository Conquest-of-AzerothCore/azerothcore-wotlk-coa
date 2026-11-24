NAME = 'without_item'
ORDER = 13
KEYS = {'item', 'source'}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS or isinstance(raw['item'], bool) \
            or not isinstance(raw['item'], int) or raw['item'] <= 0 or not isinstance(raw['source'], str) \
            or len(raw['source'].strip()) < 20:
        raise ValueError(f'without_item is {{"item": item id, "source": text}}, a positive item id and a source of at '
                         f'least 20 characters citing the DBC equipment requirement and the failure code, not {raw!r}')
    return dict(raw)


def check(spec, option):
    if option is None:
        return
    if spec.metric != 'cast_failure' or spec.fields.get('spell') != spec.trigger_spell or not spec.cast_in_before:
        raise ValueError(f'{spec.spell} without_item judges the cast_failure of its own trigger cast in both phases '
                         f'(cast_in_before true): the first with the item, the second without it')


def is_trigger_cast(spec, step: dict) -> bool:
    from profile import CASTER
    return step.get('action') == 'cast' and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell


def fixtures(class_file: dict, spec, option: dict, scenario: dict):
    from profile import CASTER
    steps = scenario['steps']
    casts = [index for index, step in enumerate(steps) if is_trigger_cast(spec, step)]
    equipped = [step for step in steps if step.get('action') == 'equip' and step.get('item') == option['item']]
    if len(casts) != 2 or not equipped or min(casts) < steps.index(equipped[0]):
        raise ValueError(f'{spec.spell} without_item needs two casts of {spec.trigger_spell} after the equip of item '
                         f'{option["item"]}, finds {len(casts)} casts and {len(equipped)} equips')
    scenario['steps'] = [*steps[:casts[1]], {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                         {'action': 'destroy_item', 'actor': CASTER, 'item': option['item']}, *steps[casts[1]:]]
    scenario['contract'] += (f' Right before the second cast of {spec.trigger_spell} its cooldown is reset (the harness '
                             f'reset_cooldown step, so the first cast\'s cooldown cannot refuse it first) and the '
                             f'equipped item {option["item"]} is destroyed (the harness destroy_item step); the first '
                             f'cast, with the item, is the control ({option["source"]}).')


def model(spec, option: dict) -> dict:
    return {NAME: option}
