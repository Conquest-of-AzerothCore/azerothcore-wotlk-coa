# Enemy shooter (`metric_delta` `enemy_shooter`, ADR 1040, provisional)

`enemy_shooter` makes the enemy player of `enemy_player_race` act in the uncast before phase and read what it did
while the trigger was on it. Keys (all required except `power`, `relocate` and `native_refusals`):

- `mode`: `ranged` (an auto-repeat shot such as Auto Shot 75) or `ability` (an instant ability with a cooldown, cast
  again after the trigger).
- `class`: a CoA class, 12 to 32; `weapons`: `[{item, slot}]`; `skills`: skill lines set to 300; `learn`: spells learned
  beside `spell`; `spell`: the spell the enemy casts at the caster.
- `power`: `[type, value]` set on the enemy before each cast; `relocate`: `[dx, dy]` yards, moved before the control
  window (the enemy and the caster start on the same point; a ranged shot needs a line of sight, so the direction is
  stated per entry); `window_ms`: the control window; `distance_yd`: `[least, most]`, the enemy's `distance_2d` to the
  caster, read before the control window.
- `native_refusals`: `[[spell, reason]]` the cast refuses by design, for the ranged mode (Calm on a player refuses its
  own trigger 807778 with reason 27); any other refused cast voids the trial. `source` states the fixture.

The entry targets and measures the `enemy` (`target`, `measure_actor`), has no `cast_in_before`, and states
`expected_gain` (the metric after the trigger less the metric after the control window) with `before_expected` the
least control reading. The control window runs `window_ms` ms with no trigger; the treatment window is the aura read
(1000 ms after the trigger) plus the entry's `wait_ms`, never shorter than `window_ms`.

The verdict is `unmeasured` (a void trial, never `ok` or `alert`) when the control read less than 1, the enemy's
distance is outside `distance_yd`, the trigger aura (`trigger_spell` cast by the caster) is not on the enemy, or a cast
other than `native_refusals` was refused in the ranged mode. In the ability mode a refusal after the trigger is the
effect under test and is not a void.

Sun Cleric: Calm 804057 `shooter_ranged` (Auto Shot of a Witch Hunter enemy) and `shooter_ability` (Justice 572848 of a
Sun Cleric enemy, the positive control).
