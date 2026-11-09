# 0039. `$?sN` tooltip conditionals read the chosen branch; a SpellMod-dependent own-effect token stays unmodelled

- Status: accepted
- Date: 2026-11-09
- Related: supersedes the unimplemented `round4/unreadable-spec.md` for the same 54 Templar `unreadable`
  verdicts; does not reopen [ADR 0013](0013-conformance-expands-spell-markup.md) (`@s:` expansion, a different
  markup).

## Context

Round 4 left 54 Templar `effect_value` rows `status == "unreadable"`, in four shapes: a tooltip with no `$`/`@`
token at all (18 rows, 14 spells), a `@ext:...:ext@` client note (14 rows, 10 spells), a `$?s<id>[...][...]`
conditional (20 rows, 5 spells), and two rare tokens, `$<id>i1` (a harmless trailing digit on `$i`) and `$o1` (a
periodic-total token, same client case as `$sN`/`$mN`). The owner's ruling requires every verdict judged or
closed with an evidence-backed reason; `unreadable` is neither.

For the `$?` conditional, `QuestTextParser.cpp`'s `SpellParserConditional` evaluates a boolean expression
(`s<id>`/`S<id>` → `player->IsSpellKnown`, `a<id>`/`A<id>` → `HasAuraBySpellId`, with `!`/`&`/`|`/`(...)`) and
re-parses only the chosen branch through the ordinary token parser. All 54 rows in this shape use only a single
`s<id>`/`S<id>` atom. Direct DBC reads of the five gating tooltips (705290, 705300, 801461, 803157×8, 805409×7)
showed every false branch empty, matching the reference Templar (who knows no class spell by default); the four
true branches with a real `$` token resolve to four different models: 705300's names a third spell's own,
state-independent effect; 803157 and 805409's name their gating spell's own, state-independent effect; 801461's
names its *own* effect 0, which 707385 modifies at runtime through a live `SPELLMOD_EFFECT1` SpellMod
(confirmed by reading `SpellEffectInfo::CalcValue` → `Unit::ApplyEffectModifiers` → `ModOwner::ApplySpellMod`,
and by the existing, unrelated `passives.py` generic-modifier scan's own passing row for 707385 → 801461 effect
0, "0 before and 20 after the learn").

## Considered options

1. Evaluate the condition and read the chosen branch's text through the same `Tooltip` instance, keyed on a new
   `CasterStats.known_spells` set (empty by default, so every existing scenario's reading is unchanged).
   Chosen: it is a direct, narrow reading of the client's own grammar, needs no server fix, and the 705300/
   803157/805409 true-branch tokens already flow through the existing `foreign_effect`/own-effect machinery in
   `values.py` with no new code path — only a new call site reached because the reader can now see the token.
2. Keep every `$?...` block `unreadable` verbatim (the status quo). Rejected: fails the owner's "judged or
   closed" bar for all 54 rows, and is less accurate than option 1 for no benefit — the grammar is unambiguous
   stock-client behaviour, not a disputed reading.
3. For 801461's own-effect true-branch token, generate a check anyway (a second scenario that learns 707385,
   comparing the live `spell_effect_value` against this reader's static DBC points). Rejected: this reader has
   no model of a live SpellMod (it is a server-side, runtime-only effect; `CasterStats`/`Records` read only
   static `Spell.dbc` fields), so the "expected" value it would compute (0, the raw `EffectBasePoints`) is
   provably wrong once 707385 is known (the live value is 20); such a check would be a guaranteed false alert,
   which the project's "no invented expectations" rule treats as no better than a false ok. The existing
   `passives.py` generic-modifier scan already covers this exact SpellMod correctly (it reads the modifier's own
   magnitude, not the tooltip text), so no coverage is lost by declining this option.

## Decision

`CasterStats` gains `known_spells: frozenset[int] = frozenset()`. `Tooltip.read` evaluates a `$?s<id>[t][f]`
block by matching the condition against `SINGLE_CONDITION = re.compile(r'[sS](\d+)')`; a match picks `t` when
`int(id) in known_spells` else `f` (empty when absent) and recurses with `self.read(chosen)`, folding the result
into the outer `Readout` at the block's position. Anything else — an unmatched condition (a boolean operator or
an `a<id>`/`A<id>` atom) or a chained conditional (`...]?s<id2>[...][...]`, the client's own nested-ternary
shape, detected by `conditional_bounds`'s existing recursive end-of-block search) stays one `unreadable` entry
naming the unhandled operator or the chain, never guessed.

`value_scenario` gains the same `known_spells` parameter, threaded into `structure_stats`/`CasterStats` and into
an extra `learn` step per gating spell, so the Python-side reading and the live scenario's precondition always
agree. `classes/<name>.json`'s new `conditional_spells` list (`[{"spell": <rank>, "learn": <gating spell>,
"reason": "..."}]`) names, per rank, which gating spell to additionally learn in a second, `value-true`-keyed
scenario (`conformance.py`'s `add_conditional_value`, next to `add_values`, named distinctly per AGENTS.md).
Templar's list carries 16 entries: 705300, the 8 Chastise ranks (503135-503141, 803157) and the 7 Righteous
Tempest ranks (805409, 807269-807274) — all three state-independent. **801461 is deliberately left out of this
list**: no `value-true` scenario is generated for it, so no new check is ever produced for its own-effect true
branch; at the baseline (`known_spells` empty) its `unreadable` row simply stops being generated (the false
branch is empty), which already satisfies "judged or closed" for that row without inventing an unreliable check.

For the no-token shapes: `values.py` gains `GENERIC = 'generic: '` (circular-import-safe, `values.py` cannot
import `hits.UNMODELLED` back) and `EXT_NOTE = re.compile(r'@ext:.*:ext@', re.DOTALL)`. A `readout.unreadable`
entry matching `EXT_NOTE` and the "no token at all" fallback both become `generic: ...` instead of
`unreadable: ...`; `compare.py`'s `judge_expectation` routes `GENERIC` through the same `unmodelled` status as
`UNMODELLED`/`UNMEASURABLE`.

For the two rare tokens: the `digit`-rejecting guard in `spell_token_value` is reordered so a trailing digit on
`h`/`H`/`d`/`D`/`u`/`U`/`i`/`I` (`QuestTextParser.cpp` never reads an index for these four letters) is accepted
and ignored, instead of raising. A new `PERIODIC_TOTAL_LETTERS = 'oO'` branch (same client `case` as `s`/`m`,
confirmed by reading `QuestTextParser.cpp:826-900`) reads `Records.periodic_total`: the effect's own points
scaled by `duration / period` (`+ period` when `AttributesEx5 & 0x200`; `period` is `EffectAmplitude`, or 5000 ms
default when that is 0 or unreadable). Because the resulting `Displayed` carries the same `effect_index`/`kind`
as any other `EFFECT_KINDS` token, it falls through the *existing* `periodic_reason`/`period_reading` empirical
probe in `values.py` with no new dispatch code — `period_reading`'s `ScaledPeriod` re-read already classifies it
`OVER_TICKS` and routes it to the existing `unmeasurable: a total over the ticks of periodic effect <n>; the hit
scenario judges one tick` explanation.

## Consequences

- All 54 of round 4's `unreadable` Templar rows stop being `unreadable` (verified by regenerating the manifest
  for all 30 affected spells and grepping zero remaining `rule.startswith('unreadable:')` rows): 18 + 14 become
  `generic`/`unmodelled`, 20 vanish outright (replaced by 16 brand-new `effect_value` rows on
  705300/803157-family/805409-family, none of them a rename of an old row), and 2 become `unmodelled` via the
  pre-existing `unmeasurable` periodic-total path.
- 801461's conditional contributes zero new coverage of its true branch; this is a known, documented limitation
  (the reader cannot predict a live SpellMod), not a defect — the existing `passives.py` generic-modifier scan
  already covers the same 707385 → 801461 relationship correctly, from a different angle (the modifier's own
  magnitude, not the tooltip text).
- `caster_stats_from` (`profile.py`) and `ManifestWriter.add`/manifest entries (`conformance.py`) gained the same
  `known_spells` passthrough, serialized per scenario entry, so `compare.py`'s `read_tokens` rebuilds the correct
  caster state when re-reading a `value-true` scenario's tokens against the live measurement.
- No server fix, no C++ or SQL change: every edit is Python tool code under `apps/coa-gameplay-test/
  conformance/`.
