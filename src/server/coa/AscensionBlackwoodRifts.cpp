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
constexpr uint32 ChannelEndToleranceMs = 400;

bool ChannelsAt(Player* player, GameObject* rift)
{
    Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
    return channel && channel->GetSpellInfo()->Id == SPELL_CLOSING_THE_BLACKWOOD_RIFT &&
        channel->m_targets.GetGOTargetGUID() == rift->GetGUID();
}

struct go_coa_blackwood_rift : public GameObjectAI
{
    explicit go_coa_blackwood_rift(GameObject* go) : GameObjectAI(go) { }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse)
            return false;

        if (player->GetQuestStatus(QUEST_WHERE_THE_VEIL_WANES) == QUEST_STATUS_INCOMPLETE &&
            player->CastSpell(me, SPELL_CLOSING_THE_BLACKWOOD_RIFT, false) == SPELL_CAST_OK)
            _channelMs[player->GetGUID()] = 0;
        return true;
    }

    void UpdateAI(uint32 diff) override
    {
        SpellInfo const* closing = sSpellMgr->GetSpellInfo(SPELL_CLOSING_THE_BLACKWOOD_RIFT);
        for (auto channel = _channelMs.begin(); channel != _channelMs.end();)
        {
            channel->second += diff;
            Player* player = ObjectAccessor::GetPlayer(*me, channel->first);
            if (player && ChannelsAt(player, me))
            {
                ++channel;
                continue;
            }

            bool const closed = player && closing && channel->second + ChannelEndToleranceMs >= uint32(closing->GetDuration());
            channel = _channelMs.erase(channel);
            if (closed)
            {
                player->KillCreditGO(me->GetEntry(), me->GetGUID());
                _channelMs.clear();
                me->DespawnOrUnsummon();
                return;
            }
        }
    }

private:
    std::unordered_map<ObjectGuid, uint32> _channelMs;
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
