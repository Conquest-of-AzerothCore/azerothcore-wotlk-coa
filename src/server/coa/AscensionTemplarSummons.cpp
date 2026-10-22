/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace
{
using namespace AscensionTemplar;
constexpr uint32 SPELL_HOPE_STEALTH = 1784;
constexpr uint32 SPELL_HOPE_MITIGATION = 704409;
constexpr float HopeSpotRadius = 2.5f;
constexpr float HopeSpotStagger = 1.0f;
constexpr float HopeSpotAngle = 0.9f;
constexpr float HopeSpotTolerance = 1.0f;
constexpr uint32 HopeRepositionInterval = 500;
constexpr uint32 HopeSpotPoint = 1;
Position HopeSpot(Player* player, float angle, float radius)
{
    float x = player->GetPositionX() + radius * std::cos(player->GetOrientation() + angle);
    float y = player->GetPositionY() + radius * std::sin(player->GetOrientation() + angle);
    float z = player->GetPositionZ();
    player->UpdateGroundPositionZ(x, y, z);
    return Position(x, y, z, player->GetOrientation());
}
struct npc_ascension_templar_hope : public ScriptedAI
{
    npc_ascension_templar_hope(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid _owner;
    float _angle = 0.0f;
    float _radius = HopeSpotRadius;
    uint32 _reposition = 0;
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
        player->AddAura(49889, me);
        for (uint8 hand = 0; hand < 2; ++hand)
            me->SetUInt32Value(UNIT_VIRTUAL_ITEM_SLOT_ID + hand,
                               player->GetUInt32Value(PLAYER_VISIBLE_ITEM_16_ENTRYID + hand * 2));
        uint32 living = 0;
        for (ObjectGuid guid : State(player).copies)
            if (Creature* copy = ObjectAccessor::GetCreature(*player, guid); copy && copy->IsAlive())
                ++living;
        _angle = float(M_PI) + (living % 2 ? HopeSpotAngle : -HopeSpotAngle);
        _radius = HopeSpotRadius + (living % 2 ? HopeSpotStagger : 0.0f);
        Position spot = HopeSpot(player, _angle, _radius);
        if (!player->IsWithinLOS(spot.GetPositionX(), spot.GetPositionY(), spot.GetPositionZ()))
            spot = player->GetPosition();
        me->NearTeleportTo(spot.GetPositionX(), spot.GetPositionY(), spot.GetPositionZ(), player->GetOrientation());
        State(player).copies.push_back(me->GetGUID());
        me->SetReactState(REACT_DEFENSIVE);
        if (Aura* stealth = me->AddAura(SPELL_HOPE_STEALTH, me))
            if (AuraEffect* slow = stealth->GetEffect(EFFECT_2))
                slow->ChangeAmount(0);
        me->AddAura(SPELL_HOPE_MITIGATION, me);
    }
    void AttackStart(Unit* who) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, _owner);
        if (!who || !player)
            return;
        Unit* aimed = who->GetVictim();
        if (player->GetSelectedUnit() == who || player->GetVictim() == who || aimed == me || aimed == player)
            ScriptedAI::AttackStart(who);
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, _owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100.0f))
        {
            me->DespawnOrUnsummon();
            return;
        }
        _reposition = _reposition > diff ? _reposition - diff : 0;
        if (Unit* target = me->GetVictim(); target && !player->IsValidAttackTarget(target))
            me->AttackStop();
        Unit* target = player->GetSelectedUnit();
        if (!target || !player->IsValidAttackTarget(target) || !player->IsHostileTo(target))
            target = player->GetVictim();
        if (target && player->IsValidAttackTarget(target))
        {
            if (target != me->GetVictim())
                AttackStart(target);
        }
        else if (!me->GetVictim() && !_reposition)
        {
            _reposition = HopeRepositionInterval;
            Position spot = HopeSpot(player, _angle, _radius);
            if (me->GetExactDist2d(&spot) > HopeSpotTolerance)
                me->GetMotionMaster()->MovePoint(HopeSpotPoint, spot);
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
