/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <array>

namespace
{
constexpr std::array<uint32, 2> GhostClawSpells = {{803985, 807234}};

class reaper_ghost_claw_kill_reset : public PlayerScript
{
public:
    reaper_ghost_claw_kill_reset() : PlayerScript("reaper_ghost_claw_kill_reset",
        {PLAYERHOOK_ON_CREATURE_KILL, PLAYERHOOK_ON_PVP_KILL}) { }

    void OnPlayerCreatureKill(Player* killer, Creature*) override { Reset(killer); }
    void OnPlayerPVPKill(Player* killer, Player*) override { Reset(killer); }

private:
    static void Reset(Player* player)
    {
        if (!player || player->getClass() != CLASS_REAPER)
            return;

        for (uint32 spellId : GhostClawSpells)
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
            if (!info || !player->HasSpell(spellId))
                continue;

            if (info->MaxCharges)
                player->RestoreSpellCharge(spellId);
            else if (player->HasSpellCooldown(spellId))
                player->RemoveSpellCooldown(spellId, true);
        }
    }
};
}

void AddSC_AscensionReaperGhostClaw()
{
    new reaper_ghost_claw_kill_reset();
}
