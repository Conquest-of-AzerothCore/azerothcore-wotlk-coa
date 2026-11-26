# 0006. The client prints `$m` at the referenced spell's own level

- Status: accepted (mentor D-29 points 2-3, D-42)
- Date: 2026-11-23

## Context

A Felsworn tooltip such as Tyrant's Gaze 805240 ("dealing ${$m1+0+$AP*0.35} Shadowflame Damage", "heals you for
${$805241m1+$AP*.5}") has two readings of `$m` on an effect with `RealPointsPerLevel` (RPPL) != 0: base points only, or
base points plus RPPL x (level - BaseLevel). The server's stock `SpellEffectInfo::CalcValue` (SpellInfo.cpp:479)
uses the caster level clamped to the spell's MaxLevel (below BaseLevel, BaseLevel), then
`BP + int(RPPL x (level - max(BaseLevel, SpellLevel)))` and the die. Expectations written from a tooltip need to know
which reading the player sees.

Two renders on the lab client, a Human Felsworn at level 60 (melee AP 312, Agility 130), read the tooltips through
`coa-client-lab` `probe spell` and, for one debuff, `SetUnitDebuff`:

| Reading | Shown | Base only | Base + per level | Match |
|---|---|---|---|---|
| 805240 own `$m1` (BP 219, RPPL 4.0, BaseLevel 29, row) | 453 | 329 | 344 + 109.2 = 453 | per level |
| 805240 `${$805241m1+$AP*.5}` (BP 145, RPPL 3.0, BaseLevel 1, no row) | 302 | 146 + 156 = 302 | 479 | base only |
| 800214 `@s:802678` Felstrike `$m1` (BP 8, RPPL 0.5, BaseLevel 10, no row), also after `.learn` | 54 | 6 x 9 = 54 | 6 x 34 = 204 | base only |
| 800355 `$m2` (BP 694, RPPL 9.55, BaseLevel 59, row) | 704 | 695 | 704.55 | per level |
| 801312 `$m1` (BP 20, DieSides 5, RPPL 1.35, BaseLevel 2, MaxLevel 4, row) | 23 | 21 | 23.7 (capped); 99.3 (uncapped) | per level, capped |
| 800207 `${$m1+0+$spfi*.3+$AP*.23}` (BP 24, RPPL 0.45, BaseLevel 15, MaxLevel 20, row) | 99 | 96.8 | 99.0 (capped); 117 (uncapped) | per level, capped |
| 570159 debuff `${$m1+$ppl1+$AGI*0.15}` (BP 4, RPPL 0.5, BaseLevel 17, no row) | 68 | 46 | not reproducible by one reading | aura path |

The split is the SkillLineAbility table (`/srv/coa/server-data/dbc`, identical to the client per the lab preflight):
rows exist for 800207 (line 52), 800214, 800355, 801312 (line 53) and 805240 (line 57), and none for 805241, 802678,
570158, 570159, 800356.

The client decompilation explains it: the stock `Spell_C_GetMinMaxPoints` uses `Spell_C_GetSpellLevel` =
`GetSpellRank(spell) / 5` when its level argument is 0, and `GetSpellRank` is the rank of the spell's skill line found
through SkillLineAbility, capped at 5 x MaxLevel, 0 without a row. Ascension's `Extensions.dll` returns 0 from that
function when called from `SpellParserParseText`, so each `$m` and `$<id>m` falls back to its own spell's level. The
call site of the unit-aura path was not read; the aura rule below is inferred from the 68.

The second render repeated every reading on the current client files and every tooltip line list was byte-identical to
the first. Client files (sha256):

| File | First render (lab) | Second render (current) |
|---|---|---|
| Extensions.dll | 3451a91b6b68980ab895a63bc6f121c312023c3698310a33d2a6878adbae9a2e | a9ced4ae63c0fe118703039bafd9ae0e5194ec2e9c9620e47a10e3c79e08e52c |
| Data/patch-B.MPQ | not recorded | 850396b06761f0c74628f7aaeb2c3ca8f5dfd762d31ceae77bcfc4465b70f8d1 |
| Data/patch-T.MPQ | not recorded | 5b3f26e9c4635a7dfbcc6dba16ceb60dd8afd19b98febd8b1c91e4f963261a8b |
| Data/patch-ZG.MPQ | not recorded | f60f8929e990252ab53d779a862d4e118c455174e9efea6d48e26e9db393b2f0 |

The second render's preflight reported the DBC check as FAIL (49 of 368 client tables differ from the server set); the
nine spells' Spell records and their five SkillLineAbility rows are identical in both sets, so the readings stand.

## Options

- Treat `$m` as always base only. Refuted by 805240, 800355, 801312 and 800207.
- Treat `$m` as always base plus per level at the caster level. Refuted by 805241 and Felstrike 802678.
- Follow the stock parser (one level for the whole text). Refuted by the same two readings: it would print 479.
- Follow the referenced spell's own level, with SkillLineAbility as the source of that level (chosen).

## Decision

At level 60 a spell tooltip (spellbook, talent card, hyperlink) prints `$m`, `$mN` and `$<id>mN` as:

- With a SkillLineAbility row for the character's race and class: `BP + 1 + RPPL x max(0, L - BaseLevel)`, where `L` is
  the skill rank (300 at level 60) divided by 5, capped by the referenced spell's MaxLevel when it is above 0, so
  `L = min(60, MaxLevel)` for MaxLevel > 0 and 60 otherwise. The client shows the minimum for DieSides > 1.
- Without a row: `BP + 1`, no per-level points.
- A live aura tooltip on a unit applies per-level points to `$m1` (and a nonzero level to the whole text), and `$ppl1`
  adds the per-level total again. This rests on one reading (570159 = 68), not on a decomposition.

A conformance expectation that reads `$m` on an effect with RPPL != 0 states in its `observe_source` the
SkillLineAbility row it found, the rank level `L` and the MaxLevel cap it used. For a spell without a row the
expectation waits for an owner ruling; 805241 has one (owner ruling Sun Cleric O-37 (2026-11-23, Sun Cleric ADR 0044): the server follows the displayed value, see
[ADR 0002](0002-tyrants-gaze-heals-its-displayed-points-and-generates-one-felfury.md)) and Felstrike 802678 stays an
open owner question. No server change follows from this ADR.

## Consequences

- Entries on spells with a row and MaxLevel 0 (805240, 560284 Infernal, 800355) already equal the rule at level 60 and
  do not change. No class entry reads `$m` of a MaxLevel-capped spell with a row (800207, 801312, 801895, 802060,
  520236, 705129).
- Nine tokens on spells without a row (300469, 520832, 520806, 563271, 806096, 803645, 805241, 802678, 500761) show a
  base-only value while the stock server applies the per-level term; each stays unexpected until the owner rules on it.
  Five of them also carry `$<id>ppl1`, which no spell-tooltip render covered.
- The rule describes the client's text, not the server's behaviour; the server's `CalcValue` is unchanged.

## Observation

The `$ppl1` token on the unit-aura path counts the per-level part twice; the reconstruction's CFormula scaffold maps
`ppl1` to the raw RPPL, which the 68 contradicts for the shipped client.

## Addendum 2026-11-23: render 3 evidence and the truncation tolerance

Render 3 (`.agents/plans/felsworn-conformance/render3/report.md`, lab client on slot 3) read seven sentences on spells
without a SkillLineAbility row. It supersedes the statement above that `$<id>ppl1` is not rendered on a no-row spell:

- `$<id>ppl1` prints the referenced effect's base plus RealPointsPerLevel x (60 - BaseLevel), unrounded, and the whole
  `${...}` expression is rounded to the nearest (Doomscarring 64.5 prints 65, Illidari Barrier 431.96 prints 432).
  Six sentences fit this decomposition: Illidari Barrier 300468 (432), Scars of the Past 520805 (200), Doomscarring
  685321 (65), Whirling Vengeance 704602 (932), Fel Torpedo 500610 (304) and Felwrath 520236 (108).
- Unphased 803645 now has a SkillLineAbility row (86011); its `-($m1)` prints 60, the server's -60 negated.
- The server's `CalcValue` truncates the per-level points to an integer before the sum (SpellInfo.cpp:497), where the
  client rounds the whole expression. For the fractional rates this differs by under one point: Whirling Vengeance
  756 against 756.6 (931 measured, 932 printed) and Fel Torpedo 194 against 194.6, judged as its dice range 194 to 198.
  Mentor decision D-48 accepts this as known engine rounding (the Sturdy precedent): a conformance expectation reads
  the rendered formula and tolerates the truncation inside the engine model's interval; it does not become a defect.
- No server, DBC or client text change follows.
