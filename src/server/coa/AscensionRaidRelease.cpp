/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRaidReleasePolicy.h"
#include "Config.h"
#include "DBCStructure.h"
#include "Language.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

namespace
{
uint32 g_raidReleaseStage = RaidRelease::AllRaidsReleased;

void LoadRaidReleaseStage()
{
    g_raidReleaseStage = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ReleaseStage",
        RaidRelease::AllRaidsReleased);
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
        if (RaidRelease::IsRaidReleased(entry->MapID, g_raidReleaseStage))
            return true;

        player->GetSession()->SendAreaTriggerMessage(LANG_INSTANCE_CLOSED);
        return false;
    }
};
}

void AddSC_AscensionRaidRelease()
{
    new ascension_raid_release_config();
    new ascension_raid_release_player();
}
