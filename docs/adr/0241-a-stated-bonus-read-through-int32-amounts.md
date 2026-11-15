# 0241. A stated bonus read through int32 amounts

- Status: accepted, amended 2026-11-12 (see Amendment)
- Date: 2026-11-12
- Extends: ADR 0239

## Context

The side a re-review of R3 (lean/r3-review-a.md, R-M1) kept one minor open: Radiant Blade 524822 and 525080
("Increases the effectiveness of Oath: Righteous Lunge by $s1%", 25% and 50%) were judged on the derived ratio of
Oath and talent over no Oath, so the band was 5% of +45.22% and +55.15% (about +-2.3 and +-2.8 points), not the ruled
+-2 and +-2.5 points of the talent's +25% and +50%. ADR 0239's stated-unit judge reads a ratio back through a
continuous model, but the engine truncates each scaled amount to int32 (`SpellEffectInfo::CalcValue`): 5 x 1.25 =
6.25 -> 6, 30 x 1.25 = 37.5 -> 37. Read back continuously, the engine's own amounts give +22.7%, below the +23% floor,
although the integer-truncation ruling of 2026-11-11 accepts them.

## Options

1. ADR 0239 as it stands, expected set to the continuous 1.0703: the truncated amounts alert.
2. The engine's truncation inside the stated model: the ratio is a step function of the bonus, and the reading names
   the int32 amounts.
3. Keep the derived-ratio band.

## Decision

Option 2. `stated` takes `truncated: true`. The ratio becomes prod(1 + int32(part x (1 + bonus)) / 100) /
prod(1 + part / 100), and the expected ratio must equal it at the stated bonus. The 99% interval is read back as the
bonuses that give a ratio inside it:
- `alert` when no ratio of int32 amounts lies inside it, or no bonus inside the band gives the amounts read;
- `ok` when every bonus that gives them lies inside the band, or when the interval holds one step that a bonus inside
  the band gives (the engine resolves no finer);
- `insufficient_trials` when it holds several steps and reaches outside the band.

The band stays the stated value's (5% or 2 points). The verdict's low and high are the bonuses whose amounts pass. The
Radiant Blade entries compare Oath and talent against the Oath alone, as Combat Training does, expected 1.0639 (rank 1,
amounts 6 and 37) and 1.1366 (rank 2, 7 and 45).

## Consequences

- Rank 1: amounts 6 and 37 come from +23.3% to +26.7%, inside +23% to +27%. Rank 2: 7 and 45 come from +50% to
  +53.3%; the band ends at +52.5%, and no read can tell 52.5% from 53% because both give the same amounts.
- A bonus inside the band whose amounts differ from the stated bonus's passes (rank 1's 6 and 36 come from +20% to
  +23.3%, and +23% to +23.3% lies in the band). The ruling's band, not the stated value's own step, decides.
- Seeded tests: the stated step passes on both ranks; amounts no bonus inside the band gives alert (5 and 35, the
  Oath alone, rank 1's amounts under rank 2); a ratio between two steps alerts; a wide interval across steps is not
  judged; an expected ratio off the truncated amounts is refused.
- Entries without `truncated` regenerate byte-identical. The two Radiant Blade scenarios change (their control arm
  and model) and are rerun twice.

## Amendment (2026-11-12)

### Context

The misc review (lean/misc-review.md, A-I1) found that the one-step `ok` branch passed amounts the engine does not
give at the stated bonus. Both stored R3 verdicts of 524822 (pair 20261112-045309 / -050012) printed a pass range of
+20% to +30%: rank 1's amounts 6 and 36 (+20% to +23.3%) and 6 and 38 (+26.7% to +30%) read ok, although the ruled
band is +23% to +27% and the measurement resolves those steps. Rank 2 printed +46.67% to +53.33%, its lower edge from
7 and 44. That contradicts ADR 0145 (one below only where a per-roll value truncates to it), the integer-truncation
ruling of 2026-11-11 (the engine's computation reproduces the observed value) and the tool rule of the per-level
ruling (ok only when the full engine computation reproduces the read exactly; a same-size mutant still alerts).

### Decision

`ok` only on the stated step: the int32 amounts the engine computation gives at the stated bonus.
- `ok` when the 99% interval holds one engine step and its amounts are the stated bonus's;
- `alert` when it holds no ratio of int32 amounts, one step with other amounts, or several steps without the stated
  one;
- `insufficient_trials` when it holds the stated step and another.

The band no longer decides. The verdict's low and high are the bonuses that give the stated amounts: +23.33% to
+26.67% (6 and 37) and +50% to +53.33% (7 and 45).

### Consequences

- Seeded mutants one amount off the stated step alert: 6 and 36, 6 and 38 (rank 1), 7 and 44, 7 and 46 (rank 2).
  Several steps that leave the stated one out alert. Under the first decision the first three read ok.
- The Consequences bullet that let a bonus inside the band pass with other amounts is withdrawn.
- The stored pair re-judged without rerunning: 524822 ok in both runs, pass range +20%-+30% before, +23.33%-+26.67%
  after; 525080 ok in both runs, +46.67%-+53.33% before, +50%-+53.33% after. No other status of the 367 labels moved.
- `engine_amount` nudges by 1e-6 before truncating, so where two parts cross an integer at the same bonus (+20% on
  5 and 30) the model holds a step about 2e-5 points wide (6 and 35). The stated steps are not at such a bonus.
