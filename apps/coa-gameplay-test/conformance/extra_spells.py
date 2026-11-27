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
CAST_EVENTS = frozenset({'SPELL_CAST_SUCCESS', 'SPELL_CAST_START'})
WHITESPACE = re.compile(r'\s+')
CPP_INT = re.compile(r"(?P<digits>(?:0[xX][0-9a-fA-F']+|0[bB][01']+|[0-9][0-9']*))"
                     r"(?:[uU](?:ll|LL|[lL])?|(?:ll|LL|[lL])[uU]?)?")
TRAINER_DELETE = re.compile(r'(?is)^DELETE\s+FROM\s+`?trainer_spell`?(?:\s+WHERE\s+(.*))?$')
WRITE_MODE = r'(INSERT\s+IGNORE|INSERT|REPLACE)\s+INTO\s+'
TRAINER_WRITE = re.compile(rf'(?is)^{WRITE_MODE}`?trainer_spell\b|^UPDATE\b.*?\btrainer_spell\b.*?\bSET\b')
TRAINER_INSERT = re.compile(rf'(?is)^{WRITE_MODE}`?trainer_spell`?'
                            r'\s*(?:\(([^)]*)\)\s*)?VALUES\b(.*)$')
TRAINER_INSERT_SELECT = re.compile(
    rf'(?is)^{WRITE_MODE}`?trainer_spell`?'
    r'\s*(?:\(([^)]*)\)\s*)?SELECT\s+(?:DISTINCT\s+)?(.*?)\s+FROM\s+`?trainer_spell`?'
    r'(?:\s+WHERE\s+(.*?))?(?:\s+LIMIT\s+(\d+))?\s*$')
UNTRACKED_UPDATE = re.compile(r'(?is)^UPDATE\s+`?trainer_spell`?\s+SET\s+(.*?)\s+WHERE\s+(.+)$')
UNTRACKED_ASSIGNMENT = re.compile(
    r'(?i)`?(?:MoneyCost|ReqSkillLine|ReqSkillRank|ReqAbility[123]|VerifiedBuild)`?\s*=\s*[+-]?\d+')
TRAINER_PREDICATE = re.compile(
    r'(?i)\s*(?:(`TrainerId`|`SpellId`|TrainerId|SpellId)\s*'
    r'(?:=\s*([+-]?\d+)|IN\s*\(\s*([+-]?\d+(?:\s*,\s*[+-]?\d+)*)\s*\))|'
    r'(AND\b|OR\b|\(|\)))')
SPELL_FIELDS = ['SpellName[enUS]', 'Rank[enUS]', 'Description[enUS]', 'Attributes']
TOOLTIP_PREVIEW_CHARS = 180

STOCK_GENERIC_SPELLS = frozenset({
    75, 81, 107, 196, 197, 198, 199, 200, 201, 202, 227, 264, 266, 674, 750, 1180, 2567, 2764,
    3018, 3124, 3127, 5009, 5011, 5019, 6603, 8613, 8737, 9077, 9078, 9116, 15590, 28875,
    33379, 33388, 33391, 34090, 34091, 54197,
})


class ExtraSpellsError(ValueError):
    pass


def log_events(path: Path | None) -> tuple[Counter, Counter]:
    casts, others = Counter(), Counter()
    if path and Path(path).exists():
        for line in Path(path).read_text(encoding='utf-8').splitlines():
            if not line.strip():
                continue
            event, spell, count = line.rsplit(',', 2)
            (casts if event in CAST_EVENTS else others)[int(spell)] += int(count)
    return casts, others


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


def cpp_int(token: str) -> int:
    match = CPP_INT.fullmatch(token)
    if match is None:
        raise ValueError(token)
    digits = match['digits'].replace("'", '')
    if digits[:2].lower() in ('0x', '0b'):
        return int(digits, 0)
    return int(digits, 8 if digits.startswith('0') else 10)


def grant_rows(path: Path, name: str, width: int, required: bool):
    block = re.sub(r'//[^\n]*|/\*.*?\*/', '', array_block(path, name, required), flags=re.S).strip() + '}'
    if block == '}':
        return
    if block.startswith('{{') and block.endswith('}}'):
        block = block[1:-1]
    if not (block.startswith('{') and block.endswith('}')):
        raise ExtraSpellsError(f'invalid initializer for {name} in {path}')
    remaining = block[1:-1].strip()
    while remaining:
        match = re.match(r'\{([^{}]*)\}\s*(,|$)', remaining)
        row = match[1].split(',') if match else []
        try:
            if len(row) != width:
                raise ValueError
            yield tuple(cpp_int(token.strip()) for token in row)
        except ValueError as error:
            raise ExtraSpellsError(f'unparseable row in {name} in {path}: {remaining[:120]}') from error
        remaining = remaining[match.end():].strip()


def class_spells_table(root: Path = REPOSITORY, required: bool = False) -> dict[int, dict[int, int]]:
    found: dict[int, dict[int, int]] = {}
    for class_id, level, spell_id in grant_rows(Path(root) / CUSTOM_CLASS_HEADER, 'ClassSpells', 3, required):
        per_class = found.setdefault(class_id, {})
        per_class[spell_id] = min(per_class.get(spell_id, level), level)
    return found


def live_baseline_spells(root: Path = REPOSITORY, required: bool = False) -> dict[int, set[int]]:
    found: dict[int, set[int]] = {}
    for class_id, race_id, spell_id in grant_rows(Path(root) / LIVE_BASELINE_HEADER, 'Spells', 3, required):
        if race_id == 0:
            found.setdefault(class_id, set()).add(spell_id)
    return found


def taught_abilities(root: Path = REPOSITORY, required: bool = False) -> dict[int, dict[int, tuple[int, int]]]:
    found: dict[int, dict[int, tuple[int, int]]] = {}
    for class_id, _, level, parent_id, spell_id in grant_rows(
            Path(root) / TAUGHT_ABILITY_HEADER, 'TaughtAbilities', 5, required):
        per_class = found.setdefault(class_id, {})
        if spell_id not in per_class or level < per_class[spell_id][0]:
            per_class[spell_id] = (level, parent_id)
    return found


def felsworn_rifts(root: Path = REPOSITORY, required: bool = False) -> dict[int, int]:
    found: dict[int, int] = {}
    for spell_id, level in grant_rows(Path(root) / COMPAT_SOURCE, 'FelswornHordeCapitalRifts', 2, required):
        found[spell_id] = min(found.get(spell_id, level), level)
    return found


def matching_trainer_keys(active: dict[tuple[int, int], int], where_clause: str | None) -> list[tuple[int, int]]:
    if where_clause is None:
        return list(active)
    tokens = []
    pos = 0
    where_clause = where_clause.strip()
    while pos < len(where_clause):
        match = TRAINER_PREDICATE.match(where_clause, pos)
        if not match:
            raise ExtraSpellsError(f'unsupported trainer_spell WHERE: {where_clause!r}')
        column, equals, members, operator = match.groups()
        if operator:
            tokens.append(operator.upper())
        else:
            index = 0 if column.strip('`').lower() == 'trainerid' else 1
            values = {int(value) for value in (equals or members).split(',')}
            tokens.append((index, values))
        pos = match.end()

    tokens = iter(tokens)
    token = next(tokens, None)

    def consume():
        nonlocal token
        current, token = token, next(tokens, None)
        return current

    def term():
        current = consume()
        if isinstance(current, tuple):
            index, values = current
            return lambda key: key[index] in values
        if current == '(':
            predicate = expression()
            if consume() == ')':
                return predicate
        raise ExtraSpellsError(f'invalid trainer_spell WHERE: {where_clause!r}')

    def conjunction():
        parts = [term()]
        while token == 'AND':
            consume()
            parts.append(term())
        return lambda key: all(part(key) for part in parts)

    def expression():
        parts = [conjunction()]
        while token == 'OR':
            consume()
            parts.append(conjunction())
        return lambda key: any(part(key) for part in parts)

    predicate = expression()
    if token is not None:
        raise ExtraSpellsError(f'invalid trainer_spell WHERE: {where_clause!r}')
    return [key for key in active if predicate(key)]


def write_trainer_row(active, mode, trainer_id, spell_id, req_level):
    key = trainer_id, spell_id
    if 'IGNORE' not in mode.upper() or key not in active:
        active[key] = req_level


def apply_trainer_delete(active: dict[tuple[int, int], int], where_clause: str | None) -> None:
    if where_clause is None:
        active.clear()
        return
    for key in matching_trainer_keys(active, where_clause):
        del active[key]


def apply_trainer_insert(active: dict[tuple[int, int], int], mode: str,
                         columns_text: str | None, values_text: str) -> None:
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
        write_trainer_row(active, mode, trainer_id, spell_id, req_level)


def resolve_select_int(expr: str, source_row: dict[str, int]) -> int:
    token = expr.strip(' `\r\n\t')
    lowered = token.lower()
    if lowered in source_row:
        return source_row[lowered]
    try:
        return int(token)
    except ValueError as error:
        raise ExtraSpellsError(f'unsupported trainer_spell SELECT expression: {expr!r}') from error


def apply_trainer_insert_select(active: dict[tuple[int, int], int], mode: str,
                                columns_text: str | None, select_text: str, where_clause: str | None,
                                limit_text: str | None) -> None:
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
        write_trainer_row(active, mode, trainer_id, spell_id, req_level)


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
            try:
                if deleted := TRAINER_DELETE.fullmatch(statement):
                    apply_trainer_delete(active, deleted[1])
                elif inserted := TRAINER_INSERT.fullmatch(statement):
                    apply_trainer_insert(active, *inserted.groups())
                elif inserted_select := TRAINER_INSERT_SELECT.fullmatch(statement):
                    apply_trainer_insert_select(active, *inserted_select.groups())
                elif (updated := UNTRACKED_UPDATE.fullmatch(statement)) and all(
                        UNTRACKED_ASSIGNMENT.fullmatch(assignment.strip()) for assignment in updated[1].split(',')):
                    continue
                elif TRAINER_WRITE.match(statement):
                    raise ExtraSpellsError('unsupported trainer_spell statement')
            except ExtraSpellsError as error:
                raise ExtraSpellsError(f'{error} in {path}: {statement}') from error
    by_class: dict[int, dict[int, int]] = {}
    for (trainer_id, spell_id), req_level in active.items():
        if not TRAINER_CLASS_MIN <= trainer_id <= TRAINER_CLASS_MAX:
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
    chains = progression_chains(dbc, header, class_id)
    rank_to_first = {first: first for first in chains} | {
        rank: first for first, chain in chains.items() for rank, _ in chain}
    raw_candidates = server_candidates(source_root, class_id, level, required=True)
    collapsed: dict[int, set[str]] = {}
    for spell_id, srcs in raw_candidates.items():
        base = rank_to_first.get(spell_id, spell_id)
        collapsed.setdefault(base, set()).update(srcs)

    source_ids = raw_candidates.keys() | collapsed.keys()
    source_rows = rows_by_identity(dbc, 'Spell', source_ids, SPELL_FIELDS)
    missing = {spell: set(raw_candidates.get(spell, ())) | collapsed.get(spell, set())
               for spell in sorted(source_ids - source_rows.keys())}
    if missing:
        grants = '; '.join(f'{spell} ({", ".join(sorted(sources))})' for spell, sources in missing.items())
        raise ExtraSpellsError(f'source-granted spells missing from Spell.dbc in {dbc_dir}: {grants}')

    ca_list = class_spells(dbc_dir, class_id, header, level)
    advancement_ids = {spell.spell_id for spell in ca_list}
    extra_ids = [entry['spell'] for entry in class_file.get('extra_spells', [])]
    excluded_by_id = validate_excluded_extra_spells(class_file.get('excluded_extra_spells', []),
                                                    advancement_ids, set(extra_ids))
    covered_list = class_spells(dbc_dir, class_id, header, level, extra_spells=extra_ids)
    covered_base = {spell.spell_id for spell in covered_list}
    covered_ranks = {rank for spell in covered_list for rank in spell.ranks}
    updates = source_root / UPDATES_ROOT / 'updates'
    pulled_ids = pulled_spells(records, covered_list, updates)

    covered_name_sources = sorted({spell.max_rank for spell in covered_list} | pulled_ids)
    candidate_ranks: dict[int, tuple[int, ...]] = {}
    for base in collapsed:
        chain = chains.get(base, [])
        all_ranks = (base,) + tuple(rank for rank, _ in chain)
        candidate_ranks[base] = all_ranks
    needed_ids = set(covered_name_sources) | {rank for ranks in candidate_ranks.values() for rank in ranks}
    spell_rows = source_rows | rows_by_identity(dbc, 'Spell', needed_ids - source_ids, SPELL_FIELDS)

    covered_names: dict[str, list[int]] = {}
    for spell_id in covered_name_sources:
        row = spell_rows.get(spell_id)
        if row and row['SpellName[enUS]']:
            covered_names.setdefault(row['SpellName[enUS]'], []).append(spell_id)
    for name in covered_names:
        covered_names[name] = sorted(set(covered_names[name]))

    casts, others = log_events(log_events_path)
    covered_candidates = 0
    excluded, stock_generic, unchained_ranks, unaccounted = [], [], [], []
    for base, srcs_set in sorted(collapsed.items()):
        if base in covered_base or base in covered_ranks or base in pulled_ids:
            covered_candidates += 1
            continue
        srcs = sorted(srcs_set)
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
        if base not in chains and name in covered_names and re.fullmatch(r'Rank\s+\d+', row['Rank[enUS]'] or '', re.I):
            unchained_ranks.append({
                'spell': base, 'name': name, 'rank': row['Rank[enUS]'] or '',
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
        },
        'unaccounted': unaccounted,
        'unchained_ranks': unchained_ranks,
        'excluded': excluded,
        'stock_generic': stock_generic,
    }


def audit_extra_lines(report: dict) -> list[str]:
    counts = report['counts']
    lines = [
        f"class {report['class_id']} ({report['name']}, L{report['level']}): "
        f"advancement={counts['advancement']} extra={counts['extra_spells']} "
        f"excluded={counts['excluded']} stock={counts['stock_generic']} "
        f"unchained={counts['unchained_ranks']} unaccounted={counts['unaccounted']}"
    ]
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
