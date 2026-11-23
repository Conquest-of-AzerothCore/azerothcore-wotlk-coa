# Block extension trials (`behaviour_metric_delta`, `kind: "block_extension_trials"`, ADR 1216, provisional)

Whether a block taken while an aura is on extends it by the stated time. `shield` is equipped with Block 107, `aura`
and `spell` learned. Each of `trials` trials removes `aura`, casts it on the caster (power `cast_power`, cooldown
reset), sets `set_combat_avoidance` with `block: 100` and dodge and parry at 0 (owner ruling O-20) and has a passive
striker (react state 0) cast `strike_spell` at the caster once. One strike per application: an extension casts nothing, so on an
application hit several times the number of extensions, and so the expected expiry, is unknown.

After the strike the blocked and unblocked hit counts are read, then the aura's presence with game-time stamps
(`game_time_ms`) at eight offsets from the cast: on both sides of the base band (`DurationIndex` of `aura`, +-10%)
and on both sides of the extended band (base + `extension_spell` Effect[`extension_effect`], +-10%). The stamps
bracket the expiry.

Judge, per trial: a strike that does not raise the cumulative counts by exactly one blocked hit and no unblocked
hit, or a cast that left no aura, voids the trial. A
bracket inside the base band is a plain trial, inside the extended band an extended trial; a bracket outside both
bands, or an aura back after it was gone, alerts; a bracket straddling a band edge is unmeasured. The verdict alerts
on any alerting trial, is unmeasured on any unmeasured trial or when no trial was extended, and is ok otherwise. The
share of extended trials and its 99% Wilson interval are reported and never judged. `void_on_cast_failure: true`
makes a run with a refused cast unmeasured.

Sun Cleric: Sunflare Aegis 707629 on Hammer of Kings 804751 (12000 ms; 712469 Effect[0] 4000 ms), 24 trials, Speed
Slash 2118233 strikes, shield 231296.

## `block: 0` (zero arm, opt-in)

`block: 0` forces the block chance to 0 and inverts the strike condition: a trial is void unless its strike is one
unblocked hit (a strike blocked anyway, about 4% with the shield on, is void and never a failure). Each judged trial
must expire in the base band; an extended expiry alerts, and fewer than 24 judged trials is unmeasured (a 30%
extension of every unblocked strike escapes 24 judged trials with probability 0.7^24 = 1.9e-4). Needs at least 24
`trials`. Sun Cleric 284 uses 32.

## `mode: "grant"` (ADR 1216 addendum, D-230)

Whether a strike grants `aura` at all, and how often. No cast: per trial `aura` is removed and read absent, block is
forced to `block` (0 or 100), a passive striker casts `strike_spell` once, the blocked and unblocked counts are
read (differenced against the previous trial) and then the aura. A trial whose strike is not as forced, or whose aura
was on before the strike, is void. Keys: `trials` (per part), `parts` (pooled scenarios, as `aura_keep_rate`),
`control_trials` (per part, before `spell` is learned: none may show the aura), `block`, and for a rate `chance_pct`
with `half_width_points`. Nine steps per trial; a scenario holds at most 10000 steps.

Without `chance_pct` (block 0): no judged trial may show the aura, fewer than 24 judged trials is unmeasured. With it
(block 100): judged trials must reach ceil(z^2 p(1-p) / h^2) (5444 for 30% and 1.6 points), and the share must lie in
`chance_pct` +- `half_width_points`, else alert (a finding). The 99% Wilson interval is reported. The residual of a
conformant server leaving the range is erfc(z / sqrt 2) = 1.0% per run, about 1e-4 when both runs of a pair must agree.

### Granted duration (`duration_spell`, ADR 1242, provisional)

Opt-in on `mode: "grant"` at `block: 100`, without `chance_pct`, `control_trials` or `parts`: keys `duration_spell`,
`duration_effect`, `min_granted` and `residual_target`. The expected duration is `duration_spell`
Effect[`duration_effect`] from the DBC. Each trial reads `game_time_ms` right before and right after the strike and the
aura with game-time stamps at 0.93 and 1.07 times the duration after the strike. A trial whose strike granted the aura
is judged when the read ages (bounded by the two strike stamps) lie in 0.905..0.965 and 1.035..1.095 times the duration
(ADR 1221's window shares, both inside +-10%); otherwise it is void, as is a trial with no grant or a strike not
blocked once. A judged trial must show the aura on at the first read and gone at the second, else alert; fewer than
`min_granted` judged trials is unmeasured. `trials` must reach the count at which fewer than `min_granted` grants come
with probability at most `residual_target` per pair (two runs) at the talent's `ProcChance`.

Sun Cleric: Sunflare Aegis 707629 `block_grant_duration`, 712448 Effect[0] 4000 ms, 47 trials, at least 5 judged
(7.9e-4 per pair at 30%).
