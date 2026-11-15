# Proc gate interval (`behaviour_metric_delta`, `kind: "proc_gate_interval"`, ADR 0663)

ADR 0663 is a shared draft whose number is provisional and assigned at merge; its class half is Witch Doctor ADR 0002.

An internal cooldown on a proc ("Can only occur once every 0.5 sec."), measured in game time on both sides: a trigger
inside the window gives nothing, the first trigger after it gives the proc. Triggers are events of a harness event
stream (`trigger`: `stream`, `spell`, optional `target`; `spell_damage`, `spell_heal` or `spell_energize`); outputs
are events of an event stream (`output` with `stream`) or of the encounter timeline (`output`: `event` `spawn`,
`cast` or `aura_applied` with `source_entry`). All are stamped by the server's game clock.

Order of one scenario:
- the spells of `learn` and of the casts are learned; a timeline output starts the encounter timeline;
  `forced_talent` gets the forcing fixture of SPELLMOD_CHANCE_OF_SUCCESS +1000% (removed and read gone at the end);
- control: one round of `trigger_casts` (`[spell, target]`, `cast_wait_ms` apart), `control_ms`, and the trigger
  and output counts at its start and end;
- the cause: `talent` learned, then the real `setup_casts`. With setup casts, `cause_auras` (`[aura, cast]`, `[]` for
  a cause that does not lapse) is required: generation refuses a last window read later than the aura's DBC duration
  less 1000 ms after that cast;
- `windows` windows, each with its own round when `window_casts` (default true), `window_ms`, then the counts and
  three game-time reads since the latest cast of `since_spell`: the longest trigger gap, the shortest and the longest
  output interval (`event_interval_min_ms` / `max`, or `timeline_interval_min_ms` / `max` for one window only).

Before every trigger cast, `cast_auras` (`[aura, stacks]`) are set by harness `set_aura` (a precondition fixture for
the trigger, never the subject), `cast_power` sets the power and the cooldown is reset. `fixture` adds player stats.
`dummies` (1 to 11) stand `dummy_step_yd` apart from 3 yd, named `dummy`, `dummy2`, ... A window without casts must
read before the shortest trigger aura ends.

The judge, with the G-19 band b of `gate_ms`:
- a missing count or release read is a missing measurement; the forcing fixture still held, or an output in the
  control, alerts; a control without a trigger is `unmeasured`;
- a window with two outputs or more is judged. Its shortest output interval is an upper bound of the gate; its
  longest output interval less its longest trigger gap is a lower bound, since the trigger before that output was
  refused;
- the shortest output interval below `gate_ms - b` alerts (a proc inside the window); the lower bound above
  `gate_ms + b` alerts (a trigger refused after the window);
- otherwise every judged window's longest trigger gap must lie below `gate_ms - b` (a trigger inside every window),
  with at least two output intervals and at least one refused trigger, else `unmeasured`;
- the gate then lies in the bracket (largest lower bound, smallest shortest interval]. `ok` needs the whole bracket
  inside `gate_ms` +- b: lower bound at least `gate_ms - b` and shortest interval at most `gate_ms + b`. A bracket that
  reaches outside the band is `unmeasured`, and the explanation states it.
- `amount_pct` (a leech share of the trigger amount): a mean trigger amount whose share is below 1 is `unmeasured`,
  since a proc that rounds to nothing still starts the gate and reads as a refused trigger.

Resolution, on both sides: on a regular trigger grid of gap g, every window alike gives a bracket g wide, so a gate
shorter or longer than stated by less than one trigger gap reads the same and is `unmeasured`, not `ok`. A bracket
narrower than g comes only when the stated gate sits on the grid and edge timing splits the windows: one trigger on
the gate edge is refused (the next output one gap later) and another is accepted. Then the lower bound and the
shortest interval meet at the stated gate. With triggers at most 2b apart, the bracket is at most 2b wide and can
close inside the band without a split. On a wider grid without a split, the entry stays `unmeasured`, and the clause
stays data conformant (G-19, ADR 0135).

Witch Doctor: Ingredient: Bloodthistle 801664 (Potion leech 803287 on Spirit Eclipse hits, 500 ms), Hexfire Mass
807450 (Serpent Ward 50587 spawns on Hex of Malice ticks, 3000 ms).
