# 0031. Owner ruling Q-cu-12 (O-17): Void-Touched keeps one stack after Gaze of C'Thun

- Status: accepted (owner ruling Cultist Q-cu-12 / O-17, 2026-11-25)
- Date: 2026-11-25

## Context

Void-Touched `300286` (server `Spell.dbc`, `Description[enUS]`): "Direct healing done now applies Void-Touched.
@s:301982:0@ When you cast Gaze of C'Thun, all stacks are consumed to heal all allies affected by Void-Touched for
${$301983m1+$301983ppl1+$BH*0.35}, increased based on how many stacks were on them."

In `cultist_spells::OnSpellBeforeEffects` (`src/server/coa/AscensionCultistAbilities.cpp:94-106`), when a Cultist casts
Gaze of C'Thun (`500110`) or Devouring Gaze (`680576`), the server heals every ally carrying `301982` via `301983`,
removes the consumed `301982` aura, and immediately calls `MarkVoidTouched(player, ally)` (`:105`), which re-applies 1
stack of Void-Touched `301982`.

Archived live combat logs from the original CoA realms (29 logs, 10+ players) show 4,452 immediate re-applications of
Void-Touched `301982` out of 5,095 Gaze of C'Thun consumptions, confirming that the live game re-applied 1 stack right
after consumption.

On 2026-11-25 (owner ruling `O-17`, card `Q-cu-12`), after reviewing the live log evidence alongside the tooltip, the
owner ruled `keep_one`: keep the server re-applying one Void-Touched stack immediately after Gaze of C'Thun consumes
them, and leave the client tooltip text unchanged.

## Options

- Keep `MarkVoidTouched(player, ally)` in `src/server/coa/AscensionCultistAbilities.cpp:105` and leave client tooltip
  text unchanged, recording the kept deviation from the literal tooltip as Status 2 (*Conformant by a recorded rule or
  owner ruling*, `docs/coa/class-conformance.md` §2). Chosen by owner ruling `O-17` (`Q-cu-12`).
- Remove `MarkVoidTouched(player, ally)` so stacks drop to `0` after Gaze of C'Thun. Rejected by owner ruling `O-17`
  because live logs overwhelmingly show immediate 1-stack re-application (4,452 of 5,095).
- Change client tooltip text to mention re-applying 1 stack. Rejected by owner ruling `O-17` (client text stays
  unchanged).

## Decision

Keep `MarkVoidTouched(player, ally)` (`src/server/coa/AscensionCultistAbilities.cpp:105`) untouched and leave client
tooltip text unchanged. No server C++, SQL, or DBC change is made for `Q-cu-12`.

## Consequences

- Kept deviation from the literal tooltip (`"all stacks are consumed"`): allies retain 1 refreshed stack of `301982`
  immediately after Gaze of C'Thun consumes their stacks, matching archived live behaviour (4,452 of 5,095 across 29
  logs and 10+ players).
- In `apps/coa-gameplay-test/conformance/classes/cultist_clauses.json`, `Row[32]` (`300286`) keeps `kind: "claim"` and
  records Status 2 (*Conformant by a recorded rule or owner ruling*) under owner ruling `O-17` (`Q-cu-12`, 2026-11-25,
  Cultist ADR 0031) for the stack-retention part, alongside the proven heal formula (Cultist ADR 0018).
- In `apps/coa-gameplay-test/conformance/classes/cultist.json`, `300286 gaze_consume_base` expects `1` stack of `301982`
  in its `ally_arm` (control `0` without `300286`, tolerance `0`) with `O-17` / `Q-cu-12` cited in `source` and
  `observe_source`, guarding the ruled behaviour; the temporary `300286 gaze_heal_base` split is removed.
- Regression (counted pair `cu-rfix42-prove` `20261125-094043` / `20261125-094117`, build `0a0822d00f1f`, 0 flips):
  `300286 behaviour_metric_delta gaze_consume_base` read `spell_heal_total` `0 -> 364` and `ally_arm` `301982 aura_stacks`
  `0 -> 1` in both runs (`ok/ok`); all 7 `300286` entries (`apply`, `duration`, `max_stacks_ten`, `max_stacks`,
  `gaze_consume_base`, `gaze_consume_sp`, `gaze_consume_5stacks`) read `ok/ok`.
