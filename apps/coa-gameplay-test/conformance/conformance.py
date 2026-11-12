import argparse
from dataclasses import asdict, replace
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Sequence

from behaviours import behaviour_entries, behaviour_scenario, sized_behaviour
from classes import CHARACTER_LEVEL, PROGRESSION_HEADER, ClassSpell, class_spells
from compare import (ALERTS_FILE, LEVERS_FILE, REPORT_FILE, STATUSES, VERDICTS_FILE, BuildMismatch, ScenarioDrift,
                     evaluate, literal_values, write_levers, write_outputs)
from coverage import (COVERAGE_FILE, EvidenceError, clause_coverage, clause_coverage_lines, fragment_entries,
                      load_clauses, load_consumption, write_coverage, write_fragment)
from diff import IMPACT_FILE, diff_directories, write_impact
from expiry import EXPIRY_KIND, behaviour_expiry, trigger_expiry
from packets import PacketError, write_packets
from passives import passive_scenario
from hits import (REFERENCE_TARGET, UNMODELLED, Unmodelled, aura_modifiers, casts_needed, floored_casts, gate_stacks,
                  hit_parts, melee_scenario, rank_hit, records_of, reference_caster, reference_hit_model,
                  reference_melee_model)
from procs import (DELTA_CHECK, delta_proc_plan, delta_proc_scenario, proc_entries, proc_plan, proc_scenario,
                   proc_status_expectation, proc_unmodelled_expectation, shares_aura, shares_proc_spell, trigger_key)
from profile import (DBC_DIR, DbcSetMismatch, control_entries, ledger_consumption_path, load_class_file,
                     server_dbc_dir, spell_dbc_sha256)
from questions import QUESTIONS_FILE
from sample import SampleError, load_buckets, parse_minimums, sample_document
from scaffold import LIVE_BASELINE_HEADER, SHARED_DEFINES, scaffold_class
from sheets import write_sheets
from stack import PASSES, STACK_CHECKS, STACK_DPS, STACK_KIND, stack_scenarios
from tooltip import read_tooltip
from triggers import (COOLDOWN_DELTA_KIND, DURATION_DELTA_KIND, GATE_ABSENCE_KIND, MAGNITUDE_RATIO_KIND,
                      SELF_TRIGGER_KIND, cooldown_trigger_scenario, duration_trigger_scenario, gate_absence_scenario,
                      magnitude_ratio_scenario, self_trigger_scenario, shares_cooldown_effect, shares_trigger_aura,
                      trigger_entries, trigger_plan, trigger_scenario, trigger_status_expectation,
                      trigger_unmodelled_expectation)
from values import Expectation, armed_for, dataset, static_conditional_known, structure_stats, value_scenario

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

SCENARIO_DIR = 'scenarios'
MANIFEST_FILE = 'manifest.json'
KEY_SEPARATORS = re.compile(r'[^a-z0-9]+')
DRIFT_EXIT = 2
DIFF_EXIT = 3
BUILD_EXIT = 5


def scenario_key(*parts) -> str:
    return KEY_SEPARATORS.sub('-', '-'.join(['conformance', *map(str, parts)]).lower()).strip('-')


class ManifestWriter:
    def __init__(self, class_file: dict, out: Path):
        self.class_file = class_file
        self.out = out
        self.entries: list[dict] = []

    def add(self, key: str, kind: str, spell: ClassSpell | None, rank_id: int, expectations: list[Expectation],
            scenario: dict | None = None, tokens: list[str] = (), name: str | None = None,
            known_spells: Sequence[int] = ()):
        if any(entry['key'] == key for entry in self.entries):
            raise ValueError(f'Duplicate scenario key {key}')
        file, sha = None, None
        if scenario is not None:
            text = json.dumps(run.validate(scenario, run.SIMULATED_CLOCK), indent=2) + '\n'
            file = f'{SCENARIO_DIR}/{key}.json'
            (self.out / file).write_text(text, encoding='utf-8')
            sha = hashlib.sha256(text.encode('utf-8')).hexdigest()
        self.entries.append({'key': key, 'file': file, 'sha256': sha, 'kind': kind,
                             'spell_id': spell.spell_id if spell else rank_id,
                             'spell_name': spell.name if spell else name or kind,
                             'rank_id': rank_id, 'tokens': list(tokens), 'known_spells': list(known_spells),
                             'expectations': [asdict(expectation) for expectation in expectations]})


def unmodelled(label: str, spell: ClassSpell, reason: str) -> list[Expectation]:
    return [Expectation(label, 'unmodelled', spell.spell_id, spell.max_rank, None, '', UNMODELLED + reason)]


def add_periodic_total(writer: ManifestWriter, spell: ClassSpell, rank_id: int, item: dict):
    class_file = writer.class_file
    key = scenario_key(class_file['name'], 'periodic-total', rank_id)
    try:
        casts = casts_needed(reference_hit_model(class_file, rank_id))
    except Unmodelled as error:
        writer.add(key, 'periodic_total', spell, rank_id,
                  [Expectation(item['label'], 'unmodelled', spell.spell_id, rank_id, item['effect'], '',
                               UNMODELLED + error.reason)])
        return
    except ValueError as error:
        writer.add(key, 'periodic_total', spell, rank_id,
                  [Expectation(item['label'], 'unmodelled', spell.spell_id, rank_id, item['effect'], '',
                               UNMODELLED + str(error))])
        return
    try:
        parts = hit_parts(class_file, spell, casts, rank_id=rank_id, label=item['label'], check='periodic_total')
    except ValueError as error:
        writer.add(key, 'periodic_total', spell, rank_id,
                  [Expectation(item['label'], 'unmodelled', spell.spell_id, rank_id, item['effect'], '',
                               UNMODELLED + str(error))])
        return
    if len(parts) == 1:
        scenario, expectations = parts[0]
        writer.add(key, 'periodic_total', spell, rank_id, expectations, scenario)
        return
    for part, (scenario, expectations) in enumerate(parts, start=1):
        writer.add(f'{key}-part-{part}', 'periodic_total', spell, rank_id, expectations, scenario)


def add_values(writer: ManifestWriter, spell: ClassSpell, dbc_dir: Path):
    class_file = writer.class_file
    records = records_of(class_file)
    for rank_id in spell.ranks:
        scenario, expectations, periodic_totals = value_scenario(class_file, spell, rank_id)
        armed_file = armed_for(class_file, records, rank_id)
        conditional_known = static_conditional_known(class_file, rank_id)
        readout = read_tooltip(dataset(dbc_dir), rank_id, structure_stats(armed_file, conditional_known))
        description = records.field('Spell', rank_id, 'Description[enUS]')
        literal = literal_values(class_file, rank_id, description)
        tokens = [value.text for value in readout.values] + [value.text for value in literal]
        writer.add(scenario_key(class_file['name'], 'value', rank_id), 'value', spell, rank_id, expectations,
                   scenario, tokens, known_spells=sorted(conditional_known))
        for item in periodic_totals:
            add_periodic_total(writer, spell, rank_id, item)


def add_hit(writer: ManifestWriter, spell: ClassSpell):
    class_file = writer.class_file
    key = scenario_key(class_file['name'], 'hit', spell.max_rank)
    label = f'{spell.max_rank} hit_mean'
    try:
        casts = floored_casts(class_file, spell.max_rank,
                              casts_needed(reference_hit_model(class_file, spell.max_rank)))
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
    key = scenario_key(class_file['name'], 'behaviour', entry['spell'], entry.get('kind', ''),
                        entry.get('variant', ''))
    parts = int(entry.get('parts', 1))
    if parts > 1:
        expectations = [replace(expectation, model={**(expectation.model or {}), 'parts': parts})
                        for expectation in expectations]
        for part in range(1, parts + 1):
            writer.add(scenario_key(key.removeprefix('conformance-'), 'part', part), 'behaviour', None,
                       entry['spell'], expectations, {**scenario, 'name': f'{scenario["name"]} part {part}'},
                       name=entry['name'])
        return
    writer.add(key, 'behaviour', None, entry['spell'], expectations, scenario, name=entry['name'])
    expiry = behaviour_expiry(class_file, entry)
    if expiry:
        writer.add(scenario_key(class_file['name'], EXPIRY_KIND, entry['spell'], entry.get('kind', ''),
                                entry.get('variant', '')), EXPIRY_KIND, None, entry['spell'], expiry[1], expiry[0],
                   name=entry['name'])


def target_gate_entries(class_file: dict, spell_ids: list[int] | None) -> list[dict]:
    entries = class_file.get('target_aura_gates', [])
    if spell_ids is None:
        return entries
    chosen = [entry for entry in entries if entry['spell'] in spell_ids]
    unknown = set(spell_ids) - {entry['spell'] for entry in chosen}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} target_aura_gates entries')
    return chosen


def target_gate_arms(entry: dict, cap: int) -> list[tuple[int, float, str]]:
    arms = [(cap, entry['percent'], '')]
    for held in entry.get('stack_arms', []):
        if not 0 <= held < cap:
            raise ValueError(f'{entry["spell"]} stack_arms {held} is outside 0..{cap - 1} below the stack cap {cap}')
        arms.append((held, entry['percent'] * held / cap, f'stacks {held}'))
    return arms


def add_target_gate(writer: ManifestWriter, entry: dict):
    records = records_of(writer.class_file)
    for held, percent, arm in target_gate_arms(entry, gate_stacks(records, entry['gate_spell'])):
        add_target_gate_arm(writer, entry, held, percent, arm)


def add_target_gate_arm(writer: ManifestWriter, entry: dict, held: int, percent: float, arm: str):
    class_file = writer.class_file
    records = records_of(class_file)
    rank_id = entry['rank']
    suffix = ' '.join(part for part in (entry.get('label_suffix', ''), arm) if part)
    name = records.field('Spell', rank_id, 'SpellName[enUS]')
    test_spell = ClassSpell(rank_id, name, (rank_id,), rank_id, 0, False)
    label = f'{rank_id} hit_mean {suffix}' if suffix else f'{rank_id} hit_mean'
    key = scenario_key(class_file['name'], 'target-gate', entry['spell'], suffix)
    try:
        casts = casts_needed(reference_hit_model(class_file, rank_id))
    except Unmodelled as error:
        writer.add(key, 'target_gate', test_spell, rank_id, unmodelled(label, test_spell, str(error)))
        return
    try:
        parts = hit_parts(class_file, test_spell, casts, rank_id=rank_id, label=label,
                          gate=(entry['gate_spell'], percent, entry['spell']), gate_held=held)
    except ValueError as error:
        writer.add(key, 'target_gate', test_spell, rank_id, unmodelled(label, test_spell, str(error)))
        return
    if len(parts) == 1:
        scenario, expectations = parts[0]
        writer.add(key, 'target_gate', test_spell, rank_id, expectations, scenario)
        return
    for part, (scenario, expectations) in enumerate(parts, start=1):
        writer.add(scenario_key(class_file['name'], 'target-gate', entry['spell'], suffix, 'part', part),
                   'target_gate', test_spell, rank_id, expectations, scenario)


def learned_hit_entries(class_file: dict, spell_ids: list[int] | None) -> list[dict]:
    entries = class_file.get('learned_hits', [])
    if spell_ids is None:
        return entries
    chosen = [entry for entry in entries if entry['spell'] in spell_ids]
    unknown = set(spell_ids) - {entry['spell'] for entry in chosen}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} learned_hits entries')
    return chosen


def add_learned_hit(writer: ManifestWriter, entry: dict):
    class_file = writer.class_file
    records = records_of(class_file)
    rank_id, learned = entry['rank'], entry['spell']
    test_spell = ClassSpell(rank_id, records.field('Spell', rank_id, 'SpellName[enUS]'), (rank_id,), rank_id, 0,
                            False)
    label = f'{rank_id} hit_mean {entry["label_suffix"]}'
    key = scenario_key(class_file['name'], 'learned-hit', learned, entry['label_suffix'])
    armed_file = armed_for(class_file, records, rank_id)
    try:
        casts = casts_needed(rank_hit(armed_file, rank_id, reference_caster(armed_file), REFERENCE_TARGET,
                                      armed_file.get('known_auras', []), learned).model)
        parts = hit_parts(class_file, test_spell, casts, rank_id=rank_id, label=label, learned=learned)
    except (Unmodelled, ValueError) as error:
        writer.add(key, 'learned_hit', test_spell, rank_id,
                   unmodelled(label, test_spell, getattr(error, 'reason', str(error))))
        return
    for part, (scenario, expectations) in enumerate(parts, start=1):
        writer.add(key if len(parts) == 1 else f'{key}-part-{part}', 'learned_hit', test_spell, rank_id,
                   expectations, scenario)


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
    if shares_proc_spell(class_file, entry):
        key_parts = (aura, entry['proc_spell'], trigger_key(entry))
    elif shares_aura(class_file, entry):
        key_parts = (aura, entry['proc_spell'])
    else:
        key_parts = (aura,)
    key = scenario_key(class_file['name'], 'proc', *key_parts)
    if entry.get('status'):
        writer.add(key, 'proc', None, aura, [proc_status_expectation(entry)], name=name)
        return
    plan_fn = delta_proc_plan if entry.get('kind') == DELTA_CHECK else proc_plan
    scenario_fn = delta_proc_scenario if entry.get('kind') == DELTA_CHECK else proc_scenario
    try:
        plan = plan_fn(class_file, entry)
    except Unmodelled as error:
        writer.add(key, 'proc', None, aura, [proc_unmodelled_expectation(entry, error.reason)], name=name)
        return
    for part in range(plan.parts):
        scenario, expectations = scenario_fn(class_file, entry, part)
        writer.add(scenario_key(class_file['name'], 'proc', *key_parts, 'part', part + 1), 'proc', None, aura,
                   expectations, scenario, name=name)


def add_trigger(writer: ManifestWriter, entry: dict):
    class_file = writer.class_file
    aura, name = entry['aura'], entry['name']
    if entry.get('effect') is not None:
        key_parts = (aura, entry['effect'])
        if entry.get('kind') == COOLDOWN_DELTA_KIND and shares_cooldown_effect(class_file, entry):
            key_parts = (*key_parts, entry['observe_spell'])
    elif entry.get('kind') is None and not entry.get('status') and shares_trigger_aura(class_file, entry):
        key_parts = (aura, entry['trigger'].get('spell', entry['trigger']['action']))
    elif entry.get('kind') == GATE_ABSENCE_KIND:
        key_parts = (aura, 'gate', *([entry['label_suffix']] if entry.get('label_suffix') else []))
    else:
        key_parts = (aura,)
    key = scenario_key(class_file['name'], 'trigger', *key_parts)
    if entry.get('status'):
        writer.add(key, 'trigger', None, aura, [trigger_status_expectation(entry)], name=name)
        return
    scenario_fn = {COOLDOWN_DELTA_KIND: cooldown_trigger_scenario, DURATION_DELTA_KIND: duration_trigger_scenario,
                  MAGNITUDE_RATIO_KIND: magnitude_ratio_scenario, SELF_TRIGGER_KIND: self_trigger_scenario,
                  GATE_ABSENCE_KIND: gate_absence_scenario}.get(entry.get('kind'), trigger_scenario)
    try:
        plan = trigger_plan(class_file, entry)
    except Unmodelled as error:
        writer.add(key, 'trigger', None, aura, [trigger_unmodelled_expectation(entry, error.reason)], name=name)
        return
    for part in range(len(plan.part_attempts)):
        scenario, expectations = scenario_fn(class_file, entry, part)
        writer.add(scenario_key(class_file['name'], 'trigger', *key_parts, 'part', part + 1), 'trigger', None, aura,
                   expectations, scenario, name=name)
    expiry = trigger_expiry(class_file, entry)
    if expiry:
        writer.add(scenario_key(class_file['name'], EXPIRY_KIND, 'trigger', *key_parts), EXPIRY_KIND, None, aura,
                   expiry[1], expiry[0], name=name)


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
             triggers: list[int] | None = None, behaviours: list[int] | None = None,
             target_gates: list[int] | None = None, trials: dict[str, int] | None = None,
             learned_hits: list[int] | None = None, controls: bool = False) -> Path:
    class_file = load_class_file(class_id)
    dbc_dir = server_dbc_dir(class_file.get('dbc_dir', DBC_DIR))
    out = Path(out)
    scenario_dir = out / SCENARIO_DIR
    if scenario_dir.is_dir() and any(scenario_dir.glob('*.json')):
        raise ValueError(f'{scenario_dir} already holds scenarios; generate into a new directory')
    scenario_dir.mkdir(parents=True, exist_ok=True)
    writer = ManifestWriter(class_file, out)
    everything = (spells is None and procs is None and passives is None and triggers is None and behaviours is None
                 and target_gates is None and learned_hits is None and not stack and not controls)
    chosen_procs = proc_entries(class_file, procs) if everything or procs is not None else []
    chosen_triggers = trigger_entries(class_file, triggers) if everything or triggers is not None else []
    chosen_passives = selected_passives(class_file, dbc_dir, passives) if passives is not None else []
    chosen_behaviours = behaviour_entries(class_file, behaviours) if everything or behaviours is not None else []
    if controls:
        chosen_behaviours += control_entries(class_id)
    chosen_target_gates = target_gate_entries(class_file, target_gates) \
        if everything or target_gates is not None else []
    chosen_learned_hits = learned_hit_entries(class_file, learned_hits) \
        if everything or learned_hits is not None else []
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
        add_behaviour(writer, sized_behaviour(entry, trials))
    for entry in chosen_target_gates:
        add_target_gate(writer, entry)
    for entry in chosen_learned_hits:
        add_learned_hit(writer, entry)
    if stack:
        add_stack(writer, passes)
    if everything:
        add_melee(writer)
    manifest = {'schema': 1, 'class_id': class_file['class_id'], 'class_name': class_file['name'],
                'level': class_file['level'], 'dbc_dir': str(dbc_dir),
                'spell_dbc_sha256': spell_dbc_sha256(dbc_dir), 'class_file': class_file,
                'known_modifiers': known_modifiers(class_file), 'scenarios': writer.entries}
    path = out / MANIFEST_FILE
    path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return path


def scaffold_command(args) -> int:
    if args.out.exists():
        raise ValueError(f'{args.out} already exists; scaffold into a new file')
    class_file = scaffold_class(args.class_id, server_dbc_dir(args.dbc_dir), args.config, args.mysql,
                                level=args.level, shared_defines=args.shared_defines,
                                live_baseline=args.live_baseline)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(class_file, indent=2) + '\n')
    print(f'{args.out}: scaffolded class {class_file["class_id"]} ({class_file["name"]})')
    return 0


def generate_command(args) -> int:
    path = generate(args.class_id, args.out, args.spell, args.proc, args.stack, args.passes, args.passive,
                    args.trigger, args.behaviour, args.target_gate, learned_hits=args.learned_hit,
                    controls=args.controls)
    manifest = json.loads(path.read_text(encoding='utf-8'))
    written = sum(1 for entry in manifest['scenarios'] if entry['file'])
    print(f'{path}: {written} scenarios in {path.parent / SCENARIO_DIR}, '
          f'{len(manifest["scenarios"]) - written} entries without a scenario')
    return 0


def compare_command(args) -> int:
    try:
        comparison = evaluate(args.manifest, args.results, build=args.build)
    except ScenarioDrift as error:
        print(f'Scenario drift, no verdict:\n{error}', file=sys.stderr)
        return DRIFT_EXIT
    except BuildMismatch as error:
        print(f'Build mismatch, no verdict: {error}', file=sys.stderr)
        return BUILD_EXIT
    out = args.out or args.manifest.parent
    alerts, report = write_outputs(args.manifest, args.results, comparison.verdicts, out)
    counts = {status: sum(verdict.status == status for verdict in comparison.verdicts) for status in STATUSES}
    print(' '.join(f'{status}={count}' for status, count in counts.items()))
    print(f'{len(comparison.runs)} scenarios with a result, {len(comparison.missing)} without, '
          f'{len(comparison.other_build)} refused as another build; judged {comparison.build.text()}')
    print(f'{alerts}\n{report}\n{out / VERDICTS_FILE}\n{out / QUESTIONS_FILE}')
    if any(verdict.check in STACK_CHECKS for verdict in comparison.verdicts):
        print(write_levers(args.manifest, args.results, comparison.verdicts, out))
    return 0


def sheets_command(args) -> int:
    class_file = load_class_file(args.class_id)
    dbc_dir = server_dbc_dir(class_file.get('dbc_dir', DBC_DIR))
    written = write_sheets(dbc_dir, class_file, args.out, args.spell, args.verdicts)
    print(f'{len(written)} sheets in {args.out}')
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
    if args.clauses:
        from compare import read_verdicts
        header, verdicts = read_verdicts(args.after)
        try:
            result = clause_coverage(load_clauses(args.clauses), verdicts, header.get('build'),
                                     load_consumption(ledger_consumption_path(args.clauses)))
            entries = fragment_entries(result, header) if args.fragment else []
        except (EvidenceError, DbcSetMismatch) as error:
            print(f'No clause coverage: {error}', file=sys.stderr)
            return DIFF_EXIT
        print('\n'.join(clause_coverage_lines(result)))
        if args.fragment:
            print(write_fragment(args.fragment, entries))
    return 0


def mutate_command(args) -> int:
    from mutants import MANIFEST_KEY, load_mutants, mutate
    path = mutate(args.manifest, load_mutants(args.mutants))
    applied = json.loads(path.read_text(encoding='utf-8'))[MANIFEST_KEY]
    for mutant in applied:
        print(f"{mutant['label']}: {mutant['op']} of {mutant['spell']} x{mutant['factor']:g} in "
              f"{len(mutant['scenarios'])} scenarios")
    print(path)
    return 0


def k3_command(args) -> int:
    from k3 import compare_runs, k3_rows, load_probes, merge_consumption
    from mutants import contamination, load_mutants, mutated_scenarios
    baseline, mutant = compare_runs(args.baseline), compare_runs(args.mutant)
    mutants = load_mutants(args.mutants)
    manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
    changed = contamination([verdicts for _, verdicts in baseline], [verdicts for _, verdicts in mutant],
                            mutated_scenarios(manifest))
    rows, outcomes = k3_rows(load_probes(args.probes), mutants, baseline, mutant, str(args.out))
    document = {'build': baseline[0][0].get('build'), 'contaminated': changed, 'probes': outcomes, 'rows': rows}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')
    if args.consumption and rows:
        print(merge_consumption(args.consumption, rows))
    print(f'{len(rows)} K3 rows, {len(changed)} contaminated unmutated verdicts; {args.out}')
    return 0 if not changed else DIFF_EXIT


def mounted_roots(worktree: Path) -> list[Path]:
    common = subprocess.run(['git', '-C', str(worktree), 'rev-parse', '--git-common-dir'], capture_output=True,
                            text=True, check=True).stdout.strip()
    common_dir = Path(common) if Path(common).is_absolute() else Path(worktree) / common
    return [Path(worktree), common_dir.resolve().parent]


def prove_command(args) -> int:
    from prove import SUMMARY_FILE, ProveSpec, is_under, prove
    from pilot import hit_ratio_pilot, sizable_labels
    from prove_ledger import ledger_hooks
    if not (args.behaviour or args.proc or args.trigger):
        raise ValueError('prove needs at least one --behaviour, --proc or --trigger entry of the class file')
    roots = mounted_roots(args.worktree)
    if not is_under(args.out, roots):
        raise ValueError(f'--out {args.out} lies outside {[str(root) for root in roots]}, the directories coa-verify '
                         f'mounts; the scenario files would not be visible to the run')

    def make(out: Path, trials: dict[str, int] | None = None) -> Path:
        return generate(args.class_id, out, procs=args.proc, triggers=args.trigger, behaviours=args.behaviour,
                        trials=trials)

    entries = behaviour_entries(load_class_file(args.class_id), args.behaviour) if args.behaviour else []
    sized = [entry for entry in entries if entry.get('kind') == 'hit_ratio']

    def make_pilot(out: Path, trials: dict[str, int]) -> Path:
        return generate(args.class_id, out, behaviours=sorted({entry['spell'] for entry in sized}), trials=trials)

    out = Path(args.out).resolve()
    spec = ProveSpec(out, args.worktree, args.runs, args.build, args.timeout_ms)
    rows, enrich, annotate = ledger_hooks(args.clauses) if args.clauses else (None, None, None)
    pilot = hit_ratio_pilot(sizable_labels(sized), make_pilot, make)
    code = prove(spec, make, rows, enrich, annotate, pilot=pilot)
    print(f'{out / SUMMARY_FILE}: exit {code}')
    return code


def sample_command(args) -> int:
    try:
        document = sample_document(load_buckets(args.buckets), args.seed, args.total, args.bucket,
                                   parse_minimums(args.minimum), args.first_chunk)
    except SampleError as error:
        print(error, file=sys.stderr)
        return 2
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(document, indent=1) + '\n', encoding='utf-8')
    print(f'{args.out}: {sum(document["drawn_clauses"].values())} clauses in {len(document["draws"])} draws '
          f'(quotas {document["quotas"]}), chunk 1 {document["chunks"]["1"]["clauses"]} clauses, chunk 2 '
          f'{document["chunks"]["2"]["clauses"]}')
    return 0


def packets_command(args) -> int:
    started = time.monotonic()
    class_file = load_class_file(args.class_id)
    try:
        sample = json.loads(args.sample.read_text(encoding='utf-8'))
        class_map = json.loads(args.class_map.read_text(encoding='utf-8')) if args.class_map else None
        written = write_packets(server_dbc_dir(class_file.get('dbc_dir', DBC_DIR)), class_file, sample, args.chunk,
                                load_buckets(args.buckets), args.out, class_map)
    except (PacketError, SampleError) as error:
        print(error, file=sys.stderr)
        return 2
    print(f'{args.out}: {len(written)} packets for chunk {args.chunk} in {time.monotonic() - started:.2f} s')
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description='Generate class conformance scenarios and compare their results.')
    commands = parser.add_subparsers(dest='command', required=True)
    scaffolding = commands.add_parser('scaffold', help='write a minimal classes/<name>.json for a CoA class')
    scaffolding.add_argument('--class', dest='class_id', type=int, required=True)
    scaffolding.add_argument('--out', type=Path, required=True)
    scaffolding.add_argument('--dbc-dir', dest='dbc_dir', type=Path, default=DBC_DIR)
    scaffolding.add_argument('--config', type=Path, required=True, help='worldserver config, for WorldDatabaseInfo')
    scaffolding.add_argument('--mysql', required=True, help='mysql client binary')
    scaffolding.add_argument('--level', type=int, default=CHARACTER_LEVEL)
    scaffolding.add_argument('--shared-defines', dest='shared_defines', type=Path, default=SHARED_DEFINES)
    scaffolding.add_argument('--live-baseline', dest='live_baseline', type=Path, default=LIVE_BASELINE_HEADER)
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
    generating.add_argument('--target-gate', dest='target_gate', type=int, action='append',
                            help='the spell of a target_aura_gates entry of the class file; repeat to select '
                                 'several')
    generating.add_argument('--learned-hit', dest='learned_hit', type=int, action='append',
                            help='the learned spell of a learned_hits entry of the class file; repeat to select '
                                 'several')
    generating.add_argument('--controls', action='store_true',
                            help='the control entries of the class (controls/*.json): stock spells that check the '
                                 'engine, outside the class file and its coverage')
    generating.add_argument('--stack', action='store_true',
                            help='the passes of every stack configuration of the class file, cumulative talents')
    generating.add_argument('--passes', type=int, default=PASSES, help=f'passes per stack configuration ({PASSES})')
    proving = commands.add_parser('prove', help='generate exactly the given class-file entries, run them at least '
                                                'twice through coa-verify, compare each run, report flips and '
                                                'unjudged verdicts and write a ledger fragment')
    proving.add_argument('--class', dest='class_id', type=int, required=True)
    proving.add_argument('--behaviour', type=int, action='append',
                         help='the spell of a behaviour entry of the class file; repeatable')
    proving.add_argument('--proc', type=int, action='append',
                         help='the aura of a proc entry of the class file; repeatable')
    proving.add_argument('--trigger', type=int, action='append',
                         help='the aura of a trigger entry of the class file; repeatable')
    proving.add_argument('--runs', type=int, default=2, help='gameplay runs, at least 2 (2)')
    proving.add_argument('--out', type=Path, required=True,
                         help='a new directory under the worktree or its main checkout')
    proving.add_argument('--worktree', type=Path, required=True, help='the worktree coa-verify runs against')
    proving.add_argument('--build', action='store_true', help='include the build stage in run 1 only')
    proving.add_argument('--timeout-ms', dest='timeout_ms', type=int, default=600000,
                         help='limit of one coa-verify run in milliseconds (600000)')
    proving.add_argument('--clauses', type=Path,
                         help='a clause ledger: the fragment lists its claims whose labels all run here, and the '
                              'summary reports its coverage on each run')
    sheeting = commands.add_parser('sheets', help='write one JSON+text behaviour sheet per spell into --out, '
                                                   'with no class-file entries or verdicts (a blind-reader input)')
    sheeting.add_argument('--class', dest='class_id', type=int, required=True)
    sheeting.add_argument('--out', type=Path, required=True)
    sheeting.add_argument('--spell', type=int, action='append', required=True,
                          help='a spell id to sheet; repeat to select several spells')
    sheeting.add_argument('--verdicts', type=Path,
                          help='a compare output directory (verdicts.json) to attach that spell\'s verdicts')
    comparing = commands.add_parser('compare', help=f'judge a verify_all stamp, write {ALERTS_FILE}, {REPORT_FILE}, '
                                                    f'{VERDICTS_FILE}, {QUESTIONS_FILE} and, for stack runs, '
                                                    f'{LEVERS_FILE}')
    comparing.add_argument('--manifest', type=Path, required=True)
    comparing.add_argument('--results', type=Path, required=True, help='a .cache/verify-all/<STAMP> directory')
    comparing.add_argument('--out', type=Path, help='output directory, the manifest directory by default')
    comparing.add_argument('--build', help='the build being judged: a worldserver sha256 or a server commit; runs of '
                                           'another build are refused, and without it the results must hold one build')
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
    covering.add_argument('--clauses', type=Path,
                          help='a classes/<name>_clauses.json clause ledger; prints proven/total clause coverage '
                               'against --after and lists every unproven clause')
    covering.add_argument('--fragment', type=Path,
                          help='with --clauses, write a new ledger fragment: every claim with its computed '
                               'evidence and the Spell.dbc sha256 of the verdicts')
    mutating = commands.add_parser('mutate', help='add a player-scoped server mutant to every generated scenario '
                                                  'that carries a mutant label, in place')
    mutating.add_argument('--manifest', type=Path, required=True, help='a generated manifest, mutated in place')
    mutating.add_argument('--mutants', type=Path, required=True,
                          help='a JSON array of server mutants {label, spell, op, factor}, factor 2 or 0')
    probing = commands.add_parser('k3', help='judge K3 consumption probes from compare outputs of baseline and '
                                             'mutant runs of one build, and report contamination')
    probing.add_argument('--probes', type=Path, required=True,
                         help='a JSON array of K3 probes {label, spell, effect, observation[, mutant, predicted]}')
    probing.add_argument('--mutants', type=Path, required=True, help='the mutants file the mutant runs used')
    probing.add_argument('--manifest', type=Path, required=True, help='the mutated manifest')
    probing.add_argument('--baseline', type=Path, required=True, help='compare outputs run1, run2, ... unmutated')
    probing.add_argument('--mutant', type=Path, required=True, help='compare outputs run1, run2, ... mutated')
    probing.add_argument('--out', type=Path, required=True, help='the K3 result file to write')
    probing.add_argument('--consumption', type=Path,
                         help='merge the written rows into this consumption file (classes/<class>_consumption.json)')
    sampling = commands.add_parser('sample', help='draw a batch sample of whole spells from a bucket file, in draw '
                                                  'order, and split it into two chunks')
    sampling.add_argument('--buckets', type=Path, required=True,
                          help='a JSON file of clauses {spell, bucket, ...} (or {"clauses": [...]})')
    sampling.add_argument('--seed', required=True, help='spells are ordered by sha256 of "<seed>|<spell id>"')
    sampling.add_argument('--total', type=int, required=True, help='clauses to draw over all buckets')
    sampling.add_argument('--bucket', action='append', required=True,
                          help='a bucket to draw from, in draw and interleaving order; repeatable')
    sampling.add_argument('--minimum', action='append', default=[], help='BUCKET=COUNT, a quota floor; repeatable')
    sampling.add_argument('--first-chunk', dest='first_chunk', type=int, required=True,
                          help='clauses chunk 1 holds at least, taken as whole spells interleaved across buckets')
    sampling.add_argument('--out', type=Path, required=True, help='the sample file to write')
    packeting = commands.add_parser('packets', help='write one Markdown packet per spell of a sample chunk: '
                                                    'tooltip, Spell.dbc effects, script hits, ledger rows, class-file '
                                                    'entries, the nearest entry of each check kind, fixtures and the '
                                                    'class map fields')
    packeting.add_argument('--class', dest='class_id', type=int, required=True)
    packeting.add_argument('--sample', type=Path, required=True, help='the sample file of conformance.py sample')
    packeting.add_argument('--chunk', required=True, help='the chunk of the sample whose spells get a packet')
    packeting.add_argument('--buckets', type=Path, required=True,
                           help='the bucket file the sample was drawn from, with every clause row of the class')
    packeting.add_argument('--class-map', dest='class_map', type=Path,
                           help='a class map JSON ({"classes": {"<class id>": {"spells": [...]}}}), read only')
    packeting.add_argument('--out', type=Path, required=True, help='the directory that receives <spell id>.md')
    args = parser.parse_args(argv)
    handlers = {'scaffold': scaffold_command, 'generate': generate_command, 'sheets': sheets_command,
                'compare': compare_command, 'diff': diff_command, 'coverage': coverage_command,
                'prove': prove_command, 'mutate': mutate_command, 'k3': k3_command, 'sample': sample_command,
                'packets': packets_command}
    return handlers[args.command](args)


if __name__ == '__main__':
    sys.exit(main())
