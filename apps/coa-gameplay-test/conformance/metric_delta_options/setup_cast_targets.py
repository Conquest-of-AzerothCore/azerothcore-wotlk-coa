NAME = 'setup_cast_targets'
ORDER = 26
UNITS = ('caster', 'dummy', 'enemy', 'corpse')


def parse(raw) -> tuple[str, ...]:
    if not isinstance(raw, list) or not raw or any(target not in UNITS for target in raw):
        raise ValueError(f'setup_cast_targets is a non-empty list of {" or ".join(UNITS)}, one per setup cast, '
                         f'not {raw!r}')
    return tuple(raw)


def check(spec, value):
    if value is None:
        return
    if len(value) != len(spec.setup_casts) or spec.setup_target is not None or spec.gate_cast or spec.attack_swings:
        raise ValueError(f'{spec.spell} setup_cast_targets names one target per setup cast, without setup_target, '
                         f'gate_cast or attack_swings')


def setup_cast_target(spec, targets, index: int) -> str:
    return targets[index]


def fixtures(class_file: dict, spec, targets, scenario: dict):
    scenario['contract'] += (' The setup casts are made at their own targets: '
                             + ', '.join(f'{spell} at the {target}' for spell, target in zip(spec.setup_casts, targets))
                             + '.')
