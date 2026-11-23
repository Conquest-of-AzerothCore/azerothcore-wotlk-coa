# Move under aura (`behaviour_metric_delta`, `kind: "move_under_aura"`, ADR 1198)

"While under the effects of Sunstorm, you can move": a real movement step, read on the position. The caster is
teleported to a fixed point (map 1, 2389.03 / -6608.37 / 125.192). In the control phase, without the aura, the
existing `client_packet` action sends `MSG_MOVE_START_FORWARD` to `step_yd` (default 2) further along x and then
`MSG_MOVE_STOP`, both with `consumed: false` so they reach the session's movement handler; `position_x` and the aura
are read at the start, after the move and after the stop. `spell` is then learned and cast at the caster, and the
same move is sent while `aura` (default `spell`) is held.

The verdict is `unmeasured` when the control did not move the player by the step (the packet would not prove
anything) or when the aura was not held before the move; `ok` when under the aura the player moved by the step within
0.1 yd and the aura stayed through the move and the stop; `alert` otherwise. The derived metric
`move_under_aura_moved` is an event: the movement handler acting on the request.

Sun Cleric: Sunstorm 760379 (mentor D-171, no harness action).

`expect: "blocked"` (opt-in, default `"moved"`; ADR 1264, mentor D-74) judges a sentence that says the caster cannot
move: the same control phase must move the full step, the aura must come from the real cast of `spell` (never
`set_aura`), and under the held aura the same own-movement attempt must leave the position within 0.1 yd of where it
was. The verdict names the attempt (own forward movement through the movement handler). Its derived metric
`move_under_aura_blocked` is an event as well. Felsworn: Illidan's Guile 806109 "you cannot attack, move or cast
spells" (the `move` part).
