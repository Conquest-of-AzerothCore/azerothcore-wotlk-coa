from dataclasses import replace
from pathlib import Path

NAME = 'before_absent_recipient'
ORDER = 19
RECIPIENT_TOTALS = frozenset({'spell_heal_total', 'spell_energize_total'})
SUMMON_PET = 56
EFFECTS = 3


def parse(raw) -> bool:
    if raw is not True:
        raise ValueError(f'before_absent_recipient is true, not {raw!r}')
    return raw


def check(spec, absent):
    if absent is None:
        return
    if spec.metric not in RECIPIENT_TOTALS or spec.fields.get('target_pet') is not True \
            or not spec.fields.get('target') or not spec.setup_only_after:
        raise ValueError(f'{spec.spell} sets before_absent_recipient only on a {sorted(RECIPIENT_TOTALS)} read with '
                         f'fields target and target_pet true and setup_only_after')


def proof_label(spec) -> str:
    return f'{spec.spell} before_absent_recipient count'


def present_label(spec) -> str:
    return f'{spec.spell} before_absent_recipient present'


def recipient_entry(class_file: dict, spec) -> int:
    from profile import DBC_DIR
    from tooltip import Records
    from values import dataset
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entries = {int(records.field('Spell', spell, f'EffectMiscValue[{effect}]'))
               for spell in spec.setup_casts for effect in range(EFFECTS)
               if records.field('Spell', spell, f'Effect[{effect}]') == SUMMON_PET}
    if len(entries) != 1:
        raise ValueError(f'{spec.spell} before_absent_recipient needs exactly one SUMMON_PET entry among its '
                         f'setup_casts {list(spec.setup_casts)}, found {sorted(entries)}')
    return entries.pop()


def fixtures(class_file: dict, spec, absent: bool, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    entry = recipient_entry(class_file, spec)
    steps = scenario['steps']
    labels = [step.get('label') for step in steps]
    before = labels.index(metric_delta_label(spec, 'before'))
    after = labels.index(metric_delta_label(spec, 'after'))
    proof = measurement(proof_label(spec), CASTER, 'owned_creature_count', entry=entry)
    present = {'action': 'assert', 'label': present_label(spec), 'actor': CASTER, 'metric': 'owned_creature_count',
               'entry': entry, 'equals': 1}
    scenario['steps'] = steps[:before] + [proof] + steps[before + 1:after] + [present] + steps[after:]
    scenario['contract'] += (f' The before phase has no recipient: its {spec.metric} read is replaced by a count of '
                             f'the owned {entry} (the setup cast\'s SUMMON_PET), which must be 0, and the before '
                             f'value is then 0; the after read requires exactly one owned {entry}.')


def model(spec, absent: bool) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {'read_label': proof_label(spec), 'before_label': metric_delta_label(spec, 'before')}}


def run_values(values: dict, absent: dict) -> dict:
    if values.get(absent['read_label']) != 0:
        return values
    return {**values, absent['before_label']: 0.0}


def verdict(verdict, run, absent: dict):
    count = run.values.get(absent['read_label'])
    if count is None:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the before recipient count was not read')
    if count != 0:
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; the before phase owned {count:g} recipients, not 0')
    return verdict
