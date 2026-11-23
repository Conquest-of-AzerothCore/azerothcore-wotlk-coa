# Minion swing arms (`behaviour_metric_delta`, `kind: "minion_swing_arms"`, ADR 0630)

A minion damage modifier stated as a percent ("increasing their damage dealt by 2% per stack", "increases the damage
the target takes from your Skeletal Warriors by 1%") is read on the same minion's plain swings with and without it. A
real `raise_spell` raises creature `minion_entry` (Summoning Adept and other gates in `learn`); one `command_spell`
sends it onto the dummy. `windows` control and `windows` treatment windows then alternate: each removes `aura`, a
treatment window sets it again at `stacks` (on the caster for `holder: "owner"`, a summon aura that reaches the
minions; on the dummy with the caster as its caster for `holder: "dummy"`), waits `settle_ms`, and counts the minion's
plain melee swings (`pet_melee_plain_damage` and `pet_melee_plain_count`, no crit and no glancing) over `window_ms`.
The aura is read at each window end (`owned_creature_count` with the aura for the owner, `aura_stacks` on the dummy);
an aura missing from a treatment window or present in a control window is unmeasured. The judge takes the per-swing
means of the two arms (the hit ratio judge's per-window sample and 99% interval) against the bonus the DBC states
(`stacks` x the aura effect's BasePoints + DieSides, which `expected` must equal), in the G-19 band. An entry
without a treatment aura is refused: the arms would not differ. `player_spell_power` gives the caster the harness
spell-power fixture, so the minion's attack power dwarfs its weapon roll and the swing spread falls under 1%.
`parts` (ADR 0651) runs the scenario that many times and pools the windows of every part into one per-window sample
per arm; a part with a missing read or an unheld aura makes the label unmeasured and is named.

The verdict stamps the metric `minion_swing_arm_damage`, an event read (this module's `METRIC_EVIDENCE` row).

Necromancer: Rotting Flesh 574138 (573131 at 10 stacks on a Ghoul 50073, claim 147.1) and Fetid Mark 706948 (706949 at
10 stacks on the dummy, a Skeletal Warrior 50065, claim 198.0).
