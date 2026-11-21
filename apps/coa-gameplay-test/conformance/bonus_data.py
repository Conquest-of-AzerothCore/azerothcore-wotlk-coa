from dataclasses import dataclass
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile

from streamed import rows, statements

TABLE = 'spell_bonus_data'
ROOT = Path(__file__).resolve().parents[3]
BASELINE_MANIFEST = Path('data') / 'coa-world' / 'baseline.json'
BASE_DIRECTORY = Path('data') / 'sql' / 'base' / 'db_world'
MODULES = Path('modules')
MODULE_SQL = Path('data') / 'sql'
WORLD = 'world'
MODULE_STATE = 'MODULE'
LATE_STATES = frozenset({'PENDING', 'CUSTOM', MODULE_STATE})
MAX_DEPTH = 10
COLUMNS = ('entry', 'direct_bonus', 'dot_bonus', 'ap_bonus', 'ap_dot_bonus', 'comments')
MENTION = re.compile(rf'(?i)(?<!\w){TABLE}(?!\w)')
INSERT = re.compile(rf'(?is)^INSERT\s+(IGNORE\s+)?INTO\s+`?{TABLE}`?\s*(?:\(([^)]*)\))?\s*VALUES\s*(.*)$')
DELETE = re.compile(rf'(?is)^DELETE\s+FROM\s+`?{TABLE}`?(?:\s+WHERE\s+(.*))?$')
KEYED = re.compile(r'(?is)^`?entry`?\s*(?:=\s*(\d+)|IN\s*\(\s*(\d+(?:\s*,\s*\d+)*)\s*\))$')
RESET = re.compile(rf'(?is)^(?:DROP\s+TABLE(?:\s+IF\s+EXISTS)?|CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?)\s+`?{TABLE}`?')
DUMP_ONLY = re.compile(rf'(?is)^(?:LOCK\s+TABLES\s+`?{TABLE}`?\s+WRITE|/\*!\d+\s+ALTER\s+TABLE\s+`?{TABLE}`?\s+'
                       r'(?:DISABLE|ENABLE)\s+KEYS\s*\*/)$')
INCLUDE_ROW = re.compile(r"\(\s*'([^']*)'\s*,\s*'([A-Z]+)'\s*\)")
UPDATE_ROW = re.compile(r"\(\s*'([^']*)'\s*,\s*'([0-9A-Fa-f]*)'")
POWER_TERM = re.compile(r'(?i)\$(?:ap|rap|sp|sph|spfi|spn|spfr|sps|spa)(?![a-z0-9])')
SCHOOL_DAMAGE, HEALTH_LEECH = 2, 9
DIRECT_EFFECTS = {SCHOOL_DAMAGE: 'SPELL_EFFECT_SCHOOL_DAMAGE', HEALTH_LEECH: 'SPELL_EFFECT_HEALTH_LEECH'}
ADD_FLAT_MODIFIER, ADD_PCT_MODIFIER, OVERRIDE_CLASS_SCRIPTS = 107, 108, 112
COEFFICIENT_SPELLMODS = frozenset({24, 32, 41, 42, 45})
COEFFICIENT_SCRIPTS = frozenset({20032, 20041, 20042, 20045})
SPELL_POWER_MODIFIERS = frozenset({24, 41, 20041})
SP_TERM, AP_TERM = 'sp', 'ap'
SPELLFAMILY_HUNTER = 9
HUNTER_EXCLUDED_FLAG = 0x10000000
RANGED_SLOT_ATTRIBUTE = 0x2
RANGED_WEAPON_MASK = (1 << 2) | (1 << 3) | (1 << 18) | (1 << 16)
DAMAGE_CLASS_MELEE = 2
AP_TERM_SOURCE = 'Unit.cpp:9885'
SP_TERM_SOURCE = 'Unit.cpp:9914'
TERM_EPSILON = 1e-6
SPELL_RANK_FILE = 'SpellRank.dbc'
WDBC_HEADER = struct.Struct('<4s4I')
SPELL_RANK_RECORD = struct.Struct('<4I')
FIRST_RANK_SOURCE = 'SpellMgr.cpp:1010-1016'


class UnreadableTable(Exception):
    pass


@dataclass(frozen=True)
class BonusRow:
    entry: int
    direct: float
    dot: float
    ap: float
    ap_dot: float
    source: str

    @property
    def terms(self) -> bool:
        return any((self.direct, self.dot, self.ap, self.ap_dot))


@dataclass(frozen=True)
class BonusTable:
    rows: dict[int, BonusRow]
    unreadable: str = ''
    directories: tuple[str, ...] = ()


@dataclass(frozen=True)
class BonusTerms:
    row: BonusRow
    ap_term: float
    sp_term: float
    power: str
    attack_power: float
    spell_power: float
    ap_formula: float = 0.0
    sp_formula: float = 0.0
    spell: int | None = None

    @property
    def inherited(self) -> bool:
        return self.spell is not None and self.spell != self.row.entry

    @property
    def total(self) -> float:
        return self.ap_term + self.sp_term

    @property
    def truncated(self) -> int:
        return sum(abs(formula - term) > TERM_EPSILON for term, formula in ((self.ap_term, self.ap_formula),
                                                                             (self.sp_term, self.sp_formula)))

    def text(self) -> str:
        parts = []
        if self.row.ap:
            parts.append(f'ap_bonus {self.row.ap:g} x {self.power} {self.attack_power:g} = {self.ap_formula:.3f}, '
                         f'int32 {self.ap_term:g} ({AP_TERM_SOURCE})')
        if self.row.direct:
            parts.append(f'direct_bonus {self.row.direct:g} x spell power {self.spell_power:g} = '
                         f'{self.sp_formula:.3f}, int32 {self.sp_term:g} ({SP_TERM_SOURCE})')
        return (f'CalcValue observed; terms modelled from spell_bonus_data, not observed: the engine adds '
                f'spell_bonus_data {self.row.entry} ({self.row.source}){self.inheritance()} after CalcValue in '
                f'Unit::SpellDamageBonusDone, each term truncated to int32 on its own: {"; ".join(parts)}; each read '
                f'is modelled as the CalcValue read + {self.total:g}; the applied damage is measured by the hit '
                f'entries of the claim')

    def inheritance(self) -> str:
        if not self.inherited:
            return ''
        return (f', the first rank of {self.spell}, which has no row of its own ({FIRST_RANK_SOURCE}, '
                f'SpellMgr::GetSpellBonusData)')

    def detail(self) -> dict:
        detail = {'entry': self.row.entry, 'source': self.row.source, 'direct_bonus': self.row.direct,
                  'ap_bonus': self.row.ap, 'attack_power': self.power, 'ap_term': self.ap_term,
                  'sp_term': self.sp_term, 'ap_formula': self.ap_formula, 'sp_formula': self.sp_formula,
                  'truncated_terms': self.truncated}
        if self.inherited:
            detail['first_rank_of'] = self.spell
        return detail


@dataclass(frozen=True)
class NotModelled:
    reason: str


def float32(value: float) -> float:
    return struct.unpack('f', struct.pack('f', value))[0]


def engine_ap_term(coefficient: float, attack_power: float) -> int:
    return int(float32(float32(coefficient) * float32(attack_power)))


def engine_sp_term(coefficient: float, spell_power: float, factor: float = 1.0) -> int:
    scaled = float32(float32(float32(coefficient) * 100.0) / 100.0)
    return int(float32(float32(int(spell_power) * scaled) * float32(factor)))


def number(value: str | None) -> float:
    if value is None:
        raise UnreadableTable('a NULL coefficient')
    try:
        return float(value.strip("'"))
    except ValueError:
        raise UnreadableTable(f'coefficient {value!r} is not a number') from None


def apply(table: dict[int, BonusRow], statement: str, source: str, columns: tuple[str, ...]):
    if DUMP_ONLY.match(statement):
        return
    if RESET.match(statement):
        table.clear()
        return
    deleted = DELETE.match(statement)
    if deleted:
        if deleted.group(1) is None:
            table.clear()
            return
        keyed = KEYED.match(deleted.group(1).strip())
        if not keyed:
            raise UnreadableTable(f'{source}: DELETE condition {deleted.group(1).strip()[:80]!r} is not keyed by entry')
        for entry in re.findall(r'\d+', keyed.group(1) or keyed.group(2)):
            table.pop(int(entry), None)
        return
    inserted = INSERT.match(statement)
    if not inserted or re.search(r'(?i)\bON\s+DUPLICATE\s+KEY\b', inserted.group(3)):
        raise UnreadableTable(f'{source}: statement {statement[:80]!r} changes {TABLE} outside DELETE and INSERT')
    names = (tuple(column.strip(' `\r\n\t') for column in inserted.group(2).split(','))
             if inserted.group(2) else columns)
    for values in rows(inserted.group(3)):
        if len(values) != len(names):
            raise UnreadableTable(f'{source}: a row of {len(values)} values for {len(names)} columns')
        fields = dict(zip(names, values))
        entry = int(fields['entry'])
        if inserted.group(1) and entry in table:
            continue
        table[entry] = BonusRow(entry, *(number(fields.get(name, '0')) for name in COLUMNS[1:5]), source)


def apply_text(table: dict[int, BonusRow], text: str, source: str, columns: tuple[str, ...]):
    for statement in statements(text):
        if MENTION.search(statement):
            apply(table, statement, source, columns)


def sql_rows(text: str, pattern: re.Pattern) -> list[tuple[str, str]]:
    return [match.groups() for statement in statements(text) if statement.upper().startswith('INSERT')
            for match in pattern.finditer(statement)]


@dataclass(frozen=True)
class World:
    base_text: str
    base_source: str
    columns: tuple[str, ...]
    includes: list[tuple[str, str]]
    applied: dict[str, str]


def baseline_world(root: Path, table: str = TABLE) -> World:
    manifest_path = root / BASELINE_MANIFEST
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    listed = manifest.get('tables', {}).get(table)
    if listed is None:
        raise UnreadableTable(f'{BASELINE_MANIFEST} lists no {table} table')
    with zipfile.ZipFile(manifest_path.parent / manifest['archive']) as archive:
        text = archive.read(f'{table}.sql').decode('utf-8')
        updates = archive.read('updates.sql').decode('utf-8')
        includes = archive.read('updates_include.sql').decode('utf-8')
    return World(text, f'{manifest["archive"]}:{table}.sql', tuple(listed['columns']), sql_rows(includes, INCLUDE_ROW),
                 {name: digest.upper() for name, digest in sql_rows(updates, UPDATE_ROW)})


def base_world(root: Path, table: str = TABLE, columns: tuple[str, ...] = COLUMNS) -> World:
    base = root / BASE_DIRECTORY
    read = lambda name: (base / name).read_text(encoding='utf-8')
    return World(read(f'{table}.sql'), str(BASE_DIRECTORY / f'{table}.sql'), columns,
                 sql_rows(read('updates_include.sql'), INCLUDE_ROW),
                 {name: digest.upper() for name, digest in sql_rows(read('updates.sql'), UPDATE_ROW)})


def sql_files(directory: Path, depth: int = 1) -> list[Path]:
    found = []
    for path in sorted(directory.iterdir()):
        if path.is_dir():
            if depth < MAX_DEPTH:
                found += sql_files(path, depth + 1)
        elif path.suffix == '.sql':
            found.append(path)
    return found


def module_directories(root: Path) -> list[Path]:
    modules = root / MODULES
    if not modules.is_dir():
        return []
    return [directory for module in sorted(modules.iterdir()) if (module / MODULE_SQL).is_dir()
            for directory in sorted((module / MODULE_SQL).iterdir()) if directory.is_dir() and WORLD in directory.name]


def hashes(content: bytes) -> set[str]:
    return {hashlib.sha1(content).hexdigest().upper(), hashlib.sha1(content.replace(b'\r', b'')).hexdigest().upper()}


def world_of(root: Path, table: str = TABLE, columns: tuple[str, ...] = COLUMNS) -> World:
    return baseline_world(root, table) if (root / BASELINE_MANIFEST).is_file() else base_world(root, table, columns)


def update_directories(root: Path, world: World) -> list[tuple[Path, str]]:
    directories = [(Path(str(root) + path[1:]) if path.startswith('$') else Path(path), state)
                   for path, state in world.includes]
    return directories + [(directory, MODULE_STATE) for directory in module_directories(root)]


def shown_directories(root: Path, directories: list[tuple[Path, str]]) -> tuple[str, ...]:
    return tuple(str(directory.relative_to(root)) if directory.is_relative_to(root) else str(directory)
                 for directory, _ in directories)


def pending_updates(root: Path, world: World, directories: list[tuple[Path, str]], table: str,
                    mention: re.Pattern):
    files: dict[str, tuple[Path, str]] = {}
    for directory, state in directories:
        if not directory.is_dir():
            continue
        for path in sql_files(directory):
            if path.name in files:
                raise UnreadableTable(f'duplicate update file name {path.name}, which the updater refuses')
            files[path.name] = (path, state)
    applied_names = {digest: name for name, digest in world.applied.items()}
    ordered = sorted(files.items(), key=lambda item: (item[1][1] in LATE_STATES, item[0]))
    for name, (path, state) in ordered:
        content = path.read_bytes()
        if not mention.search(content.decode('utf-8', errors='replace')):
            continue
        digests = hashes(content)
        if world.applied.get(name) in digests:
            continue
        renamed = next((applied_names[digest] for digest in digests if digest in applied_names), None)
        if renamed is not None and renamed not in files:
            continue
        source = str(path.relative_to(root)) if path.is_relative_to(root) else str(path)
        if state == MODULE_STATE:
            raise UnreadableTable(f'{source} names {table}, and whether its module is built cannot be read offline')
        yield source, content.decode('utf-8')


def read_table(root: Path) -> BonusTable:
    world = world_of(root)
    directories = update_directories(root, world)
    table: dict[int, BonusRow] = {}
    apply_text(table, world.base_text, world.base_source, world.columns)
    for source, text in pending_updates(root, world, directories, TABLE, MENTION):
        apply_text(table, text, source, world.columns)
    return BonusTable(table, '', shown_directories(root, directories))


@lru_cache(maxsize=None)
def bonus_table(root: Path = ROOT) -> BonusTable:
    try:
        return read_table(Path(root))
    except (UnreadableTable, OSError, KeyError, ValueError, zipfile.BadZipFile) as error:
        return BonusTable({}, str(error) or type(error).__name__)


def client_first_ranks(data: bytes, known_spells) -> dict[int, int]:
    magic, count, fields, size, _ = WDBC_HEADER.unpack_from(data)
    if magic != b'WDBC' or fields != 4 or size != SPELL_RANK_RECORD.size:
        raise ValueError(f'{SPELL_RANK_FILE} is not a WDBC table of four 32-bit fields')
    ladders: dict[int, dict[int, int]] = {}
    for record in range(count):
        _, key, spell, rank = SPELL_RANK_RECORD.unpack_from(data, WDBC_HEADER.size + record * size)
        ladders.setdefault(key, {})[rank] = spell
    first: dict[int, int] = {}
    for key in sorted(ladders):
        chain = []
        for rank, spell in sorted(ladders[key].items()):
            if rank != len(chain) + 1 or spell not in known_spells:
                chain = []
                break
            chain.append(spell)
        if len(chain) >= 2:
            first.update({spell: chain[0] for spell in chain})
    return first


def bonus_row(table: BonusTable, spell_id: int, first_rank: int | None = None) -> BonusRow | None:
    row = table.rows.get(spell_id)
    if row is None and first_rank is not None and first_rank != spell_id:
        return table.rows.get(first_rank)
    return row


def level_penalty(spell_level: int, max_level: int, caster_level: int) -> float:
    if spell_level <= 0 or spell_level >= max_level:
        return 1.0
    penalty = (20.0 - spell_level) * 3.75 if spell_level < 20 else 0.0
    factor = min(1.0, float32((spell_level + 6.0) / caster_level))
    return float32(factor * (100.0 - penalty) / 100.0)


def uses_ranged_power(field) -> bool:
    ranged = ((field('SpellFamilyName') == SPELLFAMILY_HUNTER and not field('SpellFamilyFlags[1]') & HUNTER_EXCLUDED_FLAG)
              or field('EquippedItemSubClassMask') & RANGED_WEAPON_MASK or field('Attributes') & RANGED_SLOT_ATTRIBUTE)
    return bool(ranged) and field('DmgClass') != DAMAGE_CLASS_MELEE


def single_school(mask: int) -> int | None:
    if mask <= 0 or mask & (mask - 1):
        return None
    return mask.bit_length() - 1


def bonus_terms(table: BonusTable, spell_id: int, effect: int, token_text: str, caster, field,
                modifiers: list[int], first_rank: int | None = None) -> BonusTerms | NotModelled | None:
    if not POWER_TERM.search(token_text):
        return None
    if table.unreadable:
        return NotModelled(f'{TABLE} is unreadable ({table.unreadable}), so the terms the engine adds after '
                           f'CalcValue are unknown')
    row = bonus_row(table, spell_id, first_rank)
    if row is None or not row.terms:
        return None
    kind = field('Effect[%d]' % effect)
    if kind not in DIRECT_EFFECTS:
        return NotModelled(f'{TABLE} {spell_id} ({row.source}) has terms, but effect {effect} is Spell.dbc effect '
                           f'{kind}, not a direct damage effect, so the row applies outside the modelled path')
    if row.dot or row.ap_dot:
        return NotModelled(f'{TABLE} {spell_id} ({row.source}) carries periodic terms (dot_bonus {row.dot:g}, '
                           f'ap_dot_bonus {row.ap_dot:g}), which the direct read does not model')
    school = single_school(int(field('SchoolMask') or 0))
    spell_power = caster.sp_by_school.get(school) if school is not None else None
    power, attack_power = ('RAP', caster.rap) if uses_ranged_power(field) else ('AP', caster.ap)
    active = [spell for spell, term in modifiers if (term == SP_TERM and spell_power != 0) or
              (term == AP_TERM and attack_power)]
    if active:
        return NotModelled(f'spell(s) {", ".join(map(str, active))} of the family carry a coefficient modifier '
                           f'(SPELLMOD_BONUS_MULTIPLIER or a private AP/SP coefficient index) that can affect '
                           f'{spell_id} with a non-zero stat; the recorded stats do not tell whether it applies')
    sp_term = sp_formula = 0.0
    if row.direct:
        if spell_power is None:
            return NotModelled(f'{spell_id} SchoolMask {field("SchoolMask")} has no single recorded spell power')
        penalty = level_penalty(int(field('SpellLevel') or 0), int(field('MaxLevel') or 0), caster.level)
        if spell_power and penalty != 1.0:
            return NotModelled(f'{spell_id} SpellLevel {field("SpellLevel")} gives a level penalty {penalty:g} at '
                               f'level {caster.level} (Unit::CalculateLevelPenalty), not modelled')
        sp_formula = row.direct * spell_power
        sp_term = float(engine_sp_term(row.direct, spell_power))
    ap_formula = row.ap * attack_power if row.ap else 0.0
    ap_term = float(engine_ap_term(row.ap, attack_power)) if row.ap else 0.0
    return BonusTerms(row, ap_term, sp_term, power, attack_power, spell_power or 0.0, ap_formula, sp_formula,
                      spell_id)


def coefficient_modifiers(records, family_spells: dict[int, tuple[str, tuple[int, ...]]],
                          spell_id: int) -> list[tuple[int, str]]:
    flags = family_spells.get(spell_id, (None, (0, 0, 0)))[1]
    found = []
    for candidate in sorted(family_spells):
        for effect in range(3):
            aura = records.field('Spell', candidate, f'EffectApplyAuraName[{effect}]')
            misc = records.field('Spell', candidate, f'EffectMiscValue[{effect}]')
            mask = [records.field('Spell', candidate, f'EffectSpellClassMask[{effect * 3 + word}]') for word in range(3)]
            masked = any(word & flag for word, flag in zip(mask, flags))
            if ((aura in (ADD_FLAT_MODIFIER, ADD_PCT_MODIFIER) and misc in COEFFICIENT_SPELLMODS
                 and (masked or not any(mask)))
                    or (aura == OVERRIDE_CLASS_SCRIPTS and misc in COEFFICIENT_SCRIPTS and masked)):
                found.append((candidate, SP_TERM if misc in SPELL_POWER_MODIFIERS else AP_TERM))
                break
    return found
