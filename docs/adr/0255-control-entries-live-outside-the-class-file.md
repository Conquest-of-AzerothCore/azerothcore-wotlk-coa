# 0255. Control entries live outside the class file

- Status: accepted
- Date: 2026-11-12
- Supersedes: ADR 0253's placement of the Challenging Shout control and the edge formula of its consequences

## Context

ADR 0253 put the stock Challenging Shout 1161 control in the Templar class file, marked a control in free text only.
The radius review found that its two expected alerts then appear in every Templar report that selects it, and
that score.py treats every class-file `behaviours` entry as ground truth (score.py:44-50), so a reader run would score
it as a miss. A second class-19 file in `classes/` would be shadowed: `load_class_file` returns the first file whose
`class_id` matches (profile.py). The review also found the edge formula of ADR 0253 too general.

## Decision

- Controls live in `apps/coa-gameplay-test/conformance/controls/<class>.json`: `class_id`, `name`, `behaviours`. Each
  entry is an ordinary behaviour entry with `control_for`, the class spell it checks. `profile.control_entries` reads
  them; `generate --controls` writes only them, with the class file's player and the same scenario keys. The class
  file, its ledger, coverage and score never see them.
- Challenging Shout 1161 `edge` moves there with `control_for` 800424.
- The edge formula, with its conditions (Spell.cpp:1389-1398, Object.cpp:1786-1806, Spell.cpp:9425-9446):
  - implicit-target area selection (TARGET_UNIT_SRC_AREA_ENEMY, CASTER_AREA_PARTY, CASTER_AREA_RAID) adds 2.66 only
    for a Player caster who is jumping or falling, or whose speed in its current walk/run mode exceeds 4.97; a
    standing, running-mode player qualifies, a walking one does not;
  - SRC, DEST and TARGET references add the target's combat reach only when the caster is player-controlled and the
    target is not; caster-referenced areas use `IsWithinDist3d`, which adds the target's object size;
  - area auras and script range checks (`IsWithinDistInMap`) add both units' object sizes and no leeway.

## Consequences

- A full class generate no longer writes the control: at 9a6e73942d, 1841 of 1841 scenario files stay
  byte-identical to the generation at ADR 0253, and the `--controls` output is byte-identical to the control scenario
  that ran (runs 20261112-044346 / -044500).
- Seeded tests: the control is read from the control file with its `control_for`, the class file has no 1161 entry,
  and `generate --controls` writes only the control scenario. The class-file entry count is 400 at 9a6e73942d.
