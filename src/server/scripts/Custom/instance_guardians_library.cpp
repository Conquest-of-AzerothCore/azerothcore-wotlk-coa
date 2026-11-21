/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AllCreatureScript.h"
#include "AllSpellScript.h"
#include "CreatureScript.h"
#include "InstanceMapScript.h"
#include "InstanceScript.h"
#include "LocalLevelScaling.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "ScriptMgr.h"
#include "WorldScript.h"
#include "SmartAI.h"
#include "Spell.h"
#include "SpellAuraDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "UnitScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <vector>

void CoASetDungeonReleaseStart(Map* map, Position const& start);

namespace
{
constexpr uint32 MAP_GUARDIANS_LIBRARY = 4417;
constexpr uint32 MAP_DALARAN_CRATER    = 4418;
constexpr uint32 MAP_REGRETS_CHASM     = 933;

Position const LibraryStart = { -11173.841f, -1900.9021f, 232.00911f, 5.3293033f };

Position const ChasmStart  = { -11359.0f, -3072.89f, 4.55f, 3.38f };

constexpr uint32 QUEST_GUARDIANS_SHORTCUT = 9417105;
constexpr uint32 QUEST_HOLD_THE_ANCHORS   = 9417110;
constexpr uint32 QUEST_THE_ANSWER_IS_NO   = 9417117;
constexpr uint32 QUEST_NIGHTMARES_HAND    = 9417115;
constexpr uint32 QUEST_HOLD_THE_RIFT      = 9417116;

constexpr uint32 PHASE_CRATER_CAMP   = 0x2;
constexpr uint32 PHASE_CRATER_ESCORT = 0x4;
constexpr uint32 PHASE_CRATER_RIFT   = 0x8;
constexpr uint32 PHASE_CRATER_ESCAPED = 0x10;
constexpr uint32 PHASE_CRATER_LOCKED  = 0x20;
constexpr uint32 PHASE_CRATER_ALL     = PHASE_CRATER_CAMP | PHASE_CRATER_ESCORT | PHASE_CRATER_RIFT | PHASE_CRATER_ESCAPED |
    PHASE_CRATER_LOCKED;
constexpr uint32 SEND_TO_CRATER_DELAY_MS = 1000;
Position const CraterLanding = { 293.71f, 377.26f, -64.09f, 5.50f };
constexpr uint32 CRATER_PHASE_CHECK_MS = 1000;

bool QuestStatusIn(Player const* player, uint32 questId, uint32 statusMask)
{
    return ((1u << player->GetQuestStatus(questId)) & statusMask) != 0;
}

uint32 CraterPhase(Player const* player)
{
    if (QuestStatusIn(player, QUEST_HOLD_THE_ANCHORS, 1u << QUEST_STATUS_INCOMPLETE))
        return PHASE_CRATER_ESCORT;

    if (QuestStatusIn(player, QUEST_HOLD_THE_ANCHORS, (1u << QUEST_STATUS_COMPLETE) | (1u << QUEST_STATUS_REWARDED)))
    {
        if (QuestStatusIn(player, QUEST_THE_ANSWER_IS_NO, 1u << QUEST_STATUS_REWARDED))
            return PHASEMASK_NORMAL;
        uint32 const done = (1u << QUEST_STATUS_COMPLETE) | (1u << QUEST_STATUS_REWARDED);
        if (QuestStatusIn(player, QUEST_HOLD_THE_RIFT, done))
            return PHASE_CRATER_RIFT | PHASE_CRATER_LOCKED;
        if (QuestStatusIn(player, QUEST_NIGHTMARES_HAND, done))
            return PHASE_CRATER_RIFT | PHASE_CRATER_ESCAPED;
        return PHASE_CRATER_RIFT;
    }

    if (QuestStatusIn(player, QUEST_HOLD_THE_ANCHORS, 1u << QUEST_STATUS_NONE) &&
        QuestStatusIn(player, QUEST_GUARDIANS_SHORTCUT,
            (1u << QUEST_STATUS_INCOMPLETE) | (1u << QUEST_STATUS_COMPLETE) | (1u << QUEST_STATUS_REWARDED)))
        return PHASE_CRATER_CAMP;

    return PHASEMASK_NORMAL;
}

void SetCraterPhase(Player* player, uint32 phase)
{
    if (player->IsGameMaster() || player->HasAuraType(SPELL_AURA_PHASE) || player->GetPhaseMask() == phase)
        return;

    player->SetPhaseMask(phase, true);
    player->GetSession()->SendSetPhaseShift(phase);
}

constexpr uint32 REWARD_SHOWN_FIRST = 9417310;
constexpr uint32 REWARD_SHOWN_LAST  = 9417326;
constexpr uint32 REWARD_STEP_BASE   = 9418000;
constexpr uint32 REWARD_STEPS       = 6;
constexpr uint32 REWARD_QUESTS[]    = { 9417105, 9417110, 9417116 };

uint32 RewardVariant(uint32 itemId, uint8 level)
{
    uint32 const step = level < 35 ? 0 : std::min<uint32>((level - 30) / 5, REWARD_STEPS);
    return step ? REWARD_STEP_BASE + 10 * (itemId - REWARD_SHOWN_FIRST) + step : itemId;
}

LocalLevelScaling::QuestRewardItemResolver previousRewardResolver = nullptr;

uint32 WisdomballRewardItem(Player const* player, uint32 itemId, Quest const* quest)
{
    if (player && quest && itemId >= REWARD_SHOWN_FIRST && itemId <= REWARD_SHOWN_LAST &&
        std::find(std::begin(REWARD_QUESTS), std::end(REWARD_QUESTS), quest->GetQuestId()) != std::end(REWARD_QUESTS))
        return RewardVariant(itemId, player->GetLevel());

    return previousRewardResolver ? previousRewardResolver(player, itemId, quest) : itemId;
}

constexpr uint32 NPC_MEMORY_OF_THE_COUNCIL = 9417027;
constexpr uint32 NPC_KHADGAR_ESCORT        = 9417056;
constexpr float  COUNCIL_BLAST_RANGE       = 100.0f;
constexpr float  KHADGAR_BUBBLE_RADIUS     = 5.0f;
constexpr int32  COUNCIL_BLAST_PCT         = 69;
constexpr int32  KHADGAR_BARRIER_REDUCTION = 95;

constexpr uint32 NPC_MEMORY_OF_KELTHUZAD = 9417025;
constexpr uint32 NPC_MEMORY_OF_ARUGAL    = 9417026;
constexpr float  MEMORY_MANA_COST_PCT    = 2.0f;
constexpr uint32 SPELL_MEMORY_FROSTBOLT   = 16249;
constexpr uint32 SPELL_MEMORY_SHADOW_BOLT = 1106;
constexpr uint32 SPELL_MEMORY_ARCANE_BOLT = 31445;

constexpr uint32 SPELL_MEMORY_SHADOW_VOID = 55847;
constexpr uint32 MEMORY_SHADOW_VOID_TICK  = 36;

constexpr uint32 NPC_KHADGAR_LIBRARY = 9417002;
constexpr uint32 NPC_KHADGAR_CRATER  = 9417003;
constexpr uint32 NPC_KHADGAR_RIFT    = 9417004;

bool IsQuestlineKhadgar(uint32 entry)
{
    return entry == NPC_KHADGAR_LIBRARY || entry == NPC_KHADGAR_CRATER || entry == NPC_KHADGAR_RIFT || entry == NPC_KHADGAR_ESCORT;
}

uint32 MemoryMainSpell(uint32 entry)
{
    switch (entry)
    {
        case NPC_MEMORY_OF_KELTHUZAD:   return SPELL_MEMORY_FROSTBOLT;
        case NPC_MEMORY_OF_ARUGAL:      return SPELL_MEMORY_SHADOW_BOLT;
        case NPC_MEMORY_OF_THE_COUNCIL: return SPELL_MEMORY_ARCANE_BOLT;
        default:                        return 0;
    }
}

constexpr uint32 QUESTLINE_ENTRY_FIRST     = 9417000;
constexpr uint32 QUESTLINE_ENTRY_LAST      = 9417999;
constexpr uint8  QUESTLINE_LEVEL_MIN       = 30;
constexpr uint8  QUESTLINE_LEVEL_MAX       = 60;
constexpr uint8  QUESTLINE_LOWEST_SCALED   = 29;

bool IsQuestlineMap(uint32 mapId)
{
    return mapId == MAP_GUARDIANS_LIBRARY || mapId == MAP_DALARAN_CRATER || mapId == MAP_REGRETS_CHASM;
}

bool IsScaledQuestlineCreature(Creature const* creature, CreatureTemplate const* cinfo)
{
    return creature->GetEntry() >= QUESTLINE_ENTRY_FIRST && creature->GetEntry() <= QUESTLINE_ENTRY_LAST
        && IsQuestlineMap(creature->GetMapId()) && cinfo->minlevel >= QUESTLINE_LOWEST_SCALED;
}

uint8 HighestPlayerLevel(Map* map)
{
    uint8 level = 0;
    Map::PlayerList const& players = map->GetPlayers();
    for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
        if (Player* player = itr->GetSource())
            level = std::max<uint8>(level, player->GetLevel());
    return level;
}

void ScaleQuestlineCreatures(Map* map)
{
    for (auto const& spawn : map->GetCreatureBySpawnIdStore())
    {
        Creature* creature = spawn.second;
        if (!creature || !creature->IsInWorld() || !creature->IsAlive() || creature->IsInCombat()
            || !IsScaledQuestlineCreature(creature, creature->GetCreatureTemplate()))
            continue;

        creature->SelectLevel();
        creature->UpdateAllStats();
    }
}

float QuestlineSpellDamageFactor(Creature const* creature)
{
    CreatureTemplate const* cinfo = creature->GetCreatureTemplate();
    if (!IsScaledQuestlineCreature(creature, cinfo) || creature->GetLevel() == QUESTLINE_LEVEL_MIN)
        return 1.0f;

    uint32 const healthNow = sObjectMgr->GetCreatureBaseStats(creature->GetLevel(), cinfo->unit_class)->GenerateHealth(cinfo);
    uint32 const healthFirst = sObjectMgr->GetCreatureBaseStats(QUESTLINE_LEVEL_MIN, cinfo->unit_class)->GenerateHealth(cinfo);
    return healthFirst ? float(healthNow) / float(healthFirst) : 1.0f;
}

float QuestlineSpellDamageFactor(Unit const* attacker, SpellInfo const* spellInfo)
{
    if (!attacker || !attacker->IsCreature() || !spellInfo
        || spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE || spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED)
        return 1.0f;
    return QuestlineSpellDamageFactor(attacker->ToCreature());
}
}

class spell_wisdomball_council_arcane_explosion : public SpellScript
{
    PrepareSpellScript(spell_wisdomball_council_arcane_explosion);

    bool IsCouncilCast()
    {
        Unit const* caster = GetCaster();
        return caster && caster->IsCreature() && caster->GetEntry() == NPC_MEMORY_OF_THE_COUNCIL;
    }

    void ClearStockTargets(std::list<WorldObject*>& targets)
    {
        if (IsCouncilCast())
            targets.clear();
    }

    void HandleBlast()
    {
        if (!IsCouncilCast())
            return;

        Unit* caster = GetCaster();
        SpellInfo const* spellInfo = GetSpellInfo();
        SpellSchoolMask const schoolMask = spellInfo->GetSchoolMask();

        std::vector<Player*> victims;
        Map::PlayerList const& players = caster->GetMap()->GetPlayers();
        for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            if (Player* player = itr->GetSource())
                if (player->IsAlive() && caster->IsWithinDistInMap(player, COUNCIL_BLAST_RANGE) &&
                    caster->IsValidAttackTarget(player))
                    victims.push_back(player);

        for (Player* victim : victims)
        {
            if (victim->IsImmunedToDamageOrSchool(schoolMask))
            {
                caster->SendSpellMiss(victim, spellInfo->Id, SPELL_MISS_IMMUNE);
                continue;
            }

            bool const sheltered = victim->FindNearestCreature(NPC_KHADGAR_ESCORT, KHADGAR_BUBBLE_RADIUS, true) != nullptr;
            uint32 const blast = victim->CountPctFromMaxHealth(COUNCIL_BLAST_PCT);
            uint32 const damage = sheltered ? blast - CalculatePct(blast, KHADGAR_BARRIER_REDUCTION) : blast;
            caster->SendSpellNonMeleeDamageLog(victim, spellInfo, damage, schoolMask, 0, 0, false, 0, false);
            Unit::DealDamage(caster, victim, damage, nullptr, SPELL_DIRECT_DAMAGE, schoolMask, spellInfo, false);
        }
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_wisdomball_council_arcane_explosion::ClearStockTargets,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        AfterCast += SpellCastFn(spell_wisdomball_council_arcane_explosion::HandleBlast);
    }
};

class wisdomball_reward_items : public WorldScript
{
public:
    wisdomball_reward_items() : WorldScript("wisdomball_reward_items", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        LocalLevelScaling::QuestRewardItemResolver const current =
            LocalLevelScaling::QuestRewardItemOwner.load(std::memory_order_relaxed);
        if (current == &WisdomballRewardItem)
            return;
        previousRewardResolver = current;
        LocalLevelScaling::QuestRewardItemOwner.store(&WisdomballRewardItem, std::memory_order_relaxed);
    }
};

class wisdomball_questline_mana_cost : public AllSpellScript
{
public:
    wisdomball_questline_mana_cost() : AllSpellScript("wisdomball_questline_mana_cost", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* spellInfo, bool ) override
    {
        if (!caster || !caster->IsCreature() || !caster->GetMaxPower(POWER_MANA))
            return;

        uint32 const entry = caster->GetEntry();
        bool const khadgar = IsQuestlineKhadgar(entry) && IsQuestlineMap(caster->GetMapId());
        bool const memory = MemoryMainSpell(entry)
            && (spellInfo->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) || spellInfo->HasEffect(SPELL_EFFECT_PERSISTENT_AREA_AURA));
        if (!khadgar && !memory)
            return;

        bool const paidStock = spellInfo->PowerType == POWER_MANA && !spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
        int32 const paid = paidStock ? spell->GetPowerCost() : 0;
        int32 const cost = khadgar ? 0 : int32(CalculatePct(caster->GetMaxPower(POWER_MANA), MEMORY_MANA_COST_PCT));
        if (paid != cost)
            caster->ModifyPower(POWER_MANA, paid - cost);
    }
};

class wisdomball_memory_melee : public AllCreatureScript
{
public:
    wisdomball_memory_melee() : AllCreatureScript("wisdomball_memory_melee") { }

    void OnAllCreatureUpdate(Creature* creature, uint32 ) override
    {
        uint32 const mainSpell = MemoryMainSpell(creature->GetEntry());
        if (!mainSpell || !creature->IsAlive() || !creature->IsInCombat())
            return;

        SmartAI* ai = dynamic_cast<SmartAI*>(creature->AI());
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(mainSpell);
        Unit* victim = creature->GetVictim();
        if (!ai || !spellInfo || !victim)
            return;

        bool const outOfMana = int32(creature->GetPower(POWER_MANA)) < spellInfo->CalcPowerCost(creature, spellInfo->GetSchoolMask());
        if (outOfMana == creature->HasUnitState(UNIT_STATE_MELEE_ATTACKING))
            return;

        ai->SetAutoAttack(outOfMana);
        creature->Attack(victim, outOfMana);
    }
};

class wisdomball_questline_level : public AllCreatureScript
{
public:
    wisdomball_questline_level() : AllCreatureScript("wisdomball_questline_level") { }

    void OnBeforeCreatureSelectLevel(CreatureTemplate const* cinfo, Creature* creature, uint8& level) override
    {
        if (!IsScaledQuestlineCreature(creature, cinfo))
            return;

        if (uint8 const playerLevel = HighestPlayerLevel(creature->GetMap()))
            level = std::clamp(playerLevel, QUESTLINE_LEVEL_MIN, QUESTLINE_LEVEL_MAX);
    }
};

class wisdomball_questline_spell_damage : public UnitScript
{
public:
    wisdomball_questline_spell_damage() : UnitScript("wisdomball_questline_spell_damage", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifySpellDamageTaken(Unit* , Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        damage = int32(float(damage) * QuestlineSpellDamageFactor(attacker, spellInfo));
    }

    void ModifyPeriodicDamageAurasTick(Unit* , Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && spellInfo->Id == SPELL_MEMORY_SHADOW_VOID && attacker && attacker->GetEntry() == NPC_MEMORY_OF_ARUGAL)
            damage = MEMORY_SHADOW_VOID_TICK;

        damage = uint32(float(damage) * QuestlineSpellDamageFactor(attacker, spellInfo));
    }
};

class wisdomball_questline_level_player : public PlayerScript
{
public:
    wisdomball_questline_level_player() : PlayerScript("wisdomball_questline_level_player", { PLAYERHOOK_ON_LEVEL_CHANGED }) { }

    void OnPlayerLevelChanged(Player* player, uint8 ) override
    {
        Map* map = player->GetMap();
        if (map && IsQuestlineMap(map->GetId()))
            ScaleQuestlineCreatures(map);
    }
};

class wisdomball_crater_phase_reset : public PlayerScript
{
public:
    wisdomball_crater_phase_reset() : PlayerScript("wisdomball_crater_phase_reset", { PLAYERHOOK_ON_MAP_CHANGED }) { }

    void OnPlayerMapChanged(Player* player) override
    {
        uint32 const phase = player->GetPhaseMask();
        if (player->GetMapId() == MAP_DALARAN_CRATER || phase == PHASEMASK_NORMAL || (phase & ~PHASE_CRATER_ALL) != 0)
            return;

        SetCraterPhase(player, PHASEMASK_NORMAL);
    }
};

class instance_guardians_library : public InstanceMapScript
{
public:
    instance_guardians_library() : InstanceMapScript("instance_guardians_library", MAP_GUARDIANS_LIBRARY) { }

    struct instance_guardians_library_InstanceMapScript : public InstanceScript
    {
        explicit instance_guardians_library_InstanceMapScript(Map* map) : InstanceScript(map) { }

        void OnPlayerEnter(Player* player) override
        {
            InstanceScript::OnPlayerEnter(player);

            CoASetDungeonReleaseStart(instance, LibraryStart);
            ScaleQuestlineCreatures(instance);
        }
    };

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_guardians_library_InstanceMapScript(map);
    }
};

class instance_wisdomball_dalaran_crater : public InstanceMapScript
{
public:
    instance_wisdomball_dalaran_crater() : InstanceMapScript("instance_wisdomball_dalaran_crater", MAP_DALARAN_CRATER) { }

    struct instance_wisdomball_dalaran_crater_InstanceMapScript : public InstanceScript
    {
        explicit instance_wisdomball_dalaran_crater_InstanceMapScript(Map* map) : InstanceScript(map) { }

        void OnPlayerEnter(Player* player) override
        {
            InstanceScript::OnPlayerEnter(player);
            SetCraterPhase(player, CraterPhase(player));
            ScaleQuestlineCreatures(instance);
        }

        void OnPlayerLeave(Player* player) override
        {
            InstanceScript::OnPlayerLeave(player);
            SetCraterPhase(player, PHASEMASK_NORMAL);
        }

        void Update(uint32 diff) override
        {
            InstanceScript::Update(diff);

            _phaseCheckTimer += diff;
            if (_phaseCheckTimer < CRATER_PHASE_CHECK_MS)
                return;
            _phaseCheckTimer = 0;

            Map::PlayerList const& players = instance->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                if (Player* player = itr->GetSource())
                    if (player->IsInWorld() && !player->IsBeingTeleportedFar() && player->GetMapId() == MAP_DALARAN_CRATER)
                        SetCraterPhase(player, CraterPhase(player));
        }

    private:
        uint32 _phaseCheckTimer = 0;
    };

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_wisdomball_dalaran_crater_InstanceMapScript(map);
    }
};

class instance_wisdomball_regrets_chasm : public InstanceMapScript
{
public:
    instance_wisdomball_regrets_chasm() : InstanceMapScript("instance_wisdomball_regrets_chasm", MAP_REGRETS_CHASM) { }

    struct instance_wisdomball_regrets_chasm_InstanceMapScript : public InstanceScript
    {
        explicit instance_wisdomball_regrets_chasm_InstanceMapScript(Map* map) : InstanceScript(map) { }

        void OnPlayerEnter(Player* player) override
        {
            InstanceScript::OnPlayerEnter(player);
            CoASetDungeonReleaseStart(instance, ChasmStart);
            ScaleQuestlineCreatures(instance);
            if (QuestStatusIn(player, QUEST_NIGHTMARES_HAND, (1u << QUEST_STATUS_COMPLETE) | (1u << QUEST_STATUS_REWARDED)))
                _sendToCrater.push_back(player->GetGUID());
        }

        void Update(uint32 diff) override
        {
            InstanceScript::Update(diff);
            if (_sendToCrater.empty())
                return;
            _sendToCraterTimer += diff;
            if (_sendToCraterTimer < SEND_TO_CRATER_DELAY_MS)
                return;
            _sendToCraterTimer = 0;

            std::vector<Player*> players;
            for (MapReference const& ref : instance->GetPlayers())
                if (Player* player = ref.GetSource(); player &&
                    std::find(_sendToCrater.begin(), _sendToCrater.end(), player->GetGUID()) != _sendToCrater.end())
                    players.push_back(player);
            _sendToCrater.clear();
            for (Player* player : players)
                player->TeleportTo(MAP_DALARAN_CRATER, CraterLanding.GetPositionX(), CraterLanding.GetPositionY(),
                                   CraterLanding.GetPositionZ(), CraterLanding.GetOrientation());
        }

    private:
        std::vector<ObjectGuid> _sendToCrater;
        uint32 _sendToCraterTimer = 0;
    };

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_wisdomball_regrets_chasm_InstanceMapScript(map);
    }
};

void AddSC_instance_guardians_library()
{
    new instance_guardians_library();
    new instance_wisdomball_dalaran_crater();
    new instance_wisdomball_regrets_chasm();
    RegisterSpellScript(spell_wisdomball_council_arcane_explosion);

    new wisdomball_reward_items();
    new wisdomball_questline_level();
    new wisdomball_questline_spell_damage();
    new wisdomball_questline_level_player();
    new wisdomball_crater_phase_reset();
    new wisdomball_questline_mana_cost();
    new wisdomball_memory_melee();
}
