import re

from profile import CASTER

NAME = 'hold_power_during_wait'
ORDER = 29
MIN_INTERVAL_MS = 100
RESOURCE_CLAIM = re.compile(r'mana|cost|resource|energy|rage|focus|runic|power|regenerat', re.IGNORECASE)
RESOURCE_METRICS = frozenset({'power', 'power_cost', 'spell_power_cost'})
KEYS = {'power', 'every_ms', 'count'}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS or any(
            isinstance(raw[key], bool) or not isinstance(raw[key], int) for key in KEYS):
        raise ValueError(f'hold_power_during_wait is {{"power": type, "every_ms": N, "count": N}}, not {raw!r}')
    if raw['every_ms'] < MIN_INTERVAL_MS or raw['count'] < 1:
        raise ValueError(f'hold_power_during_wait needs every_ms of at least {MIN_INTERVAL_MS} and a count of at '
                         f'least 1, not {raw!r}')
    return raw


def check(spec, value):
    if value is None:
        return
    if spec.cast_power is None:
        raise ValueError(f'{spec.spell} hold_power_during_wait refills to cast_power, which it needs')
    if spec.metric in RESOURCE_METRICS or RESOURCE_CLAIM.search(spec.quote):
        raise ValueError(f'{spec.spell} hold_power_during_wait is refused for a claim about mana, cost or a '
                         f'resource: a refill would feed the measured thing')


def after_trigger_steps(spec, value: dict, after: bool) -> list[dict]:
    steps = []
    for index in range(value['count']):
        steps += [{'action': 'wait', 'label': f'hold power {index + 1} of {value["count"]}', 'ms': value['every_ms']},
                  {'action': 'set_power', 'actor': CASTER, 'power': value['power'], 'value': spec.cast_power}]
    return steps


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    scenario['contract'] += (f' After each cast of {spec.trigger_spell} the caster power {value["power"]} is set to '
                             f'{spec.cast_power} every {value["every_ms"]} ms, {value["count"]} times, so a '
                             f'per-second power drain of a channel cannot end it early; the reading follows the last '
                             f'refill by wait_ms; the claim is not about a resource.')


def model(spec, value: dict) -> dict:
    return {NAME: value}
