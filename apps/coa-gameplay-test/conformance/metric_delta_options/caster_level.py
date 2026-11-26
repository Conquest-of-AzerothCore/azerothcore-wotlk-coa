from dataclasses import replace
import re

NAME = 'caster_level'
ORDER = 11
MAX_LEVEL = 60
LEVEL_WORDS = re.compile(r'\blevel\b', re.IGNORECASE)


def parse(raw) -> int:
    if type(raw) is not int or not 1 <= raw <= MAX_LEVEL:
        raise ValueError(f'caster_level is an integer level from 1 to {MAX_LEVEL}, not {raw!r}')
    return raw


def check(spec, level):
    if level is None:
        return
    present = dict(spec.options)
    if 'phase_caster_level' in present:
        raise ValueError(f'{spec.spell} cannot set both caster_level and phase_caster_level')
    if 'shifted_control' in present:
        raise ValueError(f'{spec.spell} sets shifted_control; use shifted_control.caster_level instead')
    if LEVEL_WORDS.search(spec.quote) is None:
        raise ValueError(f'{spec.spell} caster_level requires the word "level" in the claim quote (G-32)')


def label(spec, phase: str) -> str:
    return ' '.join(str(part) for part in (spec.spell, NAME, spec.label_suffix, phase) if part)


def fixtures(class_file: dict, spec, level: int, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    if level >= class_file['level']:
        raise ValueError(f'{spec.spell} caster_level {level} must be below class level {class_file["level"]} (G-32)')
    scenario['players'][0]['level'] = level
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    steps.insert(after, measurement(label(spec, 'after'), CASTER, 'level'))
    before = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'before'))
    steps.insert(before, measurement(label(spec, 'before'), CASTER, 'level'))
    scenario['contract'] += (
        f' The caster starts at level {level} (below class level {class_file["level"]}, G-32) before any learn step '
        f'so passive aura amounts compute at level {level} when learned; the caster level is read before both phase '
        f'measurements and any missing or differing level voids the trial.')


def model(spec, level: int) -> dict:
    return {NAME: {'level': level, 'before_label': label(spec, 'before'), 'after_label': label(spec, 'after')}}


def verdict(verdict, run, caster_level: dict):
    expected = caster_level['level']
    labels = (caster_level['before_label'], caster_level['after_label'])
    missing = next((name for name in labels if run.values.get(name) is None), None)
    if missing is not None:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; {missing} was not read')
    before, after = (run.values[name] for name in labels)
    if before != expected or after != expected:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; caster level read {before:g} before and {after:g} after, '
                                   f'not {expected}: trial void')
    return replace(verdict, explanation=f'{verdict.explanation}; caster level {before:g} before and {after:g} after '
                                        f'(G-32)')
