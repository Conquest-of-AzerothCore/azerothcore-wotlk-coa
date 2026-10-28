#include "CreatureScript.h"
#include "Item.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <bit>

namespace
{
    constexpr uint32 QUEST_WHITE_GLOVE_MISCHIEF = 175022;
    constexpr uint32 NPC_PETITIONERS_CHAMBER_CREDIT = 164505;
    constexpr uint32 ITEM_FLASK = 559857;
    constexpr uint32 ITEM_EMPTY_FLASK = 559858;
    constexpr uint32 CHAMBER_MAP = 0;
    constexpr float CHAMBER_X = -8314.038f;
    constexpr float CHAMBER_Y = 292.43518f;
    constexpr float CHAMBER_Z = 126.93212f;
    constexpr float CHAMBER_RADIUS = 25.0f;

    constexpr uint32 QUEST_VOICES_AT_THE_NORTH_GATE = 175198;
    constexpr uint32 NPC_FIRST_NORTH_GATE_CITIZEN = 164981;
    constexpr uint32 NPC_LAST_NORTH_GATE_CITIZEN = 164985;
    constexpr uint32 GOSSIP_FIRST_NORTH_GATE_CITIZEN = 100736;
    constexpr uint32 GOSSIP_ACTION_INFORM = GOSSIP_ACTION_INFO_DEF + 1;
    constexpr uint32 GOSSIP_OPTION_INFORM = 0;
    constexpr uint8 SAY_CITIZEN_REPLY = 0;
    constexpr uint32 SETTING_INFORMED_CITIZENS = 0;
    std::string const NorthGateSettingsSource = "core.coa.pale_reach.north_gate";

    bool IsNorthGateCitizen(uint32 entry)
    {
        return entry >= NPC_FIRST_NORTH_GATE_CITIZEN && entry <= NPC_LAST_NORTH_GATE_CITIZEN;
    }

    uint32 GetInformedCitizens(Player* player)
    {
        uint32 count = player->GetReqKillOrCastCurrentCount(QUEST_VOICES_AT_THE_NORTH_GATE,
            NPC_FIRST_NORTH_GATE_CITIZEN);
        uint32 informed = player->GetPlayerSetting(NorthGateSettingsSource, SETTING_INFORMED_CITIZENS).value;
        if (!count && informed)
        {
            player->UpdatePlayerSetting(NorthGateSettingsSource, SETTING_INFORMED_CITIZENS, 0);
            return 0;
        }

        return count == uint32(std::popcount(informed)) ? informed : uint32(-1);
    }
}

class spell_coa_open_little_mickeys_flask : public SpellScript
{
    PrepareSpellScript(spell_coa_open_little_mickeys_flask);

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || player->GetQuestStatus(QUEST_WHITE_GLOVE_MISCHIEF) != QUEST_STATUS_INCOMPLETE)
            return SPELL_FAILED_DONT_REPORT;

        if (!player->FindMap() || player->GetMapId() != CHAMBER_MAP ||
            player->GetDistance(CHAMBER_X, CHAMBER_Y, CHAMBER_Z) > CHAMBER_RADIUS)
            return SPELL_FAILED_INCORRECT_AREA;

        Item* flask = GetCastItem();
        if (!flask || flask->GetEntry() != ITEM_FLASK || flask->GetOwnerGUID() != player->GetGUID())
            return SPELL_FAILED_ITEM_NOT_FOUND;

        ItemPosCountVec destination;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, ITEM_EMPTY_FLASK, 1) != EQUIP_ERR_OK)
            return SPELL_FAILED_TOO_MANY_OF_ITEM;

        return SPELL_CAST_OK;
    }

    void HandleOpen(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (CheckCast() != SPELL_CAST_OK)
            return;

        Player* player = GetCaster()->ToPlayer();
        Item* flask = GetCastItem();
        if (!player->AddItem(ITEM_EMPTY_FLASK, 1))
            return;

        if (GetSpell()->m_targets.GetItemTarget() == flask)
            GetSpell()->m_targets.SetItemTarget(nullptr);

        GetSpell()->m_CastItem = nullptr;
        GetSpell()->m_castItemGUID.Clear();
        uint32 count = 1;
        player->DestroyItemCount(flask, count, true);
        player->KilledMonsterCredit(NPC_PETITIONERS_CHAMBER_CREDIT);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_coa_open_little_mickeys_flask::CheckCast);
        OnEffectHit += SpellEffectFn(spell_coa_open_little_mickeys_flask::HandleOpen, EFFECT_0,
            SPELL_EFFECT_SEND_EVENT);
    }
};

class npc_north_gate_citizen : public CreatureScript
{
public:
    npc_north_gate_citizen() : CreatureScript("npc_north_gate_citizen") { }

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new ScriptedAI(creature);
    }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        uint32 entry = creature->GetEntry();
        if (!IsNorthGateCitizen(entry))
            return false;

        uint32 menu = GOSSIP_FIRST_NORTH_GATE_CITIZEN + entry - NPC_FIRST_NORTH_GATE_CITIZEN;
        ClearGossipMenuFor(player);
        player->PlayerTalkClass->GetGossipMenu().SetMenuId(menu);
        if (player->GetQuestStatus(QUEST_VOICES_AT_THE_NORTH_GATE) == QUEST_STATUS_INCOMPLETE &&
            !(GetInformedCitizens(player) & (1u << (entry - NPC_FIRST_NORTH_GATE_CITIZEN))))
            AddGossipItemFor(player, menu, GOSSIP_OPTION_INFORM, GOSSIP_SENDER_MAIN, GOSSIP_ACTION_INFORM);

        SendGossipMenuFor(player, player->GetGossipTextId(menu, creature), creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        CloseGossipMenuFor(player);
        uint32 entry = creature->GetEntry();
        if (sender != GOSSIP_SENDER_MAIN || action != GOSSIP_ACTION_INFORM || !IsNorthGateCitizen(entry) ||
            player->GetQuestStatus(QUEST_VOICES_AT_THE_NORTH_GATE) != QUEST_STATUS_INCOMPLETE)
            return true;

        uint32 informed = GetInformedCitizens(player);
        uint32 citizen = 1u << (entry - NPC_FIRST_NORTH_GATE_CITIZEN);
        if (informed & citizen)
            return true;

        uint32 previousCount = player->GetReqKillOrCastCurrentCount(QUEST_VOICES_AT_THE_NORTH_GATE,
            NPC_FIRST_NORTH_GATE_CITIZEN);
        player->KilledMonsterCredit(NPC_FIRST_NORTH_GATE_CITIZEN);
        if (player->GetReqKillOrCastCurrentCount(QUEST_VOICES_AT_THE_NORTH_GATE,
                NPC_FIRST_NORTH_GATE_CITIZEN) == previousCount)
            return true;

        player->UpdatePlayerSetting(NorthGateSettingsSource, SETTING_INFORMED_CITIZENS, informed | citizen);
        creature->AI()->Talk(SAY_CITIZEN_REPLY, player);
        return true;
    }
};

class player_north_gate_citizens : public PlayerScript
{
public:
    player_north_gate_citizens() : PlayerScript("player_north_gate_citizens",
        { PLAYERHOOK_ON_QUEST_ABANDON, PLAYERHOOK_ON_PLAYER_QUEST_ACCEPT }) { }

    void OnPlayerQuestAbandon(Player* player, uint32 questId) override
    {
        if (questId == QUEST_VOICES_AT_THE_NORTH_GATE)
            player->UpdatePlayerSetting(NorthGateSettingsSource, SETTING_INFORMED_CITIZENS, 0);
    }

    void OnPlayerQuestAccept(Player* player, Quest const* quest) override
    {
        if (quest->GetQuestId() == QUEST_VOICES_AT_THE_NORTH_GATE)
            player->UpdatePlayerSetting(NorthGateSettingsSource, SETTING_INFORMED_CITIZENS, 0);
    }
};

void AddSC_spell_coa_stormwind_quests()
{
    RegisterSpellScript(spell_coa_open_little_mickeys_flask);
    new npc_north_gate_citizen();
    new player_north_gate_citizens();
}
