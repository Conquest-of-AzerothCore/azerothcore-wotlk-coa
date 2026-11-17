# 0571. A truncated single-part ratio may be judged by its amount band

- Status: accepted
- Date: 2026-11-13
- Amends: ADR 0239, ADR 0241 (int32 engine steps for a stated bonus)

## Context

Plague Protection 570046, "Increases the effectiveness of your Wards by $s1%" (138.0): Fetid Ward's +10% healing
received becomes the int32 amount 11, a ratio 1.11 / 1.10 = 1.00909. The engine-step judge passes only when the
99% interval holds that exact step ratio. Every run reads 0.03-0.09% under it (pair M 1.0085 / 1.0087, c1 1.0082 /
1.0088, cycle 3 1.0087 / 1.0090) with a half-width of about 0.0008, so the c1 run 1 interval (1.0074 to 1.0089)
missed the step and alerted. The mentor ruled 138.0 status 1 by the G-19 band, not by an interval that must hold the
exact value; the offset is recorded as an untraced observation.

## Decision

- A `hit_ratio` entry with `stated` `{"truncated": true, "band": true}` and one part reads the ratio as the aura
  amount on that part, ((ratio) x (1 + part / 100) - 1) x 100, and judges its 99% interval against the int32 amount
  the stated bonus gives, in the band of 5% of that amount: `ok` inside, `alert` outside, `insufficient_trials` across
  an edge. Several parts or an untruncated statement are refused.
- 570046 `fetid_ward` uses it: amount 11, band 10.45 to 11.55. The amount without the talent (10) and with a doubled
  talent (12) fall outside.

## Consequences

- Entries without `band` judge as before (Templar `generate --class 19` unchanged: no entry names it).
- Tests: `EngineAmountBandTests` (test_compare.py): a reading under the exact step and at it pass; no talent and a
  doubled talent alert; an interval across the lower edge is not judged.
