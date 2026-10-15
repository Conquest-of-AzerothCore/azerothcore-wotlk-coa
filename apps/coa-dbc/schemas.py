from dataclasses import dataclass
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
STRUCTURES = 'src/server/shared/DataStores/DBCStructure.h'
TALENTS = 'src/server/coa/AscensionCoATalentData.cpp'
CHARGES = 'src/server/coa/AscensionClassMechanics.cpp'
DBC_FIELD_BYTES = 4
SPELL_FIELD_COUNT = 234
SPELL_FIELDS_OMITTED_BY_NATIVE_STRUCTURE = ((13, 'StancesHigh'), (15, 'StancesNotHigh'))
LOCALES = ['enUS', 'koKR', 'frFR', 'deDE', 'zhCN', 'zhTW', 'esES', 'esMX', 'ruRU']


@dataclass(frozen=True)
class Field:
    name: str
    offset: int
    kind: str = 'I'
    target: str | None = None
    enum: str | None = None
    unit: str | None = None


@dataclass(frozen=True)
class Schema:
    fields: int
    size: int
    columns: tuple
    source: str
    key: str = 'ID'
    version: str = 'coa-wdbc-v1'


def column(name, index, kind='I', target=None, enum=None, unit=None):
    return Field(name, index * DBC_FIELD_BYTES, kind, target, enum, unit)


def group(name, index, count, kind='I', target=None):
    return [column(f'{name}[{i}]', index + i, kind, target) for i in range(count)]


def localized(name, index):
    return [column(f'{name}[{LOCALES[i] if i < len(LOCALES) else "locale" + str(i)}]', index + i, 's')
            for i in range(16)]


def spell_fields_from_native_offset_annotations(root):
    source = (root / STRUCTURES).read_text(encoding='utf-8')
    body = source.split('struct SpellEntry\n{', 1)[1].split('\n};', 1)[0]
    fields_by_disk_index = {}
    for line in body.splitlines():
        match = re.search(r'(?:uint32|int32|float|flag96|char const\*|std::array<[^>]+>)\s+'
                          r'(\w+)(?:\[[^]]+\])?;\s*//\s*(\d+)(?:-(\d+))?', line)
        if not match:
            continue
        name, first, last = match.groups()
        first, last = int(first), int(last or first)
        kind = ('s' if 'char const*' in line else 'f' if 'float' in line
                else 'i' if 'int32' in line.replace('uint32', '') else 'I')
        for i in range(first, last + 1):
            field_name = name if first == last else f'{name}[{i-first}]'
            if kind == 's':
                locale = LOCALES[i-first] if i-first < len(LOCALES) else f'locale{i-first}'
                field_name = f'{name}[{locale}]'
            fields_by_disk_index[i] = column(field_name, i, kind)
    return fields_by_disk_index


def spell_schema(root):
    fields_by_disk_index = spell_fields_from_native_offset_annotations(root)
    for index, name in SPELL_FIELDS_OMITTED_BY_NATIVE_STRUCTURE:
        fields_by_disk_index[index] = column(name, index)
    expected_indices = set(range(SPELL_FIELD_COUNT))
    if set(fields_by_disk_index) != expected_indices:
        missing_indices = sorted(expected_indices - fields_by_disk_index.keys())
        raise ValueError(f'Spell schema annotations changed; missing fields: {missing_indices}')
    refs = {'CastingTimeIndex': 'SpellCastTimes', 'DurationIndex': 'SpellDuration', 'RangeIndex': 'SpellRange',
            'EffectRadiusIndex': 'SpellRadius', 'EffectTriggerSpell': 'Spell', 'CasterAuraSpell': 'Spell',
            'TargetAuraSpell': 'Spell', 'ExcludeCasterAuraSpell': 'Spell', 'ExcludeTargetAuraSpell': 'Spell'}
    enums = {'Effect': 'SpellEffects', 'EffectApplyAuraName': 'AuraType', 'EffectImplicitTargetA': 'Targets',
             'EffectImplicitTargetB': 'Targets', 'SchoolMask': 'SpellSchoolMask', 'DmgClass': 'SpellDmgClass'}
    for i, field in fields_by_disk_index.items():
        base = field.name.split('[')[0]
        enum = base if base.startswith('Attributes') else enums.get(base)
        milliseconds = ('RecoveryTime', 'CategoryRecoveryTime', 'StartRecoveryTime', 'EffectAmplitude')
        unit = 'ms' if base in milliseconds else None
        fields_by_disk_index[i] = Field(field.name, field.offset, field.kind, refs.get(base), enum, unit)
    columns = tuple(fields_by_disk_index[i] for i in range(SPELL_FIELD_COUNT))
    return Schema(SPELL_FIELD_COUNT, SPELL_FIELD_COUNT * DBC_FIELD_BYTES, columns, STRUCTURES, key='Id')


def registry(root=ROOT):
    def schema(count, columns, source=STRUCTURES, size=None, key='ID'):
        return Schema(count, size or count * DBC_FIELD_BYTES, tuple(columns), source, key)

    identity = [column('ID', 0)]
    return {
        'Spell': spell_schema(root),
        'SpellDuration': schema(4, identity + [column('Duration', 1, 'i', unit='ms'),
            column('DurationPerLevel', 2, 'i', unit='ms/level'), column('MaxDuration', 3, 'i', unit='ms')]),
        'SpellRadius': schema(4, identity + [column('RadiusMin', 1, 'f', unit='yards'),
            column('RadiusPerLevel', 2, 'f', unit='yards/level'), column('RadiusMax', 3, 'f', unit='yards')]),
        'SpellRange': schema(40, identity + group('RangeMin', 1, 2, 'f') + group('RangeMax', 3, 2, 'f')
            + [column('Flags', 5)] + localized('DisplayName', 6) + localized('DisplayNameShort', 23)),
        'SpellCastTimes': schema(4, identity + [column('CastTime', 1, 'i', unit='ms')]),
        'Talent': schema(23, identity + [column('TalentTab', 1, target='TalentTab'), column('Row', 2),
            column('Col', 3)] + group('RankID', 4, 5, target='Spell')
            + [column('DependsOn', 13, target='Talent'), column('DependsOnRank', 16), column('AddToSpellBook', 19)]),
        'TalentTab': schema(24, identity + localized('Name', 1) + [column('ClassMask', 20),
            column('PetTalentMask', 21), column('TabPage', 22)]),
        'SkillLineAbility': schema(14, identity + [column('SkillLine', 1), column('Spell', 2, target='Spell'),
            column('RaceMask', 3), column('ClassMask', 4), column('MinSkillLineRank', 7),
            column('SupercededBySpell', 8, target='Spell'), column('AcquireMethod', 9),
            column('TrivialSkillLineRankHigh', 10), column('TrivialSkillLineRankLow', 11)]),
        'CharacterAdvancement': schema(179, identity + group('RequiredEntry', 2, 3, target='CharacterAdvancement')
            + group('RankSpell', 5, 5, target='Spell') + [column('AbilityEssenceCost', 14),
            column('TalentEssenceCost', 15), column('RequiredLevel', 26), column('Group', 29),
            column('ClassType', 32, target='CharacterAdvancementClassTypes'),
            column('Tab', 33, target='CharacterAdvancementTabTypes')], TALENTS, 692),
        'CharacterAdvancementClassTypes': schema(23, identity + [column('ClassID', 2),
            column('CustomClass', 4)], TALENTS),
        'CharacterAdvancementTabTypes': schema(19, identity + [column('Token', 1, 's')], TALENTS),
        'ChrSpecs': schema(65, identity + [column('ClassToken', 1, 's'), column('TabToken', 2, 's'),
            column('IdentityEntry', 28, target='CharacterAdvancement')], TALENTS),
        'SpellCharges': schema(2, [column('Spell', 0, target='Spell'),
            column('Category', 1, target='SpellChargesCategory')], CHARGES, key='Spell'),
        'SpellChargesCategory': schema(3, identity + [column('MaxCharges', 1),
            column('RecoveryTime', 2, unit='ms')], CHARGES),
        'SpellAddon': schema(23, identity + [column('Spell', 1, target='Spell')]
            + group('ClientAuraType', 20, 3), '.agents/docs/systems/ascension-spell-parity.md'),
        'SpellCustomAttr': schema(11, identity + [column('Spell', 1, target='Spell'),
            column('CustomAttributes', 2)], '.agents/docs/systems/ascension-spell-parity.md'),
    }
