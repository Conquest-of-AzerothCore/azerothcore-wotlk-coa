/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAOtherSideDamage.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include <cmath>
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
    { SPELL_TOXIC_EXPULSION, { { 589, 1209 }, { 55, 116 } } },
    { SPELL_BITING_CLOUD, { { 30, 74 }, { 0, 0 } } },
    { SPELL_FISSURE_STRIKE, { { 300, 1000 }, { 0, 0 } } },
};

constexpr float FissureLength = 20.0f;
constexpr float FissureHalfWidth = 2.0f;
constexpr float BroodRange = 30.0f;

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

    void Register() override
    {
        OnHit += SpellHitFn(spell_coa_other_side_trash_damage::HandleHit);
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

void AddSC_CoAOtherSideTrash()
{
    RegisterCreatureAI(npc_coa_other_side_trash);
    RegisterSpellAndAuraScriptPair(spell_coa_other_side_trash_damage, spell_coa_other_side_trash_damage_aura);
    RegisterSpellScript(spell_coa_other_side_fissure_strike);
    RegisterSpellScript(spell_coa_other_side_brood_empowerment);
}
