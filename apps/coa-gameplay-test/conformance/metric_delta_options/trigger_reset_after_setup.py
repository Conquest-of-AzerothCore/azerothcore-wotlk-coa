from profile import CASTER

NAME = 'trigger_reset_after_setup'
ORDER = 8


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'metric_delta trigger_reset_after_setup is true or absent, not {raw!r}')
    return raw


def check(spec, value):
    if value is None:
        return
    if not spec.setup_casts or spec.attack_swings or spec.trigger_item is not None:
        raise ValueError(f'{spec.spell} trigger_reset_after_setup clears the trigger cooldown its setup casts left, '
                         f'which needs setup casts and a cast trigger')


def setup_cast_steps(spec, value, index: int, after: bool) -> list[dict]:
    if index != len(spec.setup_casts) - 1:
        return []
    return [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell}]


def fixtures(class_file: dict, spec, value, scenario: dict):
    scenario['contract'] += (f' The cooldown of {spec.trigger_spell} is cleared again after the last setup cast, so a '
                             f'setup cast that shares its cooldown does not refuse the trigger cast.')
