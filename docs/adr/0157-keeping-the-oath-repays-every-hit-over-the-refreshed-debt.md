# 0157. Keeping the Oath repays every hit over the refreshed debt

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0155 (supersedes nothing)

## Context

ADR 0155 made one delayed hit pay over all 8 ticks of Oathkeeper 803237. A hit landing during a repayment still went
wrong: `Delay` (`AscensionTemplar.cpp`) added its 40% to the debt and reset the duration to 8000 ms, but not the tick
count or the periodic timer, so `AuraEffect::Update` stopped after `GetTotalTicks()` = 8 ticks counted from the
first hit. For two 1100 hits 3.5 s apart, 613 of the 880 delayed were paid and 267 never taken. The mentor decided on
2026-11-11, from the tooltip ("instead taking it over $803237d"), that the debt must be repaid in full
(`method-study/owner-rulings-2026-11-10.md`, "Keeping the Oath, second hit"). The owner may instead choose one 8 s
schedule per hit.

## Options

- One schedule per hit: each hit's share paid over its own 8 s. The owner's alternative; it needs a store of
  schedules per Templar, not the one aura effect amount the debt uses.
- Raise the tick limit after a refresh. `GetTotalTicks()` reads the maximum duration, which the refresh does not
  change.
- Restart the debt's ticks when a hit refreshes it, and spread the whole remaining debt over the 8 ticks of the
  refreshed duration. Chosen, as the mentor decided.

## Decision

- `Delay` calls `AuraEffect::ResetPeriodic(true)` on 803237's effect after the refresh: the tick number returns to 0
  and the periodic timer to one amplitude, so 8 ticks follow, the last at the refreshed expiry. The tick count of
  ADR 0155 is unchanged.
- Each tick pays `remaining - (ticks - 1) x floor(remaining / ticks)`: the remaining debt divided by the ticks left,
  rounded down, with the integer leftover in that payment. Every later payment of the schedule is then exactly the
  rounded-down share, so the leftover goes into one payment. A tick with no debt left pays nothing and sends no log;
  while debt remains a payment is at least 1.
- Death or removal with debt still owed is unchanged: the outstanding debt is dropped unpaid. No remove handler pays it
  (Barrier of Light's `ReduceDebt(100)` and a full reduction call `Aura::Remove`), 803237 is not death persistent, and
  the tick pays nothing while the Templar is dead.
- Templar code only.

## Consequences

- Gameplay-visible: an Oathkeeper under sustained hits now takes all the delayed damage, 40% of every hit, where part
  of it used to vanish; under repeated hits the debt keeps running until 8 s after the last one.
- Two hits 3.5 s apart: 3 x 55, then 715 as 92 and 7 x 89, 11 payments, 880, the last at 8 s after the second hit.
  Three hits at 0, 2.3 and 7.1 s: 2 x 55, 98 and 3 x 96, then 824 as 8 x 103, 14 payments, 1320.
- One hit: still 8 x 55 (ADR 0155).
- A percent reduction (`ReduceDebt`, Holy Books) during a schedule puts its new leftover into the next payment.
- Regression: catalog scenarios `templar-keeping-the-oath-second-hit` and `templar-keeping-the-oath-third-hit` (count,
  sum, last payment against the refreshed end, nothing paid after it), `templar-keeping-the-oath-debt-spread`, and the
  conformance entries `92109` `delay`, `over` and `706468` `debt`.
