# 0018. Dead and Gone reduces the cooldown of Pavise only

- Status: accepted
- Date: 2026-11-16

## Context

Dead and Gone 705524 reads: "Your Bolt and Dash now affects an additional use of a Heartseeking Bolt. Your Pavise now
lasts $/1000;s2 additional sec and has a $/1000;s3 sec reduced cooldown." (Spell.dbc server set, Description[enUS];
s2 = 2 sec, s3 = 30 sec).

Its Effect[2] is aura 107 SPELL_AURA_ADD_FLAT_MODIFIER, EffectMiscValue 11 SPELLMOD_COOLDOWN, EffectBasePoints -30001
(-30000 ms), on EffectSpellClassMask (16777216, 1073741824, 0). In family 21 that mask selects ten spells: Bolt and
Dash 520670 and Quickdraw 680244 (SpellFamilyFlags[0] 16777216), Pavise 520865 and the seven Smite Evil ranks
802004, 803359-803364 (SpellFamilyFlags[1] 1073741824). Only Pavise (RecoveryTime 90000) and Bolt and Dash
(RecoveryTime 45000) have a cooldown; Quickdraw and Smite Evil have RecoveryTime 0 and CategoryRecoveryTime 0, and
`Player::AddSpellAndCategoryCooldowns` applies SPELLMOD_COOLDOWN only to a positive recovery
(`Player.cpp:11815-11821`).

Measured (counted pair 20261116-193316 / 20261116-193354, server commit aefe9600a46e, build id 6f3deaea8776): Pavise
90 s -> 60 s and Bolt and Dash 45 s -> 15 s with 705524; Quickdraw and Smite Evil 0 in both arms. The server DBC
equals the client set for 705524; no fork edit of the mask was found; the archived combat logs hold no Bolt and Dash
or Pavise event.

The owner chose option (b) on card Q-wh-23 (O-34): restrict the 30 s reduction to Pavise, as the tooltip says, in
Witch Hunter code, no engine file. Mentor D-337 set the route; mentor D-341 chose (b2) below.

## Options

- (a) No change: Bolt and Dash keeps the undocumented -30 s.
- (b) Restrict the Effect[2] modifier to Pavise 520865 in Witch Hunter code (chosen by the owner).
- (c) Keep the reach and complete the client text.

Within (b):
- (b1) An AuraScript on 705524 whose DoEffectCalcSpellMod handler on EFFECT_2 sets the modifier's `targetSpellId`
  to 520865: a check by spell id, as `aura_ascension_tinker_hacking` does. Needs one `spell_script_names` row.
- (b2) Narrow 705524 Effect[2].SpellClassMask to flag96(0, 1073741824, 0) in `ApplyContracts`
  (`AscensionWitchHunterCompletion.cpp`), as the Guardbreaker 681493 contract does. No SQL.

## Decision

Option (b), route (b2) (mentor D-341): in `AscensionWitchHunter::ApplyContracts`, 705524 Effect[2] takes the class
mask (0, 1073741824, 0) when it is aura 107, SPELLMOD_COOLDOWN, on the DBC mask (16777216, 1073741824, 0); a changed
record is left as is. Effect[0] and Effect[1] are not touched. No SQL, no DBC edit, no engine file, no other class.
This departs from the client-data mask by owner ruling O-34.

## Consequences

- Pavise: 90 s -> 60 s with Dead and Gone, unchanged.
- Bolt and Dash: 45 s with or without Dead and Gone (was 15 s with it).
- Quickdraw no longer carries the reduction. It has no cooldown before or after.
- Limit of (b2): the mask is a family-flag check, not an id check. The seven Smite Evil ranks share the Pavise bit
  SpellFamilyFlags[1] 1073741824 and stay selected; they have no cooldown today, so the reduction is inert on them.
  A future cooldown on a Smite Evil rank would take the 30 s reduction.
- Effect[0] (+1 charge, Bolt and Dash) and Effect[1] (+2 s, Pavise) keep their DBC masks; Effect[0] also selects
  Quickdraw and Effect[1] also selects Smite Evil, recorded as an observation, not changed.
- Regressions: `705524 behaviour_metric_delta` labels pavise_cooldown (60000 against 90000), bolt_dash_cooldown
  (45000 in both arms), quickdraw_cooldown and smite_evil_cooldown (0 in both arms, with the cast-count proofs
  quickdraw_cast and smite_evil_cast), and the unchanged 271.0 (pavise_base / pavise_ext, +2 s, Effect[1]) and 270.0
  (bolt_dash_charges, bolt_dash_second_use, Effect[0] still selecting Bolt and Dash).
