# 0770. A minion proc trigger can command its pet and summon at the dummy

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 238.0 (Shadow Rage 804192, "Auto attacks have a $h% chance to deal an additional ... Shadow
Damage") needs a `proc_rate` entry on the Shadowhound's auto attacks. The c15-a author found two gaps in the
`minion` trigger: the Shadowhound 50124 raised by Houndmaster's Whistle 801343 (Effect[0] 56 SPELL_EFFECT_SUMMON_PET)
never swings when only the caster attacks the dummy (0 trials), and Houndmaster's Call 802273 is refused when the
setup cast goes to the caster instead of the dummy. The `cast_period` kind already sends a pet attack command
(`pet_attack`, ADR 0743). Mentor decisions D-248 / D-249 (item T6).

## Options

- Two opt-in fields of the minion trigger: `pet_attack` (boolean) adds the harness pet attack command at the dummy
  after the caster's attack in each attempt block; `summon_target` (`caster`, the default, or `dummy`) picks the
  target of the setup cast.
- Always commanding the pet: changes the scenarios of every minion trigger, Necromancer included (D-195).
- A separate trigger action for pets: duplicates the minion trigger's plan, fixtures and reads.

## Decision

The opt-in fields, checked in `checked_minion_trigger` (a non-boolean `pet_attack` or another `summon_target` is
refused) and applied in `minion_setup_steps` and `minion_attempt_steps`, so every kind that uses the minion trigger
accepts them; the proc trial rule names them (`minion_command_note`).

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the pet attack step follows every caster attack only when asked and the rule names it; the setup
  cast goes to the dummy only with `summon_target` `dummy`; other values are refused. Mutant: a commanded minion
  proc judged at half its 50% chance alerts, at the chance it is ok.
- Witch Hunter: with `pet_attack` the Whistle hound swings (diagnostic run 20261116-103403: 320 trials in part 1,
  against 0 before). The 804192 entry is not yet counted: the `minion_auras` fixture sets 804192 with the hound as
  its own caster, and Shadow Rage strikes only for an aura cast by the Witch Hunter (StrikeShadowRage reads
  `Owner(rage->GetCaster())`), so 0 events and the aura read (caster the player) is 0; that needs another option.
