# Trigger reset after setup (`metric_delta` `trigger_reset_after_setup`, ADR 0670)

`trigger_reset_after_setup` is `true` or absent. Each phase clears `trigger_spell`'s cooldown right before its setup
casts (built in); with the option it also clears it again after the last setup cast, through the named point
`setup_cast_steps`, so a setup cast that shares the trigger's cooldown (the same spell, a rank or a spell of its
category) does not refuse the trigger cast. It needs `setup_casts`, a cast trigger (no `trigger_item`) and no
`attack_swings`. The global cooldown is not cleared: `setup_wait_ms` must cover it. `fixtures` names the reset in the
contract.

Witch Hunter: Fiery Judgement 803369 `flames_extension` (a setup Fiery Judgement grants Flames of Sin 803422, the
trigger Fiery Judgement extends it by 3000 ms; the ranks share category 1052).
