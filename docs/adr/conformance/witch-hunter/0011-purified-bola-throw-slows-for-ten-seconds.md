# 0011. Purified Bola Throw slows for ten seconds

- Status: accepted
- Date: 2026-11-15

## Context

Purified Bola 707230 reads: "Your Bola Throw now has 2 charges, deals additional damage, and lasts 2 additional sec,
but now costs 10 Rage instead of mana." Learning it replaces Bola Throw with Purified Bola Throw 803333. Spell.dbc
803333 carries DurationIndex 31 (8000 ms), the same index as every base Bola Throw rank (500093, 501337-501343), so the
counted pair 20261115-204520 / 20261115-204601 measured an 8 s slow with and without the talent.

Owner ruling O-25 (Q-wh-18, option b; mentor D-169, D-171): Purified Bola Throw's slow lasts 10 s with the talent, 8 s
without. The client renders the 803333 text's `$d` from its own DurationIndex 31, as "8 sec".

## Options

- Rewrite 803333's duration to SpellDuration 1 (10000 ms) in Witch Hunter code, guarded on DurationIndex 31 and its
  8000 ms, and stream the 803333 text with "10 sec" in place of `$d`.
- Lengthen only the slow (effect 0) and keep the aura 271 effect 2 at 8 s: a second aura or a removal script; effect 2
  amounts to 0% (BasePoints -1, DieSides 1), so the split adds code for no observable change.
- A Spell.dbc edit: outside the class layer and not shipped to the client.

## Decision

The first option, in `ApplyContracts` (`AscensionWitchHunterCompletion.cpp`), with the text in
`rev_20261115_20_witch_hunter_purified_bola_throw_text.sql` (basis owner_ruling). SpellDuration 1 is already used by
the Witch Hunter, Felsworn and Necromancer layers. The base Bola Throw ranks keep DurationIndex 31.

## Consequences

- With Purified Bola, the slow and the 0% aura 271 effect last 10 s; the hit damage is unchanged.
- Without the talent, Bola Throw still slows for 8 s.
- If the DBC row of 803333 ever changes, the guard leaves it untouched and the 803333 slow_held and slow_ends
  regressions fail.
- The 803333 tooltip reads "for 10 sec." from the streamed row; base Bola Throw keeps "for 8 sec".
