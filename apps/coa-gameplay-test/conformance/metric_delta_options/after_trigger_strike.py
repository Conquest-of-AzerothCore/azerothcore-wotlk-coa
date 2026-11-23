from dataclasses import dataclass

NAME = 'after_trigger_strike'
ORDER = 5


@dataclass(frozen=True)
class AfterTriggerStrike:
    spell: int
    delay_ms: int
    count: int = 1
    wait_ms: int = 300


def parse(raw) -> AfterTriggerStrike:
    unknown = set(raw) - {'spell', 'delay_ms', 'count', 'wait_ms'}
    if unknown or 'spell' not in raw or 'delay_ms' not in raw:
        raise ValueError(f'after_trigger_strike takes a spell, a delay_ms and an optional count and wait_ms, not '
                         f'{sorted(raw)}')
    strike = AfterTriggerStrike(int(raw['spell']), int(raw['delay_ms']), int(raw.get('count', 1)),
                                int(raw.get('wait_ms', 300)))
    if strike.delay_ms < 0 or strike.count < 1 or strike.wait_ms < 0:
        raise ValueError('after_trigger_strike needs a delay and a wait of at least 0 ms and at least one strike')
    return strike


def check(spec, strike):
    if strike is None:
        return
    if spec.strike is not None:
        raise ValueError(f'{spec.spell} sets after_trigger_strike and strike; the scenario has one striker')


def after_trigger_steps(spec, strike: AfterTriggerStrike, after: bool) -> list[dict]:
    from behaviours import STRIKER
    from profile import CASTER
    if not after:
        return []
    steps = [{'action': 'wait', 'label': 'before the strike', 'ms': strike.delay_ms}]
    for _ in range(strike.count):
        steps += [{'action': 'cast', 'actor': STRIKER, 'spell': strike.spell, 'target': CASTER},
                  {'action': 'wait', 'label': 'strike', 'ms': strike.wait_ms}]
    return steps


def fixtures(class_file: dict, spec, strike: AfterTriggerStrike, scenario: dict):
    from behaviours import STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH, TAKEN_HIT_STRIKER_ENTRY
    from profile import CASTER
    scenario.setdefault('creatures', []).append(
        {'id': STRIKER, 'owner': CASTER, 'entry': TAKEN_HIT_STRIKER_ENTRY, 'level': class_file['level'],
         'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 1, 'spell_hit_bonus': 100})
    scenario['contract'] += (f' In the treatment phase only, {strike.delay_ms} ms after the cast of '
                             f'{spec.trigger_spell}, a striker casts {strike.spell} at the caster {strike.count} '
                             f'time(s), {strike.wait_ms} ms apart; the control phase is not struck.')
