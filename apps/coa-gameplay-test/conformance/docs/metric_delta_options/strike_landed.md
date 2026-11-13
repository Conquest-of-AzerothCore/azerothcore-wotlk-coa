# Strike landed (`metric_delta` `strike_landed`, ADR 0625)

`strike_landed` is `true`, on an entry whose `strike` hits an owned creature (`owned_entry`). Right after the after
reading, the scenario counts the damage logs (SMSG_SPELLNONMELEEDAMAGELOG, `spell_log_count` with `caster` the
striker) of the strike spell. A strike that misses or is dodged, parried or blocked logs none, so a run with no log is
`unmeasured`: the reading is not the effect. With at least one log the verdict is the plain `metric_delta` verdict.

Named point: `verdict(verdict, run, value)`, called by `metric_delta_options.option_verdict` after the forced-chance
and plain judge of a behaviour `metric_delta`; `fixtures` adds the read.

Necromancer: Ghoul Mastery 503740 `snare_control` and `frenzied_snare_immune` (Hamstring 1715, whose Effect[1]
SCHOOL_DAMAGE logs a landed strike even when the Frenzied Ghoul refuses the snare aura; claim 389.0).
