# 0155. Keeping the Oath pays its debt over every remaining tick

- Status: accepted
- Date: 2026-11-11

## Context

Keeping the Oath 92109 reads "You now delay 40% of direct damage taken, instead taking it over $803237d." and
Oathkeeper 803237 "40% of damage taken is now delayed and dealt to you over 8 seconds." (DurationIndex 31, 8000 ms;
Effect[0] periodic, amplitude 1000). A 1100 hit delays 440 exactly, but the trial measured the 440 paid in 7
payments, all by 7.5 s, while the debt lasted to 8 s; 8 payments appeared once in 16 debt trials. The mentor decided
on 2026-11-11 that this is an off-by-one in Templar code against a stated duration and approved the fix
(`method-study/owner-rulings-2026-11-10.md`).

Cause, by code reading. The 803237 tick (`AscensionTemplarAuras.cpp`) paid `ceil(remaining / ticks)` with
`ticks = GetDuration() / 1000 + 1`. `Aura::Update` takes the whole update step off the duration
(`SpellAuras.cpp:753-758`) before `AuraEffect::Update` fires the tick (`:743-745`), so at tick k the duration reads
8000 - 1000k - o, where o is how far the update overshot the tick. With o = 0 the count is right; with any
overshoot it is one short, and the last share is paid a tick early. The split therefore depended on the clock.

A tick does fire at the 8000 ms expiry: `Aura::Update` clamps the duration to 0, `AuraEffect::Update` still ticks
while `GetDuration() >= 0` (`SpellAuraEffects.cpp:1035`), tick 8 is within `GetTotalTicks()` = 8000 / 1000
(`:1040-1044`, `:7423-7437`), and `Unit::_UpdateSpells` removes expired auras only after every aura update
(`Unit.cpp:4657-4665`). The 8th payment the trial saw once, by 8.5 s, is that tick.

A second hit during a repayment: `Delay` (`AscensionTemplar.cpp`) adds its share to the debt and resets the duration
to 8000 ms, but resets neither the tick count nor the periodic timer. The ticks keep the first hit's schedule and stop
after 8 in all; the refreshed debt then stays until 8 s after the second hit without paying, and the rest of the debt
is never paid.

## Options

- Count the ticks left from the tick number, `GetTotalTicks() - GetTickNumber() + 1`. Clock-independent, but after a
  second hit it would pay the whole debt by the 8th tick: it changes the second-hit behaviour, which the mentor kept
  out of this fix.
- Round the duration up, `(GetDuration() + 999) / 1000`, as `ReduceDebt` does. It gives the same short count as
  before whenever the duration is not a whole number of seconds, which is the failing case.
- Count the ticks the duration still covers from the tick's own schedule: the current tick, plus every later tick
  of the periodic timer that falls within the remaining duration.

## Decision

The tick computes `later = GetDuration() - GetPeriodicTimer()`, the time between the next scheduled tick and the
debt's end, and pays over `ticks = later < 0 ? 1 : 2 + later / GetAmplitude()`. The periodic timer already holds
the overshoot (`m_periodicTimer += m_amplitude` runs before the tick), so the overshoot cancels and the count no
longer depends on the update step. Templar code only.

## Consequences

- One hit: 8 payments of 55 for a 440 debt, one per second, the last at the 8000 ms expiry; nothing lost and the sum
  exactly the delayed amount, in every trial whatever the clock step.
- A second hit: unchanged behaviour. The ticks still stop at 8 counted from the first hit, the debt still outlives its
  last payment and the remainder is still lost; only the shares change (for 440 + 440 at 3.5 s: 3 x 55, then 90, 90,
  90, 89, 89, 613 paid). The lost amount moves with the shares: with a non-zero overshoot the old count paid 63, 63,
  63, then 87, 87, 87, 86, 86, 622 paid and 258 lost (code reading, not measured), against 267 lost now. For a
  second hit that lands less than the overshoot after a tick, the old count was also one short; the new one is not.
  ADR 0157 later repays a second hit in full.
- `ReduceDebt`'s one-tick branch shortens the duration by 1000 ms; the new count follows it, as the old did.
- Regression: catalog scenarios `templar-keeping-the-oath-debt-spread` (per trial 7 payments and 385 at 7.5 s with
  the debt present, 8 and 440 at 8.5 s with the debt gone, payments 1000 ms apart) and
  `templar-keeping-the-oath-second-hit` (8 payments, none after, 613 paid, the debt present until 8 s after the second
  hit); conformance entries `92109` `delay` and `over` (clause 1).
