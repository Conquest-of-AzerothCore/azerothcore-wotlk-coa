NAME = 'phase_power_in_uncast_before'
ORDER = 20


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'phase_power_in_uncast_before is true, not {raw!r}')
    return raw


def check(spec, applies):
    if applies is None:
        return
    if spec.phase_power is None or (spec.cast_in_before and not spec.trigger_only_after):
        raise ValueError(f'{spec.spell} sets phase_power_in_uncast_before only with phase_power and a before phase '
                         f'that does not cast the trigger (cast_in_before false or trigger_only_after)')


def phase_steps(spec, applies: bool, after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    power, before, _ = spec.phase_power
    return [{'action': 'set_power', 'actor': CASTER, 'power': power, 'value': before}]


def fixtures(class_file: dict, spec, applies: bool, scenario: dict):
    power, before, _ = spec.phase_power
    scenario['contract'] += (f' The uncast before phase also sets power {power} to {before} (phase_power), so its '
                             f'reading starts from the same value as the after phase\'s cast.')


def model(spec, applies: bool) -> dict:
    return {NAME: True}
