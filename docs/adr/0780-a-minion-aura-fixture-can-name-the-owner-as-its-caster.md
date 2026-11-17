# 0780. A minion aura fixture can name the owner as its caster

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 238.0 (Shadow Rage 804192 on the Shadowhound, "Auto attacks have a $h% chance to deal an additional
... Shadow Damage") needs a `proc_rate` entry on the hound's auto attacks. ADR 0770 made the Whistle hound swing, but
the `minion_auras` fixture set 804192 with the hound as the aura's own caster (harness `set_aura` without `caster`), and
Shadow Rage strikes only for an aura whose caster has a player owner, as a real Shadowblast 804191 grants it. The
diagnostic run 20261116-103403 read "aura 804192 absent" and no event in all 60 parts. Mentor decisions D-250 / D-251
(item T6b), owner delegation O-12.

## Options

- An optional `"caster": "owner"` key in a `minion_auras` fixture: both `set_aura` steps of the fixture (removal and
  application) carry `caster: caster`, so the aura belongs to the minion's owner and only that aura is removed.
- Applying the aura by a real Shadowblast cast in every refresh window: a second cast stream inside the trials, with its
  own rage, cooldown and failure modes, for a grant that `705455 behaviour_metric_delta hound_grant` already counts.
- Always casting minion fixtures by the owner: changes the Necromancer scenarios (Chomp 707283 Anointed fixture, D-195).

## Decision

The opt-in key, checked in `checked_minion_trigger` (any other value, or a value without the key's documented form,
is refused) and emitted in `minion_aura_steps`, so every kind that uses minion fixtures accepts it. The fixture stays a
precondition: the entry's source names the counted label that proves the real grant.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the owner key is accepted and other values refused; the fixture's removal and application steps carry
  the caster only when asked. Mutants: an owner-cast fixture whose hound never strikes alerts; a fixture aura read as
  absent (the hound-cast failure of the diagnostic run) is not counted and the verdict is not `ok`.
- Witch Hunter: `804192 proc_rate` entry (60 parts), its fixture naming `705455 behaviour_metric_delta hound_grant`,
  the hound's 706332 spell hits left out of the trials (`trial_excluded_spells`, not auto attacks).
