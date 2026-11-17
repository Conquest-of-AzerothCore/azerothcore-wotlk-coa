# Crit field refresh (`metric_delta` `crit_field_refresh`, ADR 0678)

`crit_field_refresh` is `true` or absent. Through the named point `phase_steps`, each phase first reads
`melee_crit_chance_refreshed` (labels `<spell> crit_field_refresh before|after`), which recomputes the caster's
melee crit field (`Player::UpdateCritPercentage(BASE_ATTACK)`), so the before reading does not take a field left
unset since login while the learn refreshes it for the after reading. It needs the default between-phases learn (no
`setup_only_after`, `gate_timing` `between`, no `attack_swings`). `verdict` makes the reading `unmeasured` when a
refresh read is missing. `fixtures` names the refresh in the contract.

Witch Hunter: Secret Society 680514 `shadow_crit` (`spell_done_crit_chance` of Dusk Blade 802258 at the dummy: the
reference character's melee crit field is 0 before the learn and 2.29 after it, because aura 350's handler
refreshes it on the learn; with the refresh, 2.29 before and 10.29 after, a gain of 8).
