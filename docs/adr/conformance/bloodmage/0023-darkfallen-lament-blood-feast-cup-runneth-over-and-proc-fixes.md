# 0023. Darkfallen Lament cap and immunity, Blood Feast burst, Cup Runneth Over, and proc updates

- Status: accepted (Bloodmage conformance Lot 2, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Five additional Bloodmage contracts/scripts/procs verified against server `Spell.dbc` (`SpellFamilyName = 26`):

1. **Darkfallen Lament (`680828` / `524180`)**: tooltip states `"healing up to $524181i [12] allies"` and `"While active,
   you are immune to silence and interrupt effects"`. `524180` had `MaxAffectedTargets = 25` instead of `12`, and
   `680828` granted no silence/interrupt immunity (`15487` Silence landed during the channel).
2. **Blood Feast Arterial Bind burst (`706605` / `681077` / `520312`)**: tooltip states `"$?s681077[, and then causes
   you to burst, healing party and raid members within $520312a1 yds...][]"`. `681077` Arterial Bind is an active
   learned spell (not a passive aura), and `706605` never triggered `520312` Life's Essence on channel expiry.
3. **The Cup Runneth Over (`807544`)**: `Effect[1]` (`SPELL_AURA_ADD_PCT_MODIFIER`, `+20%` on Taldaram's Torment
   `[0, 0, 2097152]`) carries Ascension custom `MiscValue = 40` instead of WotLK `SPELLMOD_BONUS_MULTIPLIER` (`24`),
   mirroring `AscensionRunemasterTalents.cpp:183-185`. `Unit::SpellDamageBonusDone` (`Unit.cpp:9991`) applies
   `SPELLMOD_BONUS_MULTIPLIER` to `DOT` spells once remapped.
4. **Bloodcraft (`680733`)**: `rev_20260920_41` set `AttributesMask = 0`, preventing triggered Darkfallen Lament leech
   ticks (`630874`) from proccing `524182`.
5. **Flesh Foundry (`704633`)**: `rev_20260920_50` set `ProcFlags = 69908` and `SpellTypeMask = 1` (damage crits only),
   excluding healing crits (`0x8000 | 0x800` -> `104724`, `SpellTypeMask = 3`) from reducing Sated (`532125`) duration.

## Options

- Implement `524180` `MaxAffectedTargets = 12`, `807544` `MiscValue = SPELLMOD_BONUS_MULTIPLIER`,
  `aura_ascension_bloodmage_darkfallen_lament` (applying/removing `IMMUNITY_MECHANIC` for `MECHANIC_SILENCE` and
  `MECHANIC_INTERRUPT`, `IMMUNITY_STATE` for `SPELL_AURA_MOD_SILENCE`, and `IMMUNITY_EFFECT` for
  `SPELL_EFFECT_INTERRUPT_CAST`), and `aura_ascension_bloodmage_blood_feast` (triggering `520312` on
  `AURA_REMOVE_BY_EXPIRE` when `HasSpell(681077) || HasAura(681077)`) in `src/server/coa/AscensionBloodmageTalents.cpp`,
  plus the companion `spell_script_names` and `spell_proc` rows in
  `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`. Chosen: class-scoped, zero
  engine edits.

## Decision

Land all five changes in `src/server/coa/AscensionBloodmageTalents.cpp` and
`data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Darkfallen Lament caps AoE healing at 12 allies and blocks silence and interrupt effects while active.
- Blood Feast triggers Life's Essence `520312` on channel expiry when Arterial Bind `681077` is known.
- The Cup Runneth Over increases Taldaram's Torment SP scaling by `+20%`.
- Bloodcraft procs from triggered Darkfallen Lament ticks, and Flesh Foundry procs on both damage and healing crits.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
