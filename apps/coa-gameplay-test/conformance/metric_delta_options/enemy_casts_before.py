NAME = 'enemy_casts_before'
ORDER = 30
SETTLE_MS = 500


def parse(raw) -> list[int]:
    if not isinstance(raw, list) or not raw or not all(type(spell) is int and spell > 0 for spell in raw) \
            or len(set(raw)) != len(raw):
        raise ValueError(f'enemy_casts_before is a non-empty list of distinct spell ids, not {raw!r}')
    return list(raw)


def check(spec, spells):
    if spells is not None and not spec.enemy_player_race:
        raise ValueError(f'{spec.spell} enemy_casts_before needs the enemy player')


def phase_steps(spec, spells: list[int], after: bool) -> list[dict]:
    from behaviours import ENEMY_PLAYER
    if after:
        return []
    steps = []
    for spell in spells:
        steps += [{'action': 'learn', 'actor': ENEMY_PLAYER, 'spell': spell},
                  {'action': 'cast', 'actor': ENEMY_PLAYER, 'spell': spell, 'target': ENEMY_PLAYER},
                  {'action': 'wait', 'label': f'{spell} settle', 'ms': SETTLE_MS}]
    return steps


def fixtures(class_file: dict, spec, spells: list[int], scenario: dict):
    scenario['contract'] += (f' Once, at the start of the before phase and before any trigger cast, the enemy player '
                             f'learns and casts {spells} at itself (a form or a lasting aura the treatment phase still '
                             f'carries), {SETTLE_MS} ms apart.')
