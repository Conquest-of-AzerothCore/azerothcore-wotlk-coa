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

// Vanity visuals lost after a transform (#9463).
//
// Vanity spells such as Blazing Irie Wings (12000142) are permanent auras whose look is a client-side spell
// visual, drawn while the aura is in the player's aura list. When a transform or other model change ends, the
// server restores the native display and the client rebuilds the player model without those visuals, although the
// auras are still applied. The client only draws a state visual when an aura is added, so an "applied" update for
// an aura it already shows does nothing. Once the player is back on the native model, this re-sends each vanity
// aura as removed and then added, so the client draws its visual on the rebuilt model.
//
// Only vanity auras (skill line 120, "!Ascension Vanity Items") are refreshed. A fake removal would replay a
// removal ("state done") visual, and of the 918 vanity spells with a visual in the 2026-09-01 client only the two
// Chronometric Pressure spells have one, so those are skipped. The auras themselves are not changed on the server.
namespace
{
constexpr uint32 VanitySkillLine = 120;

// Vanity spells whose visual plays an effect on removal (Chronometric Pressure); refreshing them would replay it.
constexpr std::array<uint32, 2> RemovalVisualVanitySpells = { 364787, 364878 };

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
    if (std::find(RemovalVisualVanitySpells.begin(), RemovalVisualVanitySpells.end(), info->Id) !=
        RemovalVisualVanitySpells.end())
        return false;
    return IsVanitySpell(info->Id);
}

void RefreshVanityVisuals(Player* player)
{
    if (!player->IsInWorld() || player->GetDisplayId() != player->GetNativeDisplayId())
        return;

    std::vector<AuraApplication*> refresh;
    for (auto const& [slot, application] : *player->GetVisibleAuras())
        if (NeedsVisualRefresh(application))
            refresh.push_back(application);

    for (AuraApplication* application : refresh)
    {
        // AuraApplication::ClientUpdate(true) asserts that the slot is already empty on the server, so the client-only
        // removal is built here: the slot followed by spell 0, as BuildUpdatePacket writes for a removed aura.
        WorldPacket removal(SMSG_AURA_UPDATE, 8 + 1 + 4);
        removal << player->GetPackGUID();
        removal << uint8(application->GetSlot());
        removal << uint32(0);
        player->SendMessageToSet(&removal, true);

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
        }, RefreshDelay);
    }
};

void AddSC_AscensionCosmeticVisualRefresh()
{
    new coa_cosmetic_visual_refresh();
}
