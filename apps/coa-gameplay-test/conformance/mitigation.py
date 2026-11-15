from dataclasses import dataclass, field

PHYSICAL_SCHOOL_MASK = 1
MAGIC_SCHOOL_BITS = (2, 4, 8, 16, 32, 64)

MONSTER_RESISTANCE_PER_LEVEL = 1.0
MONSTER_RESISTANCE_PER_PERCENT = 5.0
MONSTER_RESISTANCE_MAX_REDUCTION = 0.75

CLASSIC_MAX_PLAYER_LEVEL = 60
CLASSIC_MAX_CREATURE_LEVEL = 63
MAX_ARMOR_REDUCTION = 0.75


@dataclass(frozen=True)
class TargetProfile:
    entry: int
    level: int
    armor: int
    resistances: dict[int, int] = field(default_factory=dict)


@dataclass(frozen=True)
class MitigationModel:
    mean: float
    variance: float
    resist_shares: tuple[float, ...] = ()


REFERENCE_TARGET = TargetProfile(entry=36, level=60, armor=528, resistances={})


def classic_combat(caster_level: int, target_level: int) -> bool:
    return caster_level <= CLASSIC_MAX_PLAYER_LEVEL and target_level <= CLASSIC_MAX_CREATURE_LEVEL


def armor_reduction(armor: int, caster_level: int, target_level: int) -> float:
    armor = max(0, armor)
    if classic_combat(caster_level, target_level):
        ratio = armor / (85.0 * caster_level + 400.0)
    else:
        level = caster_level + 4.5 * (caster_level - 59) if caster_level > 59 else caster_level
        ratio = 0.1 * armor / (8.5 * level + 40.0)
    return min(max(ratio / (1.0 + ratio), 0.0), MAX_ARMOR_REDUCTION)


def average_resist(school: int, target: TargetProfile, penetration: int) -> float:
    baseline = target.level * MONSTER_RESISTANCE_PER_LEVEL
    resistance = min(target.resistances.get(bit, 0) + baseline for bit in MAGIC_SCHOOL_BITS if school & bit)
    effective = max(0.0, resistance - penetration)
    return min(effective / MONSTER_RESISTANCE_PER_PERCENT / 100.0, MONSTER_RESISTANCE_MAX_REDUCTION)


def partial_resist_shares(average: float) -> list[float]:
    shares = [max(0.0, 0.5 - 2.5 * abs(0.1 * step - average)) for step in range(11)]
    if average <= 0.1:
        shares[0] = 1.0 - 7.5 * average
        shares[1] = 5.0 * average
        shares[2] = 2.5 * average
    return shares


def expected_mitigation(school: int, target: TargetProfile, caster_level: int, penetration: int = 0) -> MitigationModel:
    if school & PHYSICAL_SCHOOL_MASK:
        return MitigationModel(mean=1.0 - armor_reduction(target.armor, caster_level, target.level), variance=0.0)
    if not any(school & bit for bit in MAGIC_SCHOOL_BITS):
        raise ValueError(f'school mask {school} names no spell school')
    shares = partial_resist_shares(average_resist(school, target, penetration))
    resisted = sum(share * step / 10 for step, share in enumerate(shares))
    resisted_square = sum(share * (step / 10) ** 2 for step, share in enumerate(shares))
    return MitigationModel(mean=1.0 - resisted, variance=max(0.0, resisted_square - resisted ** 2),
                           resist_shares=tuple(shares))
