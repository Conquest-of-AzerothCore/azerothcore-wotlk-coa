/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionSummonedEffects.h"
#include "CellImpl.h"
#include "Creature.h"
#include "DBCStores.h"
#include "EventMap.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Item.h"
#include "MotionMaster.h"
#include "PetDefines.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <list>

using namespace AscensionSummonedEffects;

namespace
{
enum SummonedEffectEvents : uint32
{
    EVENT_ACT = 1,
    EVENT_OWNER_CHECK = 2,
    EVENT_PLACE = 3
};

enum SummonedEffectPoints : uint32
{
    POINT_OUT = 1,
    POINT_BACK = 2
};

constexpr uint32 MINE_POLL_MS = 250;
constexpr uint32 TURRET_RETRY_MS = 500;
constexpr uint32 PAYLOAD_GRACE_MS = 500;

Summon const* RowOf(Unit const* unit)
{
    return unit ? Find(unit->GetUInt32Value(UNIT_CREATED_BY_SPELL), unit->GetEntry()) : nullptr;
}

Unit* OwnerOf(Unit* unit)
{
    TempSummon* summon = unit ? unit->ToTempSummon() : nullptr;
    return summon ? summon->GetSummonerUnit() : nullptr;
}

void CastAt(Unit* source, std::uint32_t spellId, Unit* owner, AuraEffect const* triggeredBy = nullptr)
{
    if (spellId && owner)
        source->CastSpell(source->GetPositionX(), source->GetPositionY(), source->GetPositionZ(), spellId,
            true, nullptr, triggeredBy, owner->GetGUID());
}

void Outlive(Creature* anchor, std::uint32_t spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    TempSummon* summon = anchor->ToTempSummon();
    if (!summon)
        return;
    int32 const lasting = info ? info->GetMaxDuration() : 0;
    summon->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);
    summon->DespawnOrUnsummon(Milliseconds(std::max<int32>(lasting, 0) + int32(PAYLOAD_GRACE_MS)));
}

Creature* OwnedCreature(Unit* owner, std::uint32_t entry, float range)
{
    std::list<Creature*> creatures;
    owner->GetCreatureListWithEntryInGrid(creatures, entry, range);
    for (Creature* creature : creatures)
        if (creature->IsAlive() && OwnerOf(creature) == owner)
            return creature;
    return nullptr;
}

std::list<Unit*> EnemiesNear(Creature* center, Unit* owner, float radius)
{
    std::list<Unit*> enemies;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(center, owner, radius);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(center, enemies, check);
    Cell::VisitObjects(center, searcher, radius);
    enemies.remove_if([owner](Unit* enemy) { return !owner->IsValidAttackTarget(enemy); });
    return enemies;
}

void Freeze(Creature* ring, Summon const& row, Unit* owner, AuraEffect const* triggeredBy)
{
    SpellInfo const* freeze = sSpellMgr->GetSpellInfo(row.Payload);
    if (!freeze)
        return;
    for (Unit* enemy : EnemiesNear(ring, owner, freeze->Effects[EFFECT_0].CalcRadius(owner)))
    {
        if (enemy->HasAura(row.Extra, owner->GetGUID()))
            continue;
        ring->CastSpell(enemy, row.Extra, true, nullptr, triggeredBy, owner->GetGUID());
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_RADIUS_MOD, 100);
        SpellCastTargets targets;
        targets.SetDst(*enemy);
        ring->CastSpell(targets, freeze, &values, TRIGGERED_FULL_MASK, nullptr, triggeredBy, owner->GetGUID());
    }
}

bool IsAnchor(WorldObject const* object)
{
    Unit const* unit = object ? object->ToUnit() : nullptr;
    Summon const* row = unit && unit->IsCreature() ? RowOf(unit) : nullptr;
    return row && row->Kind != Behaviour::Attack;
}

Summon const* StoreRowOf(std::uint32_t buff)
{
    for (Summon const& summon : SUMMONS)
        if (summon.Kind == Behaviour::Store && summon.Helper == buff)
            return &summon;
    return nullptr;
}

void Release(Unit* owner, Summon const& row, int32 stored)
{
    Creature* totem = OwnedCreature(owner, row.Creature, 100.0f);
    Unit* source = totem ? static_cast<Unit*>(totem) : owner;
    if (stored > 0)
        source->CastCustomSpell(row.Payload, SPELLVALUE_BASE_POINT0, stored, source, true, nullptr, nullptr,
            owner->GetGUID());
    if (totem)
        totem->DespawnOrUnsummon();
}
}

struct npc_ascension_summoned_effect : public ScriptedAI
{
    explicit npc_ascension_summoned_effect(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;
    Summon const* row = nullptr;
    ObjectGuid ownerGuid;
    ObjectGuid targetGuid;
    uint32 charges = 0;
    Position destination;
    float velocity = 0.0f;
    bool slowed = false;

    bool Fights() const
    {
        return row && row->Kind == Behaviour::Attack;
    }

    void AttackStart(Unit* victim) override
    {
        if (Fights())
            ScriptedAI::AttackStart(victim);
    }

    void MoveInLineOfSight(Unit*) override { }

    void EnterEvadeMode(EvadeReason why) override
    {
        if (Fights())
            ScriptedAI::EnterEvadeMode(why);
    }

    Unit* Owner() const
    {
        return ObjectAccessor::GetUnit(*me, ownerGuid);
    }

    void IsSummonedBy(WorldObject* summoner) override
    {
        row = RowOf(me);
        Unit* owner = summoner ? summoner->ToUnit() : nullptr;
        if (!row || !owner)
        {
            me->DespawnOrUnsummon();
            return;
        }

        ownerGuid = owner->GetGUID();
        if (!me->GetOwnerGUID())
            me->SetOwnerGUID(ownerGuid);
        if (owner->HasUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED))
            me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        if (!Fights())
        {
            me->SetReactState(REACT_PASSIVE);
            if (!me->IsTotem())
                me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE);
        }

        switch (row->Kind)
        {
            case Behaviour::Spawn:
                me->CastSpell(me, row->Payload, true, nullptr, nullptr, ownerGuid);
                break;
            case Behaviour::Pulse:
            case Behaviour::Turret:
                events.ScheduleEvent(EVENT_ACT, 0ms);
                break;
            case Behaviour::Delay:
                events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
                break;
            case Behaviour::Ravager:
                Outlive(me, row->SummonSpell);
                events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
                break;
            case Behaviour::Mine:
                events.ScheduleEvent(EVENT_ACT, Milliseconds(MINE_POLL_MS));
                break;
            case Behaviour::Tick:
            case Behaviour::Expire:
            case Behaviour::Aura:
            case Behaviour::Freeze:
                me->CastSpell(me, row->Helper, true);
                break;
            case Behaviour::PullOwner:
                me->CastSpell(owner, row->Payload, true);
                break;
            case Behaviour::Heal:
                charges = LIGHTWELL_CHARGES;
                events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
                break;
            case Behaviour::Attack:
                if (Unit* victim = owner->GetVictim())
                    targetGuid = victim->GetGUID();
                else if (Player* player = owner->ToPlayer())
                    targetGuid = player->GetTarget();
                if (row->Extra)
                    me->CastSpell(me, row->Extra, true);
                me->SetReactState(REACT_DEFENSIVE);
                events.ScheduleEvent(EVENT_ACT, 0ms);
                break;
            default:
                break;
        }

        events.ScheduleEvent(EVENT_PLACE, 0ms);
        events.ScheduleEvent(EVENT_OWNER_CHECK, 1s);
    }

    void Place(Unit* owner)
    {
        if (row->Path != Motion::Stay)
            Launch(owner);
        else if (!Fights())
        {
            me->GetMotionMaster()->Clear(false);
            me->GetMotionMaster()->MoveIdle();
            me->StopMoving();
        }
    }

    void Launch(Unit* owner)
    {
        int32 travel = 0;
        for (uint32 spellId : { row->Helper, row->SummonSpell })
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId))
                if (int32 duration = info->GetMaxDuration(); duration > 0)
                    travel = travel ? std::min(travel, duration) : duration;
        if (row->Path == Motion::OutAndBack)
            travel /= 2;
        if (travel <= 0)
            return;

        me->SetOrientation(owner->GetOrientation());
        me->SetDisableGravity(true);
        velocity = row->Yards * 1000.0f / float(travel);
        destination = me->GetFirstCollisionPosition(row->Yards, 0.0f);
        me->GetMotionMaster()->MovePoint(POINT_OUT, destination, FORCED_MOVEMENT_RUN, velocity, false);
    }

    void Slow()
    {
        if (slowed || !row || row->Path == Motion::Stay || !me->isMoving())
            return;
        slowed = true;
        velocity *= SLOW_ON_HIT_RATE;
        me->GetMotionMaster()->MovePoint(POINT_OUT, destination, FORCED_MOVEMENT_RUN, velocity, false);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE || id != POINT_OUT || !row || row->Path != Motion::OutAndBack)
            return;
        if (Unit* owner = Owner())
            me->GetMotionMaster()->MovePoint(POINT_BACK, owner->GetPosition(), FORCED_MOVEMENT_RUN, velocity, false);
    }

    void JustDied(Unit*) override
    {
        if (row && row->Kind == Behaviour::Store)
            if (Unit* owner = Owner())
                owner->RemoveAurasDueToSpell(row->Helper);
    }

    void Act(Unit* owner)
    {
        switch (row->Kind)
        {
            case Behaviour::Pulse:
                me->CastSpell(me, row->Payload, true, nullptr, nullptr, ownerGuid);
                events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
                break;
            case Behaviour::Delay:
                CastAt(me, row->Payload, owner);
                Outlive(me, row->Payload);
                break;
            case Behaviour::Heal:
                Heal(owner);
                break;
            case Behaviour::Attack:
                Attack(owner);
                break;
            case Behaviour::Turret:
                Turret(owner);
                break;
            case Behaviour::Mine:
                Mine(owner);
                break;
            case Behaviour::Ravager:
                Ravager(owner);
                events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
                break;
            default:
                break;
        }
    }

    void Ravager(Unit* owner)
    {
        Player* player = owner->ToPlayer();
        if (!player)
            return;
        Item const* main = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        Item const* off = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
        uint32 const payload = main && main->GetTemplate()->InventoryType == INVTYPE_2HWEAPON && !off ?
            row->Payload : off && off->GetTemplate()->Class == ITEM_CLASS_WEAPON ? row->Extra : 0;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(row->SummonSpell);
        if (payload && info)
            for (Unit* enemy : EnemiesNear(me, owner, info->Effects[EFFECT_0].CalcRadius(owner)))
                player->CastSpell(enemy, payload, true);
    }

    void Heal(Unit* owner)
    {
        std::list<Unit*> allies;
        if (Player* player = owner->ToPlayer(); player && player->GetGroup())
        {
            for (GroupReference* ref = player->GetGroup()->GetFirstMember(); ref; ref = ref->next())
                if (Player* member = ref->GetSource())
                    allies.push_back(member);
        }
        else
            allies.push_back(owner);

        for (Unit* ally : allies)
        {
            if (!ally->IsAlive() || !ally->IsInMap(me) || !me->IsWithinDistInMap(ally, LIGHTWELL_RANGE) ||
                !ally->HealthBelowPct(LIGHTWELL_HEALTH_PCT) || ally->HasAura(row->Payload))
                continue;
            me->CastSpell(ally, row->Payload, true, nullptr, nullptr, ownerGuid);
            if (--charges == 0)
            {
                me->DespawnOrUnsummon();
                return;
            }
            break;
        }
        events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
    }

    void Attack(Unit* owner)
    {
        Unit* victim = ObjectAccessor::GetUnit(*me, targetGuid);
        if (!victim || !victim->IsAlive() || !me->IsValidAttackTarget(victim))
        {
            victim = owner->GetVictim();
            targetGuid = victim ? victim->GetGUID() : ObjectGuid::Empty;
        }

        if (victim && me->IsValidAttackTarget(victim))
        {
            if (me->GetVictim() != victim)
                AttackStart(victim);
            if (row->Payload && me->IsWithinLOSInMap(victim))
                me->CastSpell(victim, row->Payload, true, nullptr, nullptr, ownerGuid);
        }
        else if (!me->IsTotem() && !me->isMoving() && !me->IsWithinDistInMap(owner, PET_FOLLOW_DIST * 2))
            me->GetMotionMaster()->MoveFollow(owner, PET_FOLLOW_DIST, PET_FOLLOW_ANGLE);

        events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds ? row->Milliseconds : 1000));
    }

    void Turret(Unit* owner)
    {
        SpellInfo const* payload = sSpellMgr->GetSpellInfo(row->Payload);
        Unit* target = nullptr;
        if (payload)
        {
            std::list<Unit*> enemies = EnemiesNear(me, owner, payload->GetMaxRange(false, owner));
            enemies.remove_if([this](Unit* enemy) { return !me->IsWithinLOSInMap(enemy); });
            if (!enemies.empty())
            {
                enemies.sort(Acore::ObjectDistanceOrderPred(me));
                target = enemies.front();
            }
        }

        if (!target)
        {
            events.ScheduleEvent(EVENT_ACT, Milliseconds(TURRET_RETRY_MS));
            return;
        }

        me->SetFacingToObject(target);
        me->CastSpell(target, row->Payload, true, nullptr, nullptr, ownerGuid);
        if (row->Milliseconds)
            events.ScheduleEvent(EVENT_ACT, Milliseconds(row->Milliseconds));
    }

    void Mine(Unit* owner)
    {
        if (EnemiesNear(me, owner, MINE_TRIGGER_RADIUS).empty())
        {
            events.ScheduleEvent(EVENT_ACT, Milliseconds(MINE_POLL_MS));
            return;
        }
        me->CastSpell(me, row->Payload, true, nullptr, nullptr, ownerGuid);
        me->DespawnOrUnsummon(500ms);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!row)
            return;

        events.Update(diff);
        while (uint32 event = events.ExecuteEvent())
        {
            Unit* owner = Owner();
            if (!owner || !owner->IsInWorld() || owner->GetMap() != me->GetMap())
            {
                me->DespawnOrUnsummon();
                return;
            }
            if (event == EVENT_OWNER_CHECK)
                events.ScheduleEvent(EVENT_OWNER_CHECK, 1s);
            else if (event == EVENT_PLACE)
                Place(owner);
            else
                Act(owner);
        }

        if (Fights() && UpdateVictim())
            DoMeleeAttackIfReady();
    }
};

class aura_ascension_summoned_effect_tick : public AuraScript
{
    PrepareAuraScript(aura_ascension_summoned_effect_tick);

    void Tick(AuraEffect const* aurEff)
    {
        PreventDefaultAction();
        Creature* anchor = GetTarget()->ToCreature();
        Summon const* row = RowOf(anchor);
        Unit* owner = OwnerOf(anchor);
        if (!row || !owner || row->Helper != GetId())
            return;

        if (row->Kind == Behaviour::Freeze)
        {
            Freeze(anchor, *row, owner, aurEff);
            return;
        }
        CastAt(anchor, row->Payload, owner, aurEff);
        CastAt(anchor, row->Extra, owner, aurEff);
        if (!SlowsOnHit(row->Creature))
            return;
        SpellInfo const* payload = sSpellMgr->GetSpellInfo(row->Payload);
        if (payload && !EnemiesNear(anchor, owner, payload->Effects[EFFECT_0].CalcRadius(owner)).empty())
            if (npc_ascension_summoned_effect* ai = CAST_AI(npc_ascension_summoned_effect, anchor->AI()))
                ai->Slow();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_summoned_effect_tick::Tick, EFFECT_0,
            SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class aura_ascension_summoned_effect_expire : public AuraScript
{
    PrepareAuraScript(aura_ascension_summoned_effect_expire);

    void Expire(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Creature* anchor = GetTarget()->ToCreature();
        Summon const* row = RowOf(anchor);
        Unit* owner = OwnerOf(anchor);
        if (row && owner && row->Helper == GetId())
        {
            CastAt(anchor, row->Payload, owner, aurEff);
            Outlive(anchor, row->Payload);
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_summoned_effect_expire::Expire, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_skull_banner : public SpellScript
{
    PrepareSpellScript(spell_ascension_skull_banner);

    uint32 Fatigue()
    {
        Summon const* row = RowOf(GetCaster());
        return row ? row->Extra : 0;
    }

    void Filter(std::list<WorldObject*>& targets)
    {
        uint32 const fatigue = Fatigue();
        targets.remove_if([this, fatigue](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || IsAnchor(unit) || (fatigue && unit->HasAura(fatigue)) || unit->HasAura(GetSpellInfo()->Id);
        });
    }

    void ApplyFatigue()
    {
        if (uint32 const fatigue = Fatigue())
            if (Unit* target = GetHitUnit())
                GetCaster()->CastSpell(target, fatigue, true, nullptr, nullptr, GetOriginalCaster() ?
                    GetOriginalCaster()->GetGUID() : ObjectGuid::Empty);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_skull_banner::Filter, EFFECT_0,
            TARGET_UNIT_CASTER_AREA_RAID);
        AfterHit += SpellHitFn(spell_ascension_skull_banner::ApplyFatigue);
    }
};

class aura_ascension_ursols_vortex_range : public AuraScript
{
    PrepareAuraScript(aura_ascension_ursols_vortex_range);

    void Check(AuraEffect const*)
    {
        Summon const* row = FindByHelper(GetId(), Behaviour::Vortex);
        Unit* owner = GetCaster();
        Unit* target = GetTarget();
        if (!row || !owner || target->HasAura(row->Payload))
            return;
        Creature* vortex = OwnedCreature(owner, row->Creature, 60.0f);
        if (!vortex || target->IsWithinDist(vortex, VORTEX_RADIUS))
            return;
        vortex->CastSpell(target, row->Payload, true, nullptr, nullptr, owner->GetGUID());
        Remove();
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_ursols_vortex_range::Check, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

class aura_ascension_alter_time : public AuraScript
{
    PrepareAuraScript(aura_ascension_alter_time);

    void Return(AuraEffect const*, AuraEffectHandleModes)
    {
        Summon const* row = FindByHelper(GetId(), Behaviour::Return);
        if (!row || GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* target = GetTarget();
        if (Creature* marker = OwnedCreature(target, row->Creature, 200.0f))
        {
            target->NearTeleportTo(marker->GetPositionX(), marker->GetPositionY(), marker->GetPositionZ(),
                marker->GetOrientation());
            marker->DespawnOrUnsummon();
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_alter_time::Return, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_cloudburst : public AuraScript
{
    PrepareAuraScript(aura_ascension_cloudburst);

    void Burst(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        if (Summon const* row = StoreRowOf(GetId()))
            Release(GetTarget(), *row, aurEff->GetAmount());
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_cloudburst::Burst, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_cloudburst_heal : public SpellScript
{
    PrepareSpellScript(spell_ascension_cloudburst_heal);

    std::size_t injured = 0;

    void Filter(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* target)
        {
            Unit* unit = target->ToUnit();
            return !unit || IsAnchor(unit) || unit->IsFullHealth();
        });
        injured = targets.size();
    }

    void Split(SpellEffIndex)
    {
        SetHitHeal(injured ? int32(GetEffectValue() / int32(injured)) : 0);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_cloudburst_heal::Filter, EFFECT_0,
            TARGET_UNIT_DEST_AREA_ALLY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_cloudburst_heal::Split, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};

class spell_ascension_summoned_effect_summon : public SpellScript
{
    PrepareSpellScript(spell_ascension_summoned_effect_summon);

    void PreventRavagerArea(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Summon(SpellEffIndex index)
    {
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[index];
        AscensionSummonedEffects::Summon const* row = Find(GetSpellInfo()->Id, uint32(effect.MiscValue));
        Unit* caster = GetCaster();
        WorldLocation const* destination = GetHitDest();
        if (!row || !caster || !destination)
            return;

        PreventHitDefaultEffect(index);
        int32 duration = GetSpellInfo()->GetDuration();
        if (Player* modOwner = caster->GetSpellModOwner())
            modOwner->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
        caster->GetMap()->SummonCreature(row->Creature, *destination,
            sSummonPropertiesStore.LookupEntry(uint32(effect.MiscValueB)), duration > 0 ? uint32(duration) : 0, caster,
            GetSpellInfo()->Id);
    }

    void Register() override
    {
        if (m_scriptSpellId == 293180)
            OnEffectHit += SpellEffectFn(spell_ascension_summoned_effect_summon::PreventRavagerArea,
                EFFECT_ALL, SPELL_EFFECT_PERSISTENT_AREA_AURA);
        OnEffectHit += SpellEffectFn(spell_ascension_summoned_effect_summon::Summon, EFFECT_ALL, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_summoned_effect_ally_area : public SpellScript
{
    PrepareSpellScript(spell_ascension_summoned_effect_ally_area);

    void Filter(std::list<WorldObject*>& targets)
    {
        targets.remove_if(IsAnchor);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_summoned_effect_ally_area::Filter,
            EFFECT_ALL, TARGET_UNIT_DEST_AREA_ALLY);
    }
};

class AscensionCloudburstStorage : public UnitScript
{
public:
    AscensionCloudburstStorage() : UnitScript("AscensionCloudburstStorage", true, { UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    void ModifyHealReceived(Unit*, Unit* healer, uint32& heal, SpellInfo const* spellInfo) override
    {
        if (!healer || !spellInfo || !heal || !(spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NATURE))
            return;
        for (Summon const& row : SUMMONS)
        {
            if (row.Kind != Behaviour::Store || spellInfo->Id == row.Payload)
                continue;
            if (AuraEffect* stored = healer->GetAuraEffect(row.Helper, EFFECT_0))
                stored->ChangeAmount(stored->GetAmount() + int32(CalculatePct(heal, row.Extra)), false);
        }
    }
};

void AddSC_AscensionSummonedEffects()
{
    RegisterCreatureAI(npc_ascension_summoned_effect);
    RegisterSpellScript(aura_ascension_summoned_effect_tick);
    RegisterSpellScript(aura_ascension_summoned_effect_expire);
    RegisterSpellScript(spell_ascension_skull_banner);
    RegisterSpellScript(aura_ascension_ursols_vortex_range);
    RegisterSpellScript(aura_ascension_alter_time);
    RegisterSpellScript(aura_ascension_cloudburst);
    RegisterSpellScript(spell_ascension_cloudburst_heal);
    RegisterSpellScript(spell_ascension_summoned_effect_summon);
    RegisterSpellScript(spell_ascension_summoned_effect_ally_area);
    new AscensionCloudburstStorage();
}
