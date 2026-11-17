# `stop_shooting_after_ms` (metric_delta option, ADR 1005, provisional)

`"stop_shooting_after_ms": {"ms": N, "dx": D, "spell": S, "target": UNIT}` stops an auto-repeat shot (Auto Shot 75)
after the treatment cast so the aura its first hit starts can expire. The harness `stop_attack` action ends melee only
(`Unit::AttackStop` interrupts `CURRENT_MELEE_SPELL`), so the option moves the caster out of range instead: `N` ms after
the treatment cast of `S` it reads the game time and the logged hit count of `S` at `UNIT`, then moves the caster `D` yd
along x with `relocate` steps of at most 20 yd; Auto Shot's `CheckCast` then fails and no shot fires
(`Unit::_UpdateAutoRepeatSpell`). The hit count is read again right before the after and the expired readings.

The entry uses `gate_timing: "start"`, `trigger_only_after`, `expiry_wait_ms` and `game_time` with an expired window;
`S` is its `trigger_spell`. The before phase, which casts no trigger, repeats the setup casts so the measured creature
exists in both phases. The metric delta's verdict stands, and becomes `unmeasured` when no hit landed before the move,
a hit landed after it, the move came more than `N` + 25 ms of game time after the cast, or a read is missing. The aura
therefore began within `N` + 25 ms of the cast, which the `game_time` windows account for.

Witch Hunter: Defender of Darkshire 705531 ("for $573266d"), `ms` 300, `dx` -40 with the dummy 8 yd away.

Evidence (ADR 1008, provisional): the model names the evidence metric `stop_shooting_attack_time_ms`, a state the
module declares with its promise words `for \$\d*d` (the tooltip's `for $d` duration, merged into
`coverage.metric_evidence()` and `state_promises()` through `metric_delta_options.option_rows`). Coverage's unchanged
`promised_state` counts the verdict as behaviour only for a claim with those words; the haste words alone stay data.
The Witch Hunter expired window is 5375..5495 ms (5475 before ADR 1008): under 5500 ms, so a 10% longer aura still
fails, given the Auto Shot flight floor:
Bound: the cast stamp is taken two harness ticks before the read (behaviours.py:1752-1754, about 6 ms, more than the 5
ms spare under 5500 ms), so the window top alone does not fail a 5500 ms aura; it fails because the Auto Shot hit
lands at least 125 ms after the cast (projectile flight, Spell.cpp:2474-2476, DBC Speed 40), so the aura cannot start
before that and a 5500 ms aura is still present at any expired reading under 5495 ms.
