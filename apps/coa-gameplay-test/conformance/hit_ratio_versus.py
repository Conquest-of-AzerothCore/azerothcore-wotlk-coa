from dataclasses import asdict, dataclass
import math

from hits import float32
from mitigation import armor_reduction
from profile import CASTER, measurement
from values import DUMMY_HEALTH, FIXTURE_MAX_HEALTH, TARGET

NAME = 'versus_creature_type'
VERSUS_TARGET = 'versus_dummy'
STRIKER = 'striker'
STRIKER_HEALTH = 1_000_000
STRIKER_DISTANCE = 3.0
STRIKE_WAIT_MS = 300
MELEE_ATTACK_POWER_VERSUS = 102
AP_PER_DAMAGE_PER_SECOND = 14.0
MAGIC_SCHOOLS = (1, 2, 3, 4, 5, 6)
ARMS = ('control', 'treatment')
FIELDS = frozenset({'aura', 'effect', 'strike_spell', 'striker_entry', 'warmup_strikes', 'control_entry',
                    'control_type', 'treatment_entry', 'treatment_type', 'source'})


@dataclass(frozen=True)
class Versus:
    aura: int
    effect: int
    strike_spell: int
    striker_entry: int
    warmup_strikes: int
    control_entry: int
    control_type: int
    treatment_entry: int
    treatment_type: int
    source: str


def parse(raw: dict | None) -> Versus | None:
    if raw is None:
        return None
    if set(raw) != FIELDS or not isinstance(raw['source'], str) or not raw['source']:
        raise ValueError(f'hit_ratio {NAME} needs exactly {sorted(FIELDS)}, the source naming where the creature '
                         f'types were read')
    numbers = {name: raw[name] for name in FIELDS - {'source'}}
    if any(type(value) is not int or value < 0 for value in numbers.values()) or raw['warmup_strikes'] < 1 \
            or raw['effect'] > 2:
        raise ValueError(f'hit_ratio {NAME} fields are non-negative integers, an effect 0-2 and at least one '
                         f'warm-up strike')
    if raw['control_entry'] == raw['treatment_entry'] or raw['control_type'] == raw['treatment_type']:
        raise ValueError(f'hit_ratio {NAME} dummies differ in entry and creature type')
    return Versus(**numbers, source=raw['source'])


def type_bit(creature_type: int) -> int:
    return 1 << (creature_type - 1) if creature_type > 0 else 0


def versus_mask(records, versus: Versus) -> int:
    aura = records.field('Spell', versus.aura, f'EffectApplyAuraName[{versus.effect}]')
    if aura != MELEE_ATTACK_POWER_VERSUS:
        raise ValueError(f'{versus.aura} Effect[{versus.effect}] is aura {aura}, not '
                         f'{MELEE_ATTACK_POWER_VERSUS} SPELL_AURA_MOD_MELEE_ATTACK_POWER_VERSUS on melee swings')
    mask = records.field('Spell', versus.aura, f'EffectMiscValue[{versus.effect}]')
    if not type_bit(versus.treatment_type) & mask or type_bit(versus.control_type) & mask:
        raise ValueError(f'{NAME}: the treatment type {versus.treatment_type} must be in the {versus.aura} '
                         f'Effect[{versus.effect}] creature type mask {mask} and the control type '
                         f'{versus.control_type} outside it')
    return mask


def target_of(arm: str) -> str:
    return VERSUS_TARGET if arm == 'treatment' else TARGET


def read_label(prefix: str, arm: str, read: str, trial: int | None = None) -> str:
    return f'{prefix} versus {arm} {read}' + (f' {trial}' if trial is not None else '')


def health_step() -> dict:
    return {'action': 'set_health', 'actor': CASTER, 'value': FIXTURE_MAX_HEALTH, 'maximum': FIXTURE_MAX_HEALTH}


def strike_steps(versus: Versus, label: str) -> list[dict]:
    return [health_step(), {'action': 'cast', 'actor': STRIKER, 'spell': versus.strike_spell, 'target': CASTER},
            {'action': 'wait', 'label': label, 'ms': STRIKE_WAIT_MS}]


def warmup_steps(versus: Versus) -> list[dict]:
    return [step for strike in range(1, versus.warmup_strikes + 1)
            for step in strike_steps(versus, f'versus warm-up strike {strike}')]


def trial_steps(versus: Versus, prefix: str, arm: str, trial: int) -> list[dict]:
    return strike_steps(versus, f'{arm} versus strike {trial}') + [
        measurement(read_label(prefix, arm, 'attack_power', trial), CASTER, 'attack_power'),
        measurement(read_label(prefix, arm, 'amount', trial), CASTER, 'aura_amount', spell=versus.aura,
                    effect=versus.effect)]


def dummy_steps(prefix: str) -> list[dict]:
    steps = []
    for arm in ARMS:
        unit = target_of(arm)
        steps += [measurement(read_label(prefix, arm, 'armor'), unit, 'armor'),
                  measurement(read_label(prefix, arm, 'level'), CASTER, 'view_level', target=unit)]
        steps += [measurement(read_label(prefix, arm, f'resistance {school}'), unit, 'resistance', school=school)
                  for school in MAGIC_SCHOOLS]
    return steps


def creatures(dummy: dict, versus: Versus, level: int) -> list[dict]:
    return [{**dummy, 'entry': versus.control_entry},
            {**dummy, 'id': VERSUS_TARGET, 'entry': versus.treatment_entry},
            {'id': STRIKER, 'owner': CASTER, 'entry': versus.striker_entry, 'level': level, 'health': STRIKER_HEALTH,
             'distance': STRIKER_DISTANCE, 'stationary': True}]


def model(versus: Versus, mask: int, prefix: str, trials: int, speed_ms: int, caster_level: int) -> dict:
    return {**asdict(versus), 'mask': mask, 'speed_s': speed_ms / 1000, 'caster_level': caster_level,
            'reads': {arm: {'attack_power': [read_label(prefix, arm, 'attack_power', trial)
                                             for trial in range(1, trials + 1)],
                            'amount': [read_label(prefix, arm, 'amount', trial) for trial in range(1, trials + 1)],
                            'armor': read_label(prefix, arm, 'armor'), 'level': read_label(prefix, arm, 'level'),
                            'resistances': [read_label(prefix, arm, f'resistance {school}')
                                            for school in MAGIC_SCHOOLS]}
                      for arm in ARMS}}


def contract(versus: Versus, mask: int, trials: int) -> str:
    return (f'; {NAME}: the control arm swings at creature {versus.control_entry} (type {versus.control_type}), the '
            f'treatment arm at creature {versus.treatment_entry} (type {versus.treatment_type}), both at the class '
            f'level, {DUMMY_HEALTH} health, same place; {versus.aura} Effect[{versus.effect}] (aura '
            f'{MELEE_ATTACK_POWER_VERSUS}, creature type mask {mask} from the DBC) holds the treatment type only '
            f'({versus.source}); creature {versus.striker_entry} strikes the caster (health set to '
            f'{FIXTURE_MAX_HEALTH} of {FIXTURE_MAX_HEALTH}) with {versus.strike_spell} {versus.warmup_strikes} times '
            f'before the arms and once before each of the {trials} swings of both arms, then the caster\'s attack '
            f'power and the {versus.aura} Effect[{versus.effect}] amount are read; the dummies\' armor, level and '
            f'resistances are read and must be equal; the expected difference per hit is int(amount / 14 x weapon '
            f'speed) (Unit::MeleeDamageBonusDone, done flat benefit) plus the attack power drift between the arms '
            f'(attack power / 14 x weapon speed), both reduced by the read armor')


def engine_flat(amount: float, speed: float) -> int:
    return math.trunc(float32(float32(amount / AP_PER_DAMAGE_PER_SECOND) * float32(speed)))


def adjusted(values: dict, versus: dict, arm: str, totals: list[float], counts: list[float],
             reference_power: float, armor_factor: float) -> tuple[list[float], float, float] | str:
    reads = versus['reads'][arm]
    powers = [values.get(label) for label in reads['attack_power']]
    amounts = [values.get(label) for label in reads['amount']]
    missing = next((label for label, value in zip(reads['attack_power'] + reads['amount'], powers + amounts)
                    if value is None), None)
    if missing is not None:
        return f'missing measurement {missing!r}'
    if len(powers) != len(totals):
        return f'{len(totals)} {arm} trials against {len(powers)} versus reads'
    speed = float(versus['speed_s'])
    flat = [engine_flat(amount, speed) * armor_factor if arm == 'treatment' else 0.0 for amount in amounts]
    drift = [(power - reference_power) / AP_PER_DAMAGE_PER_SECOND * speed * armor_factor for power in powers]
    return ([total - count * shift for total, count, shift in zip(totals, counts, drift)],
            sum(count * value for count, value in zip(counts, flat)), sum(counts))


def dummies(values: dict, versus: dict) -> tuple[float, int] | str:
    read = {arm: [values.get(versus['reads'][arm][name]) for name in ('armor', 'level')]
            + [values.get(label) for label in versus['reads'][arm]['resistances']] for arm in ARMS}
    for arm in ARMS:
        if None in read[arm]:
            return f'the {arm} dummy reads are missing'
    if read['control'] != read['treatment']:
        return (f'the dummies differ in armor, level or resistances: control {read["control"]}, treatment '
                f'{read["treatment"]}')
    armor, level = read['control'][0], read['control'][1]
    return 1 - armor_reduction(int(armor), int(versus['caster_level']), int(level)), int(armor)


def reference_power(runs_values: list[dict], versus: dict) -> float | None:
    powers = [values.get(label) for values in runs_values for arm in ARMS
              for label in versus['reads'][arm]['attack_power']]
    if not powers or None in powers:
        return None
    return sum(powers) / len(powers)
