#ifndef MOD_COA_RAID_DIFFICULTY_WORLD_BOSS_INSTANCE_H
#define MOD_COA_RAID_DIFFICULTY_WORLD_BOSS_INSTANCE_H

#include "Chat.h"
#include "Creature.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "InstanceSaveMgr.h"
#include "Item.h"
#include "LootMgr.h"
#include "Mail.h"
#include "Map.h"
#include "MapMgr.h"
#include "Opcodes.h"
#include "PlayerScript.h"
#include "Player.h"
#include "ScriptedGossip.h"
#include "SetisLoot.h"
#include "UnitScript.h"
#include "WorldPacket.h"

#include <cmath>
#include <string>

// A world boss fought in the boss map Ascension built for him, the way Setis is: a shrine in the open world takes
// players in (Normal only), his health is per player in his map, he drops one of his items for every four players,
// every player gets Runes of Ascension, Bazaar Tokens and a Treasures of Azeroth chest, and the portal he leaves
// behind (where he falls, or at its fixed spot) or the shrine at the entrance takes them back out.
namespace coa_world_boss_instance
{
    constexpr uint32 ITEM_RUNE_OF_ASCENSION = 375250;
    constexpr uint32 ITEM_BAZAAR_TOKEN = 975001;
    constexpr uint32 ITEM_TREASURES_OF_AZEROTH = 1615011;
    constexpr uint32 RUNES = 250;
    constexpr uint32 TOKENS_MIN = 100;
    constexpr uint32 TOKENS_MAX = 150;
    constexpr uint8 NORMAL_GROUP = 1;
    constexpr float SHRINE_ARRIVAL = 20.0f;
    constexpr uint32 PORTAL_SECONDS = 600;

    struct Config
    {
        char const* boss;
        uint32 bossEntry;
        uint32 bossMap;
        Position entrance;
        uint32 shrineText;
        uint32 worldMap;
        Position shrine;
        uint32 exitPortal;
        Position exitPortalAt;      // its fixed spot; left at 0, the portal opens where he falls
    };

    inline void GiveOrMail(Player* player, std::string const& sender, uint32 item, uint32 count)
    {
        ItemPosCountVec dest;
        uint32 noSpace = 0;
        player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, item, count, &noSpace);
        if (count > noSpace)
            if (Item* stored = player->StoreNewItem(dest, item, true))
                player->SendNewItem(stored, count - noSpace, true, false);
        count = noSpace;
        if (!count)
            return;
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        MailDraft draft(sender, "Your bags were full, so this part of your reward was sent by mail.");
        if (Item* mailed = Item::CreateItem(item, count, player))
        {
            mailed->SaveToDB(trans);
            draft.AddItem(mailed);
        }
        draft.SendMailTo(trans, MailReceiver(player), MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM));
        CharacterDatabase.CommitTransaction(trans);
    }

    class go_altar : public GameObjectScript
    {
    public:
        go_altar(char const* name, Config const& config) : GameObjectScript(name), _config(config) { }

        bool OnGossipHello(Player* player, GameObject* go) override
        {
            if (!player->IsAlive())
                return true;
            ClearGossipMenuFor(player);
            AddGossipItemFor(player, GOSSIP_ICON_BATTLE, std::string("Challenge ") + _config.boss, GOSSIP_SENDER_MAIN,
                GOSSIP_ACTION_INFO_DEF + 1);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Take your hands off the shrine.", GOSSIP_SENDER_MAIN,
                GOSSIP_ACTION_INFO_DEF + 2);
            SendGossipMenuFor(player, _config.shrineText, go->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, GameObject* /*go*/, uint32 /*sender*/, uint32 action) override
        {
            CloseGossipMenuFor(player);
            if (action != GOSSIP_ACTION_INFO_DEF + 1 || !player->IsAlive())
                return true;
            // Only Normal is open for now: Heroic, Mythic and Ascended (raid difficulties 1-3) are refused.
            if (player->GetRaidDifficulty() != RAID_DIFFICULTY_10MAN_NORMAL)
            {
                ChatHandler(player->GetSession()).SendNotification("{} only answers the Normal difficulty.",
                    _config.boss);
                return true;
            }
            player->TeleportTo(_config.bossMap, _config.entrance.GetPositionX(), _config.entrance.GetPositionY(),
                _config.entrance.GetPositionZ(), _config.entrance.GetOrientation());
            return true;
        }

    private:
        Config const& _config;
    };

    class go_exit : public GameObjectScript
    {
    public:
        go_exit(char const* name, Config const& config) : GameObjectScript(name), _config(config) { }

        bool OnGossipHello(Player* player, GameObject* /*go*/) override
        {
            if (!player->IsAlive())
                return true;
            // Twenty yards out in front of the shrine, facing it.
            Position const& shrine = _config.shrine;
            float const away = shrine.GetOrientation();
            float const x = shrine.GetPositionX() + SHRINE_ARRIVAL * std::cos(away);
            float const y = shrine.GetPositionY() + SHRINE_ARRIVAL * std::sin(away);
            float z = shrine.GetPositionZ();
            if (Map* world = sMapMgr->CreateBaseMap(_config.worldMap))
            {
                float const ground = world->GetHeight(x, y, z + 20.0f);
                if (ground > INVALID_HEIGHT)
                    z = ground;
            }
            player->TeleportTo(_config.worldMap, x, y, z + 0.5f, Position::NormalizeOrientation(away + float(M_PI)));
            return true;
        }

    private:
        Config const& _config;
    };

    class boss_death : public UnitScript
    {
    public:
        boss_death(char const* name, Config const& config)
            : UnitScript(name, true, {UNITHOOK_ON_UNIT_DEATH}), _config(config) { }

        void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
        {
            Creature* boss = unit->ToCreature();
            if (!boss || boss->GetEntry() != _config.bossEntry || boss->GetMapId() != _config.bossMap)
                return;
            uint32 const raid = boss->GetMap()->GetPlayersCountExceptGMs();
            if (LootTemplate const* loot = LootTemplates_Creature.GetLootFor(boss->GetCreatureTemplate()->lootid))
            {
                Player const* looter = boss->GetLootRecipient();
                for (uint32 i = coa_setis::MinItems; i < coa_setis::LootItems(raid); ++i)
                    loot->Process(boss->loot, LootTemplates_Creature, boss->GetLootMode(), looter, NORMAL_GROUP);
            }
            std::string const sender = _config.boss;
            InstanceMap* instance = boss->GetMap()->ToInstanceMap();
            InstanceSave* save = instance ? sInstanceSaveMgr->GetInstanceSave(instance->GetInstanceId()) : nullptr;
            boss->GetMap()->DoForAllPlayers([&sender, save](Player* player)
            {
                if (save)
                {
                    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(),
                        save->GetMapId(), save->GetDifficulty());
                    if (bind && bind->perm)
                        return;
                    WorldPacket data(SMSG_INSTANCE_SAVE_CREATED, 4);
                    data << uint32(0);
                    player->SendDirectMessage(&data);
                    sInstanceSaveMgr->PlayerBindToInstance(player->GetGUID(), save, true, player);
                }
                GiveOrMail(player, sender, ITEM_RUNE_OF_ASCENSION, RUNES);
                GiveOrMail(player, sender, ITEM_BAZAAR_TOKEN, urand(TOKENS_MIN, TOKENS_MAX));
                GiveOrMail(player, sender, ITEM_TREASURES_OF_AZEROTH, 1);
            });
            Position const& at = _config.exitPortalAt.GetPositionX() != 0.0f ? _config.exitPortalAt
                : static_cast<Position const&>(*boss);
            boss->SummonGameObject(_config.exitPortal, at.GetPositionX(), at.GetPositionY(), at.GetPositionZ(),
                at.GetOrientation(), 0, 0, 0, 0, PORTAL_SECONDS, true, GO_SUMMON_TIMED_DESPAWN);
        }

    private:
        Config const& _config;
    };

    class revive : public PlayerScript
    {
    public:
        revive(char const* name, Config const& config)
            : PlayerScript(name, {PLAYERHOOK_ON_PLAYER_RESURRECT}), _config(config) { }

        // Brought back at the entrance, a player faces the way the shrine sends them in.
        void OnPlayerResurrect(Player* player, float /*restorePercent*/, bool& /*applySickness*/) override
        {
            Position const& at = _config.entrance;
            if (player->GetMapId() == _config.bossMap && player->GetExactDist2d(&at) < 30.0f)
                player->NearTeleportTo(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
                    at.GetOrientation());
        }

    private:
        Config const& _config;
    };

    inline void AddScripts(char const* altar, char const* exit, char const* leave, char const* death,
        Config const& config)
    {
        new go_altar(altar, config);
        new go_exit(exit, config);
        new go_exit(leave, config);
        new boss_death(death, config);
        new revive((std::string(death) + "_revive").c_str(), config);
    }
}

#endif
