# 0790. A weapon and school hit can take its literal weapon percent from the streamed text

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Heartseeking Bolt 807284 deals a school part (Effect[0] SCHOOL_DAMAGE) and a weapon part (Effect[1]
WEAPON_PERCENT_DAMAGE). Owner ruling O-15 streams its text through `coa_client_spell_description`
(`rev_20261115_02_witch_hunter_heartseeking_bolt_text.sql`): "deals 300% Ranged Weapon Damage plus
${$m1+244+0+$RAP*0.5+$sps*0.3}". The 300% is a literal, not a `$s2` token, because Spell.dbc Effect[1] still reads
200% (BasePoints 199 + DieSides 1). Listed in `weapon_school_hits`, the rank was refused as "its tooltip shows no
weapon value"; unlisted, only the school part was judged and the `807284 hit_mean` alert stayed open. The mentor
approved the c15-tool2 design line (D-252) with the condition that each percent carries its text row and revision
(D-253), so no value can be fitted to a hit.

## Options

- A class-file `weapon_school_percents` map, rank to `{percent, source}`, checked against the streamed text.
- Reading any literal `N%` from the text: the parser cannot tell a weapon percent from another literal.
- A `literal_tokens` or `effect_overrides` entry: they change a token's value, and here no token exists.

## Decision

`weapon_school_percents` applies only to a rank listed in `weapon_school_hits`. It adds the percent as the displayed
value of the rank's single weapon percent effect when every check holds: a positive whole percent; exactly one
weapon percent effect; no tooltip token already at that effect; `source` is the file of the streamed text row that
the tooltip reads for the rank; that text contains the literal `N%`. Any failed check leaves the rank unmodelled
with its reason.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests (`WeaponSchoolPercentTests`): the 300% adds three weapon hits to the school part; a missing entry, a
  percent absent from the text (200), a source that is not the streamed row, a non-whole percent and a rank that
  shows its percent as a token are refused. Mutant: an ignored percent is refused, not judged on the school part.
- Witch Hunter: 807284 joins `weapon_school_hits` with `{"percent": 300, "source":
  "rev_20261115_02_witch_hunter_heartseeking_bolt_text.sql"}`; the reference model is 1081.7 (tooltip mean 1186.7).
