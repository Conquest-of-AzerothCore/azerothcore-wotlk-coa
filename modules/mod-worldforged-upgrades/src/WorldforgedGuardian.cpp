/*
 * The Guardian of Time.
 *
 * His menu as live Ascension served it on Season 10: General Goods, Heirlooms (level 60), Upgrade Worldforged
 * and, for free-pick Heroes only, Mystic Scrolls with one store per class. Freepick and Warcraft Reborn realms
 * also sell the Mystic Enchanting altars. Every store is a vendor list held by
 * an unspawned creature (9781000 and on) that SendListInventory opens from the Guardian himself. The Worldforged
 * upgrades send SMSG_OPEN_CUSTOM_STORE and the client opens its own RPGItemStore window.
 *
 * Where he stood is not recovered. The client keeps the call board points of
 * interest, but only X and Y, so any spawn written here would be a guess. He is
 * created without one; place him with `.npc add 9780012`.
 */

#include "WorldforgedUpgrades.h"

#include "AscensionFreepick.h"
#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

#include <array>

namespace Worldforged
{
    void OpenStore(Player* player, uint32 store);
}

namespace
{
    constexpr uint32 INVISIBLE_GOSSIP_ICON = 34;
    constexpr uint8 HEIRLOOM_LEVEL = 60;
    constexpr uint32 GENERAL_GOODS = 9781000;
    constexpr uint32 HEIRLOOMS = 9781001;
    constexpr uint32 ALTARS = 9781012;

    enum GossipAction
    {
        ACTION_WEAPONS = GOSSIP_ACTION_INFO_DEF + 1,
        ACTION_ARMOUR = GOSSIP_ACTION_INFO_DEF + 2,
        ACTION_GENERAL_GOODS = GOSSIP_ACTION_INFO_DEF + 3,
        ACTION_HEIRLOOMS = GOSSIP_ACTION_INFO_DEF + 4,
        ACTION_MYSTIC_SCROLLS = GOSSIP_ACTION_INFO_DEF + 5,
        ACTION_ALTARS = GOSSIP_ACTION_INFO_DEF + 6,
        ACTION_MYSTIC_SCROLL_CLASS = GOSSIP_ACTION_INFO_DEF + 100,
    };

    struct ScrollStore
    {
        char const* Icon;
        char const* Class;
        uint32 Vendor;
    };

    constexpr std::array<ScrollStore, 10> SCROLL_STORES = { {
        { "Ability_Rogue_Ambush", "Warrior", 9781002 },
        { "Ability_ThunderBolt", "Paladin", 9781003 },
        { "Ability_MeleeDamage", "Hunter", 9781004 },
        { "Spell_Shadow_RitualOfSacrifice", "Rogue", 9781005 },
        { "Spell_Holy_HolySmite", "Priest", 9781006 },
        { "Spell_DeathKnight_IceTouch", "Death Knight", 9781007 },
        { "Spell_Nature_Lightning", "Shaman", 9781008 },
        { "Spell_Fire_FlameBolt", "Mage", 9781009 },
        { "Spell_Shadow_ShadowBolt", "Warlock", 9781010 },
        { "Spell_Nature_AbolishMagic", "Druid", 9781011 },
    } };

    std::string IconText(std::string const& icon, std::string const& text)
    {
        return "|TInterface/ICONS/" + icon + ":30:30:-18:0|t|r" + text;
    }

    void AddOption(Player* player, std::string const& icon, std::string const& text, uint32 action)
    {
        AddGossipItemFor(player, INVISIBLE_GOSSIP_ICON, IconText(icon, text), GOSSIP_SENDER_MAIN, action);
    }

    bool SellsAltars()
    {
        return AscensionFreepick::RealmOffersMysticAltars();
    }

    void SendMainMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        AddOption(player, "Inv_Misc_Coin_02", "General Goods", ACTION_GENERAL_GOODS);
        AddOption(player, "inv_axe_09", "Heirlooms |cffFF0000(Requires a level 60)|r", ACTION_HEIRLOOMS);
        if (AscensionFreepick::IsFreepickHero(player))
            AddOption(player, "inv_misc_scrollunrolled01c", "Mystic Scrolls", ACTION_MYSTIC_SCROLLS);
        if (SellsAltars())
            AddOption(player, "ability_racial_arcaneaffinity", "Altars", ACTION_ALTARS);
        AddOption(player, "Mail_GMIcon", "Upgrade Worldforged Weapons", ACTION_WEAPONS);
        AddOption(player, "Mail_GMIcon", "Upgrade Worldforged Armor", ACTION_ARMOUR);
        SendGossipMenuFor(player, Worldforged::GUARDIAN_ENTRY, creature->GetGUID());
    }

    void SendScrollMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);
        for (uint32 index = 0; index < SCROLL_STORES.size(); ++index)
            AddOption(player, SCROLL_STORES[index].Icon, SCROLL_STORES[index].Class,
                ACTION_MYSTIC_SCROLL_CLASS + index);
        SendGossipMenuFor(player, Worldforged::GUARDIAN_ENTRY, creature->GetGUID());
    }
}

class npc_worldforged_guardian : public CreatureScript
{
public:
    npc_worldforged_guardian() : CreatureScript("npc_worldforged_guardian") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        SendMainMenu(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        switch (action)
        {
            case ACTION_WEAPONS:
                CloseGossipMenuFor(player);
                Worldforged::OpenStore(player, Worldforged::STORE_WEAPONS);
                return true;
            case ACTION_ARMOUR:
                CloseGossipMenuFor(player);
                Worldforged::OpenStore(player, Worldforged::STORE_ARMOUR);
                return true;
            case ACTION_GENERAL_GOODS:
                CloseGossipMenuFor(player);
                player->GetSession()->SendListInventory(creature->GetGUID(), GENERAL_GOODS);
                return true;
            case ACTION_HEIRLOOMS:
                if (player->GetLevel() < HEIRLOOM_LEVEL)
                {
                    ChatHandler(player->GetSession()).SendSysMessage("You must be level 60 to buy heirlooms.");
                    SendMainMenu(player, creature);
                    return true;
                }
                CloseGossipMenuFor(player);
                player->GetSession()->SendListInventory(creature->GetGUID(), HEIRLOOMS);
                return true;
            case ACTION_ALTARS:
                if (!SellsAltars())
                    break;
                CloseGossipMenuFor(player);
                player->GetSession()->SendListInventory(creature->GetGUID(), ALTARS);
                return true;
            case ACTION_MYSTIC_SCROLLS:
                if (!AscensionFreepick::IsFreepickHero(player))
                    break;
                SendScrollMenu(player, creature);
                return true;
            default:
                break;
        }

        uint32 const store = action - ACTION_MYSTIC_SCROLL_CLASS;
        if (action >= ACTION_MYSTIC_SCROLL_CLASS && store < SCROLL_STORES.size() &&
            AscensionFreepick::IsFreepickHero(player))
        {
            CloseGossipMenuFor(player);
            player->GetSession()->SendListInventory(creature->GetGUID(), SCROLL_STORES[store].Vendor);
            return true;
        }
        CloseGossipMenuFor(player);
        return true;
    }
};

void AddWorldforgedGuardianScripts()
{
    new npc_worldforged_guardian();
}
