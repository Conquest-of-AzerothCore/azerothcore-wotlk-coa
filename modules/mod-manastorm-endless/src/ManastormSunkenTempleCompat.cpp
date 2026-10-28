#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SmartAI.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

namespace
{
    constexpr uint32 NPC_JAMMALAN_THE_PROPHET = 5710;

    void SetJammalanEvadeSuppressed(Unit* caster, Unit* target, bool suppress)
    {
        Creature* boss = caster ? caster->ToCreature() : nullptr;
        if (!boss || boss->GetEntry() != NPC_JAMMALAN_THE_PROPHET)
            return;

        Map* map = boss->GetMap();
        if (!map || !map->IsScriptedPrivateInstance() || !ManastormModuleConfig::Enabled())
            return;

        Player* player = target ? target->ToPlayer() : nullptr;
        if (!player)
            return;

        ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
        if (!run || run->GetMode() != ManastormMode::Solo || run->GetInstanceId() != map->GetInstanceId())
            return;

        if (SmartAI* smartAI = CAST_AI(SmartAI, boss->AI()))
            smartAI->SetSuppressEvade(suppress);
    }

    class spell_manastorm_hex_of_jammalan_charm : public AuraScript
    {
        PrepareAuraScript(spell_manastorm_hex_of_jammalan_charm);

        void Apply(AuraEffect const*, AuraEffectHandleModes)
        {
            SetJammalanEvadeSuppressed(GetCaster(), GetTarget(), true);
        }

        void Remove(AuraEffect const*, AuraEffectHandleModes)
        {
            SetJammalanEvadeSuppressed(GetCaster(), GetTarget(), false);
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_manastorm_hex_of_jammalan_charm::Apply, EFFECT_0,
                SPELL_AURA_MOD_CHARM, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_manastorm_hex_of_jammalan_charm::Remove, EFFECT_0,
                SPELL_AURA_MOD_CHARM, AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddSC_manastorm_sunken_temple_compat()
{
    RegisterSpellScript(spell_manastorm_hex_of_jammalan_charm);
}
