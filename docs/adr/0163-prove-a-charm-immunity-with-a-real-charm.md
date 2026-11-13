# 0163. Prove a charm immunity with a real charm

- Status: accepted (mentor approval with conditions, 2026-11-11)
- Date: 2026-11-11

## Context

Testament of Resolve 804228: "granting immunity to fear, charm, and horrify effects". Fear and horrify are proven
by the `immunity` kind. Its Spell.dbc effects name no charm immunity, and a readback (20261111-213317) read
`IsImmunedToSpell` 0 for a charm with 804228 up. A charm on the player fixture hands its control to the charmer,
so the mentor set conditions: its own scenario and fixture pair, the read inside the charm, the charm removed after
each read in both arms, the cleanup asserted, solo runs first.

## Decision

- The server action is real: the dummy casts Domination 37122 (one effect, aura 6 SPELL_AURA_MOD_CHARM, Mechanic 1,
  10 s, instant) at the caster through the harness `cast` action, the creature's own `Unit::CastSpell`.
- The `charm_immunity` kind runs a control arm (no 804228, the charm must land) and a treatment arm (804228 cast on
  the caster, the charm must not land), reads the charm aura 500 ms after each cast and removes it at once with
  `set_aura` `stacks: 0`.
- After each arm it asserts within 15000 ms, failing the scenario otherwise: no charm aura, no charmer (`charmed`, a
  new read of `Unit::IsCharmed`), `controls_self`, the faction back to its snapshot, and the dummy attacking nobody.
- "Dummy out of combat" is read and not asserted. A REACT_PASSIVE fixture never evades while it holds a PvE combat
  reference (CreatureAI.cpp:364-377), and no harness action ends combat; asserting it failed the first solo run
  (20261111-215507). Ending it would need a server-changing harness action, which is left to the mentor.

## Consequences

- Solo runs 20261111-215507 (failed on the combat assertion) and 20261111-215852 (passed): the charm lands without
  804228 and also with 804228 up. Claim 365's charm part is an owner question (status 5).
- Tests: `test_runner.test_charmed_needs_a_player`, `test_behaviours.CharmImmunityTests`.
