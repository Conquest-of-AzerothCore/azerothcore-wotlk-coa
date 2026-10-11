/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "AscensionTinkerData.h"
#include "Creature.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionTinker;
bool Select(uint32 id, SpellInfo const* info)
{
    switch (id)
    {
        case 707250: case 707261: case 653273:
            return Named(info,500549) || (info && info->Id == 500213);
        case 707272: return Named(info,801005);
        case 537247: return Named(info,500235);
        case 503553: return Any(info,{801707,802684});
        case 680998: return info && info->Id == 500213;
        case 681245: return info && info->Id == 504594;
        default: return false;
    }
}
bool TrainingDummy(Unit const* unit)
{
    Creature const* creature = unit->ToCreature();
    return creature && creature->GetScriptName() == "npc_training_dummy";
}
void Snapshot(Player* player, Spell* spell)
{
    if (spell->IsTriggered())
        return;
    for (uint32 id : TinkerFinite)
        if (Select(id,spell->GetSpellInfo()))
            if (Aura* aura = player->GetAura(id))
            {
                if (!aura->GetScriptValue(Scrap))
                    aura->SetScriptValue(Scrap,++State(player).sequence);
                spell->SetScriptValue(id,aura->GetScriptValue(Scrap));
            }
}
void Finish(Player* player, Spell* spell)
{
    for (uint32 id : TinkerFinite)
        if (uint64 generation = spell->GetScriptValue(id))
        {
            if (spell->GetSpellInfo()->Id == 500213)
                if (Aura* channel = player->GetAura(500213,player->GetGUID()))
                {
                    channel->SetScriptValue(id,generation);
                    continue;
                }
            Spend(player,id,generation);
        }
}
void Counter(Player* player, uint32 stack, uint32 buff)
{
    Cast(player,player,stack);
    if (Count(player,stack) >= 4)
    {
        player->RemoveAurasDueToSpell(stack);
        Grant(player,buff);
    }
}
class tinker_spells : public AllSpellScript
{
public:
    tinker_spells() : AllSpellScript("tinker_spells",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST,ALLSPELLHOOK_ON_BEFORE_EFFECTS,ALLSPELLHOOK_ON_CAST,
         ALLSPELLHOOK_ON_CRIT_CHANCE,ALLSPELLHOOK_ON_HIT_RESULT}) { }
    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || player != spell->GetCaster() || info->SpellFamilyName != 34 || spell->IsTriggered())
            return;
        if ((info->Id == GatlingGun || Any(info,{801387,801389,805372})) && !player->HasAura(Mechsuit))
            result = SPELL_FAILED_ONLY_MOUNTED;
        else if (Named(info,500549) && player->HasAura(Mechsuit))
            result = SPELL_FAILED_NOT_MOUNTED;
        if (result != SPELL_CAST_OK)
            return;
        if (info->Id == Mechsuit && !Count(player,Scrap))
            result = SPELL_FAILED_NO_POWER;
        if (info->Id == 504594 && !player->HasAura(681245))
            result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (player == caster && player && info->SpellFamilyName == 34)
        {
            Snapshot(player,spell);
            if (!spell->IsTriggered())
                for (uint32 module : TinkerModules)
                    if (info->Id == module)
                        ActivateModule(player,info->Id);
        }
    }
    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 34)
            return;
        if ((Named(info,805351) && target->GetCreatureType() == CREATURE_TYPE_MECHANICAL) || info->Id == 801745 ||
            (info->Id == 500220 && player->HasAura(707244) && target->GetAuraOfRankedSpell(500232,player->GetGUID())) ||
            (Named(info,680196) && player->HasAura(560791) && Nanobots(player,target)))
            chance = 100;
    }
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || player != caster || info->SpellFamilyName != 34 || spell->IsTriggered())
            return;
        uint32 id = info->Id;
        Unit* target = spell->m_targets.GetUnitTarget();
        if (id == Mechsuit && player->HasAura(Mechsuit))
        {
            if (player->HasAura(807635))
            {
                Cast(player,player,504811);
                if (AuraEffect* regeneration = player->GetAuraEffect(807635,EFFECT_0))
                    regeneration->ResetPeriodic(true);
            }
            if (player->HasAura(503569))
                Cast(player,player,504749);
        }
        Finish(player,spell);
        bool shot = Named(info,500549);
        bool sticky = Named(info,500232);
        bool rocket = Named(info,500235);
        bool bomb = Named(info,801005);
        if (player->HasAura(92141) && (shot || sticky))
            Resource(player,Scrap,shot ? 3 : 10);
        if (NotifySpellAttack(player,info,target))
            for (Creature* device : Devices(player))
                device->AI()->SetGUID(target->GetGUID(),1);
        if (shot)
        {
            if (player->HasAura(707249))
                Counter(player,707251,707250);
            if (player->HasAura(572545) && player->HasAura(653232))
                Counter(player,653282,653273);
            if (player->HasAura(707277))
                for (Creature* device : Devices(player))
                    if (Permanent(device->GetEntry()) || Turret(device->GetEntry()))
                        Cast(player,device,707278);
        }
        if ((shot || Named(info,805351)) && player->HasAura(705786))
            PetCast(player,nullptr,705787);
        if (MechAbility(info) && player->HasAura(707395))
            PetCast(player,nullptr,805519);
        if ((shot || MechAbility(info)) && player->HasAura(520022))
            for (Creature* device : Devices(player))
                if (Turret(device->GetEntry()))
                {
                    Cast(player,device,578323);
                    if (Count(device,578323) >= sSpellMgr->GetSpellInfo(578323)->StackAmount)
                    {
                        device->RemoveAurasDueToSpell(578323);
                        Cast(device,target,578335);
                    }
                }
        if (sticky)
        {
            if (player->HasAura(707260))
                Grant(player,707261,2);
            if (player->HasAura(807388) && player->HasAura(Mechsuit))
                Grant(player,680998);
            if (player->HasAura(706695))
                PetCast(player,nullptr,706698,true);
        }
        if (id == 500535 && player->HasAura(707271))
        {
            Reduce(player,801005,INT32_MAX);
            Grant(player,707272);
        }
        if (bomb && spell->GetScriptValue(707272))
        {
            Reduce(player,801005,INT32_MAX);
            if (player->HasAura(707273))
                Reduce(player,500232,std::abs(Amount(707274)));
        }
        if (bomb && player->HasAura(707237))
            PetCast(player,target,707238,true);
        if (rocket && player->HasAura(707259))
            PetCast(player,target,Highest(player,500235),true);
        if (bomb || rocket)
            for (Creature* device : Devices(player))
                if (device->GetEntry() == 467073)
                {
                    for (uint8 n = 0; n < 3; ++n)
                    {
                        Position position = device->GetPosition();
                        device->MovePositionToFirstCollision(position,1.5f,n * 2 * float(M_PI) / 3);
                        Summon(player,target,500535,&position);
                    }
                    break;
                }
        if (id == 802052 && player->HasAura(300636))
            Summon(player,target,802477);
        if (Any(info,{801707,802684}) && Chance(player,705803))
            player->RestoreSpellChargeCategory(13,1);
        if (Any(info,{504527,504594}) && player->HasAura(807500))
            for (uint32 root : {801387,801389,805372})
                Reduce(player,root,INT32_MAX);
        if (id == 504594)
            for (Creature* device : Devices(player))
                Cast(player,device,505161);
        if (Build(info))
        {
            Reduce(player,500236,std::abs(Amount(807225)));
            if (info->SpellFamilyFlags & flag96(0,512,0))
                if (player->HasAura(560782))
                    Reduce(player,560744,std::abs(Amount(560783)));
        }
        if ((id == 800349 || id == 806757) && player->HasAura(806758))
            Summon(player,target,806760);
        if (id == 500249)
        {
            ObjectGuid ownerGuid = player->GetGUID();
            ObjectGuid targetGuid = target ? target->GetGUID() : State(player).focus;
            State(player).scheduler.Schedule(3000ms,[ownerGuid,targetGuid](TaskContext)
            {
                if (Player* owner = ObjectAccessor::FindPlayer(ownerGuid))
                    if (Unit* enemy = ObjectAccessor::GetUnit(*owner,targetGuid))
                        PetCast(owner,enemy,500579,true);
            });
        }
        Refresh(player);
    }
    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32 healing, bool critical) override
    {
        Player* player = Owner(spell->GetCaster());
        auto* info = spell->GetSpellInfo();
        if (!player || !target || info->SpellFamilyName != 34 || miss != SPELL_MISS_NONE)
            return;
        if (target->IsPlayer())
            target->RemoveAurasDueToSpell(560711);
        if ((damage || TrainingDummy(target)) && Named(info,801005) && player->HasAura(805314))
            if (Aura* tracer = target->GetAura(653247,player->GetGUID()); tracer && tracer->GetStackAmount() >= 10)
                Cast(player,target,803438);
        if (Nanobots(player,target) && player->HasAura(560734) &&
            Any(info,{801809,801709,502537,801808,803552}))
            Cast(player,target,560736);
        if (healing && Named(info,680196))
        {
            if (critical && player->HasAura(805306))
                for (Unit* ally : Allies(player,target,Radius(706255),sSpellMgr->GetSpellInfo(706255)->MaxAffectedTargets))
                    Copy(player,ally,706255,CalculatePct(healing,15));
            if (player->HasAura(560787))
                for (Creature* device : Devices(player))
                    for (Unit* ally : Allies(player,device,Radius(681513),1))
                        Cast(device,ally,681513);
        }
        if (healing && Named(info,801707) && player->HasAura(524834))
            if (Creature* device = target->ToCreature(); device && Owned(player,device))
                Overcharge(player,device);
        bool brilliance = spell->GetScriptValue(653273) != 0;
        if (info->Id == 500577)
            if (Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
                channel && channel->GetSpellInfo()->Id == 500213 && channel->GetScriptValue(653273) &&
                !channel->GetScriptValue(653244) && damage)
            {
                channel->SetScriptValue(653244,1);
                brilliance = true;
            }
        if (damage && brilliance)
            player->CastCustomSpell(653244,SPELLVALUE_BASE_POINT0,
                Amount(653244,0,player) + int32(player->GetTotalAttackPowerValue(RANGED_ATTACK) * .1f),target,true);
    }
};
class spell_ascension_tinker_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_tinker_ability);
    bool handled = false;
    void Effect(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        uint32 id = GetSpellInfo()->Id;
        auto type = GetSpellInfo()->Effects[index].Effect;
        if (id == 500470)
        {
            PreventHitDefaultEffect(index);
            if (handled)
                return;
            handled = true;
            for (Creature* device : Devices(player))
                if (Turret(device->GetEntry()))
                    device->DespawnOrUnsummon();
            return;
        }
        if (id == 801744)
        {
            PreventHitDefaultEffect(index);
            if (handled)
                return;
            handled = true;
            Position position = GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetPosition();
            ObjectGuid owner = player->GetGUID();
            uint32 map = player->GetMapId(), phase = player->GetPhaseMask();
            State(player).scheduler.Schedule(Milliseconds(GetSpellInfo()->GetDuration()),
                [owner,position,map,phase](TaskContext)
            {
                Player* caster = ObjectAccessor::FindPlayer(owner);
                if (!caster || !caster->IsAlive() || caster->GetMapId() != map || caster->GetPhaseMask() != phase)
                    return;
                auto targets = Nearby(caster,caster->GetExactDist(&position) + Radius(801744));
                targets.remove_if([caster,position](Unit* enemy)
                {
                    return !caster->IsValidAttackTarget(enemy) || enemy->GetExactDist(&position) > Radius(801744);
                });
                uint32 limit = sSpellMgr->GetSpellInfo(801744)->MaxAffectedTargets;
                if (limit && targets.size() > limit)
                    targets.resize(limit);
                for (Unit* enemy : targets)
                    Cast(caster,enemy,801745);
                if (caster->HasAura(806762))
                    caster->CastSpell(position.GetPositionX(),position.GetPositionY(),position.GetPositionZ(),806763,true);
            });
        }
        bool summon = type == SPELL_EFFECT_SUMMON || type == SPELL_EFFECT_SUMMON_OBJECT_WILD || type == SPELL_EFFECT_TRANS_DOOR ||
            id == 500535 || id == 500600;
        if (summon)
        {
            PreventHitDefaultEffect(index);
            if (!handled)
            {
                handled = true;
                Position position = GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetPosition();
                Summon(player,GetExplTargetUnit(),id,&position);
            }
        }
        if (Any(GetSpellInfo(),{805372}) && type == SPELL_EFFECT_SCRIPT_EFFECT)
        {
            PreventHitDefaultEffect(index);
            if (GetHitUnit())
                PetCast(player,GetHitUnit(),805459);
        }
        if (id == 524835 || id == 800349 || id == 801798)
        {
            PreventHitDefaultEffect(index);
            if (handled)
                return;
            handled = true;
            if (id == 801798)
                Detonate(player);
            else
                for (Creature* device : Devices(player))
                    if (id == 524835)
                        Overcharge(player,device);
                    else if (Turret(device->GetEntry()) && player->IsWithinDistInMap(device,40))
                        Cast(player,device,706692);
        }
        if ((id == 802176 || id == 802236) && GetCaster()->IsCreature())
            if (Creature* device = GetCaster()->ToCreature(); Owned(player,device) && device->GetEntry() == 50300)
                device->DespawnOrUnsummon(100ms);
    }
    void Hit()
    {
        Player* player = Owner(GetCaster());
        Unit* target = GetHitUnit();
        if (!player || !target)
            return;
        uint32 id = GetSpellInfo()->Id;
        if ((Named(GetSpellInfo(),801009) || id == 801982 || id == 802477) && player->HasAura(707262))
        {
            uint32 enemies = 0;
            for (auto const& hit : *GetSpell()->GetUniqueTargetInfo())
                if (hit.effectMask & 1)
                    ++enemies;
            if (Creature* device = GetCaster()->ToCreature(); device && Owned(player,device))
                enemies = device->AI()->GetData(2);
            if (enemies == 1)
                SetHitDamage(GetHitDamage() + CalculatePct(GetHitDamage(),Amount(707262)));
        }
        if (id == 806074)
            if (Creature* device = GetCaster()->ToCreature(); device && Owned(player,device))
                SetHitDamage(int32(int64(GetHitDamage()) * device->AI()->GetData(3) / 1000));
        if (Named(GetSpellInfo(),801009) && player->HasAura(803074) && !handled)
        {
            handled = true;
            Position position = target->GetPosition();
            Summon(player,target,850020,&position);
        }
    }
    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_tinker_ability::Effect,EFFECT_ALL,SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_tinker_ability::Effect,EFFECT_ALL,SPELL_EFFECT_ANY);
        OnHit += SpellHitFn(spell_ascension_tinker_ability::Hit);
    }
};
}
void AddSC_AscensionTinkerAbilities()
{
    new tinker_spells();
    RegisterSpellScript(spell_ascension_tinker_ability);
}
