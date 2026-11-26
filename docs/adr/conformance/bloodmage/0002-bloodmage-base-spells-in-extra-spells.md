# 0002. Bloodmage base spells in extra_spells

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-26

## Context

`CharacterAdvancement.dbc` gives Bloodmage (class 20, `SONOFARUGAL`) 222 spells (301 ranks at level 60; 308 ranks
total). Outside `CharacterAdvancement.dbc`, `AscensionCompatData::ClassSpells`
(`src/server/coa/AscensionCustomClassData.h:337-375`) grants 39 baseline spells: 32 Bloodmage-specific abilities and 7
shared stock skills (`81` Dodge, `107` Block, `2764` Throw, `3018` Shoot, `5019` Wand, `6603` Auto Attack, `552011`
Resilient Constitution).

At level 60, a Bloodmage knows all 32 class baseline abilities (119 ranks at level 60; 126 ranks across all levels via
`src/server/coa/AscensionSpellProgressionData.h`). They comprise the class's core rotation, healing, shield, offering,
form and utility kit — including `500125` Bloodmoon Blast, `804685` Bloodbolt, `800156` Bloodfang Bite, `800774`
Sanguine Rupture, `500169` Claw Sweep, `500123` Ravenous Strike, `800772` Taldaram's Torment, `573299` Animated Blood,
`802310` Sanguine Mend, `500126` Lunge, `562720` Blood Curse (the base form transformed by `CharacterAdvancement`
talents `504710` Accursed Form, `504728` Transgression, and `505188` Sanguine Essence in
`AscensionTalentReplacementData.h:57-59`), and `804203` Apotheosis. Many existing `CharacterAdvancement` passives
directly modify these 32 spells.

Under [ADR 0016](../../0016-conformance-class-spells-beyond-character-advancement.md) (and the Necromancer kit-listing
precedent of 2026-11-12 summarized in `apps/coa-gameplay-test/conformance/docs/spell-sets.md`), spells outside
`CharacterAdvancement.dbc` enter a class's conformance spell set and ledger only when listed in `extra_spells` with a
verified combat-log event from a player who also casts a `CharacterAdvancement` active of the class, a live class kit
listing (`ascensionsidekick data.js coaKits`), or an owner ruling.

## Options

- Keep `extra_spells` empty (`CharacterAdvancement` only). Rejected: live Bloodmage players cast 28 of these 32
  abilities across the combat-log archive as their primary rotation, and `562720` Blood Curse is the base spell
  replaced by three specialization form talents already in the ledger.
- Add all 39 `AscensionCompatData::ClassSpells` entries, including the 7 shared stock skills. Rejected under ADR 0016
  option 2 and `spell-sets.md`: server data alone is not live-kit evidence, none of the 7 stock skills has any
  Bloodmage player event in the 186-log archive, and stock skills carry no class-specific tooltip claims.
- Add only the 32 Bloodmage-specific baseline spells to `extra_spells` — 28 with verified combat-log citations and 4
  zero-log baseline spells with `ascensionsidekick` `coaKits` Bloodmage kit citations — leaving the 7 shared stock
  skills and unobtainable variant `804195` out. Chosen.

## Decision

Add all 32 Bloodmage-specific baseline spells to `extra_spells` in
`apps/coa-gameplay-test/conformance/classes/bloodmage.json`:

| Base spell | L60 rank (ranks) | Clauses | Citation | Evidence (`coa-history`, 186 logs / sidekick `coaKits`) |
|---|---:|---:|---|---|
| `500123` Ravenous Strike | `501679` (10) | 1 | `2026-08-23 18:32:50.782, spell 501679 Ravenous Strike, Ascension combat log, private archive` | 2,460 `SPELL_CAST_SUCCESS` (9 pl, 26 logs; 1,511 on `501679`; 2,478 all-player) |
| `500125` Bloodmoon Blast | `501614` (10) | 3 | `2026-08-31 20:31:41.403, spell 501614 Bloodmoon Blast, Ascension combat log, private archive` | 3,822 `SPELL_CAST_START` (13 pl, 32 logs; 2,753 on `501614`) |
| `500126` Lunge | `500126` (1) | 3 | `2026-08-23 18:32:31.659, spell 500126 Lunge, Ascension combat log, private archive` | 285 `SPELL_CAST_SUCCESS` (9 pl, 27 logs; 285 on `500126`) |
| `500169` Claw Sweep | `500444` (8) | 1 | `2026-08-23 18:30:55.994, spell 500444 Claw Sweep, Ascension combat log, private archive` | 2,536 `SPELL_CAST_SUCCESS` (9 pl, 27 logs; 1,767 on `500444`) |
| `504296` Blood Shield | `504296` (1) | 5 | `2026-08-23 18:28:27.773, spell 504296 Blood Shield, Ascension combat log, private archive` | 71 `SPELL_CAST_SUCCESS` (8 pl, 22 logs; 71 on `504296`; 74 all-player) |
| `504849` Vital Shield | `504849` (1) | 4 | `2026-08-19 22:05:44.791, spell 504849 Vital Shield, Ascension combat log, private archive` | 7 `SPELL_CAST_SUCCESS` (2 pl, 6 logs; 7 on `504849`) |
| `504897` Coagulated Shield | `504897` (1) | 4 | `2026-08-09 18:03:51.916, spell 504897 Coagulated Shield, Ascension combat log, private archive` | 13 `SPELL_CAST_SUCCESS` (3 pl, 5 logs; 13 on `504897`; 15 all-player) |
| `562228` Detect Life | `562228` (1) | 1 | `ascensionsidekick data.js coaKits Bloodmage Sanguine kit, fetched 2026-09-18` | 0 log events; listed in sidekick Sanguine kit and archived spellbook |
| `562720` Blood Curse | `562720` (1) | 3 | `ascensionsidekick data.js coaKits Bloodmage Accursed kit, fetched 2026-09-18` | 0 verified BM casts (2 periodic ticks in log 85 from a player with no same-log CA active); listed in sidekick Accursed kit and archived spellbook |
| `562723` Moon Gaze | `562723` (1) | 3 | `2026-08-17 20:07:10.386, spell 562723 Moon Gaze, Ascension combat log, private archive` | 5 `SPELL_CAST_SUCCESS` (1 pl, 5 logs; 5 on `562723`) |
| `572116` Greater Bloodthorns | `572116` (1) | 3 | `2026-08-23 18:28:29.489, spell 572116 Greater Bloodthorns, Ascension combat log, private archive` | 101 `SPELL_CAST_SUCCESS` (3 pl, 17 logs; 101 on `572116`) |
| `572305` Hypovolemic Shock | `572412` (5) | 2 | `2026-08-23 18:52:48.518, spell 572412 Hypovolemic Shock, Ascension combat log, private archive` | 111 `SPELL_CAST_SUCCESS` (2 pl, 6 logs; 72 on `572412`) |
| `572400` Bloodsoaked Offering | `572403` (4) | 1 | `2026-08-08 18:41:21.485, spell 572403 Bloodsoaked Offering, Ascension combat log, private archive` | 14 `SPELL_CAST_SUCCESS` (3 pl, 5 logs; 1 on `572403`; 16 all-player) |
| `572404` Greater Bloodsoaked Offering | `572404` (1) | 1 | `ascensionsidekick data.js coaKits Bloodmage Sanguine kit, fetched 2026-09-18` | 0 log events; listed in sidekick Sanguine kit and archived spellbook |
| `573299` Animated Blood | `573357` (3) | 4 | `2026-08-31 20:33:42.749, spell 573357 Animated Blood, Ascension combat log, private archive` | 821 `SPELL_CAST_SUCCESS` (13 pl, 31 logs; 799 on `573357`) |
| `680299` Greater Sanguinary Offering | `680299` (1) | 2 | `2026-08-23 18:28:31.012, spell 680299 Greater Sanguinary Offering, Ascension combat log, private archive` | 109 `SPELL_CAST_SUCCESS` (3 pl, 18 logs; 109 on `680299`; 110 all-player) |
| `706605` Blood Feast | `706605` (1) | 4 | `2026-08-09 17:29:40.378, spell 706605 Blood Feast, Ascension combat log, private archive` | 4 `SPELL_CAST_SUCCESS` (1 pl, 3 logs; 4 on `706605`) |
| `706630` Sanguinary Offering | `707339` (5) | 2 | `2026-08-04 15:08:10.722, spell 707338 Sanguinary Offering, Ascension combat log, private archive` | 38 `SPELL_CAST_SUCCESS` (9 pl, 12 logs; logged up to Rank 4 `707338`; 40 all-player) |
| `707900` Blood Tap | `707900` (1) | 1 | `2026-08-31 20:33:37.864, spell 707900 Blood Tap, Ascension combat log, private archive` | 210 `SPELL_CAST_SUCCESS` (6 pl, 22 logs; 210 on `707900`; 211 all-player) |
| `800156` Bloodfang Bite | `572551` (10) | 2 | `2026-08-23 18:32:19.754, spell 572551 Bloodfang Bite, Ascension combat log, private archive` | 3,069 `SPELL_CAST_SUCCESS` (5 pl, 23 logs; 2,784 on `572551`; 3,073 all-player) |
| `800175` Running Wild | `800175` (1) | 2 | `ascensionsidekick data.js coaKits Bloodmage Eternal kit, fetched 2026-09-18` | 0 log events; listed in sidekick Eternal kit (`AscensionMountSpeed.cpp:28`) |
| `800772` Taldaram's Torment | `802580` (8) | 4 | `2026-08-31 20:31:52.242, spell 802580 Taldaram's Torment, Ascension combat log, private archive` | 1,417 `SPELL_CAST_SUCCESS` (13 pl, 33 logs; 932 on `802580`) |
| `800774` Sanguine Rupture | `572907` (8) | 3 | `2026-08-23 18:42:09.291, spell 572907 Sanguine Rupture, Ascension combat log, private archive` | 2,803 `SPELL_CAST_SUCCESS` (12 pl, 33 logs; 1,505 on `572907`) |
| `801563` Vampyr Bite | `803585` (8) | 4 | `2026-08-17 20:17:25.763, spell 803585 Vampyr Bite, Ascension combat log, private archive` | 4 `SPELL_CAST_START` (2 pl, 4 logs; 3 on `803585`) |
| `801957` Bare Fangs | `801957` (1) | 1 | `2026-06-08 01:22:30.666, spell 801957 Bare Fangs, Ascension combat log, private archive` | 5 `SPELL_CAST_SUCCESS` (1 pl, 2 logs; 5 on `801957`) |
| `802310` Sanguine Mend | `504085` (9) | 3 | `2026-08-31 20:34:35.709, spell 504085 Sanguine Mend, Ascension combat log, private archive` | 292 `SPELL_CAST_START` (6 pl, 13 logs; 12 on `504085`) |
| `802313` Bloodthorns | `501667` (10) | 3 | `2026-08-04 15:08:09.122, spell 501665 Bloodthorns, Ascension combat log, private archive` | 30 `SPELL_CAST_SUCCESS` (10 pl, 13 logs; logged up to `501665`; 34 all-player) |
| `804203` Apotheosis | `804203` (1) | 3 | `2026-08-23 18:42:06.973, spell 804203 Apotheosis, Ascension combat log, private archive` | 38 `SPELL_CAST_SUCCESS` (3 pl, 13 logs; 38 on `804203`) |
| `804685` Bloodbolt | `578305` (8) | 2 | `2026-08-31 20:31:57.008, spell 578305 Bloodbolt, Ascension combat log, private archive` | 3,419 `SPELL_CAST_SUCCESS` (13 pl, 30 logs; 3,019 on `578305`) |
| `806182` Shadow Vigil | `806182` (1) | 2 | `2026-08-23 18:49:43.482, spell 806182 Shadow Vigil, Ascension combat log, private archive` | 26 `SPELL_CAST_SUCCESS` (3 pl, 5 logs; 26 on `806182`) |
| `1108459` Slaughterhouse Offering | `1108493` (3) | 3 | `2026-08-09 19:30:16.391, spell 1108463 Slaughterhouse Offering, Ascension combat log, private archive` | 2 `SPELL_CAST_SUCCESS` (1 pl, 2 logs; logged at Rank 2 `1108463`) |
| `1200012` Blood Covenant | `1200012` (1) | 2 | `2026-08-23 18:25:38.772, spell 1200012 Blood Covenant, Ascension combat log, private archive` | 6 `SPELL_CAST_SUCCESS` (2 pl, 3 logs; 6 on `1200012`) |

Evidence, exclusions and verification details:

- Combat-log verification (28 spells): every cited event is a `SPELL_CAST_SUCCESS` (25 instant/channel spells) or
  `SPELL_CAST_START` (3 cast-time spells: `500125` Bloodmoon Blast, `802310` Sanguine Mend, `801563` Vampyr Bite, which
  do not emit `SPELL_CAST_SUCCESS` in WotLK 3.3.5 logs) from a player who also casts a Bloodmage
  `CharacterAdvancement` active (`807785` Aortic Assault, `572575`/`503612` Dark Liturgy, `802469` Reave, `503479`
  Rotclaw, or `572277` Blood Veil) in the same log. Every cited spell ID is a rank of its progression chain and matches
  the base spell's `Spell.dbc` name. Per ADR 0016 D2, committed files carry no raw log lines and no character names.
- Kit-cited zero-log baseline spells (4 spells): `562720` Blood Curse (`Accursed`), `562228` Detect Life (`Sanguine`),
  `572404` Greater Bloodsoaked Offering (`Sanguine`), and `800175` Running Wild (`Eternal`) have 0 verified Bloodmage
  cast events in the 186-log archive (`562720` has 2 periodic events — `SPELL_PERIODIC_ENERGIZE` and
  `SPELL_PERIODIC_HEAL` — in log 85 on 2026-08-03 from a player who logged no other spell in that file). All 4 appear
  in the `ascensionsidekick` `data.js` `coaKits` Bloodmage kits (fetched 2026-09-18), and `562720`, `562228` and
  `572404` also appear in the archived live Bloodmage spellbook, satisfying the 2026-11-12 kit-listing precedent
  (`spell-sets.md`).
- `804195` Apotheosis (left out): `src/server/coa/AscensionBloodmageTalents.cpp:60-63,787-822` and
  `rev_20261018_36_bloodmage_apotheosis_proc.sql` register `aura_ascension_bloodmage_apotheosis` for both `804195`
  (`SPELL_APOTHEOSIS`, Shadow-damage-only variant with `$?s681078` Empowered text on `SkillLine=75` Eternal,
  `acquire=0`) and `804203` (`SPELL_DARK_FEAST`, all-damage variant on `SkillLine=74` Accursed). However, `804195` has
  no grant path in the fork (`coa-obtainable --class 20 804195` returns `NOT FOUND`: absent from
  `AscensionCustomClassData.h`, `CharacterAdvancement.dbc`, and `trainer_spell`), has 0 events across all 186 combat
  logs, and is absent from the archived live spellbook (which lists only `804203`). Only `804203` enters
  `extra_spells`.
- `800157` Eternal Curse (left out of `extra_spells`): taught by `CharacterAdvancement` level-10 passive `92114`
  Eternal Curse (`AscensionTaughtAbilityData.h:32`) and already pulled into `classes/bloodmage_clauses.json` via
  `@s:800157:0@` on `92114` (6 pulled rows covering `807736e0..2`, `804320e0`, `800157e0`, and the Demon `@ext` rule).
  Adding `800157` to `extra_spells` would duplicate those pulled rows.
- Shared stock spells left out (7 spells): `81` Dodge, `107` Block, `2764` Throw, `3018` Shoot, `5019` Wand, `6603`
  Auto Attack, and `552011` Resilient Constitution stay out of `extra_spells`. They carry no Bloodmage-specific tooltip
  claims (`spell-sets.md`), and all 7 have 0 events from Bloodmage players in the 186-log archive.
- Weapon requirements & streamed text: none of the 32 base spells (126 ranks) has `EquippedItemClass != -1` in server
  `Spell.dbc`; `500123` Ravenous Strike sets `AttributesEx3 = 0x400` (`SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON`),
  satisfied by any main-hand weapon. None of the 32 spells or their ranks has a row in `coa_client_spell_description`
  (`704626` Thick Pelt remains the sole streamed spell).
- Clause ledger merge: the 82 generated claim rows (60 labelled, 22 unlabelled, 0 `no_claim`) across the 32 added
  spells are merged into `apps/coa-gameplay-test/conformance/classes/bloodmage_clauses.json` without modifying any of
  the 471 existing rows (all 86 mechanical split rows from commit `de81cf8628` remain byte-identical in content,
  labels, claims and relative order).

## Consequences

- `classes/bloodmage.json` now spans 254 spells (222 `CharacterAdvancement` + 32 `extra_spells`; 420 ranks at level 60).
- `classes/bloodmage_clauses.json` grows from 471 rows / 222 spells / 456 claim rows (560 stated claims: 448 labelled,
  112 unlabelled; 15 `no_claim`) to 553 rows / 254 spells / 538 claim rows (642 stated claims: 508 labelled, 134
  unlabelled across 133 rows; 15 `no_claim`).
- `conformance.py generate --class 20` succeeds with 641 generated scenarios (185 entries without a scenario).
