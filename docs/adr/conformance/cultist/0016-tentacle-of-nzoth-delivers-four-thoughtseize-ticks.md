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
  unconditional `ClearThoughtseize()` in `JustDied`, and in `OnCreatureRemoveWorld` pass a remaining-duration grace
  threshold derived from `Thoughtseize`'s DBC periodic amplitude (`Effect[1].Amplitude = 2000 ms`) when `Expired()` holds,
  removing any `Thoughtseize` aura with remaining duration strictly greater than that margin while passing `0` on
  non-natural removal.
- Skip `ClearThoughtseize()` unconditionally whenever `Expired()` holds. Rejected: on an extended `500464` (Presence of
  N'Zoth `803037` -> `500707` extended from `8000 ms` to `10000 ms` / `12000 ms` by Eternal Grasp `704878`/`704879` or
  Teachings of Mythrax `561035`, pulsing every `2000 ms`, which re-applies a fresh `8000 ms` `806596` at `8100 ms`) or
  on `501464` after target re-acquisition at `6000 ms`, skipping removal leaves `4–6 s` of silence and periodic damage on
  the enemy after the tentacle has despawned.
- Extend `501464`'s summon lifetime beyond 8000 ms (e.g. +200 ms). Rejected: contradicts the 8 sec duration in
  `Spell.dbc`, shifts `duration` checks, and would interact with Eternal Grasp duration scaling.
- Only remove the 100 ms pulse delay without guarding `OnCreatureRemoveWorld`. Rejected: leaves a same-tick (`t = 8000 ms`)
  update-order race between `Totem::Update` despawning `501464` and the target ticking `806596` #4.

## Decision

In `src/server/coa/AscensionCultistSummons.cpp`:

1. Include `"SpellAuras.h"` and `"Totem.h"` so `Expired() const` can read `Totem::GetTotemDuration()` (for `501464`) and
   `TempSummon::GetTimer()` (for `500464`) and `ClearThoughtseize(int32 graceMs = 0)` can inspect `Aura::GetDuration()`.
2. Extract `npc_ascension_cultist_summon::ApplyThoughtseize(Player*)` and invoke it immediately from `Summon()` via
   null-checked `DoAction(3)` right after `SetGUID` for `entry == 501464`, scheduling the next `Pulse` at `6000 ms`.
3. Track `lastDiff` in `UpdateAI`, call `ClearThoughtseize()` before `DespawnOrUnsummon()` on owner death/range/phase
   loss, and clear an existing `501464`'s `Thoughtseize` via null-checked `DoAction(4)` inside `Summon()` before replacing
   it with a new Old God tentacle.
4. Derive the same-tick natural-expiry margin from `Thoughtseize` (`806596`)'s `Spell.dbc` periodic amplitude
   (`Effect[1].Amplitude = 2000 ms`) in `ExpiryGrace() const`:
   `std::min<uint32>(std::max<uint32>(lastDiff * 2, amplitude / 10), amplitude / 2)` (`200 ms` at normal server ticks,
   hard-capped strictly below half a periodic interval at `1000 ms`).
5. Add `npc_ascension_cultist_summon::Expired() const` (true only when alive, owner alive/within 100 yd/same phase, and
   remaining summon lifetime `<= ExpiryGrace()`). Change `ClearThoughtseize(int32 graceMs = 0)` to remove each afflicted
   target's `Thoughtseize` aura whenever `graceMs <= 0 || aura->GetDuration() > graceMs`. In
   `cultist_summon_lifecycle::OnCreatureRemoveWorld`, always call
   `ai->ClearThoughtseize(ai->Expired() ? int32(ai->ExpiryGrace()) : 0)`. `JustDied` continues to call
   `ClearThoughtseize()` (`graceMs = 0`) unconditionally.

No shared engine, DBC, SQL, or client text changes.

## Consequences

- `Tentacle of N'Zoth` (`572103`) applies `Thoughtseize` (`806596`) at `t = 0 ms` and delivers all 4 periodic damage
  ticks while keeping the 8 sec silence duration and immediate silence removal when the tentacle dies, is replaced by
  another Old God tentacle, or loses its owner.
- When either `501464` (e.g., after re-acquiring a target at `6000 ms`) or an extended `500464` (Presence of N'Zoth with
  Eternal Grasp `704878`/`704879` or Teachings of Mythrax `561035`) expires naturally while a freshly re-applied
  `Thoughtseize` still has `> ExpiryGrace()` remaining (`~4100–6100 ms`), `OnCreatureRemoveWorld` removes that
  `Thoughtseize` immediately so the silence and DoT never outlast the tentacle.
- No other class is reached.
- Regressions (`cu-fix41-rfix-primary`, runs `20261125-095634` and `20261125-095706`, build `9c723b19bf36`, 21/21 ok,
  0 flips):
  - `572103 damage_base`: `528.0` / `524.0` (4 ticks both runs, band `[520..546]`, control uncast `0`, ok/ok),
  - `572103 damage_sp`: `3884.0` / `3892.0` (4 ticks both runs, band `[3875..3910]`, control uncast `0`, ok/ok),
  - `572103 presence_eternal_grasp_expiry`: Presence of N'Zoth (`803037`, `forced_roll`, triggered by instant `502122`)
    with Eternal Grasp R2 (`704879`, `+50%` -> `500707` `8000 ms` -> `12000 ms`): uncast control `0`; at `11509 ms`
    (window `11300..11800 ms`) `owned_creature_count(500464) == 1`, `aura(806596) == 1`, `spell_damage_count(806596) == 5`
    (`floor((12000 - 100) / 2000) = 5` ticks); at `12724 ms` (window `12400..13000 ms`, `724 ms` after despawn)
    `aura(806596) == 0` in both runs (ok/ok),
  - `572103 silence`, `tick_period` (`2006.0` / `2006.0 ms`), `duration`, `duration_contrast`, `max_one`,
    `replaces_yshaarj`, `stamina_health_arms`: all ok/ok.
- Ledger row `572103` alert `reason` removed and `presence_eternal_grasp_expiry` added to the `for $806596d` claim;
  `cu-fix41-rfix-primary/fragment.json` audits all 3 claims of row `572103` as `behaviour`.
