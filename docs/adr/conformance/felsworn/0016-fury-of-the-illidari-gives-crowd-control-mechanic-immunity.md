# 0016. Fury of the Illidari gives crowd control mechanic immunity

- Status: accepted (Felsworn mentor decision D-69, 2026-11-23)
- Date: 2026-11-23

## Context

Fury of the Illidari 561216: "While active you are immune to crowd control effects."

Measured before the fix (Felsworn A-2 review, alert 113, both runs of the A-2 pair): with the aura on, Stun 56 did not
land, Fear 12096 and Net 47021 (root) did. The A-2 entries are on `test/coa-felsworn-end-a2`.

The class contract (`AscensionFelswornContracts.cpp`, block of 561216) turned Effect[2] into aura 147
`SPELL_AURA_MECHANIC_IMMUNITY_MASK` with MiscValue `IMMUNE_TO_MOVEMENT_IMPAIRMENT_AND_LOSS_CONTROL_MASK`
(`SharedDefines.h:1469`), a `1 << MECHANIC_*` mask. For aura 147, `SpellInfo::_LoadImmunityInfo` (`SpellInfo.cpp`, the
`SPELL_AURA_MECHANIC_IMMUNITY_MASK` case) gives no mechanic immunity for that value: it reads MiscValue as the legacy
state bits (1 << 10 stun, 1 << 9 fear, 1 << 0 root, 1 << 6 snare, 1 << 2 confuse, 1 << 7 disarm, 1 << 1 transform).
The mask has bit 10 (MECHANIC_SLEEP) and lacks bits 9 and 0, hence stun immune, fear and root landing.

`git log -L` on those lines: the two lines arrived unchanged in 46bf8121e5 ("feat(CoA): complete remaining class
packages and shared mechanics", 2026-09-09, no message body); later commits only moved the file and dropped a duration
comment. No recorded reason chose aura 147 for a mechanic mask.

Source of the mechanic list, in the order of the D-69 brief:

1. 561216's own data names none. Server DBC set: Effect[2] is aura 263 `SPELL_AURA_ALLOW_ONLY_ABILITY`, MiscValue 0;
   Mechanic 0 and EffectMechanic 0 on every effect; no trigger spell; CasterAuraSpell 804216 (Inner Demon) carries no
   immunity. The reference snapshots (coabuildhub index, bindmysoul talents) hold the tooltip only; coa-history has no
   event of 561216 in 186 logs.
2. The CoA spell with the same tooltip wording is Vial of Moonwell Water 804652, aura text "Immune to crowd control
   effects.", whose list is `IMMUNE_TO_MOVEMENT_IMPAIRMENT_AND_LOSS_CONTROL_MASK & ~((1 << MECHANIC_SNARE) |
   (1 << MECHANIC_DAZE))` (`SpellInfo.cpp:2788-2790`, abd15f91be, #12317). The class's own Fury Unleashed 555738 words
   the wider set separately ("immune to movement impairing and loss of control effects", aura 147 MiscValue 1733), so
   the stock constant whole belongs to that wording, not to 561216's.

The list is therefore: charm, disoriented, fear, root, sleep, stun, freeze, knockout, polymorph, banish, shackle, turn,
horror, sapped. Snare, daze, silence, disarm and interrupt stay out and go to the owner as a question.

## Options

- Keep aura 147 and pick a legacy MiscValue: the legacy bits give state immunity to seven aura types, not the
  mechanic list, and the engine's named values (477, 1733, 1557, ...) each give a different fixed list.
- Change the engine's aura 147 reading: a shared engine path read by every class and stock spell.
- Effect[2] becomes `SPELL_AURA_DUMMY` in the class contract, and the class aura script that already runs 561216
  (`aura_ascension_felsworn_lifecycle`) applies and removes mechanic immunity for the list on that effect.

## Decision

The third option. `AscensionFelswornContracts.cpp` sets 561216 Effect[2] to `SPELL_AURA_DUMMY`;
`AscensionFelswornAuras.cpp` (`CrowdControlMechanics`, `CrowdControlImmunity`) calls `Unit::ApplySpellImmune` with
`IMMUNITY_MECHANIC` for each mechanic of the list when that effect is applied (real mode) and removed. Nothing purges
crowd control already on the caster: 561216 lacks `SPELL_ATTR1_IMMUNITY_PURGES_EFFECT` and the tooltip says "while
active".

## Consequences

- Keyed to 561216 by id. Effect[2] of 561216 is read by no other code; `CrowdControlImmunity` is new and used only here.
  No engine, SQL, DBC or client text change. The aura 263 of the data stays replaced.
- While 561216 is on, a crowd-control spell whose Mechanic or EffectMechanic is in the list is resisted as immune.
  A snare lands.
- Regressions: `immunity` entries of 561216, variants `stun` (56), `fear` (12096), `root` (47021), `sleep` (9159),
  `horror` (64044) and `disoriented` (2094), each landing without the aura, immune with it and landing again after
  expiry; `snare_lands` (Piercing Howl 12323) lands with the aura on. The other mechanics of the list have no
  fixture here: a creature's Polymorph (118, 13323) is refused on the caster in the Inner Demon form 804216 that 561216
  requires (`SpellInfo::CheckTargetCreatureType`, cast result 117), and charm, freeze, knockout, banish, shackle, turn
  and sapped have no creature cast at a player in the fixtures. They share the one loop, so they are covered by code,
  not measured.
- Open owner question: whether "crowd control" also covers snare, daze, silence, disarm or interrupt.

## Amendment: owner ruling Felsworn O-29 (2026-11-24)

The open question above is answered by the owner (Felsworn O-29 (2026-11-24)): "crowd control" on Fury of the Illidari 561216 also covers
slows and daze, and does not cover silence, disarm or interrupt (option b of the night question fw-fix561216).

- `CrowdControlMechanics` (`AscensionFelswornAuras.cpp`) is now the whole
  `IMMUNE_TO_MOVEMENT_IMPAIRMENT_AND_LOSS_CONTROL_MASK` (`SharedDefines.h:1469`): the list above plus snare and daze.
  Silence, disarm and interrupt are not in that constant and stay out. The Vial of Moonwell Water 804652 list no
  longer sets the boundary; the constant is read, not copied, and no engine file changes.
- Measured before (pair .cache/verify-all/20261123-213410 / -213446, review fix-561216/fw-rf561216/review.md lines
  75-82): Piercing Howl 12323 (Mechanic 11 snare) landed with the aura on.
- Regressions: the landing control `snare_lands` becomes the immune entry `snare` (12323) with its post-expiry control;
  new `daze` (Dazed 1604, Mechanic 27) immune with its control; new landing controls `silence_lands` (Silence 15487,
  Mechanic 9) and `disarm_lands` (Disarm 676, Mechanic 3) prove the excluded mechanics still land. Interrupt has no
  aura and no fixture of the immunity kind.
- Still keyed to 561216 Effect[2] only; `CrowdControlImmunity` has no other caller.
