/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameObjectScript.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <unordered_map>

namespace
{
constexpr uint32 SPELL_CLOSING_THE_BLACKWOOD_RIFT = 365373;
constexpr uint32 QUEST_WHERE_THE_VEIL_WANES = 175048;
constexpr int32 ChannelEndToleranceMs = 400;

Spell* ChannelAt(Player* player, GameObject* rift)
{
    Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
    if (channel && channel->GetSpellInfo()->Id == SPELL_CLOSING_THE_BLACKWOOD_RIFT &&
        channel->m_targets.GetGOTargetGUID() == rift->GetGUID())
        return channel;
    return nullptr;
}

struct go_coa_blackwood_rift : public GameObjectAI
{
    explicit go_coa_blackwood_rift(GameObject* go) : GameObjectAI(go) { }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse)
            return false;

        if (!me->isSpawned())
            return true;

        if (player->GetQuestStatus(QUEST_WHERE_THE_VEIL_WANES) == QUEST_STATUS_INCOMPLETE &&
            player->CastSpell(me, SPELL_CLOSING_THE_BLACKWOOD_RIFT, false) == SPELL_CAST_OK)
            _remainingMs[player->GetGUID()] = sSpellMgr->GetSpellInfo(SPELL_CLOSING_THE_BLACKWOOD_RIFT)->GetDuration();
        return true;
    }

    void UpdateAI(uint32) override
    {
        for (auto remaining = _remainingMs.begin(); remaining != _remainingMs.end();)
        {
            Player* player = ObjectAccessor::GetPlayer(*me, remaining->first);
            if (Spell* channel = player ? ChannelAt(player, me) : nullptr)
            {
                remaining->second = channel->GetCastTimeRemaining();
                ++remaining;
                continue;
            }

            bool const closed = player && remaining->second <= ChannelEndToleranceMs;
            remaining = _remainingMs.erase(remaining);
            if (closed)
            {
                player->KillCreditGO(me->GetEntry(), me->GetGUID());
                _remainingMs.clear();
                me->DespawnOrUnsummon();
                return;
            }
        }
    }

private:
    std::unordered_map<ObjectGuid, int32> _remainingMs;
};

class blackwood_rift_channel : public GlobalScript
{
public:
    blackwood_rift_channel() : GlobalScript("blackwood_rift_channel", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_CLOSING_THE_BLACKWOOD_RIFT && info->IsChanneled())
            info->ChannelInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE | AURA_INTERRUPT_FLAG_MOVE;
    }
};
}

void AddSC_AscensionBlackwoodRifts()
{
    RegisterGameObjectAI(go_coa_blackwood_rift);
    new blackwood_rift_channel();
}
