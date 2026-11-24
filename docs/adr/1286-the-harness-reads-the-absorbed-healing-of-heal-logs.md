# 1286. The harness reads the absorbed healing of heal logs

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

Felsworn parts 102.0 and 103.0 (Oppressive Ruin 561201) promise that "Damage dealt by Ruin now absorbs the next
${$801895m2+$801895ppl2} healing on the target", up to the rank 7 value of 501297. In the server DBC set, Ruin's
Effect[1] is aura 301 `SPELL_AURA_SCHOOL_HEAL_ABSORB` (MiscValue 127) on the hostile target, 99 for 801895 and 226 for
501297, and 561201 is a +8000 ms `SPELLMOD_DURATION` on Ruin, whose own DurationIndex is 0.

The server already reports the absorbed healing: `Unit::SendHealSpellLog` writes `HealInfo::GetAbsorb()` into
`SMSG_SPELLHEALLOG`, and the periodic heal branch of `Unit::SendPeriodicAuraLog` writes `pInfo->absorb`.
`ObserveSpellHealing` skipped that field, and dropped every log whose heal is 0. `HealInfo::AbsorbHeal` lowers the heal
by the absorbed amount, so a heal that a heal absorb took whole was never recorded. Reading the target's health around
a heal (design 1, fw-vb2) could not separate Ruin's random damage.

Mentor ruling D-91 item 4 (2026-11-24) approved, after a reviewed G-39 note, a harness change limited to recording
an existing value. Review fw-rg39 (2026-11-24) asked to state that periodic logs are read and to decide the `critical`
filter explicitly.

Options considered: filling the absorb into the existing `spellHeals` list and pushing logs with heal 0 into it
(refused: `spell_heal_count`, the `owned_creature_heal_*` metrics and the `spell_heal` event-time stream would see
new events); a health read around a fixed heal (design 1, refused above); a separate list of every heal log that
reports healing or an absorb, read by one new metric (chosen).

## Decision

- `SpellHealEvent` carries `absorb`, read from the heal log instead of skipped.
- `Actor::spellHealLogs` keeps every direct and periodic heal log whose heal or absorb is positive. The `spellHeals`
  list and every metric that reads it keep exactly the events they had.
- New metric `spell_heal_absorb_total`: the summed absorb of the `spellHealLogs` of `spell`, cast by the player or by
  the `caster` unit, optionally on `target` and with the `critical` filter. Unlike `spell_absorb_total` (direct damage
  logs only) it reads periodic heal logs too, because aura 301 is consumed by periodic heals as well. It refuses
  `pet`, `caster_entry` and `target_pet`.
- `coverage.METRIC_EVIDENCE` classes it `EVENT`, as `spell_absorb_total` and `spell_heal_total`. No judge, tolerance,
  evidence class or closing key changes.

## Consequences

- A heal-absorb promise is read from the logs of a heal landing on the absorbing unit; a learned arm against a
  not-learned control attributes the absorb, since the log names no absorber.
- No server code changes; finished classes regenerate byte-identical because no existing entry uses the metric.
- Necromancer Life For Power 705746 (aura 301) amounts now appear in `spellHealLogs`; nothing of that class reads it.
