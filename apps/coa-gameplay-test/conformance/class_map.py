import argparse
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

CLASS_IDS = range(12, 33)
NUMBER = re.compile(r'(?<![\w.])\d{3,7}(?![\w.])')
TOKEN = re.compile(r'\$\{[^}]*\}(?:\.[1-9])?|\$/\d+;\d*[A-Za-z]\d?|\$\*\d+;\d*[A-Za-z]\d?|\$<\w+>|\$\d*[A-Za-z]\d?')
CONDITION = re.compile(r'\$\?[^\[]*')
MARKUP = re.compile(r'@[a-z]+:|:[a-z]+@|@s:\d+:-?\d+@')
SPELL_MARKUP = re.compile(r'@s:(\d+):')
COLOR = re.compile(r'\|[cC][0-9a-fA-F]{8}|\|[rR]')
LITERAL = re.compile(r'(?<![\w$.])\d+(?:\.\d+)?(?![\w])')
SENTENCE_END = re.compile(r'(?<=[.!?])\s+|\n+')
LETTER_KINDS = {**dict.fromkeys('sSmMwWbBeE', 'value'), **dict.fromkeys('dD', 'duration'),
                **dict.fromkeys('hH', 'chance'), **dict.fromkeys('oO', 'periodic_total'),
                **dict.fromkeys('tT', 'period'), **dict.fromkeys('aA', 'radius'), **dict.fromkeys('rR', 'range'),
                **dict.fromkeys('uU', 'stacks'), **dict.fromkeys('xXiInN', 'count')}
FAMILY_CALL = re.compile(r'Family\(\s*\w+\s*,\s*(\d)\s*,\s*(\d+)\s*\)')
FLAGS_AND = re.compile(r'SpellFamilyFlags\[(\d)\]\s*&\s*(\d+)')
FLAG96 = re.compile(r'flag96\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
SPELL_FIELDS = (['SpellName[enUS]', 'Description[enUS]', 'Attributes', 'SpellFamilyName']
                + [f'SpellFamilyFlags[{word}]' for word in range(3)]
                + [f'EffectTriggerSpell[{index}]' for index in range(3)]
                + [f'Effect[{index}]' for index in range(3)]
                + [f'EffectApplyAuraName[{index}]' for index in range(3)]
                + [f'EffectMiscValue[{index}]' for index in range(3)])
MAX_SPELLMOD = 32
SPELLMOD_AURAS = (107, 108)
UNHANDLED = ('EffectNULL', 'EffectUnused', 'HandleNULL', 'HandleUnused', 'nullptr')
SCRIPT_ONLY = ('EffectDummy', 'EffectScriptEffect', 'HandleAuraDummy')
CORE_MINIMUM_ID = 10000
STOCK_AURAS = 317
STOCK_EFFECTS = 165
STOCK_PASSIVE_EFFECTS = (20, 78)
CORE_DIRECTORIES = ('src/server/scripts', 'src/server/game')
IGNORED_SOURCES = ('CoAGameplay', 'AscensionSpellProgressionData.h', 'AscensionLiveBaselineData.h')
CLASS_FILE_SHARE = 0.1
CLASS_FILE_MINIMUM = 5
SHARED_FILE_CLASSES = 3
BASE_ROW = re.compile(r'^\s*\{\s*(\d+),\s*(\d+),\s*(\d+)\s*\},?\s*$', re.MULTILINE)
CAST_EVENTS = ('SPELL_CAST_SUCCESS', 'SPELL_CAST_START')


def token_kind(token):
    if token.startswith('${'):
        return 'formula'
    if token.startswith('$<'):
        return 'variable'
    letter = re.search(r'[A-Za-z]', token[1:].split(';')[-1])
    return LETTER_KINDS.get(letter.group(0), 'other') if letter else 'other'


def clean(text):
    return CONDITION.sub('', MARKUP.sub(' ', COLOR.sub('', text)))


def handler_table(path, marker):
    text = path.read_text(encoding='utf-8')
    block = text[text.index(marker):]
    block = block[block.index('{') + 1:block.index('\n};')]
    return [found[0] or 'nullptr' for found in re.findall(r'^\s*(?:&(?:AuraEffect|Spell)::(\w+)|(nullptr))\s*,', block,
                                                           re.MULTILINE)]


def named_auras(root):
    defines = (root / 'src/server/game/Spells/Auras/SpellAuraDefines.h').read_text(encoding='utf-8')
    names = {int(value): name for name, value in re.findall(r'^\s*(SPELL_AURA_\w+)\s*=\s*(\d+)', defines, re.MULTILINE)}
    code = ''.join(path.read_text(encoding='utf-8', errors='replace')
                   for directory in ('src/server/game', 'src/server/coa', 'src/server/scripts')
                   for path in (root / directory).rglob('*.cpp'))
    return {value: name for value, name in names.items() if re.search(rf'\b{name}\b', code)}


def core_reading(row, effects, auras, named):
    unhandled, script_only, custom = [], [], []
    for slot in range(3):
        effect, aura = row[f'Effect[{slot}]'], row[f'EffectApplyAuraName[{slot}]']
        misc = row[f'EffectMiscValue[{slot}]']
        if effect >= STOCK_EFFECTS:
            custom.append(f'effect {effect}')
        if aura >= STOCK_AURAS:
            custom.append(f'aura {aura}')
        if aura in SPELLMOD_AURAS and misc >= 29:
            custom.append(f'modifier operation {misc}')
        if effect in STOCK_PASSIVE_EFFECTS:
            effect = 0
        if effect:
            name = effects[effect] if effect < len(effects) else 'out of range'
            if name in UNHANDLED or effect >= len(effects):
                unhandled.append(f'effect {effect} {name}')
            elif name in SCRIPT_ONLY:
                script_only.append(f'effect {effect} {name}')
        if aura:
            name = auras[aura] if aura < len(auras) else 'out of range'
            if name == 'nullptr' and aura in named:
                name = f'used in code as {named[aura]}'
            if name in UNHANDLED or aura >= len(auras):
                unhandled.append(f'aura {aura} {name}')
            elif name in SCRIPT_ONLY:
                script_only.append(f'aura {aura} {name}')
            if aura in SPELLMOD_AURAS and not 0 <= misc < MAX_SPELLMOD:
                unhandled.append(f'aura {aura} modifier operation {misc}')
    return unhandled, script_only, custom


def source_kind(path):
    if path.name.endswith('Data.h'):
        return 'data'
    return 'code'


def number_index(root):
    index = defaultdict(list)
    lines = {}
    for path in sorted((root / 'src/server/coa').rglob('*')):
        if path.suffix not in ('.cpp', '.h') or any(path.name.startswith(prefix) or path.name == prefix
                                                     for prefix in IGNORED_SOURCES):
            continue
        relative = path.relative_to(root).as_posix()
        text = path.read_text(encoding='utf-8', errors='replace')
        lines[relative] = text
        for number, line in enumerate(text.splitlines(), 1):
            for found in set(NUMBER.findall(line)):
                index[int(found)].append((relative, number, source_kind(path)))
    for directory in CORE_DIRECTORIES:
        for path in sorted((root / directory).rglob('*.cpp')):
            relative = path.relative_to(root).as_posix()
            for number, line in enumerate(path.read_text(encoding='utf-8', errors='replace').splitlines(), 1):
                for found in set(NUMBER.findall(line)):
                    if int(found) >= CORE_MINIMUM_ID:
                        index[int(found)].append((relative, number, 'core'))
    return index, lines


def family_masks(text):
    masks = {(int(word), int(mask)) for word, mask in FAMILY_CALL.findall(text) + FLAGS_AND.findall(text)
             if int(mask)}
    for words in FLAG96.findall(text):
        masks |= {(word, int(mask)) for word, mask in enumerate(words) if int(mask)}
    return masks


def base_candidates(root):
    text = (root / 'src/server/coa/AscensionCustomClassData.h').read_text(encoding='utf-8')
    block = text[text.index('ClassSpells ='):text.index('LegacyGeneratedClassSpells')]
    found = defaultdict(dict)
    for class_id, level, spell in BASE_ROW.findall(block):
        found[int(class_id)][int(spell)] = int(level)
    return found


def log_events(path):
    casts, others = Counter(), Counter()
    if path and path.exists():
        for line in path.read_text(encoding='utf-8').splitlines():
            event, spell, count = line.rsplit(',', 2)
            (casts if event in CAST_EVENTS else others)[int(spell)] += int(count)
    return casts, others


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--worktree', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--log-events', type=Path)
    parser.add_argument('--dbc-dir', type=Path)
    args = parser.parse_args()
    package = args.worktree / 'apps/coa-gameplay-test/conformance'
    sys.path.insert(0, str(package))
    from classes import PROGRESSION_HEADER, class_spells, dataset, rows_by_identity
    from profile import DBC_DIR, spell_dbc_sha256
    from scaffold import SHARED_DEFINES

    DBC_DIR = args.dbc_dir or DBC_DIR

    dbc = dataset(DBC_DIR)
    titles = {int(number): title.strip() for number, title in
              re.findall(r'CLASS_\w+\s*=\s*(\d+),?\s*//\s*TITLE\s+(.+)', SHARED_DEFINES.read_text(encoding='utf-8'))}
    index, sources = number_index(args.worktree)
    commit = subprocess.run(['git', '-C', str(args.worktree), 'rev-parse', '--short=10', 'HEAD'],
                            capture_output=True, text=True, check=True).stdout.strip()
    classes = {}
    named = named_auras(args.worktree)
    effects = handler_table(args.worktree / 'src/server/game/Spells/SpellEffects.cpp', 'pEffect SpellEffects[')
    auras = handler_table(args.worktree / 'src/server/game/Spells/Auras/SpellAuraEffects.cpp',
                          'pAuraEffectHandler AuraEffectHandler[')
    candidates = base_candidates(args.worktree)
    casts, others = log_events(args.log_events)
    listings = {}
    errors = {}
    for class_id in CLASS_IDS:
        title = titles[class_id]
        try:
            advancement = {spell.spell_id for spell in class_spells(DBC_DIR, class_id, PROGRESSION_HEADER)}
            known = set(rows_by_identity(dbc, 'Spell', set(candidates[class_id]), ['Attributes']))
            extra = sorted(known - advancement)
            listed = class_spells(DBC_DIR, class_id, PROGRESSION_HEADER, extra_spells=extra)
        except ValueError as error:
            errors[class_id] = {'title': title, 'error': str(error)}
            continue
        ranked = {rank for spell in listed for rank in spell.ranks}
        rows = rows_by_identity(dbc, 'Spell', ranked, SPELL_FIELDS)
        related = {}
        for spell in listed:
            text = rows[spell.spell_id]['Description[enUS]'] or ''
            foreign = {int(number) for token in TOKEN.findall(clean(text))
                       for number in re.findall(r'\$(\d{3,})', token)}
            foreign |= {int(number) for number in SPELL_MARKUP.findall(text)}
            triggered = {rows[rank][f'EffectTriggerSpell[{slot}]'] for rank in spell.ranks if rank in rows
                         for slot in range(3)} - {0}
            related[spell.spell_id] = {'ranks': set(spell.ranks), 'foreign': foreign - set(spell.ranks),
                                       'triggered': triggered - set(spell.ranks)}
        extra = {identity for parts in related.values() for identity in parts['foreign'] | parts['triggered']}
        rows.update(rows_by_identity(dbc, 'Spell', extra - set(rows), SPELL_FIELDS))
        code_files = Counter()
        for parts in related.values():
            identities = parts['ranks'] | parts['foreign'] | parts['triggered']
            for path in {hit[0] for identity in identities for hit in index.get(identity, []) if hit[2] == 'code'}:
                code_files[path] += 1
        own_files = sorted(path for path, count in code_files.items()
                           if count >= CLASS_FILE_MINIMUM
                           and count >= CLASS_FILE_SHARE * max(code_files.values(), default=0))
        family = Counter(rows[spell.spell_id]['SpellFamilyName'] for spell in listed).most_common(1)[0][0]
        masks = sorted({mask for path in own_files for mask in family_masks(sources[path])}) if family else []
        spells = []
        for spell in listed:
            text = rows[spell.spell_id]['Description[enUS]'] or ''
            cleaned = clean(text)
            tokens = TOKEN.findall(cleaned)
            kinds = Counter(token_kind(token) for token in tokens)
            prose = TOKEN.sub(' ', cleaned)
            sentences = [part for part in SENTENCE_END.split(cleaned.strip()) if re.search(r'[A-Za-z]', part)]
            parts = related[spell.spell_id]
            hits = {'own': [], 'foreign': [], 'triggered': []}
            for role, identities in (('own', parts['ranks']), ('foreign', parts['foreign']),
                                     ('triggered', parts['triggered'])):
                for identity in sorted(identities):
                    hits[role] += [f'{path}:{line}:{kind}:{identity}' for path, line, kind in index.get(identity, [])]
            family_hits = []
            for identity in sorted(parts['ranks'] | parts['foreign'] | parts['triggered']):
                row = rows.get(identity)
                if row and family and row['SpellFamilyName'] == family:
                    family_hits += [f'{identity}:SpellFamilyFlags[{word}]&{mask}' for word, mask in masks
                                    if row[f'SpellFamilyFlags[{word}]'] & mask]
            everything = hits['own'] + hits['foreign'] + hits['triggered']
            code = [hit for hit in everything if ':code:' in hit]
            data = [hit for hit in everything if ':data:' in hit]
            core = [hit for hit in everything if ':core:' in hit]
            unhandled, script_only, custom = [], [], []
            for identity in sorted(parts['ranks'] | parts['triggered']):
                if identity in rows:
                    found = core_reading(rows[identity], effects, auras, named)
                    unhandled += [f'{identity}: {reason}' for reason in found[0]]
                    script_only += [f'{identity}: {reason}' for reason in found[1]]
                    custom += [f'{identity}: {reason}' for reason in found[2]]
            if code:
                risk = 'scripted'
            elif family_hits:
                risk = 'family_mask'
            elif core:
                risk = 'core_script'
            elif data:
                risk = 'data_row'
            else:
                risk = 'stock'
            own_ranks = sorted(parts['ranks'])
            linked = sorted(parts['foreign'] | parts['triggered'])
            spells.append({'spell': spell.spell_id, 'name': spell.name, 'passive': spell.passive,
                           'source': 'advancement' if spell.spell_id in advancement else 'base_candidate',
                           'log_casts': sum(casts[rank] for rank in own_ranks),
                           'log_other_events': sum(others[rank] for rank in own_ranks),
                           'log_linked_events': sum(casts[rank] + others[rank] for rank in linked),
                           'required_level': spell.required_level, 'ranks': len(spell.ranks),
                           'tooltip': text, 'sentences': len(sentences), 'tokens': len(tokens),
                           'token_kinds': dict(kinds), 'literals': len(LITERAL.findall(prose)),
                           'foreign_spells': sorted(parts['foreign']), 'triggered_spells': sorted(parts['triggered']),
                           'risk': risk, 'core_hits': core, 'unhandled': unhandled, 'script_only': script_only,
                           'custom_mechanics': custom,
                           'gap': ('unhandled' if unhandled else 'script_only' if script_only else 'none')
                           if risk in ('stock', 'data_row') else 'covered_by_code',
                           'code_hits': code, 'data_hits': data, 'family_hits': family_hits})
        listings[class_id] = own_files
        classes[class_id] = {'title': title, 'family': family, 'own_files': own_files,
                             'file_hits': dict(code_files.most_common()),
                             'own_file_lines': sum(sources[path].count('\n') for path in own_files),
                             'spells': spells}
    usage = Counter(path for files in listings.values() for path in files)
    for entry in classes.values():
        entry['shared_files'] = [path for path in entry['own_files'] if usage[path] >= SHARED_FILE_CLASSES]
        entry['own_files'] = [path for path in entry['own_files'] if usage[path] < SHARED_FILE_CLASSES]
        entry['own_file_lines'] = sum(sources[path].count('\n') for path in entry['own_files'])
    args.out.mkdir(parents=True, exist_ok=True)
    payload = {'server_commit': commit, 'worktree': str(args.worktree), 'dbc_dir': str(DBC_DIR),
               'spell_dbc_sha256': spell_dbc_sha256(DBC_DIR), 'classes': classes, 'errors': errors}
    (args.out / 'class-map.json').write_text(json.dumps(payload, indent=1, sort_keys=True) + '\n', encoding='utf-8')
    header = ('| Id | Class | Spells | Base cand. | Passive | Ranks | Sentences | Tokens | Scripted | Family mask |'
              ' Core script | Data row | Stock | No code: unhandled | No code: script-only | Custom mechanics |'
              ' Seen in logs | Own code lines |\n'
              '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n')
    body = ''
    for class_id, entry in sorted(classes.items()):
        spells = entry['spells']
        risk = Counter(spell['risk'] for spell in spells)
        gap = Counter(spell['gap'] for spell in spells)
        seen = sum(1 for spell in spells
                   if spell['log_casts'] or spell['log_other_events'] or spell['log_linked_events'])
        body += (f"| {class_id} | {entry['title']} | {len(spells)} | "
                 f"{sum(spell['source'] == 'base_candidate' for spell in spells)} | "
                 f"{sum(spell['passive'] for spell in spells)} | "
                 f"{sum(spell['ranks'] for spell in spells)} | {sum(spell['sentences'] for spell in spells)} | "
                 f"{sum(spell['tokens'] for spell in spells)} | {risk['scripted']} | {risk['family_mask']} | "
                 f"{risk['core_script']} | {risk['data_row']} | {risk['stock']} | {gap['unhandled']} | "
                 f"{gap['script_only']} | "
                 f"{sum(1 for spell in spells if spell['custom_mechanics'])} | "
                 f"{seen} ({seen / len(spells):.0%}) | {entry['own_file_lines']} |\n")
    (args.out / 'class-map-table.md').write_text(header + body, encoding='utf-8')
    print(header + body)
    for class_id, entry in sorted(errors.items()):
        print('ERROR', class_id, entry)


if __name__ == '__main__':
    main()
