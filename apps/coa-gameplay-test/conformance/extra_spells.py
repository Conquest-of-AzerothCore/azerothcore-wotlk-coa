from collections import Counter
from pathlib import Path
import re

from classes import (CHARACTER_LEVEL, PROGRESSION_HEADER, class_spells, dataset, progression_chains,
                     rows_by_identity)
from streamed import SQL_DIRECTORIES, rows as sql_rows, statements as sql_statements, streamed_field
from tooltip import DESCRIPTION, PASSIVE_ATTRIBUTE, SPELL_MARKUP, Records, expansion_refusal

REPOSITORY = Path(__file__).resolve().parents[3]
CUSTOM_CLASS_HEADER = Path('src/server/coa/AscensionCustomClassData.h')
LIVE_BASELINE_HEADER = Path('src/server/coa/AscensionLiveBaselineData.h')
TAUGHT_ABILITY_HEADER = Path('src/server/coa/AscensionTaughtAbilityData.h')
COMPAT_SOURCE = Path('src/server/coa/AscensionCompat.cpp')
BASE_TRAINER_SQL = Path('data/sql/base/db_world/trainer_spell.sql')
UPDATES_ROOT = Path('data/sql')

TRAINER_CLASS_MIN = 900012
TRAINER_CLASS_MAX = 900032
TRAINER_CLASS_OFFSET = 900000
TRAINER_SPELL_COLUMNS = ('TrainerId', 'SpellId', 'MoneyCost', 'ReqSkillLine', 'ReqSkillRank',
                         'ReqAbility1', 'ReqAbility2', 'ReqAbility3', 'ReqLevel', 'VerifiedBuild')
TRAINER_COLUMNS_LOWER = frozenset(col.lower() for col in TRAINER_SPELL_COLUMNS)
WHERE_COLUMNS = frozenset({'trainerid', 'spellid', 'reqlevel'})
CAST_EVENTS = frozenset({'SPELL_CAST_SUCCESS', 'SPELL_CAST_START'})
WHITESPACE = re.compile(r'\s+')
CPP_LINE_COMMENT = re.compile(r'//[^\n]*')
CPP_BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
CPP_INT = r'(?:0[xX][0-9a-fA-F]+|\d+)(?:[uU](?:ll?|LL?)?|(?:ll?|LL?)[uU]?)?'
ROW_BRACE = re.compile(r'\{[^{}]*\}')
LINE_THREE_INTS = re.compile(rf'\{{\s*({CPP_INT})\s*,\s*({CPP_INT})\s*,\s*({CPP_INT})\s*\}}')
LINE_FIVE_INTS = re.compile(
    rf'\{{\s*({CPP_INT})\s*,\s*({CPP_INT})\s*,\s*({CPP_INT})\s*,\s*({CPP_INT})\s*,\s*({CPP_INT})\s*\}}')
LINE_TWO_INTS = re.compile(rf'\{{\s*({CPP_INT})\s*,\s*({CPP_INT})\s*\}}')
WHERE_TOKEN = re.compile(
    r'\s*(?:(\()|(\))|(,)|(=)|(-?\d+)|`([A-Za-z_][A-Za-z0-9_]*)`|([A-Za-z_][A-Za-z0-9_]*))')
TRAINER_DELETE = re.compile(r'(?is)^DELETE\s+FROM\s+`?trainer_spell`?(?:\s+WHERE\s+(.*))?$')
TRAINER_WRITE = re.compile(
    r'(?is)^(?:INSERT\s+(?:IGNORE\s+)?INTO|REPLACE\s+INTO|UPDATE|DELETE\s+FROM|TRUNCATE(?:\s+TABLE)?)'
    r'\s+`?trainer_spell`?\b')
TRAINER_INSERT = re.compile(r'(?is)^(INSERT\s+(?:IGNORE\s+)?INTO|REPLACE\s+INTO)\s+`?trainer_spell`?'
                            r'\s*(?:\(([^)]*)\)\s*)?VALUES\b(.*)$')
TRAINER_INSERT_SELECT = re.compile(
    r'(?is)^(INSERT\s+(?:IGNORE\s+)?INTO|REPLACE\s+INTO)\s+`?trainer_spell`?'
    r'\s*(?:\(([^)]*)\)\s*)?SELECT\s+(?:DISTINCT\s+)?(.*?)\s+FROM\s+`?trainer_spell`?'
    r'(?:\s+WHERE\s+(.*?))?(?:\s+LIMIT\s+(\d+))?\s*$')
TRAINER_UPDATE = re.compile(r'(?is)^UPDATE\s+`?trainer_spell`?\s+SET\s+(.*?)(?:\s+WHERE\s+(.*))?$')
TRAINER_ASSIGNMENT = re.compile(r'^\s*`?([A-Za-z_][A-Za-z0-9_]*)`?\s*=\s*(-?\d+)\s*$')
SPELL_FIELDS = ['SpellName[enUS]', 'Rank[enUS]', 'Description[enUS]', 'Attributes']
TOOLTIP_PREVIEW_CHARS = 180

STOCK_GENERIC_SPELLS = frozenset({
    75, 81, 107, 196, 197, 198, 199, 200, 201, 202, 227, 264, 266, 674, 750, 1180, 2567, 2764,
    3018, 3124, 3127, 5009, 5011, 5019, 6603, 8613, 8737, 9077, 9078, 9116, 15590, 28875,
    33379, 33388, 33391, 34090, 34091, 54197,
})


class ExtraSpellsError(ValueError):
    pass


def log_events(path: Path | None, required: bool = False) -> tuple[Counter, Counter]:
    casts, others = Counter(), Counter()
    if path is None:
        return casts, others
    target = Path(path)
    if not target.exists() or target.is_dir():
        if required:
            raise ExtraSpellsError(f'log events CSV not found: {target}')
        return casts, others
    for line in target.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        event, spell, count = line.rsplit(',', 2)
        (casts if event in CAST_EVENTS else others)[int(spell)] += int(count)
    return casts, others


def parse_cpp_int(text: str) -> int:
    digits = text.rstrip('uUlL')
    return int(digits, 16) if digits.lower().startswith('0x') else int(digits, 10)


def array_block(path: Path, name: str, required: bool = False) -> str:
    if not path.is_file():
        if required:
            raise ExtraSpellsError(f'required grant source file not found: {path}')
        return ''
    text = path.read_text(encoding='utf-8', errors='replace')
    match = re.search(rf'\b{re.escape(name)}\s*=\s*(.*?)\}};', text, re.S)
    if not match:
        if required:
            raise ExtraSpellsError(f'required array {name} not found in {path}')
        return ''
    return match.group(1)


def parse_cpp_rows(block: str, pattern: re.Pattern, name: str, path: Path) -> list[tuple[int, ...]]:
    cleaned = CPP_LINE_COMMENT.sub('', CPP_BLOCK_COMMENT.sub('', block))
    parsed: list[tuple[int, ...]] = []
    for raw_row in ROW_BRACE.findall(cleaned):
        if not raw_row[1:-1].strip():
            continue
        match = pattern.fullmatch(raw_row)
        if not match:
            raise ExtraSpellsError(f'malformed initializer row in {name} ({path}): {raw_row!r}')
        parsed.append(tuple(parse_cpp_int(group) for group in match.groups()))
    return parsed


def class_spells_table(root: Path = REPOSITORY, required: bool = False) -> dict[int, dict[int, int]]:
    path = Path(root) / CUSTOM_CLASS_HEADER
    block = array_block(path, 'ClassSpells', required=required)
    found: dict[int, dict[int, int]] = {}
    for class_id, level, spell_id in parse_cpp_rows(block, LINE_THREE_INTS, 'ClassSpells', path):
        per_class = found.setdefault(class_id, {})
        per_class[spell_id] = min(per_class.get(spell_id, level), level)
    return found


def live_baseline_spells(root: Path = REPOSITORY, required: bool = False) -> dict[int, set[int]]:
    path = Path(root) / LIVE_BASELINE_HEADER
    block = array_block(path, 'Spells', required=required)
    found: dict[int, set[int]] = {}
    for class_id, race_id, spell_id in parse_cpp_rows(block, LINE_THREE_INTS, 'Spells', path):
        if race_id == 0:
            found.setdefault(class_id, set()).add(spell_id)
    return found


def taught_abilities(root: Path = REPOSITORY, required: bool = False) -> dict[int, dict[int, tuple[int, int]]]:
    path = Path(root) / TAUGHT_ABILITY_HEADER
    block = array_block(path, 'TaughtAbilities', required=required)
    found: dict[int, dict[int, tuple[int, int]]] = {}
    for class_id, _, level, parent_id, spell_id in parse_cpp_rows(block, LINE_FIVE_INTS, 'TaughtAbilities', path):
        per_class = found.setdefault(class_id, {})
        if spell_id not in per_class or level < per_class[spell_id][0]:
            per_class[spell_id] = (level, parent_id)
    return found


def felsworn_rifts(root: Path = REPOSITORY, required: bool = False) -> dict[int, int]:
    path = Path(root) / COMPAT_SOURCE
    block = array_block(path, 'FelswornHordeCapitalRifts', required=required)
    found: dict[int, int] = {}
    for spell_id, level in parse_cpp_rows(block, LINE_TWO_INTS, 'FelswornHordeCapitalRifts', path):
        found[spell_id] = min(found.get(spell_id, level), level)
    return found


def tokenize_where(where_clause: str) -> list[tuple[str, str | int]]:
    tokens: list[tuple[str, str | int]] = []
    pos = 0
    length = len(where_clause)
    while pos < length:
        if where_clause[pos].isspace():
            pos += 1
            continue
        match = WHERE_TOKEN.match(where_clause, pos)
        if not match or match.end() == pos:
            raise ExtraSpellsError(f'unsupported trainer_spell WHERE clause near: {where_clause[pos:pos + 40]!r}')
        lparen, rparen, comma, eq, number, quoted_ident, bare_ident = match.groups()
        if lparen:
            tokens.append(('LPAREN', '('))
        elif rparen:
            tokens.append(('RPAREN', ')'))
        elif comma:
            tokens.append(('COMMA', ','))
        elif eq:
            tokens.append(('EQ', '='))
        elif number is not None:
            tokens.append(('INT', int(number)))
        elif quoted_ident is not None:
            tokens.append(('IDENT', quoted_ident.lower()))
        else:
            upper = bare_ident.upper()
            if upper in ('AND', 'OR', 'IN'):
                tokens.append((upper, upper))
            else:
                tokens.append(('IDENT', bare_ident.lower()))
        pos = match.end()
    return tokens


class WhereParser:
    def __init__(self, tokens: list[tuple[str, str | int]], raw: str):
        self.tokens = tokens
        self.raw = raw
        self.index = 0

    def peek(self) -> tuple[str, str | int] | None:
        return self.tokens[self.index] if self.index < len(self.tokens) else None

    def expect(self, kind: str) -> str | int:
        token = self.peek()
        if token is None or token[0] != kind:
            raise ExtraSpellsError(f'expected {kind} in trainer_spell WHERE clause: {self.raw!r}')
        self.index += 1
        return token[1]

    def parse(self):
        node = self.parse_or()
        if self.peek() is not None:
            raise ExtraSpellsError(f'unexpected trailing tokens in trainer_spell WHERE clause: {self.raw!r}')
        return node

    def parse_or(self):
        left = self.parse_and()
        while self.peek() and self.peek()[0] == 'OR':
            self.index += 1
            right = self.parse_and()
            left = ('OR', left, right)
        return left

    def parse_and(self):
        left = self.parse_atom()
        while self.peek() and self.peek()[0] == 'AND':
            self.index += 1
            right = self.parse_atom()
            left = ('AND', left, right)
        return left

    def parse_atom(self):
        token = self.peek()
        if token is None:
            raise ExtraSpellsError(f'unexpected end of trainer_spell WHERE clause: {self.raw!r}')
        if token[0] == 'LPAREN':
            self.index += 1
            inner = self.parse_or()
            self.expect('RPAREN')
            return inner
        column = self.expect('IDENT')
        if column not in WHERE_COLUMNS:
            raise ExtraSpellsError(f'unsupported column {column!r} in trainer_spell WHERE clause: {self.raw!r}')
        op = self.peek()
        if op is None:
            raise ExtraSpellsError(f'missing operator after {column!r} in trainer_spell WHERE clause: {self.raw!r}')
        if op[0] == 'EQ':
            self.index += 1
            value = self.expect('INT')
            return ('PRED', column, frozenset({value}))
        if op[0] == 'IN':
            self.index += 1
            self.expect('LPAREN')
            values = [self.expect('INT')]
            while self.peek() and self.peek()[0] == 'COMMA':
                self.index += 1
                values.append(self.expect('INT'))
            self.expect('RPAREN')
            return ('PRED', column, frozenset(values))
        raise ExtraSpellsError(f'unsupported operator {op[1]!r} in trainer_spell WHERE clause: {self.raw!r}')


def eval_where(node, row: dict[str, int]) -> bool:
    kind = node[0]
    if kind == 'PRED':
        return row[node[1]] in node[2]
    if kind == 'AND':
        return eval_where(node[1], row) and eval_where(node[2], row)
    return eval_where(node[1], row) or eval_where(node[2], row)


def matching_trainer_keys(active: dict[tuple[int, int], int], where_clause: str | None) -> list[tuple[int, int]]:
    if where_clause is None:
        return list(active)
    tokens = tokenize_where(where_clause)
    if not tokens:
        raise ExtraSpellsError('empty trainer_spell WHERE clause')
    ast = WhereParser(tokens, where_clause).parse()
    matched: list[tuple[int, int]] = []
    for key, req_level in active.items():
        trainer_id, spell_id = key
        row = {'trainerid': trainer_id, 'spellid': spell_id, 'reqlevel': req_level}
        if eval_where(ast, row):
            matched.append(key)
    return matched


def apply_trainer_delete(active: dict[tuple[int, int], int], where_clause: str | None) -> None:
    if where_clause is None:
        active.clear()
        return
    for key in matching_trainer_keys(active, where_clause):
        del active[key]


def apply_trainer_insert(active: dict[tuple[int, int], int], columns_text: str | None, values_text: str,
                         ignore: bool = False) -> None:
    columns = [col.strip(' `\r\n\t') for col in columns_text.split(',')] if columns_text else list(TRAINER_SPELL_COLUMNS)
    for row in sql_rows(values_text):
        if len(row) != len(columns):
            continue
        fields = dict(zip(columns, row))
        try:
            trainer_id = int(fields['TrainerId'])
            spell_id = int(fields['SpellId'])
            req_level = int(fields.get('ReqLevel') or 0)
        except (KeyError, TypeError, ValueError):
            continue
        key = (trainer_id, spell_id)
        if not ignore or key not in active:
            active[key] = req_level


def resolve_select_int(expr: str, source_row: dict[str, int]) -> int:
    token = expr.strip(' `\r\n\t')
    lowered = token.lower()
    if lowered in source_row:
        return source_row[lowered]
    try:
        return int(token)
    except ValueError as error:
        raise ExtraSpellsError(f'unsupported trainer_spell SELECT expression: {expr!r}') from error


def apply_trainer_insert_select(active: dict[tuple[int, int], int], columns_text: str | None,
                                select_text: str, where_clause: str | None, limit_text: str | None,
                                ignore: bool = False) -> None:
    columns = [col.strip(' `\r\n\t') for col in columns_text.split(',')] if columns_text else list(TRAINER_SPELL_COLUMNS)
    expressions = [part.strip() for part in select_text.split(',')]
    if len(expressions) != len(columns):
        raise ExtraSpellsError(
            f'trainer_spell SELECT column count ({len(expressions)}) does not match target ({len(columns)})')
    fields = dict(zip(columns, expressions))
    if 'TrainerId' not in fields or 'SpellId' not in fields:
        raise ExtraSpellsError(f'trainer_spell SELECT missing TrainerId or SpellId in {columns!r}')
    probe = {'trainerid': 0, 'spellid': 0, 'reqlevel': 0}
    resolve_select_int(fields['TrainerId'], probe)
    resolve_select_int(fields['SpellId'], probe)
    if 'ReqLevel' in fields:
        resolve_select_int(fields['ReqLevel'], probe)
    matched = matching_trainer_keys(active, where_clause)
    if limit_text is not None:
        matched = matched[:int(limit_text)]
    additions: list[tuple[int, int, int]] = []
    for src_trainer_id, src_spell_id in matched:
        source_row = {
            'trainerid': src_trainer_id,
            'spellid': src_spell_id,
            'reqlevel': active[(src_trainer_id, src_spell_id)],
        }
        trainer_id = resolve_select_int(fields['TrainerId'], source_row)
        spell_id = resolve_select_int(fields['SpellId'], source_row)
        req_level = resolve_select_int(fields['ReqLevel'], source_row) if 'ReqLevel' in fields else 0
        additions.append((trainer_id, spell_id, req_level))
    for trainer_id, spell_id, req_level in additions:
        key = (trainer_id, spell_id)
        if not ignore or key not in active:
            active[key] = req_level


def apply_trainer_update(active: dict[tuple[int, int], int], set_text: str, where_clause: str | None) -> None:
    parts = [part for part in set_text.split(',')]
    if not parts or all(not part.strip() for part in parts):
        raise ExtraSpellsError(f'empty trainer_spell UPDATE SET clause: {set_text!r}')
    assignments: dict[str, int] = {}
    for part in parts:
        match = TRAINER_ASSIGNMENT.fullmatch(part)
        if not match:
            raise ExtraSpellsError(f'unsupported trainer_spell UPDATE assignment: {part!r}')
        column = match.group(1).lower()
        if column not in TRAINER_COLUMNS_LOWER:
            raise ExtraSpellsError(f'unknown trainer_spell UPDATE column: {match.group(1)!r}')
        if column in ('trainerid', 'spellid'):
            raise ExtraSpellsError(f'unsupported trainer_spell key mutation in UPDATE: {part!r}')
        assignments[column] = int(match.group(2))
    matched = matching_trainer_keys(active, where_clause)
    if 'reqlevel' in assignments:
        req_level = assignments['reqlevel']
        for key in matched:
            active[key] = req_level


def trainer_spells(root: Path = REPOSITORY, required: bool = False) -> dict[int, dict[int, int]]:
    root = Path(root)
    base_path = root / BASE_TRAINER_SQL
    if required and not base_path.is_file():
        raise ExtraSpellsError(f'required trainer SQL file not found: {base_path}')
    files = [base_path]
    for directory in SQL_DIRECTORIES:
        folder = root / UPDATES_ROOT / 'updates' / directory
        if folder.is_dir():
            files += sorted(folder.glob('*.sql'), key=lambda path: path.name)
    active: dict[tuple[int, int], int] = {}
    for path in files:
        if not path.is_file():
            continue
        text = path.read_text(encoding='utf-8', errors='replace')
        if 'trainer_spell' not in text.lower():
            continue
        for statement in sql_statements(text):
            if 'trainer_spell' not in statement.lower():
                continue
            deleted = TRAINER_DELETE.match(statement)
            if deleted:
                apply_trainer_delete(active, deleted.group(1))
                continue
            inserted = TRAINER_INSERT.match(statement)
            if inserted:
                ignore = 'ignore' in inserted.group(1).lower()
                apply_trainer_insert(active, inserted.group(2), inserted.group(3), ignore=ignore)
                continue
            inserted_select = TRAINER_INSERT_SELECT.match(statement)
            if inserted_select:
                ignore = 'ignore' in inserted_select.group(1).lower()
                apply_trainer_insert_select(
                    active, inserted_select.group(2), inserted_select.group(3),
                    inserted_select.group(4), inserted_select.group(5), ignore=ignore)
                continue
            updated = TRAINER_UPDATE.match(statement)
            if updated:
                apply_trainer_update(active, updated.group(1), updated.group(2))
                continue
            if TRAINER_WRITE.match(statement):
                raise ExtraSpellsError(f'unsupported trainer_spell statement in {path}: {statement[:120]}')
    by_class: dict[int, dict[int, int]] = {}
    for (trainer_id, spell_id), req_level in active.items():
        if not (TRAINER_CLASS_MIN <= trainer_id <= TRAINER_CLASS_MAX):
            continue
        class_id = trainer_id - TRAINER_CLASS_OFFSET
        per_class = by_class.setdefault(class_id, {})
        per_class[spell_id] = min(per_class.get(spell_id, req_level), req_level)
    return by_class


def server_candidates(root: Path, class_id: int, level: int = CHARACTER_LEVEL,
                      required: bool = False) -> dict[int, list[str]]:
    sources: dict[int, set[str]] = {}
    for spell_id, req_level in class_spells_table(root, required=required).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'ClassSpells(L{req_level})')
    for spell_id in live_baseline_spells(root, required=required).get(class_id, ()):
        sources.setdefault(spell_id, set()).add('LiveBaseline')
    for spell_id, (req_level, parent_id) in taught_abilities(root, required=required).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'TaughtAbilities(L{req_level}, parent={parent_id})')
    if class_id == 14:
        for spell_id, req_level in felsworn_rifts(root, required=required).items():
            if req_level <= level:
                sources.setdefault(spell_id, set()).add(f'FelswornRifts(L{req_level})')
    for spell_id, req_level in trainer_spells(root, required=required).get(class_id, {}).items():
        if req_level <= level:
            sources.setdefault(spell_id, set()).add(f'trainer_spell(L{req_level})')
    return {spell_id: sorted(tags) for spell_id, tags in sorted(sources.items())}


def validate_excluded_extra_spells(entries, advancement_ids: set[int], extra_ids: set[int]) -> dict[int, dict]:
    if not isinstance(entries, list):
        raise ExtraSpellsError('excluded_extra_spells must be a list')
    by_id: dict[int, dict] = {}
    for item in entries:
        if not isinstance(item, dict):
            raise ExtraSpellsError('each excluded_extra_spells entry must be an object')
        spell = item.get('spell')
        name = item.get('name')
        reason = item.get('reason')
        if isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0:
            raise ExtraSpellsError(f'excluded_extra_spells entry has invalid spell id {spell!r}')
        if not isinstance(name, str) or not name.strip():
            raise ExtraSpellsError(f'excluded_extra_spells {spell} needs a non-empty name')
        if not isinstance(reason, str) or not reason.strip():
            raise ExtraSpellsError(f'excluded_extra_spells {spell} needs a non-empty reason')
        if spell in by_id:
            raise ExtraSpellsError(f'excluded_extra_spells lists {spell} more than once')
        if spell in advancement_ids:
            raise ExtraSpellsError(f'excluded_extra_spells {spell} is already a CharacterAdvancement class spell')
        if spell in extra_ids:
            raise ExtraSpellsError(f'excluded_extra_spells {spell} is already in extra_spells')
        by_id[spell] = item
    return by_id


def spell_description(records: Records, spell_id: int, updates: Path) -> str:
    if updates.is_dir():
        streamed = streamed_field(spell_id, DESCRIPTION, updates)
        if streamed is not None:
            return streamed
    return (records.dbc_field('Spell', spell_id, DESCRIPTION) or '') if records.has_spell(spell_id) else ''


def walk_pulled_spells(records: Records, spell_id: int, expanding: tuple[int, ...], updates: Path, found: set[int]) -> None:
    description = spell_description(records, spell_id, updates)
    chain = expanding + (spell_id,)
    for markup in SPELL_MARKUP.finditer(description):
        if expansion_refusal(records, markup, chain) is not None:
            continue
        pulled = int(markup.group('spell'))
        found.add(pulled)
        walk_pulled_spells(records, pulled, chain, updates, found)


def pulled_spells(records: Records, covered_list: list, updates: Path) -> set[int]:
    found: set[int] = set()
    for spell in covered_list:
        walk_pulled_spells(records, spell.max_rank, (), updates, found)
    return found


def resolve_progression_header(source_root: Path, progression_header: Path | None) -> Path:
    if progression_header is not None:
        return Path(progression_header)
    candidate = Path(source_root) / 'src/server/coa/AscensionSpellProgressionData.h'
    return candidate if candidate.is_file() else PROGRESSION_HEADER


def compact_tooltip(text: str) -> str:
    cleaned = WHITESPACE.sub(' ', text or '').strip()
    if len(cleaned) <= TOOLTIP_PREVIEW_CHARS:
        return cleaned
    return cleaned[:TOOLTIP_PREVIEW_CHARS - 3].rstrip() + '...'


def audit_extra_spells(class_file: dict, dbc_dir: Path, source_root: Path = REPOSITORY,
                       progression_header: Path | None = None, log_events_path: Path | None = None) -> dict:
    class_id = int(class_file['class_id'])
    level = int(class_file.get('level', CHARACTER_LEVEL))
    source_root = Path(source_root)
    dbc_dir = Path(dbc_dir)
    header = resolve_progression_header(source_root, progression_header)
    dbc = dataset(dbc_dir)
    records = Records(dbc)
    ca_list = class_spells(dbc_dir, class_id, header, level)
    advancement_ids = {spell.spell_id for spell in ca_list}
    extra_ids = [entry['spell'] for entry in class_file.get('extra_spells', [])]
    excluded_by_id = validate_excluded_extra_spells(class_file.get('excluded_extra_spells', []),
                                                    advancement_ids, set(extra_ids))
    covered_list = class_spells(dbc_dir, class_id, header, level, extra_spells=extra_ids)
    covered_base = {spell.spell_id for spell in covered_list}
    covered_ranks = {rank for spell in covered_list for rank in spell.ranks}
    chains = progression_chains(dbc, header, class_id)
    rank_to_first = {first: first for first in chains} | {
        rank: first for first, chain in chains.items() for rank, _ in chain}
    updates = source_root / UPDATES_ROOT / 'updates'
    pulled_ids = pulled_spells(records, covered_list, updates)

    raw_candidates = server_candidates(source_root, class_id, level, required=True)
    collapsed: dict[int, set[str]] = {}
    for spell_id, srcs in raw_candidates.items():
        base = rank_to_first.get(spell_id, spell_id)
        collapsed.setdefault(base, set()).update(srcs)

    covered_name_sources = sorted({spell.max_rank for spell in covered_list} | pulled_ids)
    candidate_ranks: dict[int, tuple[int, ...]] = {}
    for base in collapsed:
        chain = chains.get(base, [])
        all_ranks = (base,) + tuple(rank for rank, _ in chain)
        candidate_ranks[base] = all_ranks
    needed_ids = set(covered_name_sources) | {rank for ranks in candidate_ranks.values() for rank in ranks}
    spell_rows = rows_by_identity(dbc, 'Spell', needed_ids, SPELL_FIELDS)

    covered_names: dict[str, list[int]] = {}
    for spell_id in covered_name_sources:
        row = spell_rows.get(spell_id)
        if row and row['SpellName[enUS]']:
            covered_names.setdefault(row['SpellName[enUS]'], []).append(spell_id)
    for name in covered_names:
        covered_names[name] = sorted(set(covered_names[name]))

    casts, others = log_events(log_events_path, required=True)
    covered_candidates = 0
    excluded, stock_generic, unchained_ranks, unaccounted, missing_dbc = [], [], [], [], []
    for base, srcs_set in sorted(collapsed.items()):
        if base in covered_base or base in covered_ranks or base in pulled_ids:
            covered_candidates += 1
            continue
        srcs = sorted(srcs_set)
        if base not in spell_rows:
            missing_dbc.append({'spell': base, 'sources': srcs})
            continue
        row = spell_rows[base]
        name = row['SpellName[enUS]'] or ''
        if base in excluded_by_id:
            excluded.append({'spell': base, 'name': name, 'reason': excluded_by_id[base]['reason'], 'sources': srcs})
            continue
        if base in STOCK_GENERIC_SPELLS:
            stock_generic.append({'spell': base, 'name': name, 'sources': srcs})
            continue
        all_ranks = candidate_ranks[base]
        log_cast_count = sum(casts[rank] for rank in all_ranks)
        log_other_count = sum(others[rank] for rank in all_ranks)
        rank_text = (row['Rank[enUS]'] or '').strip()
        if name and name in covered_names and rank_text:
            unchained_ranks.append({
                'spell': base, 'name': name, 'rank': rank_text,
                'covered_as': covered_names[name], 'sources': srcs,
                'log_casts': log_cast_count, 'log_other_events': log_other_count})
            continue
        reached = [base] + [rank for rank, required_level in chains.get(base, []) if required_level <= level]
        max_rank = reached[-1]
        max_row = spell_rows.get(max_rank, row)
        unaccounted.append({
            'spell': base, 'max_rank': max_rank, 'ranks': len(all_ranks), 'name': name,
            'passive': bool(row['Attributes'] & PASSIVE_ATTRIBUTE), 'sources': srcs,
            'tooltip': compact_tooltip(max_row['Description[enUS]'] or ''),
            'log_casts': log_cast_count, 'log_other_events': log_other_count})

    return {
        'class_id': class_id,
        'name': class_file.get('name', ''),
        'level': level,
        'counts': {
            'advancement': len(ca_list),
            'extra_spells': len(extra_ids),
            'covered_candidates': covered_candidates,
            'excluded': len(excluded),
            'stock_generic': len(stock_generic),
            'unchained_ranks': len(unchained_ranks),
            'unaccounted': len(unaccounted),
            'missing_dbc': len(missing_dbc),
        },
        'unaccounted': unaccounted,
        'unchained_ranks': unchained_ranks,
        'missing_dbc': missing_dbc,
        'excluded': excluded,
        'stock_generic': stock_generic,
    }


def audit_extra_lines(report: dict) -> list[str]:
    counts = report['counts']
    lines = [
        f"class {report['class_id']} ({report['name']}, L{report['level']}): "
        f"advancement={counts['advancement']} extra={counts['extra_spells']} "
        f"excluded={counts['excluded']} stock={counts['stock_generic']} "
        f"unchained={counts['unchained_ranks']} unaccounted={counts['unaccounted']} "
        f"missing_dbc={counts['missing_dbc']}"
    ]
    for entry in report['missing_dbc']:
        lines.append(f"MISSING_DBC\t{entry['spell']}\t{', '.join(entry['sources'])}")
    for entry in report['unaccounted']:
        lines.append(
            f"UNACCOUNTED\t{entry['spell']}\tmax={entry['max_rank']} ({entry['ranks']}r)\t"
            f"{'P' if entry['passive'] else 'A'}\t{entry['name']}\t"
            f"logs={entry['log_casts']}c/{entry['log_other_events']}e\t{', '.join(entry['sources'])}")
    for entry in report['unchained_ranks']:
        lines.append(
            f"UNCHAINED_RANK\t{entry['spell']}\t{entry['name']} ({entry['rank']})\t"
            f"covered_as={entry['covered_as']}\t"
            f"logs={entry['log_casts']}c/{entry['log_other_events']}e\t{', '.join(entry['sources'])}")
    return lines
