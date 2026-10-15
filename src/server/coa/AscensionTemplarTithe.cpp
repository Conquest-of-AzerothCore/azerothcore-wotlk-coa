/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
enum
{
    SPELL_RESET_TITHE = 800981,
    TITHE_COST = 1 * SILVER
};

struct TitheSite
{
    uint32 area;
    TeamId team;
    uint32 reward;
    bool exact = false;
};
constexpr TitheSite sites[] = {
    {10138, TEAM_ALLIANCE, 804816},
    {10140, TEAM_HORDE, 804816},
    {10225, TEAM_ALLIANCE, 804820},
    {10231, TEAM_HORDE, 804820},
    {1637, TEAM_HORDE, 804820, true},
    {1661, TEAM_ALLIANCE, 804819},
    {1657, TEAM_ALLIANCE, 804819, true},
    {2197, TEAM_HORDE, 804819},
    {2268, TEAM_NEUTRAL, 804782},
    {796, TEAM_NEUTRAL, 804782},
    {228, TEAM_NEUTRAL, 804815},
    {2405, TEAM_NEUTRAL, 804817},
    {280, TEAM_NEUTRAL, 804784},
};

bool Inside(uint32 area, TitheSite const& site)
{
    if (site.exact)
        return area == site.area;
    for (uint8 depth = 0; area && depth < 4; ++depth)
    {
        if (area == site.area)
            return true;
        AreaTableEntry const* entry = sAreaTableStore.LookupEntry(area);
        area = entry ? entry->zone : 0;
    }
    return false;
}

class spell_ascension_templar_tithe : public SpellScript
{
    PrepareSpellScript(spell_ascension_templar_tithe);
    void Pay()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        uint32 const area = player->GetAreaId();
        for (TitheSite const& site : sites)
            if ((site.team == TEAM_NEUTRAL || site.team == player->GetTeamId()) && Inside(area, site) &&
                !player->HasSpell(site.reward) && player->HasEnoughMoney(uint32(TITHE_COST)))
            {
                player->ModifyMoney(-int32(TITHE_COST));
                player->learnSpell(site.reward);
                return;
            }
        player->CastSpell(player, SPELL_RESET_TITHE, true);
    }
    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_templar_tithe::Pay);
    }
};
}
void AddSC_AscensionTemplarTithe()
{
    RegisterSpellScript(spell_ascension_templar_tithe);
}
