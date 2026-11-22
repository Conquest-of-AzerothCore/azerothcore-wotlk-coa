NAME = 'void_on_cast_failure'
CONTRACT = ('; a refused cast in the run (a native SMSG_CAST_FAILED in the result) voids the trial: the verdict is '
            'unmeasured, never ok or alert')


def parse(raw) -> bool:
    if raw is None:
        return False
    if raw is not True:
        raise ValueError(f'hit_ratio {NAME} is true, not {raw!r}')
    return True


def refused(runs, no_failure: int) -> list[int]:
    return [reason for run in runs for reasons in run.cast_failures.values() for reason in reasons
            if reason != no_failure]


def explanation(reasons: list[int], describe) -> str:
    return f'not judged: the trial is void, {len(reasons)} casts were refused ({describe(reasons)})'
