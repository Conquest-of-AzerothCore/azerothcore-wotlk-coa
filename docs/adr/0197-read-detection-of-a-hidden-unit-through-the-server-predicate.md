# 0197. Read the detection of a hidden unit through the server's visibility predicate

- Status: accepted
- Date: 2026-11-12

## Context

Crusader's Brand 300513: "While marked enemies can always be seen by the Crusader even while stealthed or
invisible." Its Effect[1] is SPELL_AURA_MOD_STALKED (68), and `Unit::IsAlwaysDetectableFor` makes a unit carrying it
always detectable by the aura's caster. Claim 19 had no label.

## Considered options

1. The client's object list (`nearby_creature_at_client`, `Player::HaveAtClient`), static. Tried (diagnostic
   20261112-001336): stealth hid the dummy, but neither the brand nor the removal of stealth brought it back, because
   nothing triggers a visibility update while caster and dummy stand still.
2. The same, with the caster stepping 1 yd and back before each read. Tried (20261112-001430): the dummy then stayed
   at the client throughout, hidden or not.
3. `can_detect` (`Unit::CanSeeOrDetect` of the caster for the dummy), the predicate every visibility update applies.
   Chosen, as a readback: the harness calls it.

## Decision

- Behaviour kind `detection` (`reveal_aura`, `hide_auras` [[spell, name]], `distance`, `wait_ms`): for each hide aura,
  read the predicate with the dummy shown, hidden, with `reveal_aura` set on it by the caster, and with it removed;
  three exact expectations per hide aura (hidden 0, revealed 1, unrevealed 0), checked as `behaviour_metric_delta`.
- `can_detect` is a readback in `coverage.METRIC_EVIDENCE`.

## Consequences

- Claim 19 becomes data conformant on one counted pair (20261112-001621, -001651): the dummy hidden by Stealth Dummy
  2144558 and by Super Invis 8149 is detected only while it carries the caster's brand.
- An applied-visibility read needs the client's object list to refresh on an aura change; two designs failed, so the
  claim's behaviour status is a mentor question.
- No existing scenario changes.
- Tests: `test_behaviours.DetectionTests`.
