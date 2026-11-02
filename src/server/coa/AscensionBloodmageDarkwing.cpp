/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <list>
#include <vector>

namespace
{
enum DarkwingCreatures : uint32
{
    NPC_SHADOW_BAT = 50069
};

// Call of the Darkwing (801958, 802578) summons Shadow Bats through SummonProperties 61, and its procs
// (Petrified Legions 500012, Screech of the Darkwing 300260) can stack calls faster than the bats expire.
// A player keeps at most this many Shadow Bats; each new one unsummons the oldest beyond the cap.
constexpr std::size_t MaxShadowBats = 6;

void CapShadowBats(Player* player, Guardian* newest)
{
    std::list<Creature*> minions;
    player->GetAllMinionsByEntry(minions, NPC_SHADOW_BAT);

    std::vector<TempSummon*> older;
    for (Creature* minion : minions)
        if (minion != newest && minion->IsInWorld())
            if (TempSummon* summon = minion->ToTempSummon())
                older.push_back(summon);

    if (older.size() < MaxShadowBats)
        return;

    // Creature guid counters grow with every spawn on the map, so the lowest counter is the oldest bat.
    std::sort(older.begin(), older.end(),
        [](TempSummon const* a, TempSummon const* b) { return a->GetGUID().GetCounter() < b->GetGUID().GetCounter(); });

    // The newest bat already sits in the owner's control set (Minion::InitStats runs SetMinion before
    // Guardian::InitStats reaches this hook), so leave room for it: MaxShadowBats - 1 older ones remain.
    std::size_t const excess = older.size() - (MaxShadowBats - 1);
    for (std::size_t i = 0; i < excess; ++i)
        older[i]->UnSummon();
}

class bloodmage_darkwing_bat : public PlayerScript
{
  public:
    bloodmage_darkwing_bat()
        : PlayerScript("bloodmage_darkwing_bat", {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL})
    {
    }

    void OnPlayerAfterGuardianInitStatsForLevel(Player* player, Guardian* guardian) override
    {
        if (!player || !guardian || guardian->GetEntry() != NPC_SHADOW_BAT)
            return;

        CapShadowBats(player, guardian);

        if (player->getClass() != CLASS_SON_OF_ARUGAL)
            return;

        CreatureTemplate const* info = guardian->GetCreatureTemplate();
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(guardian->GetLevel(), info->unit_class);
        float const damage = stats->GenerateBaseDamage(info);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.5f);
        guardian->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        guardian->UpdateAllStats();
        guardian->SetReactState(REACT_DEFENSIVE);
    }
};
}

void AddSC_AscensionBloodmageDarkwing()
{
    new bloodmage_darkwing_bat();
}
