# 0540. A taken_hit arm may unlearn a granted passive, and read forced critical strikes

- Status: accepted
- Date: 2026-11-13

## Context

The owner put Resilient Constitution 552011 in Necromancer scope (owner ruling Q-n1, 2026-11-13: "test it against a
player attacker"). Its tooltip reads "Damage taken from other players is reduced. Critical damage taken from players
is reduced by another 20%." The class grants it at level 1 (`AscensionCompatData::ClassSpells`), so every caster
fixture already holds it, and a `taken_hit` control arm cannot leave it out: `set_aura` would remove it, but the
treatment arm would then need `set_aura` to put back the claim's own aura, which the conformance rules allow only as
a precondition fixture. The `damage_ratio` judge read non-critical strikes only, and a player striker had no way to
crit on demand, so the critical clause had no read.

552011 is in no class kit, no combat log event and no live capture, so ADR 0016's `extra_spells` citation (a logged
event or a kit listing) does not exist for it.

## Decision

- A `taken_hit` arm takes `unlearn` and `learn` (spell ids): those spells are unlearned and learned on the caster at
  the arm start, before the arm's `checks`. Resilient Constitution's control arm unlearns 552011
  (`Player::removeSpell` removes its aura) and its treatment arm learns it again (`Player::learnSpell` applies the
  passive); each arm checks the aura absent or present before its strikes. An arm may not learn and unlearn one
  spell, nor touch a spell the entry learns for every arm.
- `critical: true` (`damage_ratio` only) reads the critical strikes instead of the non-critical ones.
  `striker_force_crit` (`"spell"` or `"melee"`, a player striker and a critical read only) gives the player striker
  `FORCED_CRIT_RATING` of that kind.
- An `extra_spells` entry may cite an owner ruling: `owner ruling <question>, <date>`; `test_classes.py` counts such
  entries apart from the logged and kit citations. 552011 is listed with `owner ruling Q-n1, 2026-11-13`.
- The non-critical entry judges the configured reduction (coa.conf.dist `CoA.ResilientConstitution.DamageReductionPct
  50`): the tooltip states no magnitude, so the claim is the direction and the 0.5 is the reading. The critical entry
  is judged as 0.8 x the non-critical ratio of the same build ("another 20%"), and a creature-striker entry is the
  scope control of "from other players" (ratio 1).
- No harness C++ change: `unlearn`, `learn` and the crit rating fields already exist. Entries without the new fields
  generate the same scenarios (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- Necromancer entries 552011 `players`, `player_crits` and `creatures` (class file), two ledger rows at the tail.
- `generate --class 23` gains a value scenario for 552011 because it joins the class spell set.
- Tests: `TakenHitLearnedArmTests` (test_behaviours.py) and the extra-spell citation count (test_classes.py).
