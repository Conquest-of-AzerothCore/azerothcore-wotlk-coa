# 0032. Owner ruling Felsworn O-40: the Betrayer strike hits with the off hand

- Status: accepted (owner ruling Felsworn O-40 (2026-11-24), question N-13; mentor D-113 for the route)
- Date: 2026-11-24

## Context

Betrayer 300476, server DBC text: "Dodging attacks causes $804336s2% off-hand Weapon Damage to attackers and enrages
your party and raid members within $520256a1 yds, increasing their critical strike chance by $520256s1% for
$520256d." The strike 804336 (server DBC set) is a melee spell (DmgClass 2, Physical) with Effect[0]
SPELL_EFFECT_NORMALIZED_WEAPON_DMG (1 flat) and Effect[1] SPELL_EFFECT_WEAPON_PERCENT_DAMAGE (40%), AttributesEx3 0
and EquippedItemClass -1. Without SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON, `Spell.cpp:597-603` gives it the main hand.

Measured (pair fw-bk3, Tyrant weapons 73.62-103.34 in both hands, attack power 312): 59.6 and 60.2 per hit over 40
hits each, against 29.75 expected for the off hand and 59.43 for the main hand. The archived live logs (3 hits of
804336, gear unknown) do not decide the hand, so the claim went to the owner as question N-13.

## Options

- Keep the main-hand strike and correct the tooltip text.
- Strike with the off hand, as the tooltip says:
  - name the hand at the cast in `AscensionFelswornEvents.cpp` (`SPELLVALUE_MELEE_ATTACK_TYPE`): only the dodge path
    changes; a direct cast of 804336 (the conformance entry casts it at the dummy) keeps the main hand;
  - add SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON to 804336 in the class contracts, as the class already does for 800598:
    every cast of 804336 is an off-hand strike.

## Decision

The owner ruled (Felsworn O-40 (2026-11-24)): the strike follows the tooltip, off hand. The mentor chose the contract
route (D-113): `AscensionFelsworn::ApplyContracts` (`AscensionFelswornContracts.cpp`) adds
SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON to 804336.

## Consequences

- With an off-hand weapon, `Spell.cpp:600` sets OFF_ATTACK: the weapon roll is the off-hand weapon's and the stock
  off-hand TOTAL_PCT 0.5 (`Unit.cpp:519`) applies to the roll and to the flat part (`SpellEffects.cpp:4693-4720`).
  Proven by `300476 script_hit 804336 offhand_strike` (claim 17.1, expectation about 29.75 with the Tyrant set).
- Without an off-hand weapon (code reading, untested): 804336 has EquippedItemClass -1, so the weapon check of
  `Spell::CheckItems` (`Spell.cpp:8018-8045`) does not run and the strike is still cast. `Player::CalculateMinMaxDamage`
  (`StatSystem.cpp:693-773`) then rolls no weapon damage: attack power / 14 x 2.4 (`Unit::GetAPMultiplier`, fist) under
  the off-hand 0.5, so 40% x 0.5 x (AP / 14 x 2.4).
- With the off hand disarmed (code reading, untested): `CanUseAttackType(OFF_ATTACK)` is false, the off-hand damage is
  0, and the strike deals only what the melee bonuses add to 0.
- The strike now carries PROC_FLAG_DONE_OFFHAND_ATTACK instead of the main-hand flag (`Spell.cpp:2323-2326`), and the
  class helper `SpellAttackType` (`AscensionFelswornContracts.cpp`) reads the off hand for the victim attack power share.
- Other readers of the attribute: `SpellInfo.cpp:3248` (SPELL_ATTR4_WEAPON_SPEED_COST_SCALING only; 804336 has
  AttributesEx4 0 and no cost), the Reaper Dirge check (keyed to its own spell id). No other class's code, file or data
  reads 804336. No engine, SQL, DBC file or client text change: the tooltip already says off hand.
