/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "GlobalScript.h"
#include "Language.h"
#include "LFGMgr.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "WorldState.h"
#include <atomic>
#include <shared_mutex>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 WorldStateStageOverride = 20120;
constexpr uint32 WorldStateReleasedStage = 20121;
constexpr uint32 KelThuzad = 15990;
constexpr uint32 ReturnToKhadgar = 9837;
constexpr char KarazhanUnlockSetting[] = "core.coa.karazhan";

uint32 g_configuredStage = RaidRelease::StageMoltenCore;
std::atomic<uint32> g_raidReleaseStage = RaidRelease::StageMoltenCore;

bool HasKarazhanUnlock(Player const* player)
{
    PlayerSettingVector const* settings = player->FindPlayerSettings(KarazhanUnlockSetting);
    return settings && !settings->empty() && settings->front().IsEnabled();
}

void RefreshDungeonFinderLocks()
{
    std::shared_lock lock(*HashMapHolder<Player>::GetLock());
    for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
        if (player->IsInWorld())
            sLFGMgr->InitializeLockedDungeons(player, player->GetGroup());
}

void RefreshReleasedStage()
{
    uint32 const stageOverride = uint32(sWorldState->getWorldState(WorldStateStageOverride));
    g_raidReleaseStage = stageOverride ? stageOverride - 1 : g_configuredStage;
    sWorldState->setWorldState(WorldStateReleasedStage, g_raidReleaseStage);
    RefreshDungeonFinderLocks();
}

void LoadRaidReleaseStage()
{
    g_configuredStage = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ReleaseStage",
        RaidRelease::StageZulGurub);
    RefreshReleasedStage();
}

char const* StageName(uint32 stage)
{
    switch (stage)
    {
        case 0: return "Normal Dungeons";
        case RaidRelease::StageHeroicDungeons: return "Heroic Dungeons";
        case RaidRelease::StageMythicDungeons: return "Mythic Dungeons";
        case RaidRelease::StageZulGurub: return "Zul'Gurub";
        case RaidRelease::StageMoltenCore: return "Molten Core";
        case RaidRelease::StageOnyxiasLair: return "Onyxia's Lair";
        case RaidRelease::StageBlackwingLair: return "Blackwing Lair";
        case RaidRelease::StageAhnQiraj: return "Ruins of Ahn'Qiraj and Temple of Ahn'Qiraj";
        case RaidRelease::StageNaxxramas: return "Naxxramas";
        case RaidRelease::StageKarazhan: return "Karazhan";
        default: return "";
    }
}

class ascension_raid_release_config : public WorldScript
{
public:
    ascension_raid_release_config()
        : WorldScript("ascension_raid_release_config", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        LoadRaidReleaseStage();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadRaidReleaseStage();
    }
};

class ascension_raid_release_player : public PlayerScript
{
public:
    ascension_raid_release_player()
        : PlayerScript("ascension_raid_release_player", { PLAYERHOOK_CAN_ENTER_MAP, PLAYERHOOK_ON_MAP_CHANGED }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        sLFGMgr->InitializeLockedDungeons(player, player->GetGroup());
    }

    bool OnPlayerCanEnterMap(Player* player, MapEntry const* entry, InstanceTemplate const*, MapDifficulty const*,
        bool) override
    {
        bool released = RaidRelease::IsRaidReleased(entry->MapID, g_raidReleaseStage);
        if (released && !entry->IsRaid())
        {
            Difficulty difficulty = player->GetDifficulty(false);
            GetDownscaledMapDifficultyData(entry->MapID, difficulty);
            released = RaidRelease::IsDungeonDifficultyReleased(difficulty, g_raidReleaseStage);
        }

        if (!released)
        {
            player->GetSession()->SendAreaTriggerMessage(LANG_INSTANCE_CLOSED);
            return false;
        }

        if (entry->MapID != RaidRelease::MapKarazhan || player->GetSession()->IsBot())
            return true;

        if (!player->GetQuestRewardStatus(ReturnToKhadgar))
        {
            player->GetSession()->SendAreaTriggerMessage("Complete Return to Khadgar to enter Karazhan.");
            return false;
        }

        if (!HasKarazhanUnlock(player))
        {
            player->GetSession()->SendAreaTriggerMessage("Defeat Kel'Thuzad in Naxxramas to enter Karazhan.");
            return false;
        }

        return true;
    }
};

class ascension_karazhan_unlock : public GlobalScript
{
public:
    ascension_karazhan_unlock()
        : GlobalScript("ascension_karazhan_unlock", { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType type, uint32 creditEntry, Unit* source,
        Difficulty, DungeonEncounterList const*, uint32, bool updated) override
    {
        if (!updated || !source || map->GetId() != RaidRelease::MapNaxxramas ||
            type != ENCOUNTER_CREDIT_KILL_CREATURE || creditEntry != KelThuzad)
            return;

        for (auto const& reference : map->GetPlayers())
        {
            Player* player = reference.GetSource();
            if (!player || player->GetSession()->IsBot() || !player->IsAtGroupRewardDistance(source) ||
                HasKarazhanUnlock(player))
                continue;

            player->UpdatePlayerSetting(KarazhanUnlockSetting, 0, 1);
            CharacterDatabase.Execute(PlayerSettingsStore::PrepareReplaceStatement(player->GetGUID().GetCounter(),
                KarazhanUnlockSetting, *player->FindPlayerSettings(KarazhanUnlockSetting)));
        }
    }
};

class ascension_dungeon_finder_release_locks : public GlobalScript
{
public:
    ascension_dungeon_finder_release_locks()
        : GlobalScript("ascension_dungeon_finder_release_locks", { GLOBALHOOK_ON_INITIALIZE_LOCKED_DUNGEONS }) { }

    void OnInitializeLockedDungeons(Player*, uint8&, uint32& lockData, lfg::LFGDungeonData const* dungeon) override
    {
        if (lockData)
            return;

        MapEntry const* map = sMapStore.LookupEntry(dungeon->map);
        if (map && !map->IsRaid() && !RaidRelease::IsDungeonDifficultyReleased(dungeon->difficulty, g_raidReleaseStage))
            lockData = lfg::LFG_LOCKSTATUS_NOT_IN_SEASON;
    }
};

class ascension_raid_release_commands : public CommandScript
{
public:
    ascension_raid_release_commands() : CommandScript("ascension_raid_release_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable raidPhaseTable =
        {
            { "", HandleStatus, SEC_GAMEMASTER, Console::Yes },
            { "set", HandleSet, SEC_ADMINISTRATOR, Console::Yes },
            { "clear", HandleClear, SEC_ADMINISTRATOR, Console::Yes },
        };
        static ChatCommandTable commandTable =
        {
            { "raidphase", raidPhaseTable },
        };
        return commandTable;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        uint32 const stageOverride = uint32(sWorldState->getWorldState(WorldStateStageOverride));
        handler->PSendSysMessage("Release stage {} ({}). Config {}, override {}.", g_raidReleaseStage.load(),
            StageName(g_raidReleaseStage.load()), g_configuredStage,
            stageOverride ? std::to_string(stageOverride - 1) : std::string("none"));
        return true;
    }

    static bool HandleSet(ChatHandler* handler, uint32 stage)
    {
        if (stage > RaidRelease::AllReleased)
        {
            handler->PSendSysMessage("Release stage must be 0-{}.", RaidRelease::AllReleased);
            return false;
        }
        sWorldState->setWorldState(WorldStateStageOverride, stage + 1);
        RefreshReleasedStage();
        handler->PSendSysMessage("Release stage set to {} ({}).", stage, StageName(stage));
        return true;
    }

    static bool HandleClear(ChatHandler* handler)
    {
        sWorldState->setWorldState(WorldStateStageOverride, 0);
        RefreshReleasedStage();
        handler->PSendSysMessage("Release stage override cleared; now {} ({}).", g_raidReleaseStage.load(),
            StageName(g_raidReleaseStage.load()));
        return true;
    }
};
}

std::uint32_t RaidRelease::ReleasedStage()
{
    return g_raidReleaseStage;
}

void AddSC_AscensionRaidRelease()
{
    new ascension_raid_release_config();
    new ascension_raid_release_player();
    new ascension_karazhan_unlock();
    new ascension_dungeon_finder_release_locks();
    new ascension_raid_release_commands();
}
