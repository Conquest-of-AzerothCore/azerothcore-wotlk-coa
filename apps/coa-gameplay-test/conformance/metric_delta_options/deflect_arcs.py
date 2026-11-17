from dataclasses import dataclass, replace
import math

NAME = 'deflect_arcs'
ORDER = 22
METRIC = 'spell_damage_count'
METRIC_EVIDENCE = {'avoidance_samples': 'readback'}
ARMS = ('front', 'outside', 'behind')
POSITION_READS = (('caster', 'position_o'), ('caster', 'position_x'), ('caster', 'position_y'),
                  ('striker', 'position_x'), ('striker', 'position_y'))
MAX_SHIFT_YD = 30.0
MAX_SETTLE_MS = 5000
OPTIONAL = {'present_entry', 'owner_question'}


@dataclass(frozen=True)
class DeflectArcs:
    aura: int
    outside: tuple[float, float]
    behind: tuple[float, float]
    settle_ms: int
    present_entry: int | None = None
    owner_question: str | None = None


def shift(raw, name: str) -> tuple[float, float]:
    if not isinstance(raw, list) or len(raw) != 2 or not all(
            not isinstance(value, bool) and isinstance(value, (int, float)) and abs(value) <= MAX_SHIFT_YD
            for value in raw) or not any(raw):
        raise ValueError(f'deflect_arcs {name} is a [dx, dy] move of the caster in yd, not both 0, each at most '
                         f'{MAX_SHIFT_YD:g}, not {raw!r}')
    return float(raw[0]), float(raw[1])


def parse(raw) -> DeflectArcs:
    required = {'aura', 'outside', 'behind', 'settle_ms'}
    if not isinstance(raw, dict) or not required <= set(raw) or set(raw) - required - OPTIONAL \
            or type(raw['aura']) is not int or raw['aura'] < 1 or type(raw['settle_ms']) is not int \
            or not 0 < raw['settle_ms'] <= MAX_SETTLE_MS:
        raise ValueError(f'deflect_arcs is {{aura, outside, behind, settle_ms}} with a positive aura id and a settle '
                         f'of 1 to {MAX_SETTLE_MS} ms, and optionally {sorted(OPTIONAL)}, not {raw!r}')
    present, question = raw.get('present_entry'), raw.get('owner_question')
    if present is not None and (type(present) is not int or present < 1):
        raise ValueError(f'deflect_arcs present_entry is a positive creature entry, not {present!r}')
    if question is not None and (not isinstance(question, str) or not question.strip()):
        raise ValueError(f'deflect_arcs owner_question is a non-empty text, not {question!r}')
    return DeflectArcs(raw['aura'], shift(raw['outside'], 'outside'), shift(raw['behind'], 'behind'),
                       raw['settle_ms'], present, question)


def check(spec, arcs):
    if arcs is None:
        return
    from behaviours import STRIKER
    from profile import CASTER
    if spec.strike is None or spec.strike.after_trigger_ms is None or spec.strike.in_before \
            or spec.strike.owned_entry is not None or spec.strike.dx or spec.metric != METRIC \
            or spec.fields != {'spell': spec.strike.spell, 'caster': STRIKER, 'target': CASTER} \
            or spec.measure_actor != CASTER or spec.gate_timing != 'start' or not spec.trigger_only_after \
            or spec.expected_gain != 0:
        raise ValueError(f'{spec.spell} deflect_arcs reads the striker\'s landed {METRIC} at the caster around a '
                         f'trigger cast only after the gate (gate_timing start, trigger_only_after), with a strike '
                         f'after the trigger, no strike dx and an expected gain of 0')


def label(spec, arm: str, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} deflect {arm} {read}'


def arm_reads(spec, arcs: DeflectArcs, arm: str) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(label(spec, arm, 'aura'), CASTER, 'aura', spell=arcs.aura),
            *(measurement(label(spec, arm, f'{unit} {metric}'), unit, metric) for unit, metric in POSITION_READS)]


def present_label(spec) -> str:
    return label(spec, 'outside', 'present')


def contract_text(spec, arcs: DeflectArcs) -> str:
    text = (f' Deflect arms around the real cast of {spec.trigger_spell}: control, before any cast, the striker in '
            f'front, {spec.strike.count} strikes; front, {spec.strike.after_trigger_ms} ms after the cast, aura '
            f'{arcs.aura} read on the caster, {spec.strike.count} strikes; outside, the caster moved '
            f'{arcs.outside[0]:g}, {arcs.outside[1]:g} yd, aura {arcs.aura} read 0')
    if arcs.present_entry is not None:
        text += f', creature {arcs.present_entry} counted on the caster, which must read 1 (still present)'
    text += (f', {spec.strike.count} strikes; behind, the caster moved {arcs.behind[0]:g}, {arcs.behind[1]:g} yd more '
             f'and cast {spec.trigger_spell} again, aura {arcs.aura} read, {spec.strike.count} strikes. Judged: the '
             f'control and the outside arm land every strike, the front arm lands at most {spec.tolerance or 0:g} above '
             f'the control')
    if arcs.owner_question is not None:
        return text + f'. The behind arm is recorded, not judged, pending owner question {arcs.owner_question}.'
    return text + f', the behind arm lands at most {spec.tolerance or 0:g} of {spec.strike.count}.'


def fixtures(class_file: dict, spec, arcs: DeflectArcs, scenario: dict):
    scenario['contract'] += contract_text(spec, arcs)


def landed_read(spec, arm: str) -> dict:
    from profile import measurement
    return measurement(label(spec, arm, 'landed'), spec.measure_actor, spec.metric, **spec.fields)


def after_trigger_steps(spec, arcs: DeflectArcs, after: bool) -> list[dict]:
    if not after:
        return []
    from behaviours import strike_cast_steps
    from profile import CASTER, measurement
    steps = arm_reads(spec, arcs, 'front') + [landed_read(spec, 'front')]
    for arm, (dx, dy) in (('outside', arcs.outside), ('behind', arcs.behind)):
        steps.append({'action': 'relocate', 'actor': CASTER, 'dx': dx, 'dy': dy})
        if arm == 'behind':
            steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                      {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.target}]
        steps.append({'action': 'wait', 'label': f'deflect {arm} settle', 'ms': arcs.settle_ms})
        steps += arm_reads(spec, arcs, arm)
        if arm == 'outside' and arcs.present_entry is not None:
            steps.append(measurement(present_label(spec), CASTER, 'owned_creature_count', entry=arcs.present_entry))
        steps += strike_cast_steps(spec.strike) + [landed_read(spec, arm)]
    return steps


def model(spec, arcs: DeflectArcs) -> dict:
    from behaviours import metric_delta_label
    return {NAME: {'after_label': metric_delta_label(spec, 'after'), 'before_label': metric_delta_label(spec, 'before'),
                   'strikes': spec.strike.count, 'tolerance': spec.tolerance or 0,
                   'behind_judged': arcs.owner_question is None,
                   'labels': {arm: label(spec, arm, 'landed') for arm in ARMS},
                   'auras': {arm: label(spec, arm, 'aura') for arm in ARMS},
                   'positions': {arm: {f'{unit} {metric}': label(spec, arm, f'{unit} {metric}')
                                       for unit, metric in POSITION_READS} for arm in ARMS},
                   **({'present': present_label(spec)} if arcs.present_entry is not None else {})}}


def run_values(values: dict, arcs: dict) -> dict:
    front = values.get(arcs['labels']['front'])
    return {**values, arcs['after_label']: front} if front is not None else values


def striker_in_front(positions: dict) -> bool:
    facing = positions['caster position_o']
    dx = positions['striker position_x'] - positions['caster position_x']
    dy = positions['striker position_y'] - positions['caster position_y']
    return dx * math.cos(facing) + dy * math.sin(facing) > 0


def verdict(verdict, run, arcs: dict):
    values = run.values
    needed = [arcs['before_label'], *arcs['labels'].values(), *arcs['auras'].values(),
              *(read for reads in arcs['positions'].values() for read in reads.values())]
    if any(values.get(read) is None for read in needed):
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; a deflect arm read is missing')
    before, strikes = values[arcs['before_label']], arcs['strikes']
    counts = [values[arcs['labels'][arm]] for arm in ARMS]
    landed = dict(zip(ARMS, (counts[0] - before, counts[1] - counts[0], counts[2] - counts[1])))
    auras = {arm: values[arcs['auras'][arm]] for arm in ARMS}
    front = {arm: striker_in_front({key: values[read] for key, read in arcs['positions'][arm].items()})
             for arm in ARMS}
    judged = arcs['behind_judged']
    text = (f'{verdict.explanation}; control (no aura, striker in front) landed {before:g} of {strikes}, front with '
            f'the aura {landed["front"]:g}, in front outside its radius {landed["outside"]:g} of {strikes}; '
            f'{"" if judged else "recorded, not judged: "}from behind with the aura {landed["behind"]:g} of {strikes} '
            f'(aura {auras["behind"]:g}, striker in front: {front["behind"]})')
    present = values.get(arcs['present']) if 'present' in arcs else 1
    if 'present' in arcs:
        text += f'; creature counted in the outside arm: {"missing" if present is None else format(present, "g")}'
    if auras['front'] < 1 or auras['outside'] != 0 or not front['front'] or not front['outside']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}; a precondition failed: aura front {auras["front"]:g} (needs 1), outside '
                                   f'{auras["outside"]:g} (needs 0), striker in front {front["front"]} and '
                                   f'{front["outside"]} (needs both)')
    if judged and (auras['behind'] < 1 or front['behind']):
        return replace(verdict, status='unmeasured',
                       explanation=f'{text}; a precondition failed: aura behind {auras["behind"]:g} (needs 1), striker '
                                   f'in front {front["behind"]} (needs False)')
    if before != strikes or landed['outside'] != strikes:
        return replace(verdict, status='alert',
                       explanation=f'{text}; the control and the outside arm must land every strike')
    if present != 1:
        return replace(verdict, status='alert',
                       explanation=f'{text}; the outside arm must count the creature once (needs 1)')
    if judged and landed['behind'] > arcs['tolerance']:
        return replace(verdict, status='alert',
                       explanation=f'{text}; the behind arm must land at most {arcs["tolerance"]:g} of {strikes}')
    return replace(verdict, explanation=text)
