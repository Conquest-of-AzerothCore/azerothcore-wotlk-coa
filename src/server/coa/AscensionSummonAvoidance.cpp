/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PetDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <array>

namespace
{
enum AvoidingSummonEntry : uint32
{
    NPC_EMERALD_DRAGON_WHELP = 8776,
    NPC_CRIMSON_CANNON       = 11199,
    NPC_TIMBERMAW_ANCESTOR   = 15720,
    NPC_FUNGARIAN            = 45896,
    NPC_HONORED_ANCESTOR     = 51265,
    NPC_ANIMATED_ZOMBIE      = 503031,
};

constexpr std::array<uint32, 6> AvoidingSummonEntries =
{
    NPC_EMERALD_DRAGON_WHELP,
    NPC_CRIMSON_CANNON,
    NPC_TIMBERMAW_ANCESTOR,
    NPC_FUNGARIAN,
    NPC_HONORED_ANCESTOR,
    NPC_ANIMATED_ZOMBIE,
};

bool HasSummonAvoidance(uint32 entry)
{
    return std::find(AvoidingSummonEntries.begin(), AvoidingSummonEntries.end(), entry)
        != AvoidingSummonEntries.end();
}
}

class ascension_summon_avoidance : public PlayerScript
{
public:
    ascension_summon_avoidance() : PlayerScript("ascension_summon_avoidance",
        {PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL}) { }

    void OnPlayerAfterGuardianInitStatsForLevel(Player*, Guardian* guardian) override
    {
        if (guardian && HasSummonAvoidance(guardian->GetEntry()))
            guardian->AddAura(SPELL_PET_AVOIDANCE, guardian);
    }
};

void AddSC_AscensionSummonAvoidance()
{
    new ascension_summon_avoidance();
}
