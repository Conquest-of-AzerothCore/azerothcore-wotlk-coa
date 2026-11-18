/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundBrackets.h"
#include "Config.h"
#include "ScriptMgr.h"

namespace
{
class ascension_battleground_wide_brackets_config : public WorldScript
{
public:
    ascension_battleground_wide_brackets_config()
        : WorldScript("ascension_battleground_wide_brackets_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            return;

        AscensionBattlegroundBrackets::Configure(
            sConfigMgr->GetOption<bool>("CoA.Battleground.WideBrackets.Enable", true),
            sConfigMgr->GetOption<std::string>("CoA.Battleground.WideBrackets.Ranges", "10-29,30-49,50-59"));
    }
};
}

void AddSC_AscensionBattlegroundCatchUp()
{
    new ascension_battleground_wide_brackets_config();
}
