import math
import struct
from typing import Mapping

from profile import CASTER, measurement
from tooltip import Records
from values import ALLY

HEAL_PCT_TERMS = 'heal_pct_terms'
HEAL_PCT_LABEL = 'heal target max_health'
SPELL_EFFECT_HEAL_PCT = 136
HEAL_PCT_RULE = 'Spell::EffectHealPct, SpellEffects.cpp:2604'
FLOAT32 = struct.Struct('<f')


def heal_pct_entry(class_file: dict, rank_id: int) -> dict | None:
    return next((entry for entry in class_file.get(HEAL_PCT_TERMS, ()) if entry['spell'] == rank_id), None)


def heal_pct_percent(records: Records, rank_id: int, effect: int) -> int:
    def field(name: str):
        return records.field('Spell', rank_id, f'{name}[{effect}]')

    sides = field('EffectDieSides')
    if field('Effect') != SPELL_EFFECT_HEAL_PCT or sides not in (0, 1) or field('EffectRealPointsPerLevel'):
        raise ValueError(f'{HEAL_PCT_TERMS} {rank_id} effect {effect} needs SPELL_EFFECT_HEAL_PCT '
                         f'({SPELL_EFFECT_HEAL_PCT}) with a fixed value (die sides 0 or 1, no points per level)')
    return field('EffectBasePoints') + sides


def heal_pct_steps(class_file: dict, rank_id: int, ally: bool) -> list[dict]:
    if heal_pct_entry(class_file, rank_id) is None:
        return []
    return [measurement(HEAL_PCT_LABEL, ALLY if ally else CASTER, 'max_health')]


def single(value: float) -> float:
    return FLOAT32.unpack(FLOAT32.pack(value))[0]


def heal_pct_amount(maximum: float, percent: int) -> int:
    return math.floor(single(single(single(maximum) * percent) / 100))


def heal_pct_term(class_file: dict, records: Records, rank_id: int, values: Mapping[str, float]) -> float | None:
    entry = heal_pct_entry(class_file, rank_id)
    if entry is None:
        return None
    percent = heal_pct_percent(records, rank_id, entry['effect'])
    if HEAL_PCT_LABEL not in values:
        raise KeyError(HEAL_PCT_LABEL)
    return float(heal_pct_amount(float(values[HEAL_PCT_LABEL]), percent))


def heal_pct_text(class_file: dict, records: Records, rank_id: int) -> str:
    entry = heal_pct_entry(class_file, rank_id)
    percent = heal_pct_percent(records, rank_id, entry['effect'])
    return (f'; listed in {HEAL_PCT_TERMS}: plus effect {entry["effect"]} SPELL_EFFECT_HEAL_PCT, {percent}% of the '
            f'healed unit\'s maximum health read by {HEAL_PCT_LABEL!r}, truncated, under the same healing modifiers '
            f'({HEAL_PCT_RULE}; {entry["source"]})')
