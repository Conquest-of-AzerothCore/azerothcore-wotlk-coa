# 0692. A forced crit can be ranged

- Status: proposed
- Date: 2026-11-15

## Context

`values.FORCE_CRIT_RATINGS` mapped `force_crit` to `melee_crit_rating` or `spell_crit_rating`. A ranged weapon shot
(DmgClass 3: Darkslayer 804179, Quickdraw 806851, Heartseeking Bolt 807284) rolls its crit against the ranged crit
field, so neither value forced it. Heartless 680326 and 680327 ("Increases your Physical ranged critical damage by
$s1%.", aura 163 SPELL_AURA_MOD_CRIT_DAMAGE_BONUS, Physical) can only be judged on critical ranged hits. The harness
already applies a `ranged_crit_rating` player fixture through `ApplyRatingMod(CR_CRIT_RANGED, ...)`.

## Options

- A Heartless-only entry with a `fixture` of `ranged_crit_rating`: hit_ratio fixtures exist, but every other kind
  would stay without the route, and the crit filter would not say why the hits crit.
- A third `force_crit` value, `ranged`, in the one dict every kind reads.

## Decision

`FORCE_CRIT_RATINGS['ranged']` is `ranged_crit_rating`. The kinds that read the dict (metric_delta, crit_magnitude,
cast_applies_aura, hit_ratio and the trigger entries) accept it. A metric_delta with auto-attack swings refuses it
(the swings are melee), `taken_hit`'s `striker_force_crit` still refuses it, and `internal_cooldown_gate` keeps its own
dict.

## Consequences

- Tests: `RangedForcedCritTests` (test_behaviours.py); the two older refusal tests that used `ranged` as the unknown
  value now use `wand`; the attack-trigger refusal test keeps `ranged`.
- Entries: `680326 behaviour_hit_ratio crit_damage` (expected 1.25) and `680327 behaviour_hit_ratio crit_damage` (1.5).
- No existing entry uses the value: the finished classes' scenarios are unchanged.
- Number provisional: shared ADRs are numbered at merge.
