# 0029. Gavel effectiveness talents apply their figure to the whole hit

- Status: accepted (owner ruling O-18, Q-sc-8 option b, 2026-11-22; design approved by mentor D-146)
- Date: 2026-11-22
- Supersedes: [0007](0007-fanaticism-compounds-on-the-gavel-flat-damage.md) (its decision (a), the stock engine
  order, for the Gavels) and the Gavel figures of [0008](0008-fanaticism-expectation-is-the-reproduced-engine-arithmetic.md).
  0008 stays as the record of the old behaviour; its Horusath Blast row and its method stand.

## Context

Three talents raise the effectiveness of the Gavels (Gavel of Light 800611, Gavel of Grace 800614, Gavel of Wrath
800617 and their ranks) with a percent modifier on `SPELLMOD_ALL_EFFECTS`:

| Talent | Tooltip | DBC |
|---|---|---|
| Glorious Defender 680634 | "Increases the effectiveness of Gavels by $s1%." | Effect[0] aura 108, BasePoints 24 (+25%) |
| Battle Cleric 300347 | "... have $562316s1% increased effectiveness." | helper 562316 Effect[0] aura 108, BasePoints 49 (+50%), under Paragon |
| Fanaticism 805628 | "Increases the effectiveness of Gavels and Horusath Blast ..." (no figure) | Effect[0] aura 108, BasePoints 19 (+20%) |

The stock engine scales both Gavel effect values, the flat value F and the weapon percent, and adds F to the weapon
roll W before it applies the percent (`SpellEffects.cpp:4731-4743`), so a talent of factor m gives `m x (W + m x F)`:
the bonus compounds on the flat part. Base pair 10 (20261122-113024 / -115522, build fd0671597bc3, mace 2524) read
Glorious Defender +38.22 / +38.50 (Wrath), +29.48 / +30.21 (Light), +33.31 / +32.91 (Grace) against the displayed 25%,
and Battle Cleric on Gavel of Wrath 802561 +111.96 / +111.20 against the displayed 50%. ADR 0007 accepted the stock
order for Fanaticism, whose tooltip prints no figure, and ADR 0008 recorded its arithmetic.

Owner ruling O-18 (Q-sc-8, option b): the Gavel effectiveness talents are brought to the displayed figure on the whole
hit, Glorious Defender +25% and Battle Cleric +50%, and Fanaticism +20% by the consistency stated on the card. The
ruling overturns the mentor's D-54 (engine compounding kept) and asks for the fix in the Sun Cleric code, with no
engine edit. Shared ADR [0010](../../0010-argent-blade-flat-bonus-after-weapon-percent.md) asks for each class's own
evidence before its flag is used elsewhere; here the basis is the owner ruling, not live evidence (the live servers
are closed).

## Options

1. The ADR 0010 flag `SpellInfo::AscensionFlatAfterWeaponPercent` on every Gavel rank, set in the class contracts.
   The engine applies the percent to the weapon roll alone and then adds the flat value (`SpellEffects.cpp:4724-4728`),
   so the hit is `int(W x int(100 x m) / 100) + int(F x m)`: each part is scaled once. The talents stay native spell
   modifiers.
2. Strip the Gavel bit from the three talents' masks and scale the weapon percent per cast with
   `Spell::SetScriptWeaponDamageMultiplier` from a script that sums the learned talents. More code, and the committed
   scenarios that read the modifiers back (`sun-cleric-fanaticism`, `sun-cleric-glorious-defender`) would fail.
3. A hook on the hit: `OnSpellHitResult` receives the damage already dealt and `ModifySpellEffectBaseValue` runs before
   the modifiers (`SpellInfo.cpp:523-531`), so neither scales the whole hit.

## Decision

Option 1: `AscensionSunCleric::ApplyContracts` sets the flag when `Gavel(info)` holds (the three Gavel chains through
`sSpellMgr->GetFirstSpellInChain`, `AscensionSunCleric.cpp:171-174`). `ApplyContracts` runs from
`LoadSpellInfoCustomAttributes`, after the spell ranks are loaded, as for the Templar contract of ADR 0010.

Two talents add (mentor D-146): the engine sums percent modifiers of one operation (`Player.cpp:10622`) and the flag
keeps that sum, so Glorious Defender with Fanaticism is +45% and with Battle Cleric +75%. No source states another
rule; a multiplicative reading would need code outside the engine's modifier sum. The rule is listed for the owner.

## Consequences

- With no talent the hit is unchanged: `W x 100% + F` equals `(W + F) x 100%` for integer values. Crits, armor and the
  Gavel of Wrath splash, which copies the dealt damage, work on the final hit and follow it.
- The gap between the displayed 25 / 20 / 50% and the expected ratios (1.241, 1.195, 1.4975 on the reference setups)
  is integer truncation, under one point: `int(F x m)`, the truncated weapon percent product and the `ceil` of the
  armor reduction.
- Horusath Blast 500154 is not a weapon hit: it has one `SCHOOL_DAMAGE` effect and no weapon path, so the flag does not
  touch it and Fanaticism keeps ADR 0008's +19.34% (ratio 1.19336). Its tooltip prints no effectiveness figure.
- The class file's expectations come from the approved design's enumeration model of the flag route and were committed
  before the fix's first arm ran. Glorious Defender (mace 2524, attack power 70, dummy armor 528): 1.24094 Wrath,
  1.24170 Light, 1.23935 Grace. Fanaticism (Valkyr weapon 2529): 1.19451 / 1.19263 / 1.19331, and on the out-of-sample
  setup (attack power 280, creature 603 armor 3750) 1.19532 / 1.19415 / 1.19452. Battle Cleric under Paragon (attack
  power 86): 1.49255 / 1.49308 / 1.49087 and 1.49750 on rank 5 802561. Pairs: Glorious Defender with Fanaticism on
  800617 1.43838 (stock 1.74146, multiplicative 1.50000), with Battle Cleric on 802561 1.74617 (stock 2.80161,
  multiplicative 1.87500).
- The Gavel ranks join the class file's `weapon_percent_before_flat`; at a weapon percent of 100 it changes no
  generated scenario.
- No engine file, no SQL and no client text change. Other users of the flag (the Templar Argent Blade chain, the Knight
  of Xoroth 800340 chain) are untouched; their scenarios are rerun on the fix build.
- If Ascension evidence later shows the compounded hit was live behaviour, removing the line in `ApplyContracts`
  restores the stock order.
