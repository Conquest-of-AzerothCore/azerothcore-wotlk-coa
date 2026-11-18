#include "AllCreatureScript.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SmartAI.h"
#include <mutex>
#include <set>

namespace
{
constexpr uint32 NPC_KHADGAR_ANCHORS_ESCORT = 9417004;
constexpr uint32 NPC_KHADGAR_DESCENT_ESCORT = 9417056;
constexpr float  WAIT_DISTANCE              = 25.0f;
constexpr float  GO_ON_DISTANCE             = 20.0f;
constexpr uint32 WAIT_PAUSE_MS              = 3600000;

std::mutex waitingLock;
std::set<ObjectGuid> waiting;

bool IsWaiting(ObjectGuid guid)
{
    std::lock_guard<std::mutex> lock(waitingLock);
    return waiting.count(guid) != 0;
}

void SetWaiting(ObjectGuid guid, bool on)
{
    std::lock_guard<std::mutex> lock(waitingLock);
    if (on)
        waiting.insert(guid);
    else
        waiting.erase(guid);
}

bool PlayerWithin(Creature const* khadgar, float range)
{
    for (auto const& ref : khadgar->GetMap()->GetPlayers())
        if (Player* player = ref.GetSource())
            if (player->IsAlive() && khadgar->InSamePhase(player) && khadgar->IsWithinDistInMap(player, range))
                return true;

    return false;
}

bool CanStop(Creature const* khadgar, SmartAI* ai)
{
    return !khadgar->IsInCombat() && !ai->HasEscortState(SMART_ESCORT_PAUSED | SMART_ESCORT_RETURNING);
}
}

class wisdomball_escort_wait : public AllCreatureScript
{
public:
    wisdomball_escort_wait() : AllCreatureScript("wisdomball_escort_wait") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 ) override
    {
        uint32 const entry = creature->GetEntry();
        if (entry != NPC_KHADGAR_ANCHORS_ESCORT && entry != NPC_KHADGAR_DESCENT_ESCORT)
            return;

        ObjectGuid const guid = creature->GetGUID();
        SmartAI* ai = creature->IsAIEnabled ? dynamic_cast<SmartAI*>(creature->AI()) : nullptr;
        if (!ai || !creature->IsAlive() || !ai->HasEscortState(SMART_ESCORT_ESCORTING))
        {
            if (IsWaiting(guid))
                SetWaiting(guid, false);
            return;
        }

        if (IsWaiting(guid))
        {
            if (PlayerWithin(creature, GO_ON_DISTANCE))
            {
                SetWaiting(guid, false);
                if (ai->HasEscortState(SMART_ESCORT_PAUSED))
                    ai->SetWPPauseTimer(0);
            }
            else if (CanStop(creature, ai))
                ai->PausePath(WAIT_PAUSE_MS, true);
            return;
        }

        if (!CanStop(creature, ai) || PlayerWithin(creature, WAIT_DISTANCE))
            return;

        ai->PausePath(WAIT_PAUSE_MS, true);
        SetWaiting(guid, true);
    }
};

void AddSC_wisdomball_escort_wait()
{
    new wisdomball_escort_wait();
}
