NAME = 'hour'
ORDER = 10
HOURS_PER_DAY = 24


def parse(raw) -> int:
    if isinstance(raw, bool) or not isinstance(raw, int) or not 0 <= raw < HOURS_PER_DAY:
        raise ValueError(f'hour is a realm-local hour from 0 to {HOURS_PER_DAY - 1}, not {raw!r}')
    return raw


def fixtures(class_file: dict, spec, hour: int, scenario: dict):
    scenario['hour'] = hour
    scenario['contract'] += (f' The scenario runs at realm-local hour {hour} (the top-level hour the batch runner '
                             f'sets before the case starts), so a clock-gated effect sees that time of day.')


def model(spec, hour: int) -> dict:
    return {NAME: hour}
