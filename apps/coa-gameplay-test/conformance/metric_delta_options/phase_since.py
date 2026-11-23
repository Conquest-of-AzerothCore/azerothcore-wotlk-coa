NAME = 'phase_since'
ORDER = 30
PHASES = ('before', 'after')
SUMMED = ('fields_sum', 'area_sum', 'ring_sum', 'target_attack_window')
UNBOUNDED_KEYS = ('min', 'max')


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'phase_since is true, not {raw!r}')
    return True


def check(spec, since):
    if since is None:
        return
    if not spec.cast_in_before or spec.trigger_only_after or spec.attack_swings or spec.trigger_item is not None:
        raise ValueError(f'{spec.spell} phase_since reads each phase from its own trigger cast, so both phases cast '
                         f'the trigger spell')
    if spec.trigger_spell in spec.setup_casts:
        raise ValueError(f'{spec.spell} phase_since finds each phase by its trigger cast, which a setup cast repeats')
    combined = [name for name, _ in spec.options if name in SUMMED]
    if combined:
        raise ValueError(f'{spec.spell} phase_since cannot difference a summed or windowed reading ({combined})')


def snapshot_name(spec, phase: str, base: bool) -> str:
    return f'since_{phase}' + ('_base' if base else '')


def snapshot_step(read: dict, name: str) -> dict:
    step = {key: value for key, value in read.items() if key not in UNBOUNDED_KEYS}
    return {**step, 'action': 'snapshot', 'label': f'{read["label"]} phase start', 'save_as': name}


def fixtures(class_file: dict, spec, since: bool, scenario: dict):
    from behaviours import metric_delta_label
    from metric_delta_options.ratio_to_metric import base_label
    from profile import CASTER
    judged = {metric_delta_label(spec, 'before'): 'before', metric_delta_label(spec, 'after'): 'after',
              metric_delta_label(spec, 'expired'): 'after'}
    reads = {phase: {False: None, True: None} for phase in PHASES}
    for step in scenario['steps']:
        if step.get('action') != 'assert':
            continue
        for label, phase in judged.items():
            if step.get('label') == label and reads[phase][False] is None:
                reads[phase][False] = step
            if step.get('label') == base_label(label) and reads[phase][True] is None:
                reads[phase][True] = step
    casts = [index for index, step in enumerate(scenario['steps'])
             if step.get('action') == 'cast' and step.get('actor') == CASTER
             and step.get('spell') == spec.trigger_spell]
    before_read = scenario['steps'].index(reads['before'][False])
    anchors = {'before': next(index for index in casts if index < before_read),
               'after': next(index for index in casts if index > before_read)}
    inserted = {anchors[phase]: [snapshot_step(read, snapshot_name(spec, phase, base))
                                 for base, read in reads[phase].items() if read is not None]
                for phase in PHASES}
    steps = []
    for index, step in enumerate(scenario['steps']):
        steps += inserted.get(index, [])
        if step.get('action') == 'assert':
            for label, phase in judged.items():
                if step.get('label') in (label, base_label(label)):
                    step = {**step, 'relative_to': snapshot_name(spec, phase, step.get('label') != label)}
        steps.append(step)
    scenario['steps'] = steps
    scenario['contract'] += (' Each judged reading counts only its own phase: the read (and its ratio base) is '
                             'snapshot right before the phase\'s trigger cast and judged relative to it, so a '
                             'cumulative event total of the before phase does not enter the after reading.')
