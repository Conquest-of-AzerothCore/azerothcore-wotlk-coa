# 0741. A rank hit can sum a weapon percent and a school part

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 359.0 (Quickdraw 806851, "Unleash a quick shot, dealing $s1% Ranged Weapon Damage") has no hit
label: the final12 manifest holds `806851 hit_mean` as unmodelled ("effects of several hit models: ['school',
'weapon']"), so no hit scenario was written. Gap design H10 asked to read the cause first: it is the model, not the
caster aura gate (`required_aura_steps` already sets Quickdraw 680244, the spell's CasterAuraSpell, before each
cast). Mentor ruling D-201.

## Options

- An opt-in class-file list `weapon_school_hits`: a listed rank with one weapon percent effect and one school damage
  effect is the school hit plus the weapon percent part, the composite script hits already use
  (`script_weapon_part`, `expected_hit(weapon_part=...)`).
- The D-16 weapon-percent-only model: Quickdraw has a school part too, so it does not fit.
- Modelling every such rank: it would turn unmodelled hits of the finished classes into judged ones.

## Decision

The opt-in list. The weapon part takes the ranged attack power for a ranged weapon spell (`weapon_attacker`); a
listed rank whose tooltip shows no weapon value, or one with a learned weapon part, is refused.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); neither class
  file holds the list.
- Seeded tests: unlisted, Quickdraw stays unmodelled; listed, its model shows both values and a tooltip mean above the
  school value; the mutant that drops the weapon part is refused instead of judged on the school part alone.
- Witch Hunter: `806851 hit_mean`. Pilot 20261116-064910: 183 usable hits, mean 362.96 against the model 364.20
  (99% interval), ok.
