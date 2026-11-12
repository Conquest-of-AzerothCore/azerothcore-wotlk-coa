from collections import Counter
from dataclasses import dataclass
import math
from pathlib import Path

from compare import (ABSOLUTE_TOLERANCE, FLOAT_EPSILON, HIT_CHECKS, PASSIVE_METRIC, ROLL_SPREAD, Verdict, delta_margin,
                     margin_of, read_verdicts)
from passives import PASSIVE_DELTA
from procs import PROC_CHECK
from stack import STACK_CHECKS

IMPACT_FILE = 'impact.md'
TIME_CHECK = 'cooldown_ms'
INTERVAL_CHECKS = HIT_CHECKS | STACK_CHECKS | {PROC_CHECK}
MOVED, ADDED, REMOVED = 'moved', 'added', 'removed'
NOT_JUDGED = 'not judged: no interval on a side'


@dataclass(frozen=True)
class Change:
    label: str
    spell_id: int
    before: float | None
    after: float | None
    delta_pct: float | None
    significant: bool
    intended: bool
    kind: str = MOVED
    status_before: str | None = None
    status_after: str | None = None
    rule: str = ''
    scenario: str = ''
    judged: bool = True

    @property
    def status_changed(self) -> bool:
        return self.status_before != self.status_after

    @property
    def listed(self) -> bool:
        return self.significant or self.status_changed or self.kind != MOVED or not self.judged


Interval = tuple[float, float]


Key = tuple[str, str, str]


def key_of(verdict: Verdict) -> Key:
    return verdict.label, verdict.check, verdict.scenario


def indexed(verdicts: list[Verdict], side: str) -> dict[Key, Verdict]:
    result: dict[Key, Verdict] = {}
    for verdict in verdicts:
        key = key_of(verdict)
        if key in result:
            raise ValueError(f'{side} holds two verdicts for {key[0]!r} ({key[1]}) in scenario {key[2]!r}')
        result[key] = verdict
    return result


def reach(verdict: Verdict) -> Interval | None:
    if verdict.measured is None or verdict.low is None or verdict.high is None:
        return None
    if verdict.check in HIT_CHECKS:
        half = (verdict.high - verdict.low) / 2
        return half, half
    if verdict.check in INTERVAL_CHECKS:
        return verdict.measured - verdict.low, verdict.high - verdict.measured
    return None


def tolerance(before: Verdict, after: Verdict) -> float:
    if before.check == TIME_CHECK and after.check == TIME_CHECK:
        windows = [verdict.high - verdict.low for verdict in (before, after)
                   if verdict.low is not None and verdict.high is not None]
        if windows:
            return max(windows)
    metric = passive_metric(before, after)
    for reference in (after.expected, before.expected, before.measured):
        if reference is not None:
            return delta_margin(metric, reference) if metric else margin_of(reference)
    return delta_margin(metric, 0.0) if metric else ABSOLUTE_TOLERANCE


def passive_metric(before: Verdict, after: Verdict) -> str | None:
    return next(((verdict.detail or {}).get(PASSIVE_METRIC) for verdict in (after, before)
                 if verdict.check == PASSIVE_DELTA and (verdict.detail or {}).get(PASSIVE_METRIC)), None)


def significance(before: Verdict, after: Verdict) -> tuple[bool, bool, str]:
    if before.measured is None or after.measured is None:
        return False, True, 'no measured value on a side'
    difference = after.measured - before.measured
    if before.check in INTERVAL_CHECKS:
        reaches = (reach(before), reach(after))
        if None in reaches:
            return False, difference == 0, NOT_JUDGED if difference else 'no interval on a side, same value'
        facing = (reaches[0][1], reaches[1][0]) if difference > 0 else (reaches[0][0], reaches[1][1])
        needed = math.hypot(*facing)
        if needed <= FLOAT_EPSILON:
            needed = tolerance(before, after)
            return (abs(difference) > needed + FLOAT_EPSILON, True,
                    f'difference {difference:+.6g} against the deterministic tolerance {needed:.6g}: both 99% '
                    f'intervals have no width')
        return (abs(difference) > needed + FLOAT_EPSILON, True,
                f'difference {difference:+.6g} against {needed:.6g}, the root of the squared facing half-widths of the '
                f'two 99% intervals ({facing[0]:.6g}, {facing[1]:.6g})')
    needed = tolerance(before, after)
    spread = max((verdict.detail or {}).get(ROLL_SPREAD, 0) for verdict in (before, after))
    rolled = f' plus the roll spread {spread:g}' if spread else ''
    return (abs(difference) > needed + spread + FLOAT_EPSILON, True,
            f'difference {difference:+.6g} against the deterministic tolerance {needed:.6g}{rolled}')


def relative_change(before: float | None, after: float | None) -> float | None:
    if before is None or after is None or before == 0:
        return None
    return (after - before) / abs(before) * 100


def is_intended(verdict: Verdict, intended: set[int]) -> bool:
    return bool({verdict.spell_id, verdict.rank_id} - {0} & intended)


def diff(before: list[Verdict], after: list[Verdict], intended: set[int]) -> list[Change]:
    old, new = indexed(before, 'before'), indexed(after, 'after')
    changes = []
    for key in sorted(old.keys() | new.keys()):
        first, second = old.get(key), new.get(key)
        if first is None:
            changes.append(Change(second.label, second.spell_id, None, second.measured, None, False,
                                  is_intended(second, intended), ADDED, None, second.status, 'label only after',
                                  second.scenario))
        elif second is None:
            changes.append(Change(first.label, first.spell_id, first.measured, None, None, False,
                                  is_intended(first, intended), REMOVED, first.status, None, 'label only before',
                                  first.scenario))
        elif first.measured != second.measured or first.status != second.status:
            significant, judged, rule = significance(first, second)
            changes.append(Change(second.label, second.spell_id, first.measured, second.measured,
                                  relative_change(first.measured, second.measured), significant,
                                  is_intended(second, intended), MOVED, first.status, second.status, rule,
                                  second.scenario, judged))
    return changes


def number(value: float | None) -> str:
    return '' if value is None else f'{value:.6g}'


def percent(value: float | None) -> str:
    return '' if value is None else f'{value:+.2f}%'


def row(change: Change) -> str:
    states = f'{change.status_before or "-"} to {change.status_after or "-"}'
    kind = change.kind
    if kind == MOVED:
        kind = 'significant' if change.significant else 'inside intervals' if change.judged else 'not judged'
    return (f'| {change.label} | {change.scenario} | {change.spell_id} | {number(change.before)} | '
            f'{number(change.after)} | {percent(change.delta_pct)} | {states} | {kind} | {change.rule} |')


def table(changes: list[Change]) -> list[str]:
    header = ['| label | scenario | spell | before | after | change | status | kind | rule |',
              '|---|---|---|---|---|---|---|---|---|']
    ordered = sorted(changes, key=lambda change: (not change.significant, not change.status_changed, change.spell_id,
                                                  change.label, change.scenario))
    return header + [row(change) for change in ordered]


def blind_warning(kinds: Counter, sizes: tuple[int, int]) -> list[str]:
    removed, added = kinds[REMOVED], kinds[ADDED]
    if removed * 2 <= sizes[0] and added * 2 <= sizes[1]:
        return []
    return [f'**Warning: {removed} of {sizes[0]} verdicts before and {added} of {sizes[1]} after have no counterpart '
            f'(more than half of a side). The verdict keys (label, check, scenario) probably changed format, or the '
            f'runs cover different scenarios: the comparison is blind to most verdicts.**', '']


def impact_lines(changes: list[Change], intended: set[int], before_header: dict, after_header: dict,
                 before_dir: Path, after_dir: Path, sizes: tuple[int, int]) -> list[str]:
    noteworthy = [change for change in changes if change.listed]
    quiet = [change for change in changes if not change.listed]
    unjudged = sum(not change.judged for change in changes)
    unintended = [change for change in noteworthy if not change.intended]
    wanted = [change for change in noteworthy if change.intended]
    kinds = Counter(change.kind for change in changes)
    lines = [f'# Conformance impact: {after_header["class_name"]} (class {after_header["class_id"]})', '',
             *blind_warning(kinds, sizes),
             f'- Before: `{before_dir}` (manifest `{before_header["manifest"]}`)',
             f'- After: `{after_dir}` (manifest `{after_header["manifest"]}`)',
             f'- Intended spells: {", ".join(map(str, sorted(intended))) or "none"}',
             '- Significant: the measured values differ by more than the root of the squared facing half-widths of '
             'their own 99% intervals (hit and melee means, proc rates, stack passes, talent deltas), or by more than '
             'the deterministic tolerance of the comparison (max(1, 0.5% of expected); the cooldown window for '
             'cooldowns) for the other checks. A side without an interval or a measured value is never significant; '
             'when the values differ and an interval check has no interval on a side, the change is `not judged` '
             'and listed.',
             '- Listed: significant changes, not judged changes, every status change, and labels present on one '
             'side only (a verdict is identified by its label, check and scenario). A label is '
             'intended when its spell or rank is in the intended set; labels with spell 0 (stack DPS) never are.',
             '', '## Summary', '', '| | count |', '|---|---|',
             f'| unintended, listed | {len(unintended)} |', f'| intended, listed | {len(wanted)} |',
             f'| of which not judged (no interval) | {unjudged} |',
             f'| moved inside the intervals, same status | {len(quiet)} |', f'| added labels | {kinds[ADDED]} |',
             f'| removed labels | {kinds[REMOVED]} |']
    lines += ['', '## Unintended changes', '']
    lines += table(unintended) if unintended else ['None.']
    lines += ['', '## Intended changes', '']
    lines += table(wanted) if wanted else ['None.']
    lines += ['', '## Moved inside the intervals', '']
    lines += table(quiet) if quiet else ['None.']
    return lines + ['']


def write_impact(changes: list[Change], intended: set[int], before_dir: Path, after_dir: Path, out_dir: Path) -> Path:
    before_header, before = read_verdicts(before_dir)
    after_header, after = read_verdicts(after_dir)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / IMPACT_FILE
    path.write_text('\n'.join(impact_lines(changes, intended, before_header, after_header, Path(before_dir),
                                           Path(after_dir), (len(before), len(after)))), encoding='utf-8')
    return path


def diff_directories(before_dir: Path, after_dir: Path, intended: set[int]) -> list[Change]:
    before_header, before = read_verdicts(before_dir)
    after_header, after = read_verdicts(after_dir)
    if before_header['class_id'] != after_header['class_id']:
        raise ValueError(f'class {before_header["class_id"]} before, class {after_header["class_id"]} after')
    return diff(before, after, intended)
