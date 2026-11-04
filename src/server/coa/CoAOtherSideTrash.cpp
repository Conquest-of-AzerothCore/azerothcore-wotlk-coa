/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Chat.h"
#include "ChatCommand.h"
#include "CoAOtherSideDamage.h"
#include "CommandScript.h"
#include "Creature.h"
#include "GameTime.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <list>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
using CoAOtherSide::BaseSpellId;
using CoAOtherSide::Damage3;
using CoAOtherSide::Rolled;

enum TrashData : uint32
{
    NPC_SPIDER_ADD = 162743,
    NPC_WANDERER_1 = 162765,
    NPC_MATRIARCH = 162769,
    NPC_SPIDER = 162770,
    NPC_GUTDEVOURER_1 = 162773,
    NPC_GUTDEVOURER_2 = 162775,
    NPC_WANDERER_2 = 162776,
    NPC_CULTIST_1 = 162780,
    NPC_HISSER = 162782,
    NPC_WANDERER_3 = 162783,
    NPC_SWARM = 162784,
    NPC_WATCHER = 162785,
    NPC_LIFEDRINKER_1 = 162979,
    NPC_LIFEDRINKER_2 = 162980,
    NPC_CULTIST_2 = 162982,
    NPC_CULTIST_SHIELD = 162983,

    SAY_WANDERER_AGGRO = 0,
    SAY_WANDERER_DEATH = 1,

    SPELL_FIERCE_BLOW = 975011,
    SPELL_DECAYING_HEMORRHAGE = 256905,
    SPELL_BITE = 256906,
    SPELL_VENOMOUS_BREATH = 256907,
    SPELL_STING = 256909,
    SPELL_REND_FLESH = 256938,
    SPELL_SHIELD_BASH = 256939,
    SPELL_FISSURE_STRIKE = 256110,
    SPELL_EARTH_STRIKE = 256109,
    SPELL_ENGORGED = 257198,
    SPELL_BROOD_EMPOWERMENT = 257200,
    SPELL_BROOD_STATE = 257201,
    SPELL_BITING_CLOUD = 257202,
    SPELL_TOXIC_EXPULSION = 257203,
    SPELL_VENOM_TRAP = 256923,
    SPELL_TRAP_BREATH_VISUAL = 256907,
};

enum class Aim : uint8
{
    Victim,
    Self,
    Random,
};

constexpr uint8 DiffNormal = 0x1;
constexpr uint8 DiffHeroic = 0x2;
constexpr uint8 DiffMythic = 0x4;
constexpr uint8 DiffAll = DiffNormal | DiffHeroic | DiffMythic;

struct Ability
{
    uint32 spell;
    uint32 firstMs;
    uint32 repeatMs;
    Aim aim;
    uint8 difficulties;
};

Ability const FierceBlow = { SPELL_FIERCE_BLOW, 6000, 8000, Aim::Victim, DiffAll };

std::unordered_map<uint32, std::vector<Ability>> const Abilities =
{
    { NPC_WANDERER_1, { { SPELL_DECAYING_HEMORRHAGE, 4000, 7000, Aim::Victim, DiffAll }, FierceBlow } },
    { NPC_WANDERER_2, { { SPELL_DECAYING_HEMORRHAGE, 4000, 7000, Aim::Victim, DiffAll }, FierceBlow } },
    { NPC_WANDERER_3, { { SPELL_DECAYING_HEMORRHAGE, 4000, 7000, Aim::Victim, DiffAll }, FierceBlow } },
    { NPC_MATRIARCH, { { SPELL_STING, 3000, 8000, Aim::Victim, DiffAll }, { SPELL_BROOD_EMPOWERMENT, 1000, 2500, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_SPIDER, { FierceBlow } },
    { NPC_SPIDER_ADD, { FierceBlow } },
    { NPC_GUTDEVOURER_1, { { SPELL_BITE, 3000, 8000, Aim::Victim, DiffAll }, { SPELL_VENOMOUS_BREATH, 10000, 26000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_GUTDEVOURER_2, { { SPELL_BITE, 3000, 8000, Aim::Victim, DiffAll }, { SPELL_VENOMOUS_BREATH, 10000, 26000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_CULTIST_1, { { SPELL_REND_FLESH, 4000, 9000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_CULTIST_2, { { SPELL_REND_FLESH, 4000, 9000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_CULTIST_SHIELD, { { SPELL_SHIELD_BASH, 5000, 9000, Aim::Victim, DiffAll }, FierceBlow } },
    { NPC_HISSER, { { SPELL_TOXIC_EXPULSION, 4000, 8000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_SWARM, { { SPELL_BITING_CLOUD, 1000, 2500, Aim::Self, DiffHeroic | DiffMythic }, FierceBlow } },
    { NPC_WATCHER, { { SPELL_FISSURE_STRIKE, 5000, 8000, Aim::Self, DiffAll }, FierceBlow } },
    { NPC_LIFEDRINKER_1, { FierceBlow } },
    { NPC_LIFEDRINKER_2, { FierceBlow } },
};

struct SpellDamage
{
    Damage3 hit;
    Damage3 tick;
};

std::unordered_map<uint32, SpellDamage> const Damages =
{
    { SPELL_DECAYING_HEMORRHAGE, { { 41, 268 }, { 6, 51 } } },
    { SPELL_BITE, { { 85, 205 }, { 0, 0 } } },
    { SPELL_STING, { { 163, 431 }, { 60, 290 } } },
    { SPELL_REND_FLESH, { { 380, 355 }, { 75, 62 } } },
    { SPELL_SHIELD_BASH, { { 41, 133 }, { 0, 0 } } },
    { SPELL_TOXIC_EXPULSION, { { 1600, 2418 }, { 110, 232 } } },
    { SPELL_BITING_CLOUD, { { 30, 74 }, { 0, 0 } } },
    { SPELL_FISSURE_STRIKE, { { 300, 1000 }, { 0, 0 } } },
};

constexpr float FissureLength = 20.0f;
constexpr float FissureHalfWidth = 2.0f;
constexpr float BroodRange = 30.0f;
std::atomic<uint32> TrapActiveMs = 1500;
std::atomic<uint32> TrapPauseMs = 6000;
constexpr uint32 TrapTickMs = 500;
constexpr uint32 TrapRankMs = 5000;
constexpr float TrapFlightReach = 30.0f;
constexpr float TrapLevelGap = 2.0f;
constexpr float TrapObjectScale = 1.2f;
constexpr uint32 NPC_VENOM_TRAP = 162975;
constexpr uint32 SpawnMaskAllDifficulties = 7;
constexpr float TrapCommandReach = 10.0f;
constexpr float TrapListReach = 600.0f;
constexpr float ToxicExpulsionReach = 100.0f;
constexpr float TrapReach = 11.0f;
constexpr float TrapHalfAngle = float(M_PI) / 12.0f;

uint8 DifficultyBit(Map const* map)
{
    switch (map->GetDifficulty())
    {
        case DUNGEON_DIFFICULTY_HEROIC:
            return DiffHeroic;
        case DUNGEON_DIFFICULTY_EPIC:
            return DiffMythic;
        default:
            return DiffNormal;
    }
}

struct npc_coa_other_side_trash : public ScriptedAI
{
    explicit npc_coa_other_side_trash(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _timers.clear();
        auto itr = Abilities.find(me->GetEntry());
        if (itr == Abilities.end())
            return;
        uint8 const difficulty = DifficultyBit(me->GetMap());
        for (Ability const& ability : itr->second)
            if (ability.difficulties & difficulty)
                _timers.push_back({ &ability, ability.firstMs + urand(0, 1500) });
    }

    void JustEngagedWith(Unit* ) override
    {
        if (IsWanderer() && roll_chance_i(7))
            Talk(SAY_WANDERER_AGGRO);
        if (me->GetEntry() == NPC_MATRIARCH)
            DoCastSelf(SPELL_BROOD_STATE, true);
    }

    void DamageDealt(Unit* , uint32& , DamageEffectType type, SpellSchoolMask ) override
    {
        if (type == DIRECT_DAMAGE && (me->GetEntry() == NPC_LIFEDRINKER_1 || me->GetEntry() == NPC_LIFEDRINKER_2))
            DoCastSelf(SPELL_ENGORGED, true);
    }

    void JustDied(Unit* ) override
    {
        if (IsWanderer() && roll_chance_i(20))
            Talk(SAY_WANDERER_DEATH);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        if (_turnedAway)
        {
            if (me->HasUnitState(UNIT_STATE_CASTING))
            {
                if (me->GetOrientation() != _breathFacing)
                {
                    me->SetOrientation(_breathFacing);
                    me->SetFacingTo(_breathFacing);
                }
                return;
            }
            _turnedAway = false;
            if (Unit* victim = me->GetVictim())
            {
                me->SetTarget(victim->GetGUID());
                me->GetMotionMaster()->MoveChase(victim);
            }
        }

        for (Timer& timer : _timers)
            timer.left = timer.left > diff ? timer.left - diff : 0;

        if (!me->HasUnitState(UNIT_STATE_CASTING))
        {
            for (Timer& timer : _timers)
            {
                if (timer.left)
                    continue;
                Ability const& ability = *timer.ability;
                switch (ability.aim)
                {
                    case Aim::Victim:
                        DoCastVictim(ability.spell);
                        break;
                    case Aim::Self:
                        if (ability.spell == SPELL_VENOMOUS_BREATH)
                            TurnAway();
                        DoCastSelf(ability.spell);
                        break;
                    case Aim::Random:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 40.0f, true))
                            DoCast(target, ability.spell);
                        break;
                }
                timer.left = ability.repeatMs;
                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }
        }

        if (!me->HasUnitState(UNIT_STATE_CASTING))
            DoMeleeAttackIfReady();
    }

private:
    void TurnAway()
    {
        _breathFacing = frand(0.0f, 2.0f * float(M_PI));
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        me->StopMoving();
        me->SetTarget(ObjectGuid::Empty);
        me->SetOrientation(_breathFacing);
        me->SetFacingTo(_breathFacing);
        _turnedAway = true;
    }

    bool IsWanderer() const
    {
        uint32 const entry = me->GetEntry();
        return entry == NPC_WANDERER_1 || entry == NPC_WANDERER_2 || entry == NPC_WANDERER_3;
    }

    struct Timer
    {
        Ability const* ability;
        uint32 left;
    };
    std::vector<Timer> _timers;
    bool _turnedAway = false;
    float _breathFacing = 0.0f;
};

bool InTrapBreath(Creature const* trap, Player const* player)
{
    float const facing = trap->GetHomePosition().GetOrientation();
    return player->IsAlive() && !player->IsGameMaster() && trap->GetExactDist(player) <= TrapReach
        && std::fabs(Position::NormalizeOrientation(trap->GetAngle(player) - facing + float(M_PI)) - float(M_PI)) <= TrapHalfAngle
        && trap->IsWithinLOSInMap(player);
}

std::mutex TrapLastHitLock;
std::unordered_map<ObjectGuid, uint32> TrapLastHit;

void TrapBreathDamage(Creature* trap, Player* player)
{
    uint32 const now = uint32(GameTime::GetGameTimeMS().count());
    {
        std::lock_guard lock(TrapLastHitLock);
        auto const last = TrapLastHit.find(player->GetGUID());
        if (last != TrapLastHit.end() && now - last->second < TrapTickMs / 2)
            return;
        TrapLastHit[player->GetGUID()] = now;
    }
    SpellInfo const* venom = sSpellMgr->GetSpellInfo(SPELL_VENOM_TRAP);
    if (!venom || player->IsImmunedToDamage(trap, venom))
        return;
    int32 const base = std::max(0, venom->Effects[EFFECT_0].CalcValue(trap));
    uint32 const done = trap->SpellDamageBonusDone(player, venom, uint32(base), SPELL_DIRECT_DAMAGE, EFFECT_0);
    uint32 const taken = player->SpellDamageBonusTaken(trap, venom, done, SPELL_DIRECT_DAMAGE);
    SpellNonMeleeDamage damage(trap, player, venom, venom->GetSchoolMask());
    trap->CalculateSpellDamageTaken(&damage, int32(taken), venom);
    Unit::DealDamageMods(player, damage.damage, &damage.absorb);
    trap->DealSpellDamage(&damage, true);
    trap->SendSpellNonMeleeDamageLog(&damage);
}

struct npc_coa_other_side_venom_trap : public ScriptedAI
{
    explicit npc_coa_other_side_venom_trap(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
        me->SetObjectScale(TrapObjectScale);
        _rankIn = 0;
        _breathing = false;
    }

    void AttackStart(Unit* ) override { }
    void MoveInLineOfSight(Unit* ) override { }

    void UpdateAI(uint32 diff) override
    {
        if (_rankIn <= diff)
        {
            Rank();
            _rankIn = TrapRankMs;
        }
        else
            _rankIn -= diff;

        uint32 const active = TrapActiveMs.load();
        uint32 const cycle = _levels * active + TrapPauseMs.load();
        uint32 const now = uint32(GameTime::GetGameTimeMS().count() % cycle);
        bool const breathing = now >= _level * active && now < (_level + 1) * active;
        if (breathing && !_breathing)
        {
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
            me->CastSpell(me, SPELL_TRAP_BREATH_VISUAL, TRIGGERED_FULL_MASK);
            _tickIn = 0;
        }
        else if (!breathing && _breathing)
        {
            me->InterruptNonMeleeSpells(false);
            me->RemoveAurasDueToSpell(SPELL_TRAP_BREATH_VISUAL);
        }
        _breathing = breathing;
        if (!_breathing)
            return;

        if (_tickIn > diff)
        {
            _tickIn -= diff;
            return;
        }
        _tickIn = TrapTickMs;
        for (auto const& ref : me->GetMap()->GetPlayers())
            if (Player* player = ref.GetSource())
                if (InTrapBreath(me, player))
                    TrapBreathDamage(me, player);
    }

private:
    void Rank()
    {
        std::list<Creature*> traps;
        me->GetCreatureListWithEntryInGrid(traps, me->GetEntry(), TrapFlightReach);
        std::vector<float> heights;
        for (Creature* trap : traps)
        {
            float const z = trap->GetHomePosition().GetPositionZ();
            if (std::none_of(heights.begin(), heights.end(), [z](float h) { return std::fabs(h - z) < TrapLevelGap; }))
                heights.push_back(z);
        }
        float const own = me->GetHomePosition().GetPositionZ();
        if (std::none_of(heights.begin(), heights.end(), [own](float h) { return std::fabs(h - own) < TrapLevelGap; }))
            heights.push_back(own);
        _levels = uint32(heights.size());
        _level = uint32(std::count_if(heights.begin(), heights.end(), [own](float h) { return h < own - TrapLevelGap; }));
    }

    uint32 _rankIn = 0;
    uint32 _tickIn = 0;
    uint32 _level = 0;
    uint32 _levels = 1;
    bool _breathing = false;
};

class spell_coa_other_side_trap_breath_visual : public AuraScript
{
    PrepareAuraScript(spell_coa_other_side_trap_breath_visual);

    void SkipTrapTick(AuraEffect const* )
    {
        if (GetCaster() && GetCaster()->GetEntry() == NPC_VENOM_TRAP)
            PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_coa_other_side_trap_breath_visual::SkipTrapTick, EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class spell_coa_other_side_trash_damage : public SpellScript
{
    PrepareSpellScript(spell_coa_other_side_trash_damage);

    void HandleHit()
    {
        auto itr = Damages.find(BaseSpellId(GetSpellInfo()->Id));
        if (itr == Damages.end() || !itr->second.hit.mythic || !GetHitDamage())
            return;
        SetHitDamage(Rolled(GetCaster(), GetHitUnit(), itr->second.hit, GetSpellInfo()));
    }

    void AddSightedPlayers(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        if (!caster || BaseSpellId(GetSpellInfo()->Id) != SPELL_TOXIC_EXPULSION)
            return;
        for (auto const& ref : caster->GetMap()->GetPlayers())
        {
            Player* player = ref.GetSource();
            if (!player || !player->IsAlive() || player->IsGameMaster() || caster->GetExactDist(player) > ToxicExpulsionReach
                || !caster->IsValidAttackTarget(player) || !caster->IsWithinLOSInMap(player)
                || std::find(targets.begin(), targets.end(), player) != targets.end())
                continue;
            targets.push_back(player);
        }
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_other_side_trash_damage::HandleHit);
        if (m_scriptSpellId && BaseSpellId(m_scriptSpellId) == SPELL_TOXIC_EXPULSION)
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_other_side_trash_damage::AddSightedPlayers, EFFECT_ALL, TARGET_UNIT_SRC_AREA_ENEMY);
    }
};

class spell_coa_other_side_trash_damage_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_other_side_trash_damage_aura);

    void CalcTick(AuraEffect const* , int32& amount, bool& )
    {
        auto itr = Damages.find(BaseSpellId(GetSpellInfo()->Id));
        if (itr == Damages.end() || !itr->second.tick.mythic)
            return;
        if (Unit* caster = GetCaster())
            amount = Rolled(caster, GetUnitOwner(), itr->second.tick, GetSpellInfo());
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_coa_other_side_trash_damage_aura::CalcTick, EFFECT_ALL, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class spell_coa_other_side_fissure_strike : public SpellScript
{
    PrepareSpellScript(spell_coa_other_side_fissure_strike);

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        SpellInfo const* strike = sSpellMgr->GetSpellInfo(SPELL_EARTH_STRIKE);
        if (!strike)
            return;
        for (auto const& ref : caster->GetMap()->GetPlayers())
        {
            Player* player = ref.GetSource();
            if (!player || !player->IsAlive() || player->IsGameMaster() || std::fabs(player->GetPositionZ() - caster->GetPositionZ()) > 5.0f
                || player->IsImmunedToDamage(caster, strike))
                continue;
            float const dist = caster->GetExactDist2d(player);
            float const off = caster->GetRelativeAngle(player);
            float const along = dist * std::cos(off);
            float const across = std::fabs(dist * std::sin(off));
            if (along < 0.0f || along > FissureLength || across > FissureHalfWidth)
                continue;
            uint32 const value = player->SpellDamageBonusTaken(caster, strike, uint32(Rolled(caster, player, Damages.at(SPELL_FISSURE_STRIKE).hit, strike)), SPELL_DIRECT_DAMAGE);
            SpellNonMeleeDamage damage(caster, player, strike, strike->GetSchoolMask());
            caster->CalculateSpellDamageTaken(&damage, int32(value), strike);
            Unit::DealDamageMods(player, damage.damage, &damage.absorb);
            caster->DealSpellDamage(&damage, true);
            caster->SendSpellNonMeleeDamageLog(&damage);
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_coa_other_side_fissure_strike::HandleAfterCast);
    }
};

class spell_coa_other_side_brood_empowerment : public SpellScript
{
    PrepareSpellScript(spell_coa_other_side_brood_empowerment);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject* target)
        {
            return !caster || !target->ToCreature() || caster->GetExactDist(target) > BroodRange
                || (target->GetEntry() != NPC_SPIDER && target->GetEntry() != NPC_SPIDER_ADD);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_other_side_brood_empowerment::FilterTargets, EFFECT_ALL, TARGET_UNIT_SRC_AREA_ENTRY);
    }
};
}

using namespace Acore::ChatCommands;

class CoAOtherSideTrapCommands final : public CommandScript
{
public:
    CoAOtherSideTrapCommands() : CommandScript("CoAOtherSideTrapCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable trapCommands =
        {
            { "add", HandleAdd, SEC_GAMEMASTER, Console::No },
            { "delete", HandleDelete, SEC_GAMEMASTER, Console::No },
            { "fire", HandleFire, SEC_GAMEMASTER, Console::No },
            { "timing", HandleTiming, SEC_GAMEMASTER, Console::No },
            { "list", HandleList, SEC_GAMEMASTER, Console::No },
        };
        static ChatCommandTable roadCommands =
        {
            { "trap", trapCommands },
        };
        static ChatCommandTable commands =
        {
            { "road", roadCommands },
        };
        return commands;
    }

    static bool HandleAdd(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        Map* map = player->GetMap();
        Creature* creature = new Creature();
        if (!creature->Create(map->GenerateLowGuid<HighGuid::Unit>(), map, player->GetPhaseMaskForSpawn(), NPC_VENOM_TRAP, 0,
            player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation()))
        {
            delete creature;
            return false;
        }
        creature->SaveToDB(map->GetId(), SpawnMaskAllDifficulties, player->GetPhaseMaskForSpawn());
        ObjectGuid::LowType const spawnId = creature->GetSpawnId();
        creature->CleanupsBeforeDelete();
        delete creature;
        creature = new Creature();
        if (!creature->LoadCreatureFromDB(spawnId, map, true, true))
        {
            delete creature;
            return false;
        }
        sObjectMgr->AddCreatureToGrid(spawnId, sObjectMgr->GetCreatureData(spawnId));
        handler->PSendSysMessage("Trap {} placed at {:.2f} {:.2f} {:.2f}, facing {:.3f}.", spawnId,
            player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation());
        return true;
    }

    static bool HandleDelete(ChatHandler* handler)
    {
        Creature* trap = handler->GetSession()->GetPlayer()->FindNearestCreature(NPC_VENOM_TRAP, TrapCommandReach);
        if (!trap || !trap->GetSpawnId())
        {
            handler->SendErrorMessage("No placed trap within {:.0f} yards.", TrapCommandReach);
            return false;
        }
        ObjectGuid::LowType const spawnId = trap->GetSpawnId();
        trap->DeleteFromDB();
        trap->AddObjectToRemoveList();
        handler->PSendSysMessage("Trap {} deleted.", spawnId);
        return true;
    }

    static bool HandleFire(ChatHandler* handler)
    {
        Player* player = handler->GetSession()->GetPlayer();
        Creature* trap = player->FindNearestCreature(NPC_VENOM_TRAP, TrapListReach);
        if (!trap)
        {
            handler->SendErrorMessage("No trap nearby.");
            return false;
        }
        trap->SetFacingTo(trap->GetHomePosition().GetOrientation());
        trap->CastSpell(trap, SPELL_TRAP_BREATH_VISUAL, TRIGGERED_FULL_MASK);
        bool const inside = InTrapBreath(trap, player);
        if (inside)
            TrapBreathDamage(trap, player);
        handler->PSendSysMessage("Trap {} at {:.1f} yards breathes; you are {} its breath.", trap->GetSpawnId(), trap->GetExactDist(player), inside ? "inside" : "outside");
        return true;
    }

    static bool HandleTiming(ChatHandler* handler, uint32 activeMs, Optional<uint32> pauseMs)
    {
        if (activeMs < TrapTickMs)
        {
            handler->SendErrorMessage("Each breath must last at least {} ms.", TrapTickMs);
            return false;
        }
        TrapActiveMs = activeMs;
        if (pauseMs)
            TrapPauseMs = *pauseMs;
        handler->PSendSysMessage("Each statue breathes {} ms, then the next one up; {} ms pause after the top. Until the next restart.", TrapActiveMs.load(), TrapPauseMs.load());
        return true;
    }

    static bool HandleList(ChatHandler* handler)
    {
        std::list<Creature*> traps;
        handler->GetSession()->GetPlayer()->GetCreatureListWithEntryInGrid(traps, NPC_VENOM_TRAP, TrapListReach);
        for (Creature* trap : traps)
            handler->PSendSysMessage("Trap {}: {:.2f} {:.2f} {:.2f}, facing {:.3f}", trap->GetSpawnId(),
                trap->GetPositionX(), trap->GetPositionY(), trap->GetPositionZ(), trap->GetHomePosition().GetOrientation());
        handler->PSendSysMessage("{} traps; each breathes {} ms, {} ms pause after the top.", traps.size(), TrapActiveMs.load(), TrapPauseMs.load());
        return true;
    }
};

void AddSC_CoAOtherSideTrash()
{
    RegisterCreatureAI(npc_coa_other_side_trash);
    RegisterCreatureAI(npc_coa_other_side_venom_trap);
    RegisterSpellScript(spell_coa_other_side_trap_breath_visual);
    RegisterSpellAndAuraScriptPair(spell_coa_other_side_trash_damage, spell_coa_other_side_trash_damage_aura);
    RegisterSpellScript(spell_coa_other_side_fissure_strike);
    RegisterSpellScript(spell_coa_other_side_brood_empowerment);
    new CoAOtherSideTrapCommands();
}
