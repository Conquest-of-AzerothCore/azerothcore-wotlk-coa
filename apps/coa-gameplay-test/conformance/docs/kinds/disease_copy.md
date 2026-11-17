# Disease copies (`behaviour_metric_delta`, `kind: "disease_copy"`, ADR 0622)

A snapshot ability that refreshes the caster's diseases on one enemy and copies them onto another (Virulency 801938,
then Infest 803781) is read on three dummies: `disease` is cast at `extra1` (the source), its amount and remaining
duration read, then the entry's `spell` at `extra1`, and the source's duration read again (the refresh). The caster's
spell power is then raised through `power_aura` (`[aura, effect, amount]`, an aura amount fixture), and
`copy_wait_ms` later `infest` is cast at the primary dummy. The copy's presence, amount and duration, and the
source's duration, are read 300 ms later, game-time stamped; a fresh `disease` at `extra2` is the control.

Verdict: `ok` when the source was refreshed to `duration_ms` (G-19 band), the copy is present, its amount equals the
source's amount from before the raise, and its duration equals `duration_ms` less the stamped time since the Infest
(band); `alert` otherwise. `unmeasured` when the control's amount is not above the source's (the raise did not
separate a kept amount from a recomputed one) or when the time between the copy and the Infest falls inside the band
(a kept duration and a source-following one would read alike). The model metric `disease_copy` is an event.

Fields: `disease`, `infest`, `duration_ms`, `power_aura`, optional `disease_wait_ms` (1600), `copy_wait_ms` (4400),
`mana` (1373, set before each cast) and `label_suffix` (`copy`).
