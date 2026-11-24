# 0040. Scroll of Hope heals each ally that falls below 35%, once per fall

- Status: accepted (owner ruling O-29, confirmed defect under the tooltip and the ruling, 2026-11-23)
- Date: 2026-11-23

## Context

Scroll of Hope 680646 (server DBC, `/srv/coa/server-data/dbc`): "Read from a scroll of hope, reducing Magic damage
taken by party and raid members within $a1 yds by $s1% for $d. If any ally falls below 35% of their maximum health
while this is active they are instantly healed once for $681383s1% of their maximum health." Aura tooltip: "Magic
damage taken reduced by ${$w1}%. If any ally falls below 35% of their maximum health while this is active they are
instantly healed for $681383s1% of their maximum health." The heal 681383 reads "... they are instantly healed for 15%
of their maximum health."

Data: 680646 Effect[0] and Effect[1] are SPELL_EFFECT_APPLY_AREA_AURA_RAID (radius index 18, 15 yd), aura 87
MOD_DAMAGE_PERCENT_TAKEN and aura 42 PROC_TRIGGER_SPELL 681383; 681383 Effect[0] is SPELL_EFFECT_HEAL_PCT, BasePoints
14 (15%), ImplicitTargetA 1 (TARGET_UNIT_CASTER), TargetAuraState 13. The script is
`aura_ascension_sun_cleric_event` (`rev_20260909_13_sun_cleric_completion.sql`, spell_proc ProcFlags 1048575).

Before this change (`AscensionSunClericEvents.cpp`, both lines from e36bc50aad, `git log -L` shows no later commit):

- the check accepted a received damaging hit while the aura's holder was below 35% and the Aura's script value was
  unset;
- the proc set that script value and cast 681383 as the Cleric (`Cast(player, GetTarget(), 681383)`), so the
  TARGET_UNIT_CASTER heal landed on the Cleric whichever holder fell.

The area aura is one Aura owned by the Cleric with one application per holder (`SpellAuras.cpp`, `_CreateAuraApplication`),
so the script value was shared: the first fall of any holder spent the heal for every holder, and it was never armed
again.

Readings (packet "187 Scroll of Hope", rb1 d224b): trial A (Cleric 9000 of 10000, allies struck from 3800): 681383 heals
the Cleric 1, ally 0, ally2 0; trial B (Cleric 3800, allies 9000): Cleric 1, allies 0.

Owner ruling O-29: the ally that falls below 35% is healed, once per ally; an ally that goes back above 35% is armed
again for its next fall (once per crossing, per ally). The Cleric is not healed for an ally's fall.

## Options

1. Judge each hit as a fall: the holder is below 35% after the hit and was at or above 35% before it (health after the
   hit plus the damage), and have the holder cast 681383 on itself with the Cleric as original caster. No stored state.
2. Keep a per-holder "spent" set in the script and clear it when the holder is seen above 35%. Rejected: the script
   only sees damage taken, so a holder healed above 35% by another spell is seen again only on its next hit, the one
   that may take it below; clearing the set on the health before that hit gives option 1's rule with extra state.
3. Change 681383's implicit target in the DBC or SQL. Rejected: the cast still needs a per-holder once rule, and the
   heal is a class-only spell already cast from the class script.

## Decision

Option 1. The 680646 case of the check reads `HealthBelowPct(35)` after the hit and
`GetHealth() + damage >= CountPctFromMaxHealth(35)` before it; the proc casts 681383 from the holder on itself, triggered,
with the Cleric's GUID as original caster, so the heal is 15% of the holder's maximum health and is credited to the
Cleric (`Spell::EffectHealPct` reads the original caster's healing done, as before when the Cleric cast it). The
script value of 680646 is no longer used.

## Consequences

- Each holder (allies and the Cleric itself) is healed on each fall below 35% while the Scroll is active; a holder
  still below 35% after the heal is not healed again until it has been at or above 35% before a hit.
- Stated edge case 1: a holder already below 35% when the Scroll is cast has not fallen. Hit again while still below,
  it is not healed; it is healed at its next fall, after it has been at or above 35% (tooltip "falls below 35%"). Not
  read in-game.
- Stated edge case 2: the Cleric is a party member and holds the area aura, so its own fall below 35% re-arms and
  triggers its own heal like any ally's (the heal on the Cleric is the Cleric's own fall, never an ally's).
- Readers of the changed lines: only 680646 and 681383, both Sun Cleric spells. 680646 is named elsewhere only in the
  script's aura list (`AscensionSunClericData.h`, `SunClericEvents`, read by `AscensionSunClericContracts.cpp`) and in
  `rev_20260909_13_sun_cleric_completion.sql`; 681383 only in the changed proc. No other class file, fixture or engine
  file names either; no engine file is touched.
- Regression (class file, metric_delta, `void_on_cast_failure`, the uncast before phase as control): heal_each_ally
  (ally and ally2 each healed once, the Cleric not), heal_each_ally_fall_again (two heals per ally over five hits),
  heal_each_fall (the Cleric healed twice over five hits, formerly heal_once at 1500), heal_stays_below (Necrotic Poison
  54121 fixture: one heal while the holder stays below). Existing heal_amount, heal_above, heal_close_above and
  heal_once_hits are unchanged.
- Client text unchanged: the tooltip already says the ally is healed.
- Measured (level 60, `--ram`, `--gameplay-db-workers 4`): before, pre-fix build 4af206be7c8c, pair 20261123-075048 /
  20261123-075409, no flip: heal_each_ally ally 0, ally2 0, Cleric 1; heal_each_fall 1500. After, build 291d19c46d43,
  pair 20261123-075539 / 20261123-075629, no flip, 14 of 14 Scroll of Hope entries ok in both runs: ally 1, ally2 1,
  Cleric 0 (ally health 4876); two heals per ally over five hits (health 4680); heal_each_fall 3000; heal_stays_below 1.
