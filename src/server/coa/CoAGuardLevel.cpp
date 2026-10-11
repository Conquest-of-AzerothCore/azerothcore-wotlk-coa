/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CoAGuardLevelPolicy.h"
#include "AllCreatureScript.h"
#include "Creature.h"
#include "ScriptMgr.h"
#include "World.h"

namespace
{
    class CoAGuardLevelScript final : public AllCreatureScript
    {
    public:
        CoAGuardLevelScript() : AllCreatureScript("CoAGuardLevel") { }

        void OnBeforeCreatureSelectLevel(CreatureTemplate const*, Creature* creature, uint8& level) override
        {
            if (creature->IsGuard() && !creature->IsPet())
                level = CoAGuardLevel::Capped(level, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));
        }
    };
}

void AddSC_CoAGuardLevel()
{
    new CoAGuardLevelScript();
}
