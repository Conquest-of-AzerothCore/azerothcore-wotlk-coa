from dataclasses import dataclass, replace

NAME = 'enemy_shooter'
ORDER = 28
MODES = ('ranged', 'ability')
KEYS = {'mode', 'class', 'weapons', 'skills', 'learn', 'spell', 'power', 'relocate', 'window_ms', 'distance_yd',
        'native_refusals', 'source', 'attack_time_ms'}
OPTIONAL_KEYS = {'power', 'relocate', 'native_refusals', 'attack_time_ms'}
WEAPON_KEYS = {'item', 'slot'}
ATTACK_TIME_KEYS = {'hand', 'value', 'tolerance'}
MAX_HAND = 2
MIN_WINDOW_MS = 3000
MAX_WINDOW_MS = 20000
SKILL_VALUE = 300
MIN_CLASS = 12
MAX_CLASS = 32
APPLIED_READ_MS = 1000


@dataclass(frozen=True)
class EnemyShooter:
    mode: str
    player_class: int
    weapons: tuple[tuple[int, int], ...]
    skills: tuple[int, ...]
    learn: tuple[int, ...]
    spell: int
    power: tuple[int, int] | None
    relocate: tuple[float, float] | None
    window_ms: int
    distance_yd: tuple[float, float]
    native_refusals: tuple[tuple[int, int], ...]
    source: str
    attack_time: tuple[int, float, float] | None = None


def integer(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def pair(raw, check) -> bool:
    return isinstance(raw, list) and len(raw) == 2 and all(check(value) for value in raw)


def number(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def attack_time_valid(raw) -> bool:
    return isinstance(raw, dict) and set(raw) == ATTACK_TIME_KEYS and integer(raw['hand']) \
        and 0 <= raw['hand'] <= MAX_HAND and number(raw['value']) and raw['value'] > 0 \
        and number(raw['tolerance']) and raw['tolerance'] >= 0


def parse(raw) -> EnemyShooter:
    if not isinstance(raw, dict) or not KEYS - OPTIONAL_KEYS <= set(raw) <= KEYS:
        raise ValueError(f'enemy_shooter is {{"mode", "class", "weapons", "skills", "learn", "spell", "window_ms", '
                         f'"distance_yd", "source"[, "power", "relocate", "native_refusals", "attack_time_ms"]}}, '
                         f'not {raw!r}')
    weapons, refusals = raw['weapons'], raw.get('native_refusals', [])
    if raw['mode'] not in MODES or not integer(raw['class']) or not MIN_CLASS <= raw['class'] <= MAX_CLASS \
            or not isinstance(weapons, list) or not weapons \
            or any(not isinstance(weapon, dict) or set(weapon) != WEAPON_KEYS
                   or not all(integer(weapon[key]) for key in WEAPON_KEYS) for weapon in weapons) \
            or not isinstance(raw['skills'], list) or any(not integer(skill) for skill in raw['skills']) \
            or not isinstance(raw['learn'], list) or any(not integer(spell) for spell in raw['learn']) \
            or not integer(raw['spell']) \
            or ('power' in raw and not pair(raw['power'], integer)) \
            or ('relocate' in raw and not pair(raw['relocate'], number)) \
            or not integer(raw['window_ms']) or not MIN_WINDOW_MS <= raw['window_ms'] <= MAX_WINDOW_MS \
            or not pair(raw['distance_yd'], number) or not 0 <= raw['distance_yd'][0] < raw['distance_yd'][1] \
            or not isinstance(refusals, list) or any(not pair(refusal, integer) for refusal in refusals) \
            or ('attack_time_ms' in raw and not attack_time_valid(raw['attack_time_ms'])) \
            or not isinstance(raw['source'], str) or not raw['source']:
        raise ValueError(f'enemy_shooter needs a mode of {MODES}, a CoA class {MIN_CLASS}..{MAX_CLASS}, listed '
                         f'weapons {{"item", "slot"}}, integer skills and learned spells, an integer spell, a window '
                         f'of {MIN_WINDOW_MS}..{MAX_WINDOW_MS} ms, a [least, most] distance, a source, and optional '
                         f'[type, value] power, [dx, dy] relocate, [spell, reason] native_refusals and an '
                         f'attack_time_ms {{"hand": 0..{MAX_HAND}, "value": ms > 0, "tolerance": ms >= 0}}, not {raw!r}')
    return EnemyShooter(raw['mode'], raw['class'], tuple((weapon['item'], weapon['slot']) for weapon in weapons),
                        tuple(raw['skills']), tuple(raw['learn']), raw['spell'],
                        tuple(raw['power']) if 'power' in raw else None,
                        tuple(float(edge) for edge in raw['relocate']) if 'relocate' in raw else None,
                        raw['window_ms'], tuple(float(edge) for edge in raw['distance_yd']),
                        tuple((spell, reason) for spell, reason in refusals), raw['source'],
                        (raw['attack_time_ms']['hand'], float(raw['attack_time_ms']['value']),
                         float(raw['attack_time_ms']['tolerance'])) if 'attack_time_ms' in raw else None)


def distance_label(spec) -> str:
    return f'{spec.spell} enemy_shooter distance'


def attack_time_label(spec) -> str:
    return f'{spec.spell} enemy_shooter attack time'


def applied_label(spec) -> str:
    return f'{spec.spell} enemy_shooter trigger aura on the enemy'


def check(spec, value):
    if value is None:
        return
    if not spec.enemy_player_race or spec.target != 'enemy' or spec.measure_actor != 'enemy':
        raise ValueError(f'{spec.spell} enemy_shooter needs an enemy player (enemy_player_race) that is both the '
                         f'trigger target and the measuring actor')
    if spec.cast_in_before or spec.attack_swings or spec.enemy_casts or spec.helper_casts:
        raise ValueError(f'{spec.spell} enemy_shooter shoots in the uncast before phase: no cast_in_before, '
                         f'attack_swings, enemy_casts or helper_casts')
    if spec.expected_gain is None:
        raise ValueError(f'{spec.spell} enemy_shooter judges the after reading less the before reading: '
                         f'it needs expected_gain')
    if spec.wait_ms + APPLIED_READ_MS < value.window_ms:
        raise ValueError(f'{spec.spell} enemy_shooter window_ms {value.window_ms} is longer than the treatment '
                         f'window {spec.wait_ms + APPLIED_READ_MS} ms, so the control window would be the longer one')


def enemy_cast_steps(value: EnemyShooter) -> list[dict]:
    from profile import CASTER
    from behaviours import ENEMY_PLAYER
    return ([{'action': 'reset_cooldown', 'actor': ENEMY_PLAYER, 'spell': value.spell}] if value.mode == 'ability'
            else []) + ([{'action': 'set_power', 'actor': ENEMY_PLAYER, 'power': value.power[0],
                          'value': value.power[1]}] if value.power else []) \
        + [{'action': 'cast', 'actor': ENEMY_PLAYER, 'spell': value.spell, 'target': CASTER}]


def phase_steps(spec, value: EnemyShooter, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    from behaviours import ENEMY_PLAYER
    if after:
        return []
    steps = [{'action': 'learn', 'actor': ENEMY_PLAYER, 'spell': spell} for spell in (*value.learn, value.spell)]
    for item, slot in value.weapons:
        steps += [{'action': 'add_item', 'actor': ENEMY_PLAYER, 'item': item},
                  {'action': 'equip', 'actor': ENEMY_PLAYER, 'item': item, 'slot': slot}]
    steps += [{'action': 'set_skill', 'actor': ENEMY_PLAYER, 'skill': skill, 'value': SKILL_VALUE,
               'maximum': SKILL_VALUE} for skill in value.skills]
    if value.relocate:
        steps.append({'action': 'relocate', 'actor': ENEMY_PLAYER, 'dx': value.relocate[0], 'dy': value.relocate[1]})
    steps.append(measurement(distance_label(spec), ENEMY_PLAYER, 'distance_2d', target=CASTER))
    if value.attack_time:
        steps.append(measurement(attack_time_label(spec), ENEMY_PLAYER, 'attack_time_ms', hand=value.attack_time[0]))
    steps += enemy_cast_steps(value)
    steps.append({'action': 'wait', 'label': 'enemy control window without the trigger', 'ms': value.window_ms})
    return steps


def after_trigger_steps(spec, value: EnemyShooter, after: bool) -> list[dict]:
    from profile import CASTER, measurement
    from behaviours import ENEMY_PLAYER
    if not after:
        return []
    steps = [{'action': 'wait', 'label': 'let the trigger land on the enemy', 'ms': APPLIED_READ_MS},
             measurement(applied_label(spec), ENEMY_PLAYER, 'aura', spell=spec.trigger_spell, caster=CASTER)]
    return steps + (enemy_cast_steps(value) if value.mode == 'ability' else [])


def fixtures(class_file: dict, spec, value: EnemyShooter, scenario: dict):
    from behaviours import ENEMY_PLAYER
    enemy = next(player for player in scenario['players'] if player['id'] == ENEMY_PLAYER)
    enemy.update({'class': value.player_class, 'melee_hit_rating': 10000, 'ranged_hit_rating': 10000,
                  'expertise_rating': 10000})
    scenario['contract'] += (f' The enemy player (CoA class {value.player_class}, hit and expertise rating 10000) '
                             f'learns {list(value.learn) + [value.spell]}, is equipped with {list(value.weapons)} and '
                             f'skilled in {list(value.skills)}'
                             + (f', moved by {list(value.relocate)} yd' if value.relocate else '')
                             + '; in the uncast before phase it casts '
                             f'{value.spell} at the caster ({value.mode}) and the control window runs '
                             f'{value.window_ms} ms'
                             + ('; after the trigger the same ability is cast again once the trigger has landed'
                                if value.mode == 'ability' else
                                '; an Auto Shot keeps repeating through the treatment phase')
                             + f'. The aura of the trigger on the enemy is read {APPLIED_READ_MS} ms after the '
                             f'trigger, and the enemy\'s distance to the caster before the control window; the '
                             f'after reading less the before reading is what the enemy did while the trigger was '
                             f'on it.'
                             + (f' The enemy\'s attack time of hand {value.attack_time[0]} is read before the control '
                                f'window and must be {value.attack_time[1]} ms within {value.attack_time[2]} ms, '
                                f'else the trial is void.' if value.attack_time else '')
                             + f' {value.source}')


def model(spec, value: EnemyShooter) -> dict:
    from behaviours import metric_delta_label
    shooter = {'mode': value.mode, 'class': value.player_class, 'window_ms': value.window_ms,
               'distance_label': distance_label(spec), 'distance_yd': list(value.distance_yd),
               'applied_label': applied_label(spec), 'before_label': metric_delta_label(spec, 'before'),
               'native_refusals': [list(refusal) for refusal in value.native_refusals]}
    if value.attack_time:
        shooter['attack_time'] = {'label': attack_time_label(spec), 'hand': value.attack_time[0],
                                  'value': value.attack_time[1], 'tolerance': value.attack_time[2]}
    return {NAME: shooter}


def void_reason(run, value: dict) -> str | None:
    before = run.values.get(value['before_label'])
    distance = run.values.get(value['distance_label'])
    applied = run.values.get(value['applied_label'])
    least, most = value['distance_yd']
    native = {tuple(refusal) for refusal in value['native_refusals']}
    from compare import NO_CAST_FAILURE
    refused = sorted({(spell, reason) for spell, reasons in run.cast_failures.items() for reason in reasons
                      if reason != NO_CAST_FAILURE} - native)
    if refused and value['mode'] == 'ranged':
        return f'a cast was refused that the entry does not state as native: {refused}'
    if before is None or before < 1:
        return f'the control without the trigger read {before}, so the enemy never acted and the trial is void'
    if distance is None or not least <= distance <= most:
        return f'the enemy stood {distance} yd from the caster, outside {value["distance_yd"]}'
    attack_time = value.get('attack_time')
    if attack_time:
        read = run.values.get(attack_time['label'])
        if read is None or abs(read - attack_time['value']) > attack_time['tolerance']:
            return (f'the enemy\'s attack time of hand {attack_time["hand"]} read {read} ms, not '
                    f'{attack_time["value"]} within {attack_time["tolerance"]}, so the shooter is not the one the '
                    f'control count assumes')
    if applied is None or applied < 1:
        return f'the trigger aura read {applied} on the enemy, so the trigger never landed'
    return None


def verdict(verdict, run, value: dict):
    reason = void_reason(run, value)
    if reason is None:
        return verdict
    return replace(verdict, status='unmeasured', explanation=f'{verdict.explanation}; the trial is void: {reason}')
