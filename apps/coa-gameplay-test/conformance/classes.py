from dataclasses import dataclass
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'coa-dbc'))
from inspect_dbc import DataSet
from tooltip import PASSIVE_ATTRIBUTE, Records, weapon_skill_spells

CHARACTER_LEVEL = 60
RANK_SLOTS = 5
PROGRESSION_HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'
PROGRESSION_ROW = re.compile(r'^\s*\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\},?\s*$', re.MULTILINE)


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


def progression_chains(header: Path, class_id: int) -> dict[int, list[tuple[int, int]]]:
    chains: dict[int, list[tuple[int, int]]] = {}
    for row_class, first_spell, spell, required_level in PROGRESSION_ROW.findall(header.read_text(encoding='utf-8')):
        if int(row_class) == class_id:
            chains.setdefault(int(first_spell), []).append((int(spell), int(required_level)))
    return chains


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


def class_spells(dbc_dir: Path, class_id: int, progression_header: Path,
                 level: int = CHARACTER_LEVEL) -> list[ClassSpell]:
    dataset = DataSet(dbc_dir)
    levels = advancement_levels(dataset, class_type_ids(dataset, class_id))
    chains = progression_chains(progression_header, class_id)
    spells = {identity: fields for identity, fields in table_rows(dataset, 'Spell', ['SpellName[enUS]', 'Attributes'])
              if identity in levels}
    missing = sorted(set(levels) - set(spells))
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
    records = Records(DataSet(dbc_dir))
    ranked = {rank for spell in spells for rank in spell.ranks}
    weapon_spell = weapon_skill_spells(records).get(weapon_subclass) if weapon_subclass is not None else None
    if weapon_spell:
        ranked.add(weapon_spell)
    return sorted({ability.line for spell_id in ranked for ability in records.abilities(spell_id)})
