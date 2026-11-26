# 0002. Cultist base spells in extra_spells

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

`CharacterAdvancement.dbc` gives Cultist (class 25) 216 spells (275 ranks at level 60). Outside
`CharacterAdvancement.dbc`, `AscensionCompatData::ClassSpells` (`src/server/coa/AscensionCustomClassData.h:531-546`)
grants three Cultist base melee strikes — `500720` Blade of the Empire (also in
`src/server/coa/AscensionLiveBaselineData.h:220`), `804152` Entropic Slam, and `805116` Hammer of Twilight — alongside
four stock baseline skills (`107` Block, `2764` Throw, `3018` Shoot, `5019` Wand).

At level 60, a Cultist knows all three base strikes (`AscensionCompat.cpp:1000-1028`), upgraded via
`src/server/coa/AscensionSpellProgressionData.h` to `502122` Blade of the Empire (Rank 10; 12 ranks total), `572846`
Entropic Slam (Rank 6; 6 ranks total), and `806830` Hammer of Twilight (Rank 8; 8 ranks total). All three carry
class-specific tooltip claims (9 clauses total), and other Cultist spells in `CharacterAdvancement.dbc` directly
reference Blade of the Empire (for example `300278` Bulwark of Horror).

Under [ADR 0016](../../0016-conformance-class-spells-beyond-character-advancement.md) (and
[ADR 0540](../../0540-a-taken-hit-arm-may-unlearn-a-granted-passive.md), summarized in
`apps/coa-gameplay-test/conformance/docs/spell-sets.md`), spells outside `CharacterAdvancement.dbc` enter a class's
conformance spell set and ledger only when listed in `extra_spells` with a verified combat-log event from a player who
also casts a `CharacterAdvancement` active of the class, a class kit listing, or an owner ruling.

## Options

- Keep `extra_spells` empty (the `CharacterAdvancement`-only choice used for Witch Hunter, Sun Cleric and Felsworn).
  Rejected: live Cultist players cast all three base melee strikes heavily as their core Insanity builder and spenders,
  leaving core class gameplay unjudged.
- Add every server `AscensionCompatData::ClassSpells` row for class 25, including `107`, `2764`, `3018` and `5019`.
  Rejected under ADR 0016 option 2 and `spell-sets.md`: server data alone is not live-kit evidence, and stock skills
  carry no class-specific tooltip claims.
- Add only the three confirmed Cultist base strikes to `extra_spells` with combat-log citations, keeping the stock
  skills out. Chosen.

## Decision

Add `500720`, `804152` and `805116` to `extra_spells` in `apps/coa-gameplay-test/conformance/classes/cultist.json`:

| Base spell | L60 rank | Citation | Cultist player casts (`coa-history`, 186 logs) |
|---|---:|---|---|
| `500720` Blade of the Empire | `502122` | `2026-08-31 19:09:41.673, spell 502122 Blade of the Empire, Ascension combat log, private archive` | 13,720 `SPELL_CAST_SUCCESS` across all ranks (28 players, 43 logs; 8,145 on `502122` by 7 players in 14 logs); 1 additional Rank 5 `502117` cast in log 82 came from a player with 12 logged events (including Insanity `500706` and Despoiled Ground `805180`) and no CA active cast (13,721 all-player total) |
| `804152` Entropic Slam | `572846` | `2026-08-31 19:12:11.142, spell 572846 Entropic Slam, Ascension combat log, private archive` | 2,431 `SPELL_CAST_SUCCESS` across all ranks (20 players, 35 logs; 1,018 on `572846` by 10 players in 12 logs; equals all-player total) |
| `805116` Hammer of Twilight | `806830` | `2026-08-31 19:18:56.205, spell 806830 Hammer of Twilight, Ascension combat log, private archive` | 3,947 `SPELL_CAST_SUCCESS` across all ranks (23 players, 39 logs; 2,079 on `806830` by 6 players in 12 logs; equals all-player total) |

Evidence and format details:

- Combat-log verification: every cited event is a `SPELL_CAST_SUCCESS` from a player who also casts the Cultist
  `CharacterAdvancement` active `578115` Void Shield in the same log. Per ADR 0016 D2, committed files carry no raw
  log lines and no character names.
- Weapon sets: in server `Spell.dbc`, every rank of `500720` (12 ranks), `804152` (6 ranks) and `805116` (8 ranks) has
  `EquippedItemClass = 2`, `EquippedItemSubClassMask = 173555` (`0x2A5F3`, any melee weapon including 2H Axe subclass
  1), `EquippedItemInventoryTypeMask = 0`, and `AttributesEx3 = 0x400` (`SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON`). All
  three are class-wide melee strikes satisfied by the default `Godblade` set (`2531` Great Axe, subclass 1, slot 15),
  so `spell_weapon_sets` leaves them unmapped to inherit `default_weapon_set` (`Godblade`), matching the 56 class-wide
  tab-87 ranks ([ADR 0001](0001-cultist-weapon-sets.md)).
- Stock spells left out: `107` Block, `5019` Wand, `2764` Throw and `3018` Shoot stay out of `extra_spells`. They are
  stock skills without class-specific tooltip claims (`spell-sets.md`), and all four have 0 `spell_events` rows from
  Cultist players in the 186-log archive (`107` has 0 player events archive-wide; `2764`, `3018` and `5019` appear only
  on non-Cultist players).
- Clause ledger: the 9 generated rows (`502122`: 4 rows, `572846`: 2 rows, `806830`: 3 rows) are merged into
  `apps/coa-gameplay-test/conformance/classes/cultist_clauses.json` without disturbing any of the 424 existing rows
  (all 55 hand-split rows from commit `156dac282d` remain byte-identical in content, labels, claims and order).

## Consequences

- `classes/cultist.json` now spans 219 spells (216 `CharacterAdvancement` + 3 `extra_spells`).
- `classes/cultist_clauses.json` grows from 424 rows / 216 spells / 406 claim rows (471 stated claims: 357 labelled,
  114 unlabelled; 103 unlabelled rows; 18 `no_claim`) to 433 rows / 219 spells / 415 claim rows (480 stated claims:
  360 labelled, 120 unlabelled; 109 unlabelled rows; 18 `no_claim`).
- `conformance.py generate --class 25` generates value and hit scenarios for `502122`, `572846` and `806830` armed
  with the default `Godblade` weapon set.
