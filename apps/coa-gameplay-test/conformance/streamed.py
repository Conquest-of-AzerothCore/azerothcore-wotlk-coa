from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import re

TABLE = 'coa_client_spell_description'
SQL_UPDATES = Path(__file__).resolve().parents[3] / 'data' / 'sql' / 'updates'
SQL_DIRECTORIES = ('db_world', 'pending_db_world')
TEXT_FIELDS = {'Description[enUS]': 'description', 'ToolTip[enUS]': 'tooltip'}
ESCAPES = {'r': '\r', 'n': '\n', 't': '\t', '0': '\0', 'Z': '\x1a', 'b': '\b'}
DELETE = re.compile(rf'(?is)^DELETE\s+FROM\s+`?{TABLE}`?\s+WHERE\s+(.*)$')
INSERT = re.compile(rf'(?is)^INSERT\s+INTO\s+`?{TABLE}`?\s*\(([^)]*)\)\s*VALUES\s*(.*)$')
CONCAT = re.compile(r'(?i)CONCAT\s*\(')


@dataclass(frozen=True)
class StreamedText:
    spell: int
    description: str
    tooltip: str | None
    file: str


def statements(text: str) -> list[str]:
    found, current, quote, index = [], [], None, 0
    while index < len(text):
        character = text[index]
        if quote:
            current.append(character)
            if character == '\\' and index + 1 < len(text):
                current.append(text[index + 1])
                index += 2
                continue
            if character == quote:
                if text[index + 1:index + 2] == quote:
                    current.append(quote)
                    index += 2
                    continue
                quote = None
            index += 1
            continue
        if character in '\'"`':
            quote = character
            current.append(character)
        elif text.startswith('--', index) and text[index + 2:index + 3] in ('', ' ', '\t', '\n', '\r'):
            index = len(text) if text.find('\n', index) < 0 else text.find('\n', index)
            continue
        elif character == '#':
            index = len(text) if text.find('\n', index) < 0 else text.find('\n', index)
            continue
        elif character == ';':
            found.append(''.join(current).strip())
            current = []
        else:
            current.append(character)
        index += 1
    if ''.join(current).strip():
        found.append(''.join(current).strip())
    return found


def quoted(text: str, index: int) -> tuple[str, int]:
    value = []
    index += 1
    while True:
        character = text[index]
        if character == '\\':
            value.append(ESCAPES.get(text[index + 1], text[index + 1]))
            index += 2
        elif character == "'" and text[index + 1:index + 2] == "'":
            value.append("'")
            index += 2
        elif character == "'":
            return ''.join(value), index + 1
        else:
            value.append(character)
            index += 1


def skip_space(text: str, index: int) -> int:
    while text[index] in ' \t\r\n':
        index += 1
    return index


def value_at(text: str, index: int) -> tuple[str | None, int]:
    if text[index] == "'":
        return quoted(text, index)
    concat = CONCAT.match(text, index)
    if concat:
        parts, index = [], concat.end()
        while True:
            index = skip_space(text, index)
            part, index = quoted(text, index)
            parts.append(part)
            index = skip_space(text, index)
            index += 1
            if text[index - 1] == ')':
                return ''.join(parts), index
    raw = re.match(r'[^,)]+', text[index:]).group(0)
    word = raw.strip()
    return (None if word.upper() == 'NULL' else word), index + len(raw)


def rows(values: str) -> list[list[str | None]]:
    found, index = [], 0
    while index < len(values):
        if values[index] != '(':
            index += 1
            continue
        index += 1
        row = []
        while True:
            index = skip_space(values, index)
            value, index = value_at(values, index)
            row.append(value)
            index = skip_space(values, index)
            index += 1
            if values[index - 1] == ')':
                break
        found.append(row)
    return found


def apply_statement(texts: dict[int, StreamedText], statement: str, name: str):
    deleted = DELETE.match(statement)
    if deleted:
        for spell in re.findall(r'\d+', deleted.group(1)):
            texts.pop(int(spell), None)
        return
    inserted = INSERT.match(statement)
    if not inserted:
        return
    columns = [column.strip(' `\r\n\t') for column in inserted.group(1).split(',')]
    for row in rows(inserted.group(2)):
        fields = dict(zip(columns, row))
        spell = int(fields['ID'])
        texts[spell] = StreamedText(spell, fields.get('Description') or '', fields.get('ToolTip'), name)


@lru_cache(maxsize=None)
def streamed_texts(updates: Path = SQL_UPDATES) -> dict[int, StreamedText]:
    texts = {}
    for directory in SQL_DIRECTORIES:
        for path in sorted((Path(updates) / directory).glob('*.sql')):
            text = path.read_text(encoding='utf-8')
            if TABLE not in text:
                continue
            for statement in statements(text):
                if TABLE in statement:
                    apply_statement(texts, statement, path.name)
    return texts


def streamed_field(spell: int, name: str, updates: Path = SQL_UPDATES) -> str | None:
    text = streamed_texts(updates).get(spell)
    if text is None or name not in TEXT_FIELDS:
        return None
    if TEXT_FIELDS[name] == 'description':
        return text.description
    return text.tooltip or None


FIGURE = re.compile(r'\$\{[^}]*\}|\$[\w/;]+|\d+(?:\.\d+)?|\|c[0-9a-fA-F]{8}(.*?)\|r')


def figures(text: str) -> list[str]:
    return [match.group(0) if match.group(1) is None else match.group(1) for match in FIGURE.finditer(text)]


def same_figures(first: str, second: str) -> bool:
    return figures(first) == figures(second)
