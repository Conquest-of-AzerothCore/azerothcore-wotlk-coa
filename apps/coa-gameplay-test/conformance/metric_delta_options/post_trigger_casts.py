from dataclasses import dataclass

NAME = 'post_trigger_casts'
ORDER = 14
MAX_COUNT = 20
MIN_GAP_MS = 1600


@dataclass(frozen=True)
class PostTriggerCasts:
    spell: int
    count: int
    gap_ms: int
    health_pct: int | None


def parse(raw) -> PostTriggerCasts:
    keys = {'spell', 'count', 'gap_ms', 'health_pct'}
    if not isinstance(raw, dict) or not {'spell', 'count'} <= set(raw) <= keys \
            or any(isinstance(raw[key], bool) or not isinstance(raw[key], int) for key in raw):
        raise ValueError(f'post_trigger_casts is {{"spell", "count"[, "gap_ms", "health_pct"]}}, not {raw!r}')
    value = PostTriggerCasts(raw['spell'], raw['count'], raw.get('gap_ms', MIN_GAP_MS), raw.get('health_pct'))
    if not 1 <= value.count <= MAX_COUNT or value.gap_ms < MIN_GAP_MS \
            or (value.health_pct is not None and not 0 < value.health_pct < 100):
        raise ValueError(f'post_trigger_casts needs 1 to {MAX_COUNT} casts at least {MIN_GAP_MS} ms apart (the global '
                         f'cooldown) and a health percent between 1 and 99, not {raw!r}')
    return value


def check(spec, value):
    if value is not None and spec.strike is not None:
        raise ValueError(f'{spec.spell} post_trigger_casts and a strike both use the point right after the trigger')


def after_trigger_steps(spec, value: PostTriggerCasts, after: bool) -> list[dict]:
    from values import fixture_health_step
    from profile import CASTER
    steps = []
    for index in range(value.count):
        if value.health_pct is not None:
            steps.append(fixture_health_step(CASTER, value.health_pct))
        steps += [{'action': 'wait', 'label': f'post cast {index + 1} of {value.count}', 'ms': value.gap_ms},
                  {'action': 'reset_cooldown', 'actor': CASTER, 'spell': value.spell},
                  {'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.cast_power or 0},
                  {'action': 'cast', 'actor': CASTER, 'spell': value.spell, 'target': CASTER}]
    return steps


def fixtures(class_file: dict, spec, value: PostTriggerCasts, scenario: dict):
    scenario['contract'] += (f' After the trigger cast of every phase that casts it, the caster casts {value.spell} '
                             f'on itself {value.count} times {value.gap_ms} ms apart'
                             + (f', its health set to {value.health_pct}% before each' if value.health_pct else '')
                             + '; the reading follows the last cast by wait_ms.')


def model(spec, value: PostTriggerCasts) -> dict:
    return {NAME: {'spell': value.spell, 'count': value.count, 'gap_ms': value.gap_ms}}
