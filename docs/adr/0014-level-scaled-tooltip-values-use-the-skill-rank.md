# 0014. Level-scaled tooltip values use the skill rank

- Status: accepted
- Date: 2026-11-06
- Supersedes: ruling R6 of [ADR 0011](0011-class-tooltip-conformance.md) ("level-scaled values stay unreadable")

## Context

A spell effect with a non-zero `EffectRealPointsPerLevel` shows `EffectBasePoints + 1 + EffectRealPointsPerLevel ×
levels` in its tooltip. ADR 0011 left these values unreadable, because the client derives the level from a skill
value and the scenarios measured none. Every rank of the 172 Templar class spells holds 32 such entries, among them
Divine Force, Reckoning, Vindication, Holy Constitution, Staffguard and Untainted. Four of the 32, and two other
entries, also use `$<id>pplN`, which has no client handler.

### The stock client (wowdecomp, the 3.3.5a 12340 decompilation)

github.com/SatyPardus/wowdecomp, commit 20f9120e0a8f064338ecd9f2dd6cbc01642bf695, read 2026-11-06. It has no
license, so it was used locally as evidence and none of its code is copied here.

- `Spell_C_GetMinMaxPoints` (`Magic/MagicClient/Spell_C.cpp:3643-3670`, OFFSET 0x007FF770) reads
  `level = spellLevel`, and when that is 0 it calls `Spell_C_GetSpellLevel(spell, ...)` for the spell whose points
  it reads. It then subtracts `m_baseLevel` when that is positive, clamps the result at 0, and computes
  `m_effectBasePoints + 1 + m_effectRealPointsPerLevel × level`.
- `Spell_C_GetSpellLevel` (`Spell_C.cpp:3416-3432`, OFFSET 0x007FF070) returns `GetSpellRank(spell) / 5`.
- `CGPlayer_C::GetSpellRank` (`Object/ObjectClient/Player_C.cpp:13583-13614`, OFFSET 0x006DC330) works in steps:
  - It replaces the spell by its weapon-skill spell when `SpellUsesWeaponSkill` says so (`Player_C.cpp:2265-2283`).
    That is the case when `Targets & 0x10` is clear, `AttributesEx2 & 0x8000000` is clear, `Effect[0]` is not 25,
    `EquippedItemClass` is 2 with a non-zero subclass mask, and an equipped weapon's subclass is in the mask.
  - It looks up the `SkillLineAbility` row of the resulting spell with
    `SpellTableLookupAbility(race, class, spell)`, and returns 0 when no row is found.
  - It takes the player's skill value in that row's line and caps it at `5 × MaxLevel` of the resulting spell.
- `InitWeaponSkills` (`Player_C.cpp:620-676`, OFFSET 0x006E0340) builds the subclass → weapon-skill-spell table. It
  walks `Spell.dbc` from its last record to its first, so the lowest record index wins, and keeps passive spells
  (`Attributes & 0x40`) with `EquippedItemClass` 2 and a single-bit subclass mask below the weapon subclass count.
  The count is the highest `ItemSubClass` subclass of item class 2, plus 1 (`GetWeaponSubClassCount`,
  `Player_C.cpp:461`).
- `SpellTableLookupAbility` (`Magic/MagicClient/SpellTable.cpp:248-283`), for the player's own race and class, reads
  only a hash that `SpellTableAddSkillLineRec` (111-153) fills from `CharBaseInfo` × `SkillLineAbility`. A row
  enters the hash only when `SpellTableLookupInfo` (94-110) finds a `SkillRaceClassInfo` row of its line for that
  race and class, and when `SpellTableMatchRaceClass` (52-62) accepts the row's `RaceMask`/`ClassMask`, inverted by
  `ExcludeRace`/`ExcludeClass`.
- `GetSkillRank` (OFFSET 0x006DC2C0) adds the active player's temporary skill bonus to the skill value.
- In `$<id>sN` text tokens (`Ui/QuestTextParser.cpp:650-677`), a foreign spell with `AttributesEx2 & 0x1000000`
  is read at the character level. A foreign spell with `MaxLevel > 0` has the level capped at `MaxLevel`. In
  `${...}` expressions (`Ui/MathState.cpp:917-976`) neither rule applies, and the level is passed on as it is.

### The installed CoA client binaries

These were read on 2026-11-06 in `/mnt/steam/Games/CoA`, CoA client release `descension-names-20260924`
revision 8.

- `Ascension.exe` (sha256 `e7c2a69cb86804eb9e21254b7b45c6a03e532d8b8f94451d9e0855f7535f97c6`) holds
  `SpellParserParseText` at 0x57ABC0. Its bytes begin
  `55 8b ec 8b 45 0c 53 8b 5d 1c 85 db 56 8b 75 08 57 c6 00 00 75 13 8b 4d 18 8b 55 14 51 52 56 e8 8c 44 28 00`.
  The `call` at 0x57ABDF targets 0x7FF070 (`Spell_C_GetSpellLevel`), and its return address is 0x57ABE4. Every
  spell tooltip caller passes `spellLevel` 0 (`UIUtil/Tooltip.cpp:3311, 5816, 6073, 6112, 6778, 6868, 6879`).
- `Extensions.dll` (sha256 `a9ced4ae63c0fe118703039bafd9ae0e5194ec2e9c9620e47a10e3c79e08e52c`) holds at VA
  0x10287D70 the bytes `81 3c 24 e4 ab 57 00 75 03 33 c0 c3 a1 14 40 69 10 ff e0`. That is
  `cmp dword [esp], 0x57ABE4; jne; xor eax, eax; ret; mov eax, [0x10694014]; jmp eax`. At VA 0x10287F75 the DLL
  installs it as a detour of 0x7FF070: `68 70 7d 28 10 6a 07 68 70 f0 7f 00 e8 ...`, that is
  `push 0x10287D70; push 7; push 0x7FF070; call`. The DLL reconstruction
  (github.com/firstoni-dev/ascension-extensions-reconstruction, `src/Ascension/AscInitHooks.cpp:25, 275-280, 326`)
  describes the same hook: "0x7FF070 -> sub_10a77160 returns 0 when called from 0x57ABE4".
- What follows: a spell tooltip is parsed with the described spell's level at 0. Each point read then takes the
  level of the spell it reads, through the fallback in `Spell_C_GetMinMaxPoints`. That call is at 0x7FF7C3
  (return address 0x7FF7C8), so it is not hooked. Own tokens are unaffected. A foreign spell is read at its own
  rank, not at the described spell's level. The DLL renders `@s:` markup through the same 0x57ABC0
  (`AscSpellText.cpp:82, 670`), so expanded spells are read at their own rank too.

### Data that matters for the Templar (`/srv/coa/server-data/dbc`)

- `CharBaseInfo` holds (race 1, class 19).
- `SkillRaceClassInfo` rows 110, 111 and 112 (lines 70, 71, 72) have `ClassMask` 0x40000, which is class 19.
  Row 181 (line 136) allows every class.
- The only `SkillLineAbility` row of Staves 227 (row 9292, line 136) has `ClassMask` 0x13000200, which allows
  classes 10, 25, 26 and 29 only. The weapon-skill spells of subclasses 0-8, 10, 15 and 18 all leave out class 19.
- With the Walking Stick (Item.dbc 2495: class 2, subclass 10), Reckoning (`EquippedItemSubClassMask` 1378,
  bit 10 set) takes its rank from 227. That row is filtered out for a Templar, so the rank is 0, and Reckoning
  572741 `$m1` shows 166 instead of 179.51.
- Staffguard 705295 shows `$706583m1` at the rank of 706583, which has no ability row: 125 rather than 305.
  Untainted 705298 shows `$705299m1` = -10 rather than -41.

## Considered options

1. Keep level-scaled values unreadable (ADR 0011 R6). Rejected: 28 entries stay unchecked, and the base steps now
   give the scenarios measured skills (Decision).
2. The stock rule as the design first quoted it: the described spell's level for foreign spells, with no race and
   class filter. Rejected: the installed binaries contradict it. It reads Staffguard 706583 at the level of
   705295, which gives 305, while the CoA client shows 125. The server's applied amount also starts from 125:
   `AscensionTemplarAuras.cpp:60-63` sets it to 125 + 0.3 × Stamina + 0.25 × (dodge + parry rating). The 305 is
   `SpellEffectInfo::CalcValue`, read before that script.
3. The installed-binary rule (findings above). Chosen: the installed client binaries outrank the decompiled text
   when they disagree. If it is wrong, the affected checks (Reckoning, Staffguard, Untainted, Scarlet Hammer) alert
   rather than pass.

## Decision

- `CasterStats` gains `skills` (skill line → measured value), `weapon_subclass`, `race` and `class_id`.
  `client_spell_level(records, spell_id, caster)` is `spell_rank // 5`, where `spell_rank` follows `GetSpellRank`:
  - the weapon-skill path, using `weapon_skill_spells(records)`;
  - the race and class filter;
  - rank 0 without an ability row;
  - the `5 × MaxLevel` cap of the spell the rank comes from.
- Every `$mN $MN $sN $SN` read uses the level of the spell whose points it reads. The exception is a `$<id>sN` text
  token whose spell has `AttributesEx2 & 0x1000000`: it uses the character level, capped at a positive `MaxLevel`.
- A level-scaled entry stays unreadable, naming its field and the cause, in three cases: its skill line is not
  measured, the race or class is unknown, or several ability lines match. `$<id>pplN` stays unreadable and becomes
  a `tooltip_value` player question: the number the live tooltip shows, with the player's attack and spell power
  (owner answer Q6).
- The base steps set every line in the class file's `skill_lines` to 5 × level with `set_skill`, then measure it
  back with `skill_value` (owner answer Q4: 300 at level 60). The tooltip uses the measured value. `skill_lines`
  holds the `SkillLineAbility` lines of the class spells plus the reference weapon's line (`class_skill_lines`).

## Consequences

- The 28 level-scaled Templar entries without `ppl` become checked values. With measured skills, the 6 `ppl`
  entries are the only level-scaled entries left unreadable, and they reach `questions.md`.
- `skill_value` returns the pure skill value (`GetPureSkillValue`), while the client adds the temporary skill
  bonus. No harness metric reads that bonus, and the README states this limit.
- Not yet confirmed in a live client. The confirming follow-up is a `coa-client-check` that reads the Reckoning
  572741 and Staffguard 705295 tooltips on a level-60 Templar with the Walking Stick: 166 + 0.175 × AP + 0.5 × STA
  and 125 + 0.3 × STA expected. The binaries are the CoA client release, not proven identical to Ascension live.
- `spell_effect_value` reads `SpellEffectInfo::CalcValue`, before aura scripts. Every `effect_value` verdict
  states this in `detail['scope']`: "CalcValue before aura scripts (CalcAmount hooks not covered)". An
  amount set by an AuraScript `CalcAmount` hook is not covered, so a passing value can still differ from the applied
  aura. The 28 newly judged level-scaled `effect_value` checks of the Templar (on 28 ranks) are among the 377
  `effect_value` checks the note covers. The probe's Staffguard alert (305 against 148.7) is such an artifact: it is
  not a server defect, and an `aura_amount` check on a present aura is the remedy.
- Known divergence, kept: the reader reads the client DBC, which is what players' tooltips show unless the
  client is patched. The server overrides Untainted 705298's description
  (`rev_20261029_240_templar_untainted_tooltip.sql`, `coa_client_spell_description`) to `${-$705299m1+$STA*0.1}`.
  The client DBC reads `${$705299m1+$STA*0.1}`.
- ADR 0011 is not edited. This ADR supersedes its ruling R6 only.
