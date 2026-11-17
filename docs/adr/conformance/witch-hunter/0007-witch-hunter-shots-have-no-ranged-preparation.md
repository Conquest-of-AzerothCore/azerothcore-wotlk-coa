# 0007. Witch Hunter shots have no ranged preparation

- Status: accepted
- Date: 2026-11-15

## Context

`SpellInfo::CalcCastTime` (core, `SpellInfo.cpp`) adds 500 ms to every `SPELL_ATTR0_USES_RANGED_SLOT` spell that is
not an auto-repeat shot. Artificer's Wand (family 28) and the Tinker shots (family 34) are already exempt. Darkslayer
(804179, 680256-680262, 681203: SpellCastTimes 1500 / 2000 / 2500 ms) and Heartseeking Bolt (805754, 807279-807284:
3000 ms) are ranged-slot spells of family 21, so the server cast them 500 ms slower than their client rows. #11409
(8ecba7989c) streamed a client cast-time row for the nine Darkslayer ranks so the tooltip showed the server's time.
Owner card Q-wh-16, ruling O-22 (variant A, full scope): the Witch Hunter family has no ranged preparation. The live
rank 9 tooltip's 1.66 s fits 2500 ms divided by the live ranged haste factor 1.506 (mentor D-109).

## Options

- Exempt Darkslayer and Heartseeking Bolt in `CalcCastTime` and in the stream's ranged-preparation selector, and
  stop streaming the Darkslayer rows (variant A: 16 spells).
- Exempt all of family 21: family 21 is not Witch Hunter only. The Witch Doctor's Voodoo Arrow 503715 is family 21
  too, and the no-cross-class rule forbids changing it (mentor D-157).
- Exempt the nine Darkslayer ids only (variant B): Heartseeking Bolt keeps 3500 ms.
- One shared `SpellInfo` predicate used by both sites: it touches `SpellInfo.h` and changes the stream for Tinker and
  Artificer too, beyond the card.

## Decision

Variant A, keyed on the 16 spells (D-157). `SpellInfo.cpp` gains `witchHunterShot` next to the Artificer and Tinker
exemptions, in the Tinker form: family 21 and first rank 804179 (Darkslayer, nine ranks) or 805754 (Heartseeking
Bolt, seven ranks), both chained in `spell_ranks`. `AscensionCompat.cpp` `ApplyServerSpellSelectors` skips the same
spells, and the nine Darkslayer
ids leave `RANGED_PREPARATION_CLIENT_SPELLS` (28 ids to 19). The other 19 ids (Witch Doctor, Barbarian, Incendiary
Shot) keep their rows.

## Consequences

- With Auto Shot's +15% ranged attack speed (ADR 0006), each truncated to int32 as the engine does: Darkslayer rank 1
  1500 / 1.15 = 1304 ms, rank 2 2000 / 1.15 = 1739 ms, ranks 3-9 2500 / 1.15 = 2173 ms, Heartseeking Bolt
  3000 / 1.15 = 2608 ms. The client's own rows (no streamed row) and the server agree.
- Heavy Crossbows 503681 (+500 ms on Darkslayer) reads 1304 -> 1739 ms, a gain of 435 ms (500 / 1.15 after the two
  truncations); Darkhunter 503669's control reads 1304 ms.
- `witch-hunter-darkslayer-client-cast-time-11409.json` now asserts no streamed row, the server cast times above and
  a family-18 control (Throw Weapon 804136 keeps the preparation and its 2500 ms row).
- This is a core change for one CoA family; the PR names `SpellInfo.cpp` `CalcCastTime`.
- Counted pair 20261115-194308 / 20261115-194358 (worldserver sha256 34348eaf6a0d): the #11409 scenario passes in
  both runs; `503681 behaviour_metric_delta darkslayer_cast_time` ok 435 / 435, `503669 ... darkslayer_instant` ok 0.
- The generated passive probe `503681 e1 spell_cast_time_ms 681203` alerts at +435 against +500: its `add` model
  ignores the ranged haste applied after the modifier. A tool question, not a server defect.
- Voodoo Arrow 503715 (Witch Doctor, family 21) keeps the preparation: the #6973 scenario still reads 1000 ms.
  A first family-wide version changed it to 500 ms; D-157 narrowed the exemption to the 16 Witch Hunter spells.
