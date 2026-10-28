/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Config.h"
#include "DBCStores.h"
#include "DBCStructure.h"
#include "Language.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
uint32 g_raidReleaseStage = RaidRelease::StageMoltenCore;

void LoadRaidReleaseStage()
{
    g_raidReleaseStage = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ReleaseStage",
        RaidRelease::StageMoltenCore);
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
