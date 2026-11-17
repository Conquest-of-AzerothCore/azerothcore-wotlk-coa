# 0026. Pavise deflects hostile spells from every direction

- Status: accepted
- Date: 2026-11-17

## Context

Pavise 520865, taught by Pavise Crossbowman 681453, reads: "Slam your shield into the ground, forming a pavise for 10
sec. While you remain near it, hostile spells targeting you are deflected." (Spell.dbc server set, Description[enUS]).
The tooltip names no arc. Owner ruling O-47 (card Q-wh-45, answer b, mentor D-486): the spells are deflected from
every direction.

520865 summons 50519, which casts 1108180 "Pavise Effect" on itself (`AscensionWitchHunterSummons.cpp:353-357`):
Effect[0] APPLY_AREA_AURA_OWNER, aura 287 SPELL_AURA_DEFLECT_SPELLS, amount 100, radius index 16. The stock engine adds
the deflect term only when the victim is not stunned and the caster stands in the victim's front 180 degrees or the
victim holds SPELL_AURA_IGNORE_HIT_DIRECTION: magic spells `Unit.cpp:4087-4094` (`Unit::MagicSpellHitResult`),
ranged-class spells `Unit.cpp:3808-3817` (`Unit::MeleeSpellHitResult`). Melee-class spells have no deflect term.

Measured before the change (nf-e, fix note 224.0), counted pair 20261117-151217 / 20261117-151309, worldserver sha256
0664b3e5e408: 681453 `pavise_deflect` control 20/20 land, front 0/20, outside 20/20 (aura 0), behind 20/20 land with
1108180 held (recorded, not judged).

## Options

- (A) Give 1108180 a second area effect with aura 288 IGNORE_HIT_DIRECTION. Rejected: every reader of
  `HasIgnoreHitDirectionAura` would change too (dodge, parry and block from behind for white melee and melee or
  ranged spells, `Unit.cpp:3372`, `3408`, `3687`, `3826`), which the tooltip does not grant; the only aura 288 spells
  in Spell.dbc are Deterrence spells (cross-class link).
- (B) A deflect roll for the behind case in the Witch Hunter all-spell hook, gated like the engine's front path.
- (C) A `Unit.cpp` edit: shared engine, excluded.

## Decision

Option (B), in `src/server/coa/AscensionWitchHunterAbilities.cpp` only. `witch_hunter_casts::OnSpellBeforeEffects`
calls `PaviseDeflectFromBehind` before `WitchblightMiss`, after the engine chose every target's miss condition
(`Spell::AddUnitTarget`, `Spell.cpp:2457`; the hook at `Spell.cpp:4044`, before `HandleLaunchPhase`). For each unique
target, the roll happens only when all of these hold:

- the attacker is the spell's original caster, the unit the engine rolls with (`Spell.cpp:2455-2457`), and the target
  is not the attacker;
- the target's miss condition is still SPELL_MISS_NONE (immune, evade, reflect, miss, resist and a front deflect are
  already decided);
<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:8bde9e1c835dea5c746f9a984d53d5c3f3fb97a2551440768db0378cebe773f4 -->

- the attacker is outside the target's front 180 degrees (`HasInArc(M_PI, attacker)` false) and the target holds no
  IGNORE_HIT_DIRECTION aura: in every other case the engine's front path already rolled the deflect, so each unique target gets one
  outcome and never two deflect rolls; a cast with multiple eligible targets rolls separately for each;

<!-- /coderabbit-ai-generated:v1 -->- the target is not stunned: the engine's stunned exclusion is kept. O-47 ruled the direction only, and a stunned
  holder is not protected from the front either;
- the spell is in the engine's deflect set (`DeflectRolledFromFront`): not SPELL_ATTR3_ALWAYS_HIT, not a positive or
  dispel spell from a non-hostile attacker (`Unit.cpp:4180-4184`); DmgClass RANGED without
  SPELL_ATTR0_NO_ACTIVE_DEFENSE (`Unit.cpp:3748-3758`, `3797-3798`, `3807-3817`); DmgClass MAGIC, or DmgClass NONE with
  SpellFamilyName 0 and only school-damage or periodic-damage effects (`Unit.cpp:4228-4249`), with the target alive or
  a player, the attacker not a vehicle and no SPELL_ATTR7_NO_ATTACK_MISS (`Unit.cpp:3950-3966`). DmgClass MELEE is left
  out, as in the engine;
- the chance is the sum of the 1108180 SPELL_AURA_DEFLECT_SPELLS amounts on the target (`PaviseDeflectChance`), the
  same amount the front roll adds; `roll_chance_i` of it sets SPELL_MISS_DEFLECT.

`Spell::m_skipCheck`, which forces SPELL_MISS_NONE after the engine roll (`Spell.cpp:2458-2461`), is set only by the
`Spell` constructor argument, and no caller passes it, so the hook has no case to mirror there.

## Consequences

- Only units holding 1108180 gain anything, and only against spells cast from behind: no other deflect aura gains the
  arc, no dodge, parry, block, melee or white hit changes, and the stunned rule is unchanged. 1108180 is cast only by
  the Witch Hunter Pavise summon 50519. The engine readers of aura 287 (`Unit.cpp:3812`, `4090`) are untouched.
- Probability: the front roll deflects with min(A, 100 - miss - resist) on one roll; the behind roll deflects with A of
  the strikes left as SPELL_MISS_NONE. At A = 100, the only amount 1108180 carries, the behind roll always deflects
  (`roll_chance_i(100)`, `Random.h:63-65`) and the front roll deflects 9999 of 10000 (`irand(1, 10000) < 10000`,
  `Unit.cpp:4087-4094`); the 1e-4 front tail is the one undeflected sample of the 512-sample data arm.
- The hook runs for every cast server-wide (an AllSpellScript, as `WitchblightMiss`): one arc test per hit target and
  one aura-list scan for a target hit from behind.
- The behind deflect is set before `WitchblightMiss`, as the engine's front deflect is, so a Witchblight holder's
  attempt is consumed the same way from either side.
- The data arm `pavise_deflect_rolls` calls `Unit::MagicSpellHitResult` directly and stays a front-only READBACK.
- Spells with no Spell object (white melee, periodic ticks) are untouched, as they are from the front.
- Regression in `classes/witch_hunter.json` (claim 224.0): 681453 `pavise_deflect` judges its behind arm, at most 1 of
  20 strikes landed with 1108180 held and the striker behind the caster; control 20/20, front at most 1/20 and outside
  20/20 with aura 0 are unchanged. The `deflect_arcs` option judges the behind arm unless an `owner_question` is set;
  the entry drops `owner_question` Q-wh-45, now ruled. The outside arm's Pavise presence read (`present_entry`
  50519) must read 1: a 0 or a missing read alerts (review I-2, mentor scope D-486), so the outside arm cannot pass
  with the Pavise gone.
