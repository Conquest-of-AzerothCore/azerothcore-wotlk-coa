# Debuff resist rate (`behaviour_metric_delta`, `kind: "debuff_resist_rate"`, ADR 1268, provisional)

ADR 1268 has a provisional number and is renumbered at merge (guide 14.4).

A raised chance to resist harmful effects ("your chance to resist the next Curse or Magic effect on you is increased
by 100%") read from real strikes. A stationary striker (creature 36, no spell hit bonus, `striker_level` or the
class level) casts `strike_spell` at the caster; each trial reads whether it took hold (`aura`) 300 ms later and
removes it, and removes `clear_auras` before every strike (precondition fixtures, named in the contract).
`base_chance_pct` is the stock chance p, derived in the entry from the engine formula, never from a run.

- `mode: "rate"` (default): control trials, then a real learn of `spell`, then treatment trials at full health and
  low-health trials at `low_health_pct`. Expected shares: p, 1 - (1 - p)^2 and p. Each arm, pooled over `parts`, is
  judged by its Wilson 99% interval inside the G-20 band; `residual` (default 1e-3) is the probability per counted
  pair of 2 runs that a conformant server fails the claim, so each arm is sized to leave its band with probability
  at most `residual` / 6 per run: the smallest trials per part whose exact binomial false-fail through the judge
  (every resisted count the judge does not pass) meets it, stated per arm in the contract. Labels `<suffix>`
  (control and treatment) and `<suffix>_low_health` (control and low health).
- `mode: "lockout"`: a real learn first; per trial a priming strike, primed when `lockout_aura` is on the caster
  300 ms later. `locked_trials` per part strike again `locked_gap_ms` after the primed read: primed trials resist at
  p, the others at 1 - (1 - p)^2: each group's Wilson interval at the z of `residual` / 12 holds its chance and its
  Wilson 99% interval excludes the other (minimum trials per group sized for `residual`), and the primed share of
  the locked trials holds (1 - p) p in the same wide interval (a lockout started by anything but the second roll's
  resist alerts). The contract states the computed false-fail probability per pair (holds, a group below its
  minimum, an interval keeping the other chance); an entry above `residual` is refused. `expiry_trials` per part
  read `lockout_aura` at `lockout_ms - expiry_margin_ms` and `lockout_ms + expiry_margin_ms` after the priming
  strike: on every primed trial it is held, then gone. Labels `<suffix>` and `<suffix>_expiry`.
