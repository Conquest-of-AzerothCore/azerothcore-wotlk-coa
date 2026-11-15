/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionLevelDamageSummons.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
class ascension_summon_level_damage : public PlayerScript
{
public:
    ascension_summon_level_damage() : PlayerScript("ascension_summon_level_damage",
        {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL}) { }

    void OnPlayerAfterGuardianInitStatsForLevel(Player* player, Guardian* guardian) override
    {
        if (!player || !guardian || !IsAscensionLevelDamageSummon(guardian->GetEntry()))
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

void AddSC_AscensionSummonDamage()
{
    new ascension_summon_level_damage();
}
