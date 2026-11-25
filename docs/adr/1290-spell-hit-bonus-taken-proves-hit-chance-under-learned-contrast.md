# 1290. `spell_hit_bonus_taken` proves a target spell-hit claim only under a learned contrast

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25

## Context

Cultist Mind Rot 300300 (row 42 claim 0) and Eldritch Screams 525049 (row 159 claim 0) both state:
"Increases the chance for allies to hit with all spells against the afflicted enemy by $560943s1%". The harness
already implements `spell_hit_bonus_taken` (`CoAGameplayTest.cpp:4132-4138`, `run.py:175,1381`), which calls
`unit->GetTotalAuraModifierByMiscMask(SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE, info->GetSchoolMask())` on the live
target, the exact query `Unit::MagicSpellHitResult` (`Unit.cpp:4011`) calls at hit-resolution time. It is not
recomputed from DBC fields (in fact it reproduced the Mind Rot 560943 `EffectMiscValue[0] = 0` defect where the DBC
effect value read +3 while the live target modifier read 0 on Shadow, Fire and Nature).

However, `coverage.METRIC_EVIDENCE` omitted `spell_hit_bonus_taken`, so any class file entry referencing it failed
`test_coverage.py` and the audit could not classify the read.

Under G-21 point 2, a live unit modifier read counts as behaviour only when it comes from the engine's use-time call
after a real application with a learned/unlearned contrast on one build and matches the claim's subject. Orchestrator
decision D-39 approved registering `spell_hit_bonus_taken` with the same `READBACK` + `CONTRAST_PROOF` (`learned`) +
`STATE_PROMISES` guard pattern used for `spell_taken_crit_chance` (ADR 0800).

## Decision

- Add `'spell_hit_bonus_taken'` to `coverage.METRIC_EVIDENCE` as `READBACK`.
- Add `'spell_hit_bonus_taken': LEARNED_CONTRAST` to `coverage.CONTRAST_PROOF`.
- Add `'spell_hit_bonus_taken': r'hit chance|chance (?:for allies )?to hit'` to `coverage.STATE_PROMISES`.
- A `spell_hit_bonus_taken` verdict counts as `behaviour` only when it is conformant, carries `detail.contrast ==
  'learned'` (real learn between before and after phases), and its clause or row names hit chance or chance (for
  allies) to hit. Any uncontrasted read, condition-only contrast, or non-hit-chance clause remains `data`; an `alert`
  or `unmeasured` verdict remains `unproven`.

## Consequences

- Opt-in audit-table addition: zero change to scenario generation; finished classes regenerate byte-identical.
- Mind Rot 300300 and Eldritch Screams 525049 can now record `metric_delta` `spell_hit_bonus_taken` entries in
  `cultist.json` (producing live alerts `0` against `+3` on unfixed builds, and `behaviour` once `560943`'s school mask
  fix merges).
- Seeded tests in `test_coverage.py` cover `ok` with learned contrast (`behaviour`), non-learned contrasts (`data`),
  non-hit-chance clauses (`data`), `alert` and `unmeasured` (`unproven`), and missing-row refusal (`EvidenceError`).
