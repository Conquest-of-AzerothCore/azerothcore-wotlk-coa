NAME = 'expiry_below_after'
ORDER = 17


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'expiry_below_after is true, not {raw!r}')
    return raw


def check(spec, value):
    if value is not None and (spec.expiry_wait_ms is None or spec.after_expiry_expected is None
                              or spec.after_at_least is None or spec.after_expiry_expected >= spec.after_at_least):
        raise ValueError(f'{spec.spell} expiry_below_after judges the expired reading below the after reading and at '
                         f'or above after_expiry_expected, which needs expiry_wait_ms and an after_at_least above it')


def fixtures(class_file: dict, spec, value: bool, scenario: dict):
    scenario['contract'] += (f' The expired reading is judged for its direction only: below the after reading and at '
                             f'or above {spec.after_expiry_expected:g}.')


def model(spec, value: bool) -> dict:
    return {NAME: True}
