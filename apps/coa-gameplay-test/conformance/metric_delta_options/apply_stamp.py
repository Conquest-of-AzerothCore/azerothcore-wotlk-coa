import math
from dataclasses import replace

NAME = 'apply_stamp'
ORDER = 30
KEYS = {'aura', 'window', 'source'}
STAMPS = ('cast_count', 'cast_upper', 'read_upper', 'count', 'clock', 'first')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS:
        raise ValueError(f'apply_stamp is {{"aura", "window", "source"}}, not {raw!r}')
    aura = raw['aura']
    if isinstance(aura, bool) or not isinstance(aura, int) or aura <= 0:
        raise ValueError(f'apply_stamp aura is a spell id, not {aura!r}')
    window = raw['window']
    if (not isinstance(window, list) or len(window) != 2
            or any(isinstance(bound, bool) or not isinstance(bound, int) for bound in window)
            or not 0 < window[0] <= window[1]):
        raise ValueError(f'apply_stamp window {window!r} needs 0 < low <= high in ms')
    if not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError('apply_stamp source cites the duration and the bound the window excludes')
    return {'aura': aura, 'window': list(window), 'source': raw['source']}


def check(spec, value):
    if value is None:
        return
    if spec.game_time is None:
        raise ValueError(f'{spec.spell} apply_stamp brackets the after reading from the game_time stamps')
    if spec.strike is None or spec.strike.after_trigger_ms is not None:
        raise ValueError(f'{spec.spell} apply_stamp opens its timeline before strikes that land before the trigger')


def labels(spec) -> dict[str, str]:
    return {stamp: f'{spec.spell} apply_stamp {stamp}' for stamp in STAMPS}


def applied(spec, value: dict) -> dict:
    return {'event': 'aura_applied', 'spell': value['aura'], 'target_actors': [spec.measure_actor]}


def phase_steps(spec, value: dict, after: bool) -> list[dict]:
    from behaviours import CASTER, TAKEN_HIT_STRIKER_ENTRY
    if not after:
        return []
    entry = spec.strike.striker_entry
    return [{'action': 'encounter_start', 'actor': CASTER,
             'boss_entry': TAKEN_HIT_STRIKER_ENTRY if entry is None else entry}]


def after_trigger_steps(spec, value: dict, after: bool) -> list[dict]:
    from behaviours import CASTER
    from profile import measurement
    if not after:
        return []
    names = labels(spec)
    return [measurement(names['cast_count'], CASTER, 'timeline_count', **applied(spec, value)),
            measurement(names['cast_upper'], CASTER, 'game_time_ms')]


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, CASTER, metric_delta_label
    from profile import measurement
    names = labels(spec)
    reads = [measurement(names['read_upper'], CASTER, 'game_time_ms'),
             measurement(names['count'], CASTER, 'timeline_count', **applied(spec, value)),
             measurement(names['clock'], CASTER, 'timeline_first_ms', event='cast', spell=spec.trigger_spell,
                         target_actors=[CASTER]),
             measurement(names['first'], CASTER, 'timeline_first_ms', **applied(spec, value))]
    after_label = metric_delta_label(spec, AFTER)
    scenario['steps'] = [step for original in scenario['steps']
                         for step in (original, *(reads if original.get('label') == after_label else ()))]
    low, high = value['window']
    scenario['contract'] += (f' Apply stamp: an encounter timeline opened before the after phase\'s strikes stamps '
                             f'every apply of {value["aura"]} on the {spec.measure_actor} and the trigger cast '
                             f'{spec.trigger_spell} in one time base; the after reading is bracketed from the aura '
                             f'apply, at least the game time from just after the trigger cast (no apply after it) '
                             f'and at most the game time from just before it plus the trigger cast minus the first '
                             f'apply; the bracket must lie in {low}..{high} ms ({value["source"]}).')


def model(spec, value: dict) -> dict:
    from behaviours import game_time_labels
    cast, after, _ = game_time_labels(spec)
    return {NAME: {**value, 'stamps': labels(spec), 'cast_label': cast, 'after_label': after}}


def finite(values: dict, label: str) -> float | None:
    found = values.get(label)
    return float(found) if found is not None and math.isfinite(float(found)) else None


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    stamps = recorded['stamps']
    read = {name: finite(run.values, label) for name, label in
            {**stamps, 'cast_lower': recorded['cast_label'], 'read_lower': recorded['after_label']}.items()}
    missing = [name for name, found in read.items() if found is None]
    if missing:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: {", ".join(missing)} missing')
    if read['count'] < 1:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: no apply of {recorded["aura"]} stamped')
    if read['cast_count'] != read['count']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: {read["count"] - read["cast_count"]:g} '
                                   f'apply after the trigger cast, so the last apply is not bounded')
    offset = read['clock'] - read['first']
    low = read['read_lower'] - read['cast_upper']
    high = read['read_upper'] - read['cast_lower'] + offset
    window_low, window_high = recorded['window']
    text = (f'{verdict.explanation}; apply stamp: first apply {offset:g} ms before the trigger cast, '
            f'{read["count"]:g} applies, the after reading {low:g}..{high:g} ms after the aura apply (window '
            f'{window_low}..{window_high} ms, {recorded["source"]})')
    detail = {**(verdict.detail or {}), 'apply_bracket': [low, high]}
    if not (window_low <= low and high <= window_high):
        return replace(verdict, status='alert', detail=detail,
                       explanation=f'{text}: the bracket leaves its window, so the duration bound is not proven')
    return replace(verdict, detail=detail, explanation=text)
