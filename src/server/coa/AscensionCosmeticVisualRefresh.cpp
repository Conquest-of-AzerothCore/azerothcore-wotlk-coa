/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "UnitScript.h"

// Vanity visuals lost after a transform (#9463).
//
// Vanity spells such as Blazing Irie Wings (12000142) are permanent auras whose look is a client-side spell
// visual, drawn while the aura is in the player's aura list. When a transform or other model change ends, the
// server restores the native display and the client rebuilds the player model without those visuals, although the
// auras are still applied. Once the player is back on the native model, this re-sends each vanity aura's current
// state so the client draws its visual on the rebuilt model.
//
// Only vanity auras (skill line 120, "!Ascension Vanity Items") are touched, and only with an "applied" update:
// no removal is ever sent, so no aura's removal visual or sound can play and addons see no lost buff. The auras
// themselves are not changed on the server.
namespace
{
constexpr uint32 VanitySkillLine = 120;

// The display change reaches the client with the next object update, while aura updates are sent at once, so wait
// until the client has rebuilt the model before re-sending.
constexpr Milliseconds RefreshDelay = 300ms;

bool IsVanitySpell(uint32 spellId)
{
    SkillLineAbilityMapBounds const bounds = sSpellMgr->GetSkillLineAbilityMapBounds(spellId);
    for (auto itr = bounds.first; itr != bounds.second; ++itr)
        if (itr->second->SkillLine == VanitySkillLine)
            return true;
    return false;
}

bool NeedsVisualRefresh(AuraApplication const* application)
{
    SpellInfo const* info = application->GetBase()->GetSpellInfo();
    if (!info->SpellVisual[0] && !info->SpellVisual[1])
        return false;
    // Re-sending a model-changing aura would start another display change.
    if (info->HasAura(SPELL_AURA_TRANSFORM) || info->HasAura(SPELL_AURA_MOD_SHAPESHIFT) ||
        info->HasAura(SPELL_AURA_CLONE_CASTER))
        return false;
    return IsVanitySpell(info->Id);
}

void RefreshVanityVisuals(Player* player)
{
    if (!player->IsInWorld() || player->GetDisplayId() != player->GetNativeDisplayId())
        return;

    for (auto const& [slot, application] : *player->GetVisibleAuras())
        if (NeedsVisualRefresh(application))
            application->ClientUpdate(false);
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
        }, RefreshDelay);
    }
};

void AddSC_AscensionCosmeticVisualRefresh()
{
    new coa_cosmetic_visual_refresh();
}
