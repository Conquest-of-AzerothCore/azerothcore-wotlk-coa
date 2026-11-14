from dataclasses import replace

NAME = 'strike_landed'
ORDER = 6


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'strike_landed is true or absent, not {raw!r}')
    return True


def log_label(spec) -> str:
    return f'{spec.spell} strike_landed {spec.strike.spell} damage logs'


def check(spec, landed):
    if landed and (spec.strike is None or spec.strike.owned_entry is None):
        raise ValueError(f'{spec.spell} strike_landed needs a strike at an owned creature')


def fixtures(class_file: dict, spec, landed: bool, scenario: dict):
    from behaviours import STRIKER, metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    read = measurement(log_label(spec), CASTER, 'spell_log_count', spell=spec.strike.spell, caster=STRIKER)
    scenario['steps'] = steps[:after + 1] + [read] + steps[after + 1:]
    scenario['contract'] += (f' Right after the after reading, the damage logs of the striker\'s {spec.strike.spell} '
                             f'are counted: a strike that misses or is dodged, parried or blocked logs none, so at '
                             f'least one must have landed for the reading to be the effect.')


def model(spec, landed: bool) -> dict:
    return {NAME: {'spell': spec.strike.spell, 'log_label': log_label(spec)}}


def verdict(verdict, run, landed: dict):
    logs = run.values.get(landed['log_label'])
    if logs is None or logs < 1:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; no {landed["spell"]} strike landed ({logs} damage logs: '
                                   f'missed, dodged, parried or blocked), so the reading is not the effect')
    return replace(verdict, explanation=f'{verdict.explanation}; {logs:g} {landed["spell"]} strikes landed')
