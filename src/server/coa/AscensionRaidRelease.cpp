/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Language.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "WorldState.h"
#include <atomic>

using namespace Acore::ChatCommands;

namespace
{
constexpr uint32 WorldStateStageOverride = 20120;
constexpr uint32 WorldStateReleasedStage = 20121;

uint32 g_configuredStage = RaidRelease::StageMoltenCore;
std::atomic<uint32> g_raidReleaseStage = RaidRelease::StageMoltenCore;

void RefreshReleasedStage()
{
    uint32 const stageOverride = uint32(sWorldState->getWorldState(WorldStateStageOverride));
    g_raidReleaseStage = stageOverride ? stageOverride - 1 : g_configuredStage;
    sWorldState->setWorldState(WorldStateReleasedStage, g_raidReleaseStage);
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
        : PlayerScript("ascension_raid_release_player", { PLAYERHOOK_CAN_ENTER_MAP }) { }

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

        if (released)
            return true;

        player->GetSession()->SendAreaTriggerMessage(LANG_INSTANCE_CLOSED);
        return false;
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
    new ascension_raid_release_commands();
}
