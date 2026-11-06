/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Language.h"
#include "Log.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "WorldState.h"
#include <atomic>

namespace
{
constexpr uint32 WorldStateDefeatedStage = 20120;

uint32 g_configuredStage = RaidRelease::StageMoltenCore;
std::atomic<uint32> g_raidReleaseStage = RaidRelease::StageMoltenCore;
bool g_autoAdvance = false;

uint32 DefeatedStage()
{
    return uint32(sWorldState->getWorldState(WorldStateDefeatedStage));
}

void RefreshReleasedStage()
{
    g_raidReleaseStage = g_autoAdvance ? RaidRelease::EffectiveStage(g_configuredStage, DefeatedStage())
        : g_configuredStage;
}

void LoadRaidReleaseStage()
{
    g_configuredStage = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ReleaseStage",
        RaidRelease::StageMoltenCore);
    g_autoAdvance = sConfigMgr->GetOption<bool>("Ascension.RaidRelease.AutoAdvance", false);
    RefreshReleasedStage();
}

char const* RaidName(uint32 stage)
{
    switch (stage)
    {
        case RaidRelease::StageZulGurub: return "Zul'Gurub";
        case RaidRelease::StageMoltenCore: return "Molten Core";
        case RaidRelease::StageOnyxiasLair: return "Onyxia's Lair";
        case RaidRelease::StageBlackwingLair: return "Blackwing Lair";
        case RaidRelease::StageAhnQiraj: return "Ruins of Ahn'Qiraj and Temple of Ahn'Qiraj";
        case RaidRelease::StageNaxxramas: return "Naxxramas";
        default: return "";
    }
}

void RecordFinalBossKill(Player* killer, Creature* killed)
{
    if (!g_autoAdvance || !killer || !killed || killer->IsGameMaster())
        return;
    uint32 const defeated = DefeatedStage();
    if (!RaidRelease::AdvancesStage(killed->GetEntry(), g_raidReleaseStage, defeated))
        return;

    uint32 const stage = RaidRelease::DefeatedStage(killed->GetEntry());
    uint32 const previous = g_raidReleaseStage;
    sWorldState->setWorldState(WorldStateDefeatedStage, stage);
    RefreshReleasedStage();
    LOG_INFO("scripts", "Raid release: {} defeated by {}'s group, release stage {} -> {}",
        RaidName(stage), killer->GetName(), previous, g_raidReleaseStage.load());

    if (g_raidReleaseStage > previous)
        ChatHandler(nullptr).SendWorldText("|cffff8000{} has been defeated! {} is now open.|r", RaidName(stage),
            RaidName(g_raidReleaseStage.load()));
    else
        ChatHandler(nullptr).SendWorldText("|cffff8000{} has been defeated!|r", RaidName(stage));
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
        : PlayerScript("ascension_raid_release_player", { PLAYERHOOK_CAN_ENTER_MAP, PLAYERHOOK_ON_CREATURE_KILL,
            PLAYERHOOK_ON_CREATURE_KILLED_BY_PET }) { }

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

    void OnPlayerCreatureKill(Player* killer, Creature* killed) override
    {
        RecordFinalBossKill(killer, killed);
    }

    void OnPlayerCreatureKilledByPet(Player* owner, Creature* killed) override
    {
        RecordFinalBossKill(owner, killed);
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
}
