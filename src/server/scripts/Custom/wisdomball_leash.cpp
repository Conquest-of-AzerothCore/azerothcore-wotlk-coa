#include "AllCreatureScript.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "GameTime.h"
#include "ScriptMgr.h"

namespace
{
constexpr uint32 MAP_REGRETS_CHASM      = 933;
constexpr uint32 MAP_GUARDIANS_LIBRARY  = 4417;
constexpr uint32 MAP_DALARAN_CRATER     = 4418;

bool IsWisdomballMap(uint32 mapId)
{
    return mapId == MAP_REGRETS_CHASM || mapId == MAP_GUARDIANS_LIBRARY || mapId == MAP_DALARAN_CRATER;
}

bool KeepsDungeonLeash(Creature const* creature)
{
    return creature->isWorldBoss() || creature->IsDungeonBoss() || !creature->GetScriptName().empty()
        || !creature->GetCharmerOrOwnerGUID().IsEmpty() || creature->IsSummon();
}

bool IsFightingPlayer(Creature const* creature)
{
    Unit* victim = creature->GetVictim();
    return victim && victim->GetCharmerOrOwnerPlayerOrPlayerItself();
}
}

class wisdomball_leash : public AllCreatureScript
{
public:
    wisdomball_leash() : AllCreatureScript("wisdomball_leash") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 ) override
    {
        if (!IsWisdomballMap(creature->GetMapId()))
            return;

        if (!creature->IsAIEnabled || !creature->IsInCombat() || creature->IsInEvadeMode())
            return;

        if (KeepsDungeonLeash(creature) || !IsFightingPlayer(creature))
            return;

        if (creature->GetLastLeashExtensionTime() + creature->GetLeashTimer() > GameTime::GetGameTime().count()
            || creature->HasTauntAura())
            return;

        if (creature->IsWithinLeashArea())
            return;

        creature->AI()->EnterEvadeMode(CreatureAI::EVADE_REASON_BOUNDARY);
    }
};

void AddSC_wisdomball_leash()
{
    new wisdomball_leash();
}
