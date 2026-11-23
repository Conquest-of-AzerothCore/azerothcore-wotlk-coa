/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftReborn.h"
#include "Creature.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Trainer.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <string>

namespace
{
constexpr uint32 INVISIBLE_GOSSIP_ICON = 34;
constexpr uint32 SCROLL_SHOP_SENDER = 0x4D534853;
constexpr uint32 SCROLL_SHOP_ACTION = 1;

struct ScrollShop
{
    uint8 Class;
    char const* Icon;
    uint32 Vendor;
};

constexpr std::array<ScrollShop, 9> SCROLL_SHOPS = { {
    { CLASS_WARRIOR, "Ability_Rogue_Ambush", 9781022 },
    { CLASS_PALADIN, "Ability_ThunderBolt", 9781023 },
    { CLASS_HUNTER, "Ability_MeleeDamage", 9781024 },
    { CLASS_ROGUE, "Spell_Shadow_RitualOfSacrifice", 9781025 },
    { CLASS_PRIEST, "Spell_Holy_HolySmite", 9781026 },
    { CLASS_SHAMAN, "Spell_Nature_Lightning", 9781027 },
    { CLASS_MAGE, "Spell_Fire_FlameBolt", 9781028 },
    { CLASS_WARLOCK, "Spell_Shadow_ShadowBolt", 9781029 },
    { CLASS_DRUID, "Spell_Nature_AbolishMagic", 9781030 },
} };

ScrollShop const* ShopFor(Player const* player, Creature const* creature)
{
    if (!AscensionWarcraftReborn::IsRebornCharacter(player) || creature->GetScriptId())
        return nullptr;
    Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(creature->GetEntry());
    if (!trainer || trainer->GetTrainerType() != Trainer::Type::Class ||
        trainer->GetTrainerRequirement() != player->getClass())
        return nullptr;
    auto const shop = std::find_if(SCROLL_SHOPS.begin(), SCROLL_SHOPS.end(),
        [player](ScrollShop const& entry) { return entry.Class == player->getClass(); });
    return shop == SCROLL_SHOPS.end() ? nullptr : &*shop;
}

std::string OptionText(ScrollShop const& shop)
{
    return "|TInterface/ICONS/" + std::string(shop.Icon) + ":30:30:-18:0|t|rMystic Scrolls";
}
}

class AscensionWarcraftRebornScrollShops final : public AllCreatureScript
{
public:
    AscensionWarcraftRebornScrollShops() : AllCreatureScript("AscensionWarcraftRebornScrollShops") { }

    bool CanCreatureGossipHello(Player* player, Creature* creature) override
    {
        ScrollShop const* shop = ShopFor(player, creature);
        if (!shop)
            return false;
        if (!creature->HasNpcFlag(UNIT_NPC_FLAG_VENDOR))
            creature->SetNpcFlag(UNIT_NPC_FLAG_VENDOR);
        player->PrepareGossipMenu(creature, creature->GetGossipMenuId(), true);
        AddGossipItemFor(player, INVISIBLE_GOSSIP_ICON, OptionText(*shop), SCROLL_SHOP_SENDER, SCROLL_SHOP_ACTION);
        player->SendPreparedGossip(creature);
        return true;
    }

    bool CanCreatureGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        if (sender != SCROLL_SHOP_SENDER || action != SCROLL_SHOP_ACTION)
            return false;
        CloseGossipMenuFor(player);
        if (ScrollShop const* shop = ShopFor(player, creature))
            player->GetSession()->SendListInventory(creature->GetGUID(), shop->Vendor);
        return true;
    }
};

void AddSC_AscensionWarcraftRebornScrollShops()
{
    new AscensionWarcraftRebornScrollShops();
}
