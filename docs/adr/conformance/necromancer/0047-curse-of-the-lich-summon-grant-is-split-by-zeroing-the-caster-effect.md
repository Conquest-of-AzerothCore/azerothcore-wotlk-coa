# 0047. The Curse of the Lich summon grant is split by zeroing the caster effect

- Status: accepted
- Date: 2026-11-13

## Context

Claim 9.1, Curse of the Lich 300240 "increases the Frost critical strike chance of you and your summons by $s2%":
Effect[1] gives the caster aura 71 Frost +3, Effect[2] (190) gives the summons the same aura. A minion's Frost crit
also carries Scale()'s copy of the caster's Frost crit (AscensionNecromancerSummons.cpp:318-320), so a full-talent
read cannot tell which grant reached the summon.

## Options

- One full-talent entry: +3 or +6 on the summon, without knowing the source.
- Three arms on a Ghoul 50073 (raised by 500971 in each phase, the before phase without 300240 as the control): the
  full talent; the talent with Effect[1] set to 0 (harness `set_aura` amount on the learned aura); the same layout read
  through the base copy.

## Decision

The three arms with `owned_creature_school_spell_crit_chance` (ADR 0607, probe Lichfrost 501978):
`summon_school_crit` (expected +3), `summon_school_crit_alone` (+3) and `summon_base_alone`
(`owned_creature_spell_crit_chance`, +0), plus two precondition reads in the zeroed layout: `summon_talent_aura`
(300240 present on the Ghoul) and `caster_crit_alone` (caster Frost crit +0). No new kind.

## Consequences

- Pilot 20261113-180648: the Ghoul carries 300240 under the fixture, the caster's Frost crit stays, the base copy
  gains 0.
- Counted pair 20261113-181149 / -181218: A +6 (alert), B +3, C +0 in both runs. Both grants reach the summon,
  against the tooltip's +3; which one to remove is an owner or mentor ruling. No server change.
