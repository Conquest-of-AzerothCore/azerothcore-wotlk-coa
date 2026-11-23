from dataclasses import replace

NAME = 'player_spell_power'
ORDER = 2
HIT_ARM_FIELDS = {'amount', 'hit_arm'}


def parse(raw):
    if isinstance(raw, dict):
        if set(raw) != HIT_ARM_FIELDS or raw['hit_arm'] is not True or isinstance(raw['amount'], bool) \
                or not isinstance(raw['amount'], int) or raw['amount'] <= 0:
            raise ValueError(f'player_spell_power is a spell power or {{"amount": positive spell power, "hit_arm": '
                             f'true}}, not {raw!r}')
        return dict(raw)
    return raw


def amount(value) -> int:
    return value['amount'] if isinstance(value, dict) else value


def hit_arm(value) -> bool:
    return isinstance(value, dict)


def read_label(spec) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, "after")} spell power'


def spell_school(class_file: dict, spell: int) -> int:
    from pathlib import Path
    from profile import DBC_DIR
    from tooltip import Records
    from values import dataset
    mask = int(Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR)))).field('Spell', spell, 'SchoolMask') or 0)
    schools = [school for school in range(1, 7) if mask & (1 << school)]
    if not schools:
        raise ValueError(f'{spell} has no magic school, so player_spell_power hit_arm has no spell power to read')
    return schools[0]


def check(spec, value):
    from behaviours import CASTER
    if value is not None and hit_arm(value) and (
            spec.metric not in ('spell_damage_total', 'spell_heal_total') or spec.measure_actor != CASTER):
        raise ValueError(f'{spec.spell} player_spell_power hit_arm records the spell power of a hit: the metric is '
                         f'the caster\'s spell_damage_total or spell_heal_total, not {spec.measure_actor} '
                         f'{spec.metric}')


def fixtures(class_file: dict, spec, value, scenario: dict):
    scenario['players'][0]['spell_power'] = amount(value)
    if not hit_arm(value):
        return
    from behaviours import CASTER, metric_delta_label
    from profile import measurement
    school = spell_school(class_file, spec.trigger_spell)
    after = metric_delta_label(spec, 'after')
    steps = scenario['steps']
    index = next(index for index, step in enumerate(steps) if step.get('label') == after)
    steps.insert(index, measurement(read_label(spec), CASTER, 'spell_power', school=school))
    scenario['contract'] += (f' The caster\'s spell power of school {school} is read right before the judged reading; '
                             f'a conformant verdict records it as the spell power its hit ran at.')


def model(spec, value) -> dict:
    return {NAME: {'read': read_label(spec)}} if hit_arm(value) else {}


def verdict(verdict, run, arm: dict):
    read = run.values.get(arm['read'])
    if read is None or read <= 0:
        return verdict
    return replace(verdict, detail={**(verdict.detail or {}), 'spell_power': read})
