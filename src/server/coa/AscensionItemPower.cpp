/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionItemPowerTable.h"
#include "Log.h"
#include "Timer.h"
#include "World.h"
#include "WorldScript.h"

namespace
{
class Loader : public WorldScript
{
public:
    Loader() : WorldScript("ItemPowerLoader", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        uint32 const started = getMSTime();
        std::filesystem::path const path = std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "ItemAddon.dbc";
        if (!ItemPowerTable::Loaded().Load(path))
        {
            LOG_ERROR("server.loading", "Item power comes from equip spells only: {} is missing or not an "
                "ItemAddon table", path.string());
            return;
        }

        LOG_INFO("server.loading", ">> Loaded PvE and PvP Power for {} items in {} ms",
            ItemPowerTable::Loaded().Size(), GetMSTimeDiffToNow(started));
    }
};
}

void AddSC_AscensionItemPower()
{
    new Loader();
}
