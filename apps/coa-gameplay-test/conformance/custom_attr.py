from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import re
import zipfile

from bonus_data import (ROOT, UnreadableTable, pending_updates, shown_directories, update_directories,
                        world_of)
from streamed import rows, statements

TABLE = 'spell_custom_attr'
COLUMNS = ('spell_id', 'attributes')
MENTION = re.compile(rf'(?i)(?<!\w){TABLE}(?!\w)')
INSERT = re.compile(rf'(?is)^INSERT\s+(IGNORE\s+)?INTO\s+`?{TABLE}`?\s*(?:\(([^)]*)\))?\s*VALUES\s*(.*)$')
DELETE = re.compile(rf'(?is)^DELETE\s+FROM\s+`?{TABLE}`?(?:\s+WHERE\s+(.*))?$')
UPDATE = re.compile(rf'(?is)^UPDATE\s+`?{TABLE}`?\s+SET\s+`?attributes`?\s*=\s*(.*?)\s+WHERE\s+(.*)$')
KEYED = re.compile(r'(?is)^\(?\s*`?spell_id`?\s*(?:=\s*(\d+)|IN\s*\(\s*(\d+(?:\s*,\s*\d+)*)\s*\))\s*\)?$')
NUMBER = r'(0x[0-9A-Fa-f]+|\d+)'
OR_VALUE = re.compile(rf'(?is)^`?attributes`?\s*\|\s*\(?\s*{NUMBER}\s*\)?$')
AND_NOT_VALUE = re.compile(rf'(?is)^`?attributes`?\s*&\s*~\s*\(?\s*{NUMBER}\s*\)?$')
PLAIN_VALUE = re.compile(rf'(?is)^{NUMBER}$')
RESET = re.compile(rf'(?is)^(?:DROP\s+TABLE(?:\s+IF\s+EXISTS)?|CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?)\s+`?{TABLE}`?')
DUMP_ONLY = re.compile(rf'(?is)^(?:LOCK\s+TABLES\s+`?{TABLE}`?\s+WRITE|/\*!\d+\s+ALTER\s+TABLE\s+`?{TABLE}`?\s+'
                       r'(?:DISABLE|ENABLE)\s+KEYS\s*\*/)$')


@dataclass(frozen=True)
class CustomAttributes:
    rows: dict[int, int]
    sources: dict[int, str]
    unreadable: str = ''
    directories: tuple[str, ...] = ()

    def of(self, spell_id: int) -> int:
        return self.rows.get(spell_id, 0)


def integer(text: str | None) -> int:
    if text is None:
        raise UnreadableTable(f'a NULL {TABLE} value')
    text = text.strip("'")
    try:
        return int(text, 16) if text.lower().startswith('0x') else int(text)
    except ValueError:
        raise UnreadableTable(f'{TABLE} value {text!r} is not an integer') from None


def keyed_spells(condition: str, source: str) -> list[int]:
    keyed = KEYED.match(condition.strip())
    if not keyed:
        raise UnreadableTable(f'{source}: {TABLE} condition {condition.strip()[:80]!r} is not keyed by spell_id')
    return [int(entry) for entry in re.findall(r'\d+', keyed.group(1) or keyed.group(2))]


def updated(value: str, current: int, source: str) -> int:
    for pattern, change in ((OR_VALUE, lambda bits: current | bits), (AND_NOT_VALUE, lambda bits: current & ~bits),
                            (PLAIN_VALUE, lambda bits: bits)):
        matched = pattern.match(value.strip())
        if matched:
            return change(integer(matched.group(1)))
    raise UnreadableTable(f'{source}: {TABLE} assignment {value.strip()[:80]!r} is not modelled')


def apply(table: dict[int, int], sources: dict[int, str], statement: str, source: str, columns: tuple[str, ...]):
    if DUMP_ONLY.match(statement):
        return
    if RESET.match(statement):
        table.clear()
        sources.clear()
        return
    deleted = DELETE.match(statement)
    if deleted:
        if deleted.group(1) is None:
            table.clear()
            sources.clear()
            return
        for spell in keyed_spells(deleted.group(1), source):
            table.pop(spell, None)
            sources.pop(spell, None)
        return
    changed = UPDATE.match(statement)
    if changed:
        for spell in keyed_spells(changed.group(2), source):
            if spell in table:
                table[spell] = updated(changed.group(1), table[spell], source)
                sources[spell] = source
        return
    inserted = INSERT.match(statement)
    if not inserted or re.search(r'(?i)\bON\s+DUPLICATE\s+KEY\b', inserted.group(3)):
        raise UnreadableTable(f'{source}: statement {statement[:80]!r} changes {TABLE} outside DELETE, INSERT and '
                              f'UPDATE')
    names = (tuple(column.strip(' `\r\n\t') for column in inserted.group(2).split(','))
             if inserted.group(2) else columns)
    for values in rows(inserted.group(3)):
        if len(values) != len(names):
            raise UnreadableTable(f'{source}: a row of {len(values)} values for {len(names)} columns')
        fields = dict(zip(names, values))
        spell = integer(fields['spell_id'])
        if inserted.group(1) and spell in table:
            continue
        table[spell] = integer(fields.get('attributes', '0'))
        sources[spell] = source


def apply_text(table: dict[int, int], sources: dict[int, str], text: str, source: str, columns: tuple[str, ...]):
    for statement in statements(text):
        if MENTION.search(statement):
            apply(table, sources, statement, source, columns)


def read_custom_attributes(root: Path) -> CustomAttributes:
    world = world_of(root, TABLE, COLUMNS)
    directories = update_directories(root, world)
    table: dict[int, int] = {}
    sources: dict[int, str] = {}
    apply_text(table, sources, world.base_text, world.base_source, world.columns)
    for source, text in pending_updates(root, world, directories, TABLE, MENTION):
        apply_text(table, sources, text, source, world.columns)
    return CustomAttributes(table, sources, '', shown_directories(root, directories))


@lru_cache(maxsize=None)
def custom_attributes(root: Path = ROOT) -> CustomAttributes:
    try:
        return read_custom_attributes(Path(root))
    except (UnreadableTable, OSError, KeyError, ValueError, zipfile.BadZipFile) as error:
        return CustomAttributes({}, {}, str(error) or type(error).__name__)
