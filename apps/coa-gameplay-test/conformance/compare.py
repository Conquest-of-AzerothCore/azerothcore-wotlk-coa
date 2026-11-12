from collections import Counter
from dataclasses import asdict, dataclass, field, replace
from fractions import Fraction
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import re
from statistics import fmean, pstdev
import struct
from typing import Callable, Mapping, Protocol

from behaviours import (BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_AGGRO_REDIRECT, BEHAVIOUR_AMOUNT_DELTA,
                        BEHAVIOUR_AURA_GRANT,
                        BEHAVIOUR_CAST_APPLIES_AURA, BEHAVIOUR_CAST_COMBAT,
                        BEHAVIOUR_CAST_CONDITION, BEHAVIOUR_CAST_GATE,
                        BEHAVIOUR_CHARGE_RECHARGE, BEHAVIOUR_CHECKS, BEHAVIOUR_COUNT, BEHAVIOUR_CRIT_GUARANTEE,
                        BEHAVIOUR_CRIT_MAGNITUDE, BEHAVIOUR_DURATION, BEHAVIOUR_DURATION_RATIO,
                        BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_EXCLUSIVITY, BEHAVIOUR_FIXED_COUNT,
                        BEHAVIOUR_GROUP_STACK_CAP, BEHAVIOUR_HEAL_BLOCK, BEHAVIOUR_HIT_RATIO, BEHAVIOUR_IMMUNITY,
                        BEHAVIOUR_INTERNAL_COOLDOWN,
                        BEHAVIOUR_INTERNAL_COOLDOWN_GATE,
                        BEHAVIOUR_METRIC_DELTA, BEHAVIOUR_METRIC_RATIO_DELTA, BEHAVIOUR_MOUNT_GRANT,
                        BEHAVIOUR_OATH_CONSUMPTION,
                        BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, BEHAVIOUR_PARTY_STAT_RATIO, BEHAVIOUR_RATIO,
                        BEHAVIOUR_SINGLE_TARGET, BEHAVIOUR_THREAT_SLOPE, BEHAVIOUR_TRIGGER, BEHAVIOUR_EVENT_DELAY,
                        BEHAVIOUR_PROC_RESET, BEHAVIOUR_TAKEN_HIT, BEHAVIOUR_THREAT_REDIRECT,
                        BEHAVIOUR_DISPEL_COUNT, BEHAVIOUR_TAKEN_OUTCOME, BEHAVIOUR_CRIT_RATE, BEHAVIOUR_AMOUNT_MATCH,
                        BEHAVIOUR_FALL_DAMAGE, BEHAVIOUR_SOURCE_STACK, CONDITION_CONTRAST, DISPEL_TYPE_NAMES,
                        HIT_RATIO_ARMS, LEARNED_CONTRAST, STAT_GAIN_ATTRIBUTION, STAT_GAIN_RETURN,
                        TAKEN_HIT_CONTROL_ARM, TAKEN_HIT_RETURNED_KEYS, engine_amount, stated_ratio,
                        strongest_percent)
from bonus import (Bonus, band_excluded_text, band_status, bonus_band, bonus_detail, bonus_of,
                   bonus_status, bonus_text, delta_of, delta_text,
                   per_event_sample, sized_trials)
from expiry import BEHAVIOUR_EXPIRY, EXPIRY_KIND, combined_status, expiry_readings
from hits import (CLOSED, HEAL, MEAN_HALF_WIDTH, SCHOOL_DAMAGE, UNMODELLED, WEAPON_FLAT_EFFECTS,
                  WEAPON_PERCENT_DAMAGE, Z_99, HitModel, Modifier, Unmodelled, magic_schools, measured_hit_model)
from mitigation import TargetProfile, expected_mitigation
from observations import player_observations
from tooltip_readings import player_tooltip_readings, reading_band, reading_for
from passives import PASSIVE_DELTA, VERSUS_AURA_STATE, cleaned_tooltip, literal_token
from procs import (AMBIGUOUS_TOOLTIP, CAST, CHANCE_KIND, DELTA_CHECK, DELTA_SANITY_FACTOR, PER_TRIGGER, PROC_CHECK,
                   chance_of, wilson_interval)
from profile import (DBC_DIR, EQUIP_FIELDS, armed, caster_stats_from, known_aura_label, probe_aura_label,
                     require_server_sha)
from questions import (DATA_ISSUE, READINGS_QUESTION, SERVER_BEHAVIOUR, TEXT_QUESTION, TOOLTIP_VALUE, asked, cleaned,
                       questions, spell_name, write_questions)
from stack import (ADDS, MEASURED, MELEE_SOURCE, MINIMUM_PASSES, MULTIPLIES, STACK_CHECKS, STACK_DPS, STACK_SOURCE,
                   TALENT_DELTA, levers, mean_interval, ratio_interval)
from tooltip import (CasterStats, Displayed, ForcedPoints, Readout, Records, Tooltip, UnscaledForcedPoints,
                     Unreadable)
from triggers import (COOLDOWN_CHECK, DURATION_CHECK, EVENT_TOLERANCE, GATE_ABSENCE_CHECK, MAGNITUDE_CHECK,
                      PERIODIC, SELF_TRIGGER_CHECK, TRIGGER_CHECK, cooldown_trial_label, duration_trial_label)
from values import (CAST_MARGIN_MS, CAST_WAIT_LABEL, EFFECT_MODIFIER_BASE, EFFECTS, FIXED_DIE_SIDES,
                    GAP_CLOSER_DISTANCE, GAP_CLOSER_MARGIN_YD, GENERIC, UNMEASURABLE, UNREADABLE, Expectation,
                    calc_amount_hooks_label, dataset, effect_modifier_label, mean_samples, roll_range, sample_labels)

NOT_MEASURED = 'not_measured'
STATUSES = ('ok', 'tolerated', 'alert', 'unreadable', 'unmodelled', 'ambiguous_tooltip', 'insufficient_trials',
            'unmeasured', MEASURED, 'closed', NOT_MEASURED)
NOT_ALERTS = frozenset({'ok', MEASURED, 'closed', NOT_MEASURED})
CONFORMANT = frozenset({'ok', 'tolerated', 'closed'})
CAST_DEPENDENT_CHECKS = frozenset({'cooldown_ms', 'aura_amount', 'aura_duration_ms', 'aura_amplitude_ms',
                                   GAP_CLOSER_DISTANCE})
GAMEPLAY_CLOCK_REAL = 'real'
GAMEPLAY_CLOCK_SIMULATED = 'simulated'
NO_CAST_FAILURE = 0
CAST_RESULTS_HEADER = Path(__file__).resolve().parents[3] / 'src/server/shared/SharedDefines.h'
CAST_RESULT_ENUM = re.compile(r'enum SpellCastResult\b[^{]*\{(?P<body>[^}]*)\}')
CAST_RESULT_ENTRY = re.compile(r'^\s*(?P<name>SPELL_\w+)\s*=\s*(?P<code>\d+)', re.MULTILINE)
ABSOLUTE_TOLERANCE = 1.0
RELATIVE_TOLERANCE = 0.005
TOLERATED_RELATIVE = 0.05
FLOAT_EPSILON = 1e-9
MAGNITUDE_RATIO_TOLERANCE = 0.05
MAGNITUDE_RATIO_FLOOR = 0.01
METRIC_DELTA_FLOAT_TOLERANCE = 1e-5
TOKEN_CHECKS = frozenset({'effect_value', 'aura_amount', 'aura_duration_ms', 'max_stacks', 'spell_duration',
                          'effect_radius', 'aura_amplitude_ms'})
ROLLED_CHECKS = frozenset({'effect_value', 'aura_amount'})
ROLL_SPREAD = 'roll_spread'
PERIODIC_TOTAL = 'periodic_total'
HIT_CHECKS = frozenset({'hit_mean', 'melee_mean', PERIODIC_TOTAL})
READ_RULE = 'read '
ORDINAL = re.compile(r'#(\d+)$')
DIVIDED_TOKEN = re.compile(r'\$/(\d+);')
PLAIN_TOKEN = re.compile(r'\$(?:/\d+;)?(?P<spell>\d*)(?P<letter>[sSmM])(?P<digit>[1-3])')
TRUNCATED_READ = 1.0
COST_DIVISOR = re.compile(r'ManaCost divisor (\d+)')
EXPLORATORY = ('gameplay', 'exploratory')
ALERT_COLUMNS = ('scenario', 'spell_id', 'rank_id', 'label', 'check', 'status', 'measured', 'expected', 'low', 'high',
                 'deviation', 'explanation', 'server_commit', 'build', 'runs')
SERVER_REVISION = re.compile(r'\brev\. (?P<commit>[0-9a-f]{7,40}\+?)(?![0-9a-f])')
BINARY_SHA256 = re.compile(r'[0-9a-f]{64}')
COMMIT_PREFIX = re.compile(r'[0-9a-f]{7,40}\+?')
DIRTY = '+'
ALERTS_FILE = 'alerts.tsv'
REPORT_FILE = 'report.md'
LEVERS_FILE = 'levers.md'
VERDICTS_FILE = 'verdicts.json'
VERDICTS_SCHEMA = 1
SPELL_DURATION_SCOPE = ('base duration after the player\'s SPELLMOD_DURATION modifiers, before script hooks: a '
                        'ScriptMgr::OnCalcMaxDuration change is not covered')
EFFECT_VALUE_SCOPE = 'CalcValue before aura scripts (CalcAmount hooks not covered)'
CALC_AMOUNT_HOOKS = 'calc_amount_hooks'
CALC_VALUE_STATUS = 'calc_value_status'
PERCENT_POINT_METRICS = frozenset({'melee_crit_chance', 'melee_crit_chance_refreshed', 'spell_crit_chance',
                                   'melee_hit_chance', 'spell_hit_chance', 'parry_chance', 'dodge_chance',
                                   'spell_done_crit_chance'})
FRACTIONAL_METRICS = PERCENT_POINT_METRICS | {'weapon_damage_min'}
FRACTIONAL_FLOOR = 0.01
DETERMINISTIC_STAT_METRICS = frozenset({'stat', 'stat_exact', 'armor', 'combat_rating', 'melee_hit_chance',
                                        'spell_hit_chance', 'expertise', 'spell_power', 'attack_power',
                                        'ranged_attack_power', 'max_health', 'max_power', 'power', 'run_speed_rate',
                                        'attack_time_ms', 'parry_chance', 'dodge_chance', 'block_chance',
                                        'melee_crit_chance', 'melee_crit_chance_refreshed', 'spell_crit_chance',
                                        'weapon_damage_min', 'resistance', 'mana_regen'})
PERCENT_PATH_METRICS = frozenset({'stat', 'armor', 'max_health', 'max_power', 'resistance'})
PERCENT_PATH_RELATIONS = frozenset({'scale'})
ENGINE_ROUNDING = 'engine_rounding'
PER_LEVEL_ROUNDING = 'per_level_rounding'
PER_LEVEL_UNMODELLED = 'per-level truncation, engine computation not modelled'
PER_LEVEL_TERM_TOLERANCE = 1e-3
CRITICAL_DAMAGE_BASE = 1000
DIRECT_CRIT_DAMAGE_AURA = 163
DURATION_KIND = 'duration_ms'
PASSIVE_METRIC = 'metric'
DATA_ONLY = 'data_only'
EXCLUDED = 'excluded'
EXCLUDING_STATUSES = frozenset({'ok', 'tolerated', 'alert'})
CONTRAST = 'contrast'
PARRY_CHANCE = 'parry_chance'
NO_PARRY_BEFORE = ('parry_chance 0 before the learn: the reference character cannot parry (Player::CanParry false) '
                   'and a parry aura enables parry when applied (AuraEffect::HandleAuraModParryPercent), so the delta '
                   'holds the base parry chance as well as the bonus')
MULTIPLYING_RELATIONS = frozenset({'spell_mod_pct', 'scale', 'ratio', 'composition', 'crit_damage'})
ADDITIVE_RELATIONS = frozenset({'add', 'share'})
TRUNCATED_METRICS = frozenset({'stat'})
CLASS_ENTRIES = {PROC_CHECK: ('procs', 'aura'), TRIGGER_CHECK: ('triggers', 'aura'),
                 COOLDOWN_CHECK: ('triggers', 'aura'), DURATION_CHECK: ('triggers', 'aura'),
                 SELF_TRIGGER_CHECK: ('triggers', 'aura'), GATE_ABSENCE_CHECK: ('triggers', 'aura'),
                 TALENT_DELTA: ('talent_modifiers', 'talent')}
PER_LEVEL_TOKEN = re.compile(r'\$\d*ppl\d')
DESCRIPTION_VARIABLE = re.compile(r'\$<\w+>')
SENTENCE_END = re.compile(r'[.!?](?=\s|$|[$@])|\n')
BLANK = '___'
RELATION_MEANINGS = {MULTIPLIES: 'the bonus multiplies the whole value, after every other modifier',
                     'whole': 'the percent applies to the whole critical hit',
                     'bonus': 'the percent applies only to the extra damage that a critical strike adds on top of a '
                              'normal hit'}
TRIAL_WORDS = {'spell_cast_count': 'casts of {spell}', 'spell_damage_count': '{spell} hits',
               'melee_attack_count': 'auto attacks', 'melee_damage_count': 'auto attacks that hit'}
AURA_REQUIREMENTS = ('EquippedItemClass', 'Stances', 'CasterAuraSpell')
MODIFIER_KINDS = {'spell_damage_done': 'damage', 'spell_healing_done': 'heal'}
QUESTION_SUBJECTS = {'spell_critical_damage': 'a critical hit of {spell}', 'spell_damage_done': 'a hit of {spell}',
                     'spell_healing_done': 'a heal of {spell}'}

HitModelSource = Callable[[dict, Expectation, Mapping[str, float]], HitModel]


class ScenarioDrift(ValueError):
    pass


@dataclass(frozen=True)
class Verdict:
    label: str
    status: str
    measured: float | None
    expected: float | None
    low: float | None
    high: float | None
    explanation: str
    scenario: str = ''
    spell_id: int = 0
    rank_id: int = 0
    check: str = ''
    detail: dict | None = field(default=None, hash=False)
    server_commit: str | None = None
    build: str | None = None
    runs: list[str] | None = field(default=None, hash=False)


@dataclass(frozen=True)
class Run:
    key: str
    status: str
    message: str
    values: dict[str, float]
    steps: list[dict]
    max_step_ms: float | None
    cast_failures: dict[int, list[int]] = field(default_factory=dict)
    clock: str | None = None
    server_commit: str | None = None
    build: str | None = None
    run_id: str | None = None


@dataclass(frozen=True)
class Build:
    server_commit: str | None
    binary_sha256: str | None

    def text(self) -> str:
        return f'commit {self.server_commit or "unknown"}, worldserver sha256 {self.binary_sha256 or "unknown"}'


class BuildMismatch(ValueError):
    pass


class TooltipSource(Protocol):
    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None,
             unscaled: bool = False) -> Readout: ...

    def effect_points(self, spell_id: int, effect: int) -> tuple[int, int]: ...

    def first_effect(self, rank_id: int) -> int | None: ...

    def spell_field(self, spell_id: int, name: str): ...


def literal_values(class_file: dict, rank_id: int, description: str) -> list[Displayed]:
    text = cleaned_tooltip(description)
    tokens = (literal_token(class_file, {rank_id}, effect, text) for effect in EFFECTS)
    return [token for token in tokens if token is not None]


class DbcTooltips:
    def __init__(self, dbc_dir: Path, class_file: dict | None = None):
        self.dbc = dataset(Path(dbc_dir))
        self.records = Records(self.dbc)
        self.class_file = class_file or {}

    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None,
             unscaled: bool = False) -> Readout:
        points = UnscaledForcedPoints if unscaled else ForcedPoints
        records = self.records if forced is None else points(self.dbc, *forced)
        description = records.field('Spell', rank_id, 'Description[enUS]')
        readout = Tooltip(records, rank_id, caster).read(description)
        literal = literal_values(self.class_file, rank_id, description)
        return replace(readout, values=readout.values + literal) if literal else readout

    def effect_points(self, spell_id: int, effect: int) -> tuple[int, int]:
        rewritten = next((entry['base_points'] for entry in self.class_file.get('effect_overrides', [])
                          if (entry['spell'], entry['effect']) == (spell_id, effect) and 'base_points' in entry), None)
        base_points = self.records.field('Spell', spell_id, f'EffectBasePoints[{effect}]')
        return (base_points if rewritten is None else rewritten,
                self.records.field('Spell', spell_id, f'EffectDieSides[{effect}]'))

    def first_effect(self, rank_id: int) -> int | None:
        return next((effect for effect in EFFECTS if self.records.field('Spell', rank_id, f'Effect[{effect}]')), None)

    def spell_field(self, spell_id: int, name: str):
        return self.records.field('Spell', spell_id, name)


@dataclass(frozen=True)
class Tokens:
    readout: Readout | None
    caster: CasterStats | None = None
    error: str = ''


@dataclass(frozen=True)
class Comparison:
    manifest: dict
    runs: dict[str, Run]
    missing: list[str]
    verdicts: list[Verdict]
    build: Build = Build(None, None)
    other_build: dict[str, Build] = field(default_factory=dict)


def number(text, label: str) -> float:
    try:
        return float(text)
    except (TypeError, ValueError):
        raise ValueError(f'{label}: harness value {text!r} is not a number') from None


def measured_values(result: dict) -> dict[str, float]:
    return {step['label']: number(step['actual'], step['label'])
            for step in result.get('steps', []) if 'actual' in step}


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def recorded_scenario_hash(directory: Path) -> str | None:
    summary = directory / 'summary.json'
    if summary.is_file():
        recorded = json.loads(summary.read_text(encoding='utf-8')).get('scenario_sha256')
        if recorded:
            return recorded
    scenario = directory / 'scenario.json'
    return file_sha256(scenario) if scenario.is_file() else None


def recorded_clock(directory: Path) -> str | None:
    summary = directory / 'summary.json'
    if not summary.is_file():
        return None
    try:
        data = json.loads(summary.read_text(encoding='utf-8'))
    except ValueError:
        return None
    return GAMEPLAY_CLOCK_SIMULATED if isinstance(data.get('simulation'), dict) else GAMEPLAY_CLOCK_REAL


def recorded_build(directory: Path) -> str | None:
    summary = directory / 'summary.json'
    if not summary.is_file():
        return None
    try:
        return json.loads(summary.read_text(encoding='utf-8')).get('binary_sha256')
    except ValueError:
        return None


def server_commit(version: str | None) -> str | None:
    found = SERVER_REVISION.search(version or '')
    return found.group('commit') if found else None


def run_build(run: Run) -> Build:
    return Build(run.server_commit, run.build)


def build_matches(build: Build, wanted: str) -> bool:
    if BINARY_SHA256.fullmatch(wanted):
        return build.binary_sha256 == wanted
    commit = build.server_commit or ''
    if not commit or commit.endswith(DIRTY) != wanted.endswith(DIRTY):
        return False
    commit, wanted = commit.rstrip(DIRTY), wanted.rstrip(DIRTY)
    return commit.startswith(wanted) or wanted.startswith(commit)


def judged_build(runs: Mapping[str, Run], wanted: str | None) -> tuple[Build, dict[str, Build]]:
    if wanted is not None and not (BINARY_SHA256.fullmatch(wanted) or COMMIT_PREFIX.fullmatch(wanted)):
        raise BuildMismatch(f'--build {wanted!r} is neither a worldserver sha256 nor a commit hash of 7-40 hex digits '
                            f'(with {DIRTY} for a build of a modified tree)')
    builds = {key: run_build(run) for key, run in runs.items()}
    refused = {key: build for key, build in builds.items() if wanted is not None and not build_matches(build, wanted)}
    kept = {build for key, build in builds.items() if key not in refused}
    if len(kept) > 1:
        listed = '; '.join(sorted(build.text() for build in kept))
        raise BuildMismatch(f'the results hold runs of {len(kept)} builds ({listed}); name the build being judged '
                            f'with --build <worldserver sha256 or commit>')
    if kept:
        return kept.pop(), refused
    if wanted is None:
        return Build(None, None), refused
    return (Build(None, wanted) if BINARY_SHA256.fullmatch(wanted) else Build(wanted, None)), refused


def runs_by_hash(results_dir: Path) -> dict[str, Path]:
    found = {}
    for directory in sorted(results_dir.joinpath(*EXPLORATORY).glob('*/')):
        recorded = recorded_scenario_hash(directory)
        if recorded and (directory / 'result.json').is_file():
            found.setdefault(recorded, directory)
    return found


def load_run(results_dir: Path, entry: dict, by_hash: Mapping[str, Path]) -> Run | None:
    directory = results_dir.joinpath(*EXPLORATORY, entry['key'])
    if not directory.is_dir() and entry['sha256'] in by_hash:
        directory = by_hash[entry['sha256']]
    result_path = directory / 'result.json'
    if not result_path.is_file():
        return None
    found = recorded_scenario_hash(directory)
    if found != entry['sha256']:
        raise ScenarioDrift(f'{entry["key"]}: scenario hash {found} of {directory} does not match the manifest '
                            f'hash {entry["sha256"]}')
    result = json.loads(result_path.read_text(encoding='utf-8'))
    max_step = result.get('max_step_ms')
    return Run(entry['key'], result.get('status', ''), result.get('message') or '', measured_values(result),
               result.get('steps', []), None if max_step is None else number(max_step, 'max_step_ms'),
               cast_failures(result), recorded_clock(directory), server_commit(result.get('server_version')),
               recorded_build(directory), result.get('run_id'))


def cast_failures(result: dict) -> dict[int, list[int]]:
    failures: dict[int, list[int]] = {}
    for failure in result.get('cast_failures', []):
        failures.setdefault(int(number(failure['spell'], 'cast_failures.spell')), []).append(
            int(number(failure['reason'], 'cast_failures.reason')))
    return failures


@lru_cache(maxsize=None)
def cast_result_names(header: Path = CAST_RESULTS_HEADER) -> dict[int, str]:
    if not header.is_file():
        return {}
    enum = CAST_RESULT_ENUM.search(header.read_text(encoding='utf-8'))
    if not enum:
        return {}
    return {int(entry.group('code')): entry.group('name') for entry in CAST_RESULT_ENTRY.finditer(enum.group('body'))}


def failure_reasons(run: Run, rank_id: int) -> list[int]:
    return [reason for reason in run.cast_failures.get(rank_id, []) if reason != NO_CAST_FAILURE]


def cast_result_name(reason: int) -> str:
    return f'{cast_result_names().get(reason, "SpellCastResult")} ({reason})'


def failed_cast(run: Run, rank_id: int) -> str | None:
    reasons = failure_reasons(run, rank_id)
    step = int(run.values.get(f'{rank_id} cast_failure', NO_CAST_FAILURE))
    if step != NO_CAST_FAILURE:
        reasons.append(step)
    return ', '.join(cast_result_name(reason) for reason in dict.fromkeys(reasons)) or None


def describe_failures(reasons: list[int]) -> str:
    return ', '.join(f'{count} x {cast_result_name(reason)}' for reason, count in Counter(reasons).items())


def load_runs(manifest: dict, results_dir: Path) -> tuple[dict[str, Run], list[str]]:
    runs, missing, drift = {}, [], []
    by_hash = runs_by_hash(results_dir)
    for entry in manifest['scenarios']:
        if not entry.get('file'):
            continue
        try:
            run = load_run(results_dir, entry, by_hash)
        except ScenarioDrift as error:
            drift.append(str(error))
            continue
        if run is None:
            missing.append(entry['key'])
        else:
            runs[entry['key']] = run
    if drift:
        raise ScenarioDrift('\n'.join(drift))
    return runs, missing


def read_tokens(class_file: dict, entry: dict, run: Run, tooltips: TooltipSource) -> Tokens:
    class_file = armed(class_file, {name: tooltips.spell_field(entry['rank_id'], name) for name in EQUIP_FIELDS})
    try:
        caster = caster_stats_from(run.values, class_file, frozenset(entry.get('known_spells', ())))
    except KeyError as error:
        return Tokens(None, error=f'base measurement {error} is missing from {run.key}')
    readout = tooltips.read(entry['rank_id'], caster)
    texts = [value.text for value in readout.values]
    if texts != entry['tokens']:
        return Tokens(None, error=f'tooltip tokens read with the measured stats {texts} differ from the generated '
                                  f'tokens {entry["tokens"]}')
    return Tokens(readout, caster)


def margin_of(expected: float) -> float:
    return max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * abs(expected))


def banded_status(value: float, low: float, high: float, expected: float) -> str:
    if low - FLOAT_EPSILON <= value <= high + FLOAT_EPSILON:
        return 'ok'
    tolerated_margin = TOLERATED_RELATIVE * abs(expected)
    if expected - tolerated_margin - FLOAT_EPSILON <= value <= expected + tolerated_margin + FLOAT_EPSILON:
        return 'tolerated'
    return 'alert'


def deterministic(base: Verdict, measured: float, judged: float, expected: float, why: str) -> Verdict:
    margin = margin_of(expected)
    low, high = expected - margin, expected + margin
    status = banded_status(judged, low, high, expected)
    explanation = (f'{why}; |measured - expected| <= max({ABSOLUTE_TOLERANCE:g}, '
                   f'{RELATIVE_TOLERANCE:.1%} of expected)')
    if status == 'tolerated':
        explanation += (f'; outside that band but within {TOLERATED_RELATIVE:.0%} of expected, deviation '
                        f'{(judged - expected) / expected if expected else judged - expected:+.1%}: tolerated')
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   explanation=explanation)


def behaviour_fall_damage_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    lost = {}
    for arm, (before, after) in model['arms'].items():
        missing = next((label for label in (before, after) if run.values.get(label) is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        lost[arm] = float(run.values[before]) - float(run.values[after])
    without, with_aura = lost['without'], lost['with']
    status = 'ok' if without > 0 and 0 <= with_aura < without else 'alert'
    return replace(base, status=status, measured=with_aura, expected=without, low=0.0, high=without,
                   explanation=f'a harness-simulated landing from {model["height"]:g} yd took {without:g} health '
                               f'without the aura and {with_aura:g} with it; the loss with the aura must be at least '
                               f'0 and below the loss without it, and the loss without it above 0')


def exact(base: Verdict, measured: float, expected: float, why: str) -> Verdict:
    status = 'ok' if abs(measured - expected) <= FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=f'{why}; a count is compared exactly')


def judge_gap_closer_distance(base: Verdict, measured: float, expected: float, rule: str) -> Verdict:
    high = expected + GAP_CLOSER_MARGIN_YD
    status = 'ok' if measured <= high else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=0.0, high=high,
                   explanation=f'{rule}; measured <= NOMINAL_MELEE_RANGE + {GAP_CLOSER_MARGIN_YD:g} yd margin')


def elapsed_bound(run: Run, label: str) -> float | None:
    position = next((index for index, step in enumerate(run.steps) if step.get('label') == label), None)
    if position is None or run.max_step_ms is None:
        return None
    cast = max((index for index in range(position) if run.steps[index].get('action') == 'cast'), default=position)
    return sum(CAST_MARGIN_MS + run.max_step_ms if step.get('label') == CAST_WAIT_LABEL
               else number(step.get('elapsed_ms', 0), 'elapsed_ms') + run.max_step_ms
               for step in run.steps[cast + 1:position + 1])


def judge_time(base: Verdict, run: Run, measured: float, expected: float, why: str) -> Verdict:
    window = elapsed_bound(run, base.label)
    if window is None:
        return replace(base, measured=measured, expected=expected,
                       explanation=f'{why}; no step timing in {run.key} bounds the time elapsed since the cast')
    low = expected - window
    status = 'ok' if low - FLOAT_EPSILON <= measured <= expected + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=expected,
                   explanation=f'{why}; expected - W <= measured <= expected, W = {window:g} ms elapsed since the '
                               f'cast step (step elapsed_ms plus max_step_ms {run.max_step_ms:g} per step)')


def token_divisor(text: str) -> int:
    divided = DIVIDED_TOKEN.match(text)
    return int(divided.group(1)) if divided else 1


def plain_sign(points: int) -> int:
    return -1 if points < 0 else 1


def displayed_points(tooltips: TooltipSource, plain: re.Match, spell_id: int) -> int:
    effect = int(plain.group('digit')) - 1
    base_points, die_sides = tooltips.effect_points(int(plain.group('spell') or spell_id), effect)
    return base_points + (die_sides if plain.group('letter') == 'M' else 1)


def token_effect(expectation: Expectation) -> tuple[int, int] | None:
    model = expectation.model or {}
    if 'effect' in model:
        return model['effect_spell'], model['effect']
    if expectation.effect_index is not None:
        return expectation.rank_id, expectation.effect_index
    return None


def judge_roll(base: Verdict, expectation: Expectation, run: Run, measured: float, tokens: Tokens,
               tooltips: TooltipSource, index: int, rolls: range) -> Verdict:
    token = tokens.readout.values[index]
    plain = PLAIN_TOKEN.fullmatch(token.text)
    spell_id, effect = token_effect(expectation)
    values = []
    for roll in rolls:
        readout = tooltips.read(expectation.rank_id, tokens.caster, (spell_id, effect, roll))
        if index >= len(readout.values) or readout.values[index].text != token.text:
            return replace(base, status='unmodelled', measured=measured,
                           explanation=f'{token.text} is unreadable with roll {roll} of effect {effect}')
        value = undivided(readout.values[index])
        values.append(value * plain_sign(roll) if plain else value)
    steps = [after - before for before, after in zip(values, values[1:])]
    if not (all(step >= -FLOAT_EPSILON for step in steps) or all(step <= FLOAT_EPSILON for step in steps)):
        return replace(base, status='unmodelled', measured=measured,
                       explanation=f'{token.text} is not monotone in the roll {rolls.start}..{rolls.stop - 1} of '
                                   f'effect {effect}')
    labels = sample_labels(base.label, (expectation.model or {}).get('samples', 1))
    reads = [run.values[label] for label in labels if label in run.values]
    mean, expected, sigma = fmean(reads), fmean(values), pstdev(values)
    needed = mean_samples(values)
    roll = (f'{token.text} over the roll {rolls.start}..{rolls.stop - 1} of effect {effect}: {min(values):g} to '
            f'{max(values):g}, uniform mean {expected:.3f} sigma {sigma:.3f}; {len(reads)} spell_effect_value reads '
            f'(each one SpellEffectInfo::CalcValue roll), mean {mean:.3f}')
    detail = {'reads': len(reads), 'reads_needed': needed}
    if needed is None:
        return replace(base, status=MEASURED, measured=mean, expected=expected, detail=detail,
                       explanation=f'{roll}; a mean of 0 has no half-width of {MEAN_HALF_WIDTH:.0%}')
    if len(reads) < needed:
        return replace(base, status=MEASURED, measured=mean, expected=expected, detail=detail,
                       explanation=f'{roll}; a half-width of {MEAN_HALF_WIDTH:.0%} of the mean at 99% needs '
                                   f'{needed} reads, more than the scenario holds')
    half = Z_99 * sigma / math.sqrt(len(reads))
    low = expected - half - (TRUNCATED_READ if expected > 0 else 0)
    high = expected + half + (TRUNCATED_READ if expected < 0 else 0)
    per_level = per_level_loss(tooltips, spell_id, effect, tokens.caster.level)
    unmodelled = (per_level_model_gap(base.label, run, tooltips, expectation, tokens, index, rolls.start, per_level)
                  if per_level and per_level.loss else None)
    engine = [value - per_level.loss for value in values] if per_level and per_level.loss and not unmodelled else None
    rounded, outside = truncation_reads(values, reads)
    lowered = {read: value for read, value in zip(map(engine_truncation, engine), engine)} if engine else {}
    if engine and set(lowered) == {engine_truncation(value) for value in values}:
        engine, lowered = None, {}
    if (outside or rounded) and engine and all(read in lowered for read in reads):
        engine_reads = [engine_truncation(value) for value in engine]
        engine_mean = fmean(engine_reads)
        engine_low, engine_high = engine_mean - half, engine_mean + half
        detail = {**detail, PER_LEVEL_ROUNDING: {
            'per_level': per_level.term, 'truncated_to': per_level.truncated, 'loss': per_level.loss,
            'engine_range': [min(engine_reads), max(engine_reads)], 'engine_mean': engine_mean}}
        status = banded_status(mean, engine_low, engine_high, engine_mean)
        return replace(base, status=status, measured=mean, expected=engine_mean, low=engine_low, high=engine_high,
                       detail=detail,
                       explanation=f'{roll}; known engine rounding, per-level term truncated before the sum '
                                   f'(SpellInfo.cpp:497): {per_level.levels} levels x {per_level.rate:g} = '
                                   f'{per_level.term:g} becomes {per_level.truncated:g}, then int32 truncation '
                                   f'(SpellInfo.cpp:592): the engine reads {min(engine_reads):g} to '
                                   f'{max(engine_reads):g}, mean {engine_mean:.3f}; every read is one of them; 99% '
                                   f'interval of the mean around the engine mean +- {half:.3f}')
    if outside:
        cause = (f'; per-level term {per_level.term:g} truncated to {per_level.truncated:g} (SpellInfo.cpp:497) '
                 f'reproduces reads {sorted(lowered)} but not {[read for read in reads if read not in lowered]}'
                 if engine else '')
        if unmodelled:
            cause = f'; {PER_LEVEL_UNMODELLED}: {unmodelled}'
            detail = {**detail, PER_LEVEL_ROUNDING: PER_LEVEL_UNMODELLED}
        return replace(base, status='alert', measured=mean, expected=expected, low=low, high=high, detail=detail,
                       explanation=f'{roll}; reads {outside} lie outside the formula range {min(values):g} to '
                                   f'{max(values):g} and are not its int32 truncation at SpellEffectInfo::CalcValue '
                                   f'(at most {TRUNCATED_READ:g} toward zero, reproduced from a formula value){cause}: '
                                   f'a deviation')
    if rounded:
        detail = {**detail, ENGINE_ROUNDING: sorted(set(rounded.values()))}
    status = banded_status(mean, low, high, expected)
    tolerated_note = '; outside the 99% interval but within 5% of expected: tolerated' if status == 'tolerated' else ''
    rounding_note = ('; known engine rounding, int32 truncation: ' + ', '.join(
        f'{value:g} truncates to {read:g}' for read, value in sorted(rounded.items()))
        + ' at SpellEffectInfo::CalcValue (SpellInfo.cpp:592)') if rounded else ''
    return replace(base, status=status, measured=mean, expected=expected, low=low, high=high, detail=detail,
                   explanation=f'{roll}; 99% interval of the mean, expected mean +- Z x sigma / sqrt(reads) '
                               f'{half:.3f}, widened by {TRUNCATED_READ:g} toward zero for the int32 truncation of '
                               f'CalcValue{rounding_note}{tolerated_note}')


@dataclass(frozen=True)
class PerLevelLoss:
    levels: int
    rate: float
    term: float
    truncated: float
    loss: float


def per_level_loss(tooltips: TooltipSource, spell_id: int, effect: int, caster_level: int) -> PerLevelLoss | None:
    try:
        rate = float32(float(tooltips.spell_field(spell_id, f'EffectRealPointsPerLevel[{effect}]') or 0))
        if not rate:
            return None
        base_level, spell_level, max_level = (int(tooltips.spell_field(spell_id, name) or 0)
                                              for name in ('BaseLevel', 'SpellLevel', 'MaxLevel'))
    except Unreadable:
        return None
    level = caster_level
    if max_level > 0 and level > max_level:
        level = max_level
    elif level < base_level:
        level = base_level
    levels = level - max(base_level, spell_level)
    term = float32(levels * rate)
    truncated = float(math.trunc(term))
    return PerLevelLoss(levels, rate, term, truncated, term - truncated)


def per_level_model_gap(label: str, run: Run, tooltips: TooltipSource, expectation: Expectation, tokens: Tokens,
                        index: int, roll: int, per_level: PerLevelLoss) -> str | None:
    spell_id, effect = token_effect(expectation)
    modifiers = [run.values.get(effect_modifier_label(label, op)) for op in ('all', effect)]
    if None in modifiers:
        return 'the run reads no effect modifier of this effect'
    if any(abs(value - EFFECT_MODIFIER_BASE) > FLOAT_EPSILON for value in modifiers):
        return (f'an effect modifier changes {EFFECT_MODIFIER_BASE:g} to {modifiers[0]:g} (all effects) and '
                f'{modifiers[1]:g} (effect {effect}), which the engine model does not apply')
    forced = (spell_id, effect, roll)
    scaled = tooltips.read(expectation.rank_id, tokens.caster, forced).values
    unscaled = tooltips.read(expectation.rank_id, tokens.caster, forced, unscaled=True).values
    if index >= len(scaled) or index >= len(unscaled):
        return 'the tooltip term cannot be read without its per-level part'
    continuous = undivided(scaled[index]) - undivided(unscaled[index])
    if abs(continuous - per_level.term) > PER_LEVEL_TERM_TOLERANCE:
        return (f'the tooltip adds {continuous:g} per level where stock CalcValue adds {per_level.term:g} '
                f'({per_level.levels} levels after its level clamp)')
    return None


def hit_spell_of(expectation: Expectation) -> int:
    return (expectation.model or {}).get('hit_spell') or expectation.rank_id


FIXED_READ_TOLERANCE = 1e-4


def truncations_of(value: float) -> set[float]:
    away = math.copysign(FIXED_READ_TOLERANCE * max(1.0, abs(value)), value)
    return {engine_truncation(value), engine_truncation(value + away)}


def judge_fixed_per_level(base: Verdict, expectation: Expectation, run: Run, measured: float, tokens: Tokens,
                          tooltips: TooltipSource, index: int, expected: float, why: str) -> Verdict | None:
    found = token_effect(expectation)
    if expectation.check != 'effect_value' or found is None:
        return None
    spell_id, effect = found
    per_level = per_level_loss(tooltips, spell_id, effect, tokens.caster.level)
    if not per_level or not per_level.loss:
        return None
    base_points, _ = tooltips.effect_points(spell_id, effect)
    gap = per_level_model_gap(base.label, run, tooltips, expectation, tokens, index, base_points + 1, per_level)
    final = truncations_of(expected)
    engine = None if gap else expected - per_level.loss
    lowered = truncations_of(engine) if engine is not None else set()
    term = (f'per-level term {per_level.levels} levels x {per_level.rate:g} = {per_level.term:g}, truncated to '
            f'{per_level.truncated:g} before the sum (SpellInfo.cpp:497)')
    if measured in final:
        detail = {ENGINE_ROUNDING: [expected]} if measured != expected else None
        return replace(base, status='ok', measured=measured, expected=expected, low=min(final), high=max(final),
                       detail=detail,
                       explanation=f'{why}; the int32 truncation at SpellEffectInfo::CalcValue (SpellInfo.cpp:592) of '
                                   f'{expected:g} gives {measured:g}; no flat band applies to an effect with a {term}')
    if measured in lowered:
        return replace(base, status='ok', measured=measured, expected=engine, low=min(lowered), high=max(lowered),
                       detail={PER_LEVEL_ROUNDING: {'per_level': per_level.term, 'truncated_to': per_level.truncated,
                                                    'loss': per_level.loss, 'engine_value': engine}},
                       explanation=f'{why}; known engine rounding, {term}: the engine computes {engine:g}, read '
                                   f'{measured:g} after its int32 truncation (SpellInfo.cpp:592)')
    reason = f'; {PER_LEVEL_UNMODELLED}: {gap}' if gap else ''
    return replace(base, status='alert', measured=measured, expected=expected, low=min(final), high=max(final),
                   detail={PER_LEVEL_ROUNDING: PER_LEVEL_UNMODELLED} if gap else None,
                   explanation=f'{why}; read {measured:g}, where the int32 truncation of {expected:g} gives '
                               f'{sorted(final)} and the engine computation with the {term} gives '
                               f'{sorted(lowered) if lowered else "no modelled value"}{reason}: a deviation')


def per_level_unmodelled(verdict: Verdict, tooltips: TooltipSource, rank_id: int, caster_level: int) -> Verdict:
    if verdict.status != 'alert' or PER_LEVEL_ROUNDING in (verdict.detail or {}):
        return verdict
    losses = {effect: found for effect in EFFECTS
              if (found := per_level_loss(tooltips, rank_id, effect, caster_level)) and found.loss}
    if not losses:
        return verdict
    terms = ', '.join(f'effect {effect} {found.term:g} to {found.truncated:g}' for effect, found in losses.items())
    return replace(verdict, detail={**(verdict.detail or {}), PER_LEVEL_ROUNDING: PER_LEVEL_UNMODELLED},
                   explanation=f'{verdict.explanation}; {PER_LEVEL_UNMODELLED} ({terms}, SpellInfo.cpp:497)')


def engine_truncation(value: float) -> float:
    return float(math.trunc(float32(value)))


def truncation_reads(values: list[float], reads: list[float]) -> tuple[dict[float, float], list[float]]:
    low, high = min(values), max(values)
    truncations = {engine_truncation(value): value for value in values}
    toward_low = fmean(values) > 0
    rounded, outside = {}, []
    for read in reads:
        if low - FLOAT_EPSILON <= read <= high + FLOAT_EPSILON:
            continue
        gap = low - read if toward_low else read - high
        if gap <= TRUNCATED_READ + FLOAT_EPSILON and read in truncations:
            rounded[read] = truncations[read]
        else:
            outside.append(read)
    return rounded, outside


def token_drift(expectation: Expectation, tokens: Tokens | None) -> str | None:
    if tokens is None:
        return f'no tooltip reading for {expectation.label!r}'
    if tokens.error:
        return tokens.error
    ordinal = ORDINAL.search(expectation.label)
    values = tokens.readout.values
    if not ordinal or int(ordinal.group(1)) >= len(values):
        return f'no tooltip token for {expectation.label!r}'
    index = int(ordinal.group(1))
    if values[index].text != expectation.displayed:
        return f'token #{index} reads {values[index].text!r}, generated as {expectation.displayed!r}'
    return None


def judge_token(base: Verdict, expectation: Expectation, run: Run, measured: float, tokens: Tokens,
                tooltips: TooltipSource, name: str) -> Verdict:
    index = int(ORDINAL.search(expectation.label).group(1))
    token = tokens.readout.values[index]
    if expectation.check == 'aura_duration_ms':
        return judge_time(base, run, measured, token.value, f'{token.text} read with the measured stats')
    if expectation.check == 'max_stacks':
        return exact(base, measured, token.value, f'{token.text} read from StackAmount')
    if expectation.check == 'effect_radius':
        return deterministic(base, measured, measured, token.value,
                             f'{token.text} read from SpellRadius.RadiusMin')
    if expectation.check == 'aura_amplitude_ms':
        return deterministic(base, measured, measured, token.value, f'{token.text} read with the measured stats')
    if expectation.check == 'spell_duration':
        verdict = deterministic(base, measured, measured, token.value,
                                f'{token.text} read from SpellDuration against the {SPELL_DURATION_SCOPE}')
        return replace(verdict, detail={**(verdict.detail or {}), 'scope': SPELL_DURATION_SCOPE})
    effect = token_effect(expectation)
    if effect is not None:
        base_points, die_sides = tooltips.effect_points(*effect)
        if die_sides not in FIXED_DIE_SIDES:
            return judge_roll(base, expectation, run, measured, tokens, tooltips, index,
                              roll_range(base_points, die_sides))
    expected = undivided(token)
    plain = PLAIN_TOKEN.fullmatch(token.text)
    if plain:
        points = displayed_points(tooltips, plain, token.spell_id or expectation.rank_id)
        why = (f'{token.text} is shown unsigned; the expected value takes the sign of its Spell.dbc points '
               f'{points}')
        signed = expected * plain_sign(points)
        return (judge_fixed_per_level(base, expectation, run, measured, tokens, tooltips, index, signed, why)
                or deterministic(base, measured, measured, signed, why))
    if measured * expected < 0:
        return replace(base, status='ambiguous_tooltip', measured=measured, expected=expected,
                       explanation=f'{token.text} evaluates to {expected:g}, the measured value has the opposite sign',
                       detail={'question': sign_question(base, name, token.text, measured, expected)})
    why = f'{token.text} read with the measured stats'
    return (judge_fixed_per_level(base, expectation, run, measured, tokens, tooltips, index, expected, why)
            or deterministic(base, measured, measured, expected, why))


def sign_question(base: Verdict, name: str, text: str, measured: float, expected: float) -> dict:
    opposite = deterministic(base, measured, measured, -expected, '').status
    question = (f'The {name} tooltip shows {text} as {expected:g}, but our test server applies {measured:g}, the '
                f'opposite sign. Find a hit or heal of {name} with a known base value in the reference logs and '
                f'see whether the logged amount adds to or subtracts from it.')
    readings = [{'name': 'the sign the tooltip shows', 'expected': expected, 'measured': measured, 'status': 'alert'},
                {'name': 'the opposite sign', 'expected': -expected, 'measured': measured, 'status': opposite}]
    return question_detail(READINGS_QUESTION, question, readings, measured)


def describe_modifiers(modifiers: tuple[Modifier, ...]) -> str:
    return ', '.join(f'{modifier.spell_id} effect {modifier.effect_index} aura {modifier.aura} '
                     f'{modifier.percent:+d}%' for modifier in modifiers) or 'none'


ProcPart = tuple[dict, Run, Expectation]


def judge_hit(base: Verdict, class_file: dict, parts: list[ProcPart], hit_model: HitModelSource) -> Verdict:
    expectation = parts[0][2]
    model = expectation.model or {}
    labels = model.get('measurements', {})
    total, count, reasons, judged, missing = 0.0, 0.0, [], [], []
    for _, run, part in parts:
        reasons += failure_reasons(run, expectation.rank_id)
        part_total, part_count = run.values.get(labels.get('total')), run.values.get(labels.get('count'))
        if part_total is None or part_count is None:
            missing.append(f'{run.key} ({run.status}: {run.message})')
            continue
        total += part_total
        count += part_count
        judged.append((run, part, part_count))
    if not judged:
        return replace(base, explanation=f'no hit measurements {labels} in {", ".join(missing)}')
    mean = total / count if count > 0 else None
    minimum = model['minimum_hits']
    failures = f'; failed casts: {describe_failures(reasons)}' if reasons else ''
    notes = f'; {len(judged)} of {model["parts"]} parts' if model.get('parts', 1) > 1 else ''
    if missing:
        notes += f'; no hit measurements in {", ".join(missing)}'
    if count <= 0 and reasons:
        return replace(base, status='unmeasured', measured=mean, explanation=f'no usable hit{notes}{failures}')
    if count < minimum:
        return replace(base, status='insufficient_trials', measured=mean,
                       explanation=f'{count:g} usable hits, fewer than the {minimum} the mean needs{notes}{failures}')
    control = model.get('control_label')
    if control is not None:
        controls = [run.values.get(control) for run, _, _ in judged]
        if None in controls:
            return replace(base, measured=mean, explanation=f'measurement {control!r} is missing')
        if sum(controls) > 0:
            return replace(base, status='alert', measured=mean,
                           explanation=f'the control arm counts {sum(controls):g} hits of {model.get("hit_spell")} '
                                       f'{model.get("control_text", "without the spell known")}; the hits are not '
                                       f'told apart from it{notes}')
        notes += f'; control arm {model.get("control_text", "without the spell known")}: 0 hits ({control})'
    models = []
    for run, part, part_count in judged:
        try:
            expected = hit_model(class_file, part, run.values)
        except Unmodelled as error:
            return replace(base, status='unmodelled', measured=mean, explanation=UNMODELLED + error.reason)
        except KeyError as error:
            return replace(base, measured=mean, explanation=f'measurement {error} is missing from {run.key}')
        shown = ' | '.join(expected.displayed)
        if shown != expectation.displayed:
            return replace(base, measured=mean, expected=expected.mean,
                           explanation=f'hit tokens with the measured stats {shown!r} differ from the generated '
                                       f'{expectation.displayed!r}')
        models.append((expected, part_count))
    expected_mean = sum(part_count * expected.mean for expected, part_count in models) / count
    variance = sum(part_count * expected.sigma ** 2 for expected, part_count in models) / count
    half = Z_99 * math.sqrt(variance / count)
    low, high = expected_mean - half, expected_mean + half
    status = banded_status(mean, low, high, expected_mean)
    detail = None
    if status != 'ok' and all(expected.engine is not None for expected, _ in models):
        engine_mean = sum(part_count * expected.engine.mean for expected, part_count in models) / count
        engine_variance = sum(part_count * expected.engine.sigma ** 2 for expected, part_count in models) / count
        engine_half = Z_99 * math.sqrt(engine_variance / count)
        engine_status = banded_status(mean, engine_mean - engine_half, engine_mean + engine_half, engine_mean)
        rule = models[0][0].engine_rule
        detail = {PER_LEVEL_ROUNDING: {'tooltip_mean': expected_mean, 'engine_mean': engine_mean,
                                       'engine_low': engine_mean - engine_half,
                                       'engine_high': engine_mean + engine_half, 'rule': rule}}
        if engine_status == 'ok':
            return replace(base, status='ok', measured=mean, expected=engine_mean, low=engine_mean - engine_half,
                           high=engine_mean + engine_half, detail=detail,
                           explanation=f'{count:g} usable hits; outside the tooltip model mean {expected_mean:.3f} '
                                       f'[{low:.3f}, {high:.3f}], inside the engine model mean {engine_mean:.3f} '
                                       f'sigma {math.sqrt(engine_variance):.3f}, 99% interval of the mean: {rule}'
                                       f'{notes}{failures}')
        notes += (f'; the engine model mean {engine_mean:.3f} [{engine_mean - engine_half:.3f}, '
                  f'{engine_mean + engine_half:.3f}] does not explain it either ({rule})')
    first = models[0][0]
    modifiers = ' or '.join(dict.fromkeys(describe_modifiers(expected.modifiers) for expected, _ in models))
    kind_term = 'mean'
    if expectation.check == PERIODIC_TOTAL:
        ticks = model['hits_per_cast']
        mean, expected_mean, half = mean * ticks, expected_mean * ticks, half * ticks
        low, high = expected_mean - half, expected_mean + half
        kind_term = f'total over {ticks} ticks'
    return replace(base, status=status, measured=mean, expected=expected_mean, low=low, high=high, detail=detail,
                   explanation=f'{count:g} usable hits; {first.kind} model {kind_term} {expected_mean:.3f} sigma '
                               f'{math.sqrt(variance):.3f} from the measured stats and target, 99% interval of the '
                               f'mean; tooltip mean {first.tooltip_mean:.2f} (display only); modifiers '
                               f'{modifiers}{notes}{failures}')


RateJudgement = tuple[str, float | None, float | None, str]


def rate_judgement(procs: float, trials: float, minimum: int, expected: float) -> RateJudgement:
    if procs < 0:
        return 'alert', None, None, 'fewer events than the trigger casts they exclude'
    if trials <= 0:
        return 'unmeasured', None, None, 'no trial'
    if procs > trials:
        return 'alert', None, None, 'more procs than trials'
    if trials < minimum:
        return 'insufficient_trials', None, None, f'fewer than the {minimum} trials the rate needs'
    low, high = wilson_interval(procs, trials)
    status = 'ok' if low - FLOAT_EPSILON <= expected <= high + FLOAT_EPSILON else 'alert'
    return status, low, high, f'rate {procs / trials:.4f}, Wilson 99% interval [{low:.4f}, {high:.4f}]'


def proc_readings(model: dict) -> list[dict]:
    return model.get('readings') or [{'name': 'triggering hits only', 'labels': [model['measurements']['trials']]}]


def player_casts(model: dict, run: Run, trigger: int) -> float:
    return model['part_attempts'] - len(failure_reasons(run, trigger)) if model.get('exclude_trigger_casts') else 0.0


def refund_offset(model: dict, run: Run) -> float:
    pool = model.get('charge_pool')
    if not pool:
        return 0.0
    return run.values[model['measurements']['attempts']] - run.values[pool] * model['part_attempts']


def event_text(model: dict, event_labels: list[str], trigger: int) -> str:
    if model.get('charge_pool'):
        return (f'charges of {model["proc_spell"]} left after each cast from a restored pool, plus the completed '
                f'casts, less the pool times the casts')
    minus = f' minus the completed player casts of {trigger}' if model.get('exclude_trigger_casts') else ''
    return f'{" + ".join(event_labels)}{minus}'


def trigger_trials(run: Run, model: dict) -> list[tuple[float, float]] | None:
    readings = []
    for boundary in model['trigger_boundaries']:
        values = [run.values.get(label) for label in [boundary['hits']] + boundary['events']]
        if None in values:
            return None
        readings.append((values[0], sum(values[1:])))
    return [(after[0] - before[0], (after[1] - before[1]) / model['events_per_proc'])
            for before, after in zip(readings, readings[1:])]


def stated_chance(manifest: dict, run: Run, expectation: Expectation, tooltips: TooltipSource, base: Verdict,
                  measured: float | None) -> float | Verdict:
    try:
        caster = caster_stats_from(run.values, manifest['class_file'])
    except KeyError as error:
        return replace(base, measured=measured, explanation=f'base measurement {error} is missing from {run.key}')
    shown = expectation.model.get('chance_spell', expectation.rank_id)
    chance = chance_of(tooltips.read(shown, caster).values, expectation.displayed,
                       expectation.model.get('chance_kind', CHANCE_KIND))
    if chance is None:
        return replace(base, measured=measured, explanation=f'the tooltip of {shown} no longer shows '
                                                            f'the chance token {expectation.displayed}')
    if abs(chance - expectation.model['chance_pct']) > FLOAT_EPSILON:
        return replace(base, measured=measured, expected=chance / 100,
                       explanation=f'{expectation.displayed} shows {chance:g}%, generated as '
                                   f'{expectation.model["chance_pct"]:g}%')
    return chance


def judge_proc_per_trigger(manifest: dict, parts: list[ProcPart], tooltips: TooltipSource, base: Verdict) -> Verdict:
    _, first_run, expectation = parts[0]
    model = expectation.model
    limit = model[PER_TRIGGER]
    single, other_triggers, without_aura, unmeasured = [], 0, [], []
    for _, run, _ in parts:
        aura = run.values.get(model['measurements']['aura'])
        trials = trigger_trials(run, model)
        if aura is None or trials is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
        elif aura <= 0:
            without_aura.append(run.key)
        else:
            single += [procs for hits, procs in trials if hits == 1]
            other_triggers += sum(1 for hits, _ in trials if hits != 1)
    notes = f'{model["parts"] - len(unmeasured) - len(without_aura)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no proc measurements in {", ".join(unmeasured)}'
    notes += f'; {other_triggers} triggers without exactly one landed hit left out'
    if not single:
        status = 'alert' if unmeasured and not without_aura else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial: no trigger landed exactly one hit ({notes})')
    with_proc = float(sum(1 for procs in single if procs >= 1))
    measured = with_proc / len(single)
    chance = stated_chance(manifest, first_run, expectation, tooltips, base, measured)
    if isinstance(chance, Verdict):
        return chance
    expected = chance / 100
    status, low, high, why = rate_judgement(with_proc, len(single), model['minimum_trials'], expected)
    counts = Counter(procs for procs in single)
    histogram = ', '.join(f'{procs:g}: {counts[procs]}' for procs in sorted(counts))
    over = sum(count for procs, count in counts.items() if procs > limit)
    multiplicity = (f'{over} of {len(single)} one-hit triggers gave more than {limit} proc (at most '
                    f'{max(counts):g})' if over else f'no one-hit trigger gave more than {limit} proc')
    partial = sum(count for procs, count in counts.items() if not float(procs).is_integer())
    if partial:
        multiplicity += (f'; {partial} of {len(single)} one-hit triggers gave a part of a proc (events not a whole '
                         f'multiple of {model["events_per_proc"]})')
    if over or partial:
        status, low, high = 'alert', None, None
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   explanation=f'{multiplicity}; procs per one-hit trigger {histogram}; {with_proc:g} of '
                               f'{len(single)} one-hit triggers gave a proc, {why}: {status} ({notes}); '
                               f'{expectation.displayed} shows {chance:g}%; {expectation.rule}')


def judge_proc(manifest: dict, parts: list[ProcPart], tooltips: TooltipSource) -> Verdict:
    first_entry, first_run, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    if model.get(PER_TRIGGER):
        return judge_proc_per_trigger(manifest, parts, tooltips, base)
    labels = model['measurements']
    readings = proc_readings(model)
    event_labels = model.get('event_labels') or [labels['events']]
    refunds = [model['charge_pool'], labels['attempts']] if model.get('charge_pool') else []
    wanted = [labels['aura']] + list(dict.fromkeys(
        event_labels + [labels['trials']] + [label for reading in readings for label in reading['labels']]
        + refunds))
    trigger = model['trigger']['spell'] if model['trigger']['action'] == CAST else 0
    totals = dict.fromkeys(wanted[1:], 0.0)
    events = 0.0
    counted, without_aura, unmeasured, reasons = [], [], [], []
    for _, run, _ in parts:
        if trigger:
            reasons += failure_reasons(run, trigger)
        values = [run.values.get(label) for label in wanted]
        if None in values:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
        elif values[0] <= 0:
            without_aura.append(run.key)
        else:
            counted.append(run.key)
            for label, value in zip(wanted[1:], values[1:]):
                totals[label] += value
            events -= player_casts(model, run, trigger)
            events += refund_offset(model, run)
    events += sum(totals[label] for label in event_labels)
    procs = events / model['events_per_proc']
    trials = totals[labels['trials']]
    notes = f'{len(counted)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no proc measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    measured = procs / trials if trials > 0 else None
    if trials <= 0:
        status = 'alert' if unmeasured and not (without_aura or reasons) else 'unmeasured'
        return replace(base, status=status, measured=measured,
                       explanation=f'no usable trial: no triggering hit was measured ({notes})')
    chance = stated_chance(manifest, first_run, expectation, tooltips, base, measured)
    if isinstance(chance, Verdict):
        return chance
    expected = chance / 100
    judged = []
    for reading in readings:
        excluded = events if reading.get('minus_events') else 0.0
        reading_trials = sum(totals[label] for label in reading['labels']) - excluded
        status, low, high, why = rate_judgement(procs, reading_trials, model['minimum_trials'], expected)
        judged.append((status, procs / reading_trials if reading_trials > 0 else None, low, high,
                       f'{reading["name"]}: {procs:g} procs in {reading_trials:g} trials, {why}: {status}',
                       reading_trials))
    statuses = {status for status, *_ in judged}
    status, rate, low, high, *_ = judged[0]
    detail = None
    if len(statuses) > 1:
        status, low, high = 'ambiguous_tooltip', None, None
        detail = {'question': proc_question(manifest, first_entry, expectation, readings, judged, procs, chance,
                                            tooltips)}
    readings_text = '; '.join(text for *_, text, _ in judged)
    lead = 'the readings of the trials disagree; ' if len(statuses) > 1 else ''
    return replace(base, status=status, measured=rate, expected=expected, low=low, high=high, detail=detail,
                   explanation=f'{lead}{readings_text} ({notes}); {expectation.displayed} shows {chance:g}%; '
                               f'{expectation.rule}; events: {event_text(model, event_labels, trigger)}, '
                               f'{model["events_per_proc"]} per proc')


def observations_needed(rates: list[float]) -> int | None:
    needed = [math.ceil((Z_99 * (math.sqrt(low * (1 - low)) + math.sqrt(high * (1 - high))) / (high - low)) ** 2)
              for index, low in enumerate(rates) for high in rates[index + 1:] if abs(high - low) > FLOAT_EPSILON]
    return max(needed) if needed else None


@dataclass(frozen=True)
class HitSpread:
    sigma: float
    mean: float
    weapon: tuple[float, float] | None
    rolls: tuple[int, ...]


def hit_spread(tooltips: TooltipSource, class_file: dict, spell: int) -> HitSpread | None:
    mean = variance = flats = 0.0
    percent = 1.0
    weapon, rolls = False, []
    try:
        for effect in EFFECTS:
            kind = tooltips.spell_field(spell, f'Effect[{effect}]')
            if kind not in (SCHOOL_DAMAGE, HEAL, WEAPON_PERCENT_DAMAGE) and kind not in WEAPON_FLAT_EFFECTS:
                continue
            base, die_sides = tooltips.effect_points(spell, effect)
            sides = abs(die_sides)
            if kind == WEAPON_PERCENT_DAMAGE:
                weapon, percent = True, percent * (base + 1) / 100
            elif kind in WEAPON_FLAT_EFFECTS:
                weapon, flats = True, flats + base + 1
            else:
                mean += base + ((sides + 1) / 2 if sides else 0)
                if sides > 1:
                    variance += (sides ** 2 - 1) / 12
                    rolls.append(sides)
    except Unreadable:
        return None
    low = high = 0.0
    if weapon:
        low, high = class_file['weapon']['min_damage'], class_file['weapon']['max_damage']
        mean += percent * (low + high) / 2 + flats
        variance += (percent * (high - low)) ** 2 / 12
    if mean <= 0:
        return None
    return HitSpread(math.sqrt(variance), mean, (low, high) if weapon else None, tuple(rolls))


def hits_needed(spread: HitSpread, ratios: list[float]) -> int:
    variation = spread.sigma / spread.mean
    needed = [math.ceil(2 * (Z_99 * variation * (low + high) / (high - low)) ** 2)
              for index, low in enumerate(ratios) for high in ratios[index + 1:] if abs(high - low) > FLOAT_EPSILON]
    return max([1] + needed)


def spread_note(spread: HitSpread) -> str:
    if spread.weapon:
        return (f'with a weapon of {spread.weapon[0]:g} to {spread.weapon[1]:g} damage, like our test weapon; a weapon '
                f'with a wider damage range needs more hits')
    if spread.rolls:
        return (f'the client data rolls the hit over {", ".join(map(str, spread.rolls))} values; this is an upper '
                f'bound, since the attack power, spell power and per-level parts of the hit, left out here, make the '
                f'hits vary less for their size')
    return 'the client data gives a fixed amount, so the hits differ only by rounding'


def hit_count(spread: HitSpread | None, ratios: list[float], noun: str,
              each: str = 'each way') -> tuple[int | None, str]:
    if spread is None:
        return None, ''
    needed = hits_needed(spread, ratios)
    return needed, (f'About {needed} {noun} {each}: at that count the 99% ranges of the readings no longer overlap '
                    f'({spread_note(spread)}).')


def comparison_word(reading: float, reference: float) -> str:
    if abs(reading - reference) <= FLOAT_EPSILON:
        return 'the same'
    return 'more' if abs(reading) > abs(reference) else 'less'


def percent_interval(low: float | None, high: float | None) -> str:
    return f' (99% interval {low:.2%} to {high:.2%})' if low is not None and high is not None else ''


def proc_question(manifest: dict, scenario: dict, expectation: Expectation, readings: list[dict], judged: list,
                  procs: float, chance: float, tooltips: TooltipSource) -> dict:
    entry = class_entry(manifest, expectation)
    model = expectation.model
    name = entry.get('name') or scenario['spell_name']
    meanings = {reading['name']: reading.get('meaning', '') for reading in entry.get('trial_readings', [])}
    trigger = model['trigger']
    if trigger['action'] == CAST:
        trigger_name = spell_name(tooltips, trigger['spell'])
        one, unit = f'cast of {trigger_name}', f'casts of {trigger_name}'
        done = (f'learned only {name} and {trigger_name} ({trigger["spell"]}) and cast it at a target dummy every '
                f'{model["attempt_ms"] / 1000:g} sec, its cooldown reset before each cast, using nothing else')
    else:
        one, unit = 'auto attack that hits', 'auto attacks that hit'
        done = f'learned only {name} and auto attacked a target dummy without using any ability'
    base_trials = judged[0][5]
    chance_rate = chance / 100
    predicted = []
    for *_, trials in judged:
        extra = (trials - base_trials) / procs if procs else 0.0
        predicted.append(chance_rate / (1 - extra * chance_rate) if extra * chance_rate < 1 else None)
    counted = procs / base_trials if base_trials > 0 else None
    conditions = (f'Our test: the level {manifest["level"]} test character {done}. It counted {procs:g} {name} '
                  f'procs in {base_trials:g} {unit}')
    conditions += (f', {counted:.2%}{percent_interval(judged[0][2], judged[0][3])}.' if counted is not None
                   else '.')
    rates = [rate for rate in predicted if rate is not None]
    needed = observations_needed(rates)
    observations = (f'About {needed} {unit}: at that count the 99% ranges of the readings '
                    f'({" and ".join(f"{rate:.1%}" for rate in rates)}) no longer overlap.' if needed else '')
    counting = f'the logged {name} procs per {one} under conditions matching our test should match one reading below.'
    question = (f'With {name} learned, {entry["readings_question"]} Otherwise, {counting}'
                if entry.get('readings_question') else f'With {name} learned, {counting}')
    rows = [{'name': reading['name'], 'meaning': meanings.get(reading['name'], ''),
             'expects': f'{rate:.1%} of {unit} give a {name} proc' if rate is not None else 'no rate',
             'measured_text': f'{counted:.2%}' if counted is not None else '', 'predicted': rate, 'procs': procs,
             'trials': trials, 'rate': reading_rate, 'low': low, 'high': high, 'expected': chance / 100,
             'status': status}
            for reading, rate, (status, reading_rate, low, high, _, trials) in zip(readings, predicted, judged)]
    return question_detail(READINGS_QUESTION, question, rows, procs, conditions=conditions,
                           observations=observations)


def trigger_counts(run: Run, labels: dict, with_baseline: bool, periodic: bool, part_attempts: int,
                   baseline_attempts: int) -> tuple[float, float, float, float] | None:
    if periodic:
        without = run.values.get(labels['without']) if with_baseline else 0.0
        events = run.values.get(labels['events'])
        if events is None or without is None:
            return None
        return (float(baseline_attempts) if with_baseline else 0.0, without if with_baseline else 0.0,
               float(part_attempts), events)
    names = ('baseline_trials', 'without', 'trials', 'events') if with_baseline else ('trials', 'events')
    values = [run.values.get(labels[name]) for name in names]
    if None in values:
        return None
    return tuple(values) if with_baseline else (0.0, 0.0, *values)


def judge_trigger(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    trigger = model['trigger']['spell'] if model['trigger']['action'] == CAST else 0
    periodic = model['trigger']['action'] == PERIODIC
    observed = f'{model["observe_metric"]} of {model["observe_spell"]}'
    trials = events = 0.0
    baseline: tuple[float, float] | None = None
    counted, without_aura, unmeasured, reasons = [], [], [], []
    for _, run, part in parts:
        if trigger:
            reasons += failure_reasons(run, trigger)
        with_baseline = part.model['baseline_attempts'] > 0
        found = trigger_counts(run, labels, with_baseline, periodic, part.model['part_attempts'],
                               part.model['baseline_attempts'])
        aura = run.values.get(labels['aura'])
        if found is None or aura is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
            continue
        baseline_trials, without, total_trials, total_events = found
        if with_baseline:
            baseline = (baseline_trials, without)
        if aura <= 0:
            without_aura.append(run.key)
            continue
        counted.append(run.key)
        trials += total_trials if periodic else total_trials - baseline_trials
        events += total_events - without
    notes = f'{len(counted)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no trigger measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    if baseline is not None and baseline[1] > 0:
        return replace(base, measured=baseline[1], expected=0.0, low=0.0, high=0.0,
                       explanation=f'{observed} occurred {baseline[1]:g} times in {baseline[0]:g} baseline trials '
                                   f'without the passive ({notes})')
    if trials <= 0:
        status = 'alert' if unmeasured and not (without_aura or reasons) else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial with the passive learned ({notes})')
    expected = trials * model['per_trigger'] + (len(counted) if model.get('periodic_initial_tick') else 0)
    low, high = expected - EVENT_TOLERANCE, expected + EVENT_TOLERANCE
    counts = (f'{events:g} events ({observed}) in {trials:g} trials ({model["trial_metric"]}), '
              f'{model["per_trigger"]:g} per trigger expects {expected:g}')
    judged = replace(base, measured=events, expected=expected, low=low, high=high)
    if trials < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{counts}; fewer than the {model["minimum_trials"]} trials the check needs '
                                   f'({notes})')
    status = 'ok' if low - FLOAT_EPSILON <= events <= high + FLOAT_EPSILON else 'alert'
    if status == 'ok' and (baseline is None or baseline[0] <= 0):
        return replace(judged, status='unmeasured',
                       explanation=f'{counts}; the baseline without the passive has no trial, so the events are not '
                                   f'tied to the passive ({notes})')
    return replace(judged, status=status, explanation=f'{counts}; no event in {baseline[0]:g} baseline trials '
                                                      f'without the passive; {expectation.rule} ({notes})')


def judge_self_trigger(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    observed = f'{model["observe_metric"]} of {model["observe_spell"]}'
    trials = events = 0.0
    counted, unmeasured, reasons = [], [], []
    for _, run, part in parts:
        reasons += failure_reasons(run, model['trigger']['spell'])
        total_trials = run.values.get(labels['trials'])
        total_events = run.values.get(labels['events'])
        if total_trials is None or total_events is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
            continue
        counted.append(run.key)
        trials += total_trials
        events += total_events
    notes = f'{len(counted)} of {model["parts"]} parts'
    if unmeasured:
        notes += f'; no trigger measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    if trials <= 0:
        status = 'alert' if unmeasured else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial ({notes})')
    expected = trials * model['per_trigger']
    low, high = expected - EVENT_TOLERANCE, expected + EVENT_TOLERANCE
    counts = (f'{events:g} events ({observed}) in {trials:g} trials ({model["trial_metric"]} of '
              f'{model["trigger"]["spell"]}), {model["per_trigger"]:g} per trigger expects {expected:g}')
    judged = replace(base, measured=events, expected=expected, low=low, high=high)
    if trials < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{counts}; fewer than the {model["minimum_trials"]} trials the check needs '
                                   f'({notes})')
    status = 'ok' if low - FLOAT_EPSILON <= events <= high + FLOAT_EPSILON else 'alert'
    return replace(judged, status=status,
                   explanation=f'{counts}; the trigger spell is its own tooltip clause, with no separate passive to '
                               f'gate a baseline against; {expectation.rule} ({notes})')


def judge_gate_absence(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    observed = f'{model["observe_metric"]} of {model["observe_spell"]}'
    trials = events = 0.0
    counted, unmeasured, reasons, refused = [], [], [], []
    for _, run, part in parts:
        reasons += failure_reasons(run, model['trigger']['spell'])
        total_trials = run.values.get(labels['trials'])
        total_events = run.values.get(labels['events'])
        if total_trials is None or total_events is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
            continue
        control = model.get('away_control')
        if control is not None and run.values.get(control) != 0:
            refused.append(f'{run.key} ({run.values.get(control)})')
        counted.append(run.key)
        trials += total_trials
        events += total_events
    notes = f'{len(counted)} of {model["parts"]} parts'
    if refused:
        return replace(base, status='unmeasured',
                       explanation=f'{model["observe_spell"]} could not be cast at the away position, so its absence '
                                   f'does not show the withheld gate: cast failure in {", ".join(refused)}')
    if unmeasured:
        notes += f'; no trigger measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    if trials <= 0:
        status = 'alert' if unmeasured else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial ({notes})')
    counts = f'{events:g} events ({observed}) in {trials:g} trials ({model["trial_metric"]} of {model["trigger"]["spell"]})'
    judged = replace(base, measured=events, expected=0.0, low=0.0, high=0.0)
    if trials < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{counts}; fewer than the {model["minimum_trials"]} trials the check needs '
                                   f'({notes})')
    status = 'ok' if events <= FLOAT_EPSILON else 'alert'
    return replace(judged, status=status,
                   explanation=f'{counts}; the passive is known but {model["gate_text"]!r} is withheld, so 0 '
                               f'events are expected ({notes})')


def elapsed_between(run: Run, start_label: str, end_label: str) -> float | None:
    start = next((index for index, step in enumerate(run.steps) if step.get('label') == start_label), None)
    end = next((index for index, step in enumerate(run.steps) if step.get('label') == end_label), None)
    if start is None or end is None or run.max_step_ms is None:
        return None
    return sum(number(step.get('elapsed_ms', 0), 'elapsed_ms') + run.max_step_ms for step in run.steps[start + 1:end + 1])


def cooldown_trial_windows(run: Run, aura: int, labels: dict, phase: str,
                          count: int) -> list[tuple[float, float]] | None:
    found = []
    for index in range(count):
        before_label = cooldown_trial_label(aura, phase, index, 'before')
        after_label = cooldown_trial_label(aura, phase, index, 'after')
        before, after = run.values.get(before_label), run.values.get(after_label)
        window = elapsed_between(run, before_label, after_label)
        if before is None or after is None or window is None:
            return None
        found.append((before - after, window))
    return found


def judge_trigger_cooldown(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    aura = expectation.spell_id
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    expected = model['expected_delta_ms']
    margin = margin_of(expected)
    measured_found: list[tuple[float, float]] = []
    baseline_found: list[tuple[float, float]] = []
    without_aura, unmeasured = [], []
    for _, run, part in parts:
        labels = part.model['measurements']
        baseline_attempts = part.model['baseline_attempts']
        baseline = cooldown_trial_windows(run, aura, labels, 'baseline', baseline_attempts)
        if baseline_attempts and baseline is None:
            unmeasured.append(unusable_run(run))
            continue
        if baseline:
            baseline_found += baseline
        aura_value = run.values.get(labels['aura'])
        if aura_value is None:
            unmeasured.append(unusable_run(run))
            continue
        if aura_value <= 0:
            without_aura.append(run.key)
            continue
        measured = cooldown_trial_windows(run, aura, labels, 'measured', part.model['part_attempts'])
        if measured is None:
            unmeasured.append(unusable_run(run))
            continue
        measured_found += measured
    notes = f'{len(measured_found)} measured trials across {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {aura} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no cooldown measurements in {", ".join(unmeasured)}'
    bad_baseline = [(delta, window) for delta, window in baseline_found
                    if not (-margin <= delta <= window + margin)]
    if bad_baseline:
        delta, window = bad_baseline[0]
        return replace(base, measured=delta, expected=0.0, low=-margin, high=window + margin,
                       explanation=f'cooldown delta {delta:g} ms (up to {window:g} ms of it from the real time '
                                   f'elapsed since the before reading) in a baseline trial without the passive '
                                   f'({notes})')
    if not measured_found:
        status = 'alert' if unmeasured and not without_aura else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial with the passive learned ({notes})')
    measured_deltas = [delta for delta, _ in measured_found]
    mean_delta = fmean(measured_deltas)
    low, high = expected - margin, expected + margin
    judged = replace(base, measured=mean_delta, expected=expected, low=low, high=high)
    if len(measured_found) < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{len(measured_found)} trials, fewer than the {model["minimum_trials"]} the '
                                   f'check needs ({notes})')
    outliers = [(delta, window) for delta, window in measured_found
               if not (expected - margin <= delta <= expected + window + margin)]
    if outliers:
        delta, window = outliers[0]
        return replace(judged, status='alert',
                       explanation=f'{len(outliers)} of {len(measured_found)} trials outside '
                                   f'[{expected - margin:g}, expected + up to {window:g} ms elapsed] ms '
                                   f'(e.g. {delta:g}); mean {mean_delta:g} ms; no nonzero baseline delta beyond its '
                                   f'own elapsed window ({notes})')
    if not baseline_found:
        return replace(judged, status='unmeasured',
                       explanation=f'mean {mean_delta:g} ms over {len(measured_found)} trials within tolerance of '
                                   f'the expected {expected:g} ms; the baseline without the passive has no trial, '
                                   f'so the delta is not tied to the passive ({notes})')
    return replace(judged, status='ok',
                   explanation=f'mean {mean_delta:g} ms over {len(measured_found)} trials within tolerance of the '
                               f'expected {expected:g} ms; no baseline trial without the passive exceeded its own '
                               f'elapsed-time window; {expectation.rule} ({notes})')


def duration_trial_windows(run: Run, aura: int, labels: dict, phase: str,
                          count: int) -> list[tuple[float, float]] | None:
    found = []
    for index in range(count):
        before_label = duration_trial_label(aura, phase, index, 'before')
        after_label = duration_trial_label(aura, phase, index, 'after')
        before, after = run.values.get(before_label), run.values.get(after_label)
        window = elapsed_between(run, before_label, after_label)
        if before is None or after is None or window is None:
            return None
        found.append((after - before, window))
    return found


def judge_trigger_duration(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    aura = expectation.spell_id
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    expected = model['expected_delta_ms']
    margin = margin_of(expected)
    measured_found: list[tuple[float, float]] = []
    baseline_found: list[tuple[float, float]] = []
    without_aura, unmeasured = [], []
    for _, run, part in parts:
        labels = part.model['measurements']
        baseline_attempts = part.model['baseline_attempts']
        baseline = duration_trial_windows(run, aura, labels, 'baseline', baseline_attempts)
        if baseline_attempts and baseline is None:
            unmeasured.append(unusable_run(run))
            continue
        if baseline:
            baseline_found += baseline
        aura_value = run.values.get(labels['aura'])
        if aura_value is None:
            unmeasured.append(unusable_run(run))
            continue
        if aura_value <= 0:
            without_aura.append(run.key)
            continue
        measured = duration_trial_windows(run, aura, labels, 'measured', part.model['part_attempts'])
        if measured is None:
            unmeasured.append(unusable_run(run))
            continue
        measured_found += measured
    notes = f'{len(measured_found)} measured trials across {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {aura} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no duration measurements in {", ".join(unmeasured)}'
    bad_baseline = [(delta, window) for delta, window in baseline_found
                    if not (-(window + margin) <= delta <= margin)]
    if bad_baseline:
        delta, window = bad_baseline[0]
        return replace(base, measured=delta, expected=0.0, low=-(window + margin), high=margin,
                       explanation=f'duration delta {delta:g} ms (up to {window:g} ms of natural decay since the '
                                   f'before reading) in a baseline trial without the passive ({notes})')
    if not measured_found:
        status = 'alert' if unmeasured and not without_aura else 'unmeasured'
        return replace(base, status=status, explanation=f'no usable trial with the passive learned ({notes})')
    measured_deltas = [delta for delta, _ in measured_found]
    mean_delta = fmean(measured_deltas)
    low, high = expected - margin, expected + margin
    judged = replace(base, measured=mean_delta, expected=expected, low=low, high=high)
    if len(measured_found) < model['minimum_trials']:
        return replace(judged, status='insufficient_trials',
                       explanation=f'{len(measured_found)} trials, fewer than the {model["minimum_trials"]} the '
                                   f'check needs ({notes})')
    outliers = [(delta, window) for delta, window in measured_found
               if not (expected - window - margin <= delta <= expected + margin)]
    if outliers:
        delta, window = outliers[0]
        return replace(judged, status='alert',
                       explanation=f'{len(outliers)} of {len(measured_found)} trials outside '
                                   f'[expected - up to {window:g} ms elapsed, {expected + margin:g}] ms '
                                   f'(e.g. {delta:g}); mean {mean_delta:g} ms; no nonzero baseline delta beyond its '
                                   f'own elapsed window ({notes})')
    if not baseline_found:
        return replace(judged, status='unmeasured',
                       explanation=f'mean {mean_delta:g} ms over {len(measured_found)} trials within tolerance of '
                                   f'the expected {expected:g} ms; the baseline without the passive has no trial, '
                                   f'so the delta is not tied to the passive ({notes})')
    return replace(judged, status='ok',
                   explanation=f'mean {mean_delta:g} ms over {len(measured_found)} trials within tolerance of the '
                               f'expected {expected:g} ms; no baseline trial without the passive exceeded its own '
                               f'elapsed-time window; {expectation.rule} ({notes})')


def magnitude_target_mitigation(model: dict, run: Run) -> float | None:
    school_mask = model.get('resisted_school_mask')
    if not school_mask:
        return 1.0
    labels = model['target_measurements']
    level = run.values.get(labels['view_level'])
    resistances = {1 << school: run.values.get(labels[f'resistance {school}'])
                   for school in magic_schools(school_mask)}
    if level is None or None in resistances.values():
        return None
    target = TargetProfile(entry=0, level=int(level), armor=0,
                           resistances={bit: int(value) for bit, value in resistances.items()})
    return expected_mitigation(school_mask, target, model['caster_level']).mean


def judge_trigger_magnitude(parts: list[ProcPart]) -> Verdict:
    first_entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    expected = model['expected_ratio']
    trigger_total = trigger_count = observe_total = observe_count = kept_count = 0.0
    without_aura, unmeasured = [], []
    reasons: list[int] = []
    part_ratios: list[float] = []
    for _, run, part in parts:
        labels = part.model['measurements']
        reasons += failure_reasons(run, model['trigger']['spell'])
        aura = run.values.get(labels['aura'])
        trig_total = run.values.get(labels['trigger_total'])
        trig_count = run.values.get(labels['trigger_count'])
        obs_total = run.values.get(labels['observe_total'])
        obs_count = run.values.get(labels['observe_count'])
        kept = magnitude_target_mitigation(part.model, run)
        if aura is None or trig_total is None or trig_count is None or obs_total is None or obs_count is None \
                or kept is None:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
            continue
        if aura <= 0:
            without_aura.append(run.key)
            continue
        trigger_total += trig_total
        trigger_count += trig_count
        observe_total += obs_total
        observe_count += obs_count
        kept_count += kept * obs_count
        if trig_total > 0 and trig_count > 0 and obs_count > 0:
            part_ratios.append((obs_total / obs_count) / (trig_total / trig_count))
    usable = len(parts) - len(without_aura) - len(unmeasured)
    notes = f'{usable} usable parts of {model["parts"]}'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no magnitude measurements in {", ".join(unmeasured)}'
    if reasons:
        notes += f'; failed casts: {describe_failures(reasons)}'
    if usable <= 0 or trigger_total <= 0 or trigger_count <= 0:
        status = 'alert' if unmeasured and not without_aura else 'unmeasured'
        return replace(base, status=status,
                       explanation=f'no usable trial with the passive learned and trigger damage measured ({notes})')
    if observe_count < model['minimum_trials']:
        status = 'insufficient_trials' if observe_count > 0 else ('alert' if unmeasured and not without_aura
                                                                   else 'unmeasured')
        return replace(base, status=status,
                       explanation=f'{observe_count:g} {model["observe_metric"]} events, fewer than the '
                                   f'{model["minimum_trials"]} the check needs ({notes})')
    mean_trigger = trigger_total / trigger_count
    mean_observe = observe_total / observe_count
    ratio = mean_observe / mean_trigger
    kept = kept_count / observe_count
    tooltip_ratio = expected
    expected = tooltip_ratio * kept
    margin = max(MAGNITUDE_RATIO_FLOOR, MAGNITUDE_RATIO_TOLERANCE * expected)
    low, high = expected - margin, expected + margin
    judged = replace(base, measured=ratio, expected=expected, low=low, high=high)
    status = 'ok' if low - FLOAT_EPSILON <= ratio <= high + FLOAT_EPSILON else 'alert'
    trigger_source = 'main-hand melee attacks' if model['trigger']['action'] == 'attack' \
        else str(model['trigger']['spell'])
    resisted = (f' (tooltip {tooltip_ratio:g} x {kept:.4f} kept after the target\'s average partial resist of school '
                f'mask {model["resisted_school_mask"]})') if model.get('resisted_school_mask') else ''
    excluded, excluded_note = magnitude_excluded(low, high, part_ratios)
    return replace(judged, status=status, detail={EXCLUDED: excluded},
                   explanation=f'mean {mean_observe:g} {model["observe_metric"]} of {model["observe_spell"]} over '
                               f'{observe_count:g} of its own events, against mean {mean_trigger:g} '
                               f'{model["trigger_metric"]} of {trigger_source} over {trigger_count:g} of its own '
                               f'events, = {ratio:.4f}, within max({MAGNITUDE_RATIO_FLOOR:g}, '
                               f'{MAGNITUDE_RATIO_TOLERANCE:.0%} of expected) of {expected:g}{resisted}; '
                               f'{expectation.rule} ({notes}); {excluded_note}')


def magnitude_excluded(low: float, high: float, part_ratios: list[float]) -> tuple[list[float] | None, str]:
    if len(part_ratios) < MINIMUM_PASSES:
        return None, (f'excludes no ratio by a measured interval: {len(part_ratios)} part gives no sampling '
                      f'interval, so only the band {low:.6g} to {high:.6g} is stated')
    mean, part_low, part_high = mean_interval(part_ratios)
    half = (part_high - part_low) / 2
    return [low - half, high + half], (f'this check {band_excluded_text(low - half, high + half, "a ratio")} '
                                       f'(the band widened by the 99% half-width {half:.4g} of the mean of '
                                       f'{len(part_ratios)} part ratios, {mean:.4f})')


DETAIL_KEYS = ('config', 'baseline', 'index', 'passes', 'source', 'talents')


def stack_detail(model: dict | None, values: list[float] | None = None) -> dict:
    detail = {key: (model or {})[key] for key in DETAIL_KEYS if key in (model or {})}
    if values is not None:
        detail['per_pass'] = values
    return detail


def failures_note(runs: list[Run], spells: set[int] | None = None) -> str:
    by_spell: dict[int, list[int]] = {}
    for run in runs:
        for spell, reasons in run.cast_failures.items():
            if spells is None or spell in spells:
                by_spell.setdefault(spell, []).extend(reason for reason in reasons if reason != NO_CAST_FAILURE)
    parts = [f'{spell}: {describe_failures(reasons)}' for spell, reasons in sorted(by_spell.items()) if reasons]
    return f'; failed casts {"; ".join(parts)}' if parts else ''


def listed(values: list[float]) -> str:
    return ', '.join(f'{value:.6g}' for value in values)


def unusable_run(run: Run) -> str:
    return f'{run.key} ({run.status}: {run.message})'


def measured_stack_verdict(base: Verdict, model: dict, values: list[float], unusable: list[str], why: str) -> Verdict:
    passes = model['passes']
    detail = stack_detail(model, values)
    notes = f'{len(values)} of {passes} passes' + (f'; not usable: {", ".join(unusable)}' if unusable else '')
    if not values:
        return replace(base, detail=detail, explanation=f'no usable pass ({notes}); {why}')
    if len(values) < passes:
        return replace(base, status='insufficient_trials', measured=fmean(values), detail=detail,
                       explanation=f'{notes}, fewer than the {passes} the interval needs: {listed(values)}; {why}')
    mean, low, high = mean_interval(values)
    return replace(base, status=MEASURED, measured=mean, low=low, high=high, detail=detail,
                   explanation=f'{notes}: {listed(values)}; 99% Student t interval of the mean of the passes; {why}')


def judge_stack_dps(base: Verdict, parts: list[ProcPart]) -> Verdict:
    expectation = parts[0][2]
    model = expectation.model
    labels, seconds = model['measurements'], model['rotation_ms'] / 1000
    values, unusable = [], []
    for _, run, _ in parts:
        start, end = run.values.get(labels['health_start']), run.values.get(labels['health_end'])
        if start is None or end is None:
            unusable.append(unusable_run(run))
        else:
            values.append((start - end) / seconds)
    return measured_stack_verdict(base, model, values, unusable,
                                  expectation.rule + failures_note([run for _, run, _ in parts]))


def judge_stack_source(base: Verdict, parts: list[ProcPart]) -> Verdict:
    expectation = parts[0][2]
    model = expectation.model
    labels, seconds, source = model['measurements'], model['rotation_ms'] / 1000, model['source']
    values, counts, unusable = [], [], []
    for _, run, _ in parts:
        total, count = run.values.get(labels['total']), run.values.get(labels['count'])
        if total is None or count is None:
            unusable.append(unusable_run(run))
        else:
            values.append(total / seconds)
            counts.append(count)
    failures = failures_note([run for _, run, _ in parts], {source}) if source != MELEE_SOURCE else ''
    if values and not any(counts) and failures:
        return replace(base, status='unmeasured', measured=0.0, detail=stack_detail(model, values),
                       explanation=f'no hit of {source} in {len(values)} passes{failures}')
    return measured_stack_verdict(base, model, values, unusable,
                                  f'{expectation.rule}; hits per pass: {listed(counts)}{failures}')


def per_hit_means(runs: list[Run], labels: dict) -> tuple[list[float], list[str], list[str]]:
    means, empty, unusable = [], [], []
    for run in runs:
        total, count = run.values.get(labels['total']), run.values.get(labels['count'])
        if total is None or count is None:
            unusable.append(unusable_run(run))
        elif count <= 0:
            empty.append(run.key)
        else:
            means.append(total / count)
    return means, empty, unusable


def known_percents(manifest: dict, model: dict, runs: list[Run]) -> tuple[list[tuple[str, float]], str | None]:
    found = []
    for row in manifest.get('known_modifiers', []):
        if row['applies_to'] != 'damage' or not row['school_mask'] & model['school_mask']:
            continue
        present = [run.values.get(known_aura_label(row['spell_id']), 0) > 0 for run in runs]
        if all(present):
            found.append((known_label(row), float(row['percent'])))
        elif any(present):
            return [], (f'known aura {row["spell_id"]} is present in {sum(present)} of {len(present)} passes, so the '
                        f'configurations differ by more than the talent')
    return found, None


def composition_readings(model: dict, known: list[tuple[str, float]]) -> list[tuple[str, float, str]]:
    bonus = model['bonus_pct']
    readings = [(MULTIPLIES, bonus, 'the bonus scales the per-hit damage of the previous configuration, known '
                                    'modifiers and earlier bonuses included')]
    others = known + [(f'{item["token"]} of {item["talent"]}', item['bonus_pct'])
                      for item in model.get('earlier_bonuses') or []]
    if others:
        stacked = sum(percent for _, percent in others)
        names = ', '.join(f'{name} {percent:+g}%' for name, percent in others)
        readings.append((ADDS, 100 * bonus / (100 + stacked),
                         f'the bonus adds to the other percents of the hit, {names}: 100 x {bonus:g} / (100 '
                         f'{stacked:+g})'))
    return readings


def owner_fallback(statuses: set[str], log_query: str | None) -> str:
    if len(statuses) == 1:
        return next(iter(statuses))
    if not log_query:
        return 'ambiguous_tooltip'
    return 'ok' if 'ok' in statuses else 'alert'


def log_query_of(manifest: dict, label: str) -> str | None:
    return (manifest['class_file'].get('log_queries') or {}).get(label)


def judge_talent_delta(manifest: dict, parts: list[ProcPart], config_runs: dict[str, dict[str, Run]],
                       tooltips: TooltipSource) -> Verdict:
    entry, _, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check, stack_detail(model))
    source, passes = model['source'], model['passes']
    current_runs = list(config_runs.get(model['config'], {}).values())
    baseline_runs = list(config_runs.get(model['baseline'], {}).values())
    current, current_empty, current_unusable = per_hit_means(current_runs, model['measurements'])
    baseline, baseline_empty, baseline_unusable = per_hit_means(baseline_runs, model['measurements'])
    failures = failures_note(current_runs + baseline_runs, {source})
    notes = []
    for name, means, empty, unusable in ((model['config'], current, current_empty, current_unusable),
                                         (model['baseline'], baseline, baseline_empty, baseline_unusable)):
        note = f'{name}: {len(means)} of {passes} passes'
        if empty:
            note += f', no hit of {source} in {", ".join(empty)}'
        if unusable:
            note += f', not usable: {", ".join(unusable)}'
        notes.append(note)
    notes_text = '; '.join(notes)
    if (not current and current_empty) or (not baseline and baseline_empty):
        return replace(base, status='unmeasured',
                       explanation=f'no non-critical, unblocked hit of {source} ({notes_text}){failures}')
    if not current or not baseline:
        return replace(base, explanation=f'no per-hit measurement of {source} ({notes_text})')
    measured = (fmean(current) / fmean(baseline) - 1) * 100
    if len(current) < passes or len(baseline) < passes:
        return replace(base, status='insufficient_trials', measured=measured,
                       explanation=f'{notes_text}, fewer than the {passes} passes the interval needs{failures}')
    try:
        caster = caster_stats_from(current_runs[0].values, manifest['class_file'])
    except KeyError as error:
        return replace(base, measured=measured, explanation=f'base measurement {error} is missing from '
                                                            f'{current_runs[0].key}')
    shown = next((value.value for value in tooltips.read(expectation.rank_id, caster).values
                  if value.text == model['token']), None)
    if shown is None:
        return replace(base, measured=measured, explanation=f'the tooltip of {expectation.rank_id} no longer shows '
                                                            f'{model["token"]}')
    if abs(shown - model['bonus_pct']) > FLOAT_EPSILON:
        return replace(base, measured=measured, expected=shown,
                       explanation=f'{model["token"]} shows {shown:g}%, generated as {model["bonus_pct"]:g}%')
    known, mixed = known_percents(manifest, model, current_runs + baseline_runs)
    if mixed:
        return replace(base, status='unmodelled', measured=measured, explanation=mixed)
    delta, low, high = ratio_interval(current, baseline)
    half = (high - low) / 2
    relative = half / (100 + model['bonus_pct'])
    judged_passes = min(len(current), len(baseline))
    stated = Bonus(delta, half, model['bonus_pct'], judged_passes)
    power, reason, needed = bonus_status(stated)
    if power == 'insufficient_trials':
        return replace(base, status='insufficient_trials', measured=delta, expected=model['bonus_pct'], low=low,
                       high=high, detail={**base.detail, 'trials_needed': needed},
                       explanation=f'{bonus_text(stated)}; {reason}; about {needed} passes per configuration would '
                                   f'meet it (observed variance, same t quantile); per-hit means of {source}: '
                                   f'{listed(current)} against {listed(baseline)}{failures}')
    judged = [(name, expected, band_status(Bonus(delta, half, expected, judged_passes)), why)
              for name, expected, why in composition_readings(model, known)]
    statuses = {status for _, _, status, _ in judged}
    log_query = log_query_of(manifest, expectation.label)
    status = owner_fallback(statuses, log_query)
    applied = next((item for item in judged if item[2] == 'ok'), None) if status == 'ok' and len(statuses) > 1 else None
    if len(statuses) == 1:
        lead = ''
    elif applied:
        lead = (f'owner fallback: logs queried ({log_query}) say nothing; the server applies {applied[0]} '
               f'({applied[3]}), a reading the tooltip permits; ')
    elif status == 'alert':
        lead = f'owner fallback: logs queried ({log_query}) say nothing; the server applies neither reading; '
    else:
        lead = 'the composition readings disagree; '
    readings = '; '.join(f'{name} ({why}): expected {expected:.4g}%: {item_status}'
                         for name, expected, item_status, why in judged)
    expected_value = applied[1] if applied else judged[0][1]
    applied_bonus = Bonus(delta, half, expected_value, judged_passes)
    detail = {**base.detail, EXCLUDED: list(applied_bonus.excluded), 'bonus': bonus_detail(applied_bonus)}
    if status == 'ambiguous_tooltip':
        detail = {**detail, 'question': talent_question(manifest, expectation, judged, delta, known, tooltips)}
    return replace(base, status=status, measured=delta, expected=expected_value, low=low, high=high, detail=detail,
                   explanation=f'{lead}{readings}; per-hit means of {source} in {len(current)} and {len(baseline)} '
                               f'passes: {listed(current)} against {listed(baseline)}; 99% Welch interval of the '
                               f'ratio of the means, half-width {relative:.2%} of the expected ratio; '
                               f'{expectation.rule}{failures}; {bonus_text(applied_bonus)}')


def known_label(row: dict) -> str:
    return f'known aura {row["spell_id"]} effect {row["effect_index"]} aura {row["aura"]}'


def modifier_text(tooltips: TooltipSource, row: dict) -> str:
    return f'{spell_name(tooltips, row["spell_id"])} {row["spell_id"]} ({row["percent"]:+d}% {row["applies_to"]})'


def talent_question(manifest: dict, expectation: Expectation, judged: list, delta: float,
                    known: list[tuple[str, float]], tooltips: TooltipSource) -> dict:
    model = expectation.model
    talent = class_entry(manifest, expectation).get('name') or spell_name(tooltips, expectation.spell_id)
    source = spell_name(tooltips, model['source'])
    rows = {known_label(row): row for row in manifest.get('known_modifiers', [])}
    others = [modifier_text(tooltips, rows[label]) if label in rows else f'{label} ({percent:+g}%)'
              for label, percent in known]
    others += [f'{spell_name(tooltips, item["talent"])} {item["talent"]} ({item["bonus_pct"]:+g}% damage of {source})'
               for item in model.get('earlier_bonuses') or []]
    class_file = manifest['class_file']
    earlier = [spell for config in class_file.get('stack', [])[:model['index']] for spell in config['talents']]
    learned = list(class_file.get('rotation', {}).get('learn', [])) + earlier
    named = ', '.join(f'{spell_name(tooltips, spell)} {spell}' for spell in learned) or 'no talent'
    conditions = (f'Our test: the level {manifest["level"]} test character, with {named} learned, ran the same '
                  f'rotation on a target dummy {model["passes"]} times, then {model["passes"]} times with {talent} '
                  f'also learned, and compared the average non-critical, unblocked {source} hit. Other percent '
                  f'modifiers of that hit on the test character: {", ".join(others) or "none"}.')
    bonus = model['bonus_pct']
    adds = next((expected for name, expected, _, _ in judged if name == ADDS), bonus)
    meanings = {MULTIPLIES: RELATION_MEANINGS[MULTIPLIES],
                ADDS: (f'the bonus is added to the other percent modifiers of the hit, here {", ".join(others)}, so it '
                       f'counts for {comparison_word(adds, bonus)}: the hit grows by {adds:.4g}% instead of '
                       f'{bonus:g}%')}
    changes = ' or '.join(f'{expected:.4g}%' for _, expected, _, _ in judged)
    needed, observations = hit_count(hit_spread(tooltips, class_file, model['source']),
                                     [1 + expected / 100 for _, expected, _, _ in judged],
                                     f'non-critical, unblocked {source} hits')
    record = (f'Record {needed} non-critical, unblocked {source} hits on the same target dummy without {talent} and '
              f'{needed} with it' if needed else
              f'Record as many non-critical, unblocked {source} hits on the same target dummy as you can without '
              f'{talent} and with it')
    question = (f'{record}, in a combat log and with the other modifiers of our test, and compare the averages; a '
                f'non-critical, unblocked {source} hit {changes} larger than without {talent} matches one reading '
                f'below.')
    readings = [{'name': name, 'meaning': meanings.get(name, why), 'expects': f'the {source} hit {expected:+.4g}%',
                 'measured_text': f'{delta:+.4g}%', 'expected': expected, 'measured': delta, 'status': status,
                 'unit': '%'} for name, expected, status, why in judged]
    return question_detail(READINGS_QUESTION, question, readings, delta, conditions=conditions,
                           observations=observations)


def judge_stack(manifest: dict, stack_parts: dict[str, list[ProcPart]], tooltips: TooltipSource,
                hit_model: HitModelSource) -> list[Verdict]:
    config_runs: dict[str, dict[str, Run]] = {}
    for parts in stack_parts.values():
        for entry, run, expectation in parts:
            if expectation.check == STACK_DPS:
                config_runs.setdefault(expectation.model['config'], {})[entry['key']] = run
    verdicts = []
    for parts in stack_parts.values():
        entry, run, expectation = parts[0]
        base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                       expectation.rank_id, expectation.check)
        if expectation.rule.startswith((UNMODELLED, UNREADABLE, AMBIGUOUS_TOOLTIP)):
            verdict = judge(manifest, entry, run, expectation, None, tooltips, hit_model)
            verdicts.append(replace(verdict, detail={**(verdict.detail or {}), **stack_detail(expectation.model)}))
        elif expectation.check == STACK_DPS:
            verdicts.append(judge_stack_dps(base, parts))
        elif expectation.check == STACK_SOURCE:
            verdicts.append(judge_stack_source(base, parts))
        else:
            verdicts.append(judge_talent_delta(manifest, parts, config_runs, tooltips))
    return verdicts


@dataclass(frozen=True)
class DeltaReading:
    name: str
    delta: float
    why: str


def delta_floor(metric: str) -> float:
    return FRACTIONAL_FLOOR if metric in FRACTIONAL_METRICS else ABSOLUTE_TOLERANCE


def delta_margin(metric: str, expected: float) -> float:
    floor = delta_floor(metric)
    if metric in DETERMINISTIC_STAT_METRICS:
        return floor
    return max(floor, RELATIVE_TOLERANCE * abs(expected))


def truncated(expected: float) -> float:
    return float(math.floor(expected + METRIC_DELTA_FLOAT_TOLERANCE))


def stat_reading_ok(metric: str, measured: float, expected: float) -> bool:
    if metric in PERCENT_PATH_METRICS:
        return abs(measured - truncated(expected)) <= FLOAT_EPSILON
    return abs(measured - expected) <= delta_margin(metric, expected) + FLOAT_EPSILON


def float32(value: float) -> float:
    return struct.unpack('f', struct.pack('f', value))[0]


def engine_percent_factor(percent: float) -> float:
    factor = float32(1.0)
    return float32(factor + float32(float32(factor * float32(percent)) / float32(100.0)))


def engine_percent_value(before: float, percent: float) -> float:
    return float32(float32(before) * engine_percent_factor(percent))


def engine_reading(before: float, percent: float) -> float:
    return float(math.trunc(engine_percent_value(before, percent)))


def delta_margin_rule(metric: str) -> str:
    floor = delta_floor(metric)
    if metric in PERCENT_PATH_METRICS:
        return (f'delta = the expected delta truncated to an integer, as the engine truncates the {metric} reading, '
                f'with no symmetric floor, no relative margin and no tolerated tier; one below only as a known '
                f'engine rounding that the float emulation reproduces')
    if metric in DETERMINISTIC_STAT_METRICS:
        return (f'|delta - expected| <= {floor:g}, the rounding of a deterministic {metric} reading, with no '
                f'relative margin and no tolerated tier')
    return f'|delta - expected| <= max({floor:g}, {RELATIVE_TOLERANCE:.1%} of expected)'


def delta_status(metric: str, measured: float, expected: float) -> str:
    if abs(measured) <= FLOAT_EPSILON < abs(expected):
        return 'alert'
    margin = delta_margin(metric, expected)
    if metric in DETERMINISTIC_STAT_METRICS:
        return 'ok' if stat_reading_ok(metric, measured, expected) else 'alert'
    return banded_status(measured, expected - margin, expected + margin, expected)


def question_detail(kind: str, question: str, readings: list[dict], measured: float | None, *, conditions: str = '',
                    observations: str = '') -> dict:
    detail = {'kind': kind, 'question': question, 'readings': readings, 'measured': measured}
    if conditions:
        detail['conditions'] = conditions
    if observations:
        detail['observations'] = observations
    return detail


def class_entry(manifest: dict, expectation: Expectation) -> dict:
    section = CLASS_ENTRIES.get(expectation.check)
    if section is None:
        return {}
    name, key = section
    source = (expectation.model or {}).get('source')
    candidates = [entry for entry in manifest['class_file'].get(name, []) if entry[key] == expectation.spell_id
                 and (expectation.check != TALENT_DELTA or entry['source'] == source)]
    if len(candidates) > 1 and expectation.check == PROC_CHECK:
        proc_spell = (expectation.model or {}).get('proc_spell')
        candidates = [entry for entry in candidates if entry.get('proc_spell') == proc_spell] or candidates
    return candidates[0] if candidates else {}


def entry_token(entry: str, description: str) -> str:
    if entry in description or ' [' not in entry:
        return entry
    return entry.rsplit(' [', 1)[0]


def sentence_with_blank(description: str, token: str) -> str:
    text = cleaned(description)
    position = text.find(token)
    if position < 0:
        return token
    starts = [match.end() for match in SENTENCE_END.finditer(text, 0, position)]
    end = SENTENCE_END.search(text, position + len(token))
    return (text[starts[-1] if starts else 0:position] + BLANK
            + text[position + len(token):end.end() if end else len(text)]).strip()


def tooltip_value_question(spell_name: str, level: int, entry: str, description: str) -> dict:
    token = entry_token(entry, cleaned(description))
    per_level = ', '.join(dict.fromkeys(PER_LEVEL_TOKEN.findall(token)))
    question = (f'The {spell_name} tooltip shows a number in "{sentence_with_blank(description, token)}" that '
                f'depends on {per_level}, a per-level value that the client data alone does not give. A log line of '
                f'{spell_name} at level {level} with known attack power and spell power, found in the reference '
                f'logs, pins the number in place of {BLANK}.')
    return question_detail(TOOLTIP_VALUE, question, [], None)


def data_issue_question(spell_name: str, entry: str, description: str) -> dict:
    token = entry_token(entry, cleaned(description))
    variables = ', '.join(dict.fromkeys(DESCRIPTION_VARIABLE.findall(token)))
    question = (f'The {spell_name} tooltip uses {variables} in "{sentence_with_blank(description, token)}", but the '
                f'client data of this spell defines no description variable (SpellDescriptionVariableID 0), so the '
                f'number cannot be computed from it. A log line of {spell_name} with known level, attack power and '
                f'spell power, found in the reference logs, shows the number (or confirms it is 0, blank or the '
                f'raw text) in place of {BLANK}.')
    return question_detail(DATA_ISSUE, question, [], None)


def unreadable_question(tooltips: TooltipSource, rank_id: int, spell_name: str, level: int, entry: str,
                        class_file: dict | None = None) -> dict | None:
    per_level = PER_LEVEL_TOKEN.search(entry)
    undefined = DESCRIPTION_VARIABLE.search(entry)
    if not per_level and not undefined:
        return None
    try:
        description = tooltips.spell_field(rank_id, 'Description[enUS]')
        description = description if isinstance(description, str) else ''
        if class_file is not None:
            token = entry_token(entry, cleaned(description))
            if reading_for(player_tooltip_readings(class_file), rank_id, token) is not None:
                return None
        if per_level:
            return tooltip_value_question(spell_name, level, entry, description)
        if not tooltips.spell_field(rank_id, 'SpellDescriptionVariableID'):
            return data_issue_question(spell_name, entry, description)
    except Unreadable:
        return None
    return None


def judge_proc_delta(manifest: dict, parts: list[ProcPart], tooltips: TooltipSource) -> Verdict:
    first_entry, first_run, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    labels = model['measurements']
    wanted = [labels['aura'], labels['baseline_trials'], labels['baseline_events'], labels['trials'],
             labels['events']]
    totals = dict.fromkeys(wanted[1:], 0.0)
    counted, without_aura, unmeasured = [], [], []
    for _, run, _ in parts:
        values = [run.values.get(label) for label in wanted]
        if None in values:
            unmeasured.append(f'{run.key} ({run.status}: {run.message})')
        elif values[0] <= 0:
            without_aura.append(run.key)
        else:
            counted.append(run.key)
            for label, value in zip(wanted[1:], values[1:]):
                totals[label] += value
    notes = f'{len(counted)} of {model["parts"]} parts'
    if without_aura:
        notes += f'; aura {expectation.spell_id} absent in {", ".join(without_aura)}'
    if unmeasured:
        notes += f'; no proc measurements in {", ".join(unmeasured)}'
    baseline_trials, baseline_events = totals[labels['baseline_trials']], totals[labels['baseline_events']]
    cumulative_trials, cumulative_events = totals[labels['trials']], totals[labels['events']]
    trials, events = cumulative_trials - baseline_trials, cumulative_events - baseline_events
    if baseline_trials <= 0 or trials <= 0:
        return replace(base, status='unmeasured', explanation=f'no usable trial in either phase ({notes})')
    p_baseline = baseline_events / baseline_trials
    p_main = events / trials
    try:
        caster = caster_stats_from(first_run.values, manifest['class_file'])
    except KeyError as error:
        return replace(base, explanation=f'base measurement {error} is missing from {first_run.key}')
    chance = chance_of(tooltips.read(expectation.rank_id, caster).values, expectation.displayed)
    if chance is None:
        return replace(base, explanation=f'the tooltip of {expectation.rank_id} no longer shows the chance token '
                                         f'{expectation.displayed}')
    if abs(chance - model['chance_pct']) > FLOAT_EPSILON:
        return replace(base, expected=chance / 100,
                       explanation=f'{expectation.displayed} shows {chance:g}%, generated as {model["chance_pct"]:g}%')
    expected = chance / 100
    if p_baseline <= 0:
        return replace(base, status='unmeasured', expected=expected,
                       explanation=f'no baseline events to compare against ({notes})')
    measured = p_main / p_baseline - 1
    se = math.sqrt(p_main * (1 - p_main) / trials + p_baseline * (1 - p_baseline) / baseline_trials)
    sanity_low, sanity_high = 0.0, DELTA_SANITY_FACTOR * expected
    if se <= 0:
        status = 'unmeasured'
        z = None
    else:
        z = (p_main - p_baseline) / se
        status = 'ok' if z >= Z_99 and sanity_low - FLOAT_EPSILON <= measured <= sanity_high + FLOAT_EPSILON \
            else 'alert'
    z_text = f'{z:.2f}' if z is not None else 'n/a'
    explanation = (f'baseline rate {p_baseline:.4f} ({baseline_events:g} in {baseline_trials:g}), with-aura rate '
                   f'{p_main:.4f} ({events:g} in {trials:g}), two-proportion z {z_text} (>= {Z_99:g} needed); '
                   f'measured chance {measured:+.4f}, tooltip {expected:g} ({notes})')
    return replace(base, status=status, measured=measured, expected=expected, low=sanity_low, high=sanity_high,
                   explanation=explanation)


def server_question(manifest: dict, expectation: Expectation, verdict: Verdict, tooltips: TooltipSource) -> Verdict:
    entry = class_entry(manifest, expectation)
    if verdict.status != 'alert' or not entry.get('question'):
        return verdict
    reading = {'name': 'as the tooltip says', 'expected': verdict.expected, 'measured': verdict.measured,
               'status': 'alert'}
    model = expectation.model or {}
    if 'observe_spell' in model and verdict.expected is not None and verdict.measured is not None:
        observed = f'applications of {spell_name(tooltips, model["observe_spell"])} ({model["observe_spell"]})'
        trial = TRIAL_WORDS.get(model['trial_metric'], model['trial_metric']).format(
            spell=spell_name(tooltips, model['trigger']['spell']))
        trials = verdict.expected / model['per_trigger'] if model['per_trigger'] else 0
        reading.update(expects=f'{verdict.expected:g} {observed} for {trials:g} {trial}',
                       measured_text=f'{verdict.measured:g} {observed}')
    return replace(verdict, detail={**(verdict.detail or {}), 'question': question_detail(
        SERVER_BEHAVIOUR, entry['question'], [reading], verdict.measured)})


def missing_measurement(run: Run, label: str) -> str:
    return f'no measurement {label!r} in {run.key} ({run.status}: {run.message})'


def undivided(token: Displayed) -> float:
    return token.value if token.kind == DURATION_KIND else token.value * token_divisor(token.text)


def signed_token(token: Displayed, points: float | None, tooltips: TooltipSource, rank_id: int) -> tuple[float, str]:
    value = undivided(token)
    if points is not None:
        return (math.copysign(value, points),
                f'{token.text} reads {token.value:g}, signed by the effect points {points:g}')
    plain = PLAIN_TOKEN.fullmatch(token.text)
    if plain:
        shown = displayed_points(tooltips, plain, rank_id)
        return value * plain_sign(shown), f'{token.text} reads {token.value:g}, signed by its Spell.dbc points {shown}'
    return value, f'{token.text} reads {token.value:g}'


def present_rows(manifest: dict, model: dict, run: Run, tooltips: TooltipSource) -> list[dict]:
    kind = MODIFIER_KINDS.get(model['metric'])
    school = tooltips.spell_field(model['target'], 'SchoolMask')
    return [row for row in manifest.get('known_modifiers', [])
            if row['applies_to'] == kind and row['school_mask'] & school
            and run.values.get(known_aura_label(row['spell_id']), 0) > 0]


def present_modifiers(manifest: dict, model: dict, run: Run, tooltips: TooltipSource,
                      aura: int | None = None) -> list[tuple[str, float]]:
    rows = present_rows(manifest, model, run, tooltips)
    if aura is not None:
        rows = [row for row in rows if row['aura'] == aura]
    return [(f'{known_label(row)} {row["percent"]:+d}%', float(row['percent'])) for row in rows]


def delta_readings(manifest: dict, run: Run, model: dict, before: float, value: float,
                   tooltips: TooltipSource) -> list[DeltaReading]:
    relation = model['relation']
    if relation in ('spell_mod_flat', 'add'):
        return [DeltaReading(relation, value, f'delta {value:+g}')]
    if relation in ('spell_mod_pct', 'scale', 'ratio'):
        return [DeltaReading(relation, before * value / 100, f'delta = before x {value:+g}%')]
    if relation == 'share':
        source = run.values[model['source_label']]
        return [DeltaReading(relation, source * value / 100,
                             f'delta = {model["source_label"]} {source:g} measured before the learn x {value:+g}%')]
    if relation == 'haste':
        return [DeltaReading('divides', before * 100 / (100 + value) - before, f'after = before / (1 {value:+g}%)')]
    if relation == 'crit_damage':
        if model.get('aura') == DIRECT_CRIT_DAMAGE_AURA:
            return [DeltaReading('whole', before * value / 100, f'the whole critical hit x (1 {value:+g}%)')]
        return [DeltaReading('bonus', (before - CRITICAL_DAMAGE_BASE) * value / 100,
                             f'the critical bonus above the fixed base {CRITICAL_DAMAGE_BASE} x (1 {value:+g}%)')]
    if relation == 'composition':
        readings = [DeltaReading(MULTIPLIES, before * value / 100,
                                 'the bonus multiplies the value, known modifiers included')]
        known = present_modifiers(manifest, model, run, tooltips, model.get('aura'))
        if known:
            stacked = sum(percent for _, percent in known)
            names = ', '.join(name for name, _ in known)
            readings.append(DeltaReading(ADDS, before * value / (100 + stacked),
                                         f'the bonus adds to the percents of {names}: before x {value:g} / (100 '
                                         f'{stacked:+g})'))
        return readings
    return []


def target_name(tooltips: TooltipSource, spell_id: int) -> str:
    return f'{tooltips.spell_field(spell_id, "SpellName[enUS]")} {spell_id}'


def same_group(model: dict, other: dict) -> bool:
    def without_spell(fields: dict) -> dict:
        return {key: value for key, value in fields.items() if key != 'spell'}

    return ((other['effect'], other['metric'], without_spell(other['fields']))
            == (model['effect'], model['metric'], without_spell(model['fields'])))


def target_group(entry: dict, model: dict) -> list[dict]:
    return [data['model'] for data in entry['expectations']
            if data['check'] == PASSIVE_DELTA and data['model'] and same_group(model, data['model'])]


def unmodelled_named_targets(entry: dict, model: dict) -> list[tuple[dict, str]]:
    return [(data['model'], data['rule']) for data in entry['expectations']
            if data['check'] == 'unmodelled' and data['model'] and data['model'].get('named')
            and same_group(model, data['model'])]


def interval_verdict(base: Verdict, metric: str, delta: float, judged: list[tuple[DeltaReading, str]],
                     context: str) -> Verdict:
    reading, status = judged[0]
    margin = delta_margin(metric, reading.delta)
    low, high = ((truncated(reading.delta),) * 2 if metric in PERCENT_PATH_METRICS
                 else (reading.delta - margin, reading.delta + margin))
    readings = '; '.join(f'{item.name} ({item.why}): expected delta {item.delta:+.6g}: {item_status}'
                         for item, item_status in judged)
    return replace(base, status=status, measured=delta, expected=reading.delta, low=low, high=high,
                   explanation=f'{context}; {readings}; {delta_margin_rule(metric)}')


def engine_rounding_verdict(base: Verdict, model: dict, before: float, delta: float, value: float,
                            reading: DeltaReading, context: str) -> Verdict | None:
    stated = truncated(reading.delta)
    if (model['metric'] not in PERCENT_PATH_METRICS or model['relation'] not in PERCENT_PATH_RELATIONS
            or abs(delta) <= FLOAT_EPSILON or abs(delta - (stated - 1)) > FLOAT_EPSILON):
        return None
    computed = engine_percent_value(before, value)
    if abs(engine_reading(before, value) - (before + delta)) > FLOAT_EPSILON:
        return None
    detail = {ENGINE_ROUNDING: computed}
    neighbours = [percent for percent in (value - 1, value + 1)
                  if abs(engine_reading(before, percent) - (before + delta)) <= FLOAT_EPSILON]
    if neighbours:
        detail[DATA_ONLY] = (f'the engine reading {before + delta:g} also follows from '
                             f'{" and ".join(f"{percent:+g}%" for percent in neighbours)}, so it does not tell the '
                             f'stated {value:+g}%')
    return replace(base, status='ok', measured=delta, expected=reading.delta, low=stated - 1, high=stated,
                   detail=detail,
                   explanation=f'{context}; {reading.name} ({reading.why}): expected delta {reading.delta:+.6g}: '
                               f'known engine rounding: AddPct builds the factor {engine_percent_factor(value)!r} in '
                               f'float, {before:g} x that factor is {computed!r} in float, truncated to '
                               f'{before + delta:g}, one below the stated {before + stated:g}')


def change(before: float, delta: float) -> str:
    return f'{100 * delta / before:+.4g}%' if before else f'{delta:+.6g}'


def passive_reading(model: dict, reading: DeltaReading, reference: DeltaReading, before: float, delta: float,
                    others: str) -> dict:
    after = before + reading.delta
    if model['metric'] == 'spell_critical_damage':
        expects = f'a critical hit deals {after / 10:.4g}% of a normal hit'
        measured = f'{(before + delta) / 10:.4g}%'
    else:
        expects = f'{change(before, reading.delta)} larger'
        measured = change(before, delta)
    meaning = RELATION_MEANINGS.get(reading.name, reading.why)
    if reading.name == ADDS:
        meaning = (f'the bonus is added to the other percent modifiers, here {others}, so it counts for '
                   f'{comparison_word(reading.delta, reference.delta)}: {change(before, reading.delta)} instead of '
                   f'{change(before, reference.delta)}')
    return {'name': reading.name, 'meaning': meaning, 'expects': expects, 'measured_text': measured}


def judge_readings(base: Verdict, manifest: dict, entry: dict, run: Run, model: dict,
                   judged: list[tuple[DeltaReading, str]], before: float, delta: float, context: str,
                   tooltips: TooltipSource) -> Verdict:
    statuses = {status for _, status in judged}
    if len(statuses) == 1:
        return interval_verdict(base, model['metric'], delta, judged, context)
    log_query = log_query_of(manifest, base.label)
    fallback = owner_fallback(statuses, log_query)
    if fallback == 'ok':
        applied = next(item for item in judged if item[1] == 'ok')
        verdict = interval_verdict(base, model['metric'], delta, [applied], context)
        return replace(verdict, explanation=f'owner fallback: logs queried ({log_query}) say nothing; the server '
                                            f'applies {applied[0].name} ({applied[0].why}), a reading the tooltip '
                                            f'permits; {verdict.explanation}')
    if fallback == 'alert':
        readings_text = '; '.join(f'{item.name} ({item.why}): expected delta {item.delta:+.6g}: {item_status}'
                                  for item, item_status in judged)
        return replace(base, status='alert', measured=delta, expected=judged[0][0].delta,
                       explanation=f'owner fallback: logs queried ({log_query}) say nothing; the server applies '
                                   f'neither reading; {context}; {readings_text}')
    spell = (tooltips.spell_field(model['target'], 'SpellName[enUS]') if model['target'] is not None
             else model['metric'])
    passive = entry['spell_name']
    subject = QUESTION_SUBJECTS.get(model['metric'], model['metric']).format(spell=spell)
    spread = hit_spread(tooltips, manifest['class_file'], model['target']) if model['target'] is not None else None
    noun = 'heals' if MODIFIER_KINDS.get(model['metric']) == 'heal' else 'hits'
    if model['metric'] == 'spell_critical_damage':
        needed, observations = hit_count(spread, [(before + reading.delta) / CRITICAL_DAMAGE_BASE
                                                  for reading, _ in judged], f'critical and normal {noun}',
                                         'of each kind')
        options = ' or '.join(f'{(before + reading.delta) / 10:.4g}%' for reading, _ in judged)
        record = (f'Record {needed} critical and {needed} normal {noun} of {spell}' if needed
                  else f'Record as many critical and normal {noun} of {spell} as you can')
        question = (f'With {passive} learned, does {subject} on a target dummy deal {options} of a normal hit '
                    f'({before / 10:.4g}% without it)? {record} on the same target dummy in a combat log and compare '
                    f'their averages.')
    else:
        needed, observations = hit_count(spread, [1 + reading.delta / before for reading, _ in judged] if before
                                         else [], f'non-critical {noun}')
        changes = ' or '.join(change(before, reading.delta) for reading, _ in judged)
        record = (f'Record {needed} non-critical {noun} of {spell} on the same target dummy without {passive} and '
                  f'{needed} with it' if needed else
                  f'Record as many non-critical {noun} of {spell} on the same target dummy as you can without '
                  f'{passive} and with it')
        question = (f'With {passive} learned, is {subject} {changes} larger than without it? {record}, in a combat '
                    f'log, and compare the averages.')
    others = ''
    conditions = (f'Our test: the level {manifest["level"]} test character learned only {passive} and measured '
                  f'{subject} on a target dummy before and after the learn.')
    if model['metric'] in MODIFIER_KINDS and model['target'] is not None:
        others = ', '.join(modifier_text(tooltips, row) for row in present_rows(manifest, model, run, tooltips))
        conditions += f' Other percent modifiers of that value on the test character: {others or "none"}.'
    reference = next((reading for reading, _ in judged if reading.name == MULTIPLIES), judged[0][0])
    readings = [{**passive_reading(model, reading, reference, before, delta, others),
                 'expected': before + reading.delta, 'delta': reading.delta, 'status': status,
                 'measured': before + delta} for reading, status in judged]
    text = '; '.join(f'{reading.name} ({reading.why}): expected delta {reading.delta:+.6g}: {status}'
                     for reading, status in judged)
    return replace(base, status='ambiguous_tooltip', measured=delta, expected=judged[0][0].delta,
                   explanation=f'the readings disagree; {context}; {text}',
                   detail={'question': question_detail(READINGS_QUESTION, question, readings, before + delta,
                                                       conditions=conditions, observations=observations)})


def mask_matches(manifest: dict, run: Run, entry: dict, model: dict, value: float,
                 tooltips: TooltipSource) -> list[tuple[dict, float, float, DeltaReading]]:
    return expected_movers(manifest, run, entry, model, value, tooltips, lambda other: other['in_mask'])


def namesake_matches(manifest: dict, run: Run, entry: dict, model: dict, value: float,
                     tooltips: TooltipSource) -> list[tuple[dict, float, float, DeltaReading]]:
    name = tooltips.spell_field(model['target'], 'SpellName[enUS]')
    return expected_movers(manifest, run, entry, model, value, tooltips,
                           lambda other: other['named'] and tooltips.spell_field(other['target'],
                                                                                 'SpellName[enUS]') == name)


def expected_movers(manifest: dict, run: Run, entry: dict, model: dict, value: float, tooltips: TooltipSource,
                    accepted: Callable[[dict], bool]) -> list[tuple[dict, float, float, DeltaReading]]:
    matches = []
    for other in target_group(entry, model):
        if other['target'] == model['target'] or not accepted(other):
            continue
        before, after = run.values.get(other['before_label']), run.values.get(other['after_label'])
        if before is None or after is None:
            continue
        readings = delta_readings(manifest, run, other, before, value, tooltips)
        if (readings and abs(readings[0].delta) > FLOAT_EPSILON
                and delta_status(other['metric'], after - before, readings[0].delta) == 'ok'):
            matches.append((other, before, after - before, readings[0]))
    return matches


def judge_modifier_target(base: Verdict, manifest: dict, entry: dict, run: Run, model: dict, value: float,
                          before: float, delta: float, judged: list[tuple[DeltaReading, str]], context: str,
                          tooltips: TooltipSource) -> Verdict:
    name = target_name(tooltips, model['target'])
    if not model['named'] and any(other['named'] for other in target_group(entry, model)):
        return replace(base, status=MEASURED, measured=delta, expected=judged[0][0].delta,
                       explanation=f'{context}; {name} is in the class mask but the tooltip names other spells: '
                                   f'reported, not judged')
    unmodelled = unmodelled_named_targets(entry, model)
    if not model['named'] and unmodelled:
        named = ', '.join(f'{target_name(tooltips, other["target"])} ({rule})' for other, rule in unmodelled)
        return replace(base, status='unmodelled', measured=delta, expected=judged[0][0].delta,
                       explanation=f'{context}; {name} is in the class mask but the tooltip names {named}, '
                                   f'unmodelled for this quantity: not judged')
    reading, status = judged[0]
    if status == 'ok' or model['in_mask']:
        return interval_verdict(base, model['metric'], delta, judged, context)
    namesakes = namesake_matches(manifest, run, entry, model, value, tooltips)
    if namesakes:
        others = ', '.join(target_name(tooltips, other['target']) for other, *_ in namesakes)
        return replace(base, status=MEASURED, measured=delta, expected=reading.delta,
                       explanation=f'{context}; {name} shares its name with {others}, which shows the expected '
                                   f'delta: a namesake the modifier does not reach, reported, not judged')
    matches = mask_matches(manifest, run, entry, model, value, tooltips)
    if not matches:
        verdict = interval_verdict(base, model['metric'], delta, judged, context)
        return replace(verdict, explanation=f'{verdict.explanation}; {name} is named outside the class mask and no '
                                            f'mask spell shows the expected delta')
    others = ', '.join(target_name(tooltips, other['target']) for other, *_ in matches)
    question = (f'{entry["spell_name"]} names {name}, but its modifier changed {model["metric"]} of {others} by '
                f'{reading.delta:+g} and of {name} by {delta:+g} here. A reference log with {entry["spell_name"]} '
                f'learned, showing whether {name} changes as the tooltip says, would settle it.')
    readings = [{'name': name, 'expected': before + reading.delta, 'delta': reading.delta, 'status': status,
                 'measured': before + delta}]
    readings += [{'name': target_name(tooltips, other['target']), 'expected': other_before + other_reading.delta,
                  'delta': other_reading.delta, 'status': 'ok', 'measured': other_before + other_delta}
                 for other, other_before, other_delta, other_reading in matches]
    return replace(base, status='ambiguous_tooltip', measured=delta, expected=reading.delta,
                   explanation=f'the tooltip names {name}, the modifier applies to {others}; {context}; '
                               f'{reading.name}: expected delta {reading.delta:+.6g}',
                   detail={'question': question_detail(TEXT_QUESTION, question, readings, before + delta)})


def count_power(model: dict, expected: float) -> str | None:
    if model.get('all_offered'):
        return None
    headroom = int(model.get('headroom', 0))
    if headroom >= 1:
        return None
    return (f'the scenario offers no candidate beyond the stated {expected:g}, so a server that reaches more would '
            f'read {expected:g} too')


def exact_count_verdict(base: Verdict, model: dict, measured: float, offered: int, detail: str) -> Verdict:
    expected = float(model['expected'])
    status = 'ok' if abs(measured - expected) <= FLOAT_EPSILON else 'alert'
    power = count_power(model, expected) if status == 'ok' else None
    scope = ('every offered candidate is stated' if model.get('all_offered') else
             f'{offered} candidate{"" if offered == 1 else "s"} offered for {expected:g} stated')
    explanation = (f'{detail}; {scope}; a count is compared exactly, and a measured 0 against a nonzero expected is '
                   f'always an alert')
    if power:
        return replace(base, status='insufficient_trials', measured=measured, expected=expected, low=expected,
                       high=expected, explanation=f'{explanation}; not judged: {power}')
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=explanation)


def per_cast_breadths(run: Run, per_cast: dict) -> list[int] | str:
    marks = []
    for labels in [per_cast['start'], *per_cast['casts']]:
        row = [run.values.get(label) for label in labels]
        missing = next((label for label, value in zip(labels, row) if value is None), None)
        if missing:
            return missing_measurement(run, missing)
        marks.append(row)
    return [sum(1 for before, after in zip(earlier[1:], later[1:]) if after - before > 0)
            for earlier, later in zip(marks, marks[1:]) if later[0] - earlier[0] > 0]


def per_cast_count_verdict(base: Verdict, model: dict, run: Run, offered: int, lead: str) -> Verdict:
    breadths = per_cast_breadths(run, model['per_cast'])
    if isinstance(breadths, str):
        return replace(base, explanation=breadths)
    casts = len(model['per_cast']['casts'])
    if not breadths:
        return replace(base, status='unmeasured',
                       explanation=f'{lead}; none of the {casts} casts hit the primary dummy, so no cast shows its '
                                   f'breadth')
    return exact_count_verdict(base, model, float(max(breadths)), offered,
                               f'{lead}; extra dummies hit per cast that hit the primary: {breadths} of {casts} '
                               f'casts, judged on the widest')


def behaviour_count_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before_hit, after_hit = [], []
    for before_label, after_label in model['dummy_labels']:
        before = run.values.get(before_label)
        after = run.values.get(after_label)
        if before is None or after is None:
            label = before_label if before is None else after_label
            return replace(base, explanation=missing_measurement(run, label))
        before_hit.append(before > 0)
        after_hit.append(after - before > 0)
    for start_label, end_label in model.get('primary_hits', []):
        start, end = run.values.get(start_label), run.values.get(end_label)
        if start is None or end is None:
            return replace(base, explanation=missing_measurement(run, start_label if start is None else end_label))
        if end - start != 1:
            return replace(base, status='unmeasured',
                           explanation=f'the primary dummy took {end - start:g} hits before the read ({end_label}), '
                                       f'not the one whose spread is counted')
    measured_before, measured_after = sum(before_hit), sum(after_hit)
    if measured_before:
        return replace(base, status='unmeasured', measured=float(measured_after - measured_before),
                       explanation=f'{measured_before} of {len(before_hit)} additional dummies were already hit '
                                   f'before the passive was learned; the delta cannot be isolated')
    lead = (f'{measured_before} of {len(before_hit)} additional dummies hit before the learn, {measured_after} '
            f'after')
    if model.get('per_cast'):
        return per_cast_count_verdict(base, model, run, len(after_hit), lead)
    return exact_count_verdict(base, model, float(measured_after), len(after_hit), lead)


def behaviour_fixed_count_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    hits = []
    for label in model['dummy_labels']:
        value = run.values.get(label)
        if value is None:
            return replace(base, explanation=missing_measurement(run, label))
        hits.append(value > 0)
    measured = float(sum(hits))
    far_label = model.get('far_label')
    far_detail = ''
    far_hit = False
    if far_label is not None:
        far_value = run.values.get(far_label)
        if far_value is None:
            return replace(base, explanation=missing_measurement(run, far_label))
        far_hit = far_value > 0
        far_detail = f'; beyond-radius dummy hit count {far_value:g} (must stay 0, proving the radius limit)'
    behind_label = model.get('behind_label')
    if behind_label is not None:
        behind_value = run.values.get(behind_label)
        if behind_value is None:
            return replace(base, explanation=missing_measurement(run, behind_label))
        far_hit = far_hit or behind_value > 0
        far_detail += (f'; dummy behind the caster, inside the radius, hit count {behind_value:g} (must stay 0, '
                       f'proving the facing)')
    lead = f'{int(measured)} of {len(hits)} additional dummies hit{far_detail}'
    placed = True
    if model.get('primary_distances'):
        distances = [run.values.get(label) for label in model['primary_distances']]
        missing = next((label for label, value in zip(model['primary_distances'], distances) if value is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        placed = all(distance < model['radius'] for distance in distances)
        lead += (f'; distances to the primary {", ".join(f"{distance:g}" for distance in distances)} yd (each must be '
                 f'under {model["radius"]:g})')
    pulled = True
    if model.get('pull'):
        pull = model['pull']
        readings = [[run.values.get(label) for label in pair] for pair in (*pull['near'], pull['far'])]
        missing = [label for pair in (*pull['near'], pull['far']) for label in pair if run.values.get(label) is None]
        if missing:
            return replace(base, explanation=missing_measurement(run, missing[0]))
        near, far = readings[:-1], readings[-1]
        pulled = (all(after <= before - pull['minimum_yd'] for before, after in near)
                  and abs(far[1] - far[0]) <= pull['still_yd'])
        lead += ('; distances to the caster before and after: '
                 + ', '.join(f'{before:g} to {after:g}' for before, after in near)
                 + f'; beyond the radius {far[0]:g} to {far[1]:g} (each one inside must close by at least '
                   f'{pull["minimum_yd"]:g} yd, the one beyond must move less than {pull["still_yd"]:g} yd)')
    verdict = (per_cast_count_verdict(base, model, run, len(hits), lead) if model.get('per_cast') else
               exact_count_verdict(base, model, measured, len(hits), lead))
    if (far_hit or not pulled or not placed) and verdict.status != 'unmeasured':
        return replace(verdict, status='alert')
    return verdict


PARTY_STAT_RATIO_TOLERANCE = 1e-4


def behaviour_party_stat_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    near_before = run.values.get(model['near_before_label'])
    near_after = run.values.get(model['near_after_label'])
    if near_before is None or near_after is None:
        return replace(base, explanation=missing_measurement(
            run, model['near_before_label'] if near_before is None else model['near_after_label']))
    if near_before <= 0:
        return replace(base, status='unmeasured', measured=near_after,
                       explanation=f'{model["near_before_label"]} measured {near_before:g}; a party stat ratio '
                                   f'check needs a positive baseline on the grouped ally')
    near_ratio = near_after / near_before
    expected = float(model['expected'])
    near_ok = abs(near_ratio - expected) <= PARTY_STAT_RATIO_TOLERANCE
    far_before_label, far_after_label = model.get('far_before_label'), model.get('far_after_label')
    far_detail = ''
    far_ok = True
    if far_before_label is not None:
        far_before = run.values.get(far_before_label)
        far_after = run.values.get(far_after_label)
        if far_before is None or far_after is None:
            return replace(base, explanation=missing_measurement(
                run, far_before_label if far_before is None else far_after_label))
        if far_before <= 0:
            return replace(base, status='unmeasured', measured=near_ratio,
                           explanation=f'{far_before_label} measured {far_before:g}; the out-of-radius ally needs '
                                       f'a positive baseline too')
        far_ratio = far_after / far_before
        far_ok = abs(far_ratio - 1.0) <= PARTY_STAT_RATIO_TOLERANCE
        far_detail = f'; out-of-radius ally ratio {far_ratio:g} (must stay at 1.0, within range it would move too)'
    status = 'ok' if near_ok and far_ok else 'alert'
    return replace(base, status=status, measured=near_ratio, expected=expected,
                   low=expected - PARTY_STAT_RATIO_TOLERANCE, high=expected + PARTY_STAT_RATIO_TOLERANCE,
                   explanation=f'{model["metric"]} on the grouped, non-caster ally measured {near_before:g} before '
                               f'the caster learned the passive and {near_after:g} after, ratio {near_ratio:g} '
                               f'against expected {expected:g}{far_detail}')


def behaviour_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    if before <= 0:
        return replace(base, status='unmeasured', measured=after,
                       explanation=f'{model["before_label"]} measured {before:g} before the learn; a ratio needs '
                                   f'a positive baseline')
    ratio = after / before
    expected_ratio = float(model['expected'])
    delta = after - before
    expected_delta = before * (expected_ratio - 1.0)
    status = delta_status(BEHAVIOUR_RATIO, delta, expected_delta)
    margin_ratio = delta_margin(BEHAVIOUR_RATIO, expected_delta) / before
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - margin_ratio,
                   high=expected_ratio + margin_ratio,
                   explanation=f'{model["target_name"]} healed {before:g} before and {after:g} after the learn, '
                               f'ratio {ratio:g}; measured delta {delta:+g} against expected delta '
                               f'{expected_delta:+g} of {model["before_label"]}, judged on the healing scale, not '
                               f'the ratio scale, and a measured 0 against a nonzero expected delta is always an '
                               f'alert')


def behaviour_leech_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    damage = run.values.get(model['damage_label'])
    heal = run.values.get(model['heal_label'])
    baseline_label = model.get('heal_baseline_label')
    baseline = run.values.get(baseline_label) if baseline_label else 0.0
    damage_baseline_label = model.get('damage_baseline_label')
    damage_baseline = run.values.get(damage_baseline_label) if damage_baseline_label else 0.0
    missing = next((label for label, value in ((model['damage_label'], damage), (model['heal_label'], heal),
                                               (baseline_label, baseline),
                                               (damage_baseline_label, damage_baseline)) if label and value is None),
                   None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    if damage_baseline_label:
        if damage_baseline <= 0:
            return replace(base, status='unmeasured', measured=baseline,
                           explanation=f'{damage_baseline_label} measured {damage_baseline:g}; the control cast must '
                                       f'land to show that it heals nothing')
        if abs(baseline) > FLOAT_EPSILON:
            return replace(base, status='alert', measured=baseline, expected=0.0, low=0.0, high=0.0,
                           explanation=f'the control cast without the auras healed {baseline:g} '
                                       f'({model["control_heal_label"]}), where nothing is stated')
        damage -= damage_baseline
    if damage <= 0:
        return replace(base, status='unmeasured', measured=heal,
                       explanation=f'{model["damage_label"]} measured {damage:g}; a ratio needs a positive damage '
                                   f'amount')
    actual_heal = heal - baseline
    ratio = actual_heal / damage
    expected_ratio = float(model['expected'])
    delta = actual_heal - damage
    expected_delta = damage * (expected_ratio - 1.0)
    status = delta_status(BEHAVIOUR_RATIO, delta, expected_delta)
    margin_ratio = delta_margin(BEHAVIOUR_RATIO, expected_delta) / damage
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - margin_ratio,
                   high=expected_ratio + margin_ratio,
                   explanation=f'{model["target_name"]} dealt {damage:g} and healed {actual_heal:g} ({heal:g} total '
                               f'minus a {baseline:g} baseline), ratio {ratio:g}; measured delta {delta:+g} against '
                               f'expected delta {expected_delta:+g} of {model["damage_label"]}, judged on the '
                               f'healing scale, not the ratio scale, and a measured 0 against a nonzero expected '
                               f'delta is always an alert')


def behaviour_stat_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    stat = run.values.get(model['stat_label'])
    amount = run.values.get(model['amount_label'])
    if stat is None or amount is None:
        return replace(base, explanation=missing_measurement(run, model['stat_label'] if stat is None
                                                              else model['amount_label']))
    if stat <= 0:
        return replace(base, status='unmeasured', measured=amount,
                       explanation=f'{model["stat_label"]} measured {stat:g}; a ratio needs a positive stat value')
    ratio = amount / stat
    expected_ratio = float(model['expected'])
    delta = amount - stat
    expected_delta = stat * (expected_ratio - 1.0)
    status = delta_status(BEHAVIOUR_RATIO, delta, expected_delta)
    margin_ratio = delta_margin(BEHAVIOUR_RATIO, expected_delta) / stat
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - margin_ratio,
                   high=expected_ratio + margin_ratio,
                   explanation=f'{model["target_name"]} applied an aura amount of {amount:g} against its own '
                               f'{model["stat_metric"]} of {stat:g}, ratio {ratio:g}; measured delta {delta:+g} '
                               f'against expected delta {expected_delta:+g} of {model["stat_label"]}, judged on '
                               f'the stat scale, not the ratio scale, and a measured 0 against a nonzero expected '
                               f'delta is always an alert')


def behaviour_trigger_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = (model['without_before_label'], model['without_after_label'],
             model['with_before_label'], model['with_after_label'])
    values = [run.values.get(label) for label in labels]
    if any(value is None for value in values):
        missing = next(label for label, value in zip(labels, values) if value is None)
        return replace(base, explanation=missing_measurement(run, missing))
    without_before, without_after, with_before, with_after = values
    without_delta = without_after - without_before
    with_delta = with_after - with_before
    expected = float(model['expected'])
    trigger_spell = model['trigger_spell']
    explanation = (f'without the passive: {without_delta:g} of {expected:g} breaks cast {trigger_spell} on the '
                   f'striker (expected 0); with the passive: {with_delta:g} of {expected:g} breaks cast it '
                   f'(expected >= {expected:g})')
    if without_delta > 0:
        return replace(base, status='alert', measured=without_delta, expected=0.0, explanation=explanation)
    if with_delta == 0:
        return replace(base, status='alert', measured=with_delta, expected=expected, explanation=explanation)
    status = 'ok' if with_delta >= expected else 'alert'
    return replace(base, status=status, measured=with_delta, expected=expected, explanation=explanation)


def behaviour_metric_delta_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    before_expected = float(model['before_expected'])
    expected = float(model['expected'])
    tolerance = float(model.get('tolerance', METRIC_DELTA_FLOAT_TOLERANCE))
    before_ok = abs(before - before_expected) <= tolerance
    at_least = model.get('after_at_least')
    after_ok = after >= float(at_least) if at_least is not None else abs(after - expected) <= tolerance
    expired_label = model.get('expired_label')
    expired, expired_ok, expired_explanation = None, True, ''
    if expired_label is not None:
        expired = run.values.get(expired_label)
        if expired is None:
            return replace(base, explanation=missing_measurement(run, expired_label))
        after_expiry_expected = float(model['after_expiry_expected'])
        expired_ok = abs(expired - after_expiry_expected) <= tolerance
        expired_explanation = (f'; {expired:g} once the triggering aura has actually expired (expected '
                               f'{after_expiry_expected:g}), ruling out the effect outliving its own aura')
    status = 'ok' if before_ok and after_ok and expired_ok else 'alert'
    after_text = f'at least {float(at_least):g}' if at_least is not None else f'{expected:g}'
    explanation = (f'{model["metric"]} measured {before:g} before the learn (expected '
                   f'{before_expected:g}) and {after:g} after (expected {after_text}); match within '
                   f'{tolerance:g} required' + expired_explanation)
    explanation += (', wide enough to absorb IEEE-754 float32 round-trip noise on a ratio metric '
                    '(observed ~1e-7) but far below any real defect in this family of checks, with no '
                    'combat-roll variance of its own') if tolerance <= METRIC_DELTA_FLOAT_TOLERANCE else (
                    ', an explicit per-entry tolerance wide enough to absorb this metric\'s own simulated-clock '
                    'tick jitter but far below the magnitude of any real defect this check would need to catch')
    low, high = (float(at_least), None) if at_least is not None else (expected - tolerance, expected + tolerance)
    return replace(base, status=status, measured=after, expected=expected, low=low, high=high,
                   explanation=explanation)


def stat_gain_arm_labels(arm: dict) -> list[str]:
    reads = arm.get(STAT_GAIN_ATTRIBUTION)
    if not reads:
        return []
    return [*(label for moment in ('before', 'after') for _, label in reads[moment]['auras']),
            reads['before']['count'], reads['after']['count'], reads['before']['casts'], reads['after']['casts'],
            reads[STAT_GAIN_RETURN]]


def stat_gain_attributed(run: Run, model: dict) -> tuple[bool, dict, list[str]]:
    attribution = model[STAT_GAIN_ATTRIBUTION]
    held, applied, notes, others_seen = True, {}, [], set()
    for arm in model['arms']:
        reads = arm[STAT_GAIN_ATTRIBUTION]
        before = {aura: run.values[label] for aura, label in reads['before']['auras']}
        after = {aura: run.values[label] for aura, label in reads['after']['auras']}
        listed = [aura for aura in after if before[aura] < 0.5 <= after[aura]]
        applied[arm['name']] = listed
        appeared = run.values[reads['after']['count']] - run.values[reads['before']['count']]
        start, back = run.values[arm['before']], run.values[reads[STAT_GAIN_RETURN]]
        others = [aura for aura in listed if aura not in attribution['auras']]
        others_seen.update(others)
        landed = run.values[reads['after']['casts']] - run.values[reads['before']['casts']]
        failures = [*([f'the cast did not land ({landed:g} casts counted)'] if landed < 0.5 else []),
                    *(f'{aura} not read absent before the cast' for aura in attribution['auras']
                      if before[aura] >= 0.5),
                    *(f'{aura} not read present after it' for aura in attribution['auras']
                      if after[aura] < 0.5 and arm['name'] != attribution['withheld_arm']),
                    *([f'{appeared:g} auras appeared, {len(listed)} listed'] if abs(appeared - len(listed)) > 0.5
                      else []),
                    *([f'other auras {others} and no arm without {attribution["spell"]}']
                      if others and not attribution['withheld_arm'] else []),
                    *([f'returned to {back:g}, not {start:g}']
                      if abs(back - start) > METRIC_DELTA_FLOAT_TOLERANCE else [])]
        held = held and not failures
        notes.append(f'{arm["name"]}: {landed:g} cast landed, applied {listed}, {model["metric"]} back to {back:g} '
                     f'from {start:g}'
                     + (f' ({"; ".join(failures)})' if failures else ''))
    control = attribution['withheld_arm']
    unshown = sorted(others_seen - set(applied.get(control, ()))) if control else []
    if unshown:
        held = False
        notes.append(f'other auras {unshown} do not appear in the {control} arm')
    return held, applied, notes


def behaviour_stat_gain_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    parts, failed, first = [], False, None
    for arm in model['arms']:
        labels = [arm['before'], arm['after'], *(label for term in arm['terms'] for label in term),
                  *stat_gain_arm_labels(arm)]
        missing = next((label for label in labels if run.values.get(label) is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        gain = run.values[arm['after']] - run.values[arm['before']]
        if arm['gain'] is not None:
            low = high = expected = float(arm['gain'])
            stated = f'{expected:g}'
        else:
            expected = sum(coefficient * sum(run.values[label] for label in term)
                           for coefficient, term in zip(model['coefficients'], arm['terms']))
            low = high = math.floor(expected + FLOAT_EPSILON)
            stated = f'{expected:g} from the stats read, truncated to {low:g}'
        held = low - METRIC_DELTA_FLOAT_TOLERANCE <= gain <= high + METRIC_DELTA_FLOAT_TOLERANCE
        failed = failed or not held
        if first is None and arm['gain'] is None:
            first = (gain, expected, low, high)
        parts.append(f'{arm["name"]}: {model["metric"]} gained {gain:g}, expected {stated}: '
                     f'{"held" if held else "missed"}')
    gain, expected, low, high = first
    contrast, detail = CONDITION_CONTRAST, {}
    if STAT_GAIN_ATTRIBUTION in model:
        held, applied, notes = stat_gain_attributed(run, model)
        parts += [*notes, f'{model["metric"]} read through {model[STAT_GAIN_ATTRIBUTION]["read"]}']
        contrast = LEARNED_CONTRAST if held and not failed else CONDITION_CONTRAST
        detail = {'applied_auras': applied, 'read': model[STAT_GAIN_ATTRIBUTION]['read']}
    return replace(base, status='alert' if failed else 'ok', measured=gain, expected=expected, low=low, high=high,
                   explanation='; '.join(parts), detail={**(base.detail or {}), **detail, CONTRAST: contrast})


def behaviour_heal_block_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    blocked = bool(model['blocked'])
    expected = 1.0 if blocked else 0.0
    before_ok = abs(before - 0.0) <= METRIC_DELTA_FLOAT_TOLERANCE
    after_ok = abs(after - expected) <= METRIC_DELTA_FLOAT_TOLERANCE
    status = 'ok' if before_ok and after_ok else 'alert'
    requirement = ('the heal-block aura must be present after the cast' if blocked
                   else 'the heal-block aura must stay absent after the cast')
    return replace(base, status=status, measured=after, expected=expected, low=expected, high=expected,
                   explanation=f'aura measured {before:g} before the cast (expected 0) and {after:g} after '
                               f'(expected {expected:g}); {requirement}')


def tick_count_words(ticks: int) -> str:
    return 'one periodic tick' if ticks == 1 else f'{ticks} periodic ticks'


def behaviour_metric_ratio_delta_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    if before <= 0:
        return replace(base, status='unmeasured', measured=after,
                       explanation=f'{model["before_label"]} measured {before:g}; a ratio needs a positive '
                                   f'baseline (the caster never built any threat on the dummy)')
    ratio = after / before
    expected_ratio = float(model['expected_ratio'])
    tolerance = float(model['tolerance'])
    application = cast_application(run, model)
    if application is not None and application[0] is None:
        return replace(base, explanation=application[1])
    applied = application is None or application[0]
    status = 'ok' if applied and abs(ratio - expected_ratio) <= tolerance else 'alert'
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - tolerance,
                   high=expected_ratio + tolerance,
                   explanation=f'{model["metric"]} measured {before:g} before {model["before_label"]!r} and '
                               f'{after:g} after {tick_count_words(model.get("ticks", 1))} '
                               f'{model["after_label"]!r}, ratio {ratio:g}; '
                               f'expected {expected_ratio:g} within {tolerance:g}, a ratio rather than an '
                               f'absolute value since the baseline a real attack sequence builds is not '
                               f'deterministic' + ('' if application is None else f'; {application[1]}'))


def cast_application(run: Run, model: dict) -> tuple[bool | None, str] | None:
    if 'aura_before_label' not in model:
        return None
    before_label, after_label = model['aura_before_label'], model['aura_after_label']
    before = run.values.get(before_label)
    after = run.values.get(after_label)
    if before is None or after is None:
        return None, missing_measurement(run, before_label if before is None else after_label)
    applied = before == 0 and after != 0
    words = 'applied by the cast' if applied else 'not shown applied by the cast'
    return applied, (f'aura {words}: {before_label!r} {before:g} (absent expected) and {after_label!r} {after:g} '
                     f'(present expected)')


def behaviour_absorb_pierce_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = (model['zero_label'], model['unshielded_label'], model['shielded_label'],
             model['shield_before_label'], model['shield_after_label'])
    values = [run.values.get(label) for label in labels]
    if any(value is None for value in values):
        missing = next(label for label, value in zip(labels, values) if value is None)
        return replace(base, explanation=missing_measurement(run, missing))
    zero, unshielded, shielded, shield_before, shield_after = values
    unshielded_delta = unshielded - zero
    shielded_delta = shielded - unshielded
    expected_ratio = float(model['expected_ratio'])
    tolerance = float(model['tolerance'])
    if unshielded_delta <= 0:
        return replace(base, status='unmeasured', measured=shielded_delta,
                       explanation=f'{model["unshielded_label"]} measured a damage delta of {unshielded_delta:g} '
                                   f'against the unshielded dummy; a ratio needs a positive baseline hit')
    ratio = shielded_delta / unshielded_delta
    shield_untouched = shield_after == shield_before
    status = 'ok' if abs(ratio - expected_ratio) <= tolerance and shield_untouched else 'alert'
    explanation = (f'damage dealt to the dummy measured {unshielded_delta:g} unshielded and {shielded_delta:g} '
                   f'with {model["shield_before_label"]!r} shielding it, ratio {ratio:g} against expected '
                   f'{expected_ratio:g} within {tolerance:g}; the shield\'s own aura_amount measured '
                   f'{shield_before:g} before the shielded cast and {shield_after:g} after it '
                   f'({"untouched" if shield_untouched else "consumed, contradicting the piercing claim"})')
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - tolerance,
                   high=expected_ratio + tolerance, explanation=explanation)


def behaviour_duration_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    crits = run.values.get(model['count_label'])
    missing = next((label for label, value in ((model['before_label'], before), (model['after_label'], after),
                                               (model['count_label'], crits)) if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    if crits != 1:
        return replace(base, status='unmeasured', measured=crits,
                       explanation=f'{model["count_label"]} measured {crits:g} forced crits; the forcing '
                                   f'assumption (a maxed melee_crit_rating guarantees a logged critical hit) did '
                                   f'not hold, so the duration delta cannot be attributed to a crit')
    measured = before - after
    expected = model['wait_ms'] + model['expected_ms']
    overshoot = run.max_step_ms or 0.0
    low = expected - CAST_MARGIN_MS
    high = expected + overshoot
    status = 'ok' if low - FLOAT_EPSILON <= measured <= high + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   explanation=f'{model["before_label"]} measured {before:g} ms, {model["after_label"]} measured '
                               f'{after:g} ms, a loss of {measured:g} ms over one forced crit swing; expected at '
                               f'least the wait ({model["wait_ms"]:g} ms) plus {model["expected_ms"]:g} ms, plus up '
                               f'to {overshoot:g} ms of the wait step\'s own tick overshoot (run.max_step_ms), '
                               f'never less than the wait and never more than that sum plus the overshoot')


def behaviour_duration_ratio_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    if before <= 0:
        return replace(base, status='unmeasured', measured=after,
                       explanation=f'{model["before_label"]} measured {before:g} ms; a duration ratio needs a '
                                   f'positive baseline')
    ratio = after / before
    expected_ratio = float(model['expected'])
    delta = after - before
    expected_delta = before * (expected_ratio - 1.0)
    overshoot = run.max_step_ms or 0.0
    settle_window_jitter_margin = CAST_MARGIN_MS + overshoot
    status = 'alert' if abs(delta) <= FLOAT_EPSILON < abs(expected_delta) \
        else 'ok' if abs(delta - expected_delta) <= settle_window_jitter_margin + FLOAT_EPSILON else 'alert'
    margin_ratio = settle_window_jitter_margin / before
    return replace(base, status=status, measured=ratio, expected=expected_ratio, low=expected_ratio - margin_ratio,
                   high=expected_ratio + margin_ratio,
                   explanation=f'{model["vehicle_spell"]} aura_duration_ms measured {before:g} ms before and '
                               f'{after:g} ms after {model["target_name"]} was learned, ratio {ratio:g}; measured '
                               f'delta {delta:+g} ms against expected delta {expected_delta:+g} ms of '
                               f'{model["before_label"]}, within a margin of {settle_window_jitter_margin:g} ms '
                               f'({overshoot:g} ms of it the run\'s own tick overshoot, run.max_step_ms), and a '
                               f'measured 0 against a nonzero expected delta is always an alert')


def behaviour_duration_refresh_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = ('without_before_label', 'without_after_label', 'with_before_label', 'with_after_label')
    values = {label: run.values.get(model[label]) for label in labels}
    missing = next((model[label] for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    without_before, without_after = values['without_before_label'], values['without_after_label']
    with_before, with_after = values['with_before_label'], values['with_after_label']
    full_duration = model['full_duration_ms']
    margin = model['refresh_margin_ms']
    without_ok = without_after <= without_before + FLOAT_EPSILON
    with_ok = with_after >= full_duration - margin - FLOAT_EPSILON
    status = 'ok' if without_ok and with_ok else 'alert'
    measured = with_after
    low = full_duration - margin
    return replace(base, status=status, measured=measured, expected=full_duration, low=low, high=full_duration,
                   explanation=f'without the passive: {without_before:g} ms before the breaker cast, '
                               f'{without_after:g} ms after (must not increase); with the passive learned: '
                               f'{with_before:g} ms before, {with_after:g} ms after (must return to within '
                               f'{margin:g} ms of the {full_duration:g} ms full duration, SpellDuration.dbc); '
                               f'a without-phase increase or a with-phase shortfall is always an alert')


def behaviour_amount_delta_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = ('without_before_label', 'without_after_label', 'with_before_label', 'with_after_label')
    values = {label: run.values.get(model[label]) for label in labels}
    missing = next((model[label] for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    without_before, without_after = values['without_before_label'], values['without_after_label']
    with_before, with_after = values['with_before_label'], values['with_after_label']
    percent = round(float(model['fraction']) * 100)
    with_expected = with_before - (int(with_before) * percent) // 100
    without_ok = abs(without_after - without_before) <= FLOAT_EPSILON
    with_ok = abs(with_after - with_expected) <= FLOAT_EPSILON
    status = 'ok' if without_ok and with_ok else 'alert'
    return replace(base, status=status, measured=with_after, expected=with_expected, low=with_expected,
                   high=with_expected,
                   explanation=f'without the passive: {without_before:g} before the cast, {without_after:g} after '
                               f'(must be unchanged); with the passive learned: {with_before:g} before, '
                               f'{with_after:g} after (expected {with_expected:g}, a truncating {percent}% '
                               f'reduction of the before amount); a without-phase change or a with-phase mismatch '
                               f'is always an alert')


def behaviour_crit_guarantee_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    crit = run.values.get(model['crit_label'])
    noncrit = run.values.get(model['noncrit_label'])
    if crit is None or noncrit is None:
        return replace(base, explanation=missing_measurement(run, model['crit_label'] if crit is None
                                                              else model['noncrit_label']))
    total = crit + noncrit
    minimum = model['minimum_events']
    if total < minimum:
        return replace(base, status='insufficient_trials', measured=total,
                       explanation=f'{model["crit_label"]} + {model["noncrit_label"]} measured {total:g} '
                                   f'triggered hits of {model["trial_spell"]} against {model["target_name"]}, '
                                   f'fewer than the {minimum:g} needed to judge the crit guarantee')
    ratio = crit / total
    status = banded_status(ratio, 1.0, 1.0, 1.0)
    verdict = replace(base, status=status, measured=ratio, expected=1.0, low=1.0, high=1.0,
                      explanation=f'{crit:g} critical of {total:g} {model["trial_spell"]} hits against '
                                  f'{model["target_name"]} ({model["creature_type_source"]}); every triggered hit '
                                  f'must critically strike ({model["quote"]!r}); a ratio below 1.0 is tolerated '
                                  f'within {TOLERATED_RELATIVE:.0%} of 1.0, otherwise alert')
    if 'control_crit_label' not in model or verdict.status not in ('ok', 'tolerated'):
        return verdict
    control_crit = run.values.get(model['control_crit_label'])
    control_noncrit = run.values.get(model['control_noncrit_label'])
    if control_crit is None or control_noncrit is None:
        return replace(base, explanation=missing_measurement(run, model['control_crit_label'] if control_crit is
                                                              None else model['control_noncrit_label']))
    control_total = control_crit + control_noncrit
    if control_total < minimum:
        return replace(verdict, status='insufficient_trials', measured=control_total,
                       explanation=verdict.explanation + f'; {model["control_crit_label"]} + '
                                   f'{model["control_noncrit_label"]} measured only {control_total:g} triggered '
                                   f'hits against {model["control_target_name"]}, fewer than the {minimum:g} '
                                   f'needed to judge the specificity control')
    control_ratio = control_crit / control_total
    if control_ratio >= model['control_max_ratio']:
        verdict = replace(verdict, status='alert', measured=control_ratio, expected=model['control_max_ratio'],
                          explanation=verdict.explanation +
                          f'; {control_crit:g} of {control_total:g} {model["trial_spell"]} hits against '
                          f'{model["control_target_name"]} were also critical (ratio {control_ratio:.2f}, at or '
                          f'above the {model["control_max_ratio"]:.0%} specificity ceiling): the guarantee is not '
                          f'specific to {model["target_name"]}, {model["quote"]!r}')
    return verdict


def behaviour_aura_grant_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = ('before_label', 'after_label', 'oath_label')
    values = {label: run.values.get(model[label]) for label in labels}
    missing = next((model[label] for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    before, after, oath = values['before_label'], values['after_label'], values['oath_label']
    delta = after - before
    expected = model['expected']
    status = 'ok' if delta == expected and oath >= 1 else 'alert'
    return replace(base, status=status, measured=delta, expected=expected, low=expected, high=expected,
                   explanation=f'{model["chain_aura"]} aura_stacks measured {before:g} before the cast and '
                               f'{after:g} after (delta {delta:+g}, expected +{expected:g}); {model["oath_aura"]} '
                               f'aura present after the cast: {bool(oath)}; a delta other than +{expected:g} or a '
                               f'missing Oath aura is always an alert ({model["quote"]!r})')


def behaviour_oath_consumption_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = ('before_label', 'after_label', 'stacks_label')
    values = {label: run.values.get(model[label]) for label in labels}
    missing = next((model[label] for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    before, after, stacks = values['before_label'], values['after_label'], values['stacks_label']
    delta = after - before
    expected = float(model['expected'])
    expected_delta = before * (expected - 1.0) if model['relation'] == 'ratio' else expected
    verdict = deterministic(base, delta, delta, expected_delta,
                            f'{model["metric"]} measured {before:g} before {model["oath_spell"]} was fixtured to '
                            f'1 stack and {after:g} after (delta {delta:+g}), both deterministic formula reads '
                            f'with no combat roll; expected delta {expected_delta:+g} from {model["oath_spell"]}\'s '
                            f'own Spell.dbc SpellMod effect ({model["relation"]} {expected:g})')
    if stacks != 0 and verdict.status in ('ok', 'tolerated'):
        verdict = replace(verdict, status='alert',
                          explanation=verdict.explanation + f'; {model["stacks_label"]} measured {stacks:g} after '
                                      f'actually casting the trigger spell (expected 0: the Oath must be consumed, '
                                      f'not just read, {model["quote"]!r})')
    if model.get('other_oath_spell') and verdict.status in ('ok', 'tolerated'):
        other_labels = ('other_alone_label', 'both_label', 'other_stacks_label')
        other_values = {label: run.values.get(model[label]) for label in other_labels}
        other_missing = next((model[label] for label, value in other_values.items() if value is None), None)
        if other_missing:
            return replace(base, explanation=missing_measurement(run, other_missing))
        other_alone, both, other_stacks = (other_values['other_alone_label'], other_values['both_label'],
                                           other_values['other_stacks_label'])
        other_delta = other_alone - before
        if model['relation'] == 'ratio':
            expected_both = after * other_alone / before if before else before
            combine_why = (f'both Oaths\' own ratio multipliers over the no-Oath baseline compound '
                           f'({after:g}/{before:g} * {other_alone:g}/{before:g})')
        else:
            expected_both = before + delta + other_delta
            combine_why = 'both Oaths\' own flat deltas over the no-Oath baseline sum'
        expected_both_delta = expected_both - before
        both_delta = both - before
        margin = margin_of(expected_both_delta)
        both_status = banded_status(both_delta, expected_both_delta - margin, expected_both_delta + margin,
                                    expected_both_delta)
        if both_status == 'alert':
            verdict = replace(verdict, status='alert', measured=both_delta, expected=expected_both_delta,
                              explanation=verdict.explanation +
                              f'; holding both {model["oath_spell"]} and {model["other_oath_spell"]} together '
                              f'measured {model["metric"]} delta {both_delta:+g}, not what {combine_why} predicts '
                              f'({expected_both_delta:+g}): "for each consumed" is not additive across distinct '
                              f'Oaths ({model["quote"]!r})')
        elif both_status == 'tolerated' and verdict.status == 'ok':
            verdict = replace(verdict, status='tolerated', measured=both_delta, expected=expected_both_delta,
                              explanation=verdict.explanation +
                              f'; the combined delta {both_delta:+g} deviates from what {combine_why} predicts '
                              f'{expected_both_delta:+g} by more than the usual band but within '
                              f'{TOLERATED_RELATIVE:.0%}: tolerated')
        if other_stacks != 0 and verdict.status in ('ok', 'tolerated'):
            verdict = replace(verdict, status='alert',
                              explanation=verdict.explanation +
                              f'; {model["other_stacks_label"]} measured {other_stacks:g} after actually casting '
                              f'the trigger spell (expected 0: every held Oath must be consumed, not just '
                              f'{model["oath_spell"]}, {model["quote"]!r})')
    return verdict


def behaviour_oath_consumption_removal_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    amount_labels = model['amount_labels']
    amounts = [run.values.get(label) for label in amount_labels]
    missing = next((label for label, value in zip(amount_labels, amounts) if value is None), None)
    if missing is None:
        missing = next((label for label in (model['script_label'], *model['before_removal_labels'],
                                            *model['after_removal_labels']) if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    script = run.values[model['script_label']]
    before_removal = [run.values[label] for label in model['before_removal_labels']]
    after_removal = [run.values[label] for label in model['after_removal_labels']]
    expected = sum(amounts)
    verdict = deterministic(base, script, script, expected,
                            f'{model["oath_spells"]}\'s own aura_amount readings ({amounts}) sum to {expected:g}; '
                            f'{model["script_label"]} measured {script:g} right after the cast')
    held_wrong = [label for label, stacks in zip(model['before_removal_labels'], before_removal) if stacks != 1]
    removed_wrong = [label for label, stacks in zip(model['after_removal_labels'], after_removal) if stacks != 0]
    if (held_wrong or removed_wrong) and verdict.status in ('ok', 'tolerated'):
        verdict = replace(verdict, status='alert',
                          explanation=verdict.explanation +
                          f'; aura_stacks while held {dict(zip(model["before_removal_labels"], before_removal))} '
                          f'(every Oath must still read 1, not consumed by the cast itself), after the lifecycle '
                          f'aura expired {dict(zip(model["after_removal_labels"], after_removal))} (every Oath must '
                          f'read 0, consumed only on removal): {model["quote"]!r}')
    return verdict


def behaviour_internal_cooldown_gate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = ('after1_label', 'after2_label', 'after3_label')
    values = {label: run.values.get(model[label]) for label in labels}
    missing = next((model[label] for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    after1, after2, after3 = values['after1_label'], values['after2_label'], values['after3_label']
    icd = model['internal_cooldown_ms']
    blocked_delta = after2 - after1
    if blocked_delta != 0:
        return replace(base, status='alert', measured=blocked_delta, expected=0.0, low=0.0, high=0.0,
                       explanation=f'{model["after2_label"]} fired {blocked_delta:+g} times {model["short_gap_ms"]} '
                                   f'ms after the first cast, before its own {icd:g} ms internal cooldown elapsed '
                                   f'({model["quote"]!r})')
    reopened_delta = after3 - after2
    status = 'ok' if reopened_delta == 1 else 'alert'
    return replace(base, status=status, measured=reopened_delta, expected=1.0, low=1.0, high=1.0,
                   explanation=f'no event between the first and second cast ({model["short_gap_ms"]} ms apart, '
                               f'inside the {icd:g} ms internal cooldown); {reopened_delta:+g} event(s) between '
                               f'the second and third ({model["reopen_gap_ms"]} ms apart, {icd:g} ms internal '
                               f'cooldown plus margin) ({model["quote"]!r})')
def behaviour_exclusivity_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    removed = run.values.get(model['removed_label'])
    kept = run.values.get(model['kept_label'])
    if removed is None or kept is None:
        return replace(base, explanation=missing_measurement(run, model['removed_label'] if removed is None
                                                              else model['kept_label']))
    removed_ok = abs(removed - 0.0) <= FLOAT_EPSILON
    kept_ok = abs(kept - 1.0) <= FLOAT_EPSILON
    status = 'ok' if removed_ok and kept_ok else 'alert'
    return replace(base, status=status, measured=removed, expected=0.0, low=0.0, high=0.0,
                   explanation=f'{model["removed_spell"]} aura measured {removed:g} (expected 0) after casting '
                               f'{model["kept_spell"]}, whose own aura measured {kept:g} (expected 1); a nonzero '
                               f'read on the previous member or a zero read on the newly cast member is always an '
                               f'alert')


def behaviour_single_target_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    first = run.values.get(model['first_label'])
    removed = run.values.get(model['removed_label'])
    second = run.values.get(model['second_label'])
    missing = next((model[key] for key, value in (
        ('first_label', first), ('removed_label', removed), ('second_label', second)) if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    first_ok = abs(first - 1.0) <= FLOAT_EPSILON
    removed_ok = abs(removed - 0.0) <= FLOAT_EPSILON
    second_ok = abs(second - 1.0) <= FLOAT_EPSILON
    status = 'ok' if first_ok and removed_ok and second_ok else 'alert'
    return replace(base, status=status, measured=removed, expected=0.0, low=0.0, high=0.0,
                   explanation=f'first ally\'s aura measured {first:g} after the first cast (expected 1) and '
                               f'{removed:g} after the second cast onto a different ally (expected 0, removed); '
                               f'the second ally\'s aura measured {second:g} after that second cast (expected 1); '
                               f'any of these three readings missing its expected value is always an alert')


INVERSE_RELATION = 'inverse'


def behaviour_group_stack_cap_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    baseline = run.values.get(model['baseline_label'])
    own = run.values.get(model['own_label'])
    combined = run.values.get(model['combined_label'])
    missing = next((model[key] for key, value in (
        ('baseline_label', baseline), ('own_label', own), ('combined_label', combined)) if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    own_pct, partner_pct = model['own_pct'], model['partner_pct']
    personal_pct = model.get('personal_pct', 0.0)
    mechanism = model.get('mechanism', 'spell_group')
    mechanism_phrase = ('same spell_group SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT membership' if
                        mechanism == 'spell_group' else "the same aura type's global cap, no spell_group needed")
    cap_pct = strongest_percent(own_pct, partner_pct)
    own_factor = (1 + own_pct / 100) * (1 + personal_pct / 100)
    combined_factor = (1 + cap_pct / 100) * (1 + personal_pct / 100)
    inverse = model.get('relation') == INVERSE_RELATION
    own_expected = baseline / own_factor if inverse else baseline * own_factor
    combined_expected = baseline / combined_factor if inverse else baseline * combined_factor
    tolerance = model.get('tolerance')
    own_margin = tolerance if tolerance is not None else delta_margin(model.get('metric', ''), own_expected)
    combined_margin = tolerance if tolerance is not None else delta_margin(model.get('metric', ''),
                                                                           combined_expected)
    own_ok = abs(own - own_expected) <= own_margin
    combined_ok = abs(combined - combined_expected) <= combined_margin
    status = 'ok' if own_ok and combined_ok else 'alert'
    return replace(base, status=status, measured=combined, expected=combined_expected,
                   low=combined_expected - combined_margin, high=combined_expected + combined_margin,
                   explanation=f'baseline {baseline:g}; after learning the own passive alone, measured {own:g} '
                               f'against expected {own_expected:g} ({own_pct:+g}%, +/-{own_margin:g}); after also '
                               f'learning the partner ({partner_pct:g}%, {mechanism_phrase}), measured {combined:g} '
                               f'against expected {combined_expected:g} (capped at the stronger {cap_pct:+g}%, '
                               f'+/-{combined_margin:g}); a combined reading that reflects the sum of both '
                               f'percentages instead of their cap is always an alert'
                               + (f'; the metric is a time between events, so each percent divides it'
                                  if inverse else ''))


def behaviour_crit_magnitude_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    attempts = run.values.get(model['attempts_label'])
    crits = run.values.get(model['crits_label'])
    total = run.values.get(model['total_label'])
    missing = next((label for label, value in ((model['attempts_label'], attempts), (model['crits_label'], crits),
                                                (model['total_label'], total)) if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    expected = attempts * model['base_expected'] + crits * model['crit_bonus_expected']
    status = 'ok' if abs(total - expected) <= FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=total, expected=expected, low=expected, high=expected,
                   explanation=f'{model["metric"]} measured {total:g} over {attempts:g} forced-crit melee '
                               f'attempts of which {crits:g} landed as a critical hit; expected {attempts:g} x '
                               f'{model["base_expected"]:g} plus {crits:g} x {model["crit_bonus_expected"]:g} = '
                               f'{expected:g}')


def behaviour_charge_recharge_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [model['initial_label'], *model['attempt_labels'], model['overcast_label'],
             model['cast_failure_label'], model['before_recharge_label'], model['after_recharge_label']]
    values = {label: run.values.get(label) for label in labels}
    missing = next((label for label, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    max_charges = int(model['max_charges'])
    initial = values[model['initial_label']]
    attempts = [values[label] for label in model['attempt_labels']]
    overcast = values[model['overcast_label']]
    cast_failure = values[model['cast_failure_label']]
    before_recharge = values[model['before_recharge_label']]
    after_recharge = values[model['after_recharge_label']]
    expected_attempts = [max_charges - (index + 1) for index in range(max_charges)]
    initial_ok = initial == max_charges
    attempts_ok = attempts == expected_attempts
    overcast_ok = overcast == 0 and cast_failure != 0
    before_recharge_ok = before_recharge == 0
    after_recharge_ok = after_recharge == 1
    status = 'ok' if initial_ok and attempts_ok and overcast_ok and before_recharge_ok and after_recharge_ok \
        else 'alert'
    tolerance = float(model['tolerance'])
    explanation = (f'{max_charges} native charges expected; measured {initial:g} at the start, {attempts} after '
                   f'each of {max_charges} consecutive casts (expected {expected_attempts}); an attempted '
                   f'over-cast left {overcast:g} charges (expected 0) and was refused with reason {cast_failure:g} '
                   f'(expected nonzero); {before_recharge:g} charges remained at {model["recharge_ms"]:g} ms x '
                   f'{1.0 - tolerance:g} (expected 0, not recharged early) and '
                   f'{after_recharge:g} charges were available at {model["recharge_ms"]:g} ms x '
                   f'{1.0 + tolerance:g} (expected 1, recharged by then)')
    return replace(base, status=status, measured=after_recharge, expected=1.0, low=0.0, high=1.0,
                   explanation=explanation)


def behaviour_cast_gate_verdict(base: Verdict, run: Run, expectation: Expectation) -> Verdict:
    summed = (expectation.model or {}).get('sum_labels')
    if summed:
        missing = next((label for label in summed if run.values.get(label) is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        total = sum(float(run.values[label]) for label in summed)
        if expectation.model.get('at_least'):
            floor = float(expectation.displayed)
            return replace(base, status='ok' if total >= floor - FLOAT_EPSILON else 'alert', measured=total,
                           expected=floor, low=floor, high=float(len(summed)),
                           explanation=f'the sum of {", ".join(summed)} must be at least {floor:g}')
        return exact(base, total, float(expectation.displayed),
                     f'the sum of {", ".join(summed)} compared exactly to the expected count')
    measured = run.values.get(expectation.label)
    if measured is None:
        return replace(base, explanation=missing_measurement(run, expectation.label))
    expected = float(expectation.displayed)
    removal = (expectation.model or {}).get('removal')
    limit = (f'; a removed cooldown: the second cast is attempted {expectation.model["level"]:g} ms after the first, '
             f'past the spell\'s {removal["global_cooldown_ms"]} ms global cooldown (the harness waits '
             f'{removal["gcd_wait_ms"]} ms), so a cooldown left below {expectation.model["level"]:g} ms is not told '
             f'apart from none' if removal else '')
    what = ('the remaining cooldown read right after the cast, in ms, compared exactly'
            if (expectation.model or {}).get('reading') == 'cooldown_ms'
            else 'cast_failure SpellCastResult reason compared exactly to the expected code')
    return exact(base, float(measured), expected, what + limit)


def behaviour_immunity_verdict(base: Verdict, run: Run, expectation: Expectation) -> Verdict:
    measured = run.values.get(expectation.label)
    if measured is None:
        return replace(base, explanation=missing_measurement(run, expectation.label))
    return exact(base, float(measured), float(expectation.displayed),
                 'cast_failure reason or aura presence on the caster compared exactly to the expected value')


THREAT_SLOPE_TOLERANCE = 1e-3


def behaviour_threat_slope_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = (model['cast_label'], model['health_before_label'], model['health_after_label'], model['threat_label'])
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    cast, before, after, threat = (float(run.values[label]) for label in labels)
    expected = float(model['expected'])
    damage = before - after
    if cast != NO_CAST_FAILURE or damage <= 0:
        return replace(base, status='unmeasured', expected=expected,
                       explanation=f'cast_failure {cast:g}, health lost {damage:g}: no landed hit to divide by')
    slope = (threat - float(model['flat'])) / damage
    status = 'ok' if abs(slope - expected) <= THREAT_SLOPE_TOLERANCE else 'alert'
    return replace(base, status=status, measured=slope, expected=expected, low=expected - THREAT_SLOPE_TOLERANCE,
                   high=expected + THREAT_SLOPE_TOLERANCE,
                   explanation=f'threat {threat:g} less flat {model["flat"]:g} over health lost {damage:g} = '
                               f'{slope:.6g}, judged against {expected:g} within {THREAT_SLOPE_TOLERANCE:g}; '
                               f'every slope outside [{expected - THREAT_SLOPE_TOLERANCE:g}, '
                               f'{expected + THREAT_SLOPE_TOLERANCE:g}] is excluded')


EVENT_DELAY_SHARE = 0.05
EVENT_DELAY_FLOOR_MS = 50.0


def stamped(value: float | None) -> bool:
    return value is not None and not math.isnan(value)


def event_delay_tolerance(expected_ms: float) -> float:
    return max(EVENT_DELAY_SHARE * expected_ms, EVENT_DELAY_FLOOR_MS)


def landed_each_cast(hits: list[float]) -> bool:
    return all(later > earlier for earlier, later in zip([0.0] + hits, hits))


def behaviour_event_delay_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    expected = float(model['expected_ms'])
    tolerance = event_delay_tolerance(expected)
    low, high = expected - tolerance, expected + tolerance
    missing = next((label for read in model['reads'] for label in read.values() if label not in run.values), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    since_cast = [run.values[read['since_cast']] for read in model['reads']]
    since_hit_cast = [run.values[read['since_hit_cast']] for read in model['reads']]
    hits = [run.values[read['hits']] for read in model['reads']]
    observed = model['observe_spell']
    if not all(stamped(value) for value in since_cast + since_hit_cast) or not landed_each_cast(hits):
        return replace(base, status='alert', expected=expected, low=low, high=high,
                       explanation=f'first hit of {observed} after each cast {since_cast} ms, after its own cast '
                                   f'packet {since_hit_cast} ms, cumulative hits {hits}: a cast was not followed by a '
                                   f'stamped hit of {observed}, expected after the Spell.dbc delay of {expected:g} ms')
    delays = [cast - hit_cast for cast, hit_cast in zip(since_cast, since_hit_cast)]
    status = 'ok' if all(low - FLOAT_EPSILON <= delay <= high + FLOAT_EPSILON for delay in delays) else 'alert'
    return replace(base, status=status, measured=max(delays, key=lambda delay: abs(delay - expected)),
                   expected=expected, low=low, high=high,
                   detail={EXCLUDED: [low, high], 'delays_ms': delays, 'cast_to_hit_ms': since_hit_cast},
                   explanation=f'first hit of {observed} after each cast at {since_cast} ms, less its own '
                               f'cast-to-hit time {since_hit_cast} ms = {delays} ms from the cast to the cast of '
                               f'{observed}, Spell.dbc {expected:g} ms within '
                               f'max({EVENT_DELAY_SHARE:g} x {expected:g}, {EVENT_DELAY_FLOOR_MS:g}) = {tolerance:g} '
                               f'ms; a delay below {low:g} or above '
                               f'{high:g} ms is excluded; cumulative hits {hits}')


def proc_reset_trials(run: Run, phase: dict) -> list[tuple[float, float, float]] | str:
    labels = [phase['start']] + [label for read in phase['reads'] for label in read.values()]
    missing = next((label for label in labels if label not in run.values), None)
    if missing is not None:
        return missing_measurement(run, missing)
    procs = [run.values[phase['start']]] + [run.values[read['procs']] for read in phase['reads']]
    return [(later - earlier, run.values[read['cooldown']], run.values[read['power']])
            for earlier, later, read in zip(procs, procs[1:], phase['reads'])]


def proc_reset_faults(trials: list[tuple[float, float, float]], level: float, cost: float,
                      reduced: float | None, learned: bool) -> list[str]:
    faults = []
    after_proc = False
    for index, (events, cooldown, power) in enumerate(trials, 1):
        spent = level - power
        fired = events > 0
        if fired and not learned:
            faults.append(f'trial {index}: {events:g} procs without the passive')
        if fired and cooldown > FLOAT_EPSILON:
            faults.append(f'trial {index}: a proc fired and the cooldown still reads {cooldown:g} ms')
        if not fired and cooldown <= FLOAT_EPSILON:
            faults.append(f'trial {index}: no proc fired and the cooldown reads 0')
        stated = reduced if after_proc and reduced is not None else cost
        if abs(spent - stated) > FLOAT_EPSILON:
            faults.append(f'trial {index}: the cast cost {spent:g} against {stated:g}'
                          + (' after a proc' if after_proc else ''))
        after_proc = fired
    return faults


def behaviour_proc_reset_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    level, cost, reduced = float(model['power_level']), float(model['cost']), model.get('reduced_cost')
    trials = {}
    for phase in ('without', 'with'):
        read = proc_reset_trials(run, model['phases'][phase])
        if isinstance(read, str):
            return replace(base, explanation=read)
        trials[phase] = read
    faults = (proc_reset_faults(trials['without'], level, cost, reduced, False)
              + proc_reset_faults(trials['with'], level, cost, reduced, True))
    fired = [index for index, (events, _, _) in enumerate(trials['with']) if events > 0]
    quiet = len(trials['with']) - len(fired)
    after = [index for index in fired if index + 1 < len(trials['with'])]
    counts = (f'{len(fired)} of {len(trials["with"])} casts with the passive fired a proc of '
              f'{model["marker_spell"]}, {quiet} did not, {len(after)} casts followed a proc; '
              f'{sum(events for events, _, _ in trials["without"]):g} procs in '
              f'{len(trials["without"])} casts without it')
    rule = (f'a proc must reset the cooldown of {model["reset_spell"]} to 0, a cast without one must leave it running, '
            f'and the cast after a proc must cost {reduced if reduced is not None else cost:g} instead of {cost:g}')
    detail = {'fired': len(fired), 'quiet': quiet, 'after_proc': len(after), 'faults': faults[:20]}
    if faults:
        return replace(base, status='alert', measured=float(len(faults)), expected=0.0, low=0.0, high=0.0,
                       detail=detail, explanation=f'{counts}; {rule}; {len(faults)} faults: {"; ".join(faults[:5])}')
    least = min(len(fired), quiet, len(after) if reduced is not None else len(fired))
    status = 'ok' if least >= int(model['min_events']) else 'insufficient_trials'
    return replace(base, status=status, measured=0.0, expected=0.0, low=0.0, high=0.0, detail=detail,
                   explanation=f'{counts}; {rule}; no fault' + ('' if status == 'ok' else
                               f'; fewer than {model["min_events"]} trials in a group, not judged'))


def behaviour_mount_grant_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    caster_value = run.values.get(model['caster_label'])
    ally_value = run.values.get(model['ally_label'])
    missing = model['caster_label'] if caster_value is None else (
        model['ally_label'] if ally_value is None else None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    expected = float(model['expected'])
    caster_ok = abs(caster_value - expected) <= FLOAT_EPSILON
    ally_ok = abs(ally_value - expected) <= FLOAT_EPSILON
    status = 'ok' if caster_ok and ally_ok else 'alert'
    return replace(base, status=status, measured=caster_value, expected=expected, low=expected, high=expected,
                   explanation=f'mount_display_id {model["moment"]}: caster {caster_value:g}, ally '
                               f'{ally_value:g} (Unit::GetMountID(), both must equal {expected:g}); a mismatch '
                               f'on either actor is always an alert')


def behaviour_internal_cooldown_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    first = run.values.get(model['first_label'])
    blocked = run.values.get(model['blocked_label'])
    allowed = run.values.get(model['allowed_label'])
    missing = next((label for label, value in ((model['first_label'], first), (model['blocked_label'], blocked),
                                               (model['allowed_label'], allowed)) if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    blocked_ok = abs(blocked - first) <= FLOAT_EPSILON
    allowed_ok = abs(allowed - (first + 1.0)) <= FLOAT_EPSILON
    status = 'ok' if blocked_ok and allowed_ok else 'alert'
    return replace(base, status=status, measured=blocked, expected=first, low=first, high=first,
                   explanation=f'spell_cast_count measured {first:g} after the first heal, {blocked:g} after a '
                               f'second heal landed inside the {model["window_ms"]:g} ms window (must stay '
                               f'{first:g}), and {allowed:g} after a third heal landed past the window (must be '
                               f'{first + 1.0:g}); a count change inside the window or no change past it is '
                               f'always an alert')


def behaviour_aggro_redirect_verdict(base: Verdict, run: Run, expectation: Expectation) -> Verdict:
    measured = run.values.get(expectation.label)
    if measured is None:
        return replace(base, explanation=missing_measurement(run, expectation.label))
    expected = float(expectation.displayed)
    verdict = exact(base, float(measured), expected,
                    'victim (Unit::GetVictim() == caster) compared exactly to whether the clause redirects it')
    label = expectation.model.get('distance_label')
    if label is None:
        return verdict
    distance = run.values.get(label)
    if distance is None:
        return replace(base, explanation=missing_measurement(run, label))
    placed = abs(distance - expectation.model['distance']) <= expectation.model['placement_yd']
    explanation = (f'{verdict.explanation}; distance to the caster before the cast {distance:g} yd, placed '
                   f'{expectation.model["distance"]:g} yd (within {expectation.model["placement_yd"]:g} required)')
    return replace(verdict, status=verdict.status if placed else 'alert', explanation=explanation)


def behaviour_cast_applies_aura_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    before = run.values.get(model['before_label'])
    after = run.values.get(model['after_label'])
    if before is None or after is None:
        return replace(base, explanation=missing_measurement(run, model['before_label'] if before is None
                                                              else model['after_label']))
    expected = float(model['expected_ms'])
    low = expected - CAST_MARGIN_MS
    before_ok = abs(before) <= FLOAT_EPSILON
    after_ok = low - FLOAT_EPSILON <= after <= expected + FLOAT_EPSILON
    status = 'ok' if before_ok and after_ok else 'alert'
    return replace(base, status=status, measured=after, expected=expected, low=low, high=expected,
                   explanation=f'{model["before_label"]} measured {before:g} ms before the cast (expected 0, '
                               f'absent); {model["after_label"]} measured {after:g} ms right after it (expected '
                               f'between {low:g} and {expected:g} ms, the instant-cast tick loss below '
                               f'SpellDuration.dbc\'s {expected:g} ms); an aura present before the cast, or absent '
                               f'or materially short right after it, is always an alert')


def observed(expectation: Expectation) -> dict:
    model = expectation.model or {}
    found = {PASSIVE_METRIC: model.get('metric', model.get('observe_metric')), CONTRAST: model.get(CONTRAST)}
    return {key: value for key, value in found.items() if value is not None}


def hit_ratio_series(run: Run, reads: list[list[str]]) -> tuple[list[float], list[float]] | str:
    marks = []
    for total_label, count_label in reads:
        total, count = run.values.get(total_label), run.values.get(count_label)
        if total is None or count is None:
            return missing_measurement(run, total_label if total is None else count_label)
        marks.append((total, count))
    pairs = list(zip(marks, marks[1:]))
    return [later[0] - earlier[0] for earlier, later in pairs], [later[1] - earlier[1] for earlier, later in pairs]


def stated_bonus_of_ratio(ratio: float, parts: list[float]) -> float:
    def ratio_of(bonus: float) -> float:
        return math.prod(1 + part * (1 + bonus / 100) / 100 for part in parts) / math.prod(1 + part / 100
                                                                                           for part in parts)
    low, high = -100.0, 1000.0
    for _ in range(200):
        middle = (low + high) / 2
        low, high = (middle, high) if ratio_of(middle) < ratio else (low, middle)
    return (low + high) / 2


def stated_bonus(bonus: Bonus, stated: dict) -> Bonus:
    parts = stated['parts']
    measured = stated_bonus_of_ratio(1 + bonus.measured / 100, parts)
    if not math.isfinite(bonus.half):
        return Bonus(measured, math.inf, float(stated['bonus']), bonus.trials)
    low = stated_bonus_of_ratio(1 + (bonus.measured - bonus.half) / 100, parts)
    high = stated_bonus_of_ratio(1 + (bonus.measured + bonus.half) / 100, parts)
    return Bonus(measured, max(measured - low, high - measured), float(stated['bonus']), bonus.trials)


@dataclass(frozen=True)
class EngineStepReading:
    bonus: Bonus
    status: str
    reason: str
    passes: tuple[float, float]
    text: str


def first_bonus_where(holds: Callable[[float], bool]) -> float:
    low, high = -100.0, 1000.0
    for _ in range(200):
        middle = (low + high) / 2
        low, high = (low, middle) if holds(middle) else (middle, high)
    return high


def engine_step_reading(bonus: Bonus, stated: dict) -> EngineStepReading:
    parts = tuple(float(part) for part in stated['parts'])
    expected = float(stated['bonus'])
    ratio_of = lambda value: stated_ratio(value, parts, True)
    amounts = lambda value: [engine_amount(part * (1 + value / 100)) for part in parts]
    reaching = lambda low, high: (first_bonus_where(lambda value: ratio_of(value) >= low - FLOAT_EPSILON),
                                  first_bonus_where(lambda value: ratio_of(value) > high + FLOAT_EPSILON))
    stated_level = ratio_of(expected)
    stated_amounts = amounts(expected)
    passes = reaching(stated_level, stated_level)
    continuous = stated_bonus_of_ratio(1 + bonus.measured / 100, list(parts))
    stated_text = (f'the engine computation at the stated {expected:g}% gives the amounts {stated_amounts} on the '
                   f'parts {list(parts)}, which a bonus from {passes[0]:.4g}% to {passes[1]:.4g}% gives; only that '
                   f'step passes')
    if not math.isfinite(bonus.half):
        return EngineStepReading(Bonus(continuous, math.inf, expected, bonus.trials), 'insufficient_trials',
                                 'not judged: one trial per arm gives no interval', passes,
                                 f'no interval; {stated_text}')
    low_ratio, high_ratio = 1 + bonus.low / 100, 1 + bonus.high / 100
    interval = f'99% ratio interval {low_ratio:.5g} to {high_ratio:.5g}'
    start, end = reaching(low_ratio, high_ratio)
    level = ratio_of(start)
    if level > high_ratio + FLOAT_EPSILON:
        return EngineStepReading(Bonus(continuous, math.inf, expected, bonus.trials), 'alert',
                                 'the 99% interval holds no ratio the engine\'s int32 amounts give', passes,
                                 f'{interval} lies between two engine steps; {stated_text}')
    found = Bonus((start + end) / 2, (end - start) / 2, expected, bonus.trials)
    one_step = first_bonus_where(lambda value: ratio_of(value) > level + FLOAT_EPSILON) >= end - FLOAT_EPSILON
    held = (f'one engine step, the amounts {amounts(start)}' if one_step
            else f'the engine steps from the amounts {amounts(start)} on')
    text = (f'{interval} holds {held}, which a bonus from {start:.4g}% to {end:.4g}% gives; {stated_text}; the '
            f'engine resolves the bonus no finer than its steps')
    if one_step and amounts(start) == stated_amounts:
        return EngineStepReading(found, 'ok', 'the amounts read are the ones the engine computation at the stated '
                                              'bonus gives', passes, text)
    if low_ratio - FLOAT_EPSILON <= stated_level <= high_ratio + FLOAT_EPSILON:
        return EngineStepReading(found, 'insufficient_trials', 'not judged: the 99% interval holds the stated '
                                                               'step and another engine step', passes, text)
    return EngineStepReading(found, 'alert', 'the amounts read are not the ones the engine computation at the '
                                             'stated bonus gives', passes, text)


def behaviour_hit_ratio_verdict(base: Verdict, run: Run | list[Run], model: dict) -> Verdict:
    runs = run if isinstance(run, list) else [run]
    run = runs[0]
    scale = 100.0 if model.get('rate') else 1.0
    series = {}
    for arm in ('control', 'treatment'):
        totals, counts = [], []
        for part in runs:
            found = hit_ratio_series(part, model['reads'][arm])
            if isinstance(found, str):
                return replace(base, explanation=found)
            totals += [total * scale for total in found[0]]
            counts += found[1]
        series[arm] = (totals, counts)
    minimum = int(model['minimum_hits']) * len(runs)
    hits = {arm: sum(counts) for arm, (_, counts) in series.items()}
    if min(hits.values()) < minimum:
        return replace(base, status='unmeasured',
                       explanation=f'{hits["control"]:g} control and {hits["treatment"]:g} treatment hits counted; '
                                   f'each arm needs at least {minimum} of its {model["trials"] * len(runs)} casts to '
                                   f'land')
    control, treatment = (per_event_sample(*series[arm]) for arm in ('control', 'treatment'))
    flat = model.get('expected_delta')
    scaled = ''
    if flat is not None and model.get('scale_reads'):
        factors = {}
        for arm, labels in model['scale_reads'].items():
            amounts = [run.values.get(label) for label in labels]
            if any(amount is None for amount in amounts):
                return replace(base, explanation=missing_measurement(run, labels[amounts.index(None)]))
            factors[arm] = math.prod(1 + amount / 100 for amount in amounts)
        if len(set(factors.values())) != 1:
            return replace(base, status='alert', explanation=f'the scaling auras differ between the arms: {factors}')
        factor = factors['control']
        scaled = (f'; the stated {float(flat):g} times {factor:.4g}, the measured scaling auras, is '
                  f'{float(flat) * factor:.4g}')
        flat = float(flat) * factor
    try:
        bonus = (delta_of(treatment, control, float(flat)) if flat is not None
                 else bonus_of(treatment, control, float(model['expected_bonus'])))
    except ValueError as error:
        return replace(base, status='unmeasured', explanation=f'not judged: {error}')
    stated = model.get('stated')
    stepped = stated and flat is None and stated.get('truncated') and engine_step_reading(bonus, stated)
    if stepped:
        bonus = stepped.bonus
        status, reason, needed = stepped.status, stepped.reason, None
    else:
        if stated and flat is None:
            bonus = stated_bonus(bonus, stated)
        status, reason, needed = bonus_status(bonus)
    sized = None if stepped else sized_trials(bonus)
    detail = {'bonus': bonus_detail(bonus), 'trials_needed': needed, 'sized_trials': sized,
              'trial_limit': model.get('trial_limit'), **({'parts': len(runs)} if len(runs) > 1 else {})}
    limit = model.get('trial_limit') and model['trial_limit'] * len(runs)
    beyond = (f'; {needed} trials per arm exceed the {limit} one scenario holds' if needed and limit and needed > limit
              else '')
    if len(runs) > 1:
        beyond += f'; {len(runs)} parts pooled'
    if model.get('rate'):
        beyond += f'; the {model["rate"]} rate is in percent of the counted events'
    ratio = f', ratio {treatment.mean / control.mean:.5g}' if control.mean else ''
    if stated and flat is None:
        ratio += (f', read as the stated bonus on the parts {stated["parts"]} '
                  f'(ratio = prod(1 + part x (1 + bonus)) / prod(1 + part))')
    if stepped:
        detail['engine_step'] = {'passes_from': stepped.passes[0], 'passes_to': stepped.passes[1]}
        ratio += ' with each scaled amount truncated to int32 (the integer-truncation ruling of 2026-11-11)'
    low, high = stepped.passes if stepped else (bonus.expected - bonus.band, bonus.expected + bonus.band)
    reading = (stepped.text if stepped else delta_text(bonus) if flat is not None else bonus_text(bonus))
    return replace(base, status=status, measured=bonus.measured, expected=bonus.expected,
                   low=low, high=high, detail=detail,
                   explanation=f'per-hit mean {treatment.mean:.6g} over {treatment.events:g} treatment hits against '
                               f'{control.mean:.6g} over {control.events:g} control hits{ratio}; '
                               f'{reading}{scaled}; {reason}'
                               f'{beyond}')


RATIO_CHECKS = frozenset({BEHAVIOUR_RATIO, BEHAVIOUR_PARTY_STAT_RATIO, BEHAVIOUR_DURATION_RATIO,
                          BEHAVIOUR_METRIC_RATIO_DELTA, BEHAVIOUR_ABSORB_PIERCE_RATIO, BEHAVIOUR_GROUP_STACK_CAP,
                          BEHAVIOUR_CRIT_MAGNITUDE})


def with_excluded_band(verdict: Verdict, check: str) -> Verdict:
    if (check not in RATIO_CHECKS or verdict.status not in EXCLUDING_STATUSES or verdict.low is None
            or verdict.high is None or verdict.expected is None):
        return verdict
    low, high = verdict.low, verdict.high
    if check == BEHAVIOUR_RATIO:
        widened = TOLERATED_RELATIVE * abs(verdict.expected - 1.0)
        low, high = min(low, verdict.expected - widened), max(high, verdict.expected + widened)
    return replace(verdict, detail={**(verdict.detail or {}), EXCLUDED: [low, high]},
                   explanation=f'{verdict.explanation}; this check {band_excluded_text(low, high, "a reading")} '
                               f'(one reading, no sampling interval)')


def judge_behaviour(base: Verdict, run: Run | None, expectation: Expectation) -> Verdict:
    verdict = with_excluded_band(judged_behaviour(base, run, expectation), expectation.check)
    stamp = observed(expectation)
    return replace(verdict, detail={**(verdict.detail or {}), **stamp}) if stamp else verdict


def behaviour_amount_match_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    per_trial = {}
    for side, marks in model['reads'].items():
        values = [(run.values.get(total), run.values.get(count)) for total, count in marks]
        missing = next((label for (total, count), pair in zip(marks, values) for label, value
                        in ((total, pair[0]), (count, pair[1])) if value is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        per_trial[side] = [(after[0] - before[0], after[1] - before[1]) for before, after in zip(values, values[1:])]
    first, second = per_trial['first'], per_trial['second']
    pairs = [(a[0] / a[1], b[0] / b[1]) for a, b in zip(first, second) if a[1] > 0 and b[1] > 0]
    if len(pairs) < model['minimum_trials']:
        return replace(base, status='unmeasured',
                       explanation=f'{len(pairs)} of {model["trials"]} trials read both amounts; at least '
                                   f'{model["minimum_trials"]} are needed')
    worst = max(abs(a - b) for a, b in pairs)
    status = 'ok' if worst <= model['tolerance'] + FLOAT_EPSILON else 'alert'
    means = sum(a for a, _ in pairs) / len(pairs), sum(b for _, b in pairs) / len(pairs)
    return replace(base, status=status, measured=means[1] / means[0] if means[0] else None, expected=1.0,
                   explanation=f'{len(pairs)} trials read both amounts; per-event means {means[0]:g} and {means[1]:g}, '
                               f'largest difference within a trial {worst:g} against the allowed '
                               f'{model["tolerance"]:g}: {status}')


def judged_behaviour(base: Verdict, run: Run | None, expectation: Expectation) -> Verdict:
    if run is None:
        return replace(base, explanation=f'{base.scenario} has no scenario to measure {expectation.check}')
    model = expectation.model
    if expectation.check == BEHAVIOUR_AMOUNT_MATCH:
        return behaviour_amount_match_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CAST_GATE:
        return behaviour_cast_gate_verdict(base, run, expectation)
    if expectation.check == BEHAVIOUR_CAST_CONDITION:
        return behaviour_cast_gate_verdict(base, run, expectation)
    if expectation.check == BEHAVIOUR_CAST_COMBAT:
        return behaviour_cast_gate_verdict(base, run, expectation)
    if expectation.check == BEHAVIOUR_IMMUNITY:
        return behaviour_immunity_verdict(base, run, expectation)
    if expectation.check == BEHAVIOUR_THREAT_SLOPE:
        return behaviour_threat_slope_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_EVENT_DELAY:
        return behaviour_event_delay_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_PROC_RESET:
        return behaviour_proc_reset_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_COUNT:
        return behaviour_count_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_FIXED_COUNT:
        return behaviour_fixed_count_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_PARTY_STAT_RATIO:
        return behaviour_party_stat_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CAST_APPLIES_AURA:
        return behaviour_cast_applies_aura_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_RATIO:
        if model.get('kind') == 'leech_ratio':
            return behaviour_leech_ratio_verdict(base, run, model)
        if model.get('kind') == 'stat_ratio':
            return behaviour_stat_ratio_verdict(base, run, model)
        return behaviour_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION_REFRESH:
        return behaviour_duration_refresh_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_TRIGGER:
        return behaviour_trigger_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_METRIC_DELTA:
        if model.get('kind') == 'stat_gain':
            return behaviour_stat_gain_verdict(base, run, model)
        return behaviour_metric_delta_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_HEAL_BLOCK:
        return behaviour_heal_block_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_METRIC_RATIO_DELTA:
        return behaviour_metric_ratio_delta_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_ABSORB_PIERCE_RATIO:
        return behaviour_absorb_pierce_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION:
        return behaviour_duration_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION_RATIO:
        return behaviour_duration_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CHARGE_RECHARGE:
        return behaviour_charge_recharge_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_AMOUNT_DELTA:
        return behaviour_amount_delta_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CRIT_GUARANTEE:
        return behaviour_crit_guarantee_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_AURA_GRANT:
        return behaviour_aura_grant_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_OATH_CONSUMPTION:
        return behaviour_oath_consumption_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_OATH_CONSUMPTION_REMOVAL:
        return behaviour_oath_consumption_removal_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_INTERNAL_COOLDOWN_GATE:
        return behaviour_internal_cooldown_gate_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_EXCLUSIVITY:
        return behaviour_exclusivity_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_GROUP_STACK_CAP:
        return behaviour_group_stack_cap_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_SINGLE_TARGET:
        return behaviour_single_target_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CRIT_MAGNITUDE:
        return behaviour_crit_magnitude_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_MOUNT_GRANT:
        return behaviour_mount_grant_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_INTERNAL_COOLDOWN:
        return behaviour_internal_cooldown_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_AGGRO_REDIRECT:
        return behaviour_aggro_redirect_verdict(base, run, expectation)
    if expectation.check == BEHAVIOUR_HIT_RATIO:
        return behaviour_hit_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_EXPIRY:
        return behaviour_expiry_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_TAKEN_HIT:
        return behaviour_taken_hit_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_THREAT_REDIRECT:
        return behaviour_threat_redirect_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DISPEL_COUNT:
        return behaviour_dispel_count_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_TAKEN_OUTCOME:
        return behaviour_taken_outcome_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_FALL_DAMAGE:
        return behaviour_fall_damage_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_CRIT_RATE:
        return behaviour_crit_rate_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_SOURCE_STACK:
        return behaviour_source_stack_verdict(base, run, model)
    return replace(base, explanation=f'behaviour check {expectation.check!r} has no judge rule')


def behaviour_dispel_count_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    removed, carried = [], []
    for trial in model['reads']:
        values = []
        for before_label, after_label in trial:
            before, after = run.values.get(before_label), run.values.get(after_label)
            if before is None or after is None:
                return replace(base, explanation=missing_measurement(
                    run, before_label if before is None else after_label))
            values.append((before, after))
        carried.append(sum(1 for before, _ in values if before > 0))
        removed.append(sum(1 for before, after in values if before > 0 and after <= 0))
    kind = DISPEL_TYPE_NAMES[model['dispel_type']]
    expected = model['expected']
    if any(count != len(model['reads'][0]) for count in carried):
        return replace(base, status='unmeasured', explanation=(
            f'{model["arm"]}: the ally carried {carried} {kind} debuffs before the casts, not '
            f'{len(model["reads"][0])} each time; the removals cannot be counted'))
    faults = [f'trial {index}: {count} removed' for index, count in enumerate(removed, 1) if count != expected]
    status = 'alert' if faults else 'ok'
    mean = sum(removed) / len(removed)
    return replace(base, status=status, measured=float(mean), expected=float(expected), low=float(expected),
                   high=float(expected), explanation=(
                       f'{model["arm"]}: {kind} debuffs removed per cast {removed} of {carried[0]} carried, against '
                       f'{expected}; ' + ('; '.join(faults) if faults else 'every cast matches')
                       + '; each count is compared exactly'))


TAKEN_OUTCOME_MINIMUM_SWINGS = 100


def behaviour_taken_outcome_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    rates = {}
    for arm, reads in model['reads'].items():
        values = {key: run.values.get(label) for key, label in reads.items()}
        missing = next((reads[key] for key, value in values.items() if value is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, missing))
        swings = values['end swings'] - values['start swings']
        outcomes = values['end outcomes'] - values['start outcomes']
        if swings < TAKEN_OUTCOME_MINIMUM_SWINGS or not 0 <= outcomes <= swings:
            return replace(base, status='unmeasured',
                           explanation=f'{arm} arm: {outcomes:g} outcomes over {swings:g} swings taken; each arm '
                                       f'needs at least {TAKEN_OUTCOME_MINIMUM_SWINGS} swings')
        rates[arm] = (outcomes / swings, swings, outcomes)
    (control, control_swings, control_hits), (treated, treated_swings, treated_hits) = \
        rates['control'], rates['treatment']
    spread = control * (1 - control) / control_swings + treated * (1 - treated) / treated_swings
    bonus = Bonus((treated - control) * 100, Z_99 * math.sqrt(spread) * 100, float(model['expected_points']),
                  int(min(control_swings, treated_swings)))
    status, reason, needed = bonus_status(bonus)
    states = {arm: run.values.get(label) for arm, label in (model.get('states') or {}).items()}
    detail = {'bonus': bonus_detail(bonus), 'swings_needed': needed, 'states': states}
    return replace(base, status=status, measured=bonus.measured, expected=bonus.expected,
                   low=bonus.expected - bonus.band, high=bonus.expected + bonus.band, detail=detail,
                   explanation=f'victim state {model["victim_state"]}: {control_hits:g} of {control_swings:g} swings '
                               f'taken in the control arm ({control:.2%}), {treated_hits:g} of {treated_swings:g} '
                               f'with {model["stacks"]} stacks ({treated:.2%}); difference in points, 99% normal '
                               f'interval: {taken_outcome_text(bonus)}; {reason}'
                               + (f'; state read per arm {states} (not judged)' if states else ''))


def taken_outcome_text(bonus: Bonus) -> str:
    low, high = bonus.excluded
    return (f'difference {bonus.measured:+.4g} points (99% interval {bonus.low:+.4g} to {bonus.high:+.4g}, '
            f'{bonus.trials} swings in the smaller arm) against the stated {bonus.expected:+.4g} points, which '
            f'passes inside +-{bonus.band:.3g} points (the larger of 5% of it and 2 points); excludes a difference '
            f'below {low:+.4g} or above {high:+.4g} points')


def crit_share_difference(control: tuple[float, float], treatment: tuple[float, float]) -> tuple[float, float, float]:
    (control_hits, control_crits), (treatment_hits, treatment_crits) = control, treatment
    first, second = control_crits / control_hits, treatment_crits / treatment_hits
    first_low, first_high = wilson_interval(control_crits, control_hits)
    second_low, second_high = wilson_interval(treatment_crits, treatment_hits)
    difference = second - first
    low = difference - math.sqrt((second - second_low) ** 2 + (first_high - first) ** 2)
    high = difference + math.sqrt((second_high - second) ** 2 + (first - first_low) ** 2)
    return 100 * difference, 100 * low, 100 * high


def crit_rate_hits_needed(control: tuple[float, float], treatment: tuple[float, float], band: float) -> int:
    spread = sum(crits / hits * (1 - crits / hits) for hits, crits in (control, treatment))
    return math.ceil(Z_99 ** 2 * spread / (band / 100) ** 2)


def behaviour_crit_rate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    counted = {}
    for arm, marks in model['reads'].items():
        found = []
        for read in ('hits', 'crits'):
            start, end = run.values.get(marks['start'][read]), run.values.get(marks['end'][read])
            if start is None or end is None:
                return replace(base, explanation=missing_measurement(
                    run, marks['start'][read] if start is None else marks['end'][read]))
            found.append(end - start)
        if found[0] < model['minimum_hits']:
            return replace(base, status='insufficient_trials',
                           explanation=f'{arm}: {found[0]:g} landed hits, fewer than {model["minimum_hits"]}')
        counted[arm] = (found[0], found[1])
    control, treatment = counted['control'], counted['treatment']
    measured, low, high = crit_share_difference(control, treatment)
    expected = model['expected']
    band = bonus_band(expected)
    needed = crit_rate_hits_needed(control, treatment, band)
    if expected - band <= low and high <= expected + band:
        status = 'ok'
    elif high < expected - band or low > expected + band:
        status = 'alert'
    else:
        status = MEASURED
    text = (f'critical share {control[1]:g} of {control[0]:g} control hits and {treatment[1]:g} of '
            f'{treatment[0]:g} treatment hits: {measured:+.2f} points, 99% interval {low:+.2f} to {high:+.2f} '
            f'(Newcombe, Wilson per arm) against the stated {expected:+g} +- {band:g}; a difference below '
            f'{low:+.2f} or above {high:+.2f} points is excluded')
    if status == MEASURED:
        text += (f'; effect present, interval stated, not final: an interval inside the band needs about {needed} '
                 f'hits per arm at these shares')
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high, explanation=text,
                   detail={'crit_rate': {'control': list(control), 'treatment': list(treatment), 'band': band,
                                         'hits_needed_per_arm': needed}})


def taken_hit_formula(constant: float, coefficients: list[float], sums: list[float]) -> int:
    total = float32(constant)
    for coefficient, value in zip(coefficients, sums):
        total = float32(total + float32(float32(coefficient) * float32(value)))
    return math.trunc(total)


def taken_hit_trial_fault(arm: dict, trial: dict, expected_absorb: int | None, debt_ends: bool) -> str | None:
    absorbed, damage = trial['absorb'], trial['damage']
    if arm['absorb'] == 'none' and absorbed:
        return f'absorbed {absorbed:g} with no absorb stated'
    if arm['absorb'] == 'formula' and absorbed != expected_absorb:
        return f'absorbed {absorbed:g} against {expected_absorb}'
    if arm['absorb'] == 'share':
        share = math.floor((absorbed + damage) * arm['share_pct'] / 100)
        if absorbed != share:
            return f'absorbed {absorbed:g} of {absorbed + damage:g} against {share} ({arm["share_pct"]}%)'
    if arm['debt_removed_pct'] is None:
        return None
    due = absorbed - math.floor(absorbed * arm['debt_removed_pct'] / 100)
    if debt_ends and (not trial['debt early'] or trial['paid early'] >= due):
        return (f'debt present {trial["debt early"]:g} with {trial["paid early"]:g} of {due:g} paid before its end '
                f'(must be present with less paid)')
    if trial['debt late'] or trial['paid late'] != due:
        return (f'debt present {trial["debt late"]:g} with {trial["paid late"]:g} of {due:g} paid after its end '
                f'(must be gone with all paid)')
    return None


def taken_hit_returned_fault(arm: dict, trial: dict) -> tuple[str | None, bool]:
    if 'returned_pct' not in arm:
        return None, False
    logs, count = trial['returned logs'], trial['returned count']
    if not arm['returned_pct']:
        return (f'{logs:g} returned hits with none stated' if logs else None), False
    if not logs or not count:
        return None, False
    due = math.floor(trial['damage'] * arm['returned_pct'] / 100)
    dealt = trial['returned'] + trial['returned absorb'] + trial['returned resist']
    if count != 1 or dealt != due:
        return (f'returned {dealt:g} (damage, absorbed and resisted) in {count:g} hits of a {trial["damage"]:g} '
                f'strike against {due} ({arm["returned_pct"]}%)'), True
    return None, True


def taken_hit_reduction_faults(model: dict, landed: dict[str, list[float]], reductions: dict[str, int],
                               notes: list[str] | None = None, short: list[str] | None = None) -> list[str]:
    reference = sorted(set(landed.get(TAKEN_HIT_CONTROL_ARM, [])))
    faults = []
    for arm in model['arms']:
        if arm.get('reduction') != 'formula':
            continue
        if len(reference) != 1:
            faults.append(f'{arm["name"]}: the {TAKEN_HIT_CONTROL_ARM} strikes read {reference}, not one damage')
            continue
        low, high = taken_hit_reduced_range(model['strike_base'], reductions[arm['name']], reference[0])
        wrong = sorted({damage for damage in landed[arm['name']] if not low <= damage <= high})
        fitting = [reduction for reduction in range(model['strike_base'] + 1)
                   if all(taken_hit_reduced_range(model['strike_base'], reduction, reference[0])[0] <= damage
                          <= taken_hit_reduced_range(model['strike_base'], reduction, reference[0])[1]
                          for damage in landed[arm['name']])]
        band = bonus_band(reductions[arm['name']])
        if notes is not None:
            notes.append(f'{arm["name"]}: control strike {reference[0]:g}, accepted damage {low}-{high}; the strikes '
                         f'fit a reduction of {fitting[0] if fitting else "none"}-{fitting[-1] if fitting else "none"} '
                         f'against the stated {reductions[arm["name"]]} (band +-{band:g}), excluding any other')
        if (short is not None and fitting and (fitting[0] < reductions[arm['name']] - band
                                               or fitting[-1] > reductions[arm['name']] + band)):
            short.append(f'{arm["name"]}: the strikes fit reductions {fitting[0]}-{fitting[-1]}, wider than the '
                         f'band')
        if wrong:
            faults.append(f'{arm["name"]}: strikes read {wrong} against {low}-{high}, the {TAKEN_HIT_CONTROL_ARM} '
                          f'strike {reference[0]:g} scaled from {model["strike_base"]} to '
                          f'{model["strike_base"]} - {reductions[arm["name"]]}')
    return faults


def taken_hit_reduced_range(base: int, reduction: int, control: float) -> tuple[int, int]:
    reduced = max(0, base - reduction)
    low = Fraction(reduced * int(control), base)
    high = Fraction(reduced * (int(control) + 1), base)
    return math.floor(low), max(math.floor(low), math.ceil(high) - 1)


def behaviour_source_stack_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for reads in model['reads'].values() for label in reads.values()]
    labels += [label for sources in model['sources'].values() for label in sources]
    labels += list(model['second_source'].values())
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
    present = {arm: [run.values[label] for label in sources] for arm, sources in model['sources'].items()}
    failure = run.values[model['second_source']['cast failure']]
    own_copy = run.values[model['second_source']['own copy']]
    if present['none'] != [0.0, 0.0] or present['one'] != [1.0, 0.0] or present['two'][0] != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'the copies on the caster read {present} (own, ally), not none, own, then own')
    if failure or own_copy != 1.0:
        return replace(base, status='unmeasured',
                       explanation=f'the second source is not shown: the ally\'s cast failure reads {failure:g} and '
                                   f'its own copy {own_copy:g} (must be 0 and 1)')
    copies = ('both copies were on the caster' if present['two'] == [1.0, 1.0] else
              'the ally cast without failure and holds its own copy, which did not join the caster\'s own')
    stacked, unmoved, held = [], [], []
    for metric, reads in model['reads'].items():
        none, one, two = (run.values[reads[arm]] for arm in ('none', 'one', 'two'))
        text = f'{metric} {none:g} / {one:g} / {two:g}'
        if abs(one - none) <= FLOAT_EPSILON:
            unmoved.append(text)
        elif abs(two - one) > FLOAT_EPSILON:
            stacked.append(text)
        else:
            held.append(text)
    status = 'alert' if stacked else 'ok' if held else 'unmeasured'
    parts = ([f'held at one source: {", ".join(held)}'] if held else []) + \
            ([f'stacked: {", ".join(stacked)}'] if stacked else []) + \
            ([f'not moved by one source, so not judged: {", ".join(unmoved)}'] if unmoved else [])
    return replace(base, status=status, measured=float(len(stacked)), expected=0.0, low=0.0, high=0.0,
                   explanation=f'no source / own / both: {"; ".join(parts)}; {copies}')


def behaviour_taken_rate_verdict(base: Verdict, run: Run | list[Run], model: dict) -> Verdict:
    runs = run if isinstance(run, list) else [run]
    samples, rates = {}, {}
    for arm in HIT_RATIO_ARMS:
        resisted = []
        for part in runs:
            for label in model['reads'][arm]:
                value = part.values.get(label)
                if value is None:
                    return replace(base, explanation=missing_measurement(part, label))
                resisted.append(0.0 if value else 100.0)
        samples[arm] = per_event_sample(resisted, [1.0] * len(resisted))
        rates[arm] = samples[arm].mean
    bonus = delta_of(samples['treatment'], samples['control'], float(model['expected_points']))
    status, reason, needed = bonus_status(bonus)
    pooled = f'; {len(runs)} parts pooled' if len(runs) > 1 else ''
    return replace(base, status=status, measured=bonus.measured, expected=bonus.expected,
                   low=bonus.expected - bonus.band, high=bonus.expected + bonus.band,
                   detail={'bonus': bonus_detail(bonus), 'trials_needed': needed, 'sized_trials': sized_trials(bonus),
                           **({'parts': len(runs)} if len(runs) > 1 else {})},
                   explanation=f'resisted in {rates["control"]:.4g}% of {samples["control"].trials} control trials '
                               f'and {rates["treatment"]:.4g}% of {samples["treatment"].trials} treatment trials; '
                               f'{delta_text(bonus)} points; {reason}{pooled}')


def behaviour_taken_hit_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    if model.get('kind') == 'taken_rate':
        return behaviour_taken_rate_verdict(base, run, model)
    faults, summaries, short = [], [], []
    judged = 0
    landed_damage, reductions = {}, {}
    for arm in model['arms']:
        values = {}
        for mark, labels in arm['marks'].items():
            for key, label in labels.items():
                value = run.values.get(label)
                if value is None:
                    return replace(base, explanation=missing_measurement(run, label))
                values[(mark, key)] = value
        expected_absorb = None
        if arm['terms']:
            sums = []
            for labels in arm['terms']:
                read = [run.values.get(label) for label in labels]
                if any(value is None for value in read):
                    return replace(base, explanation=missing_measurement(run, labels[read.index(None)]))
                sums.append(sum(read))
            formula = taken_hit_formula(model['absorb_constant'], model['absorb_coefficients'], sums)
            if arm.get('reduction') == 'formula':
                reductions[arm['name']] = formula
            else:
                expected_absorb = formula
        landed = 0
        absorbs, damages = [], []
        returned = 0
        previous = 'start'
        for trial in range(1, model['trials'] + 1):
            mark = str(trial)
            delta = {key: values[(mark, key)] - values[(previous, key)]
                     for key in ('damage', 'absorb', 'logs', *(TAKEN_HIT_RETURNED_KEYS if 'returned_pct' in arm
                                                               else ()))}
            if arm['debt_removed_pct'] is not None:
                for moment in ('early', 'late'):
                    delta[f'paid {moment}'] = values[(mark, f'paid {moment}')] - values[(previous, 'paid')]
                    delta[f'debt {moment}'] = values[(mark, f'debt {moment}')]
            previous = mark
            if delta['logs'] < arm['strikes']:
                continue
            landed += 1
            absorbs.append(delta['absorb'])
            damages.append(delta['damage'])
            fault = taken_hit_trial_fault(arm, delta, expected_absorb, model.get('debt_ends', False))
            returned_fault, judged_return = taken_hit_returned_fault(arm, delta)
            returned += judged_return
            for found in (fault, returned_fault):
                if found:
                    faults.append(f'{arm["name"]} trial {trial}: {found}')
        landed_damage[arm['name']] = damages
        if landed < model['minimum_trials']:
            short.append(f'{arm["name"]} landed {landed} of {model["trials"]} trials')
        if arm.get('returned_pct') and returned < model['minimum_trials']:
            short.append(f'{arm["name"]} returned a non-critical hit in {returned} of {model["trials"]} trials')
        judged += landed
        stated = {'none': 'no absorb', 'formula': f'{expected_absorb} absorbed',
                  'share': f'{arm["share_pct"]}% absorbed'}[arm['absorb']]
        debt = ('' if arm['debt_removed_pct'] is None else
                f', debt paid by its end less {arm["debt_removed_pct"]}% removed'
                + (', part of it still unpaid just before its end' if model.get('debt_ends') else ''))
        reduced = (f', damage {sorted(set(damages))} ({reductions[arm["name"]]} taken off the '
                   f'{model.get("strike_base")} strike before the {TAKEN_HIT_CONTROL_ARM} arm\'s mitigation)'
                   if arm['name'] in reductions else '')
        back = ('' if 'returned_pct' not in arm else
                f', {returned} non-critical returned hits judged ({arm["returned_pct"]}% of the strike)')
        summaries.append(f'{arm["name"]}: {landed} landed trials, absorbed {sorted(set(absorbs))} ({stated}{debt})'
                         f'{reduced}{back}')
    notes = []
    faults += taken_hit_reduction_faults(model, landed_damage, reductions, notes, short)
    summaries += notes
    status = 'alert' if faults else 'unmeasured' if short else 'ok'
    reason = '; '.join(faults[:6]) if faults else '; '.join(short) if short else 'every landed trial matches'
    return replace(base, status=status, measured=float(len(faults)), expected=0.0, low=0.0, high=0.0,
                   explanation=f'{"; ".join(summaries)}; {reason}; each absorbed amount is compared exactly'
                               + ('; each reduced or returned amount is compared exactly'
                                  if reductions or any('returned_pct' in arm for arm in model['arms']) else ''))


def behaviour_threat_redirect_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    gained = {}
    for phase, moments in model['reads'].items():
        for holder in moments['before']:
            before = run.values.get(moments['before'][holder])
            after = run.values.get(moments['after'][holder])
            if before is None or after is None:
                return replace(base, explanation=missing_measurement(
                    run, moments['before'][holder] if before is None else moments['after'][holder]))
            gained[(phase, holder)] = after - before
    ally, caster = (holder for holder in model['reads']['control']['before'])
    control_ok = gained[('control', ally)] > 0 and abs(gained[('control', caster)]) <= FLOAT_EPSILON
    treatment_ok = abs(gained[('treatment', ally)]) <= FLOAT_EPSILON and gained[('treatment', caster)] > 0
    status = 'ok' if control_ok and treatment_ok else 'alert'
    return replace(base, status=status, measured=gained[('treatment', caster)],
                   expected=gained[('control', ally)], low=0.0, high=None,
                   explanation=f'threat gained on the dummy without the spell: {ally} '
                               f'{gained[("control", ally)]:g}, {caster} {gained[("control", caster)]:g} (must be '
                               f'positive and 0); with it: {ally} {gained[("treatment", ally)]:g}, {caster} '
                               f'{gained[("treatment", caster)]:g} (must be 0 and positive)')


def behaviour_expiry_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    readings = expiry_readings(run.values, run.steps, run.max_step_ms, run.key, model)
    held = float(sum(reading.status == 'ok' for reading in readings))
    arms = float(len(readings))
    return replace(base, status=combined_status(readings), measured=held, expected=arms, low=arms, high=arms,
                   explanation=f'{held:g} of {arms:g} arms present before and absent after their stated end; '
                               + '; '.join(reading.explanation for reading in readings),
                   detail={EXPIRY_KIND: [reading.detail for reading in readings]})


def judge_passive(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                  tooltips: TooltipSource) -> Verdict:
    verdict = passive_verdict(manifest, entry, run, expectation, tooltips)
    metric = expectation.model['metric']
    detail = {**(verdict.detail or {}), PASSIVE_METRIC: metric}
    reason = (detail.get(DATA_ONLY) or (None if ENGINE_ROUNDING in detail else floor_only_reason(verdict, metric))
              or share_neighbour_reason(verdict, expectation.model, run, metric))
    if reason:
        detail[DATA_ONLY] = reason
    return replace(verdict, detail=detail)


def share_neighbour_reason(verdict: Verdict, model: dict, run: Run | None, metric: str) -> str | None:
    if (verdict.status not in CONFORMANT or verdict.expected is None or verdict.measured is None or run is None
            or model.get('relation') != 'share' or metric in FRACTIONAL_METRICS):
        return None
    source = run.values.get(model.get('source_label'))
    if not source:
        return None
    stated = verdict.expected * 100 / source
    reading = truncated(verdict.expected)
    neighbours = [percent for percent in (stated - 1, stated + 1)
                  if truncated(source * percent / 100) == reading]
    if not neighbours:
        return None
    return (f'the integer {metric} reading {reading:g} also follows from '
            f'{" and ".join(f"{percent:+.4g}%" for percent in neighbours)} of {source:g}, so it does not tell the '
            f'stated {stated:+.4g}%')


def floor_only_reason(verdict: Verdict, metric: str) -> str | None:
    if verdict.status not in CONFORMANT or verdict.measured is None or verdict.expected is None:
        return None
    floor = delta_floor(metric)
    band = TOLERATED_RELATIVE * abs(verdict.expected)
    if floor <= band + FLOAT_EPSILON or abs(verdict.measured - verdict.expected) <= FLOAT_EPSILON:
        return None
    return (f'the {floor:g}-point floor of {metric} is wider than the {TOLERATED_RELATIVE:.0%} band '
            f'({band:.3g}) of the expected delta {verdict.expected:+.6g}, and the reading {verdict.measured:+.6g} '
            f'is off it, so it does not tell the stated value')


def exact_truncated_verdict(base: Verdict, manifest: dict, run: Run, model: dict, value: float, context: str,
                            tooltips: TooltipSource) -> Verdict | None:
    exact_before_label, exact_after_label = model.get('exact_before_label'), model.get('exact_after_label')
    if exact_before_label is None or exact_after_label is None:
        return None
    exact_before, exact_after = run.values.get(exact_before_label), run.values.get(exact_after_label)
    if exact_before is None or exact_after is None:
        return None
    exact_delta = exact_after - exact_before
    exact_readings = delta_readings(manifest, run, model, exact_before, value, tooltips)
    if not exact_readings:
        return None
    reading = exact_readings[0]
    margin = FRACTIONAL_FLOOR
    status = 'ok' if abs(exact_delta - reading.delta) <= margin + FLOAT_EPSILON else 'alert'
    unmoved = (f'the integer {model["metric"]} the game uses read {run.values.get(model["before_label"]):g} '
               f'before and {run.values.get(model["after_label"]):g} after; only the pre-truncation value moved')
    return replace(base, status=status, measured=exact_delta, expected=reading.delta,
                   low=reading.delta - margin, high=reading.delta + margin, detail={DATA_ONLY: unmoved},
                   explanation=f'{context}; the pre-truncation {model["metric"]} read {exact_before:g} before and '
                               f'{exact_after:g} after, delta {exact_delta:+.6g}; {reading.name} ({reading.why}): '
                               f'expected delta {reading.delta:+.6g}; |delta - expected| <= {FRACTIONAL_FLOOR:g}, the '
                               f'rounding of the pre-truncation reading, with no relative margin')


def passive_verdict(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                    tooltips: TooltipSource) -> Verdict:
    model = expectation.model
    rank_id = expectation.rank_id
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   rank_id, expectation.check)
    if run is None:
        return replace(base, explanation=f'{entry["key"]} has no scenario to measure {expectation.check}')
    aura = run.values.get(model['aura_label'])
    if aura is None:
        return replace(base, explanation=missing_measurement(run, model['aura_label']))
    if aura <= 0:
        requirements = ', '.join(f'{name} {tooltips.spell_field(rank_id, name)}' for name in AURA_REQUIREMENTS)
        return replace(base, status='unmeasured', explanation=f'passive aura {rank_id} absent after learn '
                                                              f'({requirements})')
    before, after = run.values.get(model['before_label']), run.values.get(model['after_label'])
    if before is None or after is None:
        label = model['before_label'] if before is None else model['after_label']
        return replace(base, status='alert' if model['judged'] else 'unmeasured',
                       explanation=missing_measurement(run, label))
    delta = after - before
    moved = f'{model["metric"]} {before:g} before and {after:g} after the learn, delta {delta:+g}'
    if not model['judged']:
        return replace(base, status=MEASURED, measured=delta,
                       explanation=f'{moved}; reported, not judged: the tooltip does not single out this quantity')
    if model['metric'] == PARRY_CHANCE and before == 0:
        return replace(base, status='unmeasured', measured=delta,
                       explanation=f'{moved}; {NO_PARRY_BEFORE}')
    if model['relation'] in MULTIPLYING_RELATIONS and before == 0 and model['named'] is not False:
        return replace(base, status='unmeasured', measured=delta,
                       explanation=f'{moved}; relation {model["relation"]} multiplies the before value 0, so every '
                                   f'bonus gives a delta of 0')
    effect = model['effect']
    if tooltips.spell_field(rank_id, f'EffectApplyAuraName[{effect}]') == VERSUS_AURA_STATE:
        state = tooltips.spell_field(rank_id, f'EffectMiscValue[{effect}]')
        established = run.values.get(model.get('aura_state_label'))
        if established != 1:
            reason = (f'aura state {state} is not set on the dummy' if established == 0 else
                      f'aura {VERSUS_AURA_STATE} applies against a target in aura state {state}, which the '
                      f'scenario neither establishes nor measures on the dummy')
            return replace(base, status='unmeasured', measured=delta, explanation=f'{moved}; {reason}')
    try:
        caster = caster_stats_from(run.values, manifest['class_file'])
    except KeyError as error:
        return replace(base, measured=delta, explanation=f'base measurement {error} is missing from {run.key}')
    token = next((value for value in tooltips.read(rank_id, caster).values if value.text == expectation.displayed),
                 None)
    if token is None:
        return replace(base, measured=delta, explanation=f'{expectation.displayed} is no token of the tooltip of '
                                                         f'{rank_id} read with the measured stats')
    value, sign = signed_token(token, model['points'], tooltips, rank_id)
    if model['relation'] == 'share' and model['source_label'] not in run.values:
        return replace(base, measured=delta, explanation=missing_measurement(run, model['source_label']))
    readings = delta_readings(manifest, run, model, before, value, tooltips)
    if not readings:
        return replace(base, measured=delta, explanation=f'no comparison for relation {model["relation"]!r}')
    context = f'{moved}; {sign}, expected {value:+g}'
    if model['metric'] in TRUNCATED_METRICS and all(abs(reading.delta) < 1 for reading in readings):
        exact = exact_truncated_verdict(base, manifest, run, model, value, context, tooltips)
        if exact is not None:
            return exact
        return replace(base, status='unmeasured', measured=delta, expected=readings[0].delta,
                       explanation=f'{context}; the expected delta {readings[0].delta:+.6g} is below the 1-point '
                                   f'resolution of {model["metric"]}, which the server truncates to an integer')
    partners = effect_partners(entry, expectation)
    if partners and model['named'] is None:
        return judge_combined(base, manifest, run, model, partners, readings, before, delta, context,
                              tooltips.read(rank_id, caster).values, tooltips, rank_id)
    if len(readings) == 1:
        rounded = engine_rounding_verdict(base, model, before, delta, value, readings[0], context)
        if rounded is not None:
            return rounded
    judged = [(reading, delta_status(model['metric'], delta, reading.delta)) for reading in readings]
    if model['named'] is not None:
        return judge_modifier_target(base, manifest, entry, run, model, value, before, delta, judged, context,
                                     tooltips)
    return judge_readings(base, manifest, entry, run, model, judged, before, delta, context, tooltips)


def effect_partners(entry: dict, expectation: Expectation) -> list[dict]:
    model = expectation.model
    return [data for data in entry['expectations']
            if data['check'] == PASSIVE_DELTA and data['model'] and data['model']['judged']
            and data['model']['named'] is None and data['model']['effect'] != model['effect']
            and data['model']['metric'] == model['metric'] and data['model']['fields'] == model['fields']]


def combined_delta(relations: set[str], deltas: list[float], before: float) -> float | None:
    if relations == {'scale'}:
        return before * math.prod(1 + delta / before for delta in deltas) - before
    if relations <= ADDITIVE_RELATIONS:
        return sum(deltas)
    return None


def judge_combined(base: Verdict, manifest: dict, run: Run, model: dict, partners: list[dict],
                   readings: list[DeltaReading], before: float, delta: float, context: str, values: list[Displayed],
                   tooltips: TooltipSource, rank_id: int) -> Verdict:
    effects = ', '.join(str(data['model']['effect']) for data in partners)
    own = f'{context}; the delta also holds effect {effects} of the same passive on the same quantity'
    unjudged = replace(base, status=MEASURED, measured=delta,
                       explanation=f'{own}; reported, not judged: no single reading of the combined effects')
    if len(readings) != 1:
        return unjudged
    deltas, relations = [readings[0].delta], {model['relation']}
    for data in partners:
        token = next((value for value in values if value.text == data['displayed']), None)
        source = data['model']['source_label']
        if token is None or (data['model']['relation'] == 'share' and source not in run.values):
            return unjudged
        value, _ = signed_token(token, data['model']['points'], tooltips, rank_id)
        partner = delta_readings(manifest, run, data['model'], before, value, tooltips)
        if len(partner) != 1:
            return unjudged
        deltas.append(partner[0].delta)
        relations.add(data['model']['relation'])
    combined = combined_delta(relations, deltas, before)
    if combined is None:
        return replace(base, status=MEASURED, measured=delta,
                       explanation=f'{own}; reported, not judged: relations {", ".join(sorted(relations))} do not '
                                   f'combine without an order')
    reading = DeltaReading('combined', combined,
                           'product of the scale factors' if relations == {'scale'} else 'sum of the deltas')
    return interval_verdict(base, model['metric'], delta, [(reading, delta_status(model['metric'], delta, combined))],
                            own)


def roll_spread(expectation: Expectation, tooltips: TooltipSource) -> int:
    try:
        effect = token_effect(expectation)
        if effect is None:
            first = tooltips.first_effect(expectation.rank_id)
            effect = None if first is None else (expectation.rank_id, first)
        if effect is None:
            return 0
        return max(0, abs(tooltips.effect_points(*effect)[1]) - 1)
    except Unreadable:
        return 0


def judge(manifest: dict, entry: dict, run: Run | None, expectation: Expectation, tokens: Tokens | None,
          tooltips: TooltipSource, hit_model: HitModelSource) -> Verdict:
    verdict = judge_expectation(manifest, entry, run, expectation, tokens, tooltips, hit_model)
    if expectation.check not in ROLLED_CHECKS or verdict.measured is None:
        return verdict
    spread = roll_spread(expectation, tooltips)
    if not spread:
        return verdict
    return replace(verdict, detail={**(verdict.detail or {}), ROLL_SPREAD: spread})


def judge_expectation(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                      tokens: Tokens | None, tooltips: TooltipSource, hit_model: HitModelSource) -> Verdict:
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
    rule, check = expectation.rule, expectation.check
    measured = run.values.get(expectation.label) if run else None
    required_clock = (expectation.model or {}).get('gameplay_clock')
    if required_clock and run is not None and run.clock not in (None, required_clock):
        return replace(base, status='unmeasured', measured=measured,
                       explanation=f'recorded under the {run.clock} clock; this scenario requires '
                                   f'--gameplay-clock {required_clock} to exercise the tooltip clause, so this '
                                   f'attempt cannot prove or disprove it')
    if rule.startswith(CLOSED):
        return replace(base, status='closed', measured=measured, explanation=rule)
    if (check == 'unmodelled' or rule.startswith(UNMODELLED) or rule.startswith(UNMEASURABLE)
            or rule.startswith(GENERIC)):
        return replace(base, status='unmodelled', measured=measured, explanation=rule)
    if rule.startswith(UNREADABLE):
        found = unreadable_question(tooltips, expectation.rank_id, entry['spell_name'], manifest['level'],
                                    rule[len(UNREADABLE):], manifest['class_file'])
        return replace(base, status='unreadable', measured=measured, explanation=rule,
                       detail={'question': found} if found else None)
    if rule.startswith(AMBIGUOUS_TOOLTIP):
        text = class_entry(manifest, expectation).get('question') or rule[len(AMBIGUOUS_TOOLTIP):]
        return replace(base, status='ambiguous_tooltip', measured=measured, explanation=rule,
                       detail={'question': question_detail(TEXT_QUESTION, text, [], None)})
    if check == PASSIVE_DELTA:
        return judge_passive(manifest, entry, run, expectation, tooltips)
    if check in BEHAVIOUR_CHECKS or check == BEHAVIOUR_EXPIRY:
        return judge_behaviour(base, run, expectation)
    if run is None:
        return replace(base, explanation=f'{entry["key"]} has no scenario to measure {check}')
    if check in TOKEN_CHECKS and rule.startswith(READ_RULE):
        drift = token_drift(expectation, tokens)
        if drift:
            return replace(base, measured=measured, explanation=drift)
    failure = failed_cast(run, expectation.rank_id) if check in CAST_DEPENDENT_CHECKS else None
    if failure:
        return replace(base, status='unmeasured', measured=measured, explanation=f'cast failed: {failure}')
    if check in HIT_CHECKS:
        return per_level_unmodelled(judge_hit(base, manifest['class_file'], [(entry, run, expectation)], hit_model),
                                    tooltips, hit_spell_of(expectation), manifest['level'])
    if measured is None:
        return replace(base, explanation=f'no measurement {expectation.label!r} in {run.key} '
                                         f'({run.status}: {run.message})')
    if check == 'known_aura':
        status = 'ok' if measured > 0 else 'alert'
        return replace(base, status=status, measured=measured, expected=1.0, low=1.0, high=1.0,
                       explanation=f'known aura {expectation.spell_id} on the reference character')
    if check == 'power_cost':
        divisor = COST_DIVISOR.fullmatch(rule)
        if divisor:
            shown = measured / int(divisor.group(1))
            return deterministic(base, shown, shown, float(expectation.displayed),
                                 f'spell_power_cost divided by the display divisor {divisor.group(1)}')
    if check == 'cooldown_ms':
        return judge_time(base, run, measured, float(expectation.displayed), rule)
    if check == GAP_CLOSER_DISTANCE:
        return judge_gap_closer_distance(base, measured, float(expectation.displayed), rule)
    if check in TOKEN_CHECKS and rule.startswith(READ_RULE):
        verdict = judge_token(base, expectation, run, measured, tokens, tooltips, entry['spell_name'])
        if check == 'effect_value':
            return calc_amount_verdict(replace(verdict, detail={**(verdict.detail or {}), 'scope': EFFECT_VALUE_SCOPE}),
                                       run, expectation)
        return verdict
    return replace(base, measured=measured, explanation=f'no comparison for check {check!r} with rule {rule!r}')


def read_effect(expectation: Expectation) -> tuple[int, int | None]:
    model = expectation.model or {}
    if 'effect_spell' in model:
        return model['effect_spell'], model['effect']
    return expectation.rank_id, expectation.effect_index


def calc_amount_verdict(verdict: Verdict, run: Run, expectation: Expectation) -> Verdict:
    spell_id, effect = read_effect(expectation)
    label = calc_amount_hooks_label(expectation.label)
    hooks = run.values.get(label)
    if hooks is None:
        return replace(verdict, status='unmeasured',
                       explanation=f'no {label!r} reading in {run.key}: the CalcValue read of spell {spell_id} effect '
                                   f'{effect} cannot be told apart from an aura script CalcAmount hook that sets the '
                                   f'applied amount later; regenerate the scenario (the read alone would be '
                                   f'{verdict.status}: {verdict.explanation})',
                       detail={**(verdict.detail or {}), CALC_VALUE_STATUS: verdict.status})
    if hooks <= 0:
        return replace(verdict, detail={**(verdict.detail or {}), CALC_AMOUNT_HOOKS: 0})
    reading = 'nothing' if verdict.measured is None else f'{verdict.measured:g}'
    return replace(verdict, status=NOT_MEASURED,
                   explanation=f'CalcValue of spell {spell_id} effect {effect} read {reading}, but '
                               f'{hooks:g} DoEffectCalcAmount hook(s) of the aura scripts bound to spell {spell_id} '
                               f'set that effect\'s amount after CalcValue, so this read does not measure the amount '
                               f'the aura applies; an aura_amount read of a present aura does (the read alone would '
                               f'be {verdict.status}: {verdict.explanation})',
                   detail={**(verdict.detail or {}), CALC_AMOUNT_HOOKS: int(hooks), CALC_VALUE_STATUS: verdict.status})


LINKED_VERDICT_REFERENCE = re.compile(r'"([^"]+)" \(status \w+\)')


def resolve_linked_statuses(verdicts: list[Verdict]) -> list[Verdict]:
    by_label = {verdict.label: verdict.status for verdict in verdicts}

    def live_text(match: re.Match) -> str:
        label = match.group(1)
        return f'"{label}" (status {by_label.get(label, "unmodelled")})'

    resolved = []
    for verdict in verdicts:
        referenced = (LINKED_VERDICT_REFERENCE.findall(verdict.explanation)
                     if verdict.check == 'unmodelled' and 'checked by' in verdict.explanation else [])
        if not referenced:
            resolved.append(verdict)
            continue
        explanation = LINKED_VERDICT_REFERENCE.sub(live_text, verdict.explanation)
        status = 'closed' if all(by_label.get(label) in CONFORMANT for label in referenced) else verdict.status
        resolved.append(replace(verdict, status=status, explanation=explanation))
    return resolved


POOLED_CHECKS = frozenset({BEHAVIOUR_HIT_RATIO, BEHAVIOUR_TAKEN_HIT})


def evaluate(manifest_path: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
             hit_model: HitModelSource | None = None, build: str | None = None) -> Comparison:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    if 'spell_dbc_sha256' in manifest:
        require_server_sha(manifest['spell_dbc_sha256'], str(manifest_path))
    runs, missing = load_runs(manifest, Path(results_dir))
    judged, other_build = judged_build(runs, build)
    runs = {key: run for key, run in runs.items() if key not in other_build}
    tooltips = tooltips or DbcTooltips(manifest.get('dbc_dir', DBC_DIR), manifest.get('class_file'))
    hit_model = hit_model or measured_hit_model
    verdicts = []
    proc_parts: dict[str, list[ProcPart]] = {}
    delta_parts: dict[str, list[ProcPart]] = {}
    stack_parts: dict[str, list[ProcPart]] = {}
    trigger_parts: dict[str, list[ProcPart]] = {}
    hit_parts: dict[str, list[ProcPart]] = {}
    hit_slots: dict[str, int] = {}
    label_runs: dict[str, list[Run]] = {}
    pooled: dict[str, list[ProcPart]] = {}
    for entry in manifest['scenarios']:
        run = runs.get(entry['key'])
        if entry.get('file') and run is None:
            for data in entry['expectations']:
                if (data.get('model') or {}).get('parts', 1) > 1 and data['check'] in POOLED_CHECKS:
                    pooled.setdefault(data['label'], []).append((entry, None, Expectation(**data)))
            continue
        tokens = read_tokens(manifest['class_file'], entry, run, tooltips) if run and entry['kind'] == 'value' else None
        for data in entry['expectations']:
            expectation = Expectation(**data)
            if run is not None:
                label_runs.setdefault(expectation.label, []).append(run)
            if expectation.check == PROC_CHECK and run is not None:
                proc_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check == DELTA_CHECK and run is not None:
                delta_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in STACK_CHECKS and run is not None:
                stack_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in (TRIGGER_CHECK, COOLDOWN_CHECK, DURATION_CHECK, MAGNITUDE_CHECK,
                                       SELF_TRIGGER_CHECK, GATE_ABSENCE_CHECK) and run is not None:
                trigger_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in POOLED_CHECKS and (expectation.model or {}).get('parts', 1) > 1:
                if expectation.label not in hit_slots:
                    hit_slots[expectation.label] = len(verdicts)
                    verdicts.append(None)
                pooled.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in HIT_CHECKS and expectation.model and run is not None:
                if expectation.label not in hit_slots:
                    hit_slots[expectation.label] = len(verdicts)
                    verdicts.append(None)
                hit_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            else:
                verdicts.append(judge(manifest, entry, run, expectation, tokens, tooltips, hit_model))
    for label in pooled:
        if label not in hit_slots:
            hit_slots[label] = len(verdicts)
            verdicts.append(None)
    for label, parts in pooled.items():
        first_entry, _, expectation = parts[0]
        base = Verdict(label, 'alert', None, None, None, None, '',
                       ' + '.join(entry['key'] for entry, _, _ in parts), expectation.spell_id, expectation.rank_id,
                       expectation.check)
        present = [run for _, run, _ in parts if run is not None]
        pooled_judge = (behaviour_hit_ratio_verdict if expectation.check == BEHAVIOUR_HIT_RATIO
                        else behaviour_taken_rate_verdict)
        verdict = (pooled_judge(base, present, expectation.model)
                   if len(present) == expectation.model['parts']
                   else replace(base, status='unmeasured', explanation=f'{len(present)} of '
                                f'{expectation.model["parts"]} pooled parts ran'))
        verdict = with_excluded_band(verdict, expectation.check)
        verdicts[hit_slots[label]] = replace(verdict, detail={**(verdict.detail or {}), **observed(expectation)})
    for label, parts in hit_parts.items():
        first_entry, _, expectation = parts[0]
        base = Verdict(label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                       expectation.rank_id, expectation.check)
        verdicts[hit_slots[label]] = per_level_unmodelled(judge_hit(base, manifest['class_file'], parts, hit_model),
                                                          tooltips, hit_spell_of(parts[0][2]), manifest['level'])
    verdicts += [server_question(manifest, parts[0][2], judge_proc(manifest, parts, tooltips), tooltips)
                 for parts in proc_parts.values()]
    verdicts += [server_question(manifest, parts[0][2], judge_proc_delta(manifest, parts, tooltips), tooltips)
                 for parts in delta_parts.values()]
    trigger_judges = {TRIGGER_CHECK: judge_trigger, COOLDOWN_CHECK: judge_trigger_cooldown,
                      DURATION_CHECK: judge_trigger_duration, MAGNITUDE_CHECK: judge_trigger_magnitude,
                      SELF_TRIGGER_CHECK: judge_self_trigger, GATE_ABSENCE_CHECK: judge_gate_absence}
    verdicts += [server_question(manifest, parts[0][2], trigger_judges[parts[0][2].check](parts), tooltips)
                 for parts in trigger_parts.values()]
    verdicts += judge_stack(manifest, stack_parts, tooltips, hit_model)
    stamped = [with_provenance(verdict, judged, label_runs.get(verdict.label) or scenario_runs(runs, verdict))
               for verdict in resolve_linked_statuses(verdicts)]
    return Comparison(manifest, runs, missing, stamped, judged, other_build)


def scenario_runs(runs: Mapping[str, Run], verdict: Verdict) -> list[Run]:
    return [runs[key] for key in verdict.scenario.split(' + ') if key in runs]


def with_provenance(verdict: Verdict, build: Build, runs: list[Run]) -> Verdict:
    run_ids = sorted({run.run_id or run.key for run in runs})
    return replace(verdict, server_commit=build.server_commit, build=build.binary_sha256, runs=run_ids)


def verdicts_build(verdicts: list[Verdict]) -> Build | None:
    builds = {(verdict.server_commit, verdict.build) for verdict in verdicts}
    return Build(*builds.pop()) if len(builds) == 1 else None


def compare(manifest: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
            hit_model: HitModelSource | None = None, build: str | None = None) -> list[Verdict]:
    return evaluate(manifest, results_dir, tooltips=tooltips, hit_model=hit_model, build=build).verdicts


def cell(value) -> str:
    if value is None:
        return ''
    if isinstance(value, float):
        return f'{value:.6g}'
    return str(value).replace('\t', ' ').replace('\n', ' ')


def alert_rows(verdicts: list[Verdict]) -> list[str]:
    rows = ['\t'.join(ALERT_COLUMNS)]
    for verdict in sorted(verdicts, key=lambda verdict: (verdict.spell_id, verdict.rank_id, verdict.label,
                                                         verdict.scenario)):
        if verdict.status in NOT_ALERTS:
            continue
        deviation = (verdict.measured - verdict.expected
                     if verdict.measured is not None and verdict.expected is not None else None)
        rows.append('\t'.join(cell(value) for value in (
            verdict.scenario, verdict.spell_id, verdict.rank_id, verdict.label, verdict.check, verdict.status,
            verdict.measured, verdict.expected, verdict.low, verdict.high, deviation, verdict.explanation,
            verdict.server_commit, verdict.build, ' '.join(verdict.runs or ()))))
    return rows


def presence(runs: dict[str, Run], label: str) -> str:
    measured = [run.values[label] for run in runs.values() if label in run.values]
    return f'{sum(value > 0 for value in measured)} of {len(measured)} runs'


def passive_lines(manifest: dict, verdicts: list[Verdict]) -> list[str]:
    families = {(entry['key'], data['label']): (data['model'] or {}).get('family', '')
                for entry in manifest['scenarios'] if entry['kind'] == 'passive' for data in entry['expectations']}
    by_family: dict[str, Counter] = {}
    for verdict in verdicts:
        family = families.get((verdict.scenario, verdict.label))
        if family is not None:
            by_family.setdefault(family, Counter())[verdict.status] += 1
    if not by_family:
        return []
    lines = ['', '## Passives', '', 'Verdicts of the passive effects by measurement family.', '',
             '| family | ' + ' | '.join(STATUSES) + ' |', '|---|' + '---|' * len(STATUSES)]
    for family in sorted(by_family):
        counts = ' | '.join(str(by_family[family].get(status, 0)) for status in STATUSES)
        lines.append(f'| {family} | {counts} |')
    return lines


def observation_lines(class_file: dict, verdicts: list[Verdict]) -> list[str]:
    observations = player_observations(class_file)
    if not observations:
        return []
    by_label = {verdict.label: verdict for verdict in verdicts}
    lines = ['', '## Player observations', '',
             'A player report of production-server behaviour; it corroborates or contradicts a verdict, never '
             'sets an expected value or settles one on its own.', '',
             '| spell | name | citation | claim | corroborates | current status |', '|---|---|---|---|---|---|']
    for entry in sorted(observations, key=lambda entry: (entry.spell, entry.citation, entry.corroborates)):
        current = by_label.get(entry.corroborates)
        status = current.status if current is not None else 'label not in this run'
        lines.append(f'| {entry.spell} | {entry.name} | {entry.citation} | {cell(entry.claim)} | '
                     f'{cell(entry.corroborates)} | {status} |')
    return lines


def tooltip_reading_status(verdict: Verdict | None, reading, tooltips: TooltipSource) -> tuple[str, str]:
    if verdict is None or verdict.measured is None:
        return '', 'label not in this run'
    try:
        low, high = reading_band(tooltips, reading)
    except (Unreadable, ValueError) as error:
        return '', f'band unreadable: {error}'
    band = f'{low:.6g}' if low == high else f'{low:.6g}-{high:.6g}'
    margin = max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * abs(high))
    status = 'ok' if low - margin <= verdict.measured <= high + margin else 'alert'
    return band, status


def tooltip_reading_lines(manifest: dict, verdicts: list[Verdict], tooltips: TooltipSource) -> list[str]:
    readings = player_tooltip_readings(manifest['class_file'])
    if not readings:
        return []
    by_key = {(data['rank_id'], data['displayed']): data['label']
             for entry in manifest['scenarios'] for data in entry['expectations']}
    by_label = {verdict.label: verdict for verdict in verdicts}
    lines = ['', '## Player tooltip readings', '',
             'A tooltip number the client showed a player at a stated attack power and spell power; corroborates '
             'or contradicts the DBC-derived expected value measured at the reference caster, never sets it.', '',
             '| spell | token | player value | ap | sp | band at ap/sp | measured | status |',
             '|---|---|---|---|---|---|---|---|']
    for reading in sorted(readings, key=lambda reading: (reading.spell, reading.token)):
        label = by_key.get((reading.spell, reading.token))
        verdict = by_label.get(label) if label else None
        band, status = tooltip_reading_status(verdict, reading, tooltips)
        measured = cell(verdict.measured) if verdict is not None else ''
        sp_text = ', '.join(f'{sp:g}' for sp in reading.sp) if reading.sp else 'n/a'
        lines.append(f'| {reading.spell} | {cell(reading.token)} | {reading.value:g} | {reading.ap:g} | {sp_text} | '
                     f'{band} | {measured} | {status} |')
    return lines


def report_lines(manifest: dict, manifest_path: Path, results_dir: Path, runs: dict[str, Run], missing: list[str],
                 verdicts: list[Verdict], tooltips: TooltipSource | None = None,
                 other_build: Mapping[str, Build] | None = None) -> list[str]:
    statuses = Counter(verdict.status for verdict in verdicts)
    failed = sorted((key, run) for key, run in runs.items() if run.status != 'passed')
    judged = verdicts_build(verdicts)
    lines = [f'# Class conformance: {manifest["class_name"]} (class {manifest["class_id"]})', '',
             f'- Manifest: `{manifest_path}`', f'- Results: `{results_dir}`',
             f'- Build judged: {judged.text() if judged else "several builds among the verdicts"}',
             f'- Scenarios: {len(runs)} with a result, {len(missing)} without a result, {len(failed)} not passed, '
             f'{len(other_build or {})} refused as another build',
             '', '## Verdicts by status', '', '| status | count |', '|---|---|']
    lines += [f'| {status} | {statuses.get(status, 0)} |' for status in STATUSES]
    lines += ['', '## Known modifiers', '',
              'Applied to a hit model only when the run measures the aura on the character; values from Spell.dbc.',
              '', '| aura | effect | aura type | EffectBasePoints | EffectRealPointsPerLevel | value at level '
              f'{manifest["level"]} | measured present |', '|---|---|---|---|---|---|---|']
    modifiers = manifest.get('known_modifiers', [])
    for aura in manifest['class_file'].get('known_auras', []):
        rows = [modifier for modifier in modifiers if modifier['spell_id'] == aura]
        present = presence(runs, known_aura_label(aura))
        if not rows:
            lines.append(f'| {aura} | | no damage or healing modifier | | | | {present} |')
        for row in rows:
            lines.append(f'| {aura} | {row["effect_index"]} | {row["aura"]} | {row["base_points"]} | '
                         f'{row["real_points_per_level"]:g} | {row["percent"]:+d}% | {present} |')
    probes = manifest['class_file'].get('probe_auras', [])
    if probes:
        lines += ['', '## Probe auras', '', 'Measured and reported, never used to explain a deviation.', '',
                  '| aura | measured present |', '|---|---|']
        lines += [f'| {aura} | {presence(runs, probe_aura_label(aura))} |' for aura in probes]
    names = {entry['spell_id']: entry['spell_name'] for entry in manifest['scenarios']}
    by_spell: dict[int, Counter] = {}
    for verdict in verdicts:
        if verdict.check != 'known_aura':
            by_spell.setdefault(verdict.spell_id, Counter())[verdict.status] += 1
    lines += ['', '## Verdicts by spell', '', '| spell | name | ' + ' | '.join(STATUSES) + ' |',
              '|---|---|' + '---|' * len(STATUSES)]
    for spell_id in sorted(by_spell):
        counts = ' | '.join(str(by_spell[spell_id].get(status, 0)) for status in STATUSES)
        lines.append(f'| {spell_id} | {names.get(spell_id, "")} | {counts} |')
    lines += passive_lines(manifest, verdicts)
    lines += observation_lines(manifest['class_file'], verdicts)
    lines += tooltip_reading_lines(manifest, verdicts, tooltips)
    not_measured = sorted(verdict.label for verdict in verdicts if verdict.status == NOT_MEASURED)
    if not_measured:
        lines += ['', '## Not measured: CalcValue reads of effects whose amount a CalcAmount hook sets', '']
        lines += [f'- `{label}`' for label in not_measured]
    if other_build:
        lines += ['', '## Runs refused: another build than the one judged', '']
        lines += [f'- `{key}`: {build.text()}' for key, build in sorted(other_build.items())]
    if missing:
        lines += ['', '## Scenarios without a result', ''] + [f'- `{key}`' for key in missing]
    if failed:
        lines += ['', '## Runs that did not pass', ''] + [f'- `{key}`: {run.status}: {run.message}'
                                                          for key, run in failed]
    return lines + ['']


def write_outputs(manifest_path: Path, results_dir: Path, verdicts: list[Verdict], out_dir: Path, *,
                  tooltips: TooltipSource | None = None) -> tuple[Path, Path]:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, missing = load_runs(manifest, Path(results_dir))
    judged = verdicts_build(verdicts)
    other_build = {key: run_build(run) for key, run in runs.items() if judged is not None and run_build(run) != judged}
    runs = {key: run for key, run in runs.items() if key not in other_build}
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    alerts, report = out_dir / ALERTS_FILE, out_dir / REPORT_FILE
    alerts.write_text('\n'.join(alert_rows(verdicts)) + '\n', encoding='utf-8')
    write_verdicts(manifest, Path(manifest_path), Path(results_dir), verdicts, out_dir)
    asked_verdicts = [verdict for verdict in verdicts if asked(verdict)]
    has_readings = bool(manifest['class_file'].get('player_tooltip_readings'))
    source = tooltips or (DbcTooltips(manifest.get('dbc_dir', DBC_DIR), manifest.get('class_file'))
                         if asked_verdicts or has_readings else None)
    report.write_text('\n'.join(report_lines(manifest, Path(manifest_path), Path(results_dir), runs, missing,
                                             verdicts, source, other_build)), encoding='utf-8')
    write_questions(questions(asked_verdicts, source) if asked_verdicts else [], out_dir, source)
    return alerts, report


def write_verdicts(manifest: dict, manifest_path: Path, results_dir: Path, verdicts: list[Verdict],
                   out_dir: Path) -> Path:
    build = verdicts_build(verdicts) or Build(None, None)
    document = {'schema': VERDICTS_SCHEMA, 'class_id': manifest['class_id'], 'class_name': manifest['class_name'],
                'level': manifest['level'], 'manifest': str(manifest_path), 'results': str(results_dir),
                'spell_dbc_sha256': manifest.get('spell_dbc_sha256'), 'build': build.binary_sha256,
                'server_commit': build.server_commit, 'verdicts': [asdict(verdict) for verdict in verdicts]}
    path = Path(out_dir) / VERDICTS_FILE
    path.write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')
    return path


def read_verdicts(directory: Path) -> tuple[dict, list[Verdict]]:
    path = Path(directory) / VERDICTS_FILE
    if not path.is_file():
        raise ValueError(f'{path} does not exist; run conformance.py compare with this version to write it')
    document = json.loads(path.read_text(encoding='utf-8'))
    if document.get('schema') != VERDICTS_SCHEMA:
        raise ValueError(f'{path} has schema {document.get("schema")!r}, expected {VERDICTS_SCHEMA}')
    header = {key: value for key, value in document.items() if key != 'verdicts'}
    return header, [Verdict(**data) for data in document['verdicts']]


def amount(value: float | None, digits: int = 1) -> str:
    return '' if value is None else f'{value:.{digits}f}'


def change_decision(before: Verdict | None, after: Verdict) -> tuple[str, str]:
    if before is None:
        return '', ''
    if before.status != MEASURED or after.status != MEASURED:
        return '', f'no: DPS {before.status} then {after.status}'
    if min(fmean(before.detail['per_pass']), fmean(after.detail['per_pass'])) <= 0:
        return '', 'no: DPS mean is not above 0 on a side'
    delta, low, high = ratio_interval(after.detail['per_pass'], before.detail['per_pass'])
    relative = (high - low) / 2 / (100 + delta)
    span = f'{low:.2f} to {high:.2f}'
    if low <= 0 <= high:
        return span, 'no: the interval holds 0'
    if relative > MEAN_HALF_WIDTH + FLOAT_EPSILON:
        return span, f'no: half-width {relative:.2%} of the ratio, above {MEAN_HALF_WIDTH:.0%}'
    return span, 'yes'


def stack_runs(manifest: dict, runs: dict[str, Run]) -> dict[str, Run]:
    keys = {entry['key'] for entry in manifest['scenarios'] if entry['kind'] == 'stack'}
    return {key: run for key, run in runs.items() if key in keys}


def lever_lines(manifest: dict, manifest_path: Path, results_dir: Path, runs: dict[str, Run],
                verdicts: list[Verdict]) -> list[str]:
    class_file = manifest['class_file']
    rotation = class_file.get('rotation', {})
    sources = rotation.get('sources', []) + [MELEE_SOURCE]
    found = levers(verdicts)
    by_config = {verdict.detail['config']: verdict for verdict in verdicts
                 if verdict.check == STACK_DPS and verdict.detail}
    deltas = sorted((verdict for verdict in verdicts if verdict.check == TALENT_DELTA and verdict.detail),
                    key=lambda verdict: (verdict.detail['index'], verdict.spell_id))
    cycle = ', '.join(f'{step["action"]} {step.get("spell", step.get("ms", ""))}' for step in rotation.get('cycle', []))
    seconds = rotation['cycles'] * sum(step['ms'] for step in rotation['cycle'] if step['action'] == 'wait') / 1000
    lines = [f'# Lever map: {manifest["class_name"]} (class {manifest["class_id"]})', '',
             f'- Manifest: `{manifest_path}`', f'- Results: `{results_dir}`',
             f'- Rotation ({rotation.get("source", "class file")}): {rotation["cycles"]} cycles of [{cycle}], '
             f'auto attack {"on" if rotation.get("auto_attack") else "off"}, drain {rotation["drain_ms"]} ms; '
             f'damage per second of rotation ({seconds:g} s); the configurations add talents cumulatively.',
             '- Interval: 99% Student t interval of the mean of the passes; a talent delta is the ratio of the mean '
             'non-critical, unblocked hits of its source against the previous configuration, with a Welch interval.',
             '', '## Configurations', '',
             '| config | talents added | passes | DPS | 99% interval | change | change % | change 99% interval | '
             'decisive | tooltip bonus % | status |', '|---|---|---|---|---|---|---|---|---|---|---|']
    previous = None
    for lever in found:
        verdict = by_config[lever.config]
        change = (lever.dps_mean - previous.dps_mean
                  if previous and previous.dps_mean is not None and lever.dps_mean is not None else None)
        talents = ', '.join(str(talent) for talent in verdict.detail.get('talents', [])) or 'none'
        interval = f'{amount(lever.dps_low)} to {amount(lever.dps_high)}' if lever.dps_low is not None else ''
        span, decisive = change_decision(by_config[previous.config] if previous else None, verdict)
        lines.append(f'| {lever.config} | {talents} | {len(verdict.detail.get("per_pass", []))} | '
                     f'{amount(lever.dps_mean)} | {interval} | {amount(change)} | {amount(lever.delta_pct, 2)} | '
                     f'{span} | {decisive} | {amount(lever.tooltip_delta_pct, 2)} | {verdict.status} |')
        previous = lever
    names = ['melee' if source == MELEE_SOURCE else str(source) for source in sources]
    lines += ['', '## Damage per second by source', '',
              '| config | ' + ' | '.join(names) + ' | unattributed |', '|---|' + '---|' * (len(names) + 1)]
    for lever in found:
        cells = [amount(lever.sources.get(source)) for source in sources]
        rest = (lever.dps_mean - sum(lever.sources.values())) if lever.dps_mean is not None else None
        lines.append(f'| {lever.config} | ' + ' | '.join(cells) + f' | {amount(rest)} |')
    lines += ['', '## Change by source against the previous configuration', '',
              '| config | ' + ' | '.join(names) + ' |', '|---|' + '---|' * len(names)]
    for before, after in zip(found, found[1:]):
        cells = [amount(after.sources[source] - before.sources[source])
                 if source in after.sources and source in before.sources else '' for source in sources]
        lines.append(f'| {after.config} | ' + ' | '.join(cells) + ' |')
    lines += ['', '## Talent deltas', '', 'Measured change of the per-hit damage of the source, in percent.', '',
              '| config | talent | source | measured % | 99% interval | tooltip % | status | explanation |',
              '|---|---|---|---|---|---|---|---|']
    for verdict in deltas:
        interval = f'{amount(verdict.low, 2)} to {amount(verdict.high, 2)}' if verdict.low is not None else ''
        lines.append(f'| {verdict.detail["config"]} | {verdict.spell_id} | {verdict.detail.get("source", "")} | '
                     f'{amount(verdict.measured, 2)} | {interval} | {amount(verdict.expected, 2)} | {verdict.status} | '
                     f'{cell(verdict.explanation)} |')
    measured_runs = stack_runs(manifest, runs)
    lines += ['', '## Known modifiers', '', 'Measured on the character in the stack runs; values from Spell.dbc.', '',
              '| aura | effect | aura type | value | measured present |', '|---|---|---|---|---|']
    for aura in class_file.get('known_auras', []):
        rows = [row for row in manifest.get('known_modifiers', []) if row['spell_id'] == aura]
        present = presence(measured_runs, known_aura_label(aura))
        lines += [f'| {aura} | {row["effect_index"]} | {row["aura"]} | {row["percent"]:+d}% | {present} |'
                  for row in rows] or [f'| {aura} | | | | {present} |']
    for aura in class_file.get('probe_auras', []):
        lines.append(f'| {aura} (probe) | | | | {presence(measured_runs, probe_aura_label(aura))} |')
    lines += ['', '## Passes', '']
    lines += [f'- {verdict.label}: {verdict.status}: {verdict.explanation}' for verdict in verdicts
              if verdict.check in (STACK_DPS, STACK_SOURCE)]
    return lines + ['']


def write_levers(manifest_path: Path, results_dir: Path, verdicts: list[Verdict], out_dir: Path) -> Path:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, _ = load_runs(manifest, Path(results_dir))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / LEVERS_FILE
    path.write_text('\n'.join(lever_lines(manifest, Path(manifest_path), Path(results_dir), runs, verdicts)),
                    encoding='utf-8')
    return path
