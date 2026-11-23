from dataclasses import dataclass

NAME = 'dummy_power_after_trigger'
ORDER = 34
MAXIMUM_POWER_INDEX = 6


@dataclass(frozen=True)
class DummyPower:
    power: int
    value: int
    after_ms: int


def parse(raw) -> DummyPower:
    if not isinstance(raw, dict) or set(raw) != {'power', 'value', 'after_ms'} \
            or any(type(raw[key]) is not int for key in raw):
        raise ValueError(f'dummy_power_after_trigger is {{"power", "value", "after_ms"}} of whole numbers, not '
                         f'{raw!r}')
    value = DummyPower(raw['power'], raw['value'], raw['after_ms'])
    if not 0 <= value.power <= MAXIMUM_POWER_INDEX or value.value < 0 or value.after_ms < 0:
        raise ValueError(f'dummy_power_after_trigger sets a power index 0 to {MAXIMUM_POWER_INDEX} to a value of 0 '
                         f'or more after 0 ms or more, not {raw!r}')
    return value


def check(spec, value):
    if value is None:
        return
    from behaviours import TARGET
    if spec.target != TARGET or spec.attack_swings:
        raise ValueError(f'{spec.spell} dummy_power_after_trigger sets the power of the dummy a cast targets')


def uncast_before(spec) -> bool:
    return spec.trigger_only_after or not spec.cast_in_before


def power_step(value: DummyPower) -> dict:
    from behaviours import TARGET
    from profile import CASTER
    return {'action': 'set_power', 'actor': CASTER, 'target': TARGET, 'power': value.power, 'value': value.value}


def phase_steps(spec, value: DummyPower, after: bool) -> list[dict]:
    if after or not uncast_before(spec):
        return []
    return [power_step(value), {'action': 'wait', 'label': 'dummy power window', 'ms': spec.wait_ms}]


def after_trigger_steps(spec, value: DummyPower, after: bool) -> list[dict]:
    if not after and uncast_before(spec):
        return []
    lead = [{'action': 'wait', 'label': 'before the dummy power', 'ms': value.after_ms}] if value.after_ms else []
    return lead + [power_step(value)]


def fixtures(class_file: dict, spec, value: DummyPower, scenario: dict):
    scenario['contract'] += (f' The dummy power {value.power} is set to {value.value} {value.after_ms} ms after each '
                             f'trigger cast (in an uncast before phase at the point of the cast) and read '
                             f'{spec.wait_ms} ms later, so the reading is what the dummy gains in that window.')
