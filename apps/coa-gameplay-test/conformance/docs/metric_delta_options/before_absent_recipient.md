# Before absent recipient (`metric_delta` `before_absent_recipient`, ADR 0860)

`before_absent_recipient` is `true`, on a `spell_heal_total` or `spell_energize_total` read whose `fields` set
`target` and `target_pet` true, with `setup_only_after`. The recipient entry is the single `SUMMON_PET` (56)
`EffectMiscValue` among `setup_casts`. The before read is replaced by `owned_creature_count` of that entry
(`<spell> before_absent_recipient count`), and the assert `<spell> before_absent_recipient present` (exactly one owned
recipient) precedes the after read. The before value is 0 only when the count reads 0; a count above 0 is `alert`, a
missing count is `unmeasured`.

Named points: `check`, `fixtures`, `model`, `run_values`, `verdict`.

Witch Hunter: Houndmaster's Whistle 801343 `hound_heal_share` (574335 on the Shadowhound 50124, claim 312.0).
