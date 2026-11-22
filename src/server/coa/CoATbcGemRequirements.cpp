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
    for (TbcGemRequirements::Mapping const& row : TbcGemRequirements::Mappings)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(row.gem);
        if (!item || item->RequiredLevel > 60)
            continue;
        GemPropertiesEntry const* property = sGemPropertiesStore.LookupEntry(item->GemProperties);
        SpellItemEnchantmentEntry const* enchantment = sSpellItemEnchantmentStore.LookupEntry(row.enchantment);
        if (item->GemProperties != row.property || !property ||
            property->spellitemenchantement != row.enchantment || !enchantment || enchantment->GemID != row.gem)
        {
            LOG_ERROR("server.loading", "Invalid TBC gem requirement mapping for item {}", row.gem);
            continue;
        }
        if (enchantment->requiredLevel > 60)
            const_cast<SpellItemEnchantmentEntry*>(enchantment)->requiredLevel = 60;
        Gems.insert(row.gem);
    }
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
