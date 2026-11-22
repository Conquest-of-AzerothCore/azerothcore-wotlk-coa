# Block extension trials (`behaviour_metric_delta`, `kind: "block_extension_trials"`, ADR 1047, provisional)

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
Slash 2118233 strikes, shield 231296. Its zero arm is a `metric_delta` entry with `caster_avoidance` block 0.
