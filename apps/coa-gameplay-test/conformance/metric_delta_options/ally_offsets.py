import math

NAME = 'ally_offsets'
ORDER = 26
RELOCATE_STEP_LIMIT_YD = 20.0
MAX_OFFSET_YD = 100.0


def parse(raw) -> tuple[tuple[str, float], ...]:
    from metric_delta_options.ally_arm import ALLY_IDS
    if not isinstance(raw, dict) or not raw or not set(raw) <= set(ALLY_IDS) or any(
            isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value)
            or not 0 < value <= MAX_OFFSET_YD for value in raw.values()):
        raise ValueError(f'ally_offsets is a non-empty object of ally ids {list(ALLY_IDS)} to yards along x, above 0 '
                         f'and at most {MAX_OFFSET_YD:g}, not {raw!r}')
    return tuple((unit, float(raw[unit])) for unit in ALLY_IDS if unit in raw)


def check(spec, offsets):
    if offsets is None:
        return
    from metric_delta_options.ally_arm import NAME as ALLY_ARM
    ally = dict(spec.options).get(ALLY_ARM)
    missing = [unit for unit, _ in offsets if ally is None or unit not in ally.ally_ids]
    if missing:
        raise ValueError(f'{spec.spell} ally_offsets moves {missing}, not grouped allies of its ally_arm')


def relocate_steps(unit: str, distance: float) -> list[dict]:
    steps = []
    remaining = distance
    while remaining > 0:
        chunk = min(remaining, RELOCATE_STEP_LIMIT_YD)
        steps.append({'action': 'relocate', 'actor': unit, 'dx': chunk})
        remaining -= chunk
    return steps


def fixtures(class_file: dict, spec, offsets, scenario: dict):
    steps = scenario['steps']
    grouped = max(index for index, step in enumerate(steps) if step.get('action') == 'group')
    moves = [step for unit, distance in offsets for step in relocate_steps(unit, distance)]
    steps[grouped + 1:grouped + 1] = moves
    placed = ', '.join(f'{unit} {distance:g} yd' for unit, distance in offsets)
    scenario['contract'] += (f' Right after grouping, before either phase, the harness relocates allies along x from '
                             f'the shared spawn ({placed}), in steps of at most {RELOCATE_STEP_LIMIT_YD:g} yd with dz '
                             f'0; the caster stays at the spawn.')


def model(spec, offsets) -> dict:
    return {NAME: dict(offsets)}
