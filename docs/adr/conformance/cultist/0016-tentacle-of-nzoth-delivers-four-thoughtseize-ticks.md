# 0016. Tentacle of N'Zoth delivers all four Thoughtseize damage ticks

- Status: accepted (owner ruling O-15 Q-cu-32, 2026-11-25)
- Date: 2026-11-25

## Context

Tentacle of N'Zoth 572103 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Target an enemy and summon
a Tentacle of N'Zoth on the ground near them that will silence them and deal
`${$806596m2+$806596ppl2+$SP*.75}` Shadow damage every `$806596t2` sec for `$806596d`. If your target runs out of range,
the tentacle will seek a new target. The tentacle gains health based on your Stamina. If the tentacle dies, the silence
effect will end. You may only have 1 Old God Tentacle active at a time."

Effective `Spell.dbc` and `pending_db_world` data:

- `572103`: `DurationIndex 31 = 8000 ms`, `Effect[0] = SPELL_EFFECT_SUMMON` (28), `MiscValue = 501464`,
  `MiscValueB = 63` (`SUMMON_TYPE_TOTEM`).
- `806596` (`Thoughtseize`): `DurationIndex 31 = 8000 ms`, `Effect[0] = SPELL_AURA_MOD_SILENCE` (27),
  `Effect[1] = SPELL_AURA_PERIODIC_DAMAGE` (3), `Amplitude = 2000 ms`, `BasePoints = 60`, `DieSides = 5`,
  `RPPL = 2.0`, `BaseLevel = SpellLevel = 32`, `AscensionCultistData.h:116` `0.75 SP`.
- Every `2 sec` for `8 sec` yields 4 periodic ticks (at level 60 with `887013` +12% class tuning: `[524..540]` at 0 SP,
  `[3884..3900]` at +1000 SP).
- `rev_20260909_12_cultist_completion.sql:310-311` registers `spell_ascension_cultist_ability` on `572103`; no value
  override exists on `572103` or `806596`.

Before this fix, counted pair `20261125-060244` / `20261125-060311` (build `eb39f0e31481`, 0 flips) measured:

- `572103 behaviour_metric_delta damage_base`: `405` / `402` (`spell_damage_count = 3`) vs 4-tick band `[520..546]`
  (alert).
- `572103 behaviour_metric_delta damage_sp` (+1000 SP): `2916` / `2925` (`spell_damage_count = 3`) vs 4-tick band
  `[3875..3910]` (alert).

Two interacting causes in `src/server/coa/AscensionCultistSummons.cpp` (since initial commit `e36bc50aad`) cut off the
4th tick:

1. `npc_ascension_cultist_summon::IsSummonedBy` (`AscensionCultistSummons.cpp:156`) scheduled the first `Pulse` at
   `+100 ms`, applying `Thoughtseize` (`806596`) at `t = +100 ms` with periodic ticks at `+2100, +4100, +6100, +8100 ms`.
2. At `t = +8000 ms`, `Totem::Update` (`Totem.cpp:38-41`) expired `501464` and called `UnSummon()`, triggering
   `cultist_summon_lifecycle::OnCreatureRemoveWorld -> ai->ClearThoughtseize()` (`AscensionCultistSummons.cpp:334-339`),
   which removed `806596` 100 ms before tick 4 fired.
3. Even with `806596` applied at `t = 0 ms`, unconditionally clearing `806596` inside `OnCreatureRemoveWorld` on natural
   timed expiry would still race the target's `t = 8000 ms` periodic tick depending on map object update order.

Live evidence (`ev2.md`): 3 summons of `572103` in live log 67 each delivered 4 `806596` ticks within 7.83-7.97 s
(caveat: all 3 had Eternal Grasp rank 1 extending tentacle lifetime). The project owner ruled (`O-15` `Q-cu-32`,
2026-11-25): deliver 4 ticks.

## Options

- Apply `Thoughtseize` (`806596`) immediately on summon (`t = 0 ms`) via `DoAction(3)` from `Summon()` for `501464`,
  explicitly clear `Thoughtseize` on early Old God tentacle replacement and owner death/out-of-range/phase-mismatch, keep
  unconditional `ClearThoughtseize()` in `JustDied`, and skip `ClearThoughtseize()` in `OnCreatureRemoveWorld` only when
  the summon leaves the world due to natural timed expiry (`Expired()`).
- Extend `501464`'s summon lifetime beyond 8000 ms (e.g. +200 ms). Rejected: contradicts the 8 sec duration in
  `Spell.dbc`, shifts `duration` checks, and would interact with Eternal Grasp duration scaling.
- Only remove the 100 ms pulse delay without guarding `OnCreatureRemoveWorld`. Rejected: leaves a same-tick (`t = 8000 ms`)
  update-order race between `Totem::Update` despawning `501464` and the target ticking `806596` #4.

## Decision

In `src/server/coa/AscensionCultistSummons.cpp`:

1. Include `"Totem.h"` so `Expired()` can read `Totem::GetTotemDuration()` (for `501464`) and `TempSummon::GetTimer()`
   (for `500464`).
2. Extract `npc_ascension_cultist_summon::ApplyThoughtseize(Player*)` and invoke it immediately from `Summon()` via
   `DoAction(3)` right after `SetGUID` for `entry == 501464`, scheduling the next `Pulse` at `6000 ms`.
3. Track `lastDiff` in `UpdateAI`, call `ClearThoughtseize()` before `DespawnOrUnsummon()` on owner death/range/phase
   loss, and clear an existing `501464`'s `Thoughtseize` via `DoAction(4)` inside `Summon()` before replacing it with a
   new Old God tentacle.
4. Add `npc_ascension_cultist_summon::Expired() const` (true only when alive, owner alive/within 100 yd/same phase, and
   remaining duration `<= std::max<uint32>(lastDiff * 2, 200)`), and gate `cultist_summon_lifecycle::OnCreatureRemoveWorld`
   on `!ai->Expired()`. `JustDied` continues to call `ClearThoughtseize()` unconditionally.

No shared engine, DBC, SQL, or client text changes.

## Consequences

- `Tentacle of N'Zoth` (`572103`) now applies `Thoughtseize` (`806596`) at `t = 0 ms` and delivers all 4 periodic damage
  ticks while keeping the 8 sec silence duration and immediate silence removal when the tentacle dies, is replaced by
  another Old God tentacle, or loses its owner.
- No other class is reached. Reached Cultist spells (`802044` 7/7 checks, including `replaces_nzoth`, and Presence of
  N'Zoth catalog scenario `apps/coa-gameplay-test/scenarios/cultist-presence-of-nzoth-back-tentacle-8638.json`) were
  rerun with 0 readings moved (`cultist-presence-of-nzoth-back-tentacle-8638.json`: `VERIFY ALL: PASSED`,
  `20261125-091750`).
- Regressions (`prove-C`, runs `20261125-091639` and `20261125-091709`, build `98a7e36003c4`, 16/16 ok, 0 flips):
  - `572103 damage_base`: `532.0` / `528.0` (4 ticks both runs, band `[520..546]`, control uncast `0`, ok/ok),
  - `572103 damage_sp`: `3884.0` / `3884.0` (4 ticks both runs, band `[3875..3910]`, control uncast `0`, ok/ok),
  - `572103 silence`, `tick_period` (`2005.0` / `2005.5 ms`), `duration` (`7509` / `8418 ms`), `duration_contrast`,
    `max_one`, `replaces_yshaarj`, `stamina_health_arms`: all ok/ok.
- Ledger row `572103` alert `reason` removed; `prove-C/fragment.json` audits all 3 claims of row `572103` as `behaviour`.
