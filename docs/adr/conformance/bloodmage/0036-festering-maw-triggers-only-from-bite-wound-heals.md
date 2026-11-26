# 0036. Festering Maw triggers Lunge cooldown reduction only from Bite Wound heals

- Status: accepted (Bloodmage conformance fix wave S-21 / O-11, 2026-11-26)
- Date: 2026-11-26

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Festering Maw `706683` (confirmed matching 2026-09-01 client archive `q742IyqxrV0.csv` `t=10:52`): "Healing with |cffffffffBite Wound|r now reduces the cooldown of |cffffffffLunge|r by 1 sec."
- `706683` carries `ProcFlags = 4` (`PROC_FLAG_DONE_MELEE_AUTO_ATTACK`) and `Effect[0]` aura `42` (`SPELL_AURA_PROC_TRIGGER_SPELL` -> `706718`, `Effect[0] = 165 SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN`, `-1000 ms` on Lunge `500126`).

With no `spell_proc` override or Bite Wound gate, `SpellMgr::LoadSpellProcs` generated a default melee auto-attack proc for `706683`, so every white melee swing triggered `706718` even when the target had no Bite Wound (`706654`). Conformance check `706683 no_bite_wound_control` (`bloodmage.json [699]`) alerted (`3` casts of `706718` vs expected `0`). Meanwhile, Bite Wound (`706654`) heals the Bloodmage inside `aura_ascension_bloodmage_bite_wound::HealCaster` (`src/server/coa/AscensionBloodmageSecondary.cpp`) via `caster->HealBySpell(healing)`.

## Options

- Disable `706683`'s DBC `Effect[0]` auto-proc via `spell_proc` (`DisableEffectsMask = 1`, `ProcFlags = 0` so `LoadSpellProcs` inherits DBC `ProcFlags = 4` cleanly without logging an error) and trigger `706718` directly inside `aura_ascension_bloodmage_bite_wound::HealCaster` right after `caster->HealBySpell(healing)` when `caster->HasAura(SPELL_FESTERING_MAW)`. Chosen: ties the cooldown reduction strictly to actual Bite Wound heals (both melee and ranged auto-attacks on a Bite Wound target) and eliminates ungated auto-attack procs.
- Keep the DBC auto-proc on `706683` and gate it with an `AuraScript::DoCheckProc` checking `target->HasAura(706654)`. Rejected: duplicates `aura_ascension_bloodmage_bite_wound::Check` (including damage > 0 and ranged auto-attacks) and still relies on melee-only DBC `ProcFlags = 4`.

## Decision

1. In `src/server/coa/AscensionBloodmageSecondary.cpp`:
   - Add `SPELL_FESTERING_MAW = 706683` and `SPELL_FESTERING_MAW_CDR = 706718` to `BloodmageSecondarySpells`, and validate both in `aura_ascension_bloodmage_bite_wound::Validate`.
   - In `aura_ascension_bloodmage_bite_wound::HealCaster`, immediately after `caster->HealBySpell(healing);`, cast `SPELL_FESTERING_MAW_CDR` on `caster` if `caster->HasAura(SPELL_FESTERING_MAW)`.
2. In `data/sql/updates/pending_db_world/rev_20261127_03_bloodmage_secondary_procs.sql`:
   - Insert a `spell_proc` row for `SpellId = 706683` with `DisableEffectsMask = 1` (disabling `Effect[0]` DBC auto-proc).

## Consequences

- Auto-attacks on targets without Bite Wound (`706654`) never trigger `706718`.
- Every Bite Wound heal delivered by `aura_ascension_bloodmage_bite_wound::HealCaster` reduces Lunge (`500126`) cooldown by `1 sec` via `706718` when Festering Maw (`706683`) is learned.
- Verification targets (executed in the coordinator's merged fix-wave build per `O-8`): `706683 no_bite_wound_control` (`[699]`), `706683 lunge_cd_cut_open` (`[700]`), and `706683 lunge_cd_cut_bound` (`[701]`).
