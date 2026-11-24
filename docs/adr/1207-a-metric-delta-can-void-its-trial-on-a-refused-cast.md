# 1207. A metric delta can void its trial on a refused cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Learning Light 300360 ("Lasts for $301265d or 3 casts"): the charge-count scenarios spaced Illumination 500143
casts 1600 ms apart, shorter than its 2000 ms cast time (Spell.dbc), so one cast per phase was refused with reason 105
and the count was off. The judge of a `metric_delta` entry never reads the run's `cast_failures`, so the refusal went
unnoticed and the readings were judged as alerts. Mentor ruling D-204.

## Options

- Add `cast_failure` reads for every setup cast: a harness and scenario change, and it still would not change a verdict.
- An opt-in flag that reads the result's existing `cast_failures`: Python only.

## Decision

An opt-in `void_on_cast_failure` in `metric_delta_options`: its option verdict hook sets `unmeasured` when
`cast_failures` lists a refusal. Refused for a `cast_failure` metric.

## Consequences

- Absent by default: no entry of an existing class writes it; the finished classes regenerate byte-identical.
- Seeded test: a refused setup cast gives `unmeasured`, a clean run is judged, the mutant without the flag judges the
  refused run.

## Addendum 2026-11-22: power refill between setup casts (mentor D-206)

The first counted pair of Learning Light 300360 showed a second cause: Illumination 500143 costs 30% of the mana pool
(Spell.dbc ManaCostPercentage 30) and the harness sets the pool once before the setup casts, so the fourth Illumination
was refused with NO_POWER (85); `void_on_cast_failure` voided the trial instead of alerting. An opt-in
`refill_power_after_setup_casts` (`{"power": type}`) sets the power to `cast_power` after every setup cast, with the
existing `set_power` step, through the `setup_cast_steps` point. The builder refuses it for a power metric or a quote
about mana, cost or a resource (a refill would feed the measured thing), and the contract says it is used. Absent by
default; the finished classes regenerate byte-identical.

## Addendum 2026-11-23: power held during the wait (Felsworn Sargeras Embrace)

Sargeras Embrace 800355 has ManaPerSecond 30 Energy (Spell.dbc). `Aura::Update` drains it every 1000 ms and removes the
aura when the pool is below the amount (SpellAuras.cpp:771-801); the harness sets the pool once to 100, so the channel
ended near 4000 ms and the 5500 ms end damage never landed. An opt-in `hold_power_during_wait`
(`{"power": type, "every_ms": N, "count": N}`) sets the power to `cast_power` every `every_ms` after the trigger cast,
with the existing `set_power` step, through the `after_trigger_steps` point. The builder refuses it for a power metric
or a quote about mana, cost or a resource (a refill would feed the measured thing), and the contract says it is used.
Absent by default; the finished classes regenerate byte-identical.
