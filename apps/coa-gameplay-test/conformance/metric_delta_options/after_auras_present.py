from dataclasses import replace

NAME = 'after_auras_present'
ORDER = 8


def parse(raw) -> tuple[tuple[int, str], ...]:
    def valid(item) -> bool:
        return (isinstance(item, dict) and set(item) == {'aura', 'source'} and isinstance(item['aura'], int)
                and not isinstance(item['aura'], bool) and item['aura'] > 0 and isinstance(item['source'], str)
                and bool(item['source']))
    if not isinstance(raw, list) or not raw or not all(valid(item) for item in raw) \
            or len({item['aura'] for item in raw}) != len(raw):
        raise ValueError(f'after_auras_present is a non-empty list of distinct {{"aura": id, "source": text}}, not '
                         f'{raw!r}')
    return tuple((item['aura'], item['source']) for item in raw)


def read_label(spec, aura: int) -> str:
    return f'{spec.spell} after_auras_present {aura}'


def fixtures(class_file: dict, spec, present: tuple, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    reads = [measurement(read_label(spec, aura), CASTER, 'aura', spell=aura) for aura, _ in present]
    scenario['steps'] = steps[:after] + reads + steps[after:]
    scenario['contract'] += (' Right before the after reading, the caster must hold '
                             + ', '.join(f'{aura} ({source})' for aura, source in present)
                             + ': a run in which one of them is absent is not the stated arm.')


def model(spec, present: tuple) -> dict:
    return {NAME: {'reads': [[aura, read_label(spec, aura), source] for aura, source in present]}}


def verdict(verdict, run, present: dict):
    for aura, label, source in present['reads']:
        held = run.values.get(label)
        if held is None or held < 1:
            return replace(verdict, status='unmeasured',
                           explanation=f'{verdict.explanation}; the caster did not hold {aura} ({source}) at the '
                                       f'after reading (read {held}), so the reading is not the stated arm')
    return verdict
