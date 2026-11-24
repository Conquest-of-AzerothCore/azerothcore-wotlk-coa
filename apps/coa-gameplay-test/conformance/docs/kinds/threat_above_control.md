# Threat above control (`behaviour_metric_delta`, `kind: "threat_above_control"`, ADR 1280, provisional)

A threat claim without a figure ("Generates a large amount of threat.") read as a direction. `hit_spell` and the
control `control_spell` are each cast `samples` times (3 to 5, default 5), alternated, each at its own fresh dummy:
the dummies stand 10 yd apart on one line from 3 yd ahead of the caster, and the caster steps 10 yd along it before
each cast after the first, so each cast reaches only the dummy 3 yd ahead (an area of 3 yd around the caster or a cone
of 8 yd leaves the next dummy 13 yd ahead and the previous one 7 yd behind). Each cast reads the dummy's health and its
threat on the caster before and after, and the caster's `cast_failure`; `settle_ms` lengthens the wait for a delayed
hit.

A sample is the threat gained over the health lost, with no flat amount removed. Judge (label
`<spell> behaviour_metric_delta <label_suffix>`, metric `threat`, contrast `own_cast`, so a state read that counts as
behaviour when the clause promises "threat"): `ok` when the lowest `hit_spell` sample lies strictly above the highest
control sample, `alert` otherwise (an equal or overlapping sample alerts); `unmeasured` on a failed cast or a sample
without health lost; a missing read is not judged. No amount is asserted.

Refused: `samples` outside 3 to 5 (two dummies per sample under the harness creature cap and its 100 yd placement), a
control equal to `hit_spell`, a negative `settle_ms`.

Felsworn: Fel Torpedo 500610 `threat_above_control` (hit 500761 against Carve's strike 803715, mentor D-106).
