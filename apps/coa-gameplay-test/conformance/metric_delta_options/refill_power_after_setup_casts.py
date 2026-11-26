import re

from profile import CASTER

NAME = 'refill_power_after_setup_casts'
ORDER = 28
RESOURCE_CLAIM = re.compile(r'mana|cost|resource|energy|rage|focus|runic|power|regenerat', re.IGNORECASE)
RESOURCE_METRICS = frozenset({'power', 'power_cost', 'spell_power_cost'})


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'power'} or not isinstance(raw['power'], int) \
            or isinstance(raw['power'], bool):
        raise ValueError(f'refill_power_after_setup_casts is {{"power": type}}, not {raw!r}')
    return raw


def check(spec, value):
    if value is None:
        return
    if spec.cast_power is None or not spec.setup_casts:
        raise ValueError(f'{spec.spell} refill_power_after_setup_casts refills to cast_power after each setup cast, '
                         f'which needs both')
    if spec.metric in RESOURCE_METRICS or RESOURCE_CLAIM.search(spec.quote):
        raise ValueError(f'{spec.spell} refill_power_after_setup_casts is refused for a claim about mana, cost or a '
                         f'resource: a refill would feed the measured thing')


def setup_cast_steps(spec, value: dict, index: int, after: bool) -> list[dict]:
    return [{'action': 'set_power', 'actor': CASTER, 'power': value['power'], 'value': spec.cast_power}]


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    scenario['contract'] += (f' The caster power {value["power"]} is set to {spec.cast_power} again after every setup '
                             f'cast, so a setup cast cannot starve a later one; the claim is not about a resource.')


def model(spec, value: dict) -> dict:
    return {NAME: value}
