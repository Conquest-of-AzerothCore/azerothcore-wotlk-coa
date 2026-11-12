# Tooltip reading

The rules follow the stock 3.3.5a client parser (wowdecomp `WoW/Source/Ui/QuestTextParser.cpp` and `MathState.cpp`,
evidence rather than authority). Each value is `Displayed(text, value, effect_index, kind, spell_id)`: `text` is the
token as written in the DBC, `value` the number before any player modifier.

| Token | Value | Kind |
|---|---|---|
| `$sN`, `$<id>sN`, `$SN` | `EffectBasePoints + 1`, unsigned, only if `EffectDieSides` is 1 | `percent` before `%`, or `flat` |
| `$mN`, `$MN` (with `<id>`) | `EffectBasePoints + 1`, `EffectBasePoints + EffectDieSides`, unsigned | as `$sN` |
| `$/N;` then `$sN`/`$SN`/`$mN`/`$MN` | divided by N; `$/1000;` followed by `sec` stays in ms | `duration_ms` or as `$sN` |
| `$d`, `$<id>d` | `SpellDuration` `Duration`, capped by `MaxDuration` | `duration_ms` |
| `$tN`, `$TN`, `$<id>tN` | the period of effect N (below), in ms; the client shows seconds | `amplitude_ms` |
| `$h`, `$<id>h` | `ProcChance` | `chance_pct` |
| `$u`, `$i` (with `<id>`) | `StackAmount`, `MaxAffectedTargets` | `count` |
| `$aN` (with `<id>`) | `SpellRadius` radius of effect N | `radius_yards` |
| `$oN`, `$ON` (with `<id>`) | `abs(EffectBasePoints + 1)` of effect N scaled by `duration / period` (`+ period` when `AttributesEx5 & 0x200`; period is `EffectAmplitude[N-1]`, or 5000 ms when that is 0 or unreadable; `QuestTextParser.cpp:830-900`, same case as `$sN`/`$mN`) | as `$sN`, routed through the periodic-total detection below like any other `EFFECT_KINDS` token |
| `${...}` | `+ - * /`, parentheses and the variables below | as `$sN` |
| `$<name>` | a `SpellDescriptionVariables` formula of the spell it is scoped to (below) | as `$sN` |
| `$pplN`, `$<id>pplN` (inside `${...}` only) | `EffectRealPointsPerLevel[N-1] × max(0, caster level − BaseLevel)` | as `$mN` |

Inside `${...}`: `$mN`/`$MN` (signed), `$h $u $i`, `$d` in seconds, `$aN`, `$tN`/`$TN` the period in ms, each with
an optional spell id; `$pplN`/`$<id>pplN` (below); `$AP`, `$RAP`, `$PL`; `$SP` is the lowest spell power of schools
1 to 6, `$sph $spfi $spn $spfr $sps $spa` one school each; `$STR $AGI $STA $INT $SPI` the effective stats 0 to 4;
`$<name>` a variable defined earlier.
`$<name>` resolves against the `SpellDescriptionVariables` formula of the spell most recently named by a `$mN`/
`$MN`/`$sN`/`$SN`/`$aN`/`$tN`/`$TN`/`$<id>...` token earlier in the *same* `${...}` expression, or the described
spell when the expression has not named one yet (`Tooltip.variable`'s `context_spell_id`, cached per spell id in
`Tooltip.variable_cache` so a formula is compiled once even when several tokens reference it). Argent Blade/
Scourgebane 807268's `${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}` names 801832 first, so `$<scalingbp>` resolves
801832's own `$scalingbp=${...}` formula (`SpellDescriptionVariableID` 182 on 801832, 0 on every Argent Blade rank
itself) instead of being unreadable for lack of a variable on the described rank.
`effect_index` is the effect of the first `$sN`/`$mN`/`$MN`/`$tN`/`$TN`/`$aN` of the spell itself in the token (for
`$<name>`, in its formula), otherwise `None`. `spell_id` is the spell of the first `$sN`/`$mN`/`$MN`/`$tN`/`$TN`/`$aN`
of the token, the described spell or another one, and `None` for a token without one (`$h`, `$d`, `$u`, `$i`). The
client reads `$D $H $U $I $AN $SN` as their lowercase forms (`$S` as `$s`: `QuestTextParser.cpp:829-834`), and so does
the reader.
The period of effect N is `EffectAmplitude[N-1]`, or 5000 ms when `ProcFlags & 1` (`QuestTextParser.cpp:977-1001`
for the text, `MathState.cpp:594-615` for expressions; the field is `m_effectAuraPeriod`, `SpellRec.h:78`). It is
unreadable in the text form when `AttributesEx5 & 0x2000` and not `AttributesEx3 & 0x20000000`: the client hastes
that shown period by the player's cast speed, which no metric reads; the expression form is never hasted
(`MathState.cpp`). A period of 0 is unreadable (`EffectAmplitude[N] 0 of spell S`). The client also applies the
player's period modifiers (`Spell_C_ModifySpellValue(..., 19)`); the reader gives the value before them. The
standalone `$tN`/`$TN` text form keeps its own effect's `effect_index`/`spell_id` (the periodic-total detection
below only applies to `EFFECT_KINDS` tokens, never to the period token itself); inside an expression it still
resolves through `math_variable` with both `None`, exactly like `$aN` there. Righteous Tempest 807274 reads `$t1` as
1000 ms, measured after a cast against the live `aura_amplitude_ms`; inside Blade of Faith 803880's
`${($d*1000/$T1)*(...)}`, `$T1` is 3000 and carries no `effect_index`/`spell_id`.
A standalone `$aN`/`$<id>aN` radius token keeps its own effect's `effect_index`/`spell_id` the same way, read
no-combat against `spell_effect_radius` (`SpellEffectInfo::CalcRadius`, no cast needed, unlike the period token).
A class file's `disabled_foreign_effects` list (`[{"spell": <id>, "effect": <n>, "reason": "..."}]`) names a
foreign effect that a class script zeroes at `SpellInfo` load time (`info->Effects[N].Effect = 0`), so raw DBC
alone cannot tell it apart from a live one; `foreign_radius` treats a listed pair as
`unmeasurable: effect <n> of spell <id> is disabled by a server correction` instead of generating a step that
would fail against the live server. Templar: Testament of Hope 1397742's `$704409a1` names effect 0 of 704409,
which `AscensionTemplarContracts.cpp:211` disables (effect 1, the one still applying the aura, carries the
identical `EffectRadiusIndex`). An effect that exists but whose amount an aura script's CalcAmount hook sets later is
not listed here: its read is generated and `compare` reports it `not_measured` from the harness hook count
([value scenarios](value-scenarios.md), ADR 0118).
Color codes `|c........` and `|r` are removed, in either case.
A trailing digit on `$h`, `$d`, `$u`, `$i` (`$h1`, `$d1`, `$u1`, `$i1`) is accepted and ignored: in
`QuestTextParser.cpp`'s token switch, `case 'H'/'h'` (`:804-805`), `case 'D'/'d'` (`:743-744`), `case 'U'/'u'`
(`:1012-1013`) and `case 'I'/'i'` (`:814-815`) never read the digit that follows the letter, so it is a harmless
no-op the client silently consumes. Lightkeeper 560835's `$561277i1` reads `MaxAffectedTargets` of 561277 exactly
like `$561277i` would.

`$?s<id>[<true>][<false>]` and `$?S<id>[<true>][<false>]` evaluate the single `s<id>`/`S<id>` atom against
`CasterStats.known_spells` (empty by default, so every existing scenario reads the false branch exactly as before
this was added) and recurse into the chosen branch's text with the same `Tooltip` instance, so a `$` token inside it
still attributes to the described spell like any other in-line token. An empty chosen branch adds nothing. Any
other `$?` shape — a boolean operator (`!`/`&`/`|`/`(`), an `a<id>`/`A<id>` aura-known atom, or a chained conditional
(`...]?s<id2>[...][...]`, the client's own nested-ternary shape) — stays one `unreadable` entry naming the unhandled
operator or the chain, never guessed. The grammar is `QuestTextParser.cpp`'s `SpellParserConditional` (evidence, not
authority). Eternal Blessing 705300's `$?s573452[...$/1000;806106s1 sec.][]` reads 806106's own effect 0 once
573452 is known; Chastise 803157 and Righteous Tempest 805409's conditionals name their own gating spell's own
effect, static regardless of caster state; Libram of Tenacity 801461's `$?s707385[...$s1%...][]` names its *own*
effect 0, which a live `SPELLMOD_EFFECT1` from 707385 changes at runtime — a value this DBC-only reader cannot
predict, so no check is generated for that one token (its row simply stops being `unreadable` once the false
branch, empty, is read instead; see
[ADR 0039](../../../docs/adr/0039-conditional-tooltip-reads-the-chosen-branch.md)).

`@s:<id>:<flags>@` with `flags` 0 or more expands to the tooltip of spell `<id>`, read by a nested reader of that spell
([ADR 0013](../../../docs/adr/0013-conformance-expands-spell-markup.md)). The header line the client draws before it
(icon and spell name) holds no number. The expanded tokens join `values` at the markup's place, with their own
`text`, `effect_index` `None` and `spell_id` the spell they read: the referenced spell for its own tokens and for
`$d $h $u $i $aN` without an id, the named spell otherwise. Zealotry 92108 thus shows `$s2` 80 of 801450. Their
unreadable parts join `unreadable`. A markup stays unreadable, with its reason, when its flags are negative (the
shift-reveal and partial renderings), when the spell is missing from the DBC set, when it closes a cycle, and when
the nesting is deeper than `MAX_EXPANSION_DEPTH` (3) expansions. A referenced tooltip without a token adds nothing:
Sacred Oath 712346 is then a tooltip without value.

Everything else goes to `unreadable` verbatim and is never guessed: a `$?` conditional with an unhandled operator
or a chained conditional (above), other `@...@` markup, other `|` escapes, other tokens (`$x`, `$l`, `$g`...),
expression functions and variables such as `$BH` or lowercase `$ap`, durations that scale with level
(`DurationPerLevel` not zero), points that scale with level when the skill rank cannot be read (see below), spread
values (`EffectDieSides` not 1 for `$sN`), missing records, non-positive durations, a `$<name>` whose spell (the
one it is scoped to, above) has no `SpellDescriptionVariables` formula of that name, and a stat or school missing
from `CasterStats`. A tooltip with no `$`/`@` token at all, or a `readout.unreadable` entry that is only a client
`@ext:...:ext@` note, is `generic: ` instead (never a number either way, so never guessed; see "No-combat scenario
of a rank" below).

### Level-scaled points

Points with a non-zero `EffectRealPointsPerLevel` read `EffectBasePoints + 1 + EffectRealPointsPerLevel ×
max(0, level − BaseLevel)` (`BaseLevel` subtracted only when positive), as the CoA client binaries compute them
([ADR 0014](../../../docs/adr/0014-level-scaled-tooltip-values-use-the-skill-rank.md), superseding ruling R6 of
ADR 0011). The level is not the character level. `client_spell_level(records, spell_id, caster)` is the skill rank
divided by 5 (integer), and the rank is computed as follows:

- `rank_spell`: a spell with `EquippedItemClass` 2 takes its rank from the weapon-skill spell of the equipped
  weapon (`CasterStats.weapon_subclass`), when the subclass is in its mask and `Targets & 0x10`,
  `AttributesEx2 & 0x8000000` and `Effect[0]` 25 do not exclude it. `weapon_skill_spells(records)` is the client's
  subclass → spell table (Staves: 10 → 227).
- `ability_line`: the `SkillLineAbility` line of that spell for the character's `race` and `class_id`. A row
  counts when `CharBaseInfo` holds the pair, a `SkillRaceClassInfo` row of its line allows it, and the row's
  `RaceMask`/`ClassMask` (inverted by `ExcludeRace`/`ExcludeClass`) allow it. Without a row the rank is 0. Staves
  227 allows only classes 10, 25, 26 and 29, so a Templar's staff spells (Reckoning) read rank 0.
- the rank is `CasterStats.skills[line]`, capped at 5 × `MaxLevel` of the spell it comes from.

Each point is read at the level of the spell it belongs to: the CoA `Extensions.dll` sets the described spell's
level to 0. Staffguard 705295 thus shows `$706583m1` at the rank of 706583, which has no ability row: 125. The
exception is a `$<id>sN` text token whose spell has `AttributesEx2 & 0x1000000`: it uses the character level,
capped at a positive `MaxLevel`.

The entry stays unreadable and names its field and the cause in three cases: the skill line is not measured
(`${$m3+0+$SP*1+$AP*.55} [EffectRealPointsPerLevel[2] of spell 807805: skill 72 is not measured]`), the race or
class is unknown, or several ability lines match. The client adds a temporary skill bonus to the rank;
`skill_value` reads the pure value, and no metric reads that bonus.

### Per-level points (`$pplN`)

`$pplN`/`$<id>pplN` is only ever found inside a `${...}` expression (never as a standalone text token) and reads
`Tooltip.per_level_points`: `EffectRealPointsPerLevel[N-1] × max(0, caster.level − BaseLevel)`, `0` when
`EffectRealPointsPerLevel` is `0`. Unlike `$mN`/`$sN` above, the level it scales by is the **caster's actual
level** (`CasterStats.level`), not `client_spell_level`'s skill-rank-derived level
([ADR 0031](../../../docs/adr/0031-ppl-tokens-scale-by-actual-level-not-skill-rank.md), which does not reopen
[ADR 0014](../../../docs/adr/0014-level-scaled-tooltip-values-use-the-skill-rank.md): `$mN`/`$sN` keep reading the
skill rank). This followed from evidence, not from the token's name alone: none of the custom Templar spells that
carry a `ppl` token have a `SkillLineAbility` row, so `client_spell_level` always resolves to 0 for them and the
skill-rank reading would make every `$pplN` term 0 regardless of `EffectRealPointsPerLevel`. Two of the
2026-11-07 player tooltip readings (Libram of Consecration 801441/803890-803893 and Eternal Blessing 705300) carry
no `$AP`/`$sph` term, so their reported number is a direct check of `$pplN` alone at AP/SP-independent faces;
Libram's reported 188 matches `EffectRealPointsPerLevel × (60 − BaseLevel)` exactly (`4.0 × (60 − 18) = 168`, `+20
= 188`) and would not match a skill-rank reading (which gives 0). `player_tooltip_readings` (below) carries this
citation.

### `$<name>` resolved against the spell it names

`$<name>` used to resolve only against the *described* spell's own `SpellDescriptionVariables` formula, so
Argent Blade/Scourgebane's `${$801832m1*$<scalingbp>+$sph*0.25+$AP*0.25}` stayed unreadable: `scalingbp` is
defined on 801832 (`SpellDescriptionVariableID` 182), not on the described rank (0 on every Argent Blade rank).
The formula text itself already names 801832 first (`$801832m1`), so `ExpressionParser` now tracks the most
recently named spell within the expression and resolves `$<name>` against *that* spell's formulas instead,
falling back to the described spell when none has been named yet (see the token table above).

Streamed texts: the server streams a spell's `Description`, and its `ToolTip` when non-empty, from
`coa_client_spell_description` in place of the client DBC's (`AscensionCompat.cpp`, `BuildSpellPatchRows`), so the
player reads the streamed text. `streamed.py` replays the table's `DELETE` and `INSERT` statements from
`data/sql/updates/db_world` and `pending_db_world` in file order, and `Records.field` returns the streamed
`Description[enUS]` (an empty one blanks the text) or non-empty `ToolTip[enUS]` of a spell with a row; `dbc_field`
keeps the DBC value. Untainted 705298 thus reads `${-$705299m1+$STA*0.1}`, the DBC `${$705299m1+$STA*0.1}`
([ADR 0192](../../../../docs/adr/0192-the-tooltip-reader-prefers-the-streamed-client-text.md)). A class script can
similarly correct a live `SpellInfo` effect without changing `Spell.dbc` at all: Upheave! 520442 effect 0 is
`EffectMiscValue[0]` 7 in the client DBC, but `AscensionTemplarContracts.cpp:130` rewrites it to 15 at load time;
the class file's `effect_overrides` entry (see "Effect overrides" below) makes the reader classify the effective
op instead of the raw DBC one.
