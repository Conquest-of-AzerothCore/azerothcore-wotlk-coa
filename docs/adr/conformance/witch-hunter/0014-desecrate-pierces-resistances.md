# 0014. Desecrate pierces resistances

- Status: accepted
- Date: 2026-11-16

## Context

Desecrate 680518 and ranks 681207-681211 read: "Desecrate up to $i enemies in front of you, dealing Weapon Damage
plus ${$m1+0} as Shadow damage, piercing resistances." (Spell.dbc server set, Description[enUS]). The DBC marks every
rank SPELL_ATTR5_NO_PARTIAL_RESISTS, a bit the engine never reads, and the Witch Hunter contract set no resist
bypass, so `Unit::CalcAbsorbResist` rolled the Shadow partial resist (`Unit.cpp:2672`). A dummy with 5000 Shadow
resistance took about 71% less Desecrate damage; the archived logs show 0 of 410 Desecrate hits resisted while
other Shadow spells of the same caster were resisted on the same mobs.

Every rank has one effect, NORMALIZED_WEAPON_DMG, Dispel 0, Mechanic 0, DmgClass MELEE and no aura. Its hit result
goes through `MeleeSpellHitResult` (`Unit.cpp:4170`), never `MagicSpellHitResult`, and the Felsworn `ResistDebuff`
needs a magic or curse dispel type (mentor check D-213).

Mentor ruling D-209: build the fix, Witch Hunter code only, no SQL.

## Options

- Set SPELL_ATTR4_NO_CAST_LOG ("Cannot be resisted") on the six ranks in the Witch Hunter contract: skips the
  partial-resist block only; absorbs still apply.
- Set `AscensionIgnoreAbsorbAndResistance`: also skips absorbs, which the tooltip does not claim.
- Honour SPELL_ATTR5_NO_PARTIAL_RESISTS in `Unit::CalcAbsorbResist`: a core change for every spell with the bit,
  whose set was not audited.

## Decision

The first option, in `AscensionWitchHunterCompletion.cpp` next to the existing Desecrate contract.

## Consequences

- Desecrate's damage is not lowered by the target's Shadow resistance; Shadow absorbs still absorb it.
- The spells cast alongside Desecrate (Shadowstorm 520278, Dusk Blade 574335, the 680519 helper, Knight's Seal 680511)
  are separate spells and keep their resist behaviour.
- The dummy's own Shadow resistance no longer lowers Desecrate either: `681211 hit_mean` reads about 457 (the
  unresisted tooltip mean) where the rank hit model, which always applies the measured target resistance, expects
  403. The model has no per-spell resistance bypass for rank hits yet.
- Regressions: `681211 behaviour_hit_ratio pierce` (5000 Shadow resistance on the dummy, ratio 1.0),
  `681211 behaviour_metric_delta absorb` (Shadow Ward 6229 still absorbs 290), `681211 behaviour_metric_delta
  cast_logged` and `681211 behaviour_metric_delta damage_logged` (the cast and the damage stay in the event stream).
