# 0025. Owner ruling O-27: one bonus for Outland Slaver and Armaments of the Legion

- Status: accepted (owner ruling O-27, relayed by the controller on 2026-11-24)
- Date: 2026-11-24

## Context

Outland Slaver 705123 (rank 1) and 707846 (rank 2), installed tooltip: "Reduces the cost of your Felrend and Fel
Fireball by $s1 and increases their damage dealt by $s2%." Effect[1] is aura 108 `SPELLMOD_DAMAGE` on dword1 bits 0
and 2 (Fel Fireball, Felrend); Effect[2] is aura 108 `SPELLMOD_ALL_EFFECTS` with the same percent on dword1 bits 0
and 24 (Fel Fireball, Twin Slice). Both stock spell modifier paths apply, so Fel Fireball took the bonus twice:
+21.53 / +16.48% (rank 1) and +44.68 / +44.70% (rank 2) against +10 and +20, while Felrend read +9.94 / +9.99 and
+19.91 / +19.94 (pair 20261123-165553 / -165628).

Armaments of the Legion 706266 (rank 1) and 707844 (rank 2): "... and increases the absorption value of Hateforged
Barrier by $s2%." Effect[1] is aura 317 `SPELL_AURA_ASCENSION_MOD_ABSORB_AMOUNT_PCT`, which multiplies the completed
absorb (`SpellAuraEffects.cpp`, `AuraEffect::CalculateAmount`); Effect[2] is aura 108 `SPELLMOD_EFFECT1` with the same
percent on Hateforged Barrier. The absorb read 1016 / 1029 and 1233 / 1207 against 931 and 1016 (1.21x and 1.44x,
pair 20261123-171751 / -171923).

The owner ruled (O-27): the server follows the tooltip, one bonus only (+10% and +20%), and Felsworn code neutralises
the duplicate. The duplicate comes from the DBC data read by stock paths; no stock or core file changes.

## Options

- Drop the Fel Fireball bit from Outland Slaver's Effect[2] mask and keep Effect[1], the modifier Felrend already
  gets; Twin Slice keeps Effect[2] untouched.
- Drop Effect[2] of Outland Slaver entirely. Rejected: it would also remove a Twin Slice bonus the ruling does not
  address.
- For Armaments, dummy Effect[2] (`SPELLMOD_EFFECT1`) and keep aura 317, which scales the whole absorb, Stamina term
  included, as "increases the absorption value" states.
- Dummy aura 317 instead. Rejected: the shared aura 317 channel stays the one other classes use for absorb bonuses,
  and the stated bonus is on the absorption value, not on one effect's base points.

## Decision

`ApplyContracts` (`AscensionFelswornContracts.cpp`), keyed to 705123, 707846, 706266 and 707844: Outland Slaver
Effect[2] loses dword1 bit 0; Armaments Effect[2] becomes `SPELL_AURA_DUMMY`. No shared file, DBC, SQL or client
text changes.

## Consequences

- Fel Fireball and its family copies with dword1 bit 0 (501281..501291, 503087, 800356, 801312, Ragefire 803481)
  get one Outland Slaver bonus; Twin Slice (dword1 bit 24) keeps its Effect[2] +10% / +20%, which the tooltip does
  not state (an observation, not changed here).
- Hateforged Barrier's absorb rises once, by aura 317.
- Readers of the four spells: the conformance entries 705123/707846 `fel_fireball_damage` and 706266/707844
  `barrier_absorb` (now with the spell penetration fixture 823764 on the Fel Fireball arms), and the gameplay
  scenarios `felsworn-outland-slaver.json` (new Effect[2] reads on Fel Fireball and Twin Slice) and
  `felsworn-armaments-of-the-legion.json` (no `SPELLMOD_EFFECT1` modifier on Hateforged Barrier). No other class
  lists these spells (class map `shared_with` empty).
