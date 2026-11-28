from dataclasses import replace

NAME = 'before_trigger_reads'
ORDER = 30
READ_KEYS = {'spell', 'expected', 'actor'}
OPTIONAL_KEYS = {'after_target_casts', 'min_stacks'}
UNITS = ('caster', 'dummy', 'enemy')


def valid_read(read) -> bool:
    if not isinstance(read, dict) or not READ_KEYS <= set(read) <= READ_KEYS | OPTIONAL_KEYS:
        return False
    if not isinstance(read['spell'], int) or isinstance(read['spell'], bool):
        return False
    if isinstance(read['expected'], bool) or read['expected'] not in (0, 1) or read['actor'] not in UNITS:
        return False
    if 'after_target_casts' in read and not isinstance(read['after_target_casts'], bool):
        return False
    if 'min_stacks' in read:
        stacks = read['min_stacks']
        if isinstance(stacks, bool) or not isinstance(stacks, int) or stacks < 1 or read['expected'] != 1:
            return False
    return True


def parse(raw) -> tuple[tuple[int, int, str, bool, int | None], ...]:
    if not isinstance(raw, list) or not raw or not all(valid_read(read) for read in raw):
        raise ValueError(f'before_trigger_reads is a non-empty list of {{"spell": id, "expected": 0 or 1, "actor": '
                         f'{" or ".join(UNITS)}, optional "after_target_casts": bool, optional "min_stacks": int >= 1}}, '
                         f'not {raw!r}')
    if len({(read['spell'], read['actor']) for read in raw}) != len(raw):
        raise ValueError(f'before_trigger_reads names a spell twice on one unit: {raw!r}')
    return tuple((read['spell'], read['expected'], read['actor'], read.get('after_target_casts', False),
                  read.get('min_stacks')) for read in raw)


def phases(spec) -> tuple[str, ...]:
    casts_before = spec.cast_in_before and not spec.trigger_only_after and not spec.setup_only_after
    return ('before', 'after') if casts_before else ('after',)


def read_label(spec, spell: int, actor: str, phase: str) -> str:
    return f'{spec.spell} before_trigger_reads {actor} {spell} {phase}'


def phase_steps(spec, reads, after: bool) -> list[dict]:
    from profile import measurement
    phase = 'after' if after else 'before'
    if phase not in phases(spec):
        return []
    return [measurement(read_label(spec, spell, actor, phase), actor, 'aura_stacks', spell=spell)
            for spell, _, actor, after_target_casts, _ in reads if not after_target_casts]


def trigger_cast_indices(spec, steps: list[dict]) -> list[int]:
    from profile import CASTER
    action = 'use_item' if spec.trigger_item is not None else 'cast'
    return [index for index, step in enumerate(steps)
            if step.get('action') == action and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell]


def fixtures(class_file: dict, spec, reads, scenario: dict):
    from profile import measurement
    deferred = [item for item in reads if item[3]]
    if deferred:
        active_phases = phases(spec)
        casts = trigger_cast_indices(spec, scenario['steps'])
        if len(casts) != len(active_phases):
            raise ValueError(f'{spec.spell} before_trigger_reads after_target_casts expected {len(active_phases)} '
                             f'trigger casts of {spec.trigger_spell}, found {len(casts)}')
        insert_at = dict(zip(casts, active_phases))
        steps = []
        for index, step in enumerate(scenario['steps']):
            if index in insert_at:
                phase = insert_at[index]
                steps += [measurement(read_label(spec, spell, actor, phase), actor, 'aura_stacks', spell=spell)
                          for spell, _, actor, _, _ in deferred]
            steps.append(step)
        scenario['steps'] = steps
    immediate = [item for item in reads if not item[3]]
    if immediate:
        scenario['contract'] += (' Before the trigger cast of each phase that makes it, right after the fixture auras '
                                 'are set and with no wait in between, '
                                 + ', '.join(f'aura {spell} on the {actor}' for spell, _, actor, _, _ in immediate)
                                 + ' is read and judged against '
                                 + ', '.join(f'at least {stacks} stacks' if stacks is not None
                                             else ('present' if expected else 'absent')
                                             for _, expected, _, _, stacks in immediate)
                                 + ': a precondition check, so a mismatch voids the trial.')
    if deferred:
        scenario['contract'] += (' Immediately before the trigger cast of each phase that makes it, after setup and '
                                 'target_casts_before settle, '
                                 + ', '.join(f'aura {spell} on the {actor}' for spell, _, actor, _, _ in deferred)
                                 + ' is read and judged against '
                                 + ', '.join(f'at least {stacks} stacks' if stacks is not None
                                             else ('present' if expected else 'absent')
                                             for _, expected, _, _, stacks in deferred)
                                 + ': a precondition check, so a mismatch voids the trial.')


def model(spec, reads) -> dict:
    return {NAME: [{'spell': spell, 'expected': expected, 'actor': actor,
                    **({'after_target_casts': True} if after_target_casts else {}),
                    **({'min_stacks': min_stacks} if min_stacks is not None else {}),
                    'read_labels': {phase: read_label(spec, spell, actor, phase) for phase in phases(spec)}}
                   for spell, expected, actor, after_target_casts, min_stacks in reads]}


def verdict(verdict, run, reads):
    off = []
    for read in reads:
        min_stacks = read.get('min_stacks')
        for phase, label in read['read_labels'].items():
            value = run.values.get(label)
            if min_stacks is not None:
                ok = value is not None and value >= min_stacks
            else:
                ok = value is not None and (value > 0) == bool(read['expected'])
            if not ok:
                off.append((read['actor'], read['spell'], read['expected'], min_stacks, phase, value))
    if not off:
        return verdict
    detail = ', '.join(
        f'the {actor} aura {spell} read {value} in the {phase} phase (expected '
        f'{f"at least {min_stacks} stacks" if min_stacks is not None else ("present" if expected else "absent")})'
        for actor, spell, expected, min_stacks, phase, value in off)
    return replace(verdict, status='unmeasured',
                   explanation=f'{verdict.explanation}; before the trigger cast {detail}, so the precondition did '
                               f'not hold')
