/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Chat.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Language.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include "WorldState.h"
#include <atomic>

namespace
{
uint32 g_configuredStage = RaidRelease::StageMoltenCore;
std::atomic<uint32> g_raidReleaseStage = RaidRelease::StageMoltenCore;
std::atomic<uint32> g_defeatVersion = 0;
bool g_autoAdvance = false;

uint32 StoredDefeatLevel(RaidRelease::FinalBoss const& boss)
{
    return uint32(sWorldState->getWorldState(boss.worldState));
}

uint32 UnlockedStage()
{
    uint32 unlocked = 0;
    for (RaidRelease::FinalBoss const& boss : RaidRelease::FinalBosses)
        if (boss.opensStage > unlocked && StoredDefeatLevel(boss) != RaidRelease::DefeatedNever)
            unlocked = boss.opensStage;
    return unlocked;
}

void RefreshReleasedStage()
{
    g_raidReleaseStage = g_autoAdvance ? RaidRelease::EffectiveStage(g_configuredStage, UnlockedStage())
        : g_configuredStage;
}

void LoadRaidReleaseStage()
{
    g_configuredStage = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ReleaseStage",
        RaidRelease::StageMoltenCore);
    g_autoAdvance = sConfigMgr->GetOption<bool>("Ascension.RaidRelease.AutoAdvance", false);
    RefreshReleasedStage();
    ++g_defeatVersion;
}

char const* RaidName(uint32 mapId)
{
    switch (mapId)
    {
        case RaidRelease::MapZulGurub: return "Zul'Gurub";
        case RaidRelease::MapMoltenCore: return "Molten Core";
        case RaidRelease::MapOnyxiasLair: return "Onyxia's Lair";
        case RaidRelease::MapBlackwingLair: return "Blackwing Lair";
        case RaidRelease::MapRuinsOfAhnQiraj: return "Ruins of Ahn'Qiraj";
        case RaidRelease::MapTempleOfAhnQiraj: return "Temple of Ahn'Qiraj";
        case RaidRelease::MapNaxxramas: return "Naxxramas";
        default: return "";
    }
}

char const* StageName(uint32 stage)
{
    switch (stage)
    {
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
    if (!killer || !killed || killer->IsGameMaster() || !killed->GetMap())
        return;
    RaidRelease::FinalBoss const* boss = RaidRelease::FindFinalBoss(killed->GetEntry());
    if (!boss || boss->mapId != killed->GetMapId())
        return;

    uint32 const previous = StoredDefeatLevel(*boss);
    uint32 const level = RaidRelease::DefeatLevel(uint32(killed->GetMap()->GetSpawnMode()));
    if (level <= previous)
        return;

    uint32 const previousStage = g_raidReleaseStage;
    sWorldState->setWorldState(boss->worldState, level);
    RefreshReleasedStage();
    ++g_defeatVersion;
    LOG_INFO("scripts", "Raid release: {} first defeated at level {} by {}'s group, release stage {} -> {}",
        RaidName(boss->mapId), level, killer->GetName(), previousStage, g_raidReleaseStage.load());

    if (previous == RaidRelease::DefeatedNever && g_raidReleaseStage > previousStage)
        ChatHandler(nullptr).SendWorldText("|cffff8000{} has been defeated for the first time! {} is now open.|r",
            RaidName(boss->mapId), StageName(g_raidReleaseStage.load()));
    else if (previous == RaidRelease::DefeatedNever)
        ChatHandler(nullptr).SendWorldText("|cffff8000{} has been defeated for the first time!|r",
            RaidName(boss->mapId));
    if (level == RaidRelease::DefeatedHeroic)
        ChatHandler(nullptr).SendWorldText("|cffff8000{} has been defeated on Heroic difficulty for the first time!|r",
            RaidName(boss->mapId));
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

std::uint32_t RaidRelease::RaidDefeatLevel(std::uint32_t mapId)
{
    FinalBoss const* boss = FinalBossOfMap(mapId);
    return boss ? StoredDefeatLevel(*boss) : DefeatedNever;
}

std::uint32_t RaidRelease::DefeatVersion()
{
    return g_defeatVersion;
}

void AddSC_AscensionRaidRelease()
{
    new ascension_raid_release_config();
    new ascension_raid_release_player();
}
