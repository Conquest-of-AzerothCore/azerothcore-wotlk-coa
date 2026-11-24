from dataclasses import replace

NAME = 'use_time_contrast'
ORDER = 25
METRICS = frozenset({'spell_cast_time_ms', 'spell_power_cost'})
STATE_PROMISES = {'spell_cast_time_ms': r'cast time|instant|casting time', 'spell_power_cost': r'cost|mana|free'}


def parse(raw) -> tuple[str, ...]:
    if not isinstance(raw, list) or not raw or not all(isinstance(arm, str) and arm for arm in raw) \
            or len(set(raw)) != len(raw):
        raise ValueError(f'use_time_contrast is a list of distinct arm label suffixes, not {raw!r}')
    return tuple(raw)


def arm_label(spec, suffix: str) -> str:
    return f'{spec.spell} behaviour_metric_delta {suffix}'


def check(spec, arms):
    if arms is None:
        return
    if spec.metric not in METRICS:
        raise ValueError(f'{spec.spell} use_time_contrast judges {sorted(METRICS)}, not {spec.metric}')
    if spec.setup_only_after:
        raise ValueError(f'{spec.spell} use_time_contrast needs the learned contrast, not setup_only_after')
    if not spec.label_suffix or spec.label_suffix not in arms:
        raise ValueError(f'{spec.spell} use_time_contrast names its own arm {spec.label_suffix!r} among {list(arms)}')
    if spec.expected_gain is None or spec.after_at_least is not None or spec.after_at_most is not None \
            or spec.expected_ratio is not None:
        raise ValueError(f'{spec.spell} use_time_contrast judges the measured gain against an expected_gain, without '
                         f'an after floor, an after ceiling or a ratio')
    if spec.expected_gain != 0 and (spec.tolerance or 0) >= abs(spec.expected_gain) / 2:
        raise ValueError(f'{spec.spell} use_time_contrast needs a tolerance below half its gain '
                         f'{spec.expected_gain:g}, not {spec.tolerance:g}')


def declared_gain(spec) -> float:
    return float(spec.expected_gain)


def fixtures(class_file: dict, spec, arms: tuple[str, ...], scenario: dict):
    scenario['contract'] += (f' The {spec.metric} read is judged as a learned contrast with the arms '
                             f'{", ".join(arms)} (declared gain {declared_gain(spec):g}).')


def model(spec, arms: tuple[str, ...]) -> dict:
    return {NAME: {'arms': [arm_label(spec, arm) for arm in arms], 'gain': declared_gain(spec)}}


def verdict(verdict, run, contrast: dict):
    return replace(verdict, detail={**(verdict.detail or {}), NAME: contrast})
