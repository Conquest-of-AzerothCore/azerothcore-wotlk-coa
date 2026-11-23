# 0199. Judge "does not stack" by two sources on one unit

- Status: accepted
- Date: 2026-11-12

## Context

Crusader's Presence 562302: "Does not stack with similar effects." Its effects are raid area auras: 172
(SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK), 211 and 210 (SPELL_AURA_MOD_FLIGHT_SPEED_NOT_STACKING), each +50. The mentor
(ext2 item 4 calls, 2026-11-12) asked for two Templars applying the aura to one unit, each stat the data names reading
the single-source value, against a one-source and a no-source control, and counts applied auras with stat reads as
behaviour.

## Decision

- Behaviour kind `source_stack` (`metrics`, `caster_auras`): the caster and a grouped ally, both carrying the fixture
  auras (a mount here), learn the spell; the stats are read on the caster with no source, after its own cast, and
  after the ally's cast, with the aura from each caster read alongside.
- Check `behaviour_source_stack`, evidence behaviour: `ok` when every stat moved by one source reads the same with
  both; `alert` when one moves again; `unmeasured` when no stat moved, when the caster lacks its own copy, or when the
  second source is not shown: the scenario reads the ally's cast failure (must be 0) and the ally's own copy (must be
  1) after its cast (review I5). A second copy that the engine keeps off the caster is then stated, not failed.

## Consequences

- Claim 128 is behaviour proven on one counted pair (20261112-010225, -010254, build 44ccd3ce350e): run speed 1.6 /
  2.4 / 2.4, flight speed 1 / 1.5 / 1.5; the ally's cast has no failure and the ally holds its own copy, which never
  joins the caster's own. No effect stacks. The earlier pair (003251, -003320) lacked the two ally reads.
- The two flight effects, both +50, are read as one figure.
- No existing scenario changes.
- Tests: `test_behaviours.SourceStackTests`.
