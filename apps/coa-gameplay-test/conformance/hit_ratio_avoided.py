from dataclasses import dataclass

import proc_avoided
from profile import CASTER, measurement

NAME = 'avoided_grant'
FIELDS = frozenset({'proc_aura', 'striker_entry', 'strikers', 'striker_auras', 'swing_ms', 'grant_ms', 'lead_ms'})
DODGE, PARRY = 100, 0
ARMS = ('control', 'treatment')


@dataclass(frozen=True)
class AvoidedGrant:
    proc_aura: int
    striker_entry: int
    strikers: int
    striker_auras: tuple[int, ...]
    swing_ms: int
    grant_ms: int
    lead_ms: int


def parse(raw: dict | None) -> AvoidedGrant | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or set(raw) != FIELDS or not isinstance(raw['striker_auras'], list) or any(
            isinstance(value, bool) or not isinstance(value, int) or value <= 0
            for value in (*(raw[key] for key in FIELDS - {'striker_auras'}), *raw['striker_auras'])):
        raise ValueError(f'hit_ratio {NAME} is {{{", ".join(sorted(FIELDS))}}} of positive whole numbers '
                         f'(striker_auras a list of them), not {raw!r}')
    if raw['grant_ms'] % raw['swing_ms'] or raw['lead_ms'] % raw['swing_ms']:
        raise ValueError(f'hit_ratio {NAME} grant_ms {raw["grant_ms"]} and lead_ms {raw["lead_ms"]} are whole '
                         f'numbers of swing_ms {raw["swing_ms"]}')
    return AvoidedGrant(raw['proc_aura'], raw['striker_entry'], raw['strikers'], tuple(raw['striker_auras']),
                        raw['swing_ms'], raw['grant_ms'], raw['lead_ms'])


def avoided_entry(spell: int, grant: AvoidedGrant) -> dict:
    return {'aura': spell, 'trigger': {'action': proc_avoided.AVOIDED, 'striker_entry': grant.striker_entry,
                                       'swing_ms': grant.swing_ms, 'dodge': DODGE, 'parry': PARRY,
                                       'strikers': grant.strikers, 'striker_auras': list(grant.striker_auras)}}


def target(spell: int, grant: AvoidedGrant) -> str:
    return proc_avoided.striker_ids(avoided_entry(spell, grant))[0]


def check(spec):
    grant = spec.avoided_grant
    if grant is None:
        return
    proc_avoided.checked_trigger(avoided_entry(spec.spell, grant))
    if spec.swing_hand is not None or spec.versus is not None or spec.caster != CASTER or \
            spec.target != target(spec.spell, grant) or spec.target_health_pct is not None or spec.rate:
        raise ValueError(f'{spec.spell} hit_ratio {NAME} casts at the first striker {target(spec.spell, grant)} from '
                         f'the caster, with no swings, versus, target health or rate')
    if spec.spell not in spec.treatment.learn or spec.spell in spec.control.learn or spec.spell in spec.learn:
        raise ValueError(f'{spec.spell} hit_ratio {NAME} learns {spec.spell} in the treatment arm only, so only its '
                         f'trials can earn {grant.proc_aura}')
    if any(aura == grant.proc_aura for arm in (spec.control, spec.treatment) for aura, _ in arm.auras):
        raise ValueError(f'{spec.spell} hit_ratio {NAME} earns {grant.proc_aura} by dodged swings, so no arm sets it')


def presence_label(prefix: str, arm: str, trial: int) -> str:
    return f'{prefix} {arm} {NAME} {trial}'


def engage_steps(spell: int, grant: AvoidedGrant) -> list[dict]:
    return proc_avoided.engage_steps(avoided_entry(spell, grant))


def trial_steps(spell: int, grant: AvoidedGrant, prefix: str, arm: str, trial: int) -> list[dict]:
    entry = avoided_entry(spell, grant)
    window = grant.grant_ms + (grant.lead_ms if trial == 1 else 0)
    return (proc_avoided.attempt_steps(entry, window // grant.swing_ms, grant.swing_ms)
            + [measurement(presence_label(prefix, arm, trial), CASTER, 'aura', spell=grant.proc_aura)])


def creatures(class_file: dict, spell: int, grant: AvoidedGrant) -> list[dict]:
    return proc_avoided.striker_fixtures(class_file, avoided_entry(spell, grant))


def model(grant: AvoidedGrant, prefix: str, trials: int) -> dict:
    return {'proc_aura': grant.proc_aura,
            'presence': {arm: [presence_label(prefix, arm, trial) for trial in range(1, trials + 1)]
                         for arm in ARMS}}


def contract(spell: int, grant: AvoidedGrant) -> str:
    return (f'; {NAME}: {grant.strikers} stationary strikers {grant.striker_entry} swing at the caster in both arms '
            f'with the caster\'s dodge at {DODGE}% and parry at {PARRY}%; {spell} is learned for the treatment arm '
            f'only, so {grant.proc_aura} is earned by the real dodge route, never set; before every observed cast '
            f'the strikers swing for {grant.grant_ms} ms ({grant.lead_ms} ms more before the first trial of each '
            f'arm) and {grant.proc_aura} is read on the caster: the run is void (unmeasured) when a treatment trial '
            f'reads it absent or a control trial reads it present')


def void(runs, grant_model: dict) -> str | None:
    expected = {'control': 0.0, 'treatment': 1.0}
    for index, run in enumerate(runs, 1):
        for arm, labels in grant_model['presence'].items():
            for trial, label in enumerate(labels, 1):
                value = run.values.get(label)
                if value is None:
                    return f'part {index}: {label} was not read'
                if (value > 0) != (expected[arm] > 0):
                    return (f'part {index}: {grant_model["proc_aura"]} is {"present" if value > 0 else "absent"} '
                            f'before {arm} trial {trial}')
    return None
