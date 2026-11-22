# 1017. A scripted crit read proves a crit claim with its partner arms

- Status: proposed
- Date: 2026-11-22
- Supersedes: the "No `CONTRAST_PROOF` row for `spell_done_crit_chance_scripted`" bullet of
  [ADR 1014](1014-four-harness-metrics-take-their-evidence-rows.md). The rest of ADR 1014 stands.

## Context

Sun Cleric crit talents live only in the CoA crit hook, `OnSpellCritChance` in
`src/server/coa/AscensionSunClericAbilities.cpp`: Gift of the Sun 680618 (Holy, target above 80% health), 300343
(target below 20% health), 704909 (against Undead), and the "always crits" branches of 680621, Gavels with 680645 and
500141 with 707517. The unscripted `spell_done_crit_chance` read cannot see them. `spell_done_crit_chance_scripted`
reads `Unit::SpellDoneCritChance` passed through `ScriptMgr::OnSpellCritChance` on a probe `Spell`; ADR 1014 classed it
as a readback with no contrast row, so a learned-contrast verdict of it stayed data.

The engine's own roll (`Spell.cpp`, after "totem's inherit owner crit chance") calls `SpellDoneCritChance`, then
`OnSpellCritChance`, then `SpellTakenCritChance`, on live state. The probe (`CoAGameplayTest.cpp`) calls the first two
in the same order with the same player, target and spell, on the live auras and target state. This is the footing of
[ADR 0691](0691-a-spell-crit-read-proves-a-crit-claim-with-its-learned-contrast.md) plus the one hook where these
talents live.

The cases where such a read must not count:

1. The hook reads per-cast state the probe lacks: the probe is built with `TRIGGERED_NONE`, never prepared, has no
   targets, no triggering aura and no script values. The Sun Cleric hook reads caster auras, target health percent,
   creature type and a target aura only (code reading).
2. The real roll uses `m_attackType` (ranged for `DmgClass` 3 and auto-repeat wands, off hand for melee spells with
   `SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON`) and `m_originalCaster` or the totem owner; the probe passes `BASE_ATTACK`
   and the player.
3. A clause that does not promise crit.
4. A conditional clause proven by one arm: "on enemies above 80% health" with only the above arm would pass a server
   that ignores health; a zero-gain arm alone would pass a server that never applies the talent.
5. The probe omits `SpellTakenCritChance`: the read proves the done side only.

## Options

- Keep ADR 1014: every hook-only crit talent stays data.
- A `CONTRAST_PROOF` row with the crit words only, as ADR 0691: closes cases 3 and 5 by words, leaves case 4 open.
- The row, the crit words, a partner gate for this metric only and generator refusals for case 2.

## Decision

The third option (mentor D-52, controller approval).

- `coverage.CONTRAST_PROOF['spell_done_crit_chance_scripted'] = LEARNED_CONTRAST` and
  `coverage.STATE_PROMISES['spell_done_crit_chance_scripted'] = CRIT_WORDS`.
- Partner gate (`coverage.PARTNERED_CONTRASTS`, `coverage.partners_hold`), applied to this metric only. A learned
  verdict of it counts as behaviour only when the same ledger row's conformant learned verdicts of the metric
  (`claim_evidence`'s `row_labels`, the labels of every claim of the row) hold:
  - a non-zero expected gain;
  - when the claim or row text is conditional (`coverage.CONDITIONAL_WORDS`), also a zero expected gain, the arm
    whose fixture breaks the condition.

  The gain is the verdict's `expected`, which `compare.metric_gain_verdict` sets to the entry's `expected_gain`.
- The conditional words err on the side of requiring the zero-gain arm: a false match only asks for one more arm. A
  conditional clause the words miss is a review finding, not a pass.
- Generator refusals (`behaviours.require_scripted_crit_probe`, `NotModelled`) for this metric: a probed spell of
  `DmgClass` 3, an auto-repeat (wand) spell, a melee spell that requires the off hand, a read on another actor than the
  player, and an entry without `expected_gain`.
- Stated review check: a pet, totem or guardian spell read as the player cannot be detected from the DBC (no field
  names the real caster). The entry's `observe_source` states the real caster and that the hook reads no per-cast
  state (case 1); the review checks both.
- The same one-arm hole exists for the `spell_done_crit_chance` row. That is an observation; it is not changed here.

Sun Cleric ledger rows whose labels use the metric at this commit (the reviewer's list):

| Spell | Row | Labels | Conditional |
|---|---|---|---|
| 680618 Gift of the Sun | "... by $s1% on enemies above 80% health." | `above` (gain 50), `below` (gain 0) | yes |

The other hook clauses of the class (300343 "on targets below 20% health", 704909 "against Undead", 707517 "on
allies affected by Bless") use no entry of this metric yet; the conditional words mark each of them conditional
(`test_the_conditional_words_mark_every_hook_clause_of_the_sun_cleric`).

## Consequences

- Tests: `test_coverage.py` `ScriptedCritPartnerTest` (both arms, one arm, zero arm alone, unconditional clause,
  condition contrast, non-crit clause, a partner of another metric, a partner in another claim of the row, the word
  list) with two mutants: the gate removed passes the one-arm row, and the row removed keeps the paired arms at data.
  `test_behaviours.py` `ScriptedCritProbeRefusalTests` covers each refusal. The ADR 1014 readback test no longer
  asserts the missing row.
- Generation of the finished classes is unchanged: Templar (`--class 19`, with and without `--stack`), Necromancer
  (`--class 23`) and Witch Hunter (`--class 15`) regenerate byte-identical at this commit; no finished class uses the
  metric.
- Number provisional: shared ADRs are numbered at merge.
