from dataclasses import dataclass

NAME = 'use_gameobject_after'
ORDER = 33
MAX_USES = 50
KEYS = frozenset({'entry', 'uses', 'gap_ms', 'destroy_item', 'lead_ms', 'user'})
USERS = ('caster', 'ally')
METRIC_EVIDENCE = {'owned_gameobject_count': 'event', 'gameobject_remaining_ms': 'state'}
STATE_PROMISES = {'gameobject_remaining_ms': r'lasts?|duration'}


@dataclass(frozen=True)
class GameObjectUses:
    entry: int
    uses: int
    gap_ms: int
    destroy_item: int | None
    lead_ms: int
    user: str = 'caster'


def parse(raw) -> GameObjectUses:
    valid = (isinstance(raw, dict) and {'entry', 'uses', 'gap_ms'} <= set(raw) <= KEYS
             and all(type(raw[key]) is int for key in raw if key != 'user') and raw['entry'] > 0
             and raw.get('user', 'caster') in USERS
             and 1 <= raw['uses'] <= MAX_USES and raw['gap_ms'] >= 0 and raw.get('destroy_item', 1) > 0
             and raw.get('lead_ms', 0) >= 0)
    if not valid:
        raise ValueError(f'use_gameobject_after is {{"entry": id, "uses": 1-{MAX_USES}, "gap_ms": n, optional '
                         f'"destroy_item": id, "lead_ms": n and "user": one of {USERS}}}, not {raw!r}')
    return GameObjectUses(raw['entry'], raw['uses'], raw['gap_ms'], raw.get('destroy_item'),
                          raw.get('lead_ms', raw['gap_ms']), raw.get('user', 'caster'))


def check(spec, uses):
    if uses is None:
        return
    if not spec.trigger_only_after:
        raise ValueError(f'{spec.spell} use_gameobject_after uses the object the treatment cast creates, so the '
                         f'control phase casts nothing (trigger_only_after)')
    if uses.user != 'caster' and 'grouped_ally' not in dict(spec.options):
        raise ValueError(f'{spec.spell} use_gameobject_after has the ally use an object of the caster, so it needs '
                         f'grouped_ally')


def after_trigger_steps(spec, uses: GameObjectUses, after: bool) -> list[dict]:
    from profile import CASTER
    if not after:
        return []
    steps = []
    owner = {} if uses.user == CASTER else {'owner': CASTER}
    for index in range(uses.uses):
        steps += [{'action': 'wait', 'label': f'before use {index + 1} of {uses.entry}',
                   'ms': uses.lead_ms if index == 0 else uses.gap_ms},
                  {'action': 'use_gameobject', 'label': f'use {index + 1} of {uses.entry}', 'actor': uses.user,
                   'entry': uses.entry, **owner}]
        if uses.destroy_item is not None:
            steps += [{'action': 'wait', 'label': f'after use {index + 1} of {uses.entry}', 'ms': uses.gap_ms},
                      {'action': 'destroy_item', 'actor': uses.user, 'item': uses.destroy_item}]
    return steps


def fixtures(class_file: dict, spec, uses: GameObjectUses, scenario: dict):
    destroyed = (f', each item {uses.destroy_item} it gives destroyed {uses.gap_ms} ms later so the bags never '
                 f'fill' if uses.destroy_item is not None else '')
    user = 'the caster uses its own' if uses.user == 'caster' else 'the ally uses the caster\'s'
    scenario['contract'] += (f' After the treatment cast {user} gameobject {uses.entry} '
                             f'{uses.uses} times through the client use handler (use_gameobject), the first '
                             f'{uses.lead_ms} ms after the cast and the others {uses.gap_ms} ms apart{destroyed}.')
