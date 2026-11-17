/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "ScriptMgr.h"
#include <array>

namespace
{
constexpr uint32 Maelith = 164284;
constexpr uint32 Miralyn = 164291;
constexpr float GazeRange = 15.0f;

struct IdleGaze
{
    uint32 watcher;
    uint32 watched;
};

constexpr std::array<IdleGaze, 2> IdleGazes = {{
    { Maelith, Miralyn },
    { Miralyn, Maelith },
}};

uint32 WatchedEntryFor(uint32 watcher)
{
    for (IdleGaze const& gaze : IdleGazes)
        if (gaze.watcher == watcher)
            return gaze.watched;
    return 0;
}

class AscensionIdleGazeScript : public AllCreatureScript
{
public:
    AscensionIdleGazeScript() : AllCreatureScript("AscensionIdleGazeScript") { }

    void OnAllCreatureUpdate(Creature* creature, uint32) override
    {
        uint32 const watched = WatchedEntryFor(creature->GetEntry());
        if (!watched || creature->GetTarget() || !creature->IsAlive() || creature->IsInCombat())
            return;

        if (Creature* partner = creature->FindNearestCreature(watched, GazeRange))
            creature->SetTarget(partner->GetGUID());
    }
};
}

void AddSC_AscensionIdleGaze()
{
    new AscensionIdleGazeScript();
}
