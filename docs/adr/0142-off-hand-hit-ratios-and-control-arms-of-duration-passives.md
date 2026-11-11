# 0142. Off-hand hit ratios and control arms of duration passives

- Status: accepted
- Date: 2026-11-11

## Context

The Templar gap batch (`lean/gap-batch-brief.md`) needs a behaviour check with a control arm for six spells the
class map finds no code for, and an off-hand measurement of Zealotry 801450 and Bursting Impact 705276.

- Deep Secrets 705263 and Oath Flow 705283 lengthen another spell's aura. The `cast_applies_aura` expiry pair had one
  arm: an aura that already lasted the longer time without the talent would pass.
- Bursting Impact "Increases your off-hand weapon damage by $s1%" and Blade Sermon's "Weapon Damage dealt by
  Zealotry" depend on the off hand. `hit_ratio` could neither wield an off hand nor observe auto attacks.
- The Zealotry trigger fixture learned Dual Wield 674, although every Templar learns it at login
  (`AscensionLiveBaselineData.h:128`, `lean/templar-offhand-reading.md`).

## Decision

- `cast_applies_aura` takes `control: {"expected_ms", "clear_auras"}`. The expiry scenario casts `cast_spell` once
  before the entry's spell is learned (arm `without`, ending at `control.expected_ms`), removes the named auras,
  resets the cooldown, learns the spell and casts again (arm `with`, ending at `expected_ms`). `label_suffix` names
  the readback and expiry labels.
- `hit_ratio` takes `off_hand_item`, an entry of the new class-file list `off_hand_weapons`: the class file's
  one-handed main hand and that off hand are equipped, with no Dual Wield grant.
- `hit_ratio` takes `swing_hand` with `metric: "melee_damage_total"`: each trial attacks for one swing interval,
  stops, settles 100 ms and reads the plain hits of that hand. A first version that kept attacking through the reads
  paired a count with the next trial's damage when a swing landed between the two reads (`.cache/verify-all/
  20261111-122456`, 19.8-point half-width); stopping removes the race.
- A trigger `dual_wield` may name `known_spell` instead of `spell`: the spell is read with `knows_spell`, not learned,
  before the off-hand equip, which the harness fails when the server refuses it.
- `one_hand_main`, `off_hand_weapon` and `off_hand_steps` move to `profile.py`, shared by triggers and behaviours.
- A passive's P5 `checked by` link names `hit_ratio` entries and suffixed `cast_applies_aura` entries by their
  own labels; the scaffold writes an empty `off_hand_weapons` list.

## Consequences

- Deep Secrets and Oath Flow are judged by two expiry arms; a talent that does not reach the duration alerts.
- Off-hand damage claims can be measured with a control arm, and the Zealotry trigger proves the class's own dual
  wield. Entries without the new fields generate the same scenarios as before.
- The swing mode reads hits of one hand only; a claim on both hands needs one entry per hand.
