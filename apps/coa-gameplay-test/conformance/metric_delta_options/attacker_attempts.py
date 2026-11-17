from dataclasses import dataclass, replace
import math

NAME = 'attacker_attempts'
ORDER = 8
ATTACKERS = 8
ATTEMPTS = ('a', 'b')
ARMS = ('control', 'aura', 'control2')
CONTROL_SHARE = 4
BAND_POINTS = 5.0
CASTER_HEALTH = 1_000_000
MAX_WAIT_MS = 10000
MAX_SCENARIO_STEPS = 10000
LANDED_READS = ('logs', 'aura', 'periodic')
DAMAGE_BAND = 0.05
DAMAGE_SHIELD_OPCODE = 591
SHIELD_DAMAGE_WORD = 5


@dataclass(frozen=True)
class AttackerAttempts:
    spell: int
    trials: int
    wait_ms: int
    attacker_auras: tuple[int, ...] = ()
    running: tuple[int, int] | tuple[int, int, int] | None = None
    landed: str = 'logs'
    shield: tuple[int, int, tuple[int, ...]] | None = None
    landed_tick: int | None = None


def parse_shield(raw) -> tuple[int, int, tuple[int, ...]] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or not {'spell', 'wait_ms'} <= set(raw) <= {'spell', 'wait_ms', 'caster_auras'}:
        raise ValueError(f'attacker_attempts shield takes spell, wait_ms and optionally caster_auras, not {raw!r}')
    values = (raw['spell'], raw['wait_ms'])
    if any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in values):
        raise ValueError(f'attacker_attempts shield spell and wait_ms are positive whole numbers, not {raw!r}')
    if raw['wait_ms'] > MAX_WAIT_MS:
        raise ValueError(f'attacker_attempts shield waits {raw["wait_ms"]} ms, above {MAX_WAIT_MS} ms')
    auras = raw.get('caster_auras', [])
    if not isinstance(auras, list) or len(set(auras)) != len(auras) or any(
            isinstance(aura, bool) or not isinstance(aura, int) or aura <= 0 for aura in auras):
        raise ValueError(f'attacker_attempts shield caster_auras is a list of distinct positive spell ids, not '
                         f'{auras!r}')
    return (*values, tuple(auras))


def parse_running(raw) -> tuple[int, int] | tuple[int, int, int] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or not {'spell', 'wait_ms'} <= set(raw) <= {'spell', 'wait_ms', 'tick'}:
        raise ValueError(f'attacker_attempts running takes spell, wait_ms and optionally tick, not {raw!r}')
    values = (raw['spell'], raw['wait_ms'], *([raw['tick']] if 'tick' in raw else []))
    if any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in values):
        raise ValueError(f'attacker_attempts running spell and wait_ms are positive whole numbers, not {raw!r}')
    if raw['wait_ms'] > MAX_WAIT_MS:
        raise ValueError(f'attacker_attempts running waits {raw["wait_ms"]} ms, above {MAX_WAIT_MS} ms')
    return values


def parse(raw) -> AttackerAttempts:
    if not isinstance(raw, dict) or not {'spell', 'trials', 'wait_ms'} <= set(raw) <= {
            'spell', 'trials', 'wait_ms', 'attacker_auras', 'running', 'landed', 'shield', 'landed_tick'}:
        raise ValueError(f'attacker_attempts takes spell, trials, wait_ms and optionally attacker_auras, running, '
                         f'landed, shield and landed_tick, not {raw!r}')
    if 'running' in raw and 'shield' in raw:
        raise ValueError(f'attacker_attempts reads either a running effect or a damage shield, not both: {raw!r}')
    landed = raw.get('landed', 'logs')
    if landed not in LANDED_READS:
        raise ValueError(f'attacker_attempts landed is one of {list(LANDED_READS)}, not {landed!r}')
    landed_tick = raw.get('landed_tick')
    if landed_tick is not None and (isinstance(landed_tick, bool) or not isinstance(landed_tick, int) or
                                    landed_tick <= 0 or landed != 'logs'):
        raise ValueError(f'attacker_attempts landed_tick is a positive spell id read with the default landed logs, '
                         f'not {raw!r}')
    auras = raw.get('attacker_auras', [])
    if not isinstance(auras, list) or len(set(auras)) != len(auras) or any(
            isinstance(aura, bool) or not isinstance(aura, int) or aura <= 0 for aura in auras):
        raise ValueError(f'attacker_attempts attacker_auras is a list of distinct positive spell ids, not {auras!r}')
    values = [raw['spell'], raw['trials'], raw['wait_ms']]
    if any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in values):
        raise ValueError(f'attacker_attempts spell, trials and wait_ms are positive whole numbers, not {values}')
    if raw['wait_ms'] > MAX_WAIT_MS:
        raise ValueError(f'attacker_attempts waits {raw["wait_ms"]} ms per attempt, above {MAX_WAIT_MS} ms')
    return AttackerAttempts(*values, tuple(auras), parse_running(raw.get('running')), landed,
                            parse_shield(raw.get('shield')), landed_tick)


def attacker_ids() -> list[str]:
    return [f'attacker{index + 1}' for index in range(ATTACKERS)]


def arm_rounds(attempts: AttackerAttempts) -> dict[str, int]:
    control = math.ceil(attempts.trials / CONTROL_SHARE)
    return {'control': control, 'aura': attempts.trials, 'control2': control}


def prefix(aura: int, attempts: AttackerAttempts) -> str:
    return f'{aura} attacker_attempts {attempts.spell}'


def read_label(head: str, arm: str, moment: str, read: str, attacker: str) -> str:
    return f'{head} {arm} {moment} {read} {attacker}'


def check(spec, attempts):
    if attempts is None:
        return
    from behaviours import CASTER
    if spec.metric != 'spell_log_count' or spec.target != CASTER:
        raise ValueError(f'{spec.spell} attacker_attempts reads spell_log_count at the caster, not {spec.metric} at '
                         f'{spec.target}')
    if spec.strike is not None or spec.setup_casts or spec.forced_chance is not None or spec.attack_swings:
        raise ValueError(f'{spec.spell} attacker_attempts replaces the phases: no strike, setup casts, forced '
                         f'chance or attack swings')


def fixture_label(head: str, aura: int, attacker: str) -> str:
    return f'{head} fixture {aura} {attacker}'


def caster_auras(attempts: AttackerAttempts) -> tuple[int, ...]:
    return attempts.shield[2] if attempts.shield else ()


def fixture_steps(head: str, attempts: AttackerAttempts) -> list[dict]:
    from profile import CASTER, measurement
    steps = [{'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker, 'spell': aura,
              'stacks': 1} for attacker in attacker_ids() for aura in attempts.attacker_auras]
    steps += [{'action': 'set_aura', 'actor': CASTER, 'target': CASTER, 'caster': CASTER, 'spell': aura,
               'stacks': 1} for aura in caster_auras(attempts)]
    return steps + [measurement(fixture_label(head, aura, attacker), attacker, 'aura', caster=attacker, spell=aura)
                    for attacker in attacker_ids() for aura in attempts.attacker_auras] + [
        measurement(fixture_label(head, aura, CASTER), CASTER, 'aura', caster=CASTER, spell=aura)
        for aura in caster_auras(attempts)]


def landed_read(head: str, arm: str, moment: str, attempts: AttackerAttempts, attacker: str) -> dict:
    from profile import CASTER, measurement
    if attempts.landed == 'aura':
        return measurement(read_label(head, arm, moment, 'landed', attacker), CASTER, 'aura', caster=attacker,
                           spell=attempts.spell)
    if attempts.landed == 'periodic':
        return measurement(read_label(head, arm, moment, 'ticks', attacker), CASTER, 'spell_damage_count',
                           spell=attempts.spell, caster=attacker, periodic=True)
    return measurement(read_label(head, arm, moment, 'logs', attacker), CASTER, 'spell_log_count',
                       spell=attempts.landed_tick or attempts.spell, caster=attacker, target=CASTER)


def landed_name(attempts: AttackerAttempts) -> str:
    return {'aura': 'landed', 'periodic': 'ticks'}.get(attempts.landed, 'logs')


def remove_from_caster(spell: int, attacker: str) -> dict:
    from profile import CASTER
    return {'action': 'set_aura', 'actor': CASTER, 'target': CASTER, 'caster': attacker, 'spell': spell,
            'stacks': 0}


def reads(head: str, arm: str, moment: str, attempts: AttackerAttempts, aura: int, attacker: str) -> list[dict]:
    from profile import CASTER, measurement
    return [landed_read(head, arm, moment, attempts, attacker),
            measurement(read_label(head, arm, moment, 'go', attacker), CASTER, 'spell_go_count',
                        spell=attempts.spell, caster=attacker),
            measurement(read_label(head, arm, moment, 'aura', attacker), attacker, 'aura', caster=attacker,
                        spell=aura)]


def running_label(head: str, arm: str, index: int, read: str, unit: str) -> str:
    return f'{head} {arm} r{index} running {read} {unit}'


def running_steps(head: str, arm: str, index: int, attempts: AttackerAttempts, aura: int) -> list[dict]:
    from profile import CASTER, measurement
    spell, wait_ms = attempts.running[:2]
    steps = []
    for attacker in attacker_ids():
        steps.append({'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker,
                      'spell': aura, 'stacks': 0})
        steps.append({'action': 'cast', 'actor': attacker, 'spell': spell, 'target': CASTER})
    for attacker in attacker_ids():
        steps.append(measurement(running_label(head, arm, index, 'dot', attacker), CASTER, 'aura', caster=attacker,
                                 spell=spell))
        if arm == 'aura':
            steps.append({'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker,
                          'spell': aura, 'stacks': 1})
        steps.append(measurement(read_label(head, arm, f'r{index}', 'pre', attacker), attacker, 'aura',
                                 caster=attacker, spell=aura))
    steps.append(measurement(running_label(head, arm, index, 'health_before', CASTER), CASTER, 'health'))
    steps.append({'action': 'wait', 'label': f'{head} {arm} r{index} running', 'ms': wait_ms})
    steps.append(measurement(running_label(head, arm, index, 'health_after', CASTER), CASTER, 'health'))
    for attacker in attacker_ids():
        steps += tick_reads(head, arm, index, attempts.running, attacker)
        steps += [measurement(running_label(head, arm, index, 'held', attacker), attacker, 'aura', caster=attacker,
                              spell=aura),
                  remove_from_caster(spell, attacker)]
    return steps


def shield_label(head: str, arm: str, index: int, read: str) -> str:
    return f'{head} {arm} r{index} shield {read}'


def struck_attacker(index: int) -> str:
    return attacker_ids()[(index - 1) % ATTACKERS]


def shield_packets(label: str) -> dict:
    from profile import CASTER, measurement
    return measurement(label, CASTER, 'server_packets', opcode=DAMAGE_SHIELD_OPCODE)


def shield_steps(head: str, arm: str, index: int, attempts: AttackerAttempts, aura: int) -> list[dict]:
    from profile import CASTER, measurement
    spell, wait_ms, _ = attempts.shield
    struck = struck_attacker(index)
    return [{'action': 'set_aura', 'actor': CASTER, 'target': struck, 'caster': struck, 'spell': spell, 'stacks': 1},
            measurement(shield_label(head, arm, index, 'on'), struck, 'aura', caster=struck, spell=spell),
            shield_packets(shield_label(head, arm, index, 'packets_before')),
            measurement(shield_label(head, arm, index, 'health_before'), CASTER, 'health'),
            {'action': 'attack', 'actor': CASTER, 'target': struck},
            {'action': 'wait', 'label': f'{head} {arm} r{index} shield', 'ms': wait_ms},
            {'action': 'stop_attack', 'actor': CASTER},
            shield_packets(shield_label(head, arm, index, 'packets_after')),
            measurement(shield_label(head, arm, index, 'damage'), CASTER, 'server_packet_u32',
                        opcode=DAMAGE_SHIELD_OPCODE, index=SHIELD_DAMAGE_WORD),
            measurement(shield_label(head, arm, index, 'health_after'), CASTER, 'health'),
            measurement(shield_label(head, arm, index, 'held'), struck, 'aura', caster=struck, spell=aura),
            {'action': 'set_aura', 'actor': CASTER, 'target': struck, 'caster': struck, 'spell': spell, 'stacks': 0}]


def tick_reads(head: str, arm: str, index: int, running: tuple, attacker: str) -> list[dict]:
    from profile import CASTER, measurement
    source = {'spell': running[2]} if len(running) > 2 else {'spell': running[0], 'periodic': True}
    return [measurement(running_label(head, arm, index, read, attacker), CASTER, metric, caster=attacker, **source)
            for read, metric in (('ticks', 'spell_damage_count'), ('damage', 'spell_damage_total'))]


def arm_steps(head: str, arm: str, rounds: int, attempts: AttackerAttempts, aura: int) -> list[dict]:
    from profile import CASTER, measurement
    steps = [step for attacker in attacker_ids() for step in reads(head, arm, 'r0', attempts, aura, attacker)]
    if attempts.running:
        steps += [step for attacker in attacker_ids()
                  for step in tick_reads(head, arm, 0, attempts.running, attacker)]
    for index in range(1, rounds + 1):
        steps.append({'action': 'set_health', 'actor': CASTER, 'value': CASTER_HEALTH, 'maximum': CASTER_HEALTH})
        if attempts.running:
            steps += running_steps(head, arm, index, attempts, aura)
        for attacker in attacker_ids() if not attempts.running else ():
            steps.append({'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker,
                          'spell': aura, 'stacks': 0})
            if arm == 'aura':
                steps.append({'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker,
                              'spell': aura, 'stacks': 1})
            steps.append(measurement(read_label(head, arm, f'r{index}', 'pre', attacker), attacker, 'aura',
                                     caster=attacker, spell=aura))
        if attempts.shield:
            steps += shield_steps(head, arm, index, attempts, aura)
        for attempt in ATTEMPTS:
            steps += [{'action': 'cast', 'actor': attacker, 'spell': attempts.spell, 'target': CASTER}
                      for attacker in attacker_ids()]
            steps.append({'action': 'wait', 'label': f'{head} {arm} r{index}{attempt}', 'ms': attempts.wait_ms})
            steps += [step for attacker in attacker_ids()
                      for step in reads(head, arm, f'r{index}{attempt}', attempts, aura, attacker)]
            if attempts.landed == 'aura' or attempts.landed_tick:
                steps += [remove_from_caster(attempts.spell, attacker) for attacker in attacker_ids()]
            if attempts.landed_tick:
                steps += [{'action': 'set_aura', 'actor': CASTER, 'target': attacker, 'caster': attacker,
                           'spell': attempts.spell, 'stacks': 0} for attacker in attacker_ids()]
    return steps


def fixtures(class_file: dict, spec, attempts: AttackerAttempts, scenario: dict):
    from behaviours import STRIKER_DISTANCE
    from values import DUMMY_ENTRY
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import CASTER, base_steps
    head = prefix(spec.spell, attempts)
    steps = base_steps(class_file) + [{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0}]
    steps += fixture_steps(head, attempts)
    for arm, rounds in arm_rounds(attempts).items():
        steps += arm_steps(head, arm, rounds, attempts, spec.spell)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} attacker_attempts builds {len(steps)} steps for {attempts.trials} trials, '
                         f'above the {MAX_SCENARIO_STEPS} steps of one scenario')
    scenario['steps'] = steps
    scenario['creatures'] = [{'id': attacker, 'owner': CASTER, 'entry': DUMMY_ENTRY, 'level': class_file['level'],
                              'health': CASTER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 0,
                              'stationary': True} for attacker in attacker_ids()]
    rounds = arm_rounds(attempts)
    fixture = (f' Each attacker carries {list(attempts.attacker_auras)} from before the first arm, never removed '
               f'(precondition fixture, read back per attacker and id).' if attempts.attacker_auras else '')
    if caster_auras(attempts):
        fixture += (f' The caster carries {list(caster_auras(attempts))} from before the first arm (precondition '
                    f'fixture, read back).')
    running = ''
    if attempts.running:
        running = (f' Running effect: at the start of every trial of every arm each attacker casts {attempts.running[0]} '
                   f'at the caster without {spec.spell} (read back on the caster as dot), then {spec.spell} is set in '
                   f'the aura arm only; over {attempts.running[1]} ms '
                   + (f'the damage of its triggered tick spell {attempts.running[2]} ' if len(attempts.running) > 2
                      else 'its periodic damage ')
                   + f'at the caster (count and logged total per attacker), the caster\'s health before and after, and {spec.spell} on each '
                   f'attacker (held) are read, then {attempts.running[0]} is removed from the caster. The running part '
                   f'passes when every window ticks, {spec.spell} is held after every aura-arm window, the pooled health '
                   f'loss of each arm is within {DAMAGE_BAND:.0%} of its logged tick damage, and the aura arm\'s mean '
                   f'tick is within {DAMAGE_BAND:.0%} of the control mean.')
    shield = ''
    if attempts.shield:
        shield = (f' Damage shield: in every trial of every arm, after the pre reads, one attacker in turn (attacker1 '
                  f'to attacker{ATTACKERS}) gets the damage shield {attempts.shield[0]} (read back as on) and the '
                  f'caster auto-attacks it for {attempts.shield[1]} ms; the caster\'s SMSG_SPELLDAMAGESHIELD count '
                  f'({DAMAGE_SHIELD_OPCODE}) before and after, the last such packet\'s damage (word '
                  f'{SHIELD_DAMAGE_WORD}), the caster\'s health before and after, and {spec.spell} on the struck '
                  f'attacker (held) are read, then the shield is removed. The shield part passes when each arm has '
                  f'a window with a shield packet, {spec.spell} is held after every aura-arm window with one, the '
                  f'pooled health loss of each arm is within {DAMAGE_BAND:.0%} of its packets times their damage, and '
                  f'the aura arm\'s mean loss per packet is within {DAMAGE_BAND:.0%} of the control mean.')
    landed = {'logs': '',
              'aura': f' An attempt lands when {attempts.spell} is on the caster from that attacker after it (read as '
                      f'landed), and {attempts.spell} is removed from the caster after every attempt read.',
              'periodic': f' An attempt lands when the periodic damage count of {attempts.spell} from that attacker '
                          f'at the caster grows over its wait (read as ticks).'}[attempts.landed]
    if attempts.landed_tick:
        landed = (f' An attempt lands when the damage logs of its triggered tick spell {attempts.landed_tick} from '
                  f'that attacker at the caster grow over its wait (read as logs); {attempts.spell} is then removed '
                  f'from the caster and from the attacker.')
    scenario['contract'] = (
        f'Attacker attempts: {ATTACKERS} passive attackers (creature entry {DUMMY_ENTRY}, level '
        f'{class_file["level"]}, {STRIKER_DISTANCE:g} yd) each cast {attempts.spell} at the caster twice per trial, '
        f'{attempts.wait_ms} ms apart; the caster\'s dodge and parry are forced to 0.{fixture} Before each trial the '
        f'attacker\'s {spec.spell} is removed and, in the aura arm only ({rounds["aura"]} trials), set again (read '
        f'back as pre); the control arms ({rounds["control"]} trials each) run first and last without it. After '
        f'every attempt the attacker\'s {attempts.spell} SPELL_GO count, damage logs at the caster and its '
        f'{spec.spell} aura are read. Passes when no first attempt of the aura arm lands, the aura is gone after '
        f'every one of them, and the second attempts land within +-{BAND_POINTS:g} points of the pooled control '
        f'attempts (99% Newcombe interval, Wilson per arm).{landed}{running}{shield}')
    waited = sum(step['ms'] for step in steps if step['action'] == 'wait')
    scenario.pop('timeout_ms', None)
    timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)


def model(spec, attempts: AttackerAttempts) -> dict:
    recorded = {'spell': attempts.spell, 'trials': attempts.trials, 'wait_ms': attempts.wait_ms,
                'aura': spec.spell}
    if attempts.attacker_auras:
        recorded['attacker_auras'] = list(attempts.attacker_auras)
    if attempts.running:
        recorded['running'] = {'spell': attempts.running[0], 'wait_ms': attempts.running[1]}
        if len(attempts.running) > 2:
            recorded['running']['tick'] = attempts.running[2]
    if attempts.landed != 'logs':
        recorded['landed'] = attempts.landed
    if attempts.landed_tick:
        recorded['landed_tick'] = attempts.landed_tick
    if attempts.shield:
        recorded['shield'] = {'spell': attempts.shield[0], 'wait_ms': attempts.shield[1]}
        if attempts.shield[2]:
            recorded['shield']['caster_auras'] = list(attempts.shield[2])
    return {NAME: recorded}


def recorded_attempts(recorded: dict) -> AttackerAttempts:
    running = recorded.get('running')
    shield = recorded.get('shield')
    return AttackerAttempts(recorded['spell'], recorded['trials'], recorded['wait_ms'],
                            tuple(recorded.get('attacker_auras', ())),
                            (running['spell'], running['wait_ms'], *([running['tick']] if 'tick' in running else []))
                            if running else None,
                            recorded.get('landed', 'logs'),
                            (shield['spell'], shield['wait_ms'], tuple(shield.get('caster_auras', ())))
                            if shield else None, recorded.get('landed_tick'))


def tallies(run, recorded: dict) -> dict | str:
    from compare import missing_measurement
    from profile import CASTER
    attempts = recorded_attempts(recorded)
    head = prefix(recorded['aura'], attempts)
    counts = {'first': [0, 0], 'kept': 0, 'second': [0, 0], 'control': [0, 0]}
    name = landed_name(attempts)
    if attempts.running:
        counts['running'] = {arm: {'windows': 0, 'ticks': 0, 'logged': 0, 'health': 0, 'held': 0}
                             for arm in ('aura', 'control')}
    if attempts.shield:
        counts['shield'] = {arm: {'windows': 0, 'struck': 0, 'packets': 0, 'expected': 0, 'health': 0, 'held': 0}
                            for arm in ('aura', 'control')}

    def value(label: str) -> float | str:
        found = run.values.get(label)
        return missing_measurement(run, label) if found is None else found

    for attacker in attacker_ids():
        for fixture in attempts.attacker_auras:
            found = value(fixture_label(head, fixture, attacker))
            if isinstance(found, str):
                return found
            if found <= 0:
                return f'{attacker} does not carry the fixture aura {fixture}, so the attempts are not read'
    for fixture in caster_auras(attempts):
        found = value(fixture_label(head, fixture, CASTER))
        if isinstance(found, str):
            return found
        if found <= 0:
            return f'the caster does not carry the fixture aura {fixture}, so the shield is not read'
    for arm, rounds in arm_rounds(attempts).items() if attempts.shield else ():
        pooled = counts['shield']['aura' if arm == 'aura' else 'control']
        for index in range(1, rounds + 1):
            found = {read: value(shield_label(head, arm, index, read))
                     for read in ('on', 'packets_before', 'packets_after', 'damage', 'health_before',
                                  'health_after', 'held')}
            missing = next((item for item in found.values() if isinstance(item, str)), None)
            if missing is not None:
                return missing
            if found['on'] <= 0:
                return (f'{arm} arm trial {index}: {struck_attacker(index)} does not carry the shield '
                        f'{attempts.shield[0]}, so the shield is not read')
            if arm != 'aura' and found['held'] > 0:
                return (f'{arm} arm trial {index}: {struck_attacker(index)} carries {recorded["aura"]} '
                        f'{found["held"]:g} after the shield window, so the arm is not what it claims')
            packets = found['packets_after'] - found['packets_before']
            pooled['windows'] += 1
            if packets < 1:
                continue
            pooled['struck'] += 1
            pooled['packets'] += packets
            pooled['expected'] += packets * found['damage']
            pooled['health'] += found['health_before'] - found['health_after']
            pooled['held'] += int(found['held'] > 0)
    for arm, rounds in arm_rounds(attempts).items() if attempts.running else ():
        pooled = counts['running']['aura' if arm == 'aura' else 'control']
        for index in range(1, rounds + 1):
            health = [value(running_label(head, arm, index, read, CASTER)) for read in ('health_before',
                                                                                         'health_after')]
            missing = next((found for found in health if isinstance(found, str)), None)
            if missing is not None:
                return missing
            pooled['health'] += health[0] - health[1]
            for attacker in attacker_ids():
                found = {read: value(running_label(head, arm, index, read, attacker))
                         for read in ('dot', 'ticks', 'damage', 'held')}
                found.update({f'{read}_before': value(running_label(head, arm, index - 1, read, attacker))
                              for read in ('ticks', 'damage')})
                missing = next((item for item in found.values() if isinstance(item, str)), None)
                if missing is not None:
                    return missing
                if found['dot'] <= 0:
                    return (f'{arm} arm trial {index}: {attempts.running[0]} from {attacker} is not on the caster '
                            f'before the window, so the running effect is not read')
                ticks = found['ticks'] - found['ticks_before']
                if ticks < 1:
                    return (f'{arm} arm trial {index}: {attempts.running[0]} from {attacker} did not tick in the '
                            f'window, so the running effect is not read')
                pooled['windows'] += 1
                pooled['ticks'] += ticks
                pooled['logged'] += found['damage'] - found['damage_before']
                pooled['held'] += int(found['held'] > 0)
    for arm, rounds in arm_rounds(attempts).items():
        for attacker in attacker_ids():
            previous = {read: value(read_label(head, arm, 'r0', read, attacker)) for read in (name, 'go')}
            for index in range(1, rounds + 1):
                pre = value(read_label(head, arm, f'r{index}', 'pre', attacker))
                if isinstance(pre, str):
                    return pre
                if (pre > 0) != (arm == 'aura'):
                    return (f'{arm} arm trial {index}: {attacker} carries {recorded["aura"]} {pre:g} before the '
                            f'first attempt, so the arm is not what it claims')
                for attempt in ATTEMPTS:
                    moment = f'r{index}{attempt}'
                    now = {read: value(read_label(head, arm, moment, read, attacker))
                           for read in (name, 'go', 'aura')}
                    missing = next((found for found in (*previous.values(), *now.values()) if isinstance(found, str)),
                                   None)
                    if missing is not None:
                        return missing
                    if now['go'] - previous['go'] != 1:
                        return (f'{arm} arm {moment}: {attacker} sent {now["go"] - previous["go"]:g} SPELL_GO for '
                                f'one attempt of {attempts.spell}, so the attempt is not read')
                    landed = int(now[name] > 0 if attempts.landed == 'aura' else now[name] - previous[name] > 0)
                    if arm != 'aura':
                        counts['control'][0] += 1
                        counts['control'][1] += landed
                    elif attempt == 'a':
                        counts['first'][0] += 1
                        counts['first'][1] += landed
                        counts['kept'] += int(now['aura'] > 0)
                    else:
                        counts['second'][0] += 1
                        counts['second'][1] += landed
                    previous = {name: now[name], 'go': now['go']}
    return counts


def running_finding(running: dict | None, recorded: dict) -> tuple[str, str] | None:
    if running is None:
        return None
    aura, control = running['aura'], running['control']
    spell = recorded['running']['spell']
    text = (f'running {spell}: held {recorded["aura"]} after {aura["held"]} of {aura["windows"]} aura-arm windows; '
            f'health loss {aura["health"]:g} against {aura["logged"]:g} logged in {aura["ticks"]} ticks (aura arm), '
            f'{control["health"]:g} against {control["logged"]:g} in {control["ticks"]} ticks (control)')
    if not control['logged'] or abs(control['health'] - control['logged']) > DAMAGE_BAND * control['logged']:
        return 'unmeasured', f'{text}; the control health loss does not match its logged ticks'
    if aura['held'] < aura['windows']:
        return 'alert', f'{text}; a tick of the running effect removed the aura'
    if abs(aura['health'] - aura['logged']) > DAMAGE_BAND * aura['logged']:
        return 'alert', f'{text}; the aura-arm ticks dealt less or more than they logged'
    aura_mean, control_mean = aura['logged'] / aura['ticks'], control['logged'] / control['ticks']
    if abs(aura_mean - control_mean) > DAMAGE_BAND * control_mean:
        return 'alert', f'{text}; mean tick {aura_mean:g} against {control_mean:g} in the control'
    return 'ok', f'{text}; mean tick {aura_mean:g} against {control_mean:g}'


def shield_finding(shield: dict | None, recorded: dict) -> tuple[str, str] | None:
    if shield is None:
        return None
    aura, control = shield['aura'], shield['control']
    spell = recorded['shield']['spell']
    text = (f'shield {spell}: packets in {aura["struck"]} of {aura["windows"]} aura-arm windows and '
            f'{control["struck"]} of {control["windows"]} control windows; held {recorded["aura"]} after '
            f'{aura["held"]} of {aura["struck"]}; health loss {aura["health"]:g} against {aura["expected"]:g} sent in '
            f'{aura["packets"]} packets (aura arm), {control["health"]:g} against {control["expected"]:g} in '
            f'{control["packets"]} (control)')
    if not aura['struck'] or not control['struck'] or not control['expected']:
        return 'unmeasured', f'{text}; an arm has no shield packet'
    if abs(control['health'] - control['expected']) > DAMAGE_BAND * control['expected']:
        return 'unmeasured', f'{text}; the control health loss does not match its shield packets'
    if aura['held'] < aura['struck']:
        return 'alert', f'{text}; a landed shield of a holder removed the aura'
    if abs(aura['health'] - aura['expected']) > DAMAGE_BAND * aura['expected']:
        return 'alert', f'{text}; the aura-arm shields dealt less or more than they sent'
    aura_mean, control_mean = aura['health'] / aura['packets'], control['health'] / control['packets']
    if abs(aura_mean - control_mean) > DAMAGE_BAND * control_mean:
        return 'alert', f'{text}; mean loss per packet {aura_mean:g} against {control_mean:g} in the control'
    return 'ok', f'{text}; mean loss per packet {aura_mean:g} against {control_mean:g}'


def verdict(verdict, run, recorded: dict):
    from compare import crit_share_difference
    from stack import MEASURED
    counts = tallies(run, recorded)
    if isinstance(counts, str):
        return replace(verdict, status='unmeasured', explanation=f'attacker attempts: {counts}')
    (first, first_landed), kept = counts['first'], counts['kept']
    (second, second_landed), (control, control_landed) = counts['second'], counts['control']
    measured, low, high = crit_share_difference((control, control_landed), (second, second_landed))
    text = (f'attacker attempts of {recorded["spell"]} under {recorded["aura"]}: {first_landed} of {first} first '
            f'attempts landed (expected 0), the aura kept after {kept} of them (expected 0); second attempts landed '
            f'{second_landed} of {second}, control attempts {control_landed} of {control}, difference '
            f'{measured:+.2f} points, 99% interval {low:+.2f} to {high:+.2f} (Newcombe, Wilson per arm) against '
            f'+-{BAND_POINTS:g}')
    running = running_finding(counts.get('running'), recorded)
    shield = shield_finding(counts.get('shield'), recorded)
    for found in (running, shield):
        if found:
            text = f'{text}; {found[1]}'
    if any(found and found[0] == 'unmeasured' for found in (running, shield)):
        return replace(verdict, status='unmeasured', explanation=f'attacker attempts: {text}')
    if running and running[0] == 'alert':
        status, reason = 'alert', 'the running effect consumed the aura or lost damage'
    elif shield and shield[0] == 'alert':
        status, reason = 'alert', 'a landed shield of a holder consumed the aura or lost damage'
    elif first_landed or kept:
        status, reason = 'alert', 'a first attempt landed or left the aura on'
    elif -BAND_POINTS <= low and high <= BAND_POINTS:
        status, reason = 'ok', f'the second attempts land within +-{BAND_POINTS:g} points of the control'
    elif abs(measured) > BAND_POINTS:
        status, reason = 'alert', f'the second attempts land more than {BAND_POINTS:g} points from the control'
    else:
        status, reason = MEASURED, 'the interval crosses the band: more trials needed, not final'
    return replace(verdict, status=status, measured=measured, expected=0.0, low=low, high=high,
                   detail={**(verdict.detail or {}), NAME: counts}, explanation=f'{text}; {reason}')
