/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"

namespace
{
enum CursedEffigySpells : uint32
{
    CursedField = 506820
};

constexpr float CursedEffigyRadius = 10.0f;
constexpr uint32 CursedEffigyPeriod = 2000;

struct npc_ascension_wildcard_cursed_effigy : public ScriptedAI
{
    explicit npc_ascension_wildcard_cursed_effigy(Creature* creature) : ScriptedAI(creature) { }

    ObjectGuid _owner;
    uint32 _timer = 1;

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player)
            return;
        _owner = player->GetGUID();
        me->SetOwnerGUID(_owner);
        me->SetCreatorGUID(_owner);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->SetCombatMovement(false);
        me->GetMotionMaster()->MoveIdle();
    }

    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::FindPlayer(_owner);
        if (!player || !player->IsAlive() || !player->IsInMap(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        if (diff >= _timer)
        {
            _timer = CursedEffigyPeriod;
            std::list<Unit*> targets;
            Acore::AnyUnfriendlyUnitInObjectRangeCheck check(me, me, CursedEffigyRadius);
            Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(me, targets, check);
            Cell::VisitObjects(me, searcher, CursedEffigyRadius);
            for (Unit* target : targets)
                if (player->IsValidAttackTarget(target))
                {
                    me->CastSpell(target, CursedField, true, nullptr, nullptr, _owner);
                    if (Aura* aura = target->GetAura(CursedField, _owner))
                        aura->SetDuration(CursedEffigyPeriod + 200);
                }
        }
        else
            _timer -= diff;
    }
};
}

void AddSC_AscensionWildcardCursedEffigy()
{
    RegisterCreatureAI(npc_ascension_wildcard_cursed_effigy);
}
