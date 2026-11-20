# 0083. Undead stances use the normal global cooldown

- Status: accepted
- Date: 2026-11-18

## Context

Issue #12524: after a stance change the next stance stays unavailable for about 1.5 s beyond the global cooldown.
Undead: Assault 500982, Undead: Pacify 500983 and 504692, and Undead: Protect 500985 and 504902 carry
StartRecoveryCategory 222 and StartRecoveryTime 3000 in the server DBC set (Category 48, RecoveryTime and
CategoryRecoveryTime 0). Spell::TriggerGlobalCooldown clamps the global cooldown to 1000-1500 ms only when
StartRecoveryTime already lies in that range, so 3000 is kept for category 222 and Spell::CheckCast refuses the next
stance with SPELL_FAILED_NOT_READY (67) for 3 s. No code or SQL changed these fields; the values are native.

Live logs (coa-log-history, May-August 2026): of 182 consecutive stance casts by one caster less than 30 s apart,
the fastest gap is 1.528 s and about 30 are below 3 s, over several players.

## Owner ruling (2026-11-18)

The stances use the normal 1.5 s global cooldown.

## Considered options

1. Keep 3000 ms. Rejected: live allowed stance changes 1.5 s apart.
2. Set StartRecoveryTime 1500 for the stance ids and keep category 222. Chosen: the stances keep their own category,
   and 1500 enters the stock clamp, so global cooldown modifiers apply as to any 1.5 s spell.

## Decision

`ApplyContracts` sets StartRecoveryTime 1500 on 500982, 500983, 500985, 504692 and 504902. Undead: Focus 808032 is a
passive and is not changed.

## Consequences

- A stance can follow another 1.5 s later; inside 1.5 s it is still refused with 67.
- Regression (class file): `stance_gcd_ready` (Protect 1600 ms after Assault: no cast failure) and `stance_gcd_held`
  (Protect 1000 ms after Assault: 67).
- The client DBC still carries 3000 for category 222; whether the client shows or enforces its own lockout is not
  verified (client lab check).
