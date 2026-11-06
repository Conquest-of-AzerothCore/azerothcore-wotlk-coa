from dataclasses import dataclass
from pathlib import Path
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'coa-dbc'))
from inspect_dbc import DataSet

SPELL_POWER_SCHOOLS = {'sph': 1, 'spfi': 2, 'spn': 3, 'spfr': 4, 'sps': 5, 'spa': 6}
EFFECTIVE_STATS = {'STR': 0, 'AGI': 1, 'STA': 2, 'INT': 3, 'SPI': 4}
EFFECT_DIGITS = '123'
POINTS_LETTERS = 'sSmM'
SINGLE_VALUE_LETTERS = 'sS'
SECONDS_DIVISOR = 1000
VARIABLE_RECORD = struct.Struct('<2I')

COLOR_CODE = re.compile(r'\|[cC][0-9a-fA-F]{8}|\|[rR]')
EXTENSION_MARKUP = re.compile(r'@+[^@]*@?')
SPELL_TOKEN = re.compile(r'(?P<spell>\d*)(?P<letter>[A-Za-z])(?P<digit>[1-9]?)')
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


class Records:
    def __init__(self, dbc: DataSet):
        self.dbc = dbc
        self.columns = {}

    def field(self, table_name: str, identity: int, name: str):
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

    def points(self, spell_id: int, effect: int, upper: bool) -> float:
        if self.field('Spell', spell_id, f'EffectRealPointsPerLevel[{effect}]') != 0:
            raise Unreadable(f'EffectRealPointsPerLevel[{effect}] of spell {spell_id}')
        base = self.field('Spell', spell_id, f'EffectBasePoints[{effect}]')
        return float(base + self.field('Spell', spell_id, f'EffectDieSides[{effect}]') if upper else base + 1)

    def single_value(self, spell_id: int, effect: int) -> float:
        if self.field('Spell', spell_id, f'EffectDieSides[{effect}]') != 1:
            raise Unreadable
        return self.points(spell_id, effect, upper=False)

    def duration_ms(self, spell_id: int) -> float:
        index = self.field('Spell', spell_id, 'DurationIndex')
        if self.field('SpellDuration', index, 'DurationPerLevel') != 0:
            raise Unreadable(f'DurationPerLevel of spell {spell_id}')
        duration = min(self.field('SpellDuration', index, 'Duration'),
                       self.field('SpellDuration', index, 'MaxDuration'))
        if duration <= 0:
            raise Unreadable
        return float(duration)

    def radius(self, spell_id: int, effect: int) -> float:
        index = self.field('Spell', spell_id, f'EffectRadiusIndex[{effect}]')
        return float(self.field('SpellRadius', index, 'RadiusMin'))

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


class ForcedPoints(Records):
    def __init__(self, dbc, spell_id: int, effect: int, value: int):
        super().__init__(dbc)
        self.forced = (spell_id, effect)
        self.value = value

    def points(self, spell_id: int, effect: int, upper: bool) -> float:
        if (spell_id, effect) != self.forced:
            return super().points(spell_id, effect, upper)
        if self.field('Spell', spell_id, f'EffectRealPointsPerLevel[{effect}]') != 0:
            raise Unreadable(f'EffectRealPointsPerLevel[{effect}] of spell {spell_id}')
        return float(self.value)


class Tooltip:
    def __init__(self, records: Records, spell_id: int, caster: CasterStats):
        self.records = records
        self.spell_id = spell_id
        self.caster = caster
        self.variables = self.read_variables()

    def read_variables(self) -> dict[str, Variable]:
        formulas = self.records.variable_formulas(self.spell_id)
        if formulas is None:
            return {}
        self.variables = {}
        definitions = list(VARIABLE_DEFINITION.finditer(formulas))
        for position, definition in enumerate(definitions):
            end = definitions[position + 1].start() if position + 1 < len(definitions) else len(formulas)
            body = VARIABLE_EXPRESSION.fullmatch(formulas[definition.end():end].strip())
            try:
                if not body:
                    raise Unreadable
                self.variables[definition.group(1)] = Variable(*self.evaluate(body.group(1)))
            except Unreadable as error:
                self.variables[definition.group(1)] = Variable(None, None, reason=error.reason)
        return self.variables

    def variable(self, name: str) -> Variable:
        variable = self.variables.get(name)
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
        if len(name) == 2 and name[0] in 'mMaA' and name[1] in EFFECT_DIGITS:
            spell_id = self.spell_reference(digits)
            effect = int(name[1]) - 1
            if name[0] in 'aA':
                return self.records.radius(spell_id, effect), None, None
            return (self.records.points(spell_id, effect, upper=name[0] == 'M'), self.own_effect(spell_id, effect),
                    spell_id)
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
                end = EXTENSION_MARKUP.match(description, position).end()
                unreadable.append(description[position:end])
                position = end
            else:
                position += 1
        return Readout(values, unreadable)

    def token(self, text: str, start: int) -> tuple[int, Displayed | Unreadable | None]:
        position = start + 1
        following = text[position:position + 1]
        if following == '?':
            return conditional_end(text, position + 1), None
        if following == '{':
            return self.expression_token(text, start)
        if following == '<':
            return self.variable_token(text, start)
        return self.spell_token(text, start)

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
            points = abs(self.records.single_value(spell_id, effect) if letter in SINGLE_VALUE_LETTERS
                         else self.records.points(spell_id, effect, upper=letter == 'M'))
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
            return self.records.radius(spell_id, int(digit) - 1), None, 'flat', None
        if digit:
            raise Unreadable
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
            return self.tooltip.variable(token.group('variable')).value
        if token.group('name'):
            value, effect_index, spell_id = self.tooltip.math_variable(token.group('spell'), token.group('name'))
            if self.effect_index is None:
                self.effect_index = effect_index
            if self.spell_id is None:
                self.spell_id = spell_id
            return value
        raise Unreadable


def unreadable_entry(text: str, error: Unreadable | None) -> str:
    return f'{text} [{error.reason}]' if error is not None and error.reason else text


def percent_or_flat(text: str, end: int) -> str:
    return 'percent' if text[end:end + 1] == '%' else 'flat'


def escape_end(text: str, start: int) -> int:
    if text[start + 1:start + 2] == 'T':
        close = text.find('|t', start + 2)
        return close + 2 if close >= 0 else len(text)
    return min(start + 2, len(text))


def conditional_end(text: str, start: int) -> int:
    true_start = text.find('[', start)
    true_end = text.find(']', true_start) if true_start >= 0 else -1
    if true_end < 0:
        return len(text)
    if text[true_end + 1:true_end + 2] == '?':
        return conditional_end(text, true_end + 2)
    false_start = text.find('[', true_end)
    false_end = text.find(']', false_start) if false_start >= 0 else -1
    return false_end + 1 if false_end >= 0 else len(text)


def read_tooltip(dbc: DataSet, spell_id: int, caster: CasterStats) -> Readout:
    records = Records(dbc)
    if not records.has_spell(spell_id):
        raise ValueError(f'Spell {spell_id} is not in Spell.dbc')
    description = records.field('Spell', spell_id, 'Description[enUS]')
    return Tooltip(records, spell_id, caster).read(description)
