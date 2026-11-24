/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoATbcGemRequirementsData.h"
#include "DBCStores.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include <set>

namespace
{
std::set<uint32> Gems;

void LoadRequirements()
{
    Gems.clear();
    constexpr std::array<TbcGemRequirements::Mapping, 2> enchantingSpheres = {{
        {22459, 342, 2948},
        {22460, 341, 2947}
    }};
    auto loadRequirement = [](TbcGemRequirements::Mapping const& row)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(row.gem);
        if (!item || item->RequiredLevel > 60)
            return;
        GemPropertiesEntry const* property = sGemPropertiesStore.LookupEntry(item->GemProperties);
        SpellItemEnchantmentEntry const* enchantment = sSpellItemEnchantmentStore.LookupEntry(row.enchantment);
        if (item->GemProperties != row.property || !property ||
            property->spellitemenchantement != row.enchantment || !enchantment || enchantment->GemID != row.gem)
        {
            LOG_ERROR("server.loading", "Invalid TBC gem requirement mapping for item {}", row.gem);
            return;
        }
        if (enchantment->requiredLevel > 60)
            const_cast<SpellItemEnchantmentEntry*>(enchantment)->requiredLevel = 60;
        Gems.insert(row.gem);
    };
    for (auto const& row : TbcGemRequirements::Mappings)
        loadRequirement(row);
    for (auto const& row : enchantingSpheres)
        loadRequirement(row);
    LOG_INFO("server.loading", "Loaded {} level-60 TBC gem requirements", Gems.size());
}

class TbcGemRequirementLoader final : public WorldScript
{
public:
    TbcGemRequirementLoader() : WorldScript("TbcGemRequirementLoader") { }

    void OnStartup() override
    {
        LoadRequirements();
    }
};

class TbcGemClientItems final : public PlayerScript
{
public:
    TbcGemClientItems() : PlayerScript("TbcGemClientItems", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        WorldSession* session = player->GetSession();
        if (!session || session->IsBot())
            return;
        for (uint32 gem : Gems)
            session->SendItemQuerySingleResponse(gem);
    }
};
}

void AddSC_CoATbcGemRequirements()
{
    new TbcGemRequirementLoader();
    new TbcGemClientItems();
}
