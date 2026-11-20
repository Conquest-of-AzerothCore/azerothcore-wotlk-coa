#include "AllCreatureScript.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "SmartAI.h"
#include "TemporarySummon.h"
#include <list>
#include <mutex>
#include <set>
#include <utility>
#include <vector>

namespace
{
constexpr uint32 NPC_KHADGAR_ANCHORS_ESCORT = 9417004;
constexpr uint32 NPC_KHADGAR_DESCENT_ESCORT = 9417056;
constexpr uint32 NPC_ANCHORS_WAVE_CONTROLLER = 9417040;
constexpr float  WAIT_DISTANCE              = 25.0f;
constexpr float  GO_ON_DISTANCE             = 20.0f;
constexpr uint32 WAIT_PAUSE_MS              = 3600000;
constexpr uint32 QUEST_HOLD_THE_ANCHORS     = 9417110;
constexpr ObjectGuid::LowType KHADGAR_ANCHORS_ESCORT_SPAWN = 9417100;
constexpr float  WAVE_CLEANUP_RANGE         = 250.0f;

std::vector<uint32> const AnchorsWaveEntries = { 9417020, 9417021, 9417022, NPC_ANCHORS_WAVE_CONTROLLER };

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

bool AnotherEscorterNear(Creature const* khadgar, Player const* accepter)
{
    for (auto const& ref : khadgar->GetMap()->GetPlayers())
        if (Player* player = ref.GetSource())
            if (player != accepter && player->GetQuestStatus(QUEST_HOLD_THE_ANCHORS) == QUEST_STATUS_INCOMPLETE &&
                khadgar->InSamePhase(player) && khadgar->IsWithinDistInMap(player, WAIT_DISTANCE))
                return true;

    return false;
}

struct AnchorsWaves
{
    std::list<Creature*> summons;
    std::set<ObjectGuid> owners;
};

AnchorsWaves FindAnchorsWaves(Creature* khadgar)
{
    AnchorsWaves waves;
    khadgar->GetCreatureListWithEntryInGrid(waves.summons, AnchorsWaveEntries, WAVE_CLEANUP_RANGE);

    waves.owners.insert(khadgar->GetGUID());
    for (Creature* summon : waves.summons)
        if (TempSummon* temp = summon->ToTempSummon())
            if (summon->GetEntry() == NPC_ANCHORS_WAVE_CONTROLLER && summon->IsAlive() &&
                temp->GetSummonerGUID() == khadgar->GetGUID())
                waves.owners.insert(summon->GetGUID());

    return waves;
}

bool IsChannelling(AnchorsWaves const& waves)
{
    return waves.owners.size() > 1;
}

void DespawnAnchorsWaves(AnchorsWaves const& waves)
{
    for (Creature* summon : waves.summons)
        if (TempSummon* temp = summon->ToTempSummon())
            if (waves.owners.count(temp->GetSummonerGUID()) || waves.owners.count(summon->GetGUID()))
                temp->UnSummon();
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

class wisdomball_anchors_escort_reset : public PlayerScript
{
public:
    wisdomball_anchors_escort_reset() : PlayerScript("wisdomball_anchors_escort_reset",
        { PLAYERHOOK_ON_PLAYER_QUEST_ACCEPT }) { }

    void OnPlayerQuestAccept(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() != QUEST_HOLD_THE_ANCHORS)
            return;

        auto const escorts = player->GetMap()->GetCreatureBySpawnIdStore().equal_range(KHADGAR_ANCHORS_ESCORT_SPAWN);
        std::vector<std::pair<Creature*, AnchorsWaves>> resets;
        for (auto itr = escorts.first; itr != escorts.second; ++itr)
        {
            Creature* khadgar = itr->second;
            SmartAI* ai = khadgar->IsAIEnabled ? dynamic_cast<SmartAI*>(khadgar->AI()) : nullptr;
            if (!ai || !khadgar->IsAlive() || AnotherEscorterNear(khadgar, player))
                continue;

            AnchorsWaves waves = FindAnchorsWaves(khadgar);
            if (ai->HasEscortState(SMART_ESCORT_ESCORTING) || IsChannelling(waves))
                resets.emplace_back(khadgar, std::move(waves));
        }

        for (auto& [khadgar, waves] : resets)
        {
            DespawnAnchorsWaves(waves);
            khadgar->DespawnOrUnsummon();
        }
    }
};

void AddSC_wisdomball_escort_wait()
{
    new wisdomball_escort_wait();
    new wisdomball_anchors_escort_reset();
}
