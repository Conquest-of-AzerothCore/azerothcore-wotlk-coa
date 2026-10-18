/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTinker.h"
#include "Creature.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace AscensionTinker
{
void PetCast(Player* player, Unit* target, uint32 spell, bool turret)
{
    for (Creature* device : Devices(player))
        if (turret ? Turret(device->GetEntry()) : Permanent(device->GetEntry()))
        {
            if (target && Turret(device->GetEntry()))
                device->SetFacingToObject(target);
            Cast(device,target ? target : device,spell);
        }
}
void DeviceEvent(Player* player, Creature* device, Unit* target, SpellInfo const* info,
                 uint32 damage, uint32 healing, bool critical, bool periodic)
{
    if (!Owned(player,device) || (!damage && !healing) || Derived(info))
        return;
    if (player->HasAura(705817) && !State(player).timers.HasTimeUntilEvent(560786))
    {
        State(player).timers.ScheduleEvent(560786,1000ms);
        Copy(player,player,560786,CalculatePct(damage + healing,Amount(705817)));
    }
    if (damage && device->GetEntry() == 500481 && player->HasAura(92140))
        for (Unit* ally : Allies(player,device,Radius(520375),1))
            Copy(player,ally,561267,damage);
    if (!damage)
        return;
    if (player->HasAura(Mechsuit) && Chance(player,807499))
    {
        Cast(player,player,707579);
        Cast(player,player,520276);
    }
    if (Chance(player,503534) && player->IsAlive())
        device->CastSpell(player,503549,true,nullptr,nullptr,player->GetGUID());
    if (critical && player->HasAura(705831))
    {
        Cast(player,player,503535);
        PetCast(player,nullptr,504822);
    }
    if (critical && !periodic && info && player->HasAura(706379))
        Cast(player,player,500244);
    if (Turret(device->GetEntry()))
    {
        if (player->HasAura(707265))
            Cast(device,target,707266);
        if (player->HasAura(524979) && roll_chance_i(sSpellMgr->GetSpellInfo(801811)->ProcChance))
        {
            Cast(device,target,706700);
            Cast(player,device,573269);
        }
        if (device->HasAura(706698))
        {
            device->RemoveAurasDueToSpell(706698);
            Cast(device,target,706696);
        }
    }
    if (!periodic && info && Permanent(device->GetEntry()) && target->HasAura(524904,player->GetGUID()))
    {
        target->RemoveAurasDueToSpell(524904,player->GetGUID());
        Cast(device,target,524903);
    }
    if (!info && device->HasAura(805519))
        Cast(device,target,805657);
    if ((device->GetEntry() == 500711 || device->HasAura(806757)) &&
        (!info || info->Id != 806781) && roll_chance_i(sSpellMgr->GetSpellInfo(806780)->ProcChance))
        Cast(device,target,806781);
}
}
namespace
{
using namespace AscensionTinker;
class aura_ascension_tinker_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_event);
    bool Check(ProcEventInfo& event)
    {
        Player* player = Owner(GetTarget());
        if (!player || !event.GetActor() || !event.GetActionTarget() || State(player).event)
            return false;
        auto* info = event.GetSpellInfo();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        bool periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        if (GetId() == 707698)
            return GetTarget() != player && event.GetActor() == GetTarget() && Owned(player,GetTarget()) &&
                (damage || healing) && !Derived(info);
        if (GetTarget() != player)
            return false;
        if (event.GetActionTarget() == player && damage)
        {
            if (GetId() == 572367)
                return !periodic && event.GetDamageInfo() &&
                    (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC) && Chance(player,572367);
            if (GetId() == 705810)
                return player->IsAlive() && player->HealthBelowPct(35) &&
                    uint64(player->GetHealth()) + damage >= CalculatePct(player->GetMaxHealth(),35) &&
                    Chance(player,705810,180000);
        }
        if (event.GetActor() != player || Derived(info))
            return false;
        Unit* target = event.GetActionTarget();
        bool fire = info && (info->SchoolMask & SPELL_SCHOOL_MASK_FIRE);
        switch (GetId())
        {
            case 92138: return damage && !periodic && fire && player->IsValidAttackTarget(target);
            case 707239: return damage && Any(info,{653238,653247}) && Chance(player,707239);
            case 704107: return damage && Named(info,805351);
            case 705846: return healing && periodic && Named(info,801809);
            case 806629: return damage && !periodic &&
                ((!info && (event.GetTypeMask() & PROC_FLAG_DONE_RANGED_AUTO_ATTACK)) ||
                 (info && info->DmgClass == SPELL_DAMAGE_CLASS_RANGED)) && Chance(player,806629);
            case 300877: return event.GetHealInfo() && ((!critical) || healing);
            case 705820: return damage && fire && critical;
            case 806758: return damage && !periodic && info && info->DmgClass == SPELL_DAMAGE_CLASS_RANGED &&
                Chance(player,806758);
            case 560785: return healing && Chance(player,560785);
            case 705815: return damage && fire;
            case 680975: return damage && Shot(info) && Chance(player,680975);
            case 573247: return damage && info && !periodic && critical && target->HasAura(653247,player->GetGUID());
            case 806627: return (damage || healing) && critical && Chance(player,806627,10000);
            case 503552: return healing && !periodic && critical;
            case 681001: return damage && info && info->Id == 504521 && player->HasAura(Mechsuit);
            case 706680: return damage && (Named(info,805372) || (info && info->Id == 801388));
            case 704449: return damage && Any(info,{504527,505160});
            case 504523: return damage && player->HasAura(Mechsuit) && (Shot(info) || Any(info,{504527,505160}));
            case 705817: return (damage || healing) && !periodic && !State(player).timers.HasTimeUntilEvent(561267);
            case 706379: return damage && info && !periodic && critical;
            case 504749: return damage && player->HasAura(Mechsuit);
            default: return false;
        }
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = Owner(GetTarget());
        if (!player)
            return;
        Unit* target = event.GetActionTarget();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        bool old = State(player).event;
        State(player).event = true;
        switch (GetId())
        {
            case 707698:
                DeviceEvent(player,GetTarget()->ToCreature(),target,event.GetSpellInfo(),damage,healing,
                    event.GetHitMask() & PROC_HIT_CRITICAL,
                    event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC));
                break;
            case 92138:
            {
                uint32 before = 0;
                if (Aura* aura = target->GetAura(Napalm,player->GetGUID()))
                    before = aura->GetStackAmount();
                Cast(player,target,Napalm);
                if (Aura* aura = target->GetAura(Napalm,player->GetGUID()); aura && before < 5 &&
                    aura->GetStackAmount() >= 5 && player->HasAura(707240))
                    player->RestoreSpellCharge(500600);
                break;
            }
            case 707239: Cast(player,target,Napalm); break;
            case 704107: Cast(player,target,653254); break;
            case 705846:
                for (Unit* ally : Allies(player,target,Radius(705847),sSpellMgr->GetSpellInfo(705847)->MaxAffectedTargets))
                    Cast(player,ally,705847);
                break;
            case 806629: player->RestoreSpellCharge(504527); break;
            case 300877:
                if (event.GetHitMask() & PROC_HIT_CRITICAL)
                    player->RemoveAurasDueToSpell(560788);
                else
                    Cast(player,player,560788);
                break;
            case 705810: Cast(player,player,570189); break;
            case 705820: Reduce(player,801827,std::abs(Amount(705821))); break;
            case 806758: Summon(player,target,806760); break;
            case 572367:
                for (Unit* ally : Allies(player,player,Radius(572369)))
                    Cast(player,ally,572369);
                break;
            case 560785: PetCast(player,nullptr,808008); break;
            case 705815: Grant(player,537247); break;
            case 680975: player->RestoreSpellCharge(504527); Grant(player,681245); Refresh(player); break;
            case 573247: Cast(player,target,653247); break;
            case 806627: Cast(player,player,806628); break;
            case 503552: Grant(player,503553); break;
            case 681001: Cast(player,player,681306); break;
            case 706680: Cast(player,target,500612); break;
            case 704449: Cast(player,target,524904); break;
            case 504523: Cast(player,target,504521); break;
            case 705817:
                State(player).timers.ScheduleEvent(561267,1000ms);
                for (Creature* pet : Devices(player))
                    if (Permanent(pet->GetEntry()))
                    {
                        uint32 value = CalculatePct(damage + healing,Amount(707698));
                        Copy(player,pet,561267,value);
                        Mana(pet,value,player);
                    }
                break;
            case 706379: Cast(player,player,500244); break;
            case 504749: Resource(player,Scrap,3); break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_event::Check);
        OnProc += AuraProcFn(aura_ascension_tinker_event::Proc);
    }
};
}
void AddSC_AscensionTinkerEvents()
{
    RegisterSpellScript(aura_ascension_tinker_event);
}
