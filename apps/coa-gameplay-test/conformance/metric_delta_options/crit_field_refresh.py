from dataclasses import replace

NAME = 'crit_field_refresh'
ORDER = 9
REFRESH_METRIC = 'melee_crit_chance_refreshed'


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'metric_delta crit_field_refresh is true or absent, not {raw!r}')
    return raw


def refresh_label(spec, after: bool) -> str:
    return f'{spec.spell} crit_field_refresh {"after" if after else "before"}'


def check(spec, value):
    if value is None:
        return
    if spec.setup_only_after or spec.gate_timing != 'between' or spec.attack_swings:
        raise ValueError(f'{spec.spell} crit_field_refresh refreshes the melee crit field in the before and the after '
                         f'phase of a learn gate, which needs the default between-phases learn')


def phase_steps(spec, value, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(refresh_label(spec, after), CASTER, REFRESH_METRIC)]


def fixtures(class_file: dict, spec, value, scenario: dict):
    scenario['contract'] += (f' Each phase first reads {REFRESH_METRIC}, which recomputes the caster\'s melee crit '
                             f'field, so the before reading does not take a field left unset since login while the '
                             f'learn of {spec.spell} refreshes it for the after reading.')


def model(spec, value) -> dict:
    return {NAME: {'labels': [refresh_label(spec, False), refresh_label(spec, True)]}}


def verdict(verdict, run, refresh: dict):
    missing = [label for label in refresh['labels'] if run.values.get(label) is None]
    if missing:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the crit field refresh {missing} was not read, so the '
                                   f'phases may compare a stale field with a fresh one')
    return verdict
