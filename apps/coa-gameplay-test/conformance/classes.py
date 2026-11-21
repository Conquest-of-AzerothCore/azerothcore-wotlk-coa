from collections import Counter
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import re
import sys
from typing import Sequence

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'coa-dbc'))
from inspect_dbc import DataSet
from tooltip import PASSIVE_ATTRIBUTE, Records, weapon_skill_spells

CHARACTER_LEVEL = 60
RANK_SLOTS = 5
TRIGGER_FIELDS = tuple(f'EffectTriggerSpell[{index}]' for index in range(3))
PROGRESSION_HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'
PROGRESSION_ROW = re.compile(r'^\s*\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\},?\s*$', re.MULTILINE)


@lru_cache(maxsize=None)
def dataset(directory: Path) -> DataSet:
    return DataSet(directory)


@dataclass(frozen=True)
class ClassSpell:
    spell_id: int
    name: str
    ranks: tuple[int, ...]
    max_rank: int
    required_level: int
    passive: bool


def table_rows(dataset: DataSet, name: str, fields: list[str]):
    table, schema, index, _ = dataset.load(name)
    columns = {column.name: column for column in schema.columns}
    for identity, row in index.items():
        yield identity, {field: dataset.value(table, row, columns[field])[0] for field in fields}


def rows_by_identity(dataset: DataSet, name: str, identities: set[int], fields: list[str]) -> dict[int, dict]:
    table, schema, index, _ = dataset.load(name)
    columns = {column.name: column for column in schema.columns}
    return {identity: {field: dataset.value(table, index[identity], columns[field])[0] for field in fields}
            for identity in identities if identity in index}


def header_chains(header: Path, class_id: int | None = None) -> dict[int, list[tuple[int, int]]]:
    chains: dict[int, list[tuple[int, int]]] = {}
    for row_class, first_spell, spell, required_level in PROGRESSION_ROW.findall(header.read_text(encoding='utf-8')):
        if class_id is None or int(row_class) == class_id:
            chains.setdefault(int(first_spell), []).append((int(spell), int(required_level)))
    return chains


def triggered_chains(dbc: DataSet, chains: dict[int, list[tuple[int, int]]]) -> dict[int, list[tuple[int, int]]]:
    casts = set(chains) | {rank for chain in chains.values() for rank, _ in chain}
    triggers = rows_by_identity(dbc, 'Spell', casts, list(TRIGGER_FIELDS))
    derived: dict[int, list[tuple[int, int]]] = {}
    for first_spell, chain in chains.items():
        cast_ranks = [first_spell] + [rank for rank, _ in chain]
        for field in TRIGGER_FIELDS:
            triggered = [triggers.get(rank, {}).get(field, 0) for rank in cast_ranks]
            if all(triggered) and len(set(triggered)) == len(triggered) and not set(triggered) & casts:
                derived.setdefault(triggered[0], [(spell, level) for spell, (_, level) in zip(triggered[1:], chain)])
    return derived


def progression_chains(dbc: DataSet, header: Path, class_id: int | None = None) -> dict[int, list[tuple[int, int]]]:
    chains = header_chains(header, class_id)
    return {**triggered_chains(dbc, chains), **chains}


def class_type_ids(dataset: DataSet, class_id: int) -> set[int]:
    types = {identity for identity, fields in table_rows(dataset, 'CharacterAdvancementClassTypes',
                                                         ['ClassID', 'CustomClass'])
             if fields['ClassID'] == class_id and fields['CustomClass'] == 1}
    if not types:
        raise ValueError(f'No custom class type for ClassID {class_id}')
    return types


def advancement_levels(dataset: DataSet, types: set[int]) -> dict[int, int]:
    rank_fields = [f'RankSpell[{slot}]' for slot in range(RANK_SLOTS)]
    levels: dict[int, int] = {}
    for _, fields in table_rows(dataset, 'CharacterAdvancement', ['ClassType', 'RequiredLevel'] + rank_fields):
        if fields['ClassType'] not in types:
            continue
        for field in rank_fields:
            spell_id = fields[field]
            if spell_id:
                levels[spell_id] = min(levels.get(spell_id, fields['RequiredLevel']), fields['RequiredLevel'])
    return levels


def class_spells(dbc_dir: Path, class_id: int, progression_header: Path, level: int = CHARACTER_LEVEL,
                 extra_spells: Sequence[int] = ()) -> list[ClassSpell]:
    dbc = dataset(dbc_dir)
    levels = advancement_levels(dbc, class_type_ids(dbc, class_id))
    repeated = sorted(spell_id for spell_id, count in Counter(extra_spells).items() if count > 1)
    if repeated:
        raise ValueError(f'Extra spells {repeated} are listed more than once')
    duplicated = sorted(set(extra_spells) & set(levels))
    if duplicated:
        raise ValueError(f'Extra spells {duplicated} are already CharacterAdvancement class spells')
    chains = progression_chains(dbc, progression_header, class_id)
    wanted = set(levels) | set(extra_spells)
    spells = rows_by_identity(dbc, 'Spell', wanted, ['SpellName[enUS]', 'Attributes', 'BaseLevel'])
    levels.update({spell_id: spells[spell_id]['BaseLevel'] for spell_id in extra_spells if spell_id in spells})
    missing = sorted(wanted - set(spells))
    if missing:
        raise ValueError(f'Spell.dbc lacks class spells {missing}')
    result = []
    for spell_id in sorted(levels):
        chain = chains.get(spell_id, [])
        reached = [spell_id] + [rank for rank, required_level in chain if required_level <= level]
        result.append(ClassSpell(
            spell_id=spell_id,
            name=spells[spell_id]['SpellName[enUS]'],
            ranks=(spell_id,) + tuple(rank for rank, _ in chain),
            max_rank=reached[-1],
            required_level=levels[spell_id],
            passive=bool(spells[spell_id]['Attributes'] & PASSIVE_ATTRIBUTE)))
    return result


def class_skill_lines(dbc_dir: Path, spells: list[ClassSpell], weapon_subclass: int | None) -> list[int]:
    records = Records(dataset(dbc_dir))
    ranked = {rank for spell in spells for rank in spell.ranks}
    weapon_spell = weapon_skill_spells(records).get(weapon_subclass) if weapon_subclass is not None else None
    if weapon_spell:
        ranked.add(weapon_spell)
    return sorted({ability.line for spell_id in ranked for ability in records.abilities(spell_id)})
