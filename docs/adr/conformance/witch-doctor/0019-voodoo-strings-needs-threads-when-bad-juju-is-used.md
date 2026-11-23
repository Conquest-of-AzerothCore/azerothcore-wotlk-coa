# 0019. Voodoo Strings needs Puppeteer's Threads on the enemy when Bad Juju is used

- Status: accepted
- Date: 2026-11-21

## Context

Voodoo Strings 705910: "When Bad Juju is used on enemies affected by Puppeteer's Threads, it strikes an additional time
every $706898T1 sec for 30% of the damage dealt over $706898d as Nature damage." The Puppeteer proc runs inside the
Juju's hit (Spell.cpp ProcSkillsAndAuras) before the class hook `OnSpellHitResult`, so the Threads the Juju's own hit
lays were already on the enemy when the hook checked them, and every Juju struck. The cycle 10 sweep 20261121-203210
(build be33fc85) read 3 strikes on a dummy that had no Threads when the Juju was cast, against the expected 0.

## Decision

- `OnSpellCalculatedTarget`, which runs at the Juju's launch before any of its damage, marks the doctor's Threads aura
  on the target with the script value `Strings`.
- The strike in `OnSpellHitResult` needs a marked Threads aura. Threads laid by the Juju's own hit are a new, unmarked
  aura.
- The amount, 30% per strike, is unchanged; the live 10% per strike reading is an open claim.

## Consequences

- Regression: catalog `witch-doctor-voodoo-strings-threads-at-use` and the class entry `705910 threads_at_use`.
- Fix note: cycle 10 decision M-62.
