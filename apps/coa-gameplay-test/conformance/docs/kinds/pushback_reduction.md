# Pushback reduction (`behaviour_metric_delta`, `kind: "pushback_reduction"`, ADR 0543)

One scenario casts `cast_spell` at the dummy three times (power set to `cast_power`, cooldown reset): unhit; hit once
by the passive striker's `strike_spell` `strike_at_ms` into the cast; and the same after a real cast of
`reducer_spell` (`reducer_wait_ms` later). The cast start, the moments just before and just after the strike step
and every poll of the caster's `casting` state inside the phase's window (`windows`, `[start, end]` ms after the cast
start, one poll per 1 ms wait step) are read with `game_time_ms`, so each cast end lies between the last casting and
the first idle poll in game time. The judge brackets the reduction 1 - (reduced end - unhit end) / (hit end - unhit
end) from those ends and judges it against `expected_pct` in the G-19 band: `ok` when the whole bracket lies inside,
`alert` when it lies outside, `measured` when it crosses an edge. A hit cast that takes other than one strike, or two
strikes at game-time offsets further apart than the poll bracket, leave the reading `unmeasured` (invalid, not
failed). Icebound Champion 807813: Lichfrost 501978, Light of the Naaru 41394 at 1000 ms, expected 50.
`reducer_learn: true` learns `reducer_spell` between the phases instead of casting it and adds a fourth window, an unhit
cast after the learn (`reduced_unhit`); each pushback is then taken within its own talent state, for a talent that also
changes the cast time (Lich Essence 802988, which shortens Lichfrost by 15%).
`repeats` (ADR 0546) repeats every cast; the judge then takes the mean bracket middle of each kind of cast and a 99%
interval of the reduction from the repeats, since one poll is one world tick (8-10 ms of game time) and a single
bracket cannot be narrower (Lich Essence: 10 repeats, 21-poll windows).
The model stamps its contrast (ADR 0570): `own_cast` when `reducer_spell` is the entry's own spell and is cast,
`learned` with `reducer_learn`, otherwise `condition`; coverage counts the `casting` read as behaviour for the first
two where the clause promises it (`coverage.promised_state`, as ADR 0553 for `metric_delta`).
The verdict names the kind's own state metric `pushback_casting` (ADR 0600), declared in the module with the
`casting` promise words plus `pushback`, so a clause that names only the spell pushback ("reduces your spell
pushback suffered from taking damage") is promised the casting state the kind reads.
