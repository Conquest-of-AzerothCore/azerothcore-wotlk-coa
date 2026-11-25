# Weapon damage arms (`metric_delta` `weapon_damage_arms`, ADR 1299, provisional)

ADR 1299 has a provisional number and is renumbered at merge (guide 14.4).

Direction-only judgement for sentences that scale a stat or quantity `"based on your main-hand weapon damage"` with no
stated figure (orchestrator decision D-38, e.g. Cultist Void Power 574147: `"Your healing power is increased based on
your main-hand weapon damage."`).

## Configuration

`weapon_damage_arms` is:

```json
{
  "weapons": [
    {"item": 2092, "source": "Worn Dagger (alternate_weapons, subclass 15, 1600 ms, 1.1607-3.4821)"},
    {"item": 2209, "source": "Kris (alternate_weapons, subclass 15, 1600 ms, 15.36-25.6)"},
    {"item": 2534, "source": "Rondel (weapon_sets.Dreadnought.main_hand, subclass 15, 1600 ms, 28.46-45.46)"}
  ],
  "unrelated": {
    "metric": "combat_rating",
    "fields": {"rating": 17},
    "aura": 10033,
    "stacks": 1,
    "source": "QA Test +100 Haste Rating (aura 189, misc 917504)"
  },
  "wait_ms": 1000
}
```

- **No expected figure is configurable:** `FORBIDS_EXPECTED = True` causes `metric_delta_spec` to refuse `expected` and
  `before_expected`, and `weapon_damage_arms.check` refuses `expected_gain`, `expected_ratio`, `after_at_least`,
  `after_at_most`, `after_expiry_expected` and `phase_power`. `parse` accepts only `{weapons, unrelated, wait_ms}`.
- **At least three distinct same-subclass, equal-speed main-hand weapons:** every item must be declared as a main-hand
  weapon (slot 15) in the class file (`weapon`, `alternate_weapons` or `weapon_sets[*].main_hand`) with integer
  `subclass` and positive integer `speed_ms` metadata. Generation refuses any weapon list whose items differ in
  `subclass` or unhasted base `speed_ms`, eliminating weapon-type and weapon-speed confounding. Missing items and skill
  lines are added and set before the first swap.
- **Equal attack power:** every weapon arm and the unrelated-stat arm read `attack_power` in both the unlearned control
  phase and the learned phase; any attack-power difference across arms voids the verdict as `unmeasured` (preventing
  attack-power confounding).
- **Unrelated-stat control:** re-equips `weapons[0]`, applies `unrelated.aura` (`unrelated.stacks`), verifies the
  unrelated stat rises while `weapon_damage_min` and `attack_power` stay unchanged, and requires the judged output gain
  to match `weapons[0]`.

## Preconditions and judgement

- **Preconditions (`unmeasured` on failure, never `alert`):** every reading present; `equipped_item` (slot 15) equals
  the expected weapon in every arm; `weapon_damage_min` strictly increases across `weapons` (`w[i+1] - w[i] > 0.5`) and
  matches between control and learned (`<= 0.5`); `attack_power` stays equal across every arm in both phases (`<= 0.5`);
  the unrelated stat rises (`> 0.5`, matching between phases) without moving `weapon_damage_min` or `attack_power`.
- **Judgement (`ok` or `alert`):** learned gains `gain[i] = learned[i] - control[i]` strictly rise across all `>= 3`
  weapons (`gain[0] >= -tol` and `gain[i+1] > gain[i] + tol`) AND `abs(gain_unrelated - gain[0]) <= tol`. Asserts no
  slope, ratio or expected figure.

Named points: `FORBIDS_EXPECTED = True`, `parse`, `check`, `fixtures`, `model`, `verdict` (`ORDER = 45`).
