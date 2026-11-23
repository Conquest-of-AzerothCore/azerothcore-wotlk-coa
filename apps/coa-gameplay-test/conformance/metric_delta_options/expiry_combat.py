from dataclasses import replace

NAME = 'expiry_combat'
ORDER = 21


def parse(raw) -> dict:
    wait = raw.get('late_wait_ms') if isinstance(raw, dict) else None
    if not isinstance(raw, dict) or set(raw) != {'late_wait_ms'} or isinstance(wait, bool) \
            or not isinstance(wait, int) or wait <= 0:
        raise ValueError(f'expiry_combat is {{"late_wait_ms": ms}}, not {raw!r}')
    return raw


def check(spec, value):
    if value is not None and (spec.expiry_wait_ms is None or spec.after_expiry_expected is None
                              or dict(spec.options).get('expiry_below_after') is None):
        raise ValueError(f'{spec.spell} expiry_combat needs expiry_wait_ms, after_expiry_expected and '
                         f'expiry_below_after')


def label(spec, name: str) -> str:
    return f'{spec.spell} expiry_combat {name}'


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    expired = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'expired'))
    scenario['steps'] = (steps[:expired] + [measurement(label(spec, 'combat expired'), CASTER, 'combat')]
                         + steps[expired:expired + 1]
                         + [{'action': 'wait', 'label': 'let the stored amount decay again', 'ms': value['late_wait_ms']},
                            measurement(label(spec, 'combat late'), CASTER, 'combat'),
                            measurement(label(spec, 'late'), spec.measure_actor, spec.metric, **spec.fields)]
                         + steps[expired + 1:])
    scenario['contract'] += (f' The caster\'s combat state is read right before the expired reading and again '
                             f'{value["late_wait_ms"]} ms later, with a second reading of {spec.metric}: the decay '
                             f'counts as "while out of combat" only when both combat reads are 0 and the late reading '
                             f'is below the expired one and at or above {spec.after_expiry_expected:g}.')


def model(spec, value: dict) -> dict:
    return {NAME: {'combat_expired': label(spec, 'combat expired'), 'combat_late': label(spec, 'combat late'),
                   'late_label': label(spec, 'late'), 'expired_label': f'{spec.spell} {spec.metric} expired',
                   'floor': spec.after_expiry_expected}}


def verdict(verdict, run, value: dict):
    if verdict.status != 'ok':
        return verdict
    reads = {name: run.values.get(value[name]) for name in ('combat_expired', 'combat_late', 'late_label',
                                                            'expired_label')}
    absent = next((name for name, read in reads.items() if read is None), None)
    if absent is not None:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; no {absent} reading')
    text = (f'; combat {reads["combat_expired"]:g} at the expired reading ({reads["expired_label"]:g}) and '
            f'{reads["combat_late"]:g} at the late one ({reads["late_label"]:g})')
    if reads['combat_expired'] != 0 or reads['combat_late'] != 0:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}{text}: the caster was still '
                                                                 f'in combat, so the decay is not out of combat')
    if not value['floor'] <= reads['late_label'] < reads['expired_label']:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}{text}: no decay out of combat '
                                                            f'(it must fall and stay at or above {value["floor"]:g})')
    return replace(verdict, explanation=f'{verdict.explanation}{text}: the amount fell out of combat')
