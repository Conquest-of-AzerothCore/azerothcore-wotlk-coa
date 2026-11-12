# 0160. Judge a script-cast hit against the tooltip that states it

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0147 (the per-level term truncated before the sum) and ADR 0153 (a hit taken from the damage log)

## Context

Some tooltips state the amount of a hit that a class script casts on an event, not the amount of the spell's own
cast: Disciplined Blows 680397 ("dealing ${$680398m1*$<scalingbp>+$AP*0.05+$AGI*0.2} Holy damage", a pulse cast on a
heal), Pulverizing 524620 ("dealing ${$524619m1*$<scalingbp>+$sph*0.225+$AP*.1} Holy damage", cast on Condemn's
damage) and Armor of Faith 804930 ("inflict ${$801546m1+$801546ppl1+$AP*0.2+$sph*0.5} High Threat Holy damage",
cast when Staffguard's shield breaks). Their checks read the token's value only (data). `hits.hit_parts` models a
rank's own cast or an aura-23 weapon hit; it has no event trigger and reads no other spell's tooltip, and its alerts
on a rank with a fractional per-level term stay "engine computation not modelled".

## Considered options

1. Cast the hit spell directly at the dummy. Rejected: the script's path, which may pass its own values, would not
   be exercised.
2. Add hit reads to the existing trigger, proc and area scenarios. Rejected: it changes existing scenarios.
3. A behaviour kind that sets the event off per trial, without the passive (the control) and with it, and judges
   the mean non-critical hit with the hit judge against the passive's tooltip. Chosen.

## Decision

- `hits.script_hit_model` reads the passive's tooltip with the caster's stats, keeps the hit spell's tokens
  re-indexed to its effects (`triggered_readout`), reads each roll of the hit's die again through that tooltip
  (`rolled_values` with `tooltip_spell`) and applies the known modifiers and mitigation, as `rank_hit` does. When an
  effect of the hit spell has a fractional per-level term, the model also carries an engine model: every per-roll
  value less the truncated fraction, in float, then truncated (SpellInfo.cpp:497).
- `measured_hit_model` uses it for an expectation whose model names a `tooltip_spell`.
- `compare.judge_hit` alerts when the model's `control_label` counts a hit, and judges a mean outside the tooltip
  model against the engine model: inside its 99% interval the verdict is `ok` as known engine rounding, with both
  means in `detail['per_level_rounding']`; outside both it alerts and is not relabelled "not modelled".
- The `script_hit` behaviour kind (`behaviours.script_hit_scenario`) builds the trials: auras, a health fixture,
  casts and an optional striker's strike, `trials` without the passive and `trials` with it, the receiver's armor,
  level and resistances, and the non-critical hit reads on the receiver (the dummy or the striker).
- Players, the dummy and the striker are at level 60.

## Consequences

- Claims 145, 388 and 87 (the damage claim) get a behaviour route; their effect-value reads stay as data labels.
- No existing scenario file changes; two passive expectations (680397, 524620) gain a pointer to the new check in
  their linked explanation, as every new behaviour entry of a spell does.
- The judge's tolerated tier is unchanged: a hit mean within 5% of the model is `tolerated`, as for every hit.
- Tests: `test_hits.ScriptHitTest`.
