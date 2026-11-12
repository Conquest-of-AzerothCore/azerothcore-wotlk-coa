from dataclasses import dataclass, field, replace
import math
from pathlib import Path
import re
import struct
import sys
from weakref import WeakKeyDictionary

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'coa-dbc'))
from inspect_dbc import DataSet
from streamed import streamed_field

SPELL_POWER_SCHOOLS = {'sph': 1, 'spfi': 2, 'spn': 3, 'spfr': 4, 'sps': 5, 'spa': 6}
EFFECTIVE_STATS = {'STR': 0, 'AGI': 1, 'STA': 2, 'INT': 3, 'SPI': 4}
EFFECT_DIGITS = '123'
POINTS_LETTERS = 'sSmM'
SINGLE_VALUE_LETTERS = 'sS'
SECONDS_DIVISOR = 1000
MAX_EXPANSION_DEPTH = 3
VARIABLE_RECORD = struct.Struct('<2I')
ABILITY_RECORD = struct.Struct('<7I')
ABILITY_LAYOUT = (14, 56)
RACE_CLASS_RECORD = struct.Struct('<4I')
RACE_CLASS_LAYOUT = (8, 32)
CHARACTER_BASE_RECORD = struct.Struct('<2B')
CHARACTER_BASE_LAYOUT = (2, 2)
ITEM_SUBCLASS_RECORD = struct.Struct('<2i')
ITEM_SUBCLASS_LAYOUT = (44, 176)
ALL_MASK_BITS = 0xFFFFFFFF
PASSIVE_ATTRIBUTE = 0x40
WEAPON_ITEM_CLASS = 2
RANK_FROM_OWN_SPELL_TARGETS = 0x10
RANK_FROM_OWN_SPELL_ATTRIBUTE_EX2 = 0x8000000
WEAPON_EFFECT = 25
CHARACTER_LEVEL_ATTRIBUTE_EX2 = 0x1000000
SKILL_PER_LEVEL = 5
AMPLITUDE_LETTERS = 'tT'
FIRST_PROC_FLAG = 1
FIRST_PROC_FLAG_PERIOD_MS = 5000
HASTED_PERIOD_ATTRIBUTE_EX5 = 0x2000
UNHASTED_PERIOD_ATTRIBUTE_EX3 = 0x20000000
TICKING_AURAS = frozenset({3, 8, 20, 21, 23, 24, 48, 53, 62, 64, 89, 162, 226, 227})
PER_TICK = 'tick'
OVER_TICKS = 'total'
MIXED_PERIOD = 'mixed'
PERIOD_PROBE_FACTOR = 2
PERIODIC_TOTAL_LETTERS = 'oO'
PERIODIC_AT_APPLY_ATTRIBUTE_EX5 = 0x200
DEFAULT_PERIOD_MS = 5000

COLOR_CODE = re.compile(r'\|[cC][0-9a-fA-F]{8}|\|[rR]')
EXTENSION_MARKUP = re.compile(r'@+[^@]*@?')
SPELL_MARKUP = re.compile(r'@s:(?P<spell>\d+):(?P<flags>-?\d+)@')
TOKEN_SPELL = re.compile(r'\$(\d+)')
SPELL_TOKEN = re.compile(r'(?P<spell>\d*)(?P<letter>[A-Za-z])(?P<digit>[1-9]?)')
SINGLE_CONDITION = re.compile(r'[sS](\d+)')
SCALED_TOKEN = re.compile(r'(?P<operator>[/*])(?P<factor>\d+);')
FORMAT_SUFFIX = re.compile(r'\.[1-9]')
NAMED_VARIABLE = re.compile(r'<(\w+)>')
SECONDS_UNIT = re.compile(r'\s*sec')
VARIABLE_DEFINITION = re.compile(r'\$(\w+)=')
VARIABLE_EXPRESSION = re.compile(r'\$\{([^}]*)\}(?:\.[1-9])?')
EXPRESSION_TOKEN = re.compile(r'\s*(?:(?P<number>\d+\.?\d*|\.\d+)|\$<(?P<variable>\w+)>'
                              r'|\$(?P<spell>\d*)(?P<name>[A-Za-z]+\d?)|(?P<operator>[-+*/()]))')
PLURAL_OR_GENDER = 'lLgG'


class Unreadable(Exception):
    def __init__(self, reason: str = ''):
        super().__init__(reason)
        self.reason = reason


@dataclass(frozen=True)
class CasterStats:
    level: int
    ap: float
    rap: float
    sp_by_school: dict[int, float]
    stats: dict[int, float]
    skills: dict[int, float] = field(default_factory=dict)
    weapon_subclass: int | None = None
    race: int | None = None
    class_id: int | None = None
    known_spells: frozenset[int] = field(default_factory=frozenset)


@dataclass(frozen=True)
class Ability:
    line: int
    race_mask: int
    class_mask: int
    exclude_race: int
    exclude_class: int


@dataclass(frozen=True)
class Displayed:
    text: str
    value: float
    effect_index: int | None
    kind: str
    spell_id: int | None = None


@dataclass(frozen=True)
class Readout:
    values: list[Displayed]
    unreadable: list[str]


@dataclass(frozen=True)
class Variable:
    value: float | None
    effect_index: int | None
    spell_id: int | None = None
    reason: str = ''


DERIVED_TABLE_CACHE: 'WeakKeyDictionary[DataSet, dict]' = WeakKeyDictionary()


def derived_table_cache(dbc: DataSet) -> dict:
    cache = DERIVED_TABLE_CACHE.get(dbc)
    if cache is None:
        cache = {'raw': {}, 'ability_index': None, 'weapon_skills': None}
        DERIVED_TABLE_CACHE[dbc] = cache
    return cache


class Records:
    def __init__(self, dbc: DataSet):
        self.dbc = dbc
        self.columns = {}
        self._derived = derived_table_cache(dbc)

    @property
    def raw(self) -> dict:
        return self._derived['raw']

    @property
    def ability_index(self):
        return self._derived['ability_index']

    @ability_index.setter
    def ability_index(self, value) -> None:
        self._derived['ability_index'] = value

    @property
    def weapon_skills(self):
        return self._derived['weapon_skills']

    @weapon_skills.setter
    def weapon_skills(self, value) -> None:
        self._derived['weapon_skills'] = value

    def field(self, table_name: str, identity: int, name: str):
        value = self.dbc_field(table_name, identity, name)
        streamed = streamed_field(identity, name) if table_name == 'Spell' else None
        return value if streamed is None else streamed

    def dbc_field(self, table_name: str, identity: int, name: str):
        table, schema, index, _ = self.dbc.load(table_name)
        if table_name not in self.columns:
            self.columns[table_name] = {column.name: column for column in schema.columns}
        if identity not in index:
            raise Unreadable
        value, error = self.dbc.value(table, index[identity], self.columns[table_name][name])
        if error:
            raise Unreadable
        return value

    def has_spell(self, spell_id: int) -> bool:
        return spell_id in self.dbc.load('Spell')[2]

    def per_level(self, spell_id: int, effect: int) -> float:
        return self.field('Spell', spell_id, f'EffectRealPointsPerLevel[{effect}]')

    def points(self, spell_id: int, effect: int, upper: bool, level: int | None = None) -> float:
        per_level = self.per_level(spell_id, effect)
        if per_level != 0 and level is None:
            raise Unreadable(f'EffectRealPointsPerLevel[{effect}] of spell {spell_id}')
        base = self.field('Spell', spell_id, f'EffectBasePoints[{effect}]')
        points = base + self.field('Spell', spell_id, f'EffectDieSides[{effect}]') if upper else base + 1
        if not per_level:
            return float(points)
        return float(points + per_level * self.levels_above_base(spell_id, level))

    def levels_above_base(self, spell_id: int, level: int) -> int:
        base_level = self.field('Spell', spell_id, 'BaseLevel')
        return max(0, level - base_level if base_level > 0 else level)

    def single_value(self, spell_id: int, effect: int, level: int | None = None) -> float:
        if self.field('Spell', spell_id, f'EffectDieSides[{effect}]') != 1:
            raise Unreadable
        return self.points(spell_id, effect, upper=False, level=level)

    def raw_records(self, table_name: str, layout: tuple[int, int], record: struct.Struct) -> list[tuple]:
        if table_name not in self.raw:
            table = self.dbc.load(table_name)[0]
            if (table.fields, table.record_size) != layout:
                raise ValueError(f'{table.name}: unsupported layout {table.fields}/{table.record_size}')
            self.raw[table_name] = [record.unpack_from(table.record(row)) for row in range(table.rows)]
        return self.raw[table_name]

    def abilities(self, spell_id: int) -> list[Ability]:
        if self.ability_index is None:
            self.ability_index = {}
            for _, line, spell, *masks in self.raw_records('SkillLineAbility', ABILITY_LAYOUT, ABILITY_RECORD):
                self.ability_index.setdefault(spell, []).append(Ability(line, *masks))
        return self.ability_index.get(spell_id, [])

    def race_class_info(self, line: int) -> list[tuple[int, int]]:
        return [(race_mask, class_mask) for _, skill, race_mask, class_mask
                in self.raw_records('SkillRaceClassInfo', RACE_CLASS_LAYOUT, RACE_CLASS_RECORD) if skill == line]

    def has_character_base(self, race: int, class_id: int) -> bool:
        return (race, class_id) in self.raw_records('CharBaseInfo', CHARACTER_BASE_LAYOUT, CHARACTER_BASE_RECORD)

    def weapon_subclass_count(self) -> int:
        subclasses = [subclass for item_class, subclass
                      in self.raw_records('ItemSubClass', ITEM_SUBCLASS_LAYOUT, ITEM_SUBCLASS_RECORD)
                      if item_class == WEAPON_ITEM_CLASS]
        return max(subclasses) + 1 if subclasses else 0

    def duration_ms(self, spell_id: int) -> float:
        index = self.field('Spell', spell_id, 'DurationIndex')
        if self.field('SpellDuration', index, 'DurationPerLevel') != 0:
            raise Unreadable(f'DurationPerLevel of spell {spell_id}')
        duration = min(self.field('SpellDuration', index, 'Duration'),
                       self.field('SpellDuration', index, 'MaxDuration'))
        if duration <= 0:
            raise Unreadable
        return float(duration)

    def amplitude_ms(self, spell_id: int, effect: int, shown_as_text: bool = False) -> float:
        if self.field('Spell', spell_id, 'ProcFlags') & FIRST_PROC_FLAG:
            return float(FIRST_PROC_FLAG_PERIOD_MS)
        if (shown_as_text and self.field('Spell', spell_id, 'AttributesEx5') & HASTED_PERIOD_ATTRIBUTE_EX5
                and not self.field('Spell', spell_id, 'AttributesEx3') & UNHASTED_PERIOD_ATTRIBUTE_EX3):
            raise Unreadable(f'AttributesEx5 0x2000 of spell {spell_id}: the client hastes the shown period by the '
                             f'cast speed, which is not measured')
        amplitude = self.field('Spell', spell_id, f'EffectAmplitude[{effect}]')
        if amplitude <= 0:
            raise Unreadable(f'EffectAmplitude[{effect}] {amplitude} of spell {spell_id}')
        return float(amplitude)

    def radius(self, spell_id: int, effect: int) -> float:
        index = self.field('Spell', spell_id, f'EffectRadiusIndex[{effect}]')
        return float(self.field('SpellRadius', index, 'RadiusMin'))

    def periodic_total(self, spell_id: int, effect: int, points: float) -> float:
        try:
            period = self.amplitude_ms(spell_id, effect)
        except Unreadable:
            period = float(DEFAULT_PERIOD_MS)
        duration = self.duration_ms(spell_id)
        if self.field('Spell', spell_id, 'AttributesEx5') & PERIODIC_AT_APPLY_ATTRIBUTE_EX5:
            duration += period
        return points * duration / period

    def variable_formulas(self, spell_id: int) -> str | None:
        identity = self.field('Spell', spell_id, 'SpellDescriptionVariableID')
        if not identity:
            return ''
        table = self.dbc.load('SpellDescriptionVariables')[0]
        if (table.fields, table.record_size) != (2, VARIABLE_RECORD.size):
            raise ValueError(f'{table.name}: unsupported layout {table.fields}/{table.record_size}')
        for row in range(table.rows):
            record_id, offset = VARIABLE_RECORD.unpack(table.record(row))
            if record_id == identity:
                return table.string(offset).decode('utf-8')
        return None


def mask_matches(value: int, mask: int, exclude: int) -> bool:
    mask = mask ^ ALL_MASK_BITS if exclude else mask
    return not mask or bool((1 << (value - 1)) & mask)


def ability_line(records: Records, spell_id: int, race: int, class_id: int) -> int | None:
    if not records.has_character_base(race, class_id):
        return None
    lines = {ability.line for ability in records.abilities(spell_id)
             if mask_matches(race, ability.race_mask, ability.exclude_race)
             and mask_matches(class_id, ability.class_mask, ability.exclude_class)
             and any(mask_matches(race, race_mask, 0) and mask_matches(class_id, class_mask, 0)
                     for race_mask, class_mask in records.race_class_info(ability.line))}
    if len(lines) > 1:
        raise Unreadable(f'spell {spell_id} has SkillLineAbility rows on lines {sorted(lines)}')
    return next(iter(lines), None)


def weapon_skill_spells(records: Records) -> dict[int, int]:
    if records.weapon_skills is None:
        count = records.weapon_subclass_count()
        table, schema, index, _ = records.dbc.load('Spell')
        columns = {column.name: column for column in schema.columns}
        spells = {}
        for spell_id, row in sorted(index.items(), key=lambda item: item[1], reverse=True):
            if not records.dbc.value(table, row, columns['Attributes'])[0] & PASSIVE_ATTRIBUTE:
                continue
            if records.dbc.value(table, row, columns['EquippedItemClass'])[0] != WEAPON_ITEM_CLASS:
                continue
            mask = records.dbc.value(table, row, columns['EquippedItemSubClassMask'])[0] & ALL_MASK_BITS
            if mask and not mask & (mask - 1) and mask.bit_length() - 1 < count:
                spells[mask.bit_length() - 1] = spell_id
        records.weapon_skills = spells
    return records.weapon_skills


def rank_spell(records: Records, spell_id: int, weapon_subclass: int | None) -> int:
    if weapon_subclass is None:
        return spell_id
    spell = {name: records.field('Spell', spell_id, name) for name in (
        'Targets', 'AttributesEx2', 'Effect[0]', 'EquippedItemClass', 'EquippedItemSubClassMask')}
    if (spell['Targets'] & RANK_FROM_OWN_SPELL_TARGETS or spell['AttributesEx2'] & RANK_FROM_OWN_SPELL_ATTRIBUTE_EX2
            or spell['Effect[0]'] == WEAPON_EFFECT or spell['EquippedItemClass'] != WEAPON_ITEM_CLASS
            or not spell['EquippedItemSubClassMask']):
        return spell_id
    weapon_spell = weapon_skill_spells(records).get(weapon_subclass)
    if not weapon_spell or not (1 << weapon_subclass) & spell['EquippedItemSubClassMask']:
        return spell_id
    return weapon_spell


def spell_rank(records: Records, spell_id: int, caster: CasterStats) -> int:
    ranked = rank_spell(records, spell_id, caster.weapon_subclass)
    if not records.has_spell(ranked) or not records.abilities(ranked):
        return 0
    if caster.race is None or caster.class_id is None:
        raise Unreadable('the race and class of the character are unknown')
    line = ability_line(records, ranked, caster.race, caster.class_id)
    if line is None:
        return 0
    if line not in caster.skills:
        raise Unreadable(f'skill {line} is not measured')
    rank = int(caster.skills[line])
    max_level = records.field('Spell', ranked, 'MaxLevel')
    if max_level > 0 and rank >= SKILL_PER_LEVEL * max_level:
        rank = SKILL_PER_LEVEL * max_level
    return max(rank, 0)


def client_spell_level(records: Records, spell_id: int, caster: CasterStats) -> int:
    return spell_rank(records, spell_id, caster) // SKILL_PER_LEVEL


class ForcedPoints(Records):
    def __init__(self, dbc, spell_id: int, effect: int, value: int):
        super().__init__(dbc)
        self.forced = (spell_id, effect)
        self.value = value

    def points(self, spell_id: int, effect: int, upper: bool, level: int | None = None) -> float:
        if (spell_id, effect) != self.forced:
            return super().points(spell_id, effect, upper, level)
        per_level = self.per_level(spell_id, effect)
        if per_level != 0 and level is None:
            raise Unreadable(f'EffectRealPointsPerLevel[{effect}] of spell {spell_id}')
        if not per_level:
            return float(self.value)
        return float(self.value + per_level * self.levels_above_base(spell_id, level))


class UnscaledForcedPoints(ForcedPoints):
    def per_level(self, spell_id: int, effect: int) -> float:
        return 0.0 if (spell_id, effect) == self.forced else super().per_level(spell_id, effect)


class ScaledPeriod(Records):
    def __init__(self, dbc, spell_id: int, effect: int, duration_factor: int, amplitude_factor: int):
        super().__init__(dbc)
        self.period = (spell_id, effect)
        self.duration_factor = duration_factor
        self.amplitude_factor = amplitude_factor

    def duration_ms(self, spell_id: int) -> float:
        duration = super().duration_ms(spell_id)
        return duration * self.duration_factor if spell_id == self.period[0] else duration

    def amplitude_ms(self, spell_id: int, effect: int, shown_as_text: bool = False) -> float:
        amplitude = super().amplitude_ms(spell_id, effect, shown_as_text)
        return amplitude * self.amplitude_factor if (spell_id, effect) == self.period else amplitude


class Tooltip:
    def __init__(self, records: Records, spell_id: int, caster: CasterStats, expanding: tuple[int, ...] = ()):
        self.records = records
        self.spell_id = spell_id
        self.caster = caster
        self.expanding = expanding + (spell_id,)
        self.variable_cache: dict[int, dict[str, Variable]] = {}
        self.variables = self.variables_for(spell_id)

    def variables_for(self, spell_id: int) -> dict[str, Variable]:
        if spell_id not in self.variable_cache:
            self.variable_cache[spell_id] = {}
            self.compile_variables(spell_id, self.variable_cache[spell_id])
        return self.variable_cache[spell_id]

    def compile_variables(self, spell_id: int, variables: dict[str, Variable]) -> None:
        formulas = self.records.variable_formulas(spell_id)
        if not formulas:
            return
        definitions = list(VARIABLE_DEFINITION.finditer(formulas))
        for position, definition in enumerate(definitions):
            end = definitions[position + 1].start() if position + 1 < len(definitions) else len(formulas)
            body = VARIABLE_EXPRESSION.fullmatch(formulas[definition.end():end].strip())
            try:
                if not body:
                    raise Unreadable
                variables[definition.group(1)] = Variable(*self.evaluate(body.group(1)))
            except Unreadable as error:
                variables[definition.group(1)] = Variable(None, None, reason=error.reason)

    def variable(self, name: str, context_spell_id: int | None = None) -> Variable:
        variables = self.variables if context_spell_id is None else self.variables_for(context_spell_id)
        variable = variables.get(name)
        if variable is None or variable.value is None:
            raise Unreadable(variable.reason if variable else '')
        return variable

    def evaluate(self, expression: str) -> tuple[float, int | None, int | None]:
        tokens = []
        position = 0
        while expression[position:].strip():
            match = EXPRESSION_TOKEN.match(expression, position)
            if not match:
                raise Unreadable
            tokens.append(match)
            position = match.end()
        parser = ExpressionParser(self, tokens)
        value = parser.sum()
        if parser.position != len(tokens):
            raise Unreadable
        return value, parser.effect_index, parser.spell_id

    def spell_reference(self, digits: str) -> int:
        spell_id = int(digits) if digits else self.spell_id
        if not self.records.has_spell(spell_id):
            raise Unreadable
        return spell_id

    def effect_points(self, spell_id: int, effect: int, upper: bool, single: bool = False,
                      named: bool = False) -> float:
        level = None
        if self.records.per_level(spell_id, effect) != 0:
            try:
                level = self.points_level(spell_id, named)
            except Unreadable as error:
                raise Unreadable(f'EffectRealPointsPerLevel[{effect}] of spell {spell_id}: {error.reason}') from None
        if single:
            return self.records.single_value(spell_id, effect, level)
        return self.records.points(spell_id, effect, upper, level)

    def per_level_points(self, spell_id: int, effect: int) -> float:
        per_level = self.records.per_level(spell_id, effect)
        if per_level == 0:
            return 0.0
        return per_level * self.records.levels_above_base(spell_id, self.caster.level)

    def points_level(self, spell_id: int, named: bool) -> int:
        if named and self.records.field('Spell', spell_id, 'AttributesEx2') & CHARACTER_LEVEL_ATTRIBUTE_EX2:
            max_level = self.records.field('Spell', spell_id, 'MaxLevel')
            return max_level if 0 < max_level <= self.caster.level else self.caster.level
        return client_spell_level(self.records, spell_id, self.caster)

    def own_effect(self, spell_id: int, effect: int) -> int | None:
        return effect if spell_id == self.spell_id else None

    def school_spell_power(self, schools) -> float:
        if any(school not in self.caster.sp_by_school for school in schools):
            raise Unreadable
        return min(self.caster.sp_by_school[school] for school in schools)

    def caster_value(self, name: str) -> float:
        if name == 'AP':
            return self.caster.ap
        if name == 'RAP':
            return self.caster.rap
        if name in ('SP', 'sp'):
            return self.school_spell_power(SPELL_POWER_SCHOOLS.values())
        if name.lower() in SPELL_POWER_SCHOOLS and name in (name.lower(), name.upper()):
            return self.school_spell_power([SPELL_POWER_SCHOOLS[name.lower()]])
        if name in ('PL', 'pl'):
            return float(self.caster.level)
        if name in EFFECTIVE_STATS and EFFECTIVE_STATS[name] in self.caster.stats:
            return self.caster.stats[EFFECTIVE_STATS[name]]
        raise Unreadable

    def math_variable(self, digits: str, name: str) -> tuple[float, int | None, int | None]:
        if len(name) == 2 and name[0] in 'mMaA' + AMPLITUDE_LETTERS and name[1] in EFFECT_DIGITS:
            spell_id = self.spell_reference(digits)
            effect = int(name[1]) - 1
            if name[0] in 'aA':
                return self.records.radius(spell_id, effect), None, None
            if name[0] in AMPLITUDE_LETTERS:
                return self.records.amplitude_ms(spell_id, effect), None, None
            return (self.effect_points(spell_id, effect, upper=name[0] == 'M'), self.own_effect(spell_id, effect),
                    spell_id)
        if name[:-1] == 'ppl' and name[-1:] in EFFECT_DIGITS:
            spell_id = self.spell_reference(digits)
            effect = int(name[-1]) - 1
            return self.per_level_points(spell_id, effect), self.own_effect(spell_id, effect), spell_id
        if name in ('h', 'H', 'u', 'U', 'i', 'I', 'd', 'D'):
            spell_id = self.spell_reference(digits)
            return self.spell_counter(spell_id, name.lower()), None, None
        if digits:
            raise Unreadable
        return self.caster_value(name), None, None

    def spell_counter(self, spell_id: int, letter: str) -> float:
        if letter == 'h':
            return float(self.records.field('Spell', spell_id, 'ProcChance'))
        if letter == 'u':
            return float(self.records.field('Spell', spell_id, 'StackAmount'))
        if letter == 'i':
            return float(self.records.field('Spell', spell_id, 'MaxAffectedTargets'))
        return self.records.duration_ms(spell_id) / SECONDS_DIVISOR

    def read(self, description: str) -> Readout:
        values, unreadable = [], []
        position = 0
        while position < len(description):
            character = description[position]
            if character == '$':
                if description[position + 1:position + 2] == '?':
                    end, readout = self.conditional(description, position)
                    values += readout.values
                    unreadable += readout.unreadable
                    position = end
                    continue
                end, value = self.token(description, position)
                if isinstance(value, Displayed):
                    values.append(value)
                else:
                    unreadable.append(unreadable_entry(description[position:end], value))
                position = end
            elif character == '|':
                color = COLOR_CODE.match(description, position)
                if color:
                    position = color.end()
                else:
                    end = escape_end(description, position)
                    unreadable.append(description[position:end])
                    position = end
            elif character == '@':
                markup = SPELL_MARKUP.match(description, position)
                if markup:
                    expanded = self.expansion(markup)
                    values += expanded.values
                    unreadable += expanded.unreadable
                    position = markup.end()
                    continue
                end = EXTENSION_MARKUP.match(description, position).end()
                unreadable.append(description[position:end])
                position = end
            else:
                position += 1
        return Readout(values, unreadable)

    def expansion(self, markup: re.Match) -> Readout:
        spell_id = int(markup.group('spell'))
        try:
            if int(markup.group('flags')) < 0:
                raise Unreadable('negative flags select a shift or partial rendering')
            if not self.records.has_spell(spell_id):
                raise Unreadable(f'spell {spell_id} is not in Spell.dbc')
            if spell_id in self.expanding:
                raise Unreadable('expansion cycle ' + ' -> '.join(map(str, self.expanding + (spell_id,))))
            if len(self.expanding) > MAX_EXPANSION_DEPTH:
                raise Unreadable(f'nesting deeper than {MAX_EXPANSION_DEPTH} expansions')
        except Unreadable as error:
            return Readout([], [unreadable_entry(markup.group(0), error)])
        nested = Tooltip(self.records, spell_id, self.caster, self.expanding)
        readout = nested.read(self.records.field('Spell', spell_id, 'Description[enUS]'))
        return Readout([referenced(value, spell_id) for value in readout.values], readout.unreadable)

    def token(self, text: str, start: int) -> tuple[int, Displayed | Unreadable | None]:
        position = start + 1
        following = text[position:position + 1]
        if following == '{':
            return self.expression_token(text, start)
        if following == '<':
            return self.variable_token(text, start)
        return self.spell_token(text, start)

    def conditional(self, text: str, start: int) -> tuple[int, Readout]:
        cond_start = start + 2
        true_start, true_end, false_start, false_end, end, chained = conditional_bounds(text, cond_start)
        if true_end < 0:
            return end, Readout([], [unreadable_entry(text[start:end], Unreadable('malformed $? conditional'))])
        if chained:
            return end, Readout([], [unreadable_entry(
                text[start:end], Unreadable(f'{text[start:end]} chains a nested $? conditional, not read'))])
        match = SINGLE_CONDITION.fullmatch(text[cond_start:true_start])
        if not match:
            return end, Readout([], [unreadable_entry(
                text[start:end],
                Unreadable(f'{text[start:end]} uses an unhandled $? operator (only a single sN/SN atom is read)'))])
        if int(match.group(1)) in self.caster.known_spells:
            chosen = text[true_start + 1:true_end]
        else:
            chosen = text[false_start + 1:false_end] if false_end >= 0 else ''
        return end, self.read(chosen)

    def expression_token(self, text: str, start: int) -> tuple[int, Displayed | Unreadable | None]:
        close = text.find('}', start)
        if close < 0:
            return len(text), None
        end = close + 1
        suffix = FORMAT_SUFFIX.match(text, end)
        if suffix:
            end = suffix.end()
        try:
            value, effect_index, spell_id = self.evaluate(text[start + 2:close])
        except Unreadable as error:
            return end, error
        return end, Displayed(text[start:end], value, effect_index, percent_or_flat(text, end), spell_id)

    def variable_token(self, text: str, start: int) -> tuple[int, Displayed | Unreadable | None]:
        match = NAMED_VARIABLE.match(text, start + 1)
        if not match:
            return start + 2, None
        try:
            variable = self.variable(match.group(1))
        except Unreadable as error:
            return match.end(), error
        return match.end(), Displayed(text[start:match.end()], variable.value, variable.effect_index,
                                      percent_or_flat(text, match.end()), variable.spell_id)

    def spell_token(self, text: str, start: int) -> tuple[int, Displayed | Unreadable | None]:
        position = start + 1
        scaled = SCALED_TOKEN.match(text, position)
        if scaled:
            position = scaled.end()
        match = SPELL_TOKEN.match(text, position)
        if not match:
            digits = re.match(r'\d*', text[position:]).group(0)
            return max(position + len(digits), start + 1), None
        end = match.end()
        if match.group('letter') in PLURAL_OR_GENDER:
            semicolon = text.find(';', end)
            return (semicolon + 1 if semicolon >= 0 else len(text)), None
        try:
            value = self.spell_token_value(match, scaled, text, end)
        except Unreadable as error:
            return end, error
        return end, Displayed(text[start:end], *value)

    def spell_token_value(self, match, scaled, text: str, end: int) -> tuple[float, int | None, str, int | None]:
        letter, digit = match.group('letter'), match.group('digit')
        spell_id = self.spell_reference(match.group('spell'))
        if letter in POINTS_LETTERS and digit and digit in EFFECT_DIGITS:
            effect = int(digit) - 1
            points = abs(self.effect_points(spell_id, effect, upper=letter == 'M',
                                            single=letter in SINGLE_VALUE_LETTERS, named=bool(match.group('spell'))))
            effect_index = self.own_effect(spell_id, effect)
            if not scaled:
                return points, effect_index, percent_or_flat(text, end), spell_id
            factor = int(scaled.group('factor'))
            if scaled.group('operator') != '/' or factor == 0:
                raise Unreadable
            if factor == SECONDS_DIVISOR and SECONDS_UNIT.match(text, end):
                return points, effect_index, 'duration_ms', spell_id
            return points / factor, effect_index, percent_or_flat(text, end), spell_id
        if scaled:
            raise Unreadable
        if letter in 'aA' and digit and digit in EFFECT_DIGITS:
            effect = int(digit) - 1
            return self.records.radius(spell_id, effect), self.own_effect(spell_id, effect), 'radius_yards', spell_id
        if letter in AMPLITUDE_LETTERS and digit and digit in EFFECT_DIGITS:
            effect = int(digit) - 1
            amplitude = self.records.amplitude_ms(spell_id, effect, shown_as_text=True)
            return amplitude, self.own_effect(spell_id, effect), 'amplitude_ms', spell_id
        if letter in PERIODIC_TOTAL_LETTERS and digit and digit in EFFECT_DIGITS:
            effect = int(digit) - 1
            points = abs(self.effect_points(spell_id, effect, upper=False, single=True,
                                            named=bool(match.group('spell'))))
            total = self.records.periodic_total(spell_id, effect, points)
            return total, self.own_effect(spell_id, effect), percent_or_flat(text, end), spell_id
        if letter in 'hH':
            return self.spell_counter(spell_id, 'h'), None, 'chance_pct', None
        if letter in 'dD':
            return self.records.duration_ms(spell_id), None, 'duration_ms', None
        if letter in 'uUiI':
            return self.spell_counter(spell_id, letter.lower()), None, 'count', None
        raise Unreadable


class ExpressionParser:
    def __init__(self, tooltip: Tooltip, tokens: list):
        self.tooltip = tooltip
        self.tokens = tokens
        self.position = 0
        self.effect_index = None
        self.spell_id = None

    def peek(self) -> str | None:
        if self.position < len(self.tokens):
            return self.tokens[self.position].group('operator')
        return None

    def sum(self) -> float:
        value = self.product()
        while self.peek() in ('+', '-'):
            operator = self.peek()
            self.position += 1
            right = self.product()
            value = value + right if operator == '+' else value - right
        return value

    def product(self) -> float:
        value = self.unary()
        while self.peek() in ('*', '/'):
            operator = self.peek()
            self.position += 1
            right = self.unary()
            if operator == '/' and right == 0:
                raise Unreadable
            value = value * right if operator == '*' else value / right
        return value

    def unary(self) -> float:
        if self.peek() == '-':
            self.position += 1
            return -self.unary()
        return self.primary()

    def primary(self) -> float:
        if self.position >= len(self.tokens):
            raise Unreadable
        token = self.tokens[self.position]
        self.position += 1
        if token.group('operator') == '(':
            value = self.sum()
            if self.peek() != ')':
                raise Unreadable
            self.position += 1
            return value
        if token.group('number'):
            return float(token.group('number'))
        if token.group('variable'):
            context = self.spell_id if self.spell_id is not None else self.tooltip.spell_id
            return self.tooltip.variable(token.group('variable'), context).value
        if token.group('name'):
            value, effect_index, spell_id = self.tooltip.math_variable(token.group('spell'), token.group('name'))
            if self.effect_index is None:
                self.effect_index = effect_index
            if self.spell_id is None:
                self.spell_id = spell_id
            return value
        raise Unreadable


def referenced(value: Displayed, spell_id: int) -> Displayed:
    if value.spell_id is None:
        named = TOKEN_SPELL.match(value.text)
        spell_id = int(named.group(1)) if named else spell_id
    else:
        spell_id = value.spell_id
    return replace(value, effect_index=None, spell_id=spell_id)


def unreadable_entry(text: str, error: Unreadable | None) -> str:
    return f'{text} [{error.reason}]' if error is not None and error.reason else text


def percent_or_flat(text: str, end: int) -> str:
    return 'percent' if text[end:end + 1] == '%' else 'flat'


def escape_end(text: str, start: int) -> int:
    if text[start + 1:start + 2] == 'T':
        close = text.find('|t', start + 2)
        return close + 2 if close >= 0 else len(text)
    return min(start + 2, len(text))


def conditional_bounds(text: str, start: int) -> tuple[int, int, int, int, int, bool]:
    true_start = text.find('[', start)
    true_end = text.find(']', true_start) if true_start >= 0 else -1
    if true_end < 0:
        return true_start, -1, -1, -1, len(text), False
    if text[true_end + 1:true_end + 2] == '?':
        _, _, _, _, end, _ = conditional_bounds(text, true_end + 2)
        return true_start, true_end, -1, -1, end, True
    false_start = text.find('[', true_end)
    false_end = text.find(']', false_start) if false_start >= 0 else -1
    end = false_end + 1 if false_end >= 0 else len(text)
    return true_start, true_end, false_start, false_end, end, False


def period_reading(records: Records, spell_id: int, caster: CasterStats, shown: Displayed, effect: int) -> str:
    def reread(duration_factor: int, amplitude_factor: int) -> float:
        scaled = ScaledPeriod(records.dbc, spell_id, effect, duration_factor, amplitude_factor)
        values = Tooltip(scaled, spell_id, caster).read(shown.text).values
        if len(values) != 1:
            raise Unreadable(f'{shown.text} is unreadable with a scaled duration or period')
        return values[0].value

    alone, longer, slower = reread(1, 1), reread(PERIOD_PROBE_FACTOR, 1), reread(1, PERIOD_PROBE_FACTOR)
    if math.isclose(longer, alone) and math.isclose(slower, alone):
        return PER_TICK
    if math.isclose(longer, alone * PERIOD_PROBE_FACTOR) and math.isclose(slower, alone / PERIOD_PROBE_FACTOR):
        return OVER_TICKS
    return MIXED_PERIOD


def mixed_period_reason(text: str, effect: int) -> str:
    return f'{text} changes with the duration or the period of effect {effect} without being a total over its ticks'


def read_tooltip(dbc: DataSet, spell_id: int, caster: CasterStats) -> Readout:
    records = Records(dbc)
    if not records.has_spell(spell_id):
        raise ValueError(f'Spell {spell_id} is not in Spell.dbc')
    description = records.field('Spell', spell_id, 'Description[enUS]')
    return Tooltip(records, spell_id, caster).read(description)
