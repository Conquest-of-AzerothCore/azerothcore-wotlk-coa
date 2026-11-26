from dataclasses import replace

NAME = 'void_on_cast_failure'
ORDER = 27


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'void_on_cast_failure is true, not {raw!r}')
    return raw


def check(spec, value):
    if value is not None and spec.metric == 'cast_failure':
        raise ValueError(f'{spec.spell} void_on_cast_failure voids a trial for a refused setup or step cast, and a '
                         f'cast_failure entry judges the cast itself')


def fixtures(class_file: dict, spec, value: bool, scenario: dict):
    scenario['contract'] += (' A refused setup or step cast (a native SMSG_CAST_FAILED in the result) voids the '
                             'trial: the verdict is unmeasured, never ok or alert.')


def model(spec, value: bool) -> dict:
    return {NAME: True}


def verdict(verdict, run, value: bool):
    from compare import NO_CAST_FAILURE, describe_failures
    refused = [reason for reasons in run.cast_failures.values() for reason in reasons if reason != NO_CAST_FAILURE]
    if not refused:
        return verdict
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; the trial is void, a cast was refused '
                               f'({describe_failures(refused)})')
