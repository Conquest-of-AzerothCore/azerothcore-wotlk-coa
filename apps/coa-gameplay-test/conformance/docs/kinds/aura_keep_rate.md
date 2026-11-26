# Aura keep rate (`behaviour_metric_delta`, `kind: "aura_keep_rate"`, ADR 0672, provisional)

The chance that a consumable aura survives the cast that consumes it. `aura` is set on the caster by harness
`set_aura` (a precondition fixture) before every cast and read on the caster after it (`aura`), with the cast's
`cast_failure` beside it; a failed cast is no trial. Control: `control_trials` casts of `control_spell`, outside the
consumer's class mask, with `control_auras` set before each (a cost fixture), must keep the aura every time.
Treatment: `trials` casts of `consumer` keep it with `chance_pct`. `learn` spells are learned first; `off_hand_item`
(an entry of the class file's `off_hand_weapons`) is equipped for a consumer that needs an off-hand weapon. `parts`
copies are pooled; the kept share is judged as a proc rate (Wilson 99% interval inside the G-20 band of
`chance_pct`), below `procs.band_trials_needed` as G-20 step 1 (`insufficient_trials`, interval stated). The contract
states the casts, the band's need and, when sized, the residual failure probability of a conformant server per run.

`aura_stacks` (default 1, ADR 1278) sets `aura` at that many stacks before every cast of both arms, for a consumer
that costs more than one stack (a consumer's `CasterAuraSpell` is already set by its cast step). Felsworn: Infernal
Doom 804219 "Ruin now has a $s1% chance not to consume Felfury" (Felfury 800058 at 2 stacks before every Ruin 501298,
control Twin Slice 801901).

No server mutant reaches the rate: the roll is a script constant (`roll_chance_i`), which no spell modifier changes;
the seeded tests alert on a consumed control and on a rate far off the band.

Witch Hunter: Lightbringer 680538 "This effect has a 25% chance to not be consumed by Purifier's Edge" (680539,
Purifier's Edge 802434, control Fiery Judgement 803369).
