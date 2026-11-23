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
- Restart the debt's ticks and its periodic timer when a hit refreshes it (`ResetPeriodic(true)`), so 8 payments
  follow each hit, the last at the refreshed end. Built first, then dropped after review: every delayed hit reset
  the timer to a full second, so hits less than 1 s apart, routine on a tank, suspended the payments until the last
  hit and then charged the whole debt in the next 8 s.
- Reset the tick count only (`ResetTicks()`), keeping the timer: payments keep their one-second cadence across hits,
  and the remaining payments spread the new debt. Chosen (option (a), mentor, 2026-11-11, after the re-review).

## Decision

- `Delay` calls `AuraEffect::ResetTicks()` on 803237's effect after the refresh: the tick number returns to 0, so
  up to 8 more ticks follow, and the periodic timer keeps its phase. The ADR 0155 count spreads the whole remaining
  debt over the ticks the refreshed duration still covers, so it is paid in full by the refreshed end. The last
  payment lands on the original one-second phase, up to 1 s before the refreshed end, not at it.
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
- Payments land every second while hits arrive, whatever their spacing.
- Two hits 3.5 s apart: 3 x 55, then 715 as 92 and 7 x 89 at 4 to 11 s, 11 payments, 880, the last 0.5 s before the
  refreshed end. Three hits at 0, 2.3 and 7.1 s: 2 x 55, then 98 and 4 x 96 at 3 to 7 s, then 728 as 8 x 91 at 8 to
  15 s, 15 payments, 1320, the last 0.1 s before the refreshed end. Ten hits 0.5 s apart from 0 to 4.5 s: one
  payment each second from 1 to 12 s, 4400.
- One hit: still 8 x 55 (ADR 0155).
- A percent reduction (`ReduceDebt`, Holy Books) during a schedule puts its new leftover into the next payment.
- Regression: catalog scenarios `templar-keeping-the-oath-second-hit`, `templar-keeping-the-oath-third-hit` and
  `templar-keeping-the-oath-rapid-hits` (payment count each second, sum, last payment within 1 s before the refreshed
  end, nothing paid after it), `templar-keeping-the-oath-debt-spread`, and the
  conformance entries `92109` `delay`, `over` and `706468` `debt`.
