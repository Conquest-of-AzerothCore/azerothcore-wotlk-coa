# Debuff resist rate (`behaviour_metric_delta`, `kind: "debuff_resist_rate"`, ADR 1268, provisional)

ADR 1268 has a provisional number and is renumbered at merge (guide 14.4).

A raised chance to resist harmful effects ("your chance to resist the next Curse or Magic effect on you is increased
by 100%") read from real strikes. A stationary striker (creature 36, no spell hit bonus, `striker_level` or the
class level) casts `strike_spell` at the caster; each trial reads whether it took hold (`aura`) 300 ms later and
removes it, and removes `clear_auras` before every strike (precondition fixtures, named in the contract).
`base_chance_pct` is the stock chance p, derived in the entry from the engine formula, never from a run.

- `mode: "rate"` (default): control trials, then a real learn of `spell`, then treatment trials at full health and
  low-health trials at `low_health_pct`. Expected shares: p, 1 - (1 - p)^2 and p. Each arm, pooled over `parts`, is
  judged by its Wilson 99% interval inside the G-20 band; the trials per part are sized so a conformant server
  leaves an arm's band with probability at most `residual` (default 1e-3). Labels `<suffix>` (control and
  treatment) and `<suffix>_low_health` (control and low health).
- `mode: "lockout"`: a real learn first; per trial a priming strike, primed when `lockout_aura` is on the caster
  300 ms later. `locked_trials` per part strike again `locked_gap_ms` after the primed read: primed trials resist at
  p, the others at 1 - (1 - p)^2, each Wilson 99% interval holding its chance and excluding the other (sized for
  `residual`). `expiry_trials` per part read `lockout_aura` at `lockout_ms - expiry_margin_ms` and
  `lockout_ms + expiry_margin_ms` after the priming strike: on every primed trial it is held, then gone. Labels
  `<suffix>` and `<suffix>_expiry`.
