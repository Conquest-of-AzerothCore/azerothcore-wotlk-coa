/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "UnitScript.h"
#include <vector>

// Cosmetic visuals lost after a transform (#9463).
//
// Vanity spells such as Blazing Irie Wings (12000142) are permanent auras whose look is a client-side spell
// visual, drawn while the aura is in the player's aura list. When a transform or other model change ends, the
// server restores the native display and the client rebuilds the player model without those visuals, although the
// auras are still applied. Once the player is back on the native model, this re-sends each permanent, positive
// visual aura as removed and then added again, so the client draws its visual on the rebuilt model. The auras
// themselves are never removed on the server.
namespace
{
// The display change reaches the client with the next object update, while aura updates are sent at once, so wait
// until the client has rebuilt the model before re-sending.
constexpr Milliseconds RefreshDelay = 300ms;

bool NeedsVisualRefresh(AuraApplication const* application)
{
    Aura const* aura = application->GetBase();
    SpellInfo const* info = aura->GetSpellInfo();
    if (!info->SpellVisual[0] && !info->SpellVisual[1])
        return false;
    if (!aura->IsPermanent() || !application->IsPositive())
        return false;
    // Re-sending a model-changing aura would start another display change.
    return !info->HasAura(SPELL_AURA_TRANSFORM) && !info->HasAura(SPELL_AURA_MOD_SHAPESHIFT) &&
        !info->HasAura(SPELL_AURA_CLONE_CASTER);
}

void RefreshCosmeticVisuals(Player* player)
{
    if (!player->IsInWorld() || player->GetDisplayId() != player->GetNativeDisplayId())
        return;

    std::vector<AuraApplication*> refresh;
    for (auto const& [slot, application] : *player->GetVisibleAuras())
        if (NeedsVisualRefresh(application))
            refresh.push_back(application);

    for (AuraApplication* application : refresh)
    {
        application->ClientUpdate(true);
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
                RefreshCosmeticVisuals(target);
        }, RefreshDelay);
    }
};

void AddSC_AscensionCosmeticVisualRefresh()
{
    new coa_cosmetic_visual_refresh();
}
