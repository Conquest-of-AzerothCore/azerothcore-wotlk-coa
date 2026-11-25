# 0008. Fel Haze ignores all enemy armor

- Status: accepted (owner ruling Felsworn O-13 (2026-11-23, Felsworn ADR 0008))
- Date: 2026-11-23

## Context

Fel Haze 803903 (server Spell.dbc, Description[enUS]): "While active, Blood of Mannoroth now also causes you to ignore
all enemy Armor."

Server DBC set:

| Id | Effect | Aura | MiscValue | BasePoints (DieSides 1) | Class mask |
|---|---|---|---|---|---|
| 803903 Fel Haze | 0 | 107 `SPELL_AURA_ADD_FLAT_MODIFIER` | 3 `SPELLMOD_EFFECT1` | 99 (+100) | [0] 0x200000 |
| 802075 Blood of Mannoroth | 0 | 280 `SPELL_AURA_MOD_ARMOR_PENETRATION_PCT` | 0 | -1 (0) | none |

Blood of Mannoroth (SpellFamilyName 20, SpellFamilyFlags[0] 0x200000) reaches 100% only through Fel Haze. The engine
reads aura 280 through the stock armor penetration cap of `Unit::CalcArmorReducedDamage`:
`maxArmorPen = std::min((armor + K) / 3, armor)`, so 100% removes at most a third of armor plus K. Against armor A and
constant K the damage kept goes from K / (A + K) to K / (A + K - (A + K) / 3): a ratio of exactly 3/2 whenever
(A + K) / 3 < A.

Conformance pair proveC (2026-11-23, build `1e433a3c0c18`, server `ebbeaa0255cf`, runs 20261123-154742 and
20261123-154842) read the `803903 ignores_armor` hit ratio at 1.5226 and 1.5274 against the dummy at armor 5528
(K = 5500 at level 60), where ignoring all armor gives (5528 + 5500) / 5500 = 2.0051. The cause is the stock cap
applied to DBC aura 280, not CoA code, so the case went to the owner, who ruled (Felsworn O-13 (2026-11-23)) that Fel Haze ignores all enemy
armor.

## Options

- Move Blood of Mannoroth Effect[0] from aura 280 to the CoA aura 338
  `SPELL_AURA_ASCENSION_MOD_IGNORE_ARMOR_PCT` in the Felsworn contract. The amount (0, or 100 with Fel Haze) removes
  that share of the armor before the stock cap is computed, with no cap.
- Change the stock cap in `Unit.cpp`. Rejected: a shared engine path read by every aura 280 source in the server
  Spell.dbc (985345 Reg's Armor Pen among them).

## Decision

In `AscensionFelsworn::ApplyContracts`, keyed to 802075 Blood of Mannoroth (SpellFamilyName 20) and guarded on its
DBC aura 280, move Effect[0] to aura 338. No shared file changes.

## Consequences

- With Fel Haze, Blood of Mannoroth sets the Felsworn's armor-ignore share to 100%: physical hits, white swings
  included (Effect[0] has no class mask), meet zero armor. Without Fel Haze the amount stays 0 and nothing changes.
- Aura 338 is read only by `Unit::CalcArmorReducedDamage`, from the attacker's own auras and from the victim's auras
  cast by that attacker. Blood is a self aura, so it counts only when the Felsworn attacks. The other aura 338 sources
  (Sun Cleric Vindicator 704938 and 707773, Witch Hunter 804194 Decimate, Xoroth 706501) are not touched.
- The other aura 280 sources at 100%, 804194 Decimate (already moved to aura 338 by the Witch Hunter contract) and
  985345 Reg's Armor Pen, are not touched. The stock cap in `Unit.cpp` is unchanged.
- Spell positivity is unchanged: neither aura 280 nor 338 has a case in `SpellInfo::_IsPositiveEffect`.
- Regressions: the `hit_ratio` entry `803903 ignores_armor` (control Blood of Mannoroth without Fel Haze, treatment
  with it, armor 5528: 2.0051; both arms hold Increase Damage 37643 set to +19900% so each hit is about 3000 and the
  engine's `ceil` on the armored hit stays under 0.1%: with Carve's bare 14-16 hits it rounds 7-8 and the ratio reads
  about 1.95) and the zero-armor entry `803903 ignores_armor_unarmored` (the same arms at armor 0:
  1.0). The scenario `felsworn-fel-haze.json` keeps its effect value reads (0 without, 100 with Fel Haze).
- No client text change: the tooltip already states the behaviour. No DBC file change.
