NAME = 'required_aura_stacks'
ORDER = 32


def parse(raw) -> tuple[int, int]:
    if not isinstance(raw, dict) or set(raw) != {'spell', 'stacks'} or not all(
            type(raw[key]) is int and raw[key] > 0 for key in raw):
        raise ValueError(f'required_aura_stacks is {{"spell": id, "stacks": n}} (positive integers), not {raw!r}')
    return raw['spell'], raw['stacks']


def check(spec, required):
    if required is None:
        return
    from pathlib import Path
    from profile import DBC_DIR
    from tooltip import Records
    from values import dataset, facts_of
    records = Records(dataset(Path(DBC_DIR)))
    casts = (spec.trigger_spell, *spec.setup_casts)
    if not any(facts_of(records, cast).caster_aura_spell == required[0] for cast in casts):
        raise ValueError(f'{spec.spell} required_aura_stacks names {required[0]}, the CasterAuraSpell of none of '
                         f'its casts')


def fixtures(class_file: dict, spec, required: tuple[int, int], scenario: dict):
    spell, stacks = required
    scenario['steps'] = [{**step, 'stacks': stacks}
                         if step.get('action') == 'set_aura' and step.get('spell') == spell else step
                         for step in scenario['steps']]
    scenario['contract'] += (f' The CasterAuraSpell precondition fixture {spell} of the casts that need it is set to '
                             f'{stacks} stacks instead of 1.')
