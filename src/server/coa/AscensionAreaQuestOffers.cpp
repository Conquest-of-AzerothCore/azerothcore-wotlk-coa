/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CellImpl.h"
#include "CreatureScript.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ServerScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <list>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace
{
constexpr float OfferRange = 10.0f;
constexpr float LeaveRange = 14.0f;
constexpr float AcceptRange = 60.0f;
constexpr uint32 ScanIntervalMs = 1000;

struct PendingOffer
{
    ObjectGuid Source;
    uint32 Quest = 0;
};

std::mutex _pendingLock;
std::unordered_map<ObjectGuid, PendingOffer> _pending;

Quest const* OfferableQuest(Player* player, Creature const* source)
{
    QuestRelationBounds const quests = sObjectMgr->GetCreatureQuestRelationBounds(source->GetEntry());
    for (auto itr = quests.first; itr != quests.second; ++itr)
        if (Quest const* quest = sObjectMgr->GetQuestTemplate(itr->second))
            if (player->CanTakeQuest(quest, false) && player->CanAddQuest(quest, false))
                return quest;
    return nullptr;
}

void Offer(Player* player, Creature const* source, Quest const* quest)
{
    {
        std::lock_guard lock(_pendingLock);
        _pending[player->GetGUID()] = { source->GetGUID(), quest->GetQuestId() };
    }
    player->PlayerTalkClass->SendQuestGiverQuestDetails(quest, player->GetGUID(), true);
}

std::optional<PendingOffer> TakePending(Player const* player, uint32 questId)
{
    std::lock_guard lock(_pendingLock);
    auto itr = _pending.find(player->GetGUID());
    if (itr == _pending.end() || itr->second.Quest != questId)
        return std::nullopt;
    PendingOffer const offer = itr->second;
    _pending.erase(itr);
    return offer;
}
}

struct npc_coa_area_quest_offer : public ScriptedAI
{
    explicit npc_coa_area_quest_offer(Creature* creature) : ScriptedAI(creature) { }

    void UpdateAI(uint32 diff) override
    {
        _sinceScan += diff;
        if (_sinceScan < ScanIntervalMs)
            return;
        _sinceScan = 0;

        std::list<Player*> players;
        Acore::AnyPlayerInObjectRangeCheck check(me, LeaveRange);
        Acore::PlayerListSearcher<Acore::AnyPlayerInObjectRangeCheck> searcher(me, players, check);
        Cell::VisitObjects(me, searcher, LeaveRange);

        std::unordered_set<ObjectGuid> inside;
        for (Player* player : players)
        {
            if (!player->InSamePhase(me))
                continue;

            bool const entered = me->IsWithinDistInMap(player, OfferRange);
            bool const wasInside = _inside.count(player->GetGUID()) != 0;
            if (!entered && !wasInside)
                continue;

            inside.insert(player->GetGUID());
            if (!wasInside)
                if (Quest const* quest = OfferableQuest(player, me))
                    Offer(player, me, quest);
        }
        _inside = std::move(inside);
    }

private:
    uint32 _sinceScan = 0;
    std::unordered_set<ObjectGuid> _inside;
};

class coa_area_quest_offer_accept : public ServerScript
{
public:
    coa_area_quest_offer_accept() : ServerScript("coa_area_quest_offer_accept", { SERVERHOOK_CAN_PACKET_RECEIVE }) { }

    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != CMSG_QUESTGIVER_ACCEPT_QUEST)
            return true;

        Player* player = session ? session->GetPlayer() : nullptr;
        if (!player)
            return true;

        WorldPacket request(packet);
        ObjectGuid guid;
        uint32 questId = 0;
        request >> guid >> questId;
        if (guid != player->GetGUID())
            return true;

        std::optional<PendingOffer> const offer = TakePending(player, questId);
        if (!offer)
            return true;

        Creature* source = ObjectAccessor::GetCreature(*player, offer->Source);
        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
        if (source && quest && source->hasQuest(questId) && player->IsWithinDistInMap(source, AcceptRange) &&
            player->CanTakeQuest(quest, true) && player->CanAddQuest(quest, true))
            player->AddQuestAndCheckCompletion(quest, source);

        player->PlayerTalkClass->SendCloseGossip();
        return false;
    }
};

void AddSC_AscensionAreaQuestOffers()
{
    RegisterCreatureAI(npc_coa_area_quest_offer);
    new coa_area_quest_offer_accept();
}
