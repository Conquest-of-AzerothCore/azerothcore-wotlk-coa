/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "UnitScript.h"
#include "WorldPacket.h"
#include <algorithm>
#include <array>
#include <vector>

namespace
{
constexpr uint32 VanitySkillLine = 120;

constexpr std::array<uint32, 2> ChronometricPressureSpells = { 364787, 364878 };

constexpr Milliseconds ModelRebuildDelay = 300ms;

bool IsVanitySpell(uint32 spellId)
{
    SkillLineAbilityMapBounds const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (itr->second->SkillLine == VanitySkillLine)
            return true;
    return false;
}

bool IsRedrawableVanityAura(AuraApplication const* application)
{
    SpellInfo const* info = application->GetBase()->GetSpellInfo();
    if (!info->SpellVisual[0] && !info->SpellVisual[1])
        return false;
    bool const changesModel = info->HasAura(SPELL_AURA_TRANSFORM) || info->HasAura(SPELL_AURA_MOD_SHAPESHIFT) ||
        info->HasAura(SPELL_AURA_CLONE_CASTER);
    if (changesModel)
        return false;
    bool const isMount = info->HasAura(SPELL_AURA_MOUNTED);
    if (isMount)
        return false;
    if (std::find(ChronometricPressureSpells.begin(), ChronometricPressureSpells.end(), info->Id) !=
        ChronometricPressureSpells.end())
        return false;
    return IsVanitySpell(info->Id);
}

void RefreshVanityVisuals(Player* player)
{
    if (!player->IsInWorld() || player->GetDisplayId() != player->GetNativeDisplayId())
        return;

    std::vector<AuraApplication*> refresh;
    for (auto const& [slot, application] : *player->GetVisibleAuras())
        if (IsRedrawableVanityAura(application))
            refresh.push_back(application);

    for (AuraApplication* application : refresh)
    {
        WorldPacket clientOnlyRemoval(SMSG_AURA_UPDATE, 8 + 1 + 4);
        clientOnlyRemoval << player->GetPackGUID();
        clientOnlyRemoval << uint8(application->GetSlot());
        clientOnlyRemoval << uint32(0);
        player->SendMessageToSet(&clientOnlyRemoval, true);

        application->ClientUpdate(false);
    }
}
}

class coa_cosmetic_visual_refresh : public UnitScript
{
public:
    coa_cosmetic_visual_refresh() : UnitScript("coa_cosmetic_visual_refresh", true,
        { UNITHOOK_ON_DISPLAYID_CHANGE }) { }

    void OnDisplayIdChange(Unit* unit, uint32 displayId) override
    {
        Player* player = unit->ToPlayer();
        if (!player || !player->IsInWorld() || displayId != player->GetNativeDisplayId())
            return;

        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([guid]()
        {
            if (Player* target = ObjectAccessor::FindPlayer(guid))
                RefreshVanityVisuals(target);
        }, ModelRebuildDelay);
    }
};

void AddSC_AscensionCosmeticVisualRefresh()
{
    new coa_cosmetic_visual_refresh();
}
