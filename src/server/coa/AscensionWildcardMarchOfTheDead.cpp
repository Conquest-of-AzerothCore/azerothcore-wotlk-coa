/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "Creature.h"
#include "DBCStores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <cmath>
#include <list>

namespace
{
enum MarchOfTheDeadSpells : uint32
{
    SPELL_MARCH_OF_THE_DEAD_EXPLOSION = 280512
};

constexpr uint32 MARCH_POINT = 1;
constexpr float MARCH_SEARCH_RANGE = 30.0f;
constexpr float MARCH_FORWARD_RANGE = 25.0f;
constexpr float MARCH_LINE_SPACING = 1.0f;
constexpr float MARCH_CONTACT_RANGE = 2.5f;

std::list<Unit*> UnitsAround(Unit* center, float range)
{
    std::list<Unit*> units;
    Acore::AnyUnitInObjectRangeCheck check(center, range);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(center, units, check);
    Cell::VisitObjects(center, searcher, range);
    units.remove_if([center](Unit* unit) { return !unit->IsAlive() || !center->InSamePhase(unit); });
    units.sort([](Unit* a, Unit* b) { return a->GetGUID() < b->GetGUID(); });
    return units;
}

Unit* MarchTarget(Player* player, Unit* explicitTarget)
{
    if (explicitTarget && player->IsValidAttackTarget(explicitTarget))
        return explicitTarget;
    if (Unit* selected = player->GetSelectedUnit(); selected && player->IsValidAttackTarget(selected))
        return selected;
    if (Unit* victim = player->GetVictim(); victim && player->IsValidAttackTarget(victim))
        return victim;
    Unit* nearest = nullptr;
    float best = MARCH_SEARCH_RANGE;
    for (Unit* unit : UnitsAround(player, MARCH_SEARCH_RANGE))
        if (player->IsValidAttackTarget(unit) && player->GetExactDist(unit) < best)
        {
            best = player->GetExactDist(unit);
            nearest = unit;
        }
    return nearest;
}

struct npc_wildcard_march_of_the_dead_zombie : public ScriptedAI
{
    npc_wildcard_march_of_the_dead_zombie(Creature* creature) : ScriptedAI(creature)
    {
        me->SetReactState(REACT_PASSIVE);
    }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
    }

    void AttackStart(Unit*) override { }

    void MoveInLineOfSight(Unit*) override { }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type == POINT_MOTION_TYPE && id == MARCH_POINT)
            Explode();
    }

    void UpdateAI(uint32) override
    {
        if (_exploded)
            return;
        Unit* owner = me->GetCharmerOrOwner();
        if (!owner)
            return;
        for (Unit* unit : UnitsAround(me, MARCH_CONTACT_RANGE))
            if (owner->IsValidAttackTarget(unit))
            {
                Explode();
                return;
            }
    }

private:
    void Explode()
    {
        if (_exploded)
            return;
        _exploded = true;
        me->CastSpell(me, SPELL_MARCH_OF_THE_DEAD_EXPLOSION, true);
        me->DespawnOrUnsummon(100ms);
    }

    bool _exploded = false;
};

class spell_wildcard_march_of_the_dead : public SpellScript
{
    PrepareSpellScript(spell_wildcard_march_of_the_dead);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return ValidateSpellInfo({SPELL_MARCH_OF_THE_DEAD_EXPLOSION}) &&
            sSummonPropertiesStore.LookupEntry(spellInfo->Effects[EFFECT_0].MiscValueB);
    }

    void HandleMarch(SpellEffIndex effIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[effIndex];
        SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(effect.MiscValueB);
        if (!player || !properties)
            return;
        int32 duration = GetSpellInfo()->GetDuration();
        if (duration > 0)
            player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
        Position aim;
        if (Unit* enemy = MarchTarget(player, GetExplTargetUnit()))
            aim = enemy->GetPosition();
        else
        {
            aim = player->GetPosition();
            player->MovePositionToFirstCollision(aim, MARCH_FORWARD_RANGE, 0.0f);
        }
        float const heading = player->GetAbsoluteAngle(aim.GetPositionX(), aim.GetPositionY());
        Position front = player->GetPosition();
        player->MovePositionToFirstCollision(front, effect.CalcRadius(player), heading - player->GetOrientation());
        int32 const count = std::max(1, GetEffectValue());
        for (int32 i = 0; i < count; ++i)
        {
            Position point = front;
            float const lateral = (float(i) - float(count - 1) / 2.0f) * MARCH_LINE_SPACING;
            point.m_positionX += std::cos(heading + float(M_PI) / 2) * lateral;
            point.m_positionY += std::sin(heading + float(M_PI) / 2) * lateral;
            point.SetOrientation(heading);
            TempSummon* zombie = player->GetMap()->SummonCreature(uint32(effect.MiscValue), point, properties,
                duration > 0 ? uint32(duration) : 0, player, GetSpellInfo()->Id);
            if (!zombie)
                continue;
            zombie->SetTempSummonType(duration > 0 ? TEMPSUMMON_TIMED_DESPAWN : TEMPSUMMON_DEAD_DESPAWN);
            zombie->GetMotionMaster()->Clear();
            zombie->SetWalk(true);
            zombie->GetMotionMaster()->MovePoint(MARCH_POINT, aim);
        }
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_wildcard_march_of_the_dead::HandleMarch, EFFECT_0,
            SPELL_EFFECT_SCRIPT_EFFECT);
    }
};
}

void AddSC_AscensionWildcardMarchOfTheDead()
{
    RegisterCreatureAI(npc_wildcard_march_of_the_dead_zombie);
    RegisterSpellScript(spell_wildcard_march_of_the_dead);
}
