# 0601. An effectiveness modifier is read on the effect it modifies

- Status: accepted
- Date: 2026-11-13

## Context

Claim 117.0, Improved Mandates 560613 "Increases the effectiveness of your Mandates by $s1%", was a tool gap
("Mandate value read"): only its `effect_value` (data) was judged. 560613 Effect[0] is aura 108
SPELL_AURA_ADD_PCT_MODIFIER, MiscValue 8 (SPELLMOD_ALL_EFFECTS), +20% on family 29 mask 64, the mask of Grim Mandate
572789 and Foul Mandate 573298. A `metric_delta` read of the Mandate's own stat (spell power, Stamina) with the talent
learned between two real Mandate casts is the behaviour, but coverage counts a state read as behaviour only where
the clause carries the read metric's promise words (`spell power`, `stamina`), and this clause names neither.

## Options

- Add `effectiveness` to the shared `spell_power` and `stat` promises in `coverage.STATE_PROMISES`: a central-list
  edit that would let every "effectiveness" clause pass on any stat read.
- An `aura_amount` read of the Mandate aura: a readback, data, not behaviour.
- A kind module that runs the `metric_delta` scenario and judge unchanged and names its own state metric
  `effectiveness_<read>` with the promise word `effectiveness` (ADR 0581 module rows).

## Decision

Kind `effectiveness_delta` (kinds/effectiveness_delta.py): an entry with `metric_delta` fields; the effect is cast
in both phases (`cast_in_before`), the modifier is learned between them (`gate_spell`, `gate_timing` `between`),
the read is `spell_power` or `stat`; anything else is refused. The judge is `metric_delta`'s on the original read.

## Consequences

- 117.0 has two behaviour entries: Grim Mandate Shadow spell power 49 -> 58 and Foul Mandate Stamina 122 -> 132.
  The tooltip values are 58.8 and 132.8; the engine stores the modified amount as int32 (`Player::ApplySpellMod`,
  Player.cpp:10658), the known engine rounding of G-26.
- The shared tables are unchanged; Templar has no entry of this kind.
- Test: kinds/test_effectiveness_delta.py (scenario order, control mutant, promise, refused entries).
