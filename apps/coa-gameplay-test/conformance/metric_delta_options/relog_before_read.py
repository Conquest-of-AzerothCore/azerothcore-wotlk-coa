from dataclasses import replace

NAME = 'relog_before_read'
ORDER = 31
CONDITION_SECONDS = 15 * 60
PHASES = ('before', 'after')
UNBOUNDED_KEYS = ('min', 'max')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != {'before_offline_s', 'after_offline_s'} or not all(
            type(raw[key]) is int and raw[key] > 0 for key in raw):
        raise ValueError(f'relog_before_read is {{"before_offline_s": s, "after_offline_s": s}} (positive seconds), '
                         f'not {raw!r}')
    if not raw['before_offline_s'] < CONDITION_SECONDS < raw['after_offline_s']:
        raise ValueError(f'relog_before_read offline times straddle {CONDITION_SECONDS} s: the control below, the '
                         f'treatment above, not {raw!r}')
    return dict(raw)


def check(spec, relog):
    if relog is None:
        return
    if spec.trigger_only_after or not spec.cast_in_before or spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} relog_before_read relogs before both judged readings, without an expiry read')
    if spec.measure_actor != 'caster':
        raise ValueError(f'{spec.spell} relog_before_read relogs the caster, so it reads the caster')
    if any(name in ('ratio_to_metric', 'phase_since', 'fields_sum', 'area_sum', 'ring_sum')
           for name, _ in spec.options):
        raise ValueError(f'{spec.spell} relog_before_read divides each reading by its own pre-relog read')


def snapshot_name(phase: str) -> str:
    return f'relog_{phase}'


def stamp_label(spec, phase: str, moment: str) -> str:
    return f'{spec.spell} relog {phase} {moment} game_time'


def fixtures(class_file: dict, spec, relog: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    judged = {metric_delta_label(spec, phase): phase for phase in PHASES}
    steps = []
    for step in scenario['steps']:
        phase = judged.get(step.get('label')) if step.get('action') == 'assert' else None
        if phase is None:
            steps.append(step)
            continue
        read = {key: value for key, value in step.items() if key not in UNBOUNDED_KEYS}
        steps += [{**read, 'action': 'snapshot', 'label': f'{step["label"]} before the relog',
                   'save_as': snapshot_name(phase)},
                  measurement(stamp_label(spec, phase, 'logout'), CASTER, 'game_time_ms'),
                  {'action': 'relog', 'label': f'{phase} relog', 'actor': CASTER,
                   'offline_seconds': relog[f'{phase}_offline_s']},
                  measurement(stamp_label(spec, phase, 'login'), CASTER, 'game_time_ms'),
                  {**step, 'ratio_to': snapshot_name(phase)}]
    scenario['steps'] = steps
    scenario['contract'] += (f' Right before each judged reading the caster is saved and logged out, its stored '
                             f'logout time moved back by {relog["before_offline_s"]} s in the control phase and '
                             f'{relog["after_offline_s"]} s in the treatment phase, and logged in again; each '
                             f'reading is the read after the login divided by the same read before the logout, and '
                             f'the game time the relog itself takes is stamped so it cannot carry the control '
                             f'past {CONDITION_SECONDS} s.')


def model(spec, relog: dict) -> dict:
    return {NAME: {'condition_s': CONDITION_SECONDS, **relog,
                   'stamps': {phase: [stamp_label(spec, phase, 'logout'), stamp_label(spec, phase, 'login')]
                              for phase in PHASES}}}


def verdict(verdict, run, relog: dict):
    spans = {}
    for phase, (logout, login) in relog['stamps'].items():
        if run.values.get(logout) is None or run.values.get(login) is None:
            return replace(verdict, status='unmeasured',
                           explanation=f'{verdict.explanation}; the {phase} relog was not stamped in game time')
        spans[phase] = (run.values[login] - run.values[logout]) / 1000
    offline = {phase: relog[f'{phase}_offline_s'] + spans[phase] for phase in spans}
    text = (f'offline {offline["before"]:g} s in the control phase and {offline["after"]:g} s in the treatment '
            f'phase (stated offline time plus the relog\'s own game time)')
    if not offline['before'] < relog['condition_s'] < offline['after']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; {text}, so the two arms do not straddle '
                                   f'{relog["condition_s"]} s')
    return replace(verdict, explanation=f'{verdict.explanation}; {text}')
