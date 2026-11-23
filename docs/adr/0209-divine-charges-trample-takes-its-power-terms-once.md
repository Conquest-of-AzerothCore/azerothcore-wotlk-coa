# 0209. Divine Charge's trample takes its attack and spell power terms once

- Status: accepted
- Date: 2026-11-12

## Context

Divine Charge 527023, claim 102: "... causing them to trample nearby enemies for
${$527270m3+$527270ppl3+$AP*.2+$sph*.4} Holy Damage every $527270t3 sec for $d." The trample is 527269, cast at each
nearby enemy by 527270's Effect[2] tick (AscensionTemplarAuras.cpp:179-191). Its Effect[0] value is set to
Amount(527270, 2) (AscensionTemplarContracts.cpp:331-332), which is SpellEffectInfo::CalcValue of 527270's Effect[2].
That CalcValue already passes through the same hook, which adds 527270's TemplarCoefficients row
(AscensionTemplarData.h:44 before this change, :43 after it; 0.2 AP + 0.4 SP). 527269's own row
(AscensionTemplarData.h:43 before this change, the same terms) then added them a second time.

Measured before the fix (counted pair 20261112-021809 / -021850, AP 313, spell power 0): 171.6 / 172.1 per
non-critical hit. Engine arithmetic: 65 + floor(1.35 x 40) = 119, plus 0.2 x 313 = 181.6, truncated to 181; -20%
(887007) gives 144; the dummy's partial resists (mean 0.88) give 127.15. With the term twice, 181 + 62.6 = 243.6,
truncated to 243 (or 244 with one truncation), gives 171.15 (171.85). The mentor approved the fix under the four
terms.

## Considered options

1. Drop 527270's Effect[2] row. 527270's own aura amount (read as `527023 effect_value 527270e2`) would lose its AP and
   SP terms.
2. Drop 527269's row. Nothing else reads it: no other spell casts 527269, its SpellFamilyFlags are 0 (no class-mask
   modifier reaches it), it has no other rank, and its spell_bonus_data row is all zeros. Chosen.

## Decision

Remove `{ 527269, 0, 0.2, 0.4, ... }` from TemplarCoefficients. The trample is 527270's Effect[2] value once:
m3 + per level + 0.2 AP + 0.4 SP.

## Consequences

- The trample reads about 127 at the reference stats.
- 527270's own amount, the steed and mount readings of Divine Charge are unchanged.
- Regression: the `527023 script_hit 527269` entry. The control entry `no_power` holds AP and spell power at 0, so the
  base term (119) is read alone.
