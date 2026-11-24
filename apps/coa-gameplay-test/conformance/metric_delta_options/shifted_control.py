from dataclasses import dataclass, replace
import math

NAME = 'shifted_control'
ORDER = 25
METRIC = 'spell_resist_chance'
METRIC_EVIDENCE = {METRIC: 'readback'}
STATE_PROMISES = {METRIC: r'spell penetration|penetration'}
KEYS = {'aura', 'amount', 'shift', 'shift_spell', 'school', 'caster_level', 'tolerance_share',
        'discrimination_share', 'source'}
REQUIRED = KEYS - {'caster_level'}
MOD_TARGET_RESISTANCE = 123
MAX_LEVEL = 80
READ_TOLERANCE = 1e-5


@dataclass(frozen=True)
class ShiftedControl:
    aura: int
    effect: int
    amount: int
    shift: int
    shift_spell: int
    shift_effect: int
    school: int
    tolerance_share: float
    discrimination_share: float
    source: str
    caster_level: int | None = None


def share(value) -> bool:
    return type(value) in (int, float) and math.isfinite(value) and 0 < value < 1


def pair(value) -> bool:
    return isinstance(value, list) and len(value) == 2 and all(type(item) is int and item >= 0 for item in value)


def parse(raw) -> ShiftedControl:
    if not isinstance(raw, dict) or not REQUIRED <= set(raw) <= KEYS or not pair(raw['aura']) \
            or not pair(raw['shift_spell']) or type(raw['amount']) is not int or type(raw['shift']) is not int \
            or raw['shift'] <= 0 or type(raw['school']) is not int or not 1 <= raw['school'] <= 6 \
            or not share(raw['tolerance_share']) or not share(raw['discrimination_share']) \
            or raw['tolerance_share'] >= raw['discrimination_share'] \
            or not isinstance(raw['source'], str) or not raw['source'].strip() \
            or ('caster_level' in raw and (type(raw['caster_level']) is not int
                                           or not 1 <= raw['caster_level'] <= MAX_LEVEL)):
        raise ValueError(f'shifted_control is {{aura: [spell, effect], amount, shift: a positive integer, '
                         f'shift_spell: [spell, effect], school: 1-6, tolerance_share and discrimination_share: '
                         f'fractions of the control span with tolerance below discrimination, source: text, '
                         f'caster_level?: 1-{MAX_LEVEL}}}, not {raw!r}')
    if raw['amount'] < 2 * raw['shift']:
        raise ValueError(f'shifted_control amount {raw["amount"]} must be at least twice the shift {raw["shift"]}, so '
                         f'the shifted control keeps a resistance of at least the shift above 0')
    return ShiftedControl(raw['aura'][0], raw['aura'][1], raw['amount'], raw['shift'], raw['shift_spell'][0],
                          raw['shift_spell'][1], raw['school'], float(raw['tolerance_share']),
                          float(raw['discrimination_share']), raw['source'], raw.get('caster_level'))


def check(spec, shifted):
    if shifted is None:
        return
    from values import TARGET
    present = dict(spec.options)
    if spec.metric != 'resistance' or spec.measure_actor != TARGET or spec.fields != {'school': shifted.school}:
        raise ValueError(f'{spec.spell} shifted_control reads the dummy\'s resistance of school {shifted.school} as '
                         f'its main reading, the fixture of every arm')
    if (shifted.aura, 1, TARGET, TARGET) not in spec.phase_auras \
            or (shifted.aura, shifted.effect, shifted.amount) not in (present.get('phase_aura_amounts') or ()):
        raise ValueError(f'{spec.spell} shifted_control needs {shifted.aura} as a phase aura of the dummy (1 stack, '
                         f'its own caster) with phase_aura_amounts effect {shifted.effect} at {shifted.amount}')
    if spec.before_expected != shifted.amount or spec.expected != shifted.amount:
        raise ValueError(f'{spec.spell} shifted_control main reading expects the fixture resistance {shifted.amount} '
                         f'in both phases')
    if spec.evidence_metric != METRIC:
        raise ValueError(f'{spec.spell} shifted_control is judged on {METRIC}: set evidence_metric to it')
    if 'phase_caster_level' in present:
        raise ValueError(f'{spec.spell} shifted_control compares reads of one caster level; use its caster_level')


def level_points(records, spell: int, effect: int, level: int) -> int:
    points = records.field('Spell', spell, f'EffectBasePoints[{effect}]')
    per_level = records.field('Spell', spell, f'EffectRealPointsPerLevel[{effect}]')
    if per_level:
        maximum = records.field('Spell', spell, 'MaxLevel')
        base = records.field('Spell', spell, 'BaseLevel')
        level = maximum if 0 < maximum < level else max(level, base)
        level -= max(base, records.field('Spell', spell, 'SpellLevel'))
        points += int(level * per_level)
    if records.field('Spell', spell, f'EffectDieSides[{effect}]') != 1:
        raise ValueError(f'shifted_control shift spell {spell} effect {effect} needs one die side')
    return points + 1


def derived_shift(class_file: dict, shifted: ShiftedControl) -> int:
    from pathlib import Path
    from classes import dataset
    from profile import DBC_DIR
    from tooltip import Records
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    spell, effect = shifted.shift_spell, shifted.shift_effect
    if records.field('Spell', spell, f'EffectApplyAuraName[{effect}]') != MOD_TARGET_RESISTANCE \
            or not records.field('Spell', spell, f'EffectMiscValue[{effect}]') & (1 << shifted.school):
        raise ValueError(f'shifted_control shift spell {spell} effect {effect} is not a '
                         f'SPELL_AURA_MOD_TARGET_RESISTANCE of school {shifted.school}')
    return -level_points(records, spell, effect, shifted.caster_level or class_file['level'])


def label(spec, read: str) -> str:
    return ' '.join(str(part) for part in (spec.spell, NAME, spec.label_suffix, read) if part)


def chance_read(spec, shifted: ShiftedControl, read: str) -> dict:
    from profile import CASTER, measurement
    from values import TARGET
    return measurement(label(spec, read), CASTER, METRIC, school=shifted.school, target=TARGET)


def amount_step(spec, shifted: ShiftedControl, amount: int) -> dict:
    from behaviours import phase_aura_step
    aura = next(aura for aura in spec.phase_auras if aura[0] == shifted.aura)
    return {**phase_aura_step(aura), 'effect': shifted.effect, 'amount': amount}


def phase_steps(spec, shifted: ShiftedControl, after: bool) -> list[dict]:
    from profile import CASTER
    if after or shifted.caster_level is None:
        return []
    return [{'action': 'set_level', 'label': f'{NAME} caster level', 'actor': CASTER, 'value': shifted.caster_level}]


def fixtures(class_file: dict, spec, shifted: ShiftedControl, scenario: dict):
    from behaviours import metric_delta_label
    from profile import measurement
    from values import TARGET
    shift = derived_shift(class_file, shifted)
    if shift != shifted.shift:
        raise ValueError(f'{spec.spell} shifted_control states the shift {shifted.shift}, but {shifted.shift_spell} '
                         f'effect {shifted.shift_effect} gives {shift} at caster level '
                         f'{shifted.caster_level or class_file["level"]}')
    steps = scenario['steps']
    after = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'after'))
    steps[after + 1:after + 1] = [chance_read(spec, shifted, 'treatment')]
    before = next(index for index, step in enumerate(steps) if step.get('label') == metric_delta_label(spec, 'before'))
    steps[before + 1:before + 1] = [
        chance_read(spec, shifted, 'control'),
        amount_step(spec, shifted, shifted.amount - shifted.shift),
        measurement(label(spec, 'shifted resistance'), TARGET, 'resistance', school=shifted.school),
        chance_read(spec, shifted, 'shifted control'),
        amount_step(spec, shifted, shifted.amount)]
    level = (f' The caster is set to level {shifted.caster_level} at the start (set_level) and learns the gate there.'
             if shifted.caster_level is not None else '')
    scenario['contract'] += (
        f' Shifted control (ADR 1281): {METRIC} of school {shifted.school} against the dummy is read in three arms: '
        f'the control (dummy resistance {shifted.amount}), the shifted control right after it (the fixture '
        f'{shifted.aura} lowered by the shift {shifted.shift} to {shifted.amount - shifted.shift}, then restored) and '
        f'the treatment (resistance {shifted.amount}, the gate learned). The shift is {shifted.shift_spell} effect '
        f'{shifted.shift_effect} at the caster level, from the DBC.{level} The treatment must equal the shifted '
        f'control within {shifted.tolerance_share:g} of the control span and stand at least '
        f'{shifted.discrimination_share:g} of it below the control ({shifted.source}).')


def model(spec, shifted: ShiftedControl) -> dict:
    return {NAME: {'control': label(spec, 'control'), 'shifted': label(spec, 'shifted control'),
                   'treatment': label(spec, 'treatment'), 'shifted_resistance': label(spec, 'shifted resistance'),
                   'shifted_expected': shifted.amount - shifted.shift, 'shift': shifted.shift,
                   'tolerance_share': shifted.tolerance_share,
                   'discrimination_share': shifted.discrimination_share, 'source': shifted.source}}


def verdict(verdict, run, shifted: dict):
    if verdict.status != 'ok':
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the fixture resistance read is off, so the shifted control '
                                   f'is void, not judged')
    labels = ('control', 'shifted', 'treatment', 'shifted_resistance')
    missing = next((shifted[key] for key in labels if run.values.get(shifted[key]) is None), None)
    if missing is not None:
        return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; {missing} was not read')
    control, moved, treatment, resistance = (run.values[shifted[key]] for key in labels)
    if abs(resistance - shifted['shifted_expected']) > READ_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; the shifted resistance reads {resistance:g}, not '
                                   f'{shifted["shifted_expected"]:g}: the shifted control is void, not judged')
    span = control - moved
    reads = (f'control {control:g}, shifted control {moved:g} (resistance {resistance:g}), treatment '
             f'{treatment:g}')
    if span <= READ_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; {reads}: lowering the resistance by {shifted["shift"]:g} '
                                   f'does not lower the read, so it cannot tell the shift: unmeasured')
    gap, offset = control - treatment, abs(moved - treatment)
    ratio = gap / span
    tolerance, discrimination = shifted['tolerance_share'] * span, shifted['discrimination_share'] * span
    separated = gap >= discrimination
    equal = offset <= tolerance
    text = (f'{reads}; control span {span:g}; control - treatment {gap:g} (at least {discrimination:g}: '
            f'{"ok" if separated else "off"}); |shifted control - treatment| {offset:g} (at most {tolerance:g}: '
            f'{"ok" if equal else "off"}) ({shifted["source"]})')
    return replace(verdict, status='ok' if separated and equal else 'alert', measured=ratio, expected=1.0,
                   low=1.0 - shifted['tolerance_share'], high=1.0 + shifted['tolerance_share'],
                   explanation=f'{verdict.explanation}; {text}')
