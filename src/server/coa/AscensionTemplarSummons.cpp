/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuras.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace
{
using namespace AscensionTemplar;
struct npc_ascension_templar_hope : public ScriptedAI
{
    npc_ascension_templar_hope(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid _owner;
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = Owner(summoner ? summoner->ToUnit() : nullptr);
        if (!player || me->GetUInt32Value(UNIT_CREATED_BY_SPELL) != 1397742)
        {
            me->DespawnOrUnsummon();
            return;
        }
        _owner = player->GetGUID();
        me->SetOwnerGUID(_owner);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetMaxHealth(std::max(1u, player->GetMaxHealth() / 2));
        me->SetHealth(me->GetMaxHealth());
        me->SetArmor(player->GetArmor());
        me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, player->GetFloatValue(UNIT_FIELD_MINDAMAGE) * .5f);
        me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, player->GetFloatValue(UNIT_FIELD_MAXDAMAGE) * .5f);
        me->SetAttackTime(BASE_ATTACK, player->GetAttackTime(BASE_ATTACK));
        me->UpdateDamagePhysical(BASE_ATTACK);
        player->CastSpell(me, 49889,
                          true);
        State(player).copies.push_back(me->GetGUID());
        me->SetReactState(REACT_DEFENSIVE);
        if (Unit* target = player->GetSelectedUnit(); target && player->IsValidAttackTarget(target))
            AttackStart(target);
    }
    void UpdateAI(uint32) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, _owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100.0f))
        {
            me->DespawnOrUnsummon();
            return;
        }
        if (Unit* target = me->GetVictim(); target && !player->IsValidAttackTarget(target))
            me->AttackStop();
        if (!me->GetVictim())
        {
            if (Unit* target = player->GetVictim(); target && player->IsValidAttackTarget(target))
                AttackStart(target);
            else
                me->GetMotionMaster()->MoveFollow(player, 2.0f, me->GetAngle(player));
        }
        if (UpdateVictim())
            DoMeleeAttackIfReady();
    }
};
}
void AddSC_AscensionTemplarSummons()
{
    RegisterCreatureAI(npc_ascension_templar_hope);
}
