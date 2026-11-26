# 0033. Owner rulings Q-cu-3, Q-cu-4, Q-cu-9, Q-cu-15, Q-cu-20, Q-cu-21, Q-cu-22, Q-cu-25, Q-cu-26: server behaviour kept with approved client text updates (O-18)

- Status: accepted (owner rulings O-12 2026-11-24, O-15 2026-11-25, O-18 2026-11-25)
- Date: 2026-11-25

## Context

During the Cultist (class 25) conformance pass, nine owner questions resulted in keeping existing server behaviour and
updating client tooltip texts (`coa_client_spell_description` and `patch-ZG.MPQ`, to be applied at class end). On
2026-11-25 (`O-18`, "go global"), the owner approved all ten client-text proposals (these nine plus the buff tooltip for
Twisted Seal `525065`, whose server fix `Q-cu-16` is recorded in [Cultist ADR 0020](0020-twisted-seal-deflects-melee-abilities.md)).
Until the class-end SQL and MPQ pass lands, each of these nine items is a deviation from the unpatched DBC tooltip kept
by owner ruling and proved in game against the approved new text's expectation.

### 1. `Q-cu-3` (`O-12`, `O-18`) — Mind Rot (`300300`, ledger row 41)

- **Current DBC text:** `"Periodic or channeled damage dealt now has a $h% chance to curse your target, applying |cffffffffMind Rot|r.@s:560714:0@"`
- **Approved O-18 text (`300300` `Description[enUS]`):** `"Periodic or channeled damage dealt now has a $h% chance to afflict your target with |cffffffffMind Rot|r.@s:560714:0@"`
- **Server behaviour kept:** Mind Rot debuff `560943` keeps `Dispel = 1` (Magic).
- **Live evidence (`ev2.md`, strength: none):** `NO LIVE EVIDENCE` — 0 events and 0 `SPELL_DISPEL` lines for `560943`,
  `560714`, or `300300` across 186 logs (`spell.csv.gz` also has `560943` `dispel_type = 1` Magic).
- **Owner's choice:** `keep` Magic dispel (`O-12`), replace `"to curse your target, applying"` with
  `"to afflict your target with"` (`O-18`).

### 2. `Q-cu-4` (`O-12`, `O-18`) — Malignant Armor (`680569`, ledger row 239)

- **Current DBC text:** `"Increases your attack power by 2 for every ${($m1*$m2)*2} armor value you have."` (renders `0`
  in-client because `Effect[1]` is empty, `$m2 = 0`).
- **Approved O-18 text (`680569` `Description[enUS]`):** `"Increases your attack power by 2 for every 100 armor value you have."`
- **Server behaviour kept:** `680569` `Effect[0]` (`aura 285`, `bp = 49 + 1 = 50`) grants `int32(GetArmor() / 50)` =
  `1 AP per 50 armor` (`2 AP per 100 armor`, `StatSystem.cpp:660-663`).
- **Live evidence (`ev2.md`, strength: none in logs; archive video matches):** `NO LIVE EVIDENCE` in combat logs
  (0 events, passive); archive tooltip video (`q742IyqxrV0.csv` `t=12:08`) displayed `"2 for every 100 armor value you have"`.
- **Owner's choice:** `text` (`O-12`, `O-18`) — keep server `1 AP / 50 armor`, fix client text to `100`.

### 3. `Q-cu-9` (`O-12`, `O-18`) — Void Strength (`805121`, ledger row 399)

- **Current DBC text:** `"|cFF66DDFFLevel 40 Passive|r\r\nIncreases your Shadow spell damage by $s3% of your Strength and your spell hit chance by $s1% of your Strength."`
- **Approved O-18 text (`805121` `Description[enUS]`):** replaces `"spell hit chance"` with `"spell hit rating"`.
- **Server behaviour kept:** `805121` `Effect[0]` (`aura 220` `SPELL_AURA_MOD_RATING_FROM_STAT`, `MiscValue = 128`
  `CR_HIT_SPELL`, `bp = 4 + 1 = 5%`) grants spell hit rating equal to `5%` of Strength (`+20` rating at 408 Strength).
- **Live evidence (`ev2.md`, strength: none):** `NO LIVE EVIDENCE` in combat logs (0 events, passive; `spell.csv.gz`
  identical `aura = 220, misc_value = 128`; archive video `t=9:04` had `"spell hit chance"`).
- **Owner's choice:** `rating_text` (`O-12`, `O-18`) — keep spell hit rating on server, change text to `"spell hit rating"`.

### 4. `Q-cu-15` (`O-15`, `O-18`) — Dark Matter (`806382`, ledger row 421 claim 2)

- **Current DBC text:** `"Channeling |cffffffffSatiate|r now heals all allies within $807219a1 yds for ${$807219m1+$807219ppl1+$bh*.2} every $807124T2 sec for $807219d."` (`$807219d = 10 sec`).
- **Approved O-18 text (`806382` `Description[enUS]`):** replaces `$807219d` with `$804275d` (`6 sec`).
- **Server behaviour kept:** `AscensionCultistAuras.cpp:195-198,233-241` removes Dark Matter driver aura `807124` as soon
  as the 6 s Satiate `804275` channel ends (`max 6` ticks).
- **Live evidence (`ev1.md`, strength: strong):** `LIVE SHOWS` Dark Matter ends at `<= 6.0 s` — 9 non-duplicate logs,
  3 players (`Hirilola`, `Yoggsdriving`, `Jimjonescult`), 32 `807124` sessions, 2,158 `807219` heals: 20/32 full sessions
  lasted `5.75–6.009 s` (0 sessions `> 6.01 s`, max `6` ticks), agreeing with the server.
- **Owner's choice:** `channel_text` (`O-15`, `O-18`) — keep 6 s duration, update text to `$804275d` (`6 sec`).

### 5. `Q-cu-20` (`O-15`, `O-18`) — Horrific Revelations / Horrific Revelation (`524877` / `704473`, ledger row 152 claim 1)

- **Current DBC text (`704473`, embedded in `524877` via `@s:704473:0@`):**
  `"Heals a friendly target for ${$m1+0+$SP*0.678496}, scaling with |cffcfa6ffInsanity|r, and increases their critical strike chance by $s2%, stacking $u times, for $d."`
- **Approved O-18 text (`704473` `Description[enUS]`):** removes `", scaling with |cffcfa6ffInsanity|r,"`.
- **Server behaviour kept:** `AscensionCultistAuras.cpp:230` casts `704473` with `0.678496 * SP` only and 0% Insanity
  scaling.
- **Live evidence (`ev1.md`, strength: suggestive):** `LIVE SUGGESTS` 0% Insanity scaling — 2 non-duplicate logs
  (`165, 168`), 1 player (`Jimjonescult`), non-crit `704473` heals stayed flat (`698–702` and `829–834`) while Insanity
  rose from 60 to 100, agreeing with the server.
- **Owner's choice:** `remove_text` (`O-15`, `O-18`) — keep 0% Insanity scaling, remove `"scaling with Insanity"`.

### 6. `Q-cu-21` (`O-15`, `O-18`) — Embrace the Void (`300307`, ledger row 50 claim 0)

- **Current DBC text:** `"Reaching 60 |cffcfa6ffInsanity|r increases your damage dealt by $573285s1% for $573285d."`
- **Approved O-18 text (`300307` `Description[enUS]`):** replaces `"your damage dealt"` with `"your Magic damage dealt"`.
- **Server behaviour kept:** `573285` `Effect[0]` (`aura 79`, `bp = 9 + 1 = +10%`, `EffectMiscValue[0] = 126`) boosts
  Magic schools only and excludes Physical melee (`bit 1`).
- **Live evidence (`ev1.md`, strength: suggestive):** `LIVE SUGGESTS` Physical melee is excluded — 1 log (`141`), 1
  player (`Devzou`), Shadow spells rose `1.095–1.106x` under `573285` while Physical `SWING_DAMAGE` read `1.020x`
  (overlapping noise), agreeing with the server.
- **Owner's choice:** `magic_only` (`O-15`, `O-18`) — keep Magic-only `+10%`, update text to `"Magic damage dealt"`.

### 7. `Q-cu-22` (`O-15`, `O-18`) — Psychic Suppression (`800432`, ledger row 351)

- **Current DBC text:** `"...The target takes $803746s1% more spell damage from all sources while you are channeling this spell."`
- **Approved O-18 text (`800432` `Description[enUS]`):** removes `"spell "` (`"more damage from all sources"`).
- **Server behaviour kept:** `803746` `Effect[0]` (`aura 87`, `bp = 14 + 1 = +15%`, `EffectMiscValue[0] = 127`) amplifies
  all damage schools including Physical.
- **Live evidence (`ev1.md`, strength: strong):** `LIVE SHOWS` Physical damage is amplified by `+15%` — 2 non-duplicate
  logs (`103, 104`), 9 Psychic Suppression boss windows, Physical (`0x1`) hits rose `1.142–1.164x` during Psychic
  Suppression and dropped back immediately afterwards, agreeing with the server.
- **Owner's choice:** `all_damage_text` (`O-15`, `O-18`) — keep all-school `+15%`, update text to `"more damage"`.

### 8. `Q-cu-25` (`O-15`, `O-18`) — Glimpse of Madness / Madness (`500719`, `500767` / `804369`, ledger rows 112 claim 1 & 127 claim 1)

- **Current DBC text (`804369`, embedded in `500719` and `500767` via `@s:804369:0@`):**
  `"Your |cffffffffGaze of C'thun|r$?s805606[ or |cFFFFFFFFObliteration Beam|r][] causes $s1% increased damage, stacks up to $u times."`
- **Approved O-18 text (`804369` `Description[enUS]`):** removes the `$?s805606[...][]` conditional so
  `"Your |cffffffffGaze of C'thun|r or |cFFFFFFFFObliteration Beam|r causes $s1% increased damage, stacks up to $u times."`
  always shows.
- **Server behaviour kept:** `804369` `Effect[0]` (`EffectSpellClassMask[0] = 131072`) unconditionally increases
  Obliteration Beam `805573` damage by `+3%` per stack even without Corrupting Whispers `805606`.
- **Live evidence (`ev2.md`, strength: strong):** `LIVE SHOWS` unconditional `+3%` per stack on Obliteration Beam —
  4 logs (`99, 103, 104, 109`), 3 players (`Xarathun`, `Nastylol`, `Bellagoth`), 16 same-cast identical-debuff target
  comparisons show `+2.82%` to `+3.11%` per Madness stack with 0 `805606`/`706725` events across 186 logs, agreeing
  with the server.
- **Owner's choice:** `always_edit_text` (`O-15`, `O-18`) — keep unconditional server mask, remove conditional text gate.

### 9. `Q-cu-26` (`O-15`, `O-18`) — Darkwither (`502220` and ranks `800446`, `502213`–`502219`, ledger row 355)

- **Current DBC text (all 9 ranks):** `"...stacking up to $?s301317[8][$706913u] times."`
- **Approved O-18 text (all 9 ranks `Description[enUS]`):** replaces `[8]` with `[7]` (`$?s301317[7][$706913u]`).
- **Server behaviour kept:** Withered `706913` (`StackAmount = 4`) + Call of C'Thun `301317` (`SPELLMOD_MAX_AURA_STACKS
  = +3`) caps at `7` stacks.
- **Live evidence (`ev2.md`, strength: strong):** `LIVE SHOWS` 7-stack cap — 5 logs (`99, 103, 104, 109, 141`), 4 players
  (`Xarathun`, `Nastylol`, `Bellagoth`, `Devzou`), 740 `SPELL_AURA_APPLIED_DOSE` events: 11 applications reached stack 7
  and 30 `SPELL_AURA_REFRESH` events occurred at stack 7, with 0 occurrences of stack 8, agreeing with the server and
  with Call of C'Thun's `"stacks 3 additional times"` tooltip.
- **Owner's choice:** `edit_text_7` (`O-15`, `O-18`) — keep 7-stack cap, change `[8]` to `[7]` on all 9 ranks.

## Options

- Keep server code untouched for all nine spells, update conformance expectations to the approved `O-18` client texts,
  record Status 2 (*Conformant by a recorded rule or owner ruling*, `docs/coa/class-conformance.md` §2) in the ledger,
  and apply the `coa_client_spell_description` SQL and `patch-ZG.MPQ` rebuild in the class-end text pass. Chosen per
  owner rulings `O-12`, `O-15`, and `O-18`.
- Change server behaviour to match the unpatched DBC tooltips against live evidence and owner rulings. Rejected by
  `O-12`, `O-15`, and `O-18`.

## Decision

No server C++ changes are made for these nine rulings. Each measurable server behaviour is proved in
`apps/coa-gameplay-test/conformance/classes/cultist.json` against the `O-18` approved text value, and each ledger row in
`apps/coa-gameplay-test/conformance/classes/cultist_clauses.json` records Status 2 (*Conformant by a recorded rule or
owner ruling*) citing the ruling and this ADR.

## Consequences

- `apps/coa-gameplay-test/conformance/classes/cultist.json`:
  - `806382 duration`: measures `807124` held at `5600 ms` (`[5450..5850] ms`) and gone at `6400 ms` (`[6150..6550] ms`)
    with `807219` ally tick count (`5 +- 1` by `5600 ms`), matching 6 s (`Q-cu-15`, `O-18`).
  - `524877 no_insanity_scaling`: new `metric_delta` entry proving tick-1 non-crit `704473` heal ratio `1.00 +- 0.02`
    between 0 and 80 Insanity (`Q-cu-20`, `O-18`).
  - `300307 melee_damage`: expects `1.0` (`+0%`) on Physical white swings alongside `shadow_damage` (`1.1`, `+10%`),
    proving Magic-only (`Q-cu-21`, `O-18`).
  - `800432 phys_control`: expects `2.15 +- 0.02` (`+15%` cumulative ratio on Physical `92559`), proving all-school
    amplification (`Q-cu-22`, `O-18`).
  - `500719` & `500767 beam_damage_without_805606`: expect `2.015 +- 0.002` (`+3%` on 2nd Obliteration Beam without
    `805606`), proving unconditional Madness bonus (`Q-cu-25`, `O-18`).
  - `502220 stack_cap_301317`: expects `7` stacks (`before_expected: 4, tolerance: 0`), proving the 7-stack cap
    (`Q-cu-26`, `O-18`).
  - `805121 spell_hit_str` (`Q-cu-9`) and `680569 ap_base` / `ap_armor` (`Q-cu-4`) already prove the kept server
    behaviours and cite `O-12`, `O-18`, and Cultist ADR 0033. (`300300` Magic dispel is proved by `300300 dispel_crit`
    using Dispel Magic `988`.)
- `apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`:
  - Rows `41` (`300300`), `239` (`680569`), `399` (`805121`), `421` (`806382`), `152` (`524877`), `50` (`300307`),
    `351` (`800432`), `112` (`500719`), `127` (`500767`), and `355` (`502220`) record Status 2 (*Conformant by a
    recorded rule or owner ruling*) citing their ruling ids, `O-18`, and Cultist ADR 0033.
  - Note on `coverage.py` before the class-end text SQL lands: `805121 r399` (`combat_rating` vs `"spell hit chance"`)
    and `680569 r239[0]` (`STATE_PROMISES['attack_power']` on `claims[1]` only) audit as `data` while still proved in
    game; `805121 r399` will automatically promote to `behaviour` once `O-18` SQL updates its text to `"spell hit rating"`.
