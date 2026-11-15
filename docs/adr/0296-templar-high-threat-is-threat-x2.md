# 0296. A Templar "High Threat" tooltip means threat x2

- Status: accepted
- Date: 2026-11-12

## Context

Three Templar tooltips say "High Threat" with no number: Sacred Swing 705293 ("High Threat Weapon Damage", six
ranks 705293, 748501-748504 and 572769), Faith Guard 705259 (its payload Faith 706466, "High Threat Holy damage") and
Armor of Faith 804930 (its payload 801546, "High Threat Holy damage"). Faith and 801546 carry a `spell_threat`
pctMod of 2 (`rev_20261103_01_templar_faith_threat.sql`, `rev_20261026_20_coa_tank_ability_threat.sql`). Sacred
Swing carried 2.25 (`rev_20261021_16_templar_sacred_swing_threat.sql`, "the Revenge multiplier"), and the
conformance run measured its slope at 2.25 with the flat 50 of its 301061 slow (ADR 0225). Owner question Q-r3a-1
asked whether one meaning governs the phrase.

The owner ruled on 2026-11-12 (`method-study/owner-rulings-2026-11-10.md`, status-5 section): option (a), threat x2
for every Templar tooltip that says "High Threat"; Sacred Swing goes from 2.25 to 2. The reference snapshots
(`~/CoaServer/reference`: coabuildhub `skills_templar.json`, sidekick `data.js`) repeat the tooltip text and give no
multiplier.

## Options

- Edit `rev_20261021_16` in place. It is a pending file that may already be applied on a realm, so a changed body
  would not reach that realm.
- A new pending file that replaces the six rows with pctMod 2. Chosen.

## Decision

`rev_20261112_21_templar_sacred_swing_threat_x2.sql` deletes and reinserts `spell_threat` (entry, 0, 2, 0) for the six
Sacred Swing ranks. The flat part stays in 301061's `SPELL_EFFECT_THREAT`. The 2.25 rows of other classes in
`rev_20261026_20` are outside the ruling and unchanged.

## Consequences

- Sacred Swing threat is x0.889 of what it was (2 / 2.25).
- `tank-threat-audit-templar.json` gains a Sacred Swing arm read as deltas around one cast (Faith's line also reaches
  that target): threat gained over health change -2.105 at 474 damage, against -2.355 under 2.25. Faith's existing
  assert is the control.
- The conformance entry `behaviours[4]` (572769, slope 2, flat from 301061) reads ok, with Faith Guard `[221]` as the
  control; a new entry checks Armor of Faith's 801546 at slope 2, its flat 100 counted from its own effect 63.
- A cached world slot picks up the new pending file without `--refresh-world`: the gameplay runner fingerprints
  `data/sql/updates` and reported the slot "refreshed" on the first run after the file appeared.
