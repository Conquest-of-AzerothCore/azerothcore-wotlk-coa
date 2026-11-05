import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import re
import sys

from classes import ClassSpell, class_spells
from compare import ALERTS_FILE, REPORT_FILE, STATUSES, ScenarioDrift, evaluate, write_outputs
from hits import (UNMODELLED, Unmodelled, aura_modifiers, casts_needed, hit_scenario, melee_scenario, records_of,
                  reference_hit_model, reference_melee_model)
from profile import DBC_DIR, load_class_file
from tooltip import read_tooltip
from values import Expectation, dataset, structure_stats, value_scenario

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

PROGRESSION_HEADER = Path(__file__).resolve().parents[3] / 'src/server/coa/AscensionSpellProgressionData.h'
SCENARIO_DIR = 'scenarios'
MANIFEST_FILE = 'manifest.json'
KEY_SEPARATORS = re.compile(r'[^a-z0-9]+')
DRIFT_EXIT = 2


def scenario_key(*parts) -> str:
    return KEY_SEPARATORS.sub('-', '-'.join(['conformance', *map(str, parts)]).lower()).strip('-')


class ManifestWriter:
    def __init__(self, class_file: dict, out: Path):
        self.class_file = class_file
        self.out = out
        self.entries: list[dict] = []

    def add(self, key: str, kind: str, spell: ClassSpell | None, rank_id: int, expectations: list[Expectation],
            scenario: dict | None = None, tokens: list[str] = ()):
        if any(entry['key'] == key for entry in self.entries):
            raise ValueError(f'Duplicate scenario key {key}')
        file, sha = None, None
        if scenario is not None:
            text = json.dumps(run.validate(scenario), indent=2) + '\n'
            file = f'{SCENARIO_DIR}/{key}.json'
            (self.out / file).write_text(text, encoding='utf-8')
            sha = hashlib.sha256(text.encode('utf-8')).hexdigest()
        self.entries.append({'key': key, 'file': file, 'sha256': sha, 'kind': kind,
                             'spell_id': spell.spell_id if spell else 0, 'spell_name': spell.name if spell else kind,
                             'rank_id': rank_id, 'tokens': list(tokens),
                             'expectations': [asdict(expectation) for expectation in expectations]})


def unmodelled(label: str, spell: ClassSpell, reason: str) -> list[Expectation]:
    return [Expectation(label, 'unmodelled', spell.spell_id, spell.max_rank, None, '', UNMODELLED + reason)]


def add_values(writer: ManifestWriter, spell: ClassSpell, dbc_dir: Path):
    class_file = writer.class_file
    for rank_id in spell.ranks:
        scenario, expectations = value_scenario(class_file, spell, rank_id)
        readout = read_tooltip(dataset(dbc_dir), rank_id, structure_stats(class_file['level']))
        writer.add(scenario_key(class_file['name'], 'value', rank_id), 'value', spell, rank_id, expectations,
                   scenario, [value.text for value in readout.values])


def add_hit(writer: ManifestWriter, spell: ClassSpell):
    class_file = writer.class_file
    key = scenario_key(class_file['name'], 'hit', spell.max_rank)
    label = f'{spell.max_rank} hit_mean'
    try:
        casts = casts_needed(reference_hit_model(class_file, spell.max_rank))
    except Unmodelled:
        casts = 1
    except ValueError as error:
        writer.add(key, 'hit', spell, spell.max_rank, unmodelled(label, spell, str(error)))
        return
    try:
        scenario, expectations = hit_scenario(class_file, spell, casts)
    except ValueError as error:
        writer.add(key, 'hit', spell, spell.max_rank, unmodelled(label, spell, str(error)))
        return
    if all(expectation.check == 'unmodelled' for expectation in expectations):
        scenario = None
    writer.add(key, 'hit', spell, spell.max_rank, expectations, scenario)


def add_melee(writer: ManifestWriter):
    class_file = writer.class_file
    try:
        swings = casts_needed(reference_melee_model(class_file))
    except Unmodelled:
        swings = 1
    scenario, expectations = melee_scenario(class_file, swings)
    if all(expectation.check == 'unmodelled' for expectation in expectations):
        scenario = None
    writer.add(scenario_key(class_file['name'], 'melee'), 'melee', None, 0, expectations, scenario)


def known_modifiers(class_file: dict) -> list[dict]:
    records = records_of(class_file)
    return [{**asdict(modifier),
             'base_points': records.field('Spell', modifier.spell_id, f'EffectBasePoints[{modifier.effect_index}]'),
             'real_points_per_level': records.field('Spell', modifier.spell_id,
                                                    f'EffectRealPointsPerLevel[{modifier.effect_index}]')}
            for modifier in aura_modifiers(records, class_file.get('known_auras', []), class_file['level'])]


def selected_spells(class_file: dict, dbc_dir: Path, spell_ids: list[int] | None) -> list[ClassSpell]:
    spells = class_spells(dbc_dir, class_file['class_id'], PROGRESSION_HEADER, class_file['level'])
    if spell_ids is None:
        return spells
    chosen = [spell for spell in spells if spell.spell_id in spell_ids or set(spell.ranks) & set(spell_ids)]
    unknown = set(spell_ids) - {rank for spell in chosen for rank in (spell.spell_id, *spell.ranks)}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} spells')
    return chosen


def generate(class_id: int, out: Path, spells: list[int] | None = None) -> Path:
    class_file = load_class_file(class_id)
    dbc_dir = Path(class_file.get('dbc_dir', DBC_DIR))
    out = Path(out)
    scenario_dir = out / SCENARIO_DIR
    if scenario_dir.is_dir() and any(scenario_dir.glob('*.json')):
        raise ValueError(f'{scenario_dir} already holds scenarios; generate into a new directory')
    scenario_dir.mkdir(parents=True, exist_ok=True)
    writer = ManifestWriter(class_file, out)
    for spell in selected_spells(class_file, dbc_dir, spells):
        add_values(writer, spell, dbc_dir)
        add_hit(writer, spell)
    if spells is None:
        add_melee(writer)
    manifest = {'schema': 1, 'class_id': class_file['class_id'], 'class_name': class_file['name'],
                'level': class_file['level'], 'dbc_dir': str(dbc_dir), 'class_file': class_file,
                'known_modifiers': known_modifiers(class_file), 'scenarios': writer.entries}
    path = out / MANIFEST_FILE
    path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return path


def generate_command(args) -> int:
    path = generate(args.class_id, args.out, args.spell)
    manifest = json.loads(path.read_text(encoding='utf-8'))
    written = sum(1 for entry in manifest['scenarios'] if entry['file'])
    print(f'{path}: {written} scenarios in {path.parent / SCENARIO_DIR}, '
          f'{len(manifest["scenarios"]) - written} entries without a scenario')
    return 0


def compare_command(args) -> int:
    try:
        comparison = evaluate(args.manifest, args.results)
    except ScenarioDrift as error:
        print(f'Scenario drift, no verdict:\n{error}', file=sys.stderr)
        return DRIFT_EXIT
    out = args.out or args.manifest.parent
    alerts, report = write_outputs(args.manifest, args.results, comparison.verdicts, out)
    counts = {status: sum(verdict.status == status for verdict in comparison.verdicts) for status in STATUSES}
    print(' '.join(f'{status}={count}' for status, count in counts.items()))
    print(f'{len(comparison.runs)} scenarios with a result, {len(comparison.missing)} without')
    print(f'{alerts}\n{report}')
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description='Generate class conformance scenarios and compare their results.')
    commands = parser.add_subparsers(dest='command', required=True)
    generating = commands.add_parser('generate', help='write the scenarios and manifest of a class')
    generating.add_argument('--class', dest='class_id', type=int, required=True)
    generating.add_argument('--out', type=Path, required=True)
    generating.add_argument('--spell', type=int, action='append',
                            help='a class spell id or rank id; repeat to select several spells')
    comparing = commands.add_parser('compare', help=f'judge a verify_all stamp, write {ALERTS_FILE} and {REPORT_FILE}')
    comparing.add_argument('--manifest', type=Path, required=True)
    comparing.add_argument('--results', type=Path, required=True, help='a .cache/verify-all/<STAMP> directory')
    comparing.add_argument('--out', type=Path, help='output directory, the manifest directory by default')
    args = parser.parse_args(argv)
    return generate_command(args) if args.command == 'generate' else compare_command(args)


if __name__ == '__main__':
    sys.exit(main())
