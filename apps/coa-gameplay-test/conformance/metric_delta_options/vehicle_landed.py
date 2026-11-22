from dataclasses import replace

NAME = 'vehicle_landed'
ORDER = 30
PHASES = ('start', 'before', 'after')
_CASTS: dict[int, dict] = {}


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'vehicle_landed is true or absent, not {raw!r}')
    return True


def label(spec, moment: str) -> str:
    return f'{spec.spell} vehicle_landed {spec.strike.spell} applications {moment}'


def check(spec, landed):
    if landed and (spec.strike is None or spec.strike.owned_entry is not None):
        raise ValueError(f'{spec.spell} vehicle_landed needs a strike at the caster, where its aura lands')


def vehicle_casts(spec, steps: list[dict]) -> int:
    from behaviours import STRIKER
    return sum(1 for step in steps if step.get('action') == 'cast' and step.get('actor') == STRIKER
               and step.get('spell') == spec.strike.spell)


def fixtures(class_file: dict, spec, landed: bool, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    labels = [step.get('label') for step in steps]
    before = labels.index(metric_delta_label(spec, 'before'))
    expired = metric_delta_label(spec, 'expired')
    after = labels.index(expired if expired in labels else metric_delta_label(spec, 'after'))
    read = {moment: measurement(label(spec, moment), CASTER, 'aura_apply_count', spell=spec.strike.spell)
            for moment in PHASES}
    scenario['steps'] = (steps[:1] + [read['start']] + steps[1:before + 1] + [read['before']]
                         + steps[before + 1:after + 1] + [read['after']] + steps[after + 1:])
    _CASTS[id(spec)] = {'before': vehicle_casts(spec, steps[1:before + 1]),
                        'after': vehicle_casts(spec, steps[before + 1:after + 1])}
    scenario['contract'] += (f' The applications of the vehicle {spec.strike.spell} on the caster, where its aura '
                             f'lands, are counted at the start, right after the before reading and after the last '
                             f'treatment reading, so no timed reading moves: a phase whose vehicle casts did not '
                             f'all apply their aura is unmeasured, never judged.')


def model(spec, landed: bool) -> dict:
    return {NAME: {'spell': spec.strike.spell, 'casts': _CASTS.pop(id(spec)),
                   'labels': {moment: label(spec, moment) for moment in PHASES}}}


def verdict(verdict, run, landed: dict):
    counts = {moment: run.values.get(name) for moment, name in landed['labels'].items()}
    casts = landed['casts']
    if any(value is None for value in counts.values()):
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the {landed["spell"]} application counts were not read')
    applied = {'before': counts['before'] - counts['start'], 'after': counts['after'] - counts['before']}
    short = [f'{moment} {applied[moment]:g} of {casts[moment]}' for moment in ('before', 'after')
             if applied[moment] < casts[moment]]
    if short:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the vehicle {landed["spell"]} did not land '
                                   f'({", ".join(short)} applications), so the reading is not the effect')
    return replace(verdict, explanation=f'{verdict.explanation}; the vehicle {landed["spell"]} landed '
                                        f'({applied["before"]:g} and {applied["after"]:g} applications)')
