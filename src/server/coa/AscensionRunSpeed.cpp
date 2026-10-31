/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Config.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 RUN_SPEED_AURA = 86000;
bool RunSpeedEnabled = false;

void SynchronizeRunSpeed(Player* player)
{
    if (!RunSpeedEnabled)
        return;
    if (player->IsAlive() && !player->HasAura(RUN_SPEED_AURA))
        player->AddAura(RUN_SPEED_AURA, player);
}

class ascension_run_speed_world final : public WorldScript
{
public:
    ascension_run_speed_world()
        : WorldScript("ascension_run_speed_world", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool reload) override
    {
        bool const enabled = sConfigMgr->GetOption<bool>("Ascension.RunSpeedAura.Enable", false);
        if (!reload)
            RunSpeedEnabled = enabled;
        else if (enabled != RunSpeedEnabled)
            LOG_WARN("coa", "Ascension.RunSpeedAura.Enable changes require a worldserver restart");
    }
};

class ascension_run_speed_record final : public GlobalScript
{
public:
    ascension_run_speed_record()
        : GlobalScript("ascension_run_speed_record", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (RunSpeedEnabled && info->Id == RUN_SPEED_AURA)
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_APPLY_AURA;
    }
};

class ascension_run_speed_player final : public PlayerScript
{
public:
    ascension_run_speed_player()
        : PlayerScript("ascension_run_speed_player", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_PLAYER_RESURRECT}) { }

    void OnPlayerLogin(Player* player) override
    {
        SynchronizeRunSpeed(player);
    }

    void OnPlayerResurrect(Player* player, float, bool&) override
    {
        SynchronizeRunSpeed(player);
    }
};
}

void AddSC_AscensionRunSpeed()
{
    new ascension_run_speed_world();
    new ascension_run_speed_record();
    new ascension_run_speed_player();
}
