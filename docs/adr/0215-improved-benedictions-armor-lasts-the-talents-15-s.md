# 0215. Improved Benediction's armor lasts the talent's 15 s

- Status: accepted
- Date: 2026-11-12
- Fix note: FN-r2b-1 (claim 197), approved by the mentor with conditions (method-study/owner-rulings-2026-11-10.md)

## Context

Improved Benediction 705287: "Benediction now grants your target armor based on your Agility and Stamina for
$/1000;s1 sec" ($s1 = 15000). On build 861e0e1e6bee the armor aura 801409 lasted 30 s: the counted pair
20261112-015203 / -015316 read 29997 ms right after a Benediction 578276 at the grouped ally and the aura present
15375-15500 ms after the cast.

- 801409's raw Spell.dbc DurationIndex is 0 (no SpellDuration entry, so SpellInfo::GetDuration is 0).
- ApplyContracts gave it DurationEntry 8 (15000 ms) (AscensionTemplarContracts.cpp, `id == 801409`).
- 705287 Effect[0] (aura 107 SPELLMOD_DURATION, BasePoints 14999 + DieSides 1 = +15000, EffectSpellClassMask word 2
  bit 131072) adds 15000 ms in Aura::CalcMaxDuration (SpellAuras.cpp:818-819).
- The mask reaches no other spell: of every Spell.dbc record of SpellFamilyName 25, only 801409 carries
  SpellFamilyFlags[2] bit 131072.
- Without the talent, the Benediction Launch hook prevents 801409 (AscensionTemplarAbilities.cpp:396-404), so the
  contract's 15 s base only ever applied together with the +15 s.

## Options

1. Option (ii) of the approval: drop the +15000 modifier's effect on 801409 and keep the contract.
2. Remove the contract's duration override: the raw 0 ms plus the +15000 modifier gives 15000 ms.

## Decision

Option 2, the case the approval names for a raw duration that already reaches 15 s with the modifier: the
`id == 801409` DurationEntry override is removed from ApplyContracts. The modifier is unchanged and keeps acting on
everything its mask covers, which is 801409 alone (other spells: none).

## Consequences

- On build c634e1026f90: 801409 reads 14997 ms right after the Benediction (readback within 14500-15000) and its expiry
  pair ends after 14625 and by 15500 ms; the armor gains are unchanged (0, 211, 241, 274).
- Regression: `705287 behaviour_cast_applies_aura armor` and `705287 behaviour_expiry armor`.
- A cast of 801409 by anything other than a Templar holding 705287 would now last 0 ms; no such path exists (the
  Launch hook prevents it without the talent).
