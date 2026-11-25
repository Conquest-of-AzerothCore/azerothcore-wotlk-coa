from dataclasses import replace

NAME = 'weapon_damage_arms'
ORDER = 45
FORBIDS_EXPECTED = True
KEYS = {'weapons', 'unrelated', 'wait_ms'}
WEAPON_KEYS = {'item', 'source'}
UNRELATED_KEYS = {'metric', 'fields', 'aura', 'stacks', 'source'}
ALLOWED_UNRELATED_METRICS = frozenset({
    'stat', 'stat_exact', 'combat_rating', 'ranged_attack_power',
    'spell_power', 'max_health', 'armor', 'healing_power',
})
MIN_WEAPONS = 3
INPUT_TOLERANCE = 0.5


def positive_int(value, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f'{NAME} {label} is a positive integer, not {value!r}')
    return value


def non_negative_int(value, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f'{NAME} {label} is a non-negative integer, not {value!r}')
    return value


def non_empty_str(value, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f'{NAME} {label} must be a non-empty string')
    return value


def parsed_weapon(raw, index: int) -> dict:
    if not isinstance(raw, dict) or set(raw) != WEAPON_KEYS:
        raise ValueError(f'{NAME} weapons[{index}] is {{"item", "source"}}, not {raw!r}')
    return {'item': positive_int(raw['item'], f'weapons[{index}].item'),
            'source': non_empty_str(raw['source'], f'weapons[{index}].source')}


def parsed_unrelated(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != UNRELATED_KEYS:
        raise ValueError(f'{NAME} unrelated is {{"metric", "fields", "aura", "stacks", "source"}}, not {raw!r}')
    metric = raw['metric']
    if metric not in ALLOWED_UNRELATED_METRICS or not isinstance(raw['fields'], dict):
        raise ValueError(f'{NAME} unrelated metric must be in {sorted(ALLOWED_UNRELATED_METRICS)} with a fields dict')
    return {'metric': metric, 'fields': dict(raw['fields']),
            'aura': positive_int(raw['aura'], 'unrelated.aura'),
            'stacks': positive_int(raw['stacks'], 'unrelated.stacks'),
            'source': non_empty_str(raw['source'], 'unrelated.source')}


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != KEYS:
        raise ValueError(f'{NAME} is {{"weapons", "unrelated", "wait_ms"}}, not {raw!r}')
    if not isinstance(raw['weapons'], list) or len(raw['weapons']) < MIN_WEAPONS:
        raise ValueError(f'{NAME} needs at least {MIN_WEAPONS} distinct main-hand weapons')
    weapons = [parsed_weapon(item, index) for index, item in enumerate(raw['weapons'])]
    items = [weapon['item'] for weapon in weapons]
    if len(set(items)) != len(items):
        raise ValueError(f'{NAME} weapons must have distinct item ids')
    unrelated = parsed_unrelated(raw['unrelated'])
    wait_ms = non_negative_int(raw['wait_ms'], 'wait_ms')
    return {'weapons': weapons, 'unrelated': unrelated, 'wait_ms': wait_ms}


def check(spec, value):
    if value is None:
        return
    if any(found is not None for found in (spec.expected, spec.before_expected, spec.expected_gain,
                                           spec.expected_ratio, spec.after_at_least, spec.after_at_most,
                                           spec.after_expiry_expected, spec.phase_power)):
        raise ValueError(f'{spec.spell} {NAME} judges a strict direction only and forbids any expected figure, '
                         f'gain, ratio, bound or phase power')
    if spec.gate_timing != 'between' or not spec.cast_in_before or spec.setup_only_after or spec.attack_swings \
            or spec.expiry_wait_ms is not None:
        raise ValueError(f'{spec.spell} {NAME} requires plain gate_timing="between" with cast_in_before=True and '
                         f'without setup_only_after, attack_swings or expiry_wait_ms')
    output = (spec.metric, dict(spec.fields))
    if output in (('weapon_damage_min', {}), ('attack_power', {})):
        raise ValueError(f'{spec.spell} {NAME} cannot judge {spec.metric} against itself')
    if output == (value['unrelated']['metric'], value['unrelated']['fields']):
        raise ValueError(f'{spec.spell} {NAME} cannot judge the unrelated stat against itself')


def declared_main_hands(class_file: dict) -> dict[int, dict]:
    from profile import EQUIPMENT_SLOT_MAIN_HAND, MAIN_HAND
    found = {}
    candidates = [class_file.get('weapon'), *class_file.get('alternate_weapons', ()),
                  *(hands.get(MAIN_HAND) for hands in class_file.get('weapon_sets', {}).values())]
    for weapon in candidates:
        if isinstance(weapon, dict) and weapon.get('slot', EQUIPMENT_SLOT_MAIN_HAND) == EQUIPMENT_SLOT_MAIN_HAND \
                and isinstance(weapon.get('item'), int):
            found.setdefault(weapon['item'], weapon)
    return found


def arm_label(spec, kind: str, tag: str) -> str:
    return f'{spec.spell} {NAME} {kind} {tag}'


def read_label(spec, tag: str) -> str:
    from behaviours import metric_delta_label
    return metric_delta_label(spec, f'{NAME} {tag}')


def labels(spec, value: dict) -> dict:
    count = len(value['weapons'])
    return {
        'reads': {
            'control': [read_label(spec, f'control {i}') for i in range(count)],
            'learned': [read_label(spec, f'learned {i}') for i in range(count)],
            'control_unrelated': read_label(spec, 'control unrelated'),
            'learned_unrelated': read_label(spec, 'learned unrelated'),
        },
        'equipped': {
            'control': [arm_label(spec, 'equipped', f'control {i}') for i in range(count)],
            'learned': [arm_label(spec, 'equipped', f'learned {i}') for i in range(count)],
            'control_unrelated': arm_label(spec, 'equipped', 'control unrelated'),
            'learned_unrelated': arm_label(spec, 'equipped', 'learned unrelated'),
        },
        'damage': {
            'control': [arm_label(spec, 'damage', f'control {i}') for i in range(count)],
            'learned': [arm_label(spec, 'damage', f'learned {i}') for i in range(count)],
            'control_unrelated': arm_label(spec, 'damage', 'control unrelated'),
            'learned_unrelated': arm_label(spec, 'damage', 'learned unrelated'),
        },
        'ap': {
            'control': [arm_label(spec, 'ap', f'control {i}') for i in range(count)],
            'learned': [arm_label(spec, 'ap', f'learned {i}') for i in range(count)],
            'control_unrelated': arm_label(spec, 'ap', 'control unrelated'),
            'learned_unrelated': arm_label(spec, 'ap', 'learned unrelated'),
        },
        'unrelated': {
            'control_base': arm_label(spec, 'unrelated', 'control base'),
            'control_active': arm_label(spec, 'unrelated', 'control active'),
            'learned_base': arm_label(spec, 'unrelated', 'learned base'),
            'learned_active': arm_label(spec, 'unrelated', 'learned active'),
        },
    }


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, BEFORE, CASTER, METRIC_DELTA_UNTIMED_WAIT_MS, metric_delta_label
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import EQUIPMENT_SLOT_MAIN_HAND, measurement, skill_target
    declared = declared_main_hands(class_file)
    missing_items = [weapon['item'] for weapon in value['weapons'] if weapon['item'] not in declared]
    if missing_items:
        raise ValueError(f'{spec.spell} {NAME} items {missing_items} are not declared main-hand weapons of '
                         f'{class_file["name"]}')
    names = labels(spec, value)
    steps = scenario['steps']
    before_label, after_label = metric_delta_label(spec, BEFORE), metric_delta_label(spec, AFTER)
    reading = next(step for step in steps if step.get('label') == after_label)
    wait_ms = value['wait_ms']
    existing_items = {step['item'] for step in steps if step.get('action') == 'add_item'}
    existing_skills = {step['skill'] for step in steps if step.get('action') == 'set_skill'}
    grant_steps = []
    target_skill = skill_target(class_file)
    for weapon in value['weapons']:
        item = weapon['item']
        if item not in existing_items:
            grant_steps.append({'action': 'add_item', 'actor': CASTER, 'item': item})
            existing_items.add(item)
        line = declared[item].get('skill_line')
        if line and line not in existing_skills:
            grant_steps.append({'action': 'set_skill', 'actor': CASTER, 'skill': line, 'value': target_skill,
                                'maximum': target_skill})
            existing_skills.add(line)

    def wait_step(label_text: str, ms: int) -> list[dict]:
        return [{'action': 'wait', 'label': label_text, 'ms': ms}] if ms > 0 else []

    def equip_step(item: int) -> dict:
        return {'action': 'equip', 'actor': CASTER, 'item': item, 'slot': EQUIPMENT_SLOT_MAIN_HAND}

    def set_aura(spell: int, stacks: int) -> dict:
        return {'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}

    def phase_block(phase: str) -> list[dict]:
        out = list(grant_steps) if phase == 'control' else []
        for idx, weapon in enumerate(value['weapons']):
            out += [equip_step(weapon['item']), *wait_step(f'{NAME} settle', wait_ms),
                    measurement(names['equipped'][phase][idx], CASTER, 'equipped_item', slot=EQUIPMENT_SLOT_MAIN_HAND),
                    measurement(names['damage'][phase][idx], CASTER, 'weapon_damage_min'),
                    measurement(names['ap'][phase][idx], CASTER, 'attack_power'),
                    {**reading, 'label': names['reads'][phase][idx]}]
        unrel = value['unrelated']
        out += [equip_step(value['weapons'][0]['item']), *wait_step(f'{NAME} unrelated base settle', wait_ms),
                measurement(names['unrelated'][f'{phase}_base'], CASTER, unrel['metric'], **unrel['fields']),
                set_aura(unrel['aura'], unrel['stacks']), *wait_step(f'{NAME} unrelated settle', wait_ms),
                measurement(names['unrelated'][f'{phase}_active'], CASTER, unrel['metric'], **unrel['fields']),
                measurement(names['equipped'][f'{phase}_unrelated'], CASTER, 'equipped_item',
                            slot=EQUIPMENT_SLOT_MAIN_HAND),
                measurement(names['damage'][f'{phase}_unrelated'], CASTER, 'weapon_damage_min'),
                measurement(names['ap'][f'{phase}_unrelated'], CASTER, 'attack_power'),
                {**reading, 'label': names['reads'][f'{phase}_unrelated']},
                set_aura(unrel['aura'], 0), *wait_step(f'{NAME} unrelated clear', wait_ms)]
        return out

    added = {before_label: phase_block('control'), after_label: phase_block('learned')}
    scenario['steps'] = [step for original in steps for step in (original, *added.get(original.get('label'), ()))]
    waited = sum(step['ms'] for step in scenario['steps'] if step['action'] == 'wait')
    if waited > METRIC_DELTA_UNTIMED_WAIT_MS:
        scenario.pop('timeout_ms', None)
        timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)
    weapon_desc = ', '.join(f'{weapon["item"]} ({weapon["source"]})' for weapon in value['weapons'])
    unrel = value['unrelated']
    scenario['contract'] += (
        f' Weapon damage arms (D-38): equips {len(value["weapons"])} main-hand weapons [{weapon_desc}] before and '
        f'after learning {spec.spell}, reading equipped_item (slot 15), weapon_damage_min, attack_power and '
        f'{spec.metric} in each arm, plus an unrelated-stat control on {unrel["metric"]} {unrel["fields"]} via '
        f'{unrel["aura"]} x{unrel["stacks"]} ({unrel["source"]}) at weapon {value["weapons"][0]["item"]}. '
        f'Preconditions (void as unmeasured on failure): each weapon equips cleanly, weapon_damage_min strictly rises '
        f'across arms and matches between control and learned, attack_power is equal across every read, and the '
        f'unrelated stat rises without moving weapon_damage_min or attack_power. Judged strictly monotonic across all '
        f'{len(value["weapons"])} weapon arms and unchanged under the unrelated stat, with no slope, ratio or expected '
        f'figure.')


def model(spec, value: dict) -> dict:
    from behaviours import AFTER, BEFORE, metric_delta_label
    from compare import METRIC_DELTA_FLOAT_TOLERANCE
    tolerance = METRIC_DELTA_FLOAT_TOLERANCE if spec.tolerance is None else spec.tolerance
    return {NAME: {**value, **labels(spec, value), 'metric': spec.metric, 'tolerance': tolerance,
                   'before_label': metric_delta_label(spec, BEFORE), 'after_label': metric_delta_label(spec, AFTER)}}


def read_values(run, label_list: list[str]) -> tuple[list[float], str | None]:
    from compare import missing_measurement
    out = []
    for label in label_list:
        val = run.values.get(label)
        if val is None:
            return [], missing_measurement(run, label)
        out.append(float(val))
    return out, None


def strictly_rising(values: list[float], tol: float) -> bool:
    return all(high > low + tol for low, high in zip(values, values[1:]))


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    tolerance = float(recorded['tolerance'])
    items = [int(weapon['item']) for weapon in recorded['weapons']]
    expected_items = [*items, items[0]]
    ctrl_out, missing = read_values(run, [*recorded['reads']['control'], recorded['reads']['control_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    lrn_out, missing = read_values(run, [*recorded['reads']['learned'], recorded['reads']['learned_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    ctrl_eq, missing = read_values(run, [*recorded['equipped']['control'], recorded['equipped']['control_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    lrn_eq, missing = read_values(run, [*recorded['equipped']['learned'], recorded['equipped']['learned_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    ctrl_dmg, missing = read_values(run, [*recorded['damage']['control'], recorded['damage']['control_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    lrn_dmg, missing = read_values(run, [*recorded['damage']['learned'], recorded['damage']['learned_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    ctrl_ap, missing = read_values(run, [*recorded['ap']['control'], recorded['ap']['control_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    lrn_ap, missing = read_values(run, [*recorded['ap']['learned'], recorded['ap']['learned_unrelated']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    unrel_vals, missing = read_values(run, [recorded['unrelated']['control_base'],
                                            recorded['unrelated']['control_active'],
                                            recorded['unrelated']['learned_base'],
                                            recorded['unrelated']['learned_active']])
    if missing:
        return replace(verdict, status='unmeasured', explanation=missing)
    if [int(val) for val in ctrl_eq] != expected_items or [int(val) for val in lrn_eq] != expected_items:
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: main-hand equipped items did not match expected {expected_items} '
                                   f'(control={[int(val) for val in ctrl_eq]}, learned={[int(val) for val in lrn_eq]})')
    ctrl_levels, ctrl_dmg_unrel = ctrl_dmg[:-1], ctrl_dmg[-1]
    lrn_levels, lrn_dmg_unrel = lrn_dmg[:-1], lrn_dmg[-1]
    if not strictly_rising(ctrl_levels, INPUT_TOLERANCE) or \
            any(abs(a - b) > INPUT_TOLERANCE for a, b in zip(ctrl_levels, lrn_levels)):
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: weapon_damage_min levels did not rise strictly and match across arms '
                                   f'(control={ctrl_levels}, learned={lrn_levels})')
    all_ap = [*ctrl_ap, *lrn_ap]
    if max(all_ap) - min(all_ap) > INPUT_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: attack_power was not equal across all arms '
                                   f'(control={ctrl_ap}, learned={lrn_ap})')
    c_ub, c_ua, l_ub, l_ua = unrel_vals
    if c_ua - c_ub <= INPUT_TOLERANCE or l_ua - l_ub <= INPUT_TOLERANCE or \
            abs((l_ua - l_ub) - (c_ua - c_ub)) > INPUT_TOLERANCE or \
            abs(ctrl_dmg_unrel - ctrl_levels[0]) > INPUT_TOLERANCE or \
            abs(lrn_dmg_unrel - lrn_levels[0]) > INPUT_TOLERANCE:
        return replace(verdict, status='unmeasured',
                       explanation=f'{NAME}: unrelated stat control fixture invalid (unrelated '
                                   f'control {c_ub:g}->{c_ua:g}, learned {l_ub:g}->{l_ua:g}; weapon_damage_min during '
                                   f'unrelated control={ctrl_dmg_unrel:g} vs {ctrl_levels[0]:g}, '
                                   f'learned={lrn_dmg_unrel:g} vs {lrn_levels[0]:g})')
    gains = [lrn - ctrl for lrn, ctrl in zip(lrn_out[:-1], ctrl_out[:-1])]
    unrel_gain = lrn_out[-1] - ctrl_out[-1]
    rising = gains[0] >= -tolerance and strictly_rising(gains, tolerance)
    stable = abs(unrel_gain - gains[0]) <= tolerance
    ok = rising and stable
    detail = {**(verdict.detail or {}), 'weapons': items, 'weapon_damage_min': ctrl_levels,
              'attack_power': all_ap[0], 'arm_gains': gains, 'unrelated_gain': unrel_gain,
              'unrelated_stat': [c_ub, c_ua, l_ub, l_ua]}
    return replace(verdict, status='ok' if ok else 'alert', measured=gains[-1], expected=None, low=None, high=None,
                   detail=detail,
                   explanation=f'{NAME} ({recorded["metric"]}): weapons {items} weapon_damage_min {ctrl_levels} at '
                               f'equal attack_power {all_ap[0]:g} -> learned gains {gains} (strictly rising: '
                               f'{rising}); unrelated stat {c_ub:g}->{c_ua:g} -> learned gain {unrel_gain:g} vs '
                               f'weapon 0 {gains[0]:g} (unchanged within {tolerance:g}: {stable}); direction only, '
                               f'no figure asserted')
