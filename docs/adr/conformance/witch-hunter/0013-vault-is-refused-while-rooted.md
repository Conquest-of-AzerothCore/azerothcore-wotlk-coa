# 0013. Vault is refused while rooted

- Status: accepted
- Date: 2026-11-16

## Context

Vault 500085 reads: "Dash in the direction you are moving[...]. Distance scales with movement speed. Not usable
while rooted." (Spell.dbc server set, Description[enUS]). `witch_hunter_casts::OnSpellCheckCast` in
`AscensionWitchHunterAbilities.cpp` refused Vault with SPELL_FAILED_ROOTED (103) while the caster had
UNIT_STATE_ROOT, but only after `if (spell->IsTriggered()) return;`. Vault carries
SPELL_ATTR4_ALLOW_CAST_WHILE_CASTING (AttributesEx4 128), so the Spell constructor adds
TRIGGERED_IGNORE_CAST_IN_PROGRESS and TRIGGERED_CAST_DIRECTLY (`Spell.cpp:641-642`) and `IsTriggered()` is true for
every player cast of Vault: the root check never ran. No stock check refuses Vault while rooted (its dash is
scripted in `After()` through `LeapVault`). The c12 regression (Entangling Roots 339 or Frost Nova 122 on the
caster, then a real Vault cast) read 0 where the tooltip gives 103.

Mentor ruling D-202: build the fix, Witch Hunter code only, no SQL.

## Options

- Move the Vault root check above the triggered return, gated by `SubmittedByPlayer` (no TRIGGERED_IGNORE_GCD),
  as the Sixfold Shot gate already is.
- Narrow the triggered return to exclude the two implicit flags: changes every later check in the function at once.
- Refuse rooted casts in `Spell::CheckCast` for ATTR4 spells: an engine change for every class.

## Decision

The first option. The Vault check sits before `IsTriggered()`, returns SPELL_FAILED_ROOTED for a player-submitted
Vault while the caster has UNIT_STATE_ROOT, and the unreachable copy after the triggered return is removed. The
other checks after the triggered return are unchanged: none of their spells carries an implicit triggered flag.

## Consequences

- A rooted player's Vault is refused with 103; an unrooted Vault, and a Vault cast while another spell is being
  cast, go through as before.
- A Vault cast by a script with TRIGGERED_IGNORE_GCD (a triggered cast) is not refused by the root check.
- Regressions: `500085 behaviour_metric_delta rooted` (103 after, 0 before), `500085 behaviour_metric_delta
  unrooted` (one Vault cast), `500085 behaviour_metric_delta while_casting` (one Vault cast during a Darkslayer
  804179 cast) with its precondition `500085 behaviour_metric_delta while_casting_darkslayer`.
