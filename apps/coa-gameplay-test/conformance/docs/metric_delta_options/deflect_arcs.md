# Deflect arcs (`metric_delta` `deflect_arcs`, ADR draft nf-e)

`deflect_arcs` (`{"aura": A, "outside": [dx, dy], "behind": [dx, dy], "settle_ms": W}`) judges a spell deflect held
near a summon. The entry reads the striker's landed `spell_damage_count` at the caster (`fields` `{spell, caster:
"striker", target: "caster"}`, `gate_timing` `start`, `trigger_only_after`, a `strike` with `after_trigger_ms`,
`expected_gain` 0). The control is the before phase: no trigger, the striker in front, every strike lands. After the
trigger and its strikes (the front arm), three arms follow, each reading the aura `A` on the caster and the caster's
orientation and position and the striker's position:

- front: the landed count of the after-trigger strikes;
- outside: the caster moves by `outside` (the striker stays in front), waits `W` ms, the strikes are cast again;
- behind: the caster moves by `behind` so the striker stands behind it, the trigger is cast again there, then the
  strikes.

The base judge reads the front count as its after reading (`run_values`): the gain over the control must be 0
within the entry's tolerance. The option then requires the control and the outside arm to land every strike
(`alert` otherwise) and leaves the entry `unmeasured` when a read is missing, the aura is not held in front, is held
outside, or the striker is not in front of the caster in those two arms. The behind arm is judged like the front
(nf-k): it must land at most the entry's tolerance of its strikes (`alert` otherwise), and the entry is `unmeasured`
when the aura is not held behind or the striker is in front of the caster there. The generated scenario contract
gains a paragraph naming the arms and what each must land.

Two optional keys, inert for entries that do not set them (nf-i):

- `present_entry` (a creature entry): an `owned_creature_count` read of that entry on the caster in the outside arm,
  appended to the explanation as "creature counted in the outside arm: N". It must read 1, or the entry alerts (a
  missing read alerts too, nf-k, review I-2), so the outside arm proves that the summon is still present while the
  caster is out of its radius.
- `owner_question` (a text id): the behind arm is recorded in the explanation and not judged, and the contract
  paragraph says so, pending that owner question. Without the key the behind arm is judged.

The module also holds the one READBACK row of `avoidance_samples` (harness probe 7 counts `SPELL_MISS_DEFLECT`
results of `Unit::MagicSpellHitResult` over 512 samples), the data arm of the deflect type.

Witch Hunter: Pavise 520865 (681453 `pavise_deflect`, aura 1108180, outside `[0, 8]`, behind `[6, -8]`,
`present_entry` 50519). Its behind arm is judged since owner ruling O-47 (card Q-wh-45, every direction; Witch Hunter
ADR 0026).
