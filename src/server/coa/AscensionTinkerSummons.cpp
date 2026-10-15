/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "Creature.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "PetAI.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include "Vehicle.h"
#include <algorithm>
namespace AscensionTinker
{
enum TinkerSummonSpell : uint32
{
    DestructoBot = 804673
};

bool Permanent(uint32 entry)
{
    return entry == 50048 || entry == 500481 || entry == 60671 || entry == 60070 || entry == 60672;
}
uint32 AbilitySkillLine(uint32 entry)
{
    switch (entry)
    {
        case 60070: return 10037;
        case 60671: return 10038;
        case 60672: return 10039;
        case 500481: return 10040;
        case 50048: return 10041;
        default: return 0;
    }
}
void TeachAbilities(Pet* pet)
{
    for (SkillLineAbilityEntry const* ability : GetSkillLineAbilitiesBySkillLine(AbilitySkillLine(pet->GetEntry())))
        if (SpellInfo const* spell = sSpellMgr->GetSpellInfo(ability->Spell))
        {
            if (spell->SpellLevel > pet->GetLevel())
                pet->unlearnSpell(spell->Id,false);
            else if (!pet->HasSpell(spell->Id))
                pet->learnSpell(spell->Id);
        }
}
bool Turret(uint32 entry)
{
    return entry == 50046;
}
bool Beacon(uint32 entry)
{
    return entry == 50037 || entry == 500360 || entry == 500361 || entry == 50036 || entry == 51036 ||
        entry == 53036 || entry == 54036 || entry == 55036 || entry == 56036;
}
bool Owned(Player* player, Unit* unit)
{
    return player && unit && unit->IsCreature() && unit->IsAlive() && unit->IsInWorld() &&
        unit->GetOwnerGUID() == player->GetGUID() && player->IsInMap(unit) &&
        (State(player).summons.count(unit->GetGUID()) || unit == player->GetPet());
}
std::list<Creature*> Devices(Player* player)
{
    std::list<Creature*> result;
    auto& guids = State(player).summons;
    for (auto it = guids.begin(); it != guids.end();)
    {
        Creature* creature = ObjectAccessor::GetCreature(*player,*it);
        if (!Owned(player,creature))
            it = guids.erase(it);
        else
        {
            result.push_back(creature);
            ++it;
        }
    }
    if (Pet* pet = player->GetPet(); Owned(player,pet) && Permanent(pet->GetEntry()) &&
        std::find(result.begin(),result.end(),pet) == result.end())
        result.push_back(pet);
    return result;
}
void Scale(Player* player, Creature* creature, bool initial)
{
    uint32 health = creature->GetHealth();
    uint32 maximumHealth = creature->GetMaxHealth();
    float mana = creature->GetMaxPower(POWER_MANA) ?
        float(creature->GetPower(POWER_MANA)) / creature->GetMaxPower(POWER_MANA) : 1;
    creature->SetLevel(player->GetLevel());
    if (!creature->HasAura(707698))
        Cast(player,creature,707698);
    float stamina = player->GetStat(STAT_STAMINA) * .3f;
    float intellect = player->GetStat(STAT_INTELLECT) * .3f;
    creature->SetStatFlatModifier(UNIT_MOD_STAT_STAMINA,BASE_VALUE,stamina);
    creature->SetStatFlatModifier(UNIT_MOD_STAT_INTELLECT,BASE_VALUE,intellect);
    creature->UpdateStats(STAT_STAMINA);
    creature->UpdateStats(STAT_INTELLECT);
    creature->SetStat(STAT_STAMINA,int32(creature->GetTotalStatValue(STAT_STAMINA)));
    creature->SetStat(STAT_INTELLECT,int32(creature->GetTotalStatValue(STAT_INTELLECT)));
    creature->SetStatFlatModifier(UNIT_MOD_HEALTH,BASE_VALUE,player->GetLevel() * 35.0f + creature->GetStat(STAT_STAMINA) * 10);
    creature->UpdateMaxHealth();
    creature->SetHealth(initial || !maximumHealth ? creature->GetMaxHealth() :
        std::max(1u, uint32(uint64(health) * creature->GetMaxHealth() / maximumHealth)));
    creature->SetStatFlatModifier(UNIT_MOD_MANA,BASE_VALUE,player->GetLevel() * 15.0f + creature->GetStat(STAT_INTELLECT) * 15);
    creature->UpdateMaxPower(POWER_MANA);
    creature->SetPower(POWER_MANA,initial ? creature->GetMaxPower(POWER_MANA) :
        uint32(creature->GetMaxPower(POWER_MANA) * mana));
    float ap = .4f * player->GetTotalAttackPowerValue(RANGED_ATTACK) + .4f * player->GetStat(STAT_INTELLECT);
    creature->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER,BASE_VALUE,ap);
    creature->UpdateAttackPowerAndDamage();
    creature->SetBaseWeaponDamage(BASE_ATTACK,MINDAMAGE,player->GetLevel() * 1.0f);
    creature->SetBaseWeaponDamage(BASE_ATTACK,MAXDAMAGE,player->GetLevel() * 1.5f);
    creature->UpdateDamagePhysical(BASE_ATTACK);
    creature->SetStatFlatModifier(UNIT_MOD_ARMOR,BASE_VALUE,float(player->GetArmor()) / 2);
    creature->UpdateArmor();
    if (!creature->HasAura(707698))
        Cast(player,creature,707698);
    for (uint32 talent : {560742,705792})
    {
        if (player->HasAura(talent) && !creature->HasAura(talent))
            Cast(player,creature,talent);
        else if (!player->HasAura(talent))
            creature->RemoveAurasDueToSpell(talent);
    }
}
void Summon(Player* player, Unit* target, uint32 spell, Position const* destination)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    if (!info)
        return;
    uint32 entry = 0, count = 1;
    SummonPropertiesEntry const* properties = nullptr;
    for (auto const& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_SUMMON)
        {
            entry = effect.MiscValue;
            if (spell == DestructoBot)
            {
                properties = sSummonPropertiesStore.LookupEntry(effect.MiscValueB);
                if (!properties || properties->Category != SUMMON_CATEGORY_PUPPET)
                    return;
            }
            break;
        }
    if (spell == 500535) entry = 226012;
    if (spell == 802477) entry = 840028;
    if (spell == 500600) entry = 226112;
    if (spell == 850020 || spell == 806760) count = 2;
    if (spell == 500236) count = 3;
    if (spell == 500535)
        count = uint32(std::max(1, info->Effects[EFFECT_1].CalcValue(player)));
    if (!entry)
        return;
    if (spell == 500239)
        for (Creature* old : Devices(player))
            if (Turret(old->GetEntry()))
            {
                old->DespawnOrUnsummon();
                return;
            }
    Position origin = destination ? *destination : player->GetPosition();
    int32 modifiedDuration = info->GetDuration();
    player->ApplySpellMod(spell, SPELLMOD_DURATION, modifiedDuration);
    uint32 duration = uint32(std::max(1000, modifiedDuration));
    if (spell == 500535 || spell == 802477 || spell == 500600)
        duration = 15000;
    for (uint32 n = 0; n < count; ++n)
    {
        Position position = origin;
        if (spell == 500600)
            position.Relocate(position.GetPositionX(),position.GetPositionY(),position.GetPositionZ() + 5,position.GetOrientation());
        if (spell == 500236)
            player->MovePositionToFirstCollision(position,1 + n * 1.5f,0);
        if (TempSummon* device = player->SummonCreature(entry,position,TEMPSUMMON_TIMED_DESPAWN,duration,0,properties))
        {
            device->AI()->SetData(1,spell);
            if (target)
                device->AI()->SetGUID(target->GetGUID(),1);
        }
    }
    if (spell == 804707 || spell == 805308)
        player->SummonGameObject(spell == 804707 ? 2201005 : 9000007,origin.GetPositionX(),origin.GetPositionY(),
            origin.GetPositionZ(),origin.GetOrientation(),0,0,0,1,duration/1000);
}
void Overcharge(Player* player, Creature* device)
{
    if (!Owned(player,device) || !Beacon(device->GetEntry()) || !player->HasAura(524834) ||
        device->HasAura(560711) || !player->IsWithinDistInMap(device,60))
        return;
    Cast(player,device,560711);
    uint32 entry = device->GetEntry();
    for (Unit* ally : Allies(player,device,entry == 50037 || entry == 500360 || entry == 500361 ? 15 : Radius(706829)))
    {
        if (entry == 50037)
            Cast(player,ally,560710);
        else if (entry == 500360)
            Mana(ally,CalculatePct(ally->GetMaxPower(POWER_MANA),Amount(560753)),player);
        else if (entry == 500361)
            Cast(player,ally,560757);
        else
            Cast(player,ally,560709);
    }
}
void Detonate(Player* player)
{
    for (Creature* device : Devices(player))
        if ((device->GetEntry() == 50045 || device->GetEntry() == 50600) && player->IsWithinDistInMap(device,60))
            device->AI()->DoAction(1);
}
}
namespace
{
using namespace AscensionTinker;
struct npc_ascension_tinker_pet : PetAI
{
    explicit npc_ascension_tinker_pet(Creature* creature) : PetAI(creature) { }
    EventMap events;
    bool initialized = false;
    uint8 taughtLevel = 0;
    void UpdateAI(uint32 diff) override
    {
        Player* player = Owner(me);
        if (player && Permanent(me->GetEntry()))
        {
            events.Update(diff);
            if (!initialized)
            {
                if (CharmInfo* charmInfo = me->GetCharmInfo())
                {
                    if (me->HasReactState(REACT_PASSIVE) && charmInfo->GetPlayerReactState() != REACT_PASSIVE)
                    {
                        me->SetReactState(REACT_DEFENSIVE);
                        charmInfo->SetPlayerReactState(REACT_DEFENSIVE);
                    }
                }
            }
            if (!initialized || events.ExecuteEvent())
            {
                Scale(player,me,!initialized);
                if (Pet* pet = me->ToPet(); pet && pet->GetLevel() != taughtLevel)
                {
                    TeachAbilities(pet);
                    taughtLevel = pet->GetLevel();
                }
                initialized = true;
                events.ScheduleEvent(1,1000ms);
                if (me->GetEntry() == 500481)
                    if (Unit* enemy = player->GetVictim(); enemy && player->IsValidAttackTarget(enemy))
                        Cast(me,enemy,520375);
            }
        }
        PetAI::UpdateAI(diff);
    }
};
struct npc_ascension_tinker_device : ScriptedAI
{
    explicit npc_ascension_tinker_device(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid owner, focus, pursued;
    Position start, previous;
    EventMap events;
    std::set<ObjectGuid> used;
    uint32 spell = 0, explosionTargets = 0;
    float travelled = 0, travelledAtLastFirepot = 0;
    bool exploded = false;
    bool Mobile() const
    {
        return me->GetEntry() == 226312 || me->GetEntry() == 226012 || me->GetEntry() == 840028 ||
            me->GetEntry() == 226112 || me->GetEntry() == 500711 || me->GetEntry() == 50300;
    }
    bool Bomb() const
    {
        return me->GetEntry() == 226012 || me->GetEntry() == 840028 || me->GetEntry() == 226112;
    }
    bool Explosive() const
    {
        return Bomb() || me->GetEntry() == 50045 || me->GetEntry() == 50600 || me->GetEntry() == 226312;
    }
    void Pursue(Unit* target)
    {
        MotionMaster* motion = me->GetMotionMaster();
        if (!Bomb())
            motion->MoveChase(target);
        else if (pursued != target->GetGUID() || motion->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
        {
            pursued = target->GetGUID();
            me->SetWalk(false);
            motion->MoveFollow(target,0,0,MOTION_SLOT_ACTIVE,false,false);
        }
    }
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = Owner(summoner ? summoner->ToUnit() : nullptr);
        if (!player)
            return;
        owner = player->GetGUID();
        me->SetOwnerGUID(owner);
        player->m_Controlled.insert(me);
        me->SetFaction(player->GetFaction());
        if (Turret(me->GetEntry()) || Explosive())
        {
            me->m_ControlledByPlayer = true;
            me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
            me->SetByteValue(UNIT_FIELD_BYTES_2, 1, player->GetByteValue(UNIT_FIELD_BYTES_2, 1));
        }
        me->SetReactState(REACT_PASSIVE);
        me->SetCombatMovement(Mobile());
        State(player).summons.insert(me->GetGUID());
        Scale(player,me,true);
        if (Turret(me->GetEntry()))
        {
            Cast(player, player, 807293);
            if (!player->HasSpell(500470))
                player->learnSpell(500470, true);
            player->SetTemporarySpellReplacement(500239, 500470);
        }
        focus = State(player).focus;
        start = previous = me->GetPosition();
        if (!Mobile())
            me->GetMotionMaster()->MoveIdle();
        if (me->GetEntry() == 50045 || me->GetEntry() == 50600)
            Cast(me,me,500354);
        if (me->GetEntry() == 226312)
        {
            Position end = start;
            me->MovePositionToFirstCollision(end,40,0);
            me->GetMotionMaster()->MovePoint(1,end);
        }
        if (me->GetEntry() == 840028)
            me->SetSpeed(MOVE_RUN,.5f);
        if (me->GetEntry() == 226112)
            me->SetCanFly(true);
        if (me->GetEntry() == 506051 || me->GetVehicleKit())
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        if (me->GetEntry() == 506051 || me->GetEntry() == 289612)
        {
            me->SetVisible(false);
            me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }
        events.ScheduleEvent(1,200ms);
        uint32 first = me->GetEntry() == 50037 ? 3000 : me->GetEntry() == 500362 ? 1500 :
            me->GetEntry() == 500360 ? 2500 : Turret(me->GetEntry()) ? 2000 : 1000;
        events.ScheduleEvent(2,Milliseconds(first));
    }
    void SetData(uint32 id, uint32 value) override
    {
        if (id == 1)
            spell = value;
    }
    void SetGUID(ObjectGuid const& guid, int32 id) override
    {
        if (id == 1)
        {
            focus = guid;
            if (Mobile() && me->GetEntry() != 226312)
                if (Unit* target = ObjectAccessor::GetUnit(*me,guid))
                    Pursue(target);
        }
    }
    uint32 GetData(uint32 id) const override
    {
        if (id == 2)
            return explosionTargets;
        if (id == 3)
            return uint32(1000 * (1 + std::min(40.0f,travelled) / 40));
        return 0;
    }
    void Explode()
    {
        Player* player = ObjectAccessor::FindPlayer(owner);
        if (!player || exploded)
            return;
        exploded = true;
        uint32 id = me->GetEntry() == 50045 ? 802336 : me->GetEntry() == 50600 ? 706648 :
            me->GetEntry() == 840028 ? 802477 : me->GetEntry() == 226112 ? 500601 :
            me->GetEntry() == 226312 ? 806074 : 801982;
        auto* info = sSpellMgr->GetSpellInfo(id);
        auto targets = Nearby(me,Radius(id));
        targets.remove_if([player](Unit* enemy) { return !player->IsValidAttackTarget(enemy); });
        if (info->MaxAffectedTargets && targets.size() > info->MaxAffectedTargets)
            targets.resize(info->MaxAffectedTargets);
        explosionTargets = uint32(targets.size());
        for (Unit* enemy : targets)
        {
            Cast(me,enemy,id);
            if (id == 802477)
                Cast(me,enemy,802779);
        }
        if (id == 500601)
            player->CastSpell(me->GetPositionX(),me->GetPositionY(),me->GetPositionZ(),500753,true);
        me->DespawnOrUnsummon(100ms);
    }
    void DropFirepot(Player* player)
    {
        auto* info = sSpellMgr->GetSpellInfo(500601);
        auto targets = Nearby(me,Radius(500601));
        targets.remove_if([player](Unit* enemy) { return !player->IsValidAttackTarget(enemy); });
        if (info->MaxAffectedTargets && targets.size() > info->MaxAffectedTargets)
            targets.resize(info->MaxAffectedTargets);
        for (Unit* enemy : targets)
            Cast(me,enemy,500601);
        player->CastSpell(me->GetPositionX(),me->GetPositionY(),me->GetPositionZ(),500753,true);
    }
    void DoAction(int32 action) override
    {
        if (action == 1)
            Explode();
    }
    void JustDied(Unit*) override
    {
        if (me->GetEntry() == 50045)
            Explode();
        Cleanup();
    }
    void Cleanup()
    {
        if (Player* player = ObjectAccessor::FindPlayer(owner))
        {
            player->m_Controlled.erase(me);
            State(player).summons.erase(me->GetGUID());
            if (Turret(me->GetEntry()))
            {
                auto devices = Devices(player);
                if (std::none_of(devices.begin(), devices.end(), [](Creature* device) { return Turret(device->GetEntry()); }))
                {
                    player->RemoveAurasDueToSpell(807293, player->GetGUID());
                    player->SetTemporarySpellReplacement(500239, 0);
                    player->removeSpell(500470, SPEC_MASK_ALL, true);
                }
            }
        }
    }
    void OnDespawn() override { Cleanup(); }
    ~npc_ascension_tinker_device() override { Cleanup(); }
    Unit* TurretTarget(Player* player)
    {
        SpellInfo const* shot = sSpellMgr->GetSpellInfo(706689);
        if (!shot)
            return nullptr;
        float range = shot->GetMaxRange(false,me);
        auto valid = [this,player,range](Unit* target)
        {
            return target && target->IsAlive() && player->IsValidAttackTarget(target) &&
                me->IsWithinDistInMap(target,range) && me->CanSeeOrDetect(target) && me->IsWithinLOSInMap(target);
        };
        if (Unit* target = ObjectAccessor::GetUnit(*me,State(player).focus); valid(target))
            return target;
        return nullptr;
    }
    void UpdateTurret(Player* player)
    {
        if (!Turret(me->GetEntry()) || me->HasUnitState(UNIT_STATE_CONTROLLED | UNIT_STATE_CASTING) ||
            me->HasAuraType(SPELL_AURA_MOD_PACIFY) || me->HasAuraType(SPELL_AURA_MOD_PACIFY_SILENCE) ||
            !me->isAttackReady(RANGED_ATTACK))
            return;
        if (Unit* target = TurretTarget(player))
        {
            me->SetFacingToObject(target);
            if (me->HasAura(706692))
                me->CastSpell(target->GetPositionX(),target->GetPositionY(),target->GetPositionZ(),706694,true);
            else
                Cast(me,target,706689);
            me->resetAttackTimer(RANGED_ATTACK);
        }
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::FindPlayer(owner);
        if (!player || !player->IsAlive() || !player->IsInMap(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        UpdateTurret(player);
        events.Update(diff);
        while (uint32 event = events.ExecuteEvent())
        {
            Unit* target = ObjectAccessor::GetUnit(*me,focus);
            if (!target || !target->IsAlive() || !player->IsValidAttackTarget(target))
                target = player->GetVictim();
            uint32 entry = me->GetEntry();
            if (event == 1)
            {
                travelled += previous.GetExactDist(me);
                previous.Relocate(*me);
                if (entry == 226312)
                {
                    me->SetSpeed(MOVE_RUN,1 + std::min(40.0f,travelled)/20.0f);
                    for (Unit* enemy : Nearby(me,2))
                        if (player->IsValidAttackTarget(enemy))
                        {
                            Explode();
                            break;
                        }
                }
                if (Bomb() && target)
                {
                    if (me->IsWithinDistInMap(target,2))
                        Explode();
                    else
                        Pursue(target);
                }
                events.ScheduleEvent(1,200ms);
            }
            if (event == 2)
            {
                Scale(player,me,false);
                uint32 next = 1000;
                if (entry == 500711 && target)
                {
                    AttackStart(target);
                    DoMeleeAttackIfReady();
                }
                if (entry == 50037 || entry == 500362 || Beacon(entry))
                    for (Unit* ally : Allies(player,me,entry == 500362 ? Radius(560746) : entry == 500361 ? Radius(560755) : Radius(706829)))
                    {
                        if (entry == 50037 || entry == 500362)
                            Cast(me,ally,entry == 50037 ? 706829 : 560746);
                        else if (entry == 500360)
                        {
                            Mana(ally,CalculatePct(ally->GetCreateMana(),Amount(560819)),player);
                            for (Powers power : {POWER_RAGE,POWER_ENERGY,POWER_FOCUS,POWER_RUNIC_POWER})
                                if (ally->GetMaxPower(power))
                                    player->EnergizeBySpell(ally,560751,power == POWER_RAGE || power == POWER_RUNIC_POWER ?
                                        Amount(560751) : Amount(560751)/10,power);
                            next = 2500;
                        }
                        else if (entry == 500361)
                        {
                            uint32 limit = player->HasAura(705811) ? 2 : 1;
                            uint64 mechanics = (1ull << MECHANIC_FEAR) | (1ull << MECHANIC_CHARM) | (1ull << MECHANIC_SLEEP);
                            if (used.size() < limit && ally->HasAuraWithMechanic(mechanics))
                            {
                                ally->RemoveAurasWithMechanic((1u << MECHANIC_FEAR) | (1u << MECHANIC_CHARM) |
                                    (1u << MECHANIC_SLEEP),AURA_REMOVE_BY_DEFAULT);
                                used.insert(ally->GetGUID());
                            }
                        }
                        else
                        {
                            uint32 helper = entry == 50036 ? 801256 : entry == 51036 ? 803804 : entry == 53036 ?
                                803805 : entry == 54036 ? 803806 : entry == 55036 ? 803807 : 803808;
                            Cast(me,ally,helper);
                            if (Aura* aura = ally->GetAura(helper,me->GetGUID()))
                                aura->SetDuration(2000);
                        }
                    }
                if (entry == 50037)
                    next = 3000;
                if (entry == 500362)
                    next = 1500;
                if (entry == 500361)
                    used.clear();
                if (me->GetVehicleKit())
                    for (Creature* device : Devices(player))
                        if (me->IsWithinDistInMap(device,40))
                        {
                            Cast(player,device,524935);
                            if (Aura* field = device->GetAura(524935,player->GetGUID()))
                                field->SetDuration(2000);
                        }
                if (entry == 500366 || entry == 52036)
                {
                    for (Unit* enemy : Nearby(me,6))
                        if (player->IsValidAttackTarget(enemy))
                            Cast(me,enemy,entry == 500366 ? 712680 : 561269);
                    next = 5000;
                }
                if (entry == 226112 && !exploded && travelled - travelledAtLastFirepot >= 3)
                {
                    travelledAtLastFirepot = travelled;
                    DropFirepot(player);
                }
                if (entry == 506051)
                    for (Unit* ally : Allies(player,me,Radius(570717)))
                        if (!ally->HasAura(570716) && !ally->HasAura(560774))
                            Cast(player,ally,560774);
                events.ScheduleEvent(2,Milliseconds(next));
            }
        }
    }
    void sGossipHello(Player* player) override
    {
        Player* creator = ObjectAccessor::FindPlayer(owner);
        if (!creator || !player->IsAlive() || !player->IsWithinDistInMap(me,5) ||
            (player != creator && !creator->IsInRaidWith(player)))
            return;
        if (me->GetVehicleKit())
            player->EnterVehicle(me);
        else if (me->GetEntry() == 506051 && used.insert(player->GetGUID()).second)
        {
            player->ModifyHealth(player->CountPctFromMaxHealth(Amount(570715)));
            Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA),Amount(570715)),creator);
            for (Powers power : {POWER_RAGE,POWER_ENERGY,POWER_FOCUS,POWER_RUNIC_POWER})
                if (player->GetMaxPower(power))
                    creator->EnergizeBySpell(player,570715,CalculatePct(player->GetMaxPower(power),Amount(570715,1)),power);
            player->RemoveAurasDueToSpell(560774);
            Cast(player,player,570716);
        }
    }
};
class go_ascension_tinker_battery : public GameObjectScript
{
public:
    go_ascension_tinker_battery() : GameObjectScript("go_ascension_tinker_battery") { }
    bool OnGossipHello(Player* player, GameObject* object) override
    {
        if (Player* creator = Owner(object->GetOwner()))
            for (Creature* station : Devices(creator))
                if (station->GetEntry() == 506051 && object->IsWithinDistInMap(station,1))
                {
                    station->AI()->sGossipHello(player);
                    break;
                }
        return true;
    }
};
}
void AddSC_AscensionTinkerSummons()
{
    new go_ascension_tinker_battery();
    RegisterCreatureAI(npc_ascension_tinker_pet);
    RegisterCreatureAI(npc_ascension_tinker_device);
}
