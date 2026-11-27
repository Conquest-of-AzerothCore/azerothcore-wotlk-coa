# Once per aura proc (`behaviour_metric_delta`, `kind: "once_per_aura_proc"`, ADR 1325, provisional)

ADR 1325 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a defensive or reactive aura's triggered effect (`proc_spell`) can occur at most once per aura application
and resets when the aura is reapplied, contrasted against a control strike without the aura active. Zero harness C++
changes: reuses passive striker casts, `set_health`, `set_combat_avoidance`, `cancel_aura`, `aura`, `cast_failure`,
`spell_log_count`, and event-class proc metrics (`spell_heal_count`, `spell_damage_count`, `spell_energize_count`,
`spell_cast_count`, `aura_apply_count`).

## Scenario and judgement

- **Fixtures:** Caster with `allow_regeneration: false`, optional `caster_auras` (`[spell, stacks]` precondition
  fixtures, plus automatic `CasterAuraSpell` via `required_aura_steps`), and a passive `striker` creature casting
  `strike_spell` at `caster` (`dodge/parry/block = 0`) after setting caster health to `strike_health / strike_max_health`.
- **Control arm:** One strike lands before `spell` is cast; `aura(spell)` must be `0` and `proc_metric` delta must be `0`
  (any proc alerts).
- **Application 1, hit 1:** Casts `spell` on `caster` (`cast_failure == 0`, `aura == 1`), sets health to `strike_health`,
  lands strike 1: `aura(spell)` must stay `1` and `proc_metric` must increment by `+1`.
- **Application 1, hit 2:** Resets health to `strike_health` while the same `spell` aura is still active, lands strike 2:
  `aura(spell)` must stay `1` and `proc_metric` must increment by `+0` (proving once-only suppression within the same
  application).
- **Application 2, hit 3:** Cancels `spell` (`aura == 0`), resets cooldown and re-casts `spell` (`cast_failure == 0`,
  `aura == 1`), resets health to `strike_health`, lands strike 3: `aura(spell)` must stay `1` and `proc_metric` must
  increment by `+1` (total `2`, proving the once-per-aura gate resets on reapplication).
<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:a87554f3006705bf9906e312e24747fa419aa3156eccc48ffb6f4ae2de23c13a -->

- **Precondition guards:** Check each phase in order. A measured proc violation returns `alert` immediately.
  A missing read, dirty baseline, missed strike, or failed cast or cancel returns `unmeasured` if reached first.

<!-- /coderabbit-ai-generated:v1 -->
- **Evidence class:** `proc_metric` (default `spell_heal_count`, `event` in `coverage.METRIC_EVIDENCE`, counted as
  `behaviour`).

Bloodmage: Endure the Curse `681190` (`proc_spell: 681189`, `strike_spell: 41394`, `strike_health: 10500`,
`strike_max_health: 100000`, `caster_auras: [[33143, 1], [524861, 1]]`).
