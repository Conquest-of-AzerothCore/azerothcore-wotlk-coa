# 1120. A hit period can make real setup casts before its trigger

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0552 (`hit_period`)

## Context

`hit_period` sets each fixture aura to one stack and takes no setup cast. Spirit Eclipse 811117 strikes once per
Spirit every 250 ms and removes its aura after the last hit (AscensionWitchDoctorAuras.cpp:285-296), so one fixture
Spirit gives one hit and no period. Five Spirits come from a real Mirage 501136, which makes the caster invisible, so
the dummy must also detect invisibility (the 811117 `spirit_hits` repair). Tool note of cycle 8 (B12).

## Decision

`hit_period` takes an optional `setup_casts` list of `{actor, spell, target, wait_ms}` (actor and target `caster` or
`dummy`), made after the control read and before the trigger, each followed by its wait. A caster cast gets the base
mana (or its flat cost) and a cooldown reset first, and its spell is learned at the start. An optional `learn` list
is learned at the start with the trigger, so a talent that changes a period has a treatment entry beside a control
entry without it (Dark Loa's Blessing 560545 makes Shadow Puppets 501087 tick every 600 ms instead of 750 ms; cycle 9
tool gap of B14).

## Consequences

- Opt-in: without the field the steps and the contract are unchanged; classes 19 (with and without `--stack`) and 23
  generate byte-identical scenarios.
- Witch Doctor 811117 `eclipse_period` judges the 250 ms tick spacing of five real Spirits; 560545 `puppets_period`
  and `puppets_period_control` judge 600 ms with the talent and 750 ms without.
