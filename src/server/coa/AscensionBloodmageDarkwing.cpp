/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"

namespace
{
enum DarkwingCreatures : uint32
{
    NPC_SHADOW_BAT = 50069
};

class bloodmage_darkwing_bat : public PlayerScript
{
  public:
    bloodmage_darkwing_bat()
        : PlayerScript("bloodmage_darkwing_bat", {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL})
    {
    }

    void OnPlayerAfterGuardianInitStatsForLevel(Player* player, Guardian* guardian) override
    {
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !guardian ||
            guardian->GetEntry() != NPC_SHADOW_BAT)
            return;

        CreatureTemplate const* info = guardian->GetCreatureTemplate();
        CreatureBaseStats const* stats = sObjectMgr->GetCreatureBaseStats(guardian->GetLevel(), info->unit_class);
        float const damage = stats->GenerateBaseDamage(info);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage);
        guardian->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.5f);
        guardian->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        guardian->UpdateAllStats();
    }
};
}

void AddSC_AscensionBloodmageDarkwing()
{
    new bloodmage_darkwing_bat();
}
