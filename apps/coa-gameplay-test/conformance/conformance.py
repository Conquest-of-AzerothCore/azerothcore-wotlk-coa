import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import re
import sys

from behaviours import behaviour_entries, behaviour_scenario
from classes import PROGRESSION_HEADER, ClassSpell, class_spells
from compare import (ALERTS_FILE, LEVERS_FILE, REPORT_FILE, STATUSES, VERDICTS_FILE, ScenarioDrift, evaluate,
                     write_levers, write_outputs)
from coverage import COVERAGE_FILE, write_coverage
from diff import IMPACT_FILE, diff_directories, write_impact
from passives import passive_scenario
from hits import (UNMODELLED, Unmodelled, aura_modifiers, casts_needed, hit_parts, melee_scenario, records_of,
                  reference_hit_model, reference_melee_model)
from procs import (proc_entries, proc_plan, proc_scenario, proc_status_expectation, proc_unmodelled_expectation,
                   shares_aura)
from profile import DBC_DIR, load_class_file
from questions import QUESTIONS_FILE
from stack import PASSES, STACK_CHECKS, STACK_DPS, STACK_KIND, stack_scenarios
from tooltip import read_tooltip
from triggers import (trigger_entries, trigger_plan, trigger_scenario, trigger_status_expectation,
                      trigger_unmodelled_expectation)
from values import Expectation, armed_for, dataset, structure_stats, value_scenario

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

SCENARIO_DIR = 'scenarios'
MANIFEST_FILE = 'manifest.json'
KEY_SEPARATORS = re.compile(r'[^a-z0-9]+')
DRIFT_EXIT = 2
DIFF_EXIT = 3


def scenario_key(*parts) -> str:
    return KEY_SEPARATORS.sub('-', '-'.join(['conformance', *map(str, parts)]).lower()).strip('-')


class ManifestWriter:
    def __init__(self, class_file: dict, out: Path):
        self.class_file = class_file
        self.out = out
        self.entries: list[dict] = []

    def add(self, key: str, kind: str, spell: ClassSpell | None, rank_id: int, expectations: list[Expectation],
            scenario: dict | None = None, tokens: list[str] = (), name: str | None = None):
        if any(entry['key'] == key for entry in self.entries):
            raise ValueError(f'Duplicate scenario key {key}')
        file, sha = None, None
        if scenario is not None:
            text = json.dumps(run.validate(scenario), indent=2) + '\n'
            file = f'{SCENARIO_DIR}/{key}.json'
            (self.out / file).write_text(text, encoding='utf-8')
            sha = hashlib.sha256(text.encode('utf-8')).hexdigest()
        self.entries.append({'key': key, 'file': file, 'sha256': sha, 'kind': kind,
                             'spell_id': spell.spell_id if spell else rank_id,
                             'spell_name': spell.name if spell else name or kind,
                             'rank_id': rank_id, 'tokens': list(tokens),
                             'expectations': [asdict(expectation) for expectation in expectations]})


def unmodelled(label: str, spell: ClassSpell, reason: str) -> list[Expectation]:
    return [Expectation(label, 'unmodelled', spell.spell_id, spell.max_rank, None, '', UNMODELLED + reason)]


def add_values(writer: ManifestWriter, spell: ClassSpell, dbc_dir: Path):
    class_file = writer.class_file
    for rank_id in spell.ranks:
        scenario, expectations = value_scenario(class_file, spell, rank_id)
        armed_file = armed_for(class_file, records_of(class_file), rank_id)
        readout = read_tooltip(dataset(dbc_dir), rank_id, structure_stats(armed_file))
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
        parts = hit_parts(class_file, spell, casts)
    except ValueError as error:
        writer.add(key, 'hit', spell, spell.max_rank, unmodelled(label, spell, str(error)))
        return
    if len(parts) == 1:
        scenario, expectations = parts[0]
        if all(expectation.check == 'unmodelled' for expectation in expectations):
            scenario = None
        writer.add(key, 'hit', spell, spell.max_rank, expectations, scenario)
        return
    for part, (scenario, expectations) in enumerate(parts, start=1):
        writer.add(scenario_key(class_file['name'], 'hit', spell.max_rank, 'part', part), 'hit', spell,
                   spell.max_rank, expectations, scenario)


def add_passive(writer: ManifestWriter, spell: ClassSpell):
    scenario, expectations = passive_scenario(writer.class_file, spell)
    writer.add(scenario_key(writer.class_file['name'], 'passive', spell.max_rank), 'passive', spell, spell.max_rank,
               expectations, scenario)


def add_behaviour(writer: ManifestWriter, entry: dict):
    class_file = writer.class_file
    scenario, expectations = behaviour_scenario(class_file, entry)
    writer.add(scenario_key(class_file['name'], 'behaviour', entry['spell']), 'behaviour', None, entry['spell'],
               expectations, scenario, name=entry['name'])


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


def add_proc(writer: ManifestWriter, entry: dict):
    class_file = writer.class_file
    aura, name = entry['aura'], entry['name']
    key_parts = (aura, entry['proc_spell']) if shares_aura(class_file, entry) else (aura,)
    key = scenario_key(class_file['name'], 'proc', *key_parts)
    if entry.get('status'):
        writer.add(key, 'proc', None, aura, [proc_status_expectation(entry)], name=name)
        return
    try:
        plan = proc_plan(class_file, entry)
    except Unmodelled as error:
        writer.add(key, 'proc', None, aura, [proc_unmodelled_expectation(entry, error.reason)], name=name)
        return
    for part in range(plan.parts):
        scenario, expectations = proc_scenario(class_file, entry, part)
        writer.add(scenario_key(class_file['name'], 'proc', *key_parts, 'part', part + 1), 'proc', None, aura,
                   expectations, scenario, name=name)


def add_trigger(writer: ManifestWriter, entry: dict):
    class_file = writer.class_file
    aura, name = entry['aura'], entry['name']
    key = scenario_key(class_file['name'], 'trigger', aura)
    if entry.get('status'):
        writer.add(key, 'trigger', None, aura, [trigger_status_expectation(entry)], name=name)
        return
    try:
        plan = trigger_plan(class_file, entry)
    except Unmodelled as error:
        writer.add(key, 'trigger', None, aura, [trigger_unmodelled_expectation(entry, error.reason)], name=name)
        return
    for part in range(len(plan.part_attempts)):
        scenario, expectations = trigger_scenario(class_file, entry, part)
        writer.add(scenario_key(class_file['name'], 'trigger', aura, 'part', part + 1), 'trigger', None, aura,
                   expectations, scenario, name=name)


def add_stack(writer: ManifestWriter, passes: int):
    class_file = writer.class_file
    numbers: dict[str, int] = {}
    for scenario, expectations in stack_scenarios(class_file, passes):
        config = next(expectation.model for expectation in expectations if expectation.check == STACK_DPS)['config']
        numbers[config] = numbers.get(config, 0) + 1
        writer.add(scenario_key(class_file['name'], STACK_KIND, config, 'pass', numbers[config]), STACK_KIND, None, 0,
                   expectations, scenario, name=config)


def known_modifiers(class_file: dict) -> list[dict]:
    records = records_of(class_file)
    return [{**asdict(modifier),
             'base_points': records.field('Spell', modifier.spell_id, f'EffectBasePoints[{modifier.effect_index}]'),
             'real_points_per_level': records.field('Spell', modifier.spell_id,
                                                    f'EffectRealPointsPerLevel[{modifier.effect_index}]')}
            for modifier in aura_modifiers(records, class_file.get('known_auras', []), class_file['level'])]


def selected_spells(class_file: dict, dbc_dir: Path, spell_ids: list[int] | None) -> list[ClassSpell]:
    spells = class_spells(dbc_dir, class_file['class_id'], PROGRESSION_HEADER, class_file['level'],
                          [entry['spell'] for entry in class_file.get('extra_spells', [])])
    if spell_ids is None:
        return spells
    chosen = [spell for spell in spells if spell.spell_id in spell_ids or set(spell.ranks) & set(spell_ids)]
    unknown = set(spell_ids) - {rank for spell in chosen for rank in (spell.spell_id, *spell.ranks)}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} spells')
    return chosen


def selected_passives(class_file: dict, dbc_dir: Path, spell_ids: list[int]) -> list[ClassSpell]:
    chosen = selected_spells(class_file, dbc_dir, spell_ids)
    active = sorted(spell.spell_id for spell in chosen if not spell.passive)
    if active:
        raise ValueError(f'Spells {active} are not passive')
    return chosen


def generate(class_id: int, out: Path, spells: list[int] | None = None, procs: list[int] | None = None,
             stack: bool = False, passes: int = PASSES, passives: list[int] | None = None,
             triggers: list[int] | None = None, behaviours: list[int] | None = None) -> Path:
    class_file = load_class_file(class_id)
    dbc_dir = Path(class_file.get('dbc_dir', DBC_DIR))
    out = Path(out)
    scenario_dir = out / SCENARIO_DIR
    if scenario_dir.is_dir() and any(scenario_dir.glob('*.json')):
        raise ValueError(f'{scenario_dir} already holds scenarios; generate into a new directory')
    scenario_dir.mkdir(parents=True, exist_ok=True)
    writer = ManifestWriter(class_file, out)
    everything = (spells is None and procs is None and passives is None and triggers is None and behaviours is None
                 and not stack)
    chosen_procs = proc_entries(class_file, procs) if everything or procs is not None else []
    chosen_triggers = trigger_entries(class_file, triggers) if everything or triggers is not None else []
    chosen_passives = selected_passives(class_file, dbc_dir, passives) if passives is not None else []
    chosen_behaviours = behaviour_entries(class_file, behaviours) if everything or behaviours is not None else []
    generated_passives: set[int] = set()
    if everything or spells is not None:
        for spell in selected_spells(class_file, dbc_dir, spells):
            add_values(writer, spell, dbc_dir)
            if spell.passive:
                add_passive(writer, spell)
                generated_passives.add(spell.spell_id)
            else:
                add_hit(writer, spell)
    for spell in chosen_passives:
        if spell.spell_id not in generated_passives:
            add_passive(writer, spell)
    for entry in chosen_procs:
        add_proc(writer, entry)
    for entry in chosen_triggers:
        add_trigger(writer, entry)
    for entry in chosen_behaviours:
        add_behaviour(writer, entry)
    if stack:
        add_stack(writer, passes)
    if everything:
        add_melee(writer)
    manifest = {'schema': 1, 'class_id': class_file['class_id'], 'class_name': class_file['name'],
                'level': class_file['level'], 'dbc_dir': str(dbc_dir), 'class_file': class_file,
                'known_modifiers': known_modifiers(class_file), 'scenarios': writer.entries}
    path = out / MANIFEST_FILE
    path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return path


def generate_command(args) -> int:
    path = generate(args.class_id, args.out, args.spell, args.proc, args.stack, args.passes, args.passive,
                    args.trigger, args.behaviour)
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
    print(f'{alerts}\n{report}\n{out / VERDICTS_FILE}\n{out / QUESTIONS_FILE}')
    if any(verdict.check in STACK_CHECKS for verdict in comparison.verdicts):
        print(write_levers(args.manifest, args.results, comparison.verdicts, out))
    return 0


def spell_ids(text: str) -> set[int]:
    return {int(part) for part in text.split(',') if part.strip()}


def diff_command(args) -> int:
    try:
        changes = diff_directories(args.before, args.after, args.intended)
    except ValueError as error:
        print(f'No impact report: {error}', file=sys.stderr)
        return DIFF_EXIT
    path = write_impact(changes, args.intended, args.before, args.after, args.out or args.after)
    listed = [change for change in changes if change.listed]
    unintended = [change for change in listed if not change.intended]
    print(f'{len(changes)} changes, {len(listed)} listed, {len(unintended)} unintended and listed, '
          f'{sum(change.significant for change in changes)} significant')
    print(path)
    return 0


def coverage_command(args) -> int:
    try:
        path = write_coverage(args.before, args.after, args.out or args.after)
    except ValueError as error:
        print(f'No coverage report: {error}', file=sys.stderr)
        return DIFF_EXIT
    print(path)
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description='Generate class conformance scenarios and compare their results.')
    commands = parser.add_subparsers(dest='command', required=True)
    generating = commands.add_parser('generate', help='write the scenarios and manifest of a class')
    generating.add_argument('--class', dest='class_id', type=int, required=True)
    generating.add_argument('--out', type=Path, required=True)
    generating.add_argument('--spell', type=int, action='append',
                            help='a class spell id or rank id; repeat to select several spells')
    generating.add_argument('--passive', type=int, action='append',
                            help='a passive class spell id or rank id: its with/without scenario only; repeatable')
    generating.add_argument('--proc', type=int, action='append',
                            help='the aura of a proc entry of the class file; repeat to select several procs')
    generating.add_argument('--trigger', type=int, action='append',
                            help='the aura of a trigger entry of the class file; repeat to select several triggers')
    generating.add_argument('--behaviour', type=int, action='append',
                            help='the spell of a behaviour entry of the class file; repeat to select several')
    generating.add_argument('--stack', action='store_true',
                            help='the passes of every stack configuration of the class file, cumulative talents')
    generating.add_argument('--passes', type=int, default=PASSES, help=f'passes per stack configuration ({PASSES})')
    comparing = commands.add_parser('compare', help=f'judge a verify_all stamp, write {ALERTS_FILE}, {REPORT_FILE}, '
                                                    f'{VERDICTS_FILE}, {QUESTIONS_FILE} and, for stack runs, '
                                                    f'{LEVERS_FILE}')
    comparing.add_argument('--manifest', type=Path, required=True)
    comparing.add_argument('--results', type=Path, required=True, help='a .cache/verify-all/<STAMP> directory')
    comparing.add_argument('--out', type=Path, help='output directory, the manifest directory by default')
    diffing = commands.add_parser('diff', help=f'write {IMPACT_FILE}: what moved between two compare outputs')
    diffing.add_argument('--before', type=Path, required=True, help=f'a compare output directory ({VERDICTS_FILE})')
    diffing.add_argument('--after', type=Path, required=True, help='a compare output directory')
    diffing.add_argument('--intended', type=spell_ids, default=set(),
                         help='comma-separated spell or rank ids the change is meant to move')
    diffing.add_argument('--out', type=Path, help='output directory, the after directory by default')
    covering = commands.add_parser('coverage', help=f'write {COVERAGE_FILE}: spells, passives and actives judged in '
                                                    f'two compare outputs')
    covering.add_argument('--before', type=Path, required=True, help=f'a compare output directory ({VERDICTS_FILE})')
    covering.add_argument('--after', type=Path, required=True, help='a compare output directory')
    covering.add_argument('--out', type=Path, help='output directory, the after directory by default')
    args = parser.parse_args(argv)
    handlers = {'generate': generate_command, 'compare': compare_command, 'diff': diff_command,
                'coverage': coverage_command}
    return handlers[args.command](args)


if __name__ == '__main__':
    sys.exit(main())
