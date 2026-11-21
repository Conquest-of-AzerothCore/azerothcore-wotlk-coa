from dataclasses import asdict
from functools import lru_cache
import json
from pathlib import Path
import subprocess

from behaviours import cleaned_tooltip
from classes import table_rows
from passives import classify
from profile import DBC_DIR
from questions import ANY_STATS
from tooltip import Readout, Records, Unreadable, read_tooltip
from values import EFFECTS, dataset, facts_of

COA_SRC = Path(__file__).resolve().parents[3] / 'src/server/coa'
REPO_ROOT = Path(__file__).resolve().parents[3]
PROC_FIELDS = ('ProcFlags', 'ProcChance', 'ProcCharges')
TRIGGER_SPELL_FIELDS = ('EffectTriggerSpell[0]', 'EffectTriggerSpell[1]', 'EffectTriggerSpell[2]')
STAT_LABELS = ('low', 'high')
TALENT_RANK_SLOTS = 5


def serialize_readout(readout: Readout) -> dict:
    return {'values': [asdict(value) for value in readout.values], 'unreadable': list(readout.unreadable)}


def read_or_unreadable(dbc, spell_id: int, caster) -> Readout:
    try:
        return read_tooltip(dbc, spell_id, caster)
    except Unreadable as error:
        return Readout([], [str(error)])


def spell_effects(records: Records, spell_id: int) -> list[int]:
    return [effect for effect in EFFECTS if records.field('Spell', spell_id, f'Effect[{effect}]')]


def decoded_effects(class_file: dict, records: Records, spell_id: int, text: str, values: list,
                    verdicts: dict | None = None) -> list[dict]:
    effects = spell_effects(records, spell_id)
    decoded = []
    for effect in effects:
        try:
            effect_record = classify(class_file, records, spell_id, spell_id, effect, effects, text, values,
                                     verdicts)
        except Unreadable as error:
            decoded.append({'effect': effect, 'reason': f'unreadable: {error}'})
            continue
        decoded.append(asdict(effect_record))
    return decoded


def raw_field_or_none(records: Records, spell_id: int, name: str):
    try:
        return records.field('Spell', spell_id, name)
    except Unreadable:
        return None


def proc_trigger_candidate(records: Records, spell_id: int) -> dict:
    return {name: raw_field_or_none(records, spell_id, name) for name in (*PROC_FIELDS, *TRIGGER_SPELL_FIELDS)}


def rank_facts(records: Records, spell_id: int) -> dict:
    try:
        return asdict(facts_of(records, spell_id))
    except Unreadable as error:
        return {'unreadable': str(error)}


def scripted_hooks(spell_id: int, src_dir: Path = COA_SRC) -> list[str]:
    if not src_dir.is_dir():
        return []
    result = subprocess.run(['grep', '-rn', '-w', str(spell_id), str(src_dir)], capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise RuntimeError(f'grep failed for spell {spell_id}: {result.stderr}')
    lines = [line for line in result.stdout.splitlines() if line]
    relative = []
    for line in lines:
        path, _, rest = line.partition(':')
        try:
            relative.append(f'{Path(path).resolve().relative_to(REPO_ROOT)}:{rest}')
        except ValueError:
            relative.append(line)
    return sorted(relative)


@lru_cache(maxsize=None)
def talent_catalog_ranks(dbc) -> dict:
    mapping: dict[int, dict] = {}
    try:
        rows = list(table_rows(dbc, 'CharacterAdvancement', [f'RankSpell[{i}]' for i in range(TALENT_RANK_SLOTS)]))
    except ValueError:
        return mapping
    for entry_id, row in rows:
        ranks = [row[f'RankSpell[{i}]'] for i in range(TALENT_RANK_SLOTS) if row[f'RankSpell[{i}]']]
        for rank_index, rank_spell_id in enumerate(ranks):
            mapping[rank_spell_id] = {'entry': entry_id, 'rank_index': rank_index, 'ranks': ranks}
    return mapping


def talent_catalog_entry(dbc, spell_id: int) -> dict | None:
    return talent_catalog_ranks(dbc).get(spell_id)


def verdict_entries(verdicts_dir, spell_id: int) -> list[dict]:
    if verdicts_dir is None:
        return []
    from compare import read_verdicts
    path = Path(verdicts_dir)
    if not (path / 'verdicts.json').is_file():
        return []
    _, verdicts = read_verdicts(path)
    return [asdict(verdict) for verdict in verdicts if verdict.spell_id == spell_id or verdict.rank_id == spell_id]


def live_statuses(verdicts_dir) -> dict[str, str] | None:
    if verdicts_dir is None:
        return None
    from compare import read_verdicts
    path = Path(verdicts_dir)
    if not (path / 'verdicts.json').is_file():
        return None
    _, verdicts = read_verdicts(path)
    return {verdict.label: verdict.status for verdict in verdicts}


def sheet(dbc_dir, class_file: dict, spell_id: int, verdicts_dir=None) -> dict:
    dbc = dataset(Path(dbc_dir))
    records = Records(dbc)
    if not records.has_spell(spell_id):
        raise ValueError(f'Spell {spell_id} is not in Spell.dbc')
    name = records.field('Spell', spell_id, 'SpellName[enUS]')
    description = records.field('Spell', spell_id, 'Description[enUS]')
    text = cleaned_tooltip(records, spell_id)
    readouts = {label: read_or_unreadable(dbc, spell_id, stats) for label, stats in zip(STAT_LABELS, ANY_STATS)}
    high_values = readouts['high'].values
    return {
        'spell_id': spell_id,
        'name': name,
        'tooltip': {
            'description': description,
            'cleaned': text,
            'low': serialize_readout(readouts['low']),
            'high': serialize_readout(readouts['high']),
        },
        'effects': decoded_effects(class_file, records, spell_id, text, high_values, live_statuses(verdicts_dir)),
        'facts': rank_facts(records, spell_id),
        'proc_trigger_fields': proc_trigger_candidate(records, spell_id),
        'scripted_hooks': scripted_hooks(spell_id),
        'talent_catalog_entry': talent_catalog_entry(dbc, spell_id),
        'verdicts': verdict_entries(verdicts_dir, spell_id),
    }


def render_text(data: dict) -> str:
    lines = [f"Spell {data['spell_id']} - {data['name']}", '']
    lines.append('Tooltip:')
    lines.append(f"  description: {data['tooltip']['description']}")
    lines.append(f"  cleaned: {data['tooltip']['cleaned']}")
    for label in STAT_LABELS:
        readout = data['tooltip'][label]
        lines.append(f'  {label} stats:')
        for value in readout['values']:
            lines.append(f"    {value['text']} = {value['value']} (effect {value['effect_index']}, "
                         f"kind {value['kind']}, spell {value['spell_id']})")
        for item in readout['unreadable']:
            lines.append(f'    unreadable: {item}')
    lines.append('')
    lines.append('Decoded effects:')
    for effect in data['effects']:
        lines.append(f"  effect {effect.get('effect')}: aura={effect.get('aura')} family={effect.get('family')} "
                     f"reason={effect.get('reason')} points={effect.get('points')}")
        for target in effect.get('targets', ()) or ():
            lines.append(f"    target: {target}")
        for plan in effect.get('plans', ()) or ():
            lines.append(f"    plan: {plan}")
    lines.append('')
    lines.append('Facts:')
    for key, value in data['facts'].items():
        lines.append(f'  {key}: {value}')
    lines.append('')
    lines.append('Proc/trigger fields:')
    for key, value in data['proc_trigger_fields'].items():
        lines.append(f'  {key}: {value}')
    lines.append('')
    lines.append('Scripted hooks:')
    for hook in data['scripted_hooks']:
        lines.append(f'  {hook}')
    lines.append('')
    talent_entry = data.get('talent_catalog_entry')
    if talent_entry:
        lines.append(f"Talent catalog entry {talent_entry['entry']} rank {talent_entry['rank_index']}: "
                     f"ranks {talent_entry['ranks']}")
        lines.append('')
    lines.append('Verdicts:')
    for verdict in data['verdicts']:
        lines.append(f"  {verdict.get('check')} {verdict.get('status')}: {verdict.get('explanation')}")
    lines.append('')
    return '\n'.join(lines) + '\n'


def write_sheets(dbc_dir, class_file: dict, out_dir, spell_ids, verdicts_dir=None) -> list[Path]:
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for spell_id in spell_ids:
        data = sheet(dbc_dir, class_file, spell_id, verdicts_dir)
        json_path = out_dir / f'{spell_id}.json'
        json_path.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
        text_path = out_dir / f'{spell_id}.txt'
        text_path.write_text(render_text(data), encoding='utf-8')
        written.append(json_path)
    return written
