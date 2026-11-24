# 1277. script_count main_hand fixture and the fed_charge_casts expiry void

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

Two review findings on Felsworn tool entries (ADR 1270, ADR 1272):

- fw-rbswb I-1: the `consumed` entries of Annihilation 803904 and Pit Lord's Strength 802076 / 802110 swing one
  interval of the class's dual-wield Slayer set (item 2027, 2300 ms in both hands). Every recorded window landed one
  attack. Before Felsworn ADR 0030 the aura held 2 native charges with 802110 and was removed when they were spent, so a
  one-attack window reads 6 + 1 = 7 with or without that fix. A dual-wield window cannot hold more: the bound sums both
  hands, and 2 intervals give 6, above the least count 5.
- fw-rbaf I-1: `fed_charge_casts` refuses an entry whose nominal slots put the last cast past 0.9 of the aura, but
  the slots drift by about one tick each (cast 4 started 5901 ms after cast 1 against 5400 planned). An uncut last
  cast after the natural expiry would pass the `charges` label as if the charge count had ended the cut.

## Options

- script_count: a landed-attack floor in the counted reading (a judge change, mentor only); a weapon set or alternate
  weapon in the class file (moves every scenario of those spells); an opt-in `main_hand` that replaces the melee
  equip steps of the opted entries only.
- fed_charge_casts: size the slots from the measured drift (still nominal); stamp the game time at the feed stop and
  void a trial whose last cast starts 0.9 of the duration or later after it.

## Decision

- `script_count.main_hand` = `{item, speed_ms, skill_line, proficiency}`, with `swings` only. The scenario's melee
  equip steps (slots 15 and 16 and their `add_item`) become: learn `proficiency` (Spell.dbc Effect[0] 25 on item class
  2, else refused), add and equip `item` in slot 15, set `skill_line` to the class skill target. The landed bound uses
  `speed_ms`; the judge, the counted reading and the evidence are unchanged (controller go, review fw-rbswb I-1).
  Felsworn uses Poniard 2208 (item_template delay 1300, dagger), Daggers 1180, skill line 173, 2 swings = 4600 ms:
  bound 4, below the count 5, as in the ADR 0030 regression's one-dagger fixture. The class file's hit and expertise
  ratings (10000) remove misses, dodges and parries.
- `fed_charge_casts` reads `game_time_ms` right after `cast_until_aura` (`fed at`); a trial whose last cast `start`
  minus `fed at` reaches 0.9 of the aura's duration is void (the void the review asked for, controller go). The aura is
  granted at or before the stamp, so the check is conservative by up to one tick.

## Consequences

- Entries without `main_hand` generate byte-identical scenarios; only the three Felsworn `consumed` entries change.
  `fed_charge_casts` is used by Felsworn 300490 only; its scenario gains one read.
- A window of about 4 landed attacks reads 0 (alert) on a server that keeps 2 native charges, so 802110's consumed
  label can fail on the ADR 0030 defect. The floor of 3 landed attacks per window is shown by the pair's raw values,
  not enforced by the judge; a run with fewer would still pass the D-95 condition 1 rule.
- Untested: the aura's end at its last count (the window stops before it) and the off hand's share of consumption.
