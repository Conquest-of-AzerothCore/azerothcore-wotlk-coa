/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionNecromancer.h"
#include "AscensionNecromancerData.h"
#include "Creature.h"
#include "DBCStores.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>

namespace AscensionNecromancer
{
namespace
{
bool Stationary(uint32 entry)
{
    return entry == 50132 || entry == 542064 || entry == 575091;
}
bool Ranged(uint32 entry)
{
    return entry == 50076 || entry == 50075 || entry == 50323 || entry == 50177;
}
bool Follows(uint32 entry)
{
    return !Stationary(entry) && entry != 523032 && entry != 542065;
}
void Formation(uint32 slot, float& distance, float& angle)
{
    uint32 ring = 0;
    uint32 places = 6;
    while (slot >= places && ring < 4)
    {
        slot -= places;
        places += 6;
        ++ring;
    }
    distance = PET_FOLLOW_DIST + 2.5f * float(ring);
    angle = Position::NormalizeOrientation(PET_FOLLOW_ANGLE + float(ring) * 0.4f +
                                           float(slot % places) * 2.0f * float(M_PI) / float(places));
}
uint32 Followers(Player* player)
{
    uint32 count = 0;
    for (Creature const* unit : Minions(player))
        if (Follows(unit->GetEntry()))
            ++count;
    return count;
}
uint8 SummonCount(Player const* player, SpellInfo const* info, NecromancerSummon const& row)
{
    int32 count = int32(player->ApplyEffectModifiers(info, row.effect, float(row.count)));
    return uint8(std::clamp(count, 1, 16));
}
uint32 FormationSlot(Player* player, Creature const* minion)
{
    uint32 slot = 0;
    for (Creature const* other : Minions(player))
    {
        if (other == minion)
            break;
        if (Follows(other->GetEntry()))
            ++slot;
    }
    return slot;
}
uint32 ChampionAura(uint32 entry)
{
    switch (entry)
    {
    case 500482:
        return 805050;
    case 500483:
        return 808017;
    case 500484:
        return 807812;
    default:
        return 0;
    }
}
uint32 AttackSpell(uint32 entry)
{
    switch (entry)
    {
    case 50067:
        return 805976;
    case 500650:
        return 572211;
    case 50075:
        return 801513;
    case 50076:
        return 801516;
    case 50323:
        return 822074;
    case 500484:
        return 801513;
    default:
        return 0;
    }
}
}
bool Responds(uint32 entry, uint32 command)
{
    switch (command)
    {
    case 504020:
    case 504489:
        return entry == 50075;
    case 504021:
        return entry == 50073;
    case 504052:
        return entry == 50067;
    case 504318:
        return entry == 50078;
    case 504319:
        return entry == 50076;
    case 504334:
    case 504905:
        return entry == 50065 || entry == 51065;
    case 504860:
        return entry == 50323;
    case 504862:
    case 504864:
        return entry == 500650;
    case 504050:
    case 504863:
        return entry == 50115;
    case 504316:
    case 504865:
        return entry == 50068;
    case 500991:
    case 504868:
    case 504907:
    case 504908:
    case 805871:
        return !Stationary(entry);
    default:
        return false;
    }
}
void Scale(Player* player, Creature* minion, uint8 cost, float& inheritedSpeed)
{
    float weight = float(std::max<uint8>(1, cost));
    float healthFraction = minion->GetHealthPct() / 100.0f;
    float manaFraction =
        minion->GetMaxPower(POWER_MANA) ? float(minion->GetPower(POWER_MANA)) / minion->GetMaxPower(POWER_MANA) : 1.0f;
    float stamina = (player->GetLevel() * 3.0f + player->GetStat(STAT_STAMINA) * 0.3f) * weight;
    float intellect = player->GetStat(STAT_INTELLECT);
    float spellPower = float(std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FROST),
                                      player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
    minion->SetLevel(player->GetLevel());
    minion->SetStatFlatModifier(UNIT_MOD_STAT_STAMINA, BASE_VALUE, stamina);
    minion->SetStatFlatModifier(UNIT_MOD_STAT_INTELLECT, BASE_VALUE, intellect * 0.3f * weight);
    minion->UpdateStats(STAT_STAMINA);
    minion->UpdateStats(STAT_INTELLECT);
    minion->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE,
                                50.0f * player->GetLevel() * weight + minion->GetStat(STAT_STAMINA) * 10);
    minion->UpdateMaxHealth();
    minion->SetHealth(std::max(1u, uint32(healthFraction * minion->GetMaxHealth())));
    minion->setPowerType(POWER_MANA);
    minion->SetStatFlatModifier(UNIT_MOD_MANA, BASE_VALUE, player->GetLevel() * 30.0f + intellect * 5 * weight);
    minion->UpdateMaxPower(POWER_MANA);
    minion->SetPower(POWER_MANA, int32(manaFraction * minion->GetMaxPower(POWER_MANA)));
    float ap = (intellect + std::max(0.0f, spellPower)) * 0.4f * weight;
    if (AuraEffect* inherited = minion->GetAuraEffect(805015, EFFECT_1))
        inherited->ChangeAmount(int32((intellect + std::max(0.0f, spellPower)) * 0.2f * weight));
    minion->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, ap);
    minion->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER_RANGED, BASE_VALUE, ap);
    minion->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, player->GetLevel() * weight);
    minion->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, player->GetLevel() * weight * 1.5f);
    minion->SetBaseWeaponDamage(RANGED_ATTACK, MINDAMAGE, player->GetLevel() * weight);
    minion->SetBaseWeaponDamage(RANGED_ATTACK, MAXDAMAGE, player->GetLevel() * weight * 1.5f);
    minion->UpdateAttackPowerAndDamage();
    minion->UpdateAttackPowerAndDamage(true);
    for (uint8 school = 0; school < MAX_SPELL_SCHOOL; ++school)
    {
        float value = player->GetResistance(SpellSchools(school)) * (school ? 0.4f : 0.35f);
        minion->SetStatFlatModifier(UnitMods(UNIT_MOD_RESISTANCE_START + school), BASE_VALUE, value);
        minion->UpdateResistances(school);
    }
    minion->m_modMeleeHitChance = player->m_modMeleeHitChance;
    minion->m_modRangedHitChance = player->m_modRangedHitChance;
    minion->m_modSpellHitChance = player->m_modSpellHitChance;
    minion->m_baseSpellCritChance = int32(player->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + SPELL_SCHOOL_FROST)) +
                                    minion->GetTotalAuraModifier(SPELL_AURA_MOD_CRIT_PCT) +
                                    minion->GetTotalAuraModifier(SPELL_AURA_MOD_SPELL_CRIT_CHANCE);
    float speed = std::max(0.1f, player->GetFloatValue(UNIT_MOD_CAST_SPEED));
    minion->SetFloatValue(UNIT_MOD_CAST_SPEED, minion->GetFloatValue(UNIT_MOD_CAST_SPEED) * speed / inheritedSpeed);
    inheritedSpeed = speed;
    minion->SetAttackTime(BASE_ATTACK, uint32(2000 * speed));
    minion->SetAttackTime(RANGED_ATTACK, uint32(2000 * speed));
}

bool Summon(Player* player, uint32 spell, Unit* target, Position const& position, int32 duration)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return false;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    if (!info)
        return false;
    uint8 cost = Cost(player, spell);
    if (cost && int32(Capacity(player)) - Used(player) < cost)
        return false;
    int32 lifetime = duration;
    if (!lifetime)
    {
        lifetime = info->GetDuration();
        if (lifetime > 0)
            player->ApplySpellMod(spell, SPELLMOD_DURATION, lifetime);
    }
    bool created = false;
    for (auto const& row : NecromancerSummons)
        if (row.spell == spell)
            for (uint8 i = 0, count = SummonCount(player, info, row); i < count; ++i)
            {
                if (cost && int32(Capacity(player)) - Used(player) < cost)
                {
                    Sync(player);
                    return created;
                }
                Position point = position;
                bool stationary = Stationary(row.creature);
                float distance = 1.5f + i * 0.5f;
                float angle = float(i) * 2.4f;
                if (Follows(row.creature))
                    Formation(Followers(player), distance, angle);
                bool const march = row.creature == 523032;
                Position aim;
                if (march)
                {
                    Unit* enemy = target && player->IsValidAttackTarget(target) ? target : nullptr;
                    if (!enemy)
                        if (Unit* selected = player->GetSelectedUnit())
                            if (player->IsValidAttackTarget(selected))
                                enemy = selected;
                    if (!enemy)
                        enemy = player->GetVictim();
                    if (!enemy)
                    {
                        float best = 30.0f;
                        for (Unit* nearby : Nearby(player, best))
                            if (player->IsValidAttackTarget(nearby) && player->GetExactDist(nearby) < best)
                            {
                                best = player->GetExactDist(nearby);
                                enemy = nearby;
                            }
                    }
                    if (enemy)
                        aim = enemy->GetPosition();
                    else if (player->GetExactDist2d(&position) > 3.0f)
                        aim = position;
                    else
                    {
                        aim = player->GetPosition();
                        player->MovePositionToFirstCollision(aim, 25.0f, 0.0f);
                    }
                    float const heading = player->GetAbsoluteAngle(aim.GetPositionX(), aim.GetPositionY());
                    point = player->GetPosition();
                    point.SetOrientation(heading);
                    player->MovePositionToFirstCollision(point, 2.0f, heading - player->GetOrientation());
                    float const lateral = (float(i) - (count - 1) / 2.0f) * 1.0f;
                    point.m_positionX += std::cos(heading + float(M_PI) / 2) * lateral;
                    point.m_positionY += std::sin(heading + float(M_PI) / 2) * lateral;
                    point.SetOrientation(heading);
                }
                else
                    player->MovePositionToFirstCollision(point, distance, angle);
                auto properties = sSummonPropertiesStore.LookupEntry(stationary ? 64 : 61);
                if (!properties)
                    return created;
                TempSummon* unit = player->GetMap()->SummonCreature(row.creature, point, properties,
                                                                    lifetime > 0 ? uint32(lifetime) : 0, player, spell);
                if (!unit)
                    continue;
                if (!IsMinion(player, unit))
                {
                    unit->DespawnOrUnsummon();
                    continue;
                }
                unit->SetTempSummonType(lifetime > 0 ? TEMPSUMMON_TIMED_DESPAWN : TEMPSUMMON_DEAD_DESPAWN);
                created = true;
                if (Follows(row.creature) && unit->IsGuardian())
                    static_cast<Minion*>(unit)->SetFollowAngle(angle);
                unit->GetMotionMaster()->Clear();
                if (row.creature == 523032)
                {
                    unit->SetWalk(true);
                    unit->GetMotionMaster()->MovePoint(1, aim);
                }
                else if (stationary)
                    unit->GetMotionMaster()->MoveIdle();
                else if (target && player->IsValidAttackTarget(target) && !player->HasAura(500983))
                    unit->AI()->AttackStart(target);
                else
                    unit->GetMotionMaster()->MoveFollow(player, distance, angle);
            }
    Sync(player);
    return created;
}

void Order(Player* player, Unit* target, uint32 spell)
{
    if (!target || !player->IsValidAttackTarget(target))
        target = player->GetVictim();
    if (!target || !player->IsValidAttackTarget(target))
        target = ObjectAccessor::GetUnit(*player, player->GetTarget());
    if (!target || !player->IsValidAttackTarget(target) || player->HasAura(500983))
        return;
    if (Creature* creature = target->ToCreature())
        if (!creature->IsDamageEnoughForLootingAndReward())
            creature->LowerPlayerDamageReq(creature->GetHealth(), true, player->GetLevel());
    State(player).focus = target->GetGUID();
    for (Creature* minion : Minions(player))
    {
        if (!Responds(minion->GetEntry(), spell) || !minion->IsWithinDistInMap(target, 60.0f) ||
            !minion->IsWithinLOSInMap(target))
            continue;
        minion->AI()->SetGUID(target->GetGUID(), 1);
        minion->AI()->SetData(1, spell);
        minion->AI()->DoAction(1);
    }
}
}

namespace
{
using namespace AscensionNecromancer;
class npc_ascension_necromancer : public ScriptedAI
{
  public:
    explicit npc_ascension_necromancer(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid _owner;
    ObjectGuid _target;
    ObjectGuid _breathTarget;
    EventMap _events;
    uint32 _command = 0;
    uint32 _spell = 0;
    uint8 _cost = 0;
    bool _exploded = false;
    float _inheritedSpeed = 1.0f;
    float _followRange = 0.0f;

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_NECROMANCER)
            return;
        _owner = player->GetGUID();
        _spell = me->GetUInt32Value(UNIT_CREATED_BY_SPELL);
        _cost = Cost(player, _spell);
        if (_cost && int32(Capacity(player)) - Used(player) < _cost)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(_owner);
        me->SetCreatorGUID(_owner);
        me->SetFaction(player->GetFaction());
        me->SetReactState(REACT_DEFENSIVE);
        me->SetCombatMovement(!Stationary(me->GetEntry()) && !Ranged(me->GetEntry()));
        State(player).minions.push_back({me->GetGUID(), _spell, _cost});
        me->AddAura(805015, me);
        Scale(player, me, _cost, _inheritedSpeed);
        me->SetHealth(me->GetMaxHealth());
        me->SetPower(POWER_MANA, me->GetMaxPower(POWER_MANA));
        if (_cost && player->HasAura(504866))
            player->CastCustomSpell(505224, SPELLVALUE_BASE_POINT0, int32(me->CountPctFromMaxHealth(40)), me, true);
        if (me->GetEntry() == 50073)
            player->AddAura(805290, me);
        if (uint32 occupancy = OccupancyAura(me->GetEntry()))
            me->CastSpell(me, occupancy, true);
        if (uint32 champion = ChampionAura(me->GetEntry()))
            me->CastSpell(me, champion, true);
        for (uint32 ward : {680388, 681460, 681529})
            if (Aura const* active = player->GetAura(ward))
                if (Aura* copy = player->AddAura(ward, me))
                    copy->SetDuration(active->GetDuration());
        if (me->GetEntry() == 50132)
        {
            ObjectGuid previous = State(player).phylactery;
            State(player).phylactery = me->GetGUID();
            if (Creature* old = ObjectAccessor::GetCreature(*me, previous))
                old->DespawnOrUnsummon();
        }
        _events.ScheduleEvent(1, 1ms);
        _events.ScheduleEvent(2, 2s);
        if (me->GetEntry() == 50133 || me->GetEntry() == 50303)
            _events.ScheduleEvent(3, Milliseconds(sSpellMgr->GetSpellInfo(807640)->Effects[1].Amplitude));
        if (me->GetEntry() == 542064)
            _events.ScheduleEvent(4, 2s);
        if (me->GetEntry() == 50177)
        {
            me->SetFloatValue(UNIT_FIELD_HOVERHEIGHT, 3.0f);
            me->SetHover(true);
            me->SetAnimTier(AnimTier::Fly);
            _events.ScheduleEvent(8, 2s);
        }
        if (me->GetEntry() == 503200)
            me->CastSpell(me, 531133, true);
        if (me->GetEntry() == 542065)
        {
            me->ToTempSummon()->SetTempSummonType(TEMPSUMMON_CORPSE_TIMED_DESPAWN);
            _events.ScheduleEvent(7, 500ms);
        }
        if (me->GetEntry() == 575091)
        {
            me->CastSpell(me, 807317, true);
            if (!player->HasSpell(807098))
                player->learnSpell(807098, true);
            auto previous = State(player).minions;
            for (auto const& row : previous)
                if (row.guid != me->GetGUID())
                    if (Creature* circle = ObjectAccessor::GetCreature(*player, row.guid))
                        if (circle->GetEntry() == 575091 && circle->GetOwnerGUID() == player->GetGUID())
                            circle->DespawnOrUnsummon();
        }
    }
    void SetGUID(ObjectGuid const& guid, int32 key) override
    {
        if (key == 1)
            _target = guid;
    }
    void MovementInform(uint32 type, uint32 id) override
    {
        if (me->GetEntry() == 523032 && type == POINT_MOTION_TYPE && id == 1)
            _events.RescheduleEvent(3, 1ms);
    }
    void SetData(uint32 key, uint32 value) override
    {
        if (key == 1)
            _command = value;
    }
    void AttackStart(Unit* target) override
    {
        Player* player = Owner(me);
        if (player && !Stationary(me->GetEntry()) && me->GetEntry() != 523032 && !player->HasAura(500983) &&
            target && player->IsValidAttackTarget(target))
            ScriptedAI::AttackStart(target);
    }
    void Regroup(Player* player)
    {
        float distance = PET_FOLLOW_DIST;
        float angle = PET_FOLLOW_ANGLE;
        Formation(FormationSlot(player, me), distance, angle);
        if (me->GetEntry() == 50177)
            angle = float(M_PI);
        if (std::fabs(_followRange - distance) < 0.01f && std::fabs(me->GetFollowAngle() - angle) < 0.01f &&
            me->GetMotionMaster()->GetCurrentMovementGeneratorType() == FOLLOW_MOTION_TYPE)
            return;
        if (me->IsGuardian())
            static_cast<Minion*>(me)->SetFollowAngle(angle);
        _followRange = distance;
        me->GetMotionMaster()->MoveFollow(player, distance, angle);
    }
    Unit* BreathTarget(Player* player)
    {
        if (Unit* victim = me->GetVictim(); victim && player->IsValidAttackTarget(victim))
            return victim;
        Unit* nearest = nullptr;
        for (auto const& [guid, reference] : player->GetCombatManager().GetPvECombatRefs())
            if (Unit* enemy = reference->GetOther(player); player->IsValidAttackTarget(enemy) &&
                me->IsWithinDistInMap(enemy, 40.0f) && me->IsWithinLOSInMap(enemy) &&
                (!nearest || me->GetDistance(enemy) < me->GetDistance(nearest)))
                nearest = enemy;
        return nearest;
    }
    void EnterEvadeMode(EvadeReason why) override
    {
        ScriptedAI::EnterEvadeMode(why);
        _followRange = 0.0f;
        Player* player = Owner(me);
        if (!player || !me->IsAlive() || !Follows(me->GetEntry()) || player->HasAura(500983) ||
            me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
            return;
        Regroup(player);
    }
    void DoAction(int32 action) override
    {
        Player* player = Owner(me);
        Unit* target = ObjectAccessor::GetUnit(*me, _target);
        if (action != 1 || !player || player->HasAura(500983) || !target || !target->IsAlive() ||
            !Responds(me->GetEntry(), _command) || me->HasUnitState(UNIT_STATE_CONTROLLED))
            return;
        AttackStart(target);
        if (_command == 500991)
            return;
        uint32 entry = me->GetEntry();
        if ((_command == 504316 && entry != 50068) || (_command == 504489 && entry != 50075) ||
            (_command == 504050 && entry != 50115))
            return;
        if (_command == 504316)
        {
            if (!target->IsImmuneToForcedMovement())
                target->GetMotionMaster()->MoveJump(me->GetPosition(), 24.0f, 8.0f);
            Cast(me, target, 800043);
            return;
        }
        if (_command == 504489)
        {
            for (Unit* unit : Nearby(target, 8.0f))
                if (player->IsValidAttackTarget(unit))
                    Cast(me, unit, 504845);
            return;
        }
        if (_command == 504050)
        {
            Cast(me, me, 801534);
            return;
        }
        switch (entry)
        {
        case 50065:
        case 51065:
            me->SetInFront(target);
            Cast(me, target, 570042);
            break;
        case 50073:
            Cast(me, target, 801514);
            break;
        case 50068:
            Copy(me, me, 504022, std::max(1, Amount(504022, 0, player) + Amount(505223, 1, player)));
            break;
        case 50115:
            _events.RescheduleEvent(5, 3s);
            break;
        case 50078:
            me->GetMotionMaster()->MoveJump(target->GetPosition(), 24.0f, 8.0f);
            _events.RescheduleEvent(6, 500ms);
            break;
        case 500650:
        {
            uint32 mana = std::min<uint32>(target->GetPower(POWER_MANA), std::min(target->GetMaxPower(POWER_MANA) / 10,
                                                                                  me->GetMaxPower(POWER_MANA) / 5));
            target->ModifyPower(POWER_MANA, -int32(mana));
            if (_command != 504864)
                Copy(me, target, 505225, mana);
            break;
        }
        case 50309:
            Cast(me, me, 801412);
            break;
        case 503030:
        case 503031:
        case 503032:
        case 523032:
            me->GetMotionMaster()->MoveCharge(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ());
            Cast(me, me, 504022);
            break;
        case 50067:
            Cast(me, target, 707598);
            break;
        case 50133:
        case 50303:
            Cast(me, target, 801518);
            break;
        case 50323:
            Cast(me, target, 822074);
            break;
        default:
            if (uint32 ability = AttackSpell(entry))
                Cast(me, target, ability);
            else
                Cast(me, me, 504022);
            break;
        }
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::FindPlayer(_owner);
        if (!player || !player->IsAlive() || !player->IsInMap(me) || !player->InSamePhase(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        _events.Update(diff);
        while (uint32 event = _events.ExecuteEvent())
        {
            if (event == 1)
            {
                Scale(player, me, Cost(player, _spell), _inheritedSpeed);
                bool passive = player->HasAura(500983) || Stationary(me->GetEntry());
                me->SetReactState(passive                   ? REACT_PASSIVE
                                  : player->HasAura(500982) ? REACT_AGGRESSIVE
                                                            : REACT_DEFENSIVE);
                if (me->GetEntry() == 523032)
                {
                    me->SetReactState(REACT_PASSIVE);
                }
                if (passive)
                {
                    me->AttackStop();
                    me->InterruptNonMeleeSpells(false);
                    if (Follows(me->GetEntry()))
                        Regroup(player);
                    else
                        me->GetMotionMaster()->MoveIdle();
                }
                else if (!me->GetVictim() && me->GetEntry() != 523032)
                {
                    Unit* target = ObjectAccessor::GetUnit(*me, State(player).focus);
                    if (!target || !player->IsValidAttackTarget(target))
                        target = player->GetVictim();
                    if (!target && !player->getAttackers().empty())
                        target = *player->getAttackers().begin();
                    if (!target && player->HasAura(500982))
                        for (Unit* unit : Nearby(me, 20.0f))
                            if (player->IsValidAttackTarget(unit) && player->IsHostileTo(unit) &&
                                me->IsWithinLOSInMap(unit))
                            {
                                target = unit;
                                break;
                            }
                    if (target)
                        AttackStart(target);
                    else if (Follows(me->GetEntry()))
                        Regroup(player);
                }
                if (me->GetEntry() == 50078 && me->IsAlive() && !me->GetVictim() && me->getAttackers().empty() &&
                    !me->HasAuraType(SPELL_AURA_MOD_STEALTH))
                    if (Aura* stealth = me->AddAura(1784, me))
                        if (AuraEffect* slow = stealth->GetEffect(EFFECT_2))
                            slow->ChangeAmount(0);
                if (me->GetEntry() == 50132 && player->HasAura(500730) && me->IsWithinDistInMap(player, 3.0f))
                {
                    State(player).shade = false;
                    player->RemoveAurasDueToSpell(500730);
                    player->RemoveAurasDueToSpell(500729);
                    player->SetHealth(player->CountPctFromMaxHealth(40));
                    me->DespawnOrUnsummon();
                    return;
                }
                _events.ScheduleEvent(1, 1s);
            }
            if (event == 2)
            {
                if (!player->HasAura(500983) && !me->HasUnitState(UNIT_STATE_CONTROLLED))
                {
                    if (me->GetEntry() == 50068)
                        Cast(me, me, 802353);
                    if (Unit* victim = me->GetVictim())
                        if (uint32 ability = AttackSpell(me->GetEntry()))
                            if (!me->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
                                Cast(me, victim, ability);
                }
                _events.ScheduleEvent(2, 3s);
            }
            if (event == 3 && !_exploded)
            {
                _exploded = true;
                if (me->GetEntry() == 523032)
                    Cast(me, me, 707010);
                else
                    Cast(me, me, 500585);
                me->DespawnOrUnsummon(100ms);
            }
            if (event == 4)
            {
                player->CastSpell(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(), 500365, true);
                _events.ScheduleEvent(4, 3s);
            }
            if (event == 5 && !player->HasAura(500983) && !me->HasUnitState(UNIT_STATE_CONTROLLED))
                if (Unit* victim = ObjectAccessor::GetUnit(*me, _target))
                    Cast(me, victim, 505229);
            if (event == 6 && !player->HasAura(500983) && !me->HasUnitState(UNIT_STATE_CONTROLLED))
                if (Unit* victim = ObjectAccessor::GetUnit(*me, _target))
                    if (me->IsWithinMeleeRange(victim))
                        for (uint8 hit = 0; hit < (victim->HealthBelowPct(35) ? 5 : 2); ++hit)
                            me->AttackerStateUpdate(victim, BASE_ATTACK, true);
            if (event == 7)
            {
                me->ToTempSummon()->SetTempSummonType(TEMPSUMMON_CORPSE_TIMED_DESPAWN);
                Unit::Kill(me, me);
                return;
            }
            if (event == 8)
            {
                if (!player->HasAura(500983) && !me->HasUnitState(UNIT_STATE_CONTROLLED))
                    if (Unit* enemy = BreathTarget(player))
                    {
                        _breathTarget = enemy->GetGUID();
                        Cast(me, enemy, 45200);
                        _events.ScheduleEvent(9, Milliseconds(uint32(me->GetDistance(enemy) * 1000.0f /
                                                                     sSpellMgr->GetSpellInfo(45200)->Speed)));
                    }
                _events.ScheduleEvent(8, 2s);
            }
            if (event == 9)
                if (Unit* enemy = ObjectAccessor::GetUnit(*me, _breathTarget))
                    Cast(me, enemy, 807339);
        }
        if (me->GetEntry() == 523032 && !_exploded)
            for (Unit* nearby : Nearby(me, 2.5f))
                if (player->IsValidAttackTarget(nearby))
                {
                    _events.RescheduleEvent(3, 1ms);
                    break;
                }
        if (!player->HasAura(500983) && !Stationary(me->GetEntry()) && !Ranged(me->GetEntry()) && UpdateVictim())
            DoMeleeAttackIfReady();
    }
};

class spell_ascension_necromancer_summon : public SpellScript
{
    PrepareSpellScript(spell_ascension_necromancer_summon);
    bool _summoned = false;
    void SummonEffect(SpellEffIndex index)
    {
        bool selected = false;
        for (auto const& row : NecromancerSummons)
            selected |= row.spell == GetSpellInfo()->Id && row.effect == index;
        if (!selected)
            return;
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        PreventHitDefaultEffect(index);
        if (_summoned)
            return;
        _summoned = true;
        Position position = GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetPosition();
        Summon(player, GetSpellInfo()->Id, GetExplTargetUnit(), position);
    }
    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_necromancer_summon::SummonEffect, EFFECT_ALL, SPELL_EFFECT_ANY);
    }
};

class necromancer_minion_dismiss : public ServerScript
{
  public:
    necromancer_minion_dismiss() : ServerScript("necromancer_minion_dismiss", {SERVERHOOK_CAN_PACKET_RECEIVE}) {}
    bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
    {
        if (packet.GetOpcode() != CMSG_CANCEL_AURA || packet.size() < sizeof(uint32) || !session)
            return true;
        Player* player = Owner(session->GetPlayer());
        uint32 creature = OccupancyCreature(packet.read<uint32>(0));
        if (!player || !creature || !player->IsInWorld())
            return true;
        auto minions = Minions(player, true);
        for (auto itr = minions.rbegin(); itr != minions.rend(); ++itr)
            if ((*itr)->GetEntry() == creature && (*itr)->IsAlive())
            {
                (*itr)->DespawnOrUnsummon();
                Sync(player);
                break;
            }
        return false;
    }
};

class spell_ascension_necromancer_warrior_strike : public SpellScript
{
    PrepareSpellScript(spell_ascension_necromancer_warrior_strike);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({570216});
    }

    void Pierce()
    {
        Creature* warrior = GetCaster()->ToCreature();
        Unit* target = GetHitUnit();
        if (warrior && warrior->GetEntry() == 51065 && target && target->IsAlive() && GetHitDamage() > 0)
            warrior->CastSpell(target, 570216, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_necromancer_warrior_strike::Pierce);
    }
};

class npc_ascension_necromancer_script : public GenericCreatureScript<npc_ascension_necromancer>
{
public:
    npc_ascension_necromancer_script() : GenericCreatureScript("npc_ascension_necromancer") {}

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (creature->GetEntry() != 50261)
            return false;
        player->PlayerTalkClass->ClearMenus();
        player->GetSession()->SendListInventory(creature->GetGUID());
        return true;
    }
};
}
void AddAscensionNecromancerSummonScripts()
{
    new npc_ascension_necromancer_script();
    RegisterSpellScript(spell_ascension_necromancer_warrior_strike);
    RegisterSpellScript(spell_ascension_necromancer_summon);
    new necromancer_minion_dismiss();
}
