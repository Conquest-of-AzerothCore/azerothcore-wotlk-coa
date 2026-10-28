/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CreatureAI.h"
#include "GameObject.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SmartAI.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <list>

namespace
{
enum VultureCultMoonwell : uint32
{
    QUEST_TRANSSUBSTANTIATING_THE_FLESH = 1660015,
    NPC_ABERRANT_FLESH_REMNANT = 161783,
    SAY_REMNANT_RISES = 0
};

enum VultureCultNewborns : uint32
{
    QUEST_A_TRAIL_OF_PETALS = 1660017,
    NPC_NEWBORN_SAVED = 161846,
    NPC_BUTTERFLY = 161847,
    NPC_ELDYA = 161848,
    SPELL_RESCUING_A_NEWBORN = 256715
};

constexpr uint32 QuestUneaseMakesTonguesWag = 1660037;
constexpr uint32 SpellTikiMaskDestroying = 256719;
constexpr uint32 GameObjectEnchantedTikiMask = 2300535;
constexpr uint32 GameObjectChatteringTikiMask = 2300536;
constexpr uint32 GameObjectPossessedTikiMask = 2300537;
constexpr uint32 KalimdorMapId = 1;
constexpr float MoonwellReach = 8.0f;
constexpr float RemnantSearchReach = 20.0f;
constexpr uint32 RemnantIdleLifetimeMs = 30000;
constexpr uint32 ButterflyLifetimeMs = 600000;
constexpr Milliseconds ButterflyDeliveryCheckInterval = 1s;
Position const EyrieMoonwell = { 10834.42f, 545.13f, 1396.39f, 0.0f };
Position const RemnantRise = { 10834.8f, 544.1f, 1396.25f, 3.14f };

Creature* FindOwnRemnant(Player* player)
{
    std::list<Creature*> remnants;
    player->GetCreatureListWithEntryInGrid(remnants, NPC_ABERRANT_FLESH_REMNANT, RemnantSearchReach);
    for (Creature* remnant : remnants)
        if (remnant->IsAlive() && remnant->GetSummonerGUID() == player->GetGUID())
            return remnant;

    return nullptr;
}

class spell_coa_channeling_blessing_of_the_moon : public SpellScript
{
    PrepareSpellScript(spell_coa_channeling_blessing_of_the_moon);

    SpellCastResult CheckAtEyrieMoonwell()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->GetQuestStatus(QUEST_TRANSSUBSTANTIATING_THE_FLESH) != QUEST_STATUS_INCOMPLETE)
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;

        if (player->GetMapId() != KalimdorMapId || !player->IsWithinDist3d(&EyrieMoonwell, MoonwellReach))
            return SPELL_FAILED_NOT_HERE;

        return SPELL_CAST_OK;
    }

    void RaiseAberrantFleshRemnant(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);

        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;

        if (Creature* remnant = FindOwnRemnant(player))
        {
            if (!remnant->IsInCombat())
                remnant->AI()->AttackStart(player);
            return;
        }

        if (TempSummon* remnant = player->SummonCreature(NPC_ABERRANT_FLESH_REMNANT, RemnantRise,
                                                         TEMPSUMMON_TIMED_DESPAWN_OOC_ALIVE, RemnantIdleLifetimeMs, 0,
                                                         nullptr, true))
        {
            remnant->SetReactState(REACT_DEFENSIVE);
            remnant->AI()->Talk(SAY_REMNANT_RISES, player);
            remnant->AI()->AttackStart(player);
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_coa_channeling_blessing_of_the_moon::CheckAtEyrieMoonwell);
        OnEffectHit += SpellEffectFn(spell_coa_channeling_blessing_of_the_moon::RaiseAberrantFleshRemnant, EFFECT_0,
                                     SPELL_EFFECT_SEND_EVENT);
    }
};

class ButterflyDeliveryAtSummoner : public BasicEvent
{
public:
    explicit ButterflyDeliveryAtSummoner(Creature* butterfly) : _butterfly(butterfly) { }

    bool Execute(uint64, uint32) override
    {
        if (!_butterfly->IsAlive() ||
            _butterfly->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
            return true;

        SmartAI* ai = CAST_AI(SmartAI, _butterfly->AI());
        if (!ai)
            return true;

        TempSummon* summon = _butterfly->ToTempSummon();
        Player* summoner = summon ? ObjectAccessor::GetPlayer(*_butterfly, summon->GetSummonerGUID()) : nullptr;
        if (summoner && summoner->FindNearestCreature(NPC_ELDYA, INTERACTION_DISTANCE))
        {
            ai->StopFollow(true);
            return true;
        }

        _butterfly->m_Events.AddEventAtOffset(this, ButterflyDeliveryCheckInterval);
        return false;
    }

private:
    Creature* _butterfly;
};

class go_coa_baby_night_elf : public GameObjectScript
{
public:
    go_coa_baby_night_elf() : GameObjectScript("go_coa_baby_night_elf") { }

    bool OnGossipHello(Player* player, GameObject* baby) override
    {
        if (player->GetQuestStatus(QUEST_A_TRAIL_OF_PETALS) == QUEST_STATUS_INCOMPLETE)
            player->CastSpell(baby, SPELL_RESCUING_A_NEWBORN, false);

        return true;
    }
};

class spell_coa_rescuing_a_newborn : public SpellScript
{
    PrepareSpellScript(spell_coa_rescuing_a_newborn);

    void TransformNewborn(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        GameObject* baby = GetHitGObj();
        if (!player || !baby || !baby->isSpawned() ||
            player->GetQuestStatus(QUEST_A_TRAIL_OF_PETALS) != QUEST_STATUS_INCOMPLETE)
            return;

        player->KilledMonsterCredit(NPC_NEWBORN_SAVED);
        if (TempSummon* butterfly = player->SummonCreature(NPC_BUTTERFLY, baby->GetPosition(), TEMPSUMMON_TIMED_DESPAWN,
                                                           ButterflyLifetimeMs, 0, nullptr, true))
            butterfly->m_Events.AddEventAtOffset(new ButterflyDeliveryAtSummoner(butterfly),
                                                 ButterflyDeliveryCheckInterval);
        baby->DespawnOrUnsummon();
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_coa_rescuing_a_newborn::TransformNewborn, EFFECT_0,
                                           SPELL_EFFECT_DUMMY);
    }
};

bool TikiMaskObjective(uint32 entry, uint8& objective)
{
    switch (entry)
    {
        case GameObjectEnchantedTikiMask:
            objective = 0;
            return true;
        case GameObjectChatteringTikiMask:
            objective = 1;
            return true;
        case GameObjectPossessedTikiMask:
            objective = 2;
            return true;
        default:
            return false;
    }
}

class go_coa_tiki_maskAI : public SmartGameObjectAI
{
public:
    explicit go_coa_tiki_maskAI(GameObject* go) : SmartGameObjectAI(go) { }

    bool CanActivateToQuest(Player* player) override
    {
        return CanUseMask(player);
    }

    void BuildClientFlags(Player const* target, uint16& dynFlags, uint32&) override
    {
        if (!CanUseMask(target))
            dynFlags |= GO_DYNFLAG_LO_NO_INTERACT;
    }

private:
    bool CanUseMask(Player const* player) const
    {
        if (!player || player->GetQuestStatus(QuestUneaseMakesTonguesWag) != QUEST_STATUS_INCOMPLETE)
            return false;

        uint8 objective;
        if (!TikiMaskObjective(me->GetEntry(), objective))
            return false;

        uint16 slot = player->FindQuestSlot(QuestUneaseMakesTonguesWag);
        return slot < MAX_QUEST_LOG_SIZE && player->GetQuestSlotCounter(slot, objective) < 1;
    }
};

class go_coa_tiki_mask : public GameObjectScript
{
public:
    go_coa_tiki_mask() : GameObjectScript("go_coa_tiki_mask") { }

    bool OnGossipHello(Player* player, GameObject* mask) override
    {
        if (player->GetQuestStatus(QuestUneaseMakesTonguesWag) != QUEST_STATUS_INCOMPLETE)
            return true;

        uint8 objective;
        if (!TikiMaskObjective(mask->GetEntry(), objective))
            return true;

        uint16 slot = player->FindQuestSlot(QuestUneaseMakesTonguesWag);
        if (slot >= MAX_QUEST_LOG_SIZE || player->GetQuestSlotCounter(slot, objective) >= 1)
            return true;

        player->CastSpell(mask, SpellTikiMaskDestroying, false);
        return false;
    }

    GameObjectAI* GetAI(GameObject* go) const override
    {
        return new go_coa_tiki_maskAI(go);
    }
};
}

void AddSC_AscensionVultureCultQuests()
{
    RegisterSpellScript(spell_coa_channeling_blessing_of_the_moon);
    RegisterSpellScript(spell_coa_rescuing_a_newborn);
    new go_coa_tiki_mask();
    new go_coa_baby_night_elf();
}
