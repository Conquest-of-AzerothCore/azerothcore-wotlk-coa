# 0033. Solar Concord resets only the spell of the active phase

- Status: accepted (owner ruling O-26, 2026-11-22)
- Date: 2026-11-22

## Context

Solar Concord 301266: "Resets the cooldown of Horusath Blast while in Sunrise and Rapture while in Sunset and causes
their damage dealt to launch a Solar Flare." The installed DBC (`/srv/coa/server-data/dbc`) resets both cooldowns on
every cast:

- 301266 Effect[1] TRIGGER_SPELL 302899 and Effect[2] TRIGGER_SPELL 301268;
- 301268 Effect[0] 195 SPELL_EFFECT_ASCENSION_RESET_COOLDOWN, MiscValue 500154 (Horusath Blast), MiscValueB 1;
- 302899 Effect[0] 195, MiscValue 806477 (Rapture), MiscValueB 1;
- neither has a CasterAuraSpell, and a CasterAuraSpell would not gate them: `Spell::EffectTriggerSpell` casts with
  `TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET` (`SpellEffects.cpp:1862`), which carries
  `TRIGGERED_IGNORE_CASTER_AURASTATE`, and `Spell::CheckCast` skips the CasterAuraSpell test under that flag
  (`Spell.cpp:5929-5938`).

The handler `Spell::EffectAscensionResetCooldown` (`SpellEffects.cpp:1103-1112`) resets the named spell's rank chain
and, with MiscValueB 1, its category (`ModifyAscensionCooldown`, `SpellEffects.cpp:390-399`), with no phase test. The
class's aura-apply hook (`AscensionSunClericAuras.cpp:101-107` before this change, e36bc50aad) also reset Horusath
Blast in Sunrise and Rapture in Sunset, so in phase the cooldown was reset twice and out of phase once.

Pairs x3, x4 and y1 (build 80cb6ee11a34) read the recast of Horusath Blast in Sunset and of Rapture in Sunrise
accepted (cast_failure 0) against the tooltip's refusal (67, SPELL_FAILED_NOT_READY), with the without arms at 67 and
the in-phase arms at 0. Owner ruling O-26: the reset follows the tooltip, by phase.

## Options

1. A CasterAuraSpell on 301268 and 302899 in the class contracts. Rejected: the triggered cast ignores it (above).
2. Drop 301266's two TRIGGER_SPELL effects in the contracts and keep the aura-apply hook. The hook removes the spell
   cooldown of each owned rank only (`Reduce`, `AscensionSunCleric.cpp:102-112`) and leaves the category reset that
   the DBC's MiscValueB 1 asks for.
3. Gate the two DBC resets in the class spell script and remove the hook's duplicate reset.

## Decision

Option 3. `spell_ascension_sun_cleric_ability` is bound to 301268 and 302899
(`rev_20261122_50_sun_cleric_solar_concord_phase_reset.sql`), and its hit handler prevents the effect of 301268 when
the caster has no Sunrise 500477 and of 302899 when the caster has no Sunset 500511
(`AscensionSunClericAbilities.cpp:509-510`). The 301266 branch of the aura-apply hook is removed, so the DBC effect is
the only reset path, once per cast, with its rank and category handling.

## Consequences

- In Sunrise, Solar Concord resets Horusath Blast and not Rapture; in Sunset, Rapture and not Horusath Blast.
- The phase is read when the triggered spell hits, right after the Solar Concord cast; 301266's own CasterAuraSpell
  500643 still requires one of the two phases for the cast.
- 301268 and 302899 are cast only by 301266 (DBC scan of every `EffectTriggerSpell`; no code casts them); no other
  spell or class reads them. The removed hook branch ran only for 301266.
- No engine file and no client text change. The Solar Flare part of the tooltip is unchanged
  (`AscensionSunClericEvents.cpp:131-132`).

## Verification

See the class conformance report of this fix: the counted pair at level 60 on the fix build, the in-phase arms
(`reset_horusath`, `reset_rapture`) expected 0 and the other-phase arms (`reset_horusath_sunset`,
`reset_rapture_sunrise`) expected 67 with their `with after_cast` reads at 0.
