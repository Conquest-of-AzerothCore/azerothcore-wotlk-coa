from collections import Counter
from dataclasses import asdict, dataclass, field, replace
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import re
from statistics import fmean, pstdev
from typing import Callable, Mapping, Protocol

from behaviours import (BEHAVIOUR_AMOUNT_DELTA, BEHAVIOUR_AURA_GRANT, BEHAVIOUR_CHECKS, BEHAVIOUR_COUNT,
                        BEHAVIOUR_CRIT_GUARANTEE, BEHAVIOUR_DURATION, BEHAVIOUR_DURATION_RATIO,
                        BEHAVIOUR_DURATION_REFRESH, BEHAVIOUR_INTERNAL_COOLDOWN_GATE, BEHAVIOUR_METRIC_DELTA,
                        BEHAVIOUR_OATH_CONSUMPTION, BEHAVIOUR_OATH_CONSUMPTION_REMOVAL, BEHAVIOUR_RATIO,
                        BEHAVIOUR_TRIGGER)
from hits import (CLOSED, HEAL, MEAN_HALF_WIDTH, SCHOOL_DAMAGE, UNMODELLED, WEAPON_FLAT_EFFECTS,
                  WEAPON_PERCENT_DAMAGE, Z_99, HitModel, Modifier, Unmodelled, measured_hit_model)
from observations import player_observations
from tooltip_readings import player_tooltip_readings, reading_band, reading_for
from passives import PASSIVE_DELTA, VERSUS_AURA_STATE, cleaned_tooltip, literal_token
from procs import AMBIGUOUS_TOOLTIP, CAST, DELTA_CHECK, DELTA_SANITY_FACTOR, PROC_CHECK, chance_of, wilson_interval
from profile import DBC_DIR, EQUIP_FIELDS, armed, caster_stats_from, known_aura_label, probe_aura_label
from questions import (DATA_ISSUE, READINGS_QUESTION, SERVER_BEHAVIOUR, TEXT_QUESTION, TOOLTIP_VALUE, asked, cleaned,
                       questions, spell_name, write_questions)
from stack import (ADDS, MEASURED, MELEE_SOURCE, MULTIPLIES, STACK_CHECKS, STACK_DPS, STACK_SOURCE, TALENT_DELTA,
                   levers, mean_interval, ratio_interval)
from tooltip import CasterStats, Displayed, ForcedPoints, Readout, Records, Tooltip, Unreadable
from triggers import (COOLDOWN_CHECK, DURATION_CHECK, EVENT_TOLERANCE, PERIODIC, TRIGGER_CHECK,
                      cooldown_trial_label, duration_trial_label)
from values import (CAST_MARGIN_MS, CAST_WAIT_LABEL, EFFECTS, FIXED_DIE_SIDES, GENERIC, UNMEASURABLE, UNREADABLE,
                    Expectation, dataset, mean_samples, roll_range, sample_labels)

STATUSES = ('ok', 'tolerated', 'alert', 'unreadable', 'unmodelled', 'ambiguous_tooltip', 'insufficient_trials',
            'unmeasured', MEASURED, 'closed')
NOT_ALERTS = frozenset({'ok', MEASURED, 'closed'})
CONFORMANT = frozenset({'ok', 'tolerated', 'closed'})
CAST_DEPENDENT_CHECKS = frozenset({'cooldown_ms', 'aura_amount', 'aura_duration_ms', 'aura_amplitude_ms'})
NO_CAST_FAILURE = 0
CAST_RESULTS_HEADER = Path(__file__).resolve().parents[3] / 'src/server/shared/SharedDefines.h'
CAST_RESULT_ENUM = re.compile(r'enum SpellCastResult\b[^{]*\{(?P<body>[^}]*)\}')
CAST_RESULT_ENTRY = re.compile(r'^\s*(?P<name>SPELL_\w+)\s*=\s*(?P<code>\d+)', re.MULTILINE)
ABSOLUTE_TOLERANCE = 1.0
RELATIVE_TOLERANCE = 0.005
TOLERATED_RELATIVE = 0.05
FLOAT_EPSILON = 1e-9
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
                 'deviation', 'explanation')
ALERTS_FILE = 'alerts.tsv'
REPORT_FILE = 'report.md'
LEVERS_FILE = 'levers.md'
VERDICTS_FILE = 'verdicts.json'
VERDICTS_SCHEMA = 1
SPELL_DURATION_SCOPE = ('base duration after the player\'s SPELLMOD_DURATION modifiers, before script hooks: a '
                        'ScriptMgr::OnCalcMaxDuration change is not covered')
EFFECT_VALUE_SCOPE = 'CalcValue before aura scripts (CalcAmount hooks not covered)'
PERCENT_POINT_METRICS = frozenset({'melee_crit_chance', 'melee_crit_chance_refreshed', 'spell_crit_chance',
                                   'melee_hit_chance', 'spell_hit_chance', 'parry_chance', 'dodge_chance',
                                   'spell_done_crit_chance'})
FRACTIONAL_METRICS = PERCENT_POINT_METRICS | {'weapon_damage_min'}
FRACTIONAL_FLOOR = 0.01
CRITICAL_DAMAGE_BASE = 1000
DIRECT_CRIT_DAMAGE_AURA = 163
DURATION_KIND = 'duration_ms'
PASSIVE_METRIC = 'metric'
PARRY_CHANCE = 'parry_chance'
NO_PARRY_BEFORE = ('parry_chance 0 before the learn: the reference character cannot parry (Player::CanParry false) '
                   'and a parry aura enables parry when applied (AuraEffect::HandleAuraModParryPercent), so the delta '
                   'holds the base parry chance as well as the bonus')
MULTIPLYING_RELATIONS = frozenset({'spell_mod_pct', 'scale', 'ratio', 'composition', 'crit_damage'})
ADDITIVE_RELATIONS = frozenset({'add', 'share'})
TRUNCATED_METRICS = frozenset({'stat'})
CLASS_ENTRIES = {PROC_CHECK: ('procs', 'aura'), TRIGGER_CHECK: ('triggers', 'aura'),
                 COOLDOWN_CHECK: ('triggers', 'aura'), DURATION_CHECK: ('triggers', 'aura'),
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


@dataclass(frozen=True)
class Run:
    key: str
    status: str
    message: str
    values: dict[str, float]
    steps: list[dict]
    max_step_ms: float | None
    cast_failures: dict[int, list[int]] = field(default_factory=dict)


class TooltipSource(Protocol):
    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None) -> Readout: ...

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

    def read(self, rank_id: int, caster: CasterStats, forced: tuple[int, int, int] | None = None) -> Readout:
        records = self.records if forced is None else ForcedPoints(self.dbc, *forced)
        description = records.field('Spell', rank_id, 'Description[enUS]')
        readout = Tooltip(records, rank_id, caster).read(description)
        literal = literal_values(self.class_file, rank_id, description)
        return replace(readout, values=readout.values + literal) if literal else readout

    def effect_points(self, spell_id: int, effect: int) -> tuple[int, int]:
        return (self.records.field('Spell', spell_id, f'EffectBasePoints[{effect}]'),
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
               cast_failures(result))


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


def exact(base: Verdict, measured: float, expected: float, why: str) -> Verdict:
    status = 'ok' if abs(measured - expected) <= FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=expected, high=expected,
                   explanation=f'{why}; a count is compared exactly')


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
    status = banded_status(mean, low, high, expected)
    tolerated_note = '; outside the 99% interval but within 5% of expected: tolerated' if status == 'tolerated' else ''
    return replace(base, status=status, measured=mean, expected=expected, low=low, high=high, detail=detail,
                   explanation=f'{roll}; 99% interval of the mean, expected mean +- Z x sigma / sqrt(reads) '
                               f'{half:.3f}, widened by {TRUNCATED_READ:g} toward zero for the int32 truncation of '
                               f'CalcValue{tolerated_note}')


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
        return deterministic(base, measured, measured, expected * plain_sign(points),
                             f'{token.text} is shown unsigned; the expected value takes the sign of its Spell.dbc '
                             f'points {points}')
    if measured * expected < 0:
        return replace(base, status='ambiguous_tooltip', measured=measured, expected=expected,
                       explanation=f'{token.text} evaluates to {expected:g}, the measured value has the opposite sign',
                       detail={'question': sign_question(base, name, token.text, measured, expected)})
    return deterministic(base, measured, measured, expected, f'{token.text} read with the measured stats')


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
    first = models[0][0]
    modifiers = ' or '.join(dict.fromkeys(describe_modifiers(expected.modifiers) for expected, _ in models))
    kind_term = 'mean'
    if expectation.check == PERIODIC_TOTAL:
        ticks = model['hits_per_cast']
        mean, expected_mean, half = mean * ticks, expected_mean * ticks, half * ticks
        low, high = expected_mean - half, expected_mean + half
        kind_term = f'total over {ticks} ticks'
    return replace(base, status=status, measured=mean, expected=expected_mean, low=low, high=high,
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


def judge_proc(manifest: dict, parts: list[ProcPart], tooltips: TooltipSource) -> Verdict:
    first_entry, first_run, expectation = parts[0]
    model = expectation.model
    base = Verdict(expectation.label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                   expectation.rank_id, expectation.check)
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
    try:
        caster = caster_stats_from(first_run.values, manifest['class_file'])
    except KeyError as error:
        return replace(base, measured=measured, explanation=f'base measurement {error} is missing from {first_run.key}')
    chance = chance_of(tooltips.read(expectation.rank_id, caster).values, expectation.displayed)
    if chance is None:
        return replace(base, measured=measured, explanation=f'the tooltip of {expectation.rank_id} no longer shows '
                                                            f'the chance token {expectation.displayed}')
    if abs(chance - model['chance_pct']) > FLOAT_EPSILON:
        return replace(base, measured=measured, expected=chance / 100,
                       explanation=f'{expectation.displayed} shows {chance:g}%, generated as {model["chance_pct"]:g}%')
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


def passes_needed(passes: int, relative_half: float) -> int:
    return math.ceil(passes * (relative_half / MEAN_HALF_WIDTH) ** 2)


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
    if relative > MEAN_HALF_WIDTH + FLOAT_EPSILON:
        needed = passes_needed(min(len(current), len(baseline)), relative)
        return replace(base, status='insufficient_trials', measured=delta, expected=model['bonus_pct'], low=low,
                       high=high, explanation=f'half-width {half:.3g} points is {relative:.2%} of the expected ratio '
                                              f'{1 + model["bonus_pct"] / 100:g}, above the {MEAN_HALF_WIDTH:.0%} '
                                              f'bound of hit means; about {needed} passes per configuration would '
                                              f'meet it (observed variance, same t quantile); per-hit means of '
                                              f'{source}: {listed(current)} against {listed(baseline)}{failures}')
    judged = [(name, expected, 'ok' if low - FLOAT_EPSILON <= expected <= high + FLOAT_EPSILON else 'alert', why)
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
    detail = base.detail
    if status == 'ambiguous_tooltip':
        detail = {**base.detail, 'question': talent_question(manifest, expectation, judged, delta, known, tooltips)}
    return replace(base, status=status, measured=delta, expected=expected_value, low=low, high=high, detail=detail,
                   explanation=f'{lead}{readings}; per-hit means of {source} in {len(current)} and {len(baseline)} '
                               f'passes: {listed(current)} against {listed(baseline)}; 99% Welch interval of the '
                               f'ratio of the means, half-width {relative:.2%} of the expected ratio; '
                               f'{expectation.rule}{failures}')


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
    return max(floor, RELATIVE_TOLERANCE * abs(expected))


def delta_status(metric: str, measured: float, expected: float) -> str:
    if abs(measured) <= FLOAT_EPSILON < abs(expected):
        return 'alert'
    margin = delta_margin(metric, expected)
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
    floor = delta_floor(metric)
    readings = '; '.join(f'{item.name} ({item.why}): expected delta {item.delta:+.6g}: {item_status}'
                         for item, item_status in judged)
    return replace(base, status=status, measured=delta, expected=reading.delta, low=reading.delta - margin,
                   high=reading.delta + margin,
                   explanation=f'{context}; {readings}; |delta - expected| <= max({floor:g}, '
                               f'{RELATIVE_TOLERANCE:.1%} of expected)')


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
    measured_before, measured_after = sum(before_hit), sum(after_hit)
    if measured_before:
        return replace(base, status='unmeasured', measured=float(measured_after - measured_before),
                       explanation=f'{measured_before} of {len(before_hit)} additional dummies were already hit '
                                   f'before the passive was learned; the delta cannot be isolated')
    delta = measured_after - measured_before
    expected = float(model['expected'])
    status = delta_status(BEHAVIOUR_COUNT, delta, expected)
    margin = delta_margin(BEHAVIOUR_COUNT, expected)
    return replace(base, status=status, measured=float(delta), expected=expected, low=expected - margin,
                   high=expected + margin,
                   explanation=f'{measured_before} of {len(before_hit)} additional dummies hit before the learn, '
                               f'{measured_after} after; |measured - expected| <= '
                               f'max({delta_floor(BEHAVIOUR_COUNT):g}, {RELATIVE_TOLERANCE:.1%} of expected), and '
                               f'a measured 0 against a nonzero expected is always an alert')


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
    missing = next((label for label, value in ((model['damage_label'], damage), (model['heal_label'], heal),
                                               (baseline_label, baseline)) if label and value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, missing))
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
    before_ok = abs(before - before_expected) <= METRIC_DELTA_FLOAT_TOLERANCE
    after_ok = abs(after - expected) <= METRIC_DELTA_FLOAT_TOLERANCE
    status = 'ok' if before_ok and after_ok else 'alert'
    return replace(base, status=status, measured=after, expected=expected, low=expected, high=expected,
                   explanation=f'{model["metric"]} measured {before:g} before the learn (expected '
                               f'{before_expected:g}) and {after:g} after (expected {expected:g}); match within '
                               f'{METRIC_DELTA_FLOAT_TOLERANCE:g} required, wide enough to absorb IEEE-754 float32 '
                               f'round-trip noise on a ratio metric (observed ~1e-7) but far below any real '
                               f'defect in this family of checks, with no combat-roll variance of its own')


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
    return replace(base, status=status, measured=ratio, expected=1.0, low=1.0, high=1.0,
                   explanation=f'{crit:g} critical of {total:g} {model["trial_spell"]} hits against '
                               f'{model["target_name"]} ({model["creature_type_source"]}); every triggered hit '
                               f'must critically strike ({model["quote"]!r}); a ratio below 1.0 is tolerated '
                               f'within {TOLERATED_RELATIVE:.0%} of 1.0, otherwise alert')


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


def judge_behaviour(base: Verdict, run: Run | None, expectation: Expectation) -> Verdict:
    if run is None:
        return replace(base, explanation=f'{base.scenario} has no scenario to measure {expectation.check}')
    model = expectation.model
    if expectation.check == BEHAVIOUR_COUNT:
        return behaviour_count_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_RATIO:
        if model.get('kind') == 'leech_ratio':
            return behaviour_leech_ratio_verdict(base, run, model)
        return behaviour_ratio_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION_REFRESH:
        return behaviour_duration_refresh_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_TRIGGER:
        return behaviour_trigger_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_METRIC_DELTA:
        return behaviour_metric_delta_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION:
        return behaviour_duration_verdict(base, run, model)
    if expectation.check == BEHAVIOUR_DURATION_RATIO:
        return behaviour_duration_ratio_verdict(base, run, model)
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
    return replace(base, explanation=f'behaviour check {expectation.check!r} has no judge rule')


def judge_passive(manifest: dict, entry: dict, run: Run | None, expectation: Expectation,
                  tooltips: TooltipSource) -> Verdict:
    verdict = passive_verdict(manifest, entry, run, expectation, tooltips)
    return replace(verdict, detail={**(verdict.detail or {}), PASSIVE_METRIC: expectation.model['metric']})


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
    margin = max(FRACTIONAL_FLOOR, RELATIVE_TOLERANCE * abs(reading.delta))
    status = 'ok' if abs(exact_delta - reading.delta) <= margin + FLOAT_EPSILON else 'alert'
    return replace(base, status=status, measured=exact_delta, expected=reading.delta,
                   low=reading.delta - margin, high=reading.delta + margin,
                   explanation=f'{context}; the pre-truncation {model["metric"]} read {exact_before:g} before and '
                               f'{exact_after:g} after, delta {exact_delta:+.6g}; {reading.name} ({reading.why}): '
                               f'expected delta {reading.delta:+.6g}; |delta - expected| <= max({FRACTIONAL_FLOOR:g}, '
                               f'{RELATIVE_TOLERANCE:.1%} of expected)')


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
    if check in BEHAVIOUR_CHECKS:
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
        return judge_hit(base, manifest['class_file'], [(entry, run, expectation)], hit_model)
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
    if check in TOKEN_CHECKS and rule.startswith(READ_RULE):
        verdict = judge_token(base, expectation, run, measured, tokens, tooltips, entry['spell_name'])
        if check == 'effect_value':
            return replace(verdict, detail={**(verdict.detail or {}), 'scope': EFFECT_VALUE_SCOPE})
        return verdict
    return replace(base, measured=measured, explanation=f'no comparison for check {check!r} with rule {rule!r}')


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


def evaluate(manifest_path: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
             hit_model: HitModelSource | None = None) -> Comparison:
    manifest = json.loads(Path(manifest_path).read_text(encoding='utf-8'))
    runs, missing = load_runs(manifest, Path(results_dir))
    tooltips = tooltips or DbcTooltips(manifest.get('dbc_dir', DBC_DIR), manifest.get('class_file'))
    hit_model = hit_model or measured_hit_model
    verdicts = []
    proc_parts: dict[str, list[ProcPart]] = {}
    delta_parts: dict[str, list[ProcPart]] = {}
    stack_parts: dict[str, list[ProcPart]] = {}
    trigger_parts: dict[str, list[ProcPart]] = {}
    hit_parts: dict[str, list[ProcPart]] = {}
    hit_slots: dict[str, int] = {}
    for entry in manifest['scenarios']:
        run = runs.get(entry['key'])
        if entry.get('file') and run is None:
            continue
        tokens = read_tokens(manifest['class_file'], entry, run, tooltips) if run and entry['kind'] == 'value' else None
        for data in entry['expectations']:
            expectation = Expectation(**data)
            if expectation.check == PROC_CHECK and run is not None:
                proc_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check == DELTA_CHECK and run is not None:
                delta_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in STACK_CHECKS and run is not None:
                stack_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in (TRIGGER_CHECK, COOLDOWN_CHECK, DURATION_CHECK) and run is not None:
                trigger_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            elif expectation.check in HIT_CHECKS and expectation.model and run is not None:
                if expectation.label not in hit_slots:
                    hit_slots[expectation.label] = len(verdicts)
                    verdicts.append(None)
                hit_parts.setdefault(expectation.label, []).append((entry, run, expectation))
            else:
                verdicts.append(judge(manifest, entry, run, expectation, tokens, tooltips, hit_model))
    for label, parts in hit_parts.items():
        first_entry, _, expectation = parts[0]
        base = Verdict(label, 'alert', None, None, None, None, '', first_entry['key'], expectation.spell_id,
                       expectation.rank_id, expectation.check)
        verdicts[hit_slots[label]] = judge_hit(base, manifest['class_file'], parts, hit_model)
    verdicts += [server_question(manifest, parts[0][2], judge_proc(manifest, parts, tooltips), tooltips)
                 for parts in proc_parts.values()]
    verdicts += [server_question(manifest, parts[0][2], judge_proc_delta(manifest, parts, tooltips), tooltips)
                 for parts in delta_parts.values()]
    trigger_judges = {TRIGGER_CHECK: judge_trigger, COOLDOWN_CHECK: judge_trigger_cooldown,
                      DURATION_CHECK: judge_trigger_duration}
    verdicts += [server_question(manifest, parts[0][2], trigger_judges[parts[0][2].check](parts), tooltips)
                 for parts in trigger_parts.values()]
    verdicts += judge_stack(manifest, stack_parts, tooltips, hit_model)
    return Comparison(manifest, runs, missing, resolve_linked_statuses(verdicts))


def compare(manifest: Path, results_dir: Path, *, tooltips: TooltipSource | None = None,
            hit_model: HitModelSource | None = None) -> list[Verdict]:
    return evaluate(manifest, results_dir, tooltips=tooltips, hit_model=hit_model).verdicts


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
            verdict.measured, verdict.expected, verdict.low, verdict.high, deviation, verdict.explanation)))
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
                 verdicts: list[Verdict], tooltips: TooltipSource | None = None) -> list[str]:
    statuses = Counter(verdict.status for verdict in verdicts)
    failed = sorted((key, run) for key, run in runs.items() if run.status != 'passed')
    lines = [f'# Class conformance: {manifest["class_name"]} (class {manifest["class_id"]})', '',
             f'- Manifest: `{manifest_path}`', f'- Results: `{results_dir}`',
             f'- Scenarios: {len(runs)} with a result, {len(missing)} without a result, {len(failed)} not passed',
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
                                             verdicts, source)), encoding='utf-8')
    write_questions(questions(asked_verdicts, source) if asked_verdicts else [], out_dir, source)
    return alerts, report


def write_verdicts(manifest: dict, manifest_path: Path, results_dir: Path, verdicts: list[Verdict],
                   out_dir: Path) -> Path:
    document = {'schema': VERDICTS_SCHEMA, 'class_id': manifest['class_id'], 'class_name': manifest['class_name'],
                'level': manifest['level'], 'manifest': str(manifest_path), 'results': str(results_dir),
                'verdicts': [asdict(verdict) for verdict in verdicts]}
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
