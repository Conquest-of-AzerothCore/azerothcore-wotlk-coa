/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunClericRadiance.h"
#include "AscensionSunCleric.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
namespace
{
using namespace AscensionSunCleric;

constexpr uint32 CHAMPIONS_ARRIVAL = 704905;
constexpr int32 CHAMPIONS_ARRIVAL_EXTRA_MS = 5000;

class aura_ascension_champion_of_the_sun_arrival : public AuraScript
{
    PrepareAuraScript(aura_ascension_champion_of_the_sun_arrival);

    void ExtendForArrival(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = Owner(GetCaster());
        Aura* aura = GetAura();
        if (!player || !aura || !player->HasAura(CHAMPIONS_ARRIVAL))
            return;
        int32 extended = aura->GetSpellInfo()->GetMaxDuration() + CHAMPIONS_ARRIVAL_EXTRA_MS;
        if (aura->GetMaxDuration() == extended)
            return;
        aura->SetMaxDuration(extended);
        aura->SetDuration(extended);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_champion_of_the_sun_arrival::ExtendForArrival,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

constexpr uint32 VINDICATOR_RANK_1 = 704938;
constexpr uint32 VINDICATOR_RANK_2 = 707773;
constexpr uint32 VOW_OF_THE_VALKYR = 807749;

void SyncVindicator(Player* player)
{
    if (!player)
        return;
    bool active = player->HasAura(VOW_OF_THE_VALKYR);
    for (uint32 id : {VINDICATOR_RANK_1, VINDICATOR_RANK_2})
        if (player->HasAura(id))
            SetAmount(player, id, EFFECT_0, active ? Amount(id, EFFECT_0) : 0);
}

class aura_ascension_vindicator_vow_gate : public AuraScript
{
    PrepareAuraScript(aura_ascension_vindicator_vow_gate);

    void Sync(AuraEffect const*, AuraEffectHandleModes)
    {
        SyncVindicator(Owner(GetCaster()));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_vindicator_vow_gate::Sync,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_vindicator_vow_gate::Sync,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};
}
void ApplyAscensionSunClericRadianceContracts(SpellInfo* info)
{
    if (!info)
        return;

    if (info->Id == 704917)
        info->Effects[EFFECT_0].BasePoints -= 1;

    if (info->Id == VINDICATOR_RANK_1 || info->Id == VINDICATOR_RANK_2)
    {
        SpellEffectInfo& effect = info->Effects[EFFECT_0];
        int32 const raw = effect.BasePoints;
        effect.ApplyAuraName = SPELL_AURA_ASCENSION_MOD_IGNORE_ARMOR_PCT;
        effect.BasePoints = -raw - 2;
        effect.SpellClassMask = flag96(0, 4096, 4);
    }
}
void AddSC_AscensionSunClericRadiance()
{
    RegisterSpellScript(aura_ascension_champion_of_the_sun_arrival);
    RegisterSpellScript(aura_ascension_vindicator_vow_gate);
}
