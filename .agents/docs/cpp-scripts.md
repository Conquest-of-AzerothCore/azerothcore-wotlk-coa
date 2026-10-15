# C++ scripts

Scripts inherit from a `ScriptObject` subclass (`SpellScript`, `AuraScript`, `CreatureScript`, `InstanceMapScript`, `GameObjectScript`, `CommandScript`, …). Two registration styles coexist:

- **Spell / aura scripts**: `RegisterSpellScript(ClassName)` (or `RegisterSpellAndAuraScriptPair(...)`) inside `AddSC_<name>()`.
- **Creature scripts**: prefer `RegisterCreatureAI(ClassName)` for new code; legacy zones still use `new ClassName();`. Match the surrounding pattern.

Then declare and call `AddSC_<name>()` from the regional loader (`Spells/spells_script_loader.cpp`, `EasternKingdoms/eastern_kingdoms_script_loader.cpp`, …).

**SmartAI** (data-driven creature behaviour) lives in the world DB's `smart_scripts` table, not C++ (engine: `src/server/game/AI/SmartScripts/`). For new creature behaviour prefer SmartAI (via the SQL update workflow); reach for `CreatureScript` only when SmartAI's event/action vocabulary isn't enough.

**SmartAI row scope — prefer the unique spawn.** Rows keyed to a spawn (`entryorguid = -guid`) are used first; the entry's rows are only a fallback, so a spawn script silently hides the entry script for that spawn (`CREATURE_FLAG_EXTRA_DONT_OVERRIDE_ENTRY_SAI`, `flags_extra` 0x08000000, is the only way to load both). When a creature has exactly one spawn, author its rows on that spawn's guid and leave the entry clean. For a unit that is not single-spawn (multiple spawns, or summoned-only with no spawn id), entry scope is the default — confirm the intended scope before authoring. Gameobjects resolve identically (spawn script first, template fallback), and a negative key must reference an existing spawn row or the row is skipped at load. Smart-event condition rows key on the same `entryorguid` value (negative for spawn scripts), so a script moved between scopes must take its conditions with it.

**SmartAIMgr skips rejected rows with only a log line.** A validated parameter with an unexpected value drops the whole row at load (`SmartAIMgr: … skipped.`); only some actions are checked, and the executor can support more than the validator allows — `SUMMON_CREATURE.attackInvoker` was boolean-checked (0/1) while the executor also implements 2 (attack the event invoker). When a row seemingly never fires, grep the startup log for its entry before suspecting the data or the engine.

**Module hooks** (e.g. `OnPlayerLogin`, `OnWorldUpdate`, `OnSpellCast`) are declared in `src/server/game/Scripting/ScriptDefines/*.h`. Implement by inheriting the matching base (`PlayerScript`, `WorldScript`, …) and registering with `new MyClass();` (or its `RegisterXxxScript` macro) inside `AddSC_<name>()`. Full list: https://www.azerothcore.org/wiki/hooks-script.

**Conventions:**

- Script ids (action/event/data/phase) get named enum entries — never raw literals, even when the file already uses them: add the entry and convert that literal's every call site and handler in the same change.
- A `SpellScript`/`AuraScript` without a matching `spell_script_names` row is inert — ship the binding SQL update in the same change as the C++ registration.
- Never add `UNIT_FLAG*` / `UNIT_FLAG2*` / `UNIT_DYNFLAG*` values without sniff or upstream evidence; the same flag used in another script is not evidence.
- Trigger NPCs (`creature_template.flags_extra` 0x80) have no threat list — `SelectTarget` / `AddThreat` / `UpdateVictim` chains on them silently do nothing. A never-evading helper NPC left on a boss's threatened-by list also stalls the boss's evade/reset forever; make such helpers `IMMUNE_TO_NPC`.
- A spell id missing from Wowhead is inconclusive — check the world DB's `spell_dbc` table (server-side spells) before concluding a sniffed id doesn't exist.

Custom (non-upstream) scripts go in `src/server/scripts/Custom/` (gitignored).

## Registration and command lifetimes

- Register AuraScript callbacks against the spell's actual valid aura effects. An unconditional periodic handler
  on a nonperiodic aura fails startup validation even if its body would do nothing. During registration, resolve
  `m_scriptSpellId` through SpellMgr; a cast object may not exist yet.
- `ChatCommandBuilder` stores a reference to its child command vector. Keep child tables alive, for example with
  static storage; an inline temporary can compile but crash command initialization.
