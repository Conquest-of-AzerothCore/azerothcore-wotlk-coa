# 0029. Fury Unleashed strikes with both weapons

- Status: accepted (tooltip and archived live evidence; review fw-rf3 I-2, controller t5, 2026-11-24)
- Date: 2026-11-24

## Context

Fury Unleashed 555738, server DBC text: "Spin your glaives for $d, increasing movement speed by $s2% and dealing
$806095s1% Weapon Damage every $t1 sec with both weapons to all nearby enemies." The aura's Effect[0] (aura 23,
1000 ms) triggers the main-hand hit 555739 only; since owner ruling Felsworn O-33 (2026-11-24) (ADR 0027) that hit carries 806095's 200%.

The data holds an off-hand twin, 806097 "Fury Unleashed": Effect[0] SPELL_EFFECT_WEAPON_PERCENT_DAMAGE (BasePoints
149, 150%), Effect[1] SPELL_EFFECT_NORMALIZED_WEAPON_DMG, AttributesEx3 SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON, DmgClass
melee, TARGET_SRC_CASTER / TARGET_UNIT_SRC_AREA_ENEMY at radius index 14, MaxAffectedTargets 8, family 20 flag[2]
0x400000 like 555739. No Spell.dbc effect triggers it and no server code cast it: the server dealt the main-hand half of
the clause only.

Archived live logs (coa-history, 2026-06-06 03:51 and 03:53, one player): 48 hits of 555739 and 46 of 806097 in the
same two logs. Each 555739 hit of a tick is followed 1 to 7 ms later by one 806097 hit on the same target: eight
targets at 03:52:12.405 to .416, then one target every second from 03:56:46.759 to 03:56:51.764. Non-critical hits on
the same target in the same tick read 174 (555739) and 124 to 127 (806097). The gear is unknown, so the logs fix the
event (one off-hand hit per main-hand hit) but not its percent or the off-hand factor.

## Options

- Leave it: the clause's "with both weapons" stays undone.
- Cast 806097 from the aura's periodic handler: the class hook runs before the default trigger, so the off-hand hit
  would land before the main-hand one, against the live order.
- Cast 806097 after each 555739 cast when the caster holds a usable off-hand weapon, at the tooltip's percent.

## Decision

- `felsworn_casts::OnSpellCast` (`AscensionFelswornAbilities.cpp`) casts 806097 on the caster after each 555739 cast
  when `Player::GetWeaponForAttack(OFF_ATTACK, true)` finds a usable weapon. The hook runs after the main hit has been
  handled, the order the live logs show.
- `ApplyContracts` (`AscensionFelswornContracts.cpp`) gives 806097 Effect[0] the BasePoints of 806095 (199, so 200%),
  as for 555739: the tooltip names one percent for both weapons.

## Consequences

- The off-hand hit is an OFF_ATTACK spell (`Spell.cpp:600`): its weapon damage is the off-hand weapon's, under the
  stock off-hand TOTAL_PCT 0.5 (`Unit.cpp:519`). With the reference Slayer set it deals half of the main-hand hit.
- Glaiving 560578 (ADR 0027, SPELLMOD_DAMAGE on family 20 flag[2] 0x400000) also raises 806097, the only other spell
  reading that flag in the server DBC set; its tooltip names Fury Unleashed's damage. Chaos Storm 800211 still triggers
  806095, not 806097.
- Keyed to 555739 and 806097 by id, both Felsworn spells; no other class file, class code or shared data reads them.
  No engine, SQL, DBC or client text change.
- Without an off-hand weapon (Infernal set, a two-hand weapon or an off-hand disarm) nothing changes.
- Regressions: `555738 hit_oh` (forced critical 806097 hit at +20000 attack power, band 6994 to 7024 from the off-hand
  path) and its control `555738 hit_oh_none` (the same cast with the off hand disarmed by 47974: no 806097 hit).

## Live-unconfirmed values (review fw-rf3b I-1, mentor D-96)

- The 200% on the off-hand strike comes from the tooltip token $806095s1 and owner ruling Felsworn O-33 (2026-11-24, Felsworn ADR 0027), not from a live
  measurement; 806097's own data value (150%) is not used.
- The off-hand factor 0.5 is the stock engine's off-hand weapon damage, not a live measurement. The archived live
  logs show an off-hand/main-hand non-crit ratio of about 0.71-0.73 (124-127 against 174; coa-history pairs 120/170
  and 327/445) with unknown gear, so neither the percent nor the factor is confirmed live.
