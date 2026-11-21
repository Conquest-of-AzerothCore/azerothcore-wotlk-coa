from dataclasses import dataclass

NAME = 'dummy_casts_at_caster'
ORDER = 29
MAXIMUM_CASTS = 20
MINIMUM_GAP_MS = 1000


@dataclass(frozen=True)
class DummyCasts:
    spell: int
    casts: int
    gap_ms: int
    lead_ms: int


def parse(raw) -> DummyCasts:
    if not isinstance(raw, dict) or set(raw) != {'spell', 'casts', 'gap_ms', 'lead_ms'} \
            or any(type(raw[key]) is not int for key in raw):
        raise ValueError(f'dummy_casts_at_caster is {{"spell", "casts", "gap_ms", "lead_ms"}} of whole numbers, not '
                         f'{raw!r}')
    value = DummyCasts(raw['spell'], raw['casts'], raw['gap_ms'], raw['lead_ms'])
    if value.spell < 1 or not 1 <= value.casts <= MAXIMUM_CASTS or value.gap_ms < MINIMUM_GAP_MS \
            or value.lead_ms < 0:
        raise ValueError(f'dummy_casts_at_caster casts a spell 1 to {MAXIMUM_CASTS} times at least '
                         f'{MINIMUM_GAP_MS} ms apart after a lead of 0 ms or more, not {raw!r}')
    return value


def check(spec, value):
    if value is None:
        return
    from behaviours import TARGET
    if spec.target != TARGET or spec.attack_swings:
        raise ValueError(f'{spec.spell} dummy_casts_at_caster has the trigger\'s dummy cast, so the trigger targets '
                         f'the dummy and is a cast')


def uncast_before(spec) -> bool:
    return spec.trigger_only_after or not spec.cast_in_before


def cast_steps(value: DummyCasts) -> list[dict]:
    from behaviours import TARGET
    from profile import CASTER
    steps = []
    for index in range(value.casts):
        steps += [{'action': 'cast', 'actor': TARGET, 'spell': value.spell, 'target': CASTER, 'triggered': False},
                  {'action': 'wait', 'label': f'dummy cast {index + 1} of {value.casts}', 'ms': value.gap_ms}]
    return steps


def phase_steps(spec, value: DummyCasts, after: bool) -> list[dict]:
    return [] if after or not uncast_before(spec) else cast_steps(value)


def after_trigger_steps(spec, value: DummyCasts, after: bool) -> list[dict]:
    if not after and uncast_before(spec):
        return []
    lead = [{'action': 'wait', 'label': 'before the dummy casts', 'ms': value.lead_ms}] if value.lead_ms else []
    return lead + cast_steps(value)


def fixtures(class_file: dict, spec, value: DummyCasts, scenario: dict):
    scenario['contract'] += (f' In each phase the dummy casts {value.spell} at the caster {value.casts} times, '
                             f'{value.gap_ms} ms apart, as an ordinary cast (no trigger flags, so script hooks that '
                             f'skip triggered casts see it)' +
                             (f', {value.lead_ms} ms after the trigger cast' if value.lead_ms else '') +
                             (' (in the uncast before phase, at the point of the cast)' if uncast_before(spec) else '')
                             + '.')
