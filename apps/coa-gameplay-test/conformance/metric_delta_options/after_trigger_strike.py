from dataclasses import dataclass, replace

NAME = 'after_trigger_strike'
ORDER = 5


@dataclass(frozen=True)
class AfterTriggerStrike:
    spell: int
    delay_ms: int
    count: int = 1
    wait_ms: int = 300
    before_aura: int | None = None


def parse(raw) -> AfterTriggerStrike:
    unknown = set(raw) - {'spell', 'delay_ms', 'count', 'wait_ms', 'before_aura'}
    if unknown or 'spell' not in raw or 'delay_ms' not in raw:
        raise ValueError(f'after_trigger_strike takes a spell, a delay_ms and optional count, wait_ms and before_aura, '
                         f'not {sorted(raw)}')
    before_aura = raw.get('before_aura')
    if before_aura is not None and (type(before_aura) is not int or before_aura <= 0):
        raise ValueError(f'after_trigger_strike before_aura must be a positive spell id, not {before_aura!r}')
    strike = AfterTriggerStrike(int(raw['spell']), int(raw['delay_ms']), int(raw.get('count', 1)),
                                int(raw.get('wait_ms', 300)), before_aura)
    if strike.delay_ms < 0 or strike.count < 1 or strike.wait_ms < 0:
        raise ValueError('after_trigger_strike needs a delay and a wait of at least 0 ms and at least one strike')
    return strike


def check(spec, strike):
    if strike is None:
        return
    if spec.strike is not None:
        raise ValueError(f'{spec.spell} sets after_trigger_strike and strike; the scenario has one striker')


def before_aura_label(spec, aura: int) -> str:
    return f'{spec.spell} after_trigger_strike before_aura {aura}'


def after_trigger_steps(spec, strike: AfterTriggerStrike, after: bool) -> list[dict]:
    from behaviours import STRIKER
    from profile import CASTER, measurement
    if not after:
        return []
    steps = [{'action': 'wait', 'label': 'before the strike', 'ms': strike.delay_ms}]
    if strike.before_aura is not None:
        steps.append(measurement(before_aura_label(spec, strike.before_aura), CASTER, 'aura',
                                 spell=strike.before_aura, caster=CASTER))
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
    if strike.before_aura is not None:
        scenario['contract'] += (f' Right after the {strike.delay_ms} ms delay and before the strike, the caster must '
                                 f'hold aura {strike.before_aura} (cast by caster); an absent aura alerts and an '
                                 f'unread aura voids the trial (unmeasured).')


def model(spec, strike: AfterTriggerStrike) -> dict:
    if strike.before_aura is None:
        return {}
    return {NAME: {'before_aura': strike.before_aura,
                   'before_aura_label': before_aura_label(spec, strike.before_aura)}}


def verdict(verdict, run, strike: dict):
    held = run.values.get(strike['before_aura_label'])
    if held is None:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; pre-strike aura {strike["before_aura"]} was not measured')
    if held < 1:
        return replace(verdict, status='alert',
                       explanation=f'{verdict.explanation}; caster did not hold aura {strike["before_aura"]} before '
                                   f'the strike (read {held:g}), so absence after the strike does not prove '
                                   f'cancellation')
    return replace(verdict,
                   explanation=f'{verdict.explanation}; caster held aura {strike["before_aura"]} before the strike '
                               f'({held:g})')
