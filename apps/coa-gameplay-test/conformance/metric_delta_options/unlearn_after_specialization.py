NAME = 'unlearn_after_specialization'
ORDER = 27


def parse(raw) -> list[int]:
    if not isinstance(raw, list) or not raw or not all(type(spell) is int and spell > 0 for spell in raw) \
            or len(set(raw)) != len(raw):
        raise ValueError(f'unlearn_after_specialization is a non-empty list of distinct spell ids, not {raw!r}')
    return list(raw)


def check(spec, spells):
    if spells is None:
        return
    if 'specialization' not in dict(spec.options):
        raise ValueError(f'{spec.spell} unlearn_after_specialization requires specialization; use unlearn_before '
                         f'otherwise')


def phase_steps(spec, spells: list[int], after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    return [{'action': 'unlearn', 'actor': CASTER, 'spell': spell} for spell in spells]


def fixtures(class_file: dict, spec, spells: list[int], scenario: dict):
    specialization = dict(spec.options)['specialization']
    scenario['contract'] += (
        f' After switching to specialization {specialization}, {spells} (auto-learned by the specialization switch) '
        f'are unlearned before the before reading so the control arm does not know them and the learn between phases '
        f'teaches the spell.')
