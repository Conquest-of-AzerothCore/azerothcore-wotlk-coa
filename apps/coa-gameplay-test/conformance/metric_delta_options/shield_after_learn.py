from dataclasses import replace

NAME = 'shield_after_learn'
ORDER = 20
METRIC_EVIDENCE = {'knows_spell': 'state'}
STATE_PROMISES = {'knows_spell': r'teach\w*|learn\w*'}
KEYS = frozenset({'item', 'slot', 'rejected_before'})


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS or not isinstance(raw['item'], int) \
            or not isinstance(raw['slot'], int) or not isinstance(raw['rejected_before'], bool):
        raise ValueError(f'shield_after_learn is {{item, slot, rejected_before}} with an integer item and slot and a '
                         f'boolean rejected_before, not {raw!r}')
    return raw


def before_label(spec) -> str:
    return f'{spec.spell} shield before'


def after_label(spec) -> str:
    return f'{spec.spell} shield after'


def phase_steps(spec, shield: dict, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    item, slot = shield['item'], shield['slot']
    label = after_label(spec) if after else before_label(spec)
    if after and not shield['rejected_before']:
        return [measurement(label, CASTER, 'equipped_item', slot=slot)]
    steps = [{'action': 'add_item', 'actor': CASTER, 'item': item} if not after else None,
             {'action': 'equip', 'actor': CASTER, 'item': item, 'slot': slot,
              **({'rejected': True} if not after and shield['rejected_before'] else {})},
             measurement(label, CASTER, 'equipped_item', slot=slot)]
    return [step for step in steps if step is not None]


def model(spec, shield: dict) -> dict:
    return {NAME: {'before_label': before_label(spec), 'after_label': after_label(spec), 'item': shield['item'],
                   'refused_before': shield['rejected_before']}}


def verdict(verdict, run, shield: dict):
    before, after = run.values.get(shield['before_label']), run.values.get(shield['after_label'])
    if before is None or after is None:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the shield slot was not read in both phases')
    equipped_before = before == shield['item']
    if equipped_before == shield['refused_before'] or after != shield['item']:
        wanted = 'not the shield' if shield['refused_before'] else str(shield['item'])
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; the shield slot read {before:g} before and {after:g} '
                                   f'after, not {wanted} and {shield["item"]}')
    return verdict
