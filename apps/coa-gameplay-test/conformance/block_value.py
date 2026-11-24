from typing import Mapping

from profile import CASTER, measurement

BLOCK_VALUE_TERMS = 'block_value_terms'
BLOCK_VALUE_LABEL = 'block_value'


def block_value_entry(class_file: dict, spell_id: int) -> dict | None:
    return next((entry for entry in class_file.get(BLOCK_VALUE_TERMS, ()) if entry['spell'] == spell_id), None)


def block_value_steps(class_file: dict, spell_id: int) -> list[dict]:
    if block_value_entry(class_file, spell_id) is None:
        return []
    return [measurement(BLOCK_VALUE_LABEL, CASTER, BLOCK_VALUE_LABEL)]


def block_value_terms(class_file: dict, spell_id: int, values: Mapping[str, float]) -> dict[int, float]:
    entry = block_value_entry(class_file, spell_id)
    if entry is None:
        return {}
    if BLOCK_VALUE_LABEL not in values:
        raise KeyError(BLOCK_VALUE_LABEL)
    return {entry['effect']: float(values[BLOCK_VALUE_LABEL])}


def block_value_text(class_file: dict, spell_id: int, effect: int, amount: float) -> str:
    entry = block_value_entry(class_file, spell_id)
    return f'plus the read block value {amount:g} on effect {effect} ({entry["source"]})'
