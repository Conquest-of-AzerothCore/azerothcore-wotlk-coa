/*
 * Shazzrah's Blink (2105611) folds vanilla Gate of Shazzrah's dummy+teleport
 * pair (23138 dummy, 23139 teleport) into a single spell: EFFECT_0 is a
 * dummy (SPELL_EFFECT_DUMMY, target "current spell target") and EFFECT_1 is
 * SPELL_EFFECT_TELEPORT_UNITS (caster to a point behind that target) - the
 * engine already performs the teleport by itself. What is missing is the
 * threat wipe stock Gate of Shazzrah does onto whoever it teleports to
 * (boss_shazzrah.cpp's spell_shazzrah_gate_dummy::HandleScript, cited there
 * as sourced from wowwiki); this restores just that piece.
 *
 * It also leaves a "Reflection of Shazzrah" (11504) behind at the spot he
 * blinked away from, repeatedly casting Mirrored Arcane Explosion (2105650)
 * on itself (smart_scripts, pending SQL, SMART_EVENT_UPDATE_OOC reusing
 * Shazzrah's own measured Arcane Explosion cadence - first 3.6s/period 8.4s -
 * since the corpus never captured a cast interval of its own for 2105650).
 * The reflection is summoned in effect 0, before the engine applies effect
 * 1's teleport, so GetCaster()'s position here is still the pre-blink spot.
 *
 * Players must keep the boss moving so Blink's clones spread out rather than
 * stack their Arcane Explosions on one spot; the reflection therefore stays
 * exactly where it spawned (rooted, passive, no threat list to chase with)
 * and is immune to all damage and control for as long as the Shazzrah
 * encounter runs, rather than despawning on its own timer. instance_molten_
 * core.cpp despawns every tracked reflection once DATA_SHAZZRAH leaves
 * IN_PROGRESS (wipe, evade, kill or reset), so none linger between pulls.
 */

#include "Creature.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "Unit.h"
#include "UnitDefines.h"

namespace
{
    enum ShazzrahBlinkSpells
    {
        NPC_REFLECTION_OF_SHAZZRAH = 11504,
    };

    class spell_shazzrah_blink_coa : public SpellScript
    {
        PrepareSpellScript(spell_shazzrah_blink_coa);

        void HandleThreatWipe(SpellEffIndex /*effIndex*/)
        {
            Unit* caster = GetCaster();
            Unit* target = GetHitUnit();

            if (caster && target)
            {
                Position const prevBlinkPos = caster->GetPosition();

                if (Creature* creatureCaster = caster->ToCreature())
                {
                    creatureCaster->GetThreatMgr().ResetAllThreat();
                    creatureCaster->GetThreatMgr().AddThreat(target, 1);
                    creatureCaster->AI()->AttackStart(target);

                    if (Creature* reflection = creatureCaster->SummonCreature(NPC_REFLECTION_OF_SHAZZRAH, prevBlinkPos, TEMPSUMMON_MANUAL_DESPAWN))
                    {
                        reflection->SetReactState(REACT_PASSIVE);
                        reflection->SetControlled(true, UNIT_STATE_ROOT);
                        reflection->SetImmuneToAll(true);
                    }
                }
            }
        }

        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_shazzrah_blink_coa::HandleThreatWipe, EFFECT_0, SPELL_EFFECT_DUMMY);
        }
    };
}

void AddCoaShazzrahScripts()
{
    RegisterSpellScript(spell_shazzrah_blink_coa);
}
