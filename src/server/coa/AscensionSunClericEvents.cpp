/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "AscensionSunClericData.h"
#include "ObjectAccessor.h"
#include "GameTime.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
namespace
{
using namespace AscensionSunCleric;
bool Vow(uint32 id)
{
    return std::find(std::begin(SunClericVows), std::end(SunClericVows), id) != std::end(SunClericVows);
}
class aura_ascension_sun_cleric_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_sun_cleric_event);
    Player* Caster()
    {
        switch (GetId())
        {
            case 680646: case 806123: case 680911: case 301005: case 680888: case 680624: case 505342:
                return Owner(GetCaster());
            default: return Owner(GetTarget());
        }
    }
    bool Check(ProcEventInfo& event)
    {
        Player* player = Caster();
        if (!player || !event.GetActor() || !event.GetActionTarget() || State(player).event)
            return false;
        uint32 id = GetId();
        auto* info = event.GetSpellInfo();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        bool periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        bool automatic = event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK);
        bool direct = info && !periodic && !automatic;
        bool melee = automatic || (info && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE);
        bool avoided = event.GetHitMask() & (PROC_HIT_MISS | PROC_HIT_DODGE | PROC_HIT_PARRY);
        bool block = event.GetHitMask() & (PROC_HIT_BLOCK | PROC_HIT_FULL_BLOCK);
        bool received = event.GetActionTarget() == GetTarget();
        bool own = event.GetActor() == player;
        if (id == 301005)
            return received && damage && !periodic;
        if (id == 680646)
            return received && damage && GetTarget()->GetHealthPct() < 35 && !GetAura()->GetScriptValue(id);
        if (id == 680911)
            return event.GetActor() == GetTarget() && damage && direct &&
                (GetTarget()->GetHealthPct() < 35 || GetAura()->GetScriptValue(id));
        if (id == 806123)
            return event.GetActor() == GetTarget() && damage && direct && !Derived(info) &&
                GetAura()->GetScriptValue(id) <= uint64(GameTime::GetGameTimeMS().count());
        if (id == 680888)
            return received && (event.GetHitMask() & (PROC_HIT_DEFLECT | PROC_HIT_REFLECT));
        if (id == 505342)
            return event.GetActor() == GetTarget() && (automatic || melee) && !periodic;
        if (id == 680624)
            return own && received && damage && !Derived(info);
        if (received)
        {
            if (id == 807547)
                return !periodic && (damage || healing) && !Derived(info);
            if (id == 560095)
                return block;
            if (id == 92137 || id == 680663)
                return avoided && Chance(player, id);
            if (id == 560492)
                return avoided && Chance(player, id, 1000);
            if (id == 300355)
                return melee && critical && damage;
            if (id == 704941)
                return event.GetHitMask() & PROC_HIT_PARRY;
            if (id == 707629)
                return block && Chance(player, id);
        }
        if (!own || (Derived(info) && !(info->Id == 807994 && healing)))
            return false;
        switch (id)
        {
            case 803489: case 803491: case 803719: case 807435: return direct && (damage || healing);
            case 807749: return (automatic && damage) || (direct && melee && damage);
            case 300369: case 804629: return damage && info && info->Id == 807058 && Chance(player, id);
            case 301239: case 560861: case 806024: return damage && info && info->Id == 807058;
            case 300943: case 704928: case 561327: return (damage || healing) && critical;
            case 300336: return healing && Any(info, {800357,500143});
            case 572885: return damage && info && info->Id == 804252;
            case 806116: return damage && info && !periodic;
            case 704563: return healing && direct;
            case 707077: return direct && event.GetHealInfo() && event.GetHealInfo()->GetHeal();
            case 681252: return damage && direct && info->SchoolMask == SPELL_SCHOOL_MASK_NORMAL;
            case 704934: return damage && melee;
            case 806699: case 802935: return damage && automatic && Chance(player, id);
            case 680641: return damage && critical && (Gavel(info) || Named(info,800654));
            case 807343: case 804632: case 547214: return damage && Named(info,500154);
            case 582832: return damage && melee && critical;
            case 805647: return damage && info && info->Id == 800691 && Chance(player,id);
            case 300349: return healing && critical && Chance(player,id,1000);
            case 806058: return damage && info && info->SpellFamilyFlags[2] == 134217728 && Chance(player,id);
            case 301266: return damage && ((Named(info,500154) && player->HasAura(Sunrise)) ||
                (Named(info,806477) && player->HasAura(Sunset)));
            case 680643: return damage && automatic && State(player).firstAttacks.insert(event.GetActionTarget()->GetGUID()).second;
            case 300371: return direct && damage && event.GetActionTarget()->HasAura(806697, player->GetGUID()) && Chance(player,id,1000);
            case 704920: return healing && direct && Any(info,{500141,500143});
            case 534267: return healing && (Any(info,{500143,800357,500147}) || (info && info->Id == 807994));
            case 704903: return damage && info && info->Id == 806980;
            case 704936: return healing && Named(info,500143);
            case 800612: return damage && automatic;
            case 300339: return healing && critical;
            default: return false;
        }
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = Caster();
        if (!player)
            return;
        uint32 id = GetId();
        auto* info = event.GetSpellInfo();
        Spell* spell = Origin(player,const_cast<Spell*>(event.GetProcSpell()));
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        Unit* target = event.GetActionTarget();
        bool old = State(player).event;
        bool oldDawn = State(player).dawnEvent;
        State(player).event = true;
        bool ownSpell = spell && spell->GetCaster() == player;
        State(player).dawnEvent = ownSpell && spell->GetScriptValue(DawnCast);
        bool fulfillment = ownSpell && spell->GetScriptValue(Dawn);
        if (Vow(id))
        {
            bool automatic = event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK;
            bool compatible = id != 807749 || !automatic;
            if (fulfillment && compatible)
                Fulfill(player, spell, target);
            if (!State(player).dawnEvent)
            {
                int32 gain = (id == 803489) ? 2 : (id == 803719 || (id == 807749 && !automatic)) ? 0 : 1;
                if (gain)
                    Resource(player, SolarPower, gain);
            }
            uint32 amount = damage ? damage : healing;
            if (id == 803489)
                Copy(player, target, damage ? 803490 : 803816, CalculatePct(amount, Amount(id,1) * (fulfillment ? 2 : 1)));
            if (id == 803491)
            {
                auto nearby = damage ? Nearby(target, 10) : Allies(player, target, 10);
                nearby.remove(target);
                nearby.remove_if([player,damage](Unit* unit) { return damage && !player->IsValidAttackTarget(unit); });
                uint32 count = uint32(Amount(803492)) * (fulfillment ? 2 : 1);
                for (Unit* unit : nearby)
                {
                    if (!count--)
                        break;
                    amount = CalculatePct(amount, 90);
                    Copy(player, unit, damage ? 803493 : 803816, amount);
                }
            }
            if (id == 803719)
            {
                uint32 mana = CalculatePct(player->GetMaxPower(POWER_MANA) - player->GetPower(POWER_MANA), Amount(504775)) +
                    std::max(0, Amount(504877,0,player));
                if (player->HasAura(547214))
                    AddPct(mana, Amount(547214));
                Mana(player, mana);
            }
            if (id == 807435)
            {
                Unit* enemy = damage ? target : player->GetVictim();
                if (enemy && player->IsValidAttackTarget(enemy))
                {
                    bool marked = enemy->HasAura(505340, player->GetGUID());
                    Eclipse(player, enemy, CalculatePct(amount, Amount(id)));
                    if (fulfillment && marked)
                    {
                        int32 pct = Amount(807444,1);
                        if (player->HasAura(704579))
                            pct = CalculatePct(pct, 100 + Amount(704579,1));
                        Copy(player, target, damage ? 807215 : 803816, CalculatePct(amount,pct));
                    }
                }
            }
            if (id == 807547)
            {
                auto allies = Allies(player, player, Radius(505197));
                allies.remove(player);
                allies.sort([player](Unit* a, Unit* b) { return player->GetDistance(a) < player->GetDistance(b); });
                if (!allies.empty())
                    Copy(player, allies.front(), 505197, CalculatePct(amount, Amount(807750) *
                        (player->HasAura(704934) ? 2 : 1) * (fulfillment ? 2 : 1)));
            }
            if (id == 807749 && fulfillment && !automatic)
                Cast(player, target, 506821);
            State(player).event = old;
            State(player).dawnEvent = oldDawn;
            return;
        }
        switch (id)
        {
            case 300369: case 301266: Cast(player,target,807175); break;
            case 92137: Cast(player,player,800722); break;
            case 300943: Cast(player,player,1257670); break;
            case 301239:
                Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA)-player->GetPower(POWER_MANA),Amount(302896)));
                Copy(player,player,707522,CalculatePct(player->GetMaxHealth()-player->GetHealth(),Amount(302896)));
                break;
            case 300336: Cast(player,target,300337); break;
            case 572885: Cast(player,target,572886); break;
            case 560861:
                if (player->HasAura(Dawn) || (spell && spell->GetScriptValue(DawnCast)))
                {
                    Reduce(player,806118,std::abs(Amount(560860)));
                    Reduce(player,301266,std::abs(Amount(560860)));
                }
                break;
            case 300355: Cast(player,player,301342); break;
            case 560492: Cast(player,event.GetActor(),560493); break;
            case 806116:
                if (player->HasAura(Sunset) && info->SchoolMask & SPELL_SCHOOL_MASK_HOLY)
                {
                    player->RemoveAurasDueToSpell(807077);
                    Cast(player,player,807061);
                }
                else if (player->HasAura(Sunrise) && info->SchoolMask & SPELL_SCHOOL_MASK_FIRE)
                {
                    player->RemoveAurasDueToSpell(807061);
                    Cast(player,player,807077);
                }
                break;
            case 704563: Cast(player,target,704564); break;
            case 681252: Reduce(player,800612,std::abs(Amount(681263))); break;
            case 704934: Cast(player,player,800601); break;
            case 806699: Reduce(player,800626,INT32_MAX); break;
            case 680663: Mana(player,CalculatePct(player->GetCreateMana(),Amount(504876))); break;
            case 680641: Cast(player,player,680642); break;
            case 680646:
                GetAura()->SetScriptValue(id,1);
                Cast(player,GetTarget(),681383);
                break;
            case 704928:
                Cast(player,player,704926);
                Mana(player,uint32(std::max(0.0f, Amount(704926,1,player) +
                    .15f * player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY))));
                break;
            case 704941: Cast(player,player,707843); break;
            case 807343: Cast(player,player,807523); break;
            case 707629: Extend(player,804751,4000); break;
            case 582832: Cast(player,player,582837); break;
            case 805647: Cast(player,target,Highest(player,800626)); break;
            case 300349: ReduceInvocations(player,std::abs(Amount(804512))); break;
            case 804632:
            {
                uint32 count=sSpellMgr->GetSpellInfo(573449)->MaxAffectedTargets;
                auto enemies=Nearby(target,Radius(573449));
                if (std::find(enemies.begin(),enemies.end(),target)==enemies.end())
                    enemies.push_front(target);
                for (Unit* enemy:enemies)
                    if (player->IsValidAttackTarget(enemy) && count)
                    {
                        --count;
                        Cast(player,enemy,807175);
                    }
                break;
            }
            case 806024: Cast(player,target,806025); break;
            case 806058: Reduce(player,520359,INT32_MAX); break;
            case 804629: Cast(player,player,807299); break;
            case 707077: Cast(player,target,804405); break;
            case 802935: Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA),Amount(504619))); break;
            case 680643: Cast(player,target,506824); break;
            case 547214: Cast(player,target,547217); break;
            case 561327:
                Reduce(player,804751,std::abs(Amount(680671)));
                Reduce(player,806479,std::abs(Amount(680671)));
                break;
            case 300371:
                for (Unit* enemy:Nearby(target,10))
                    if (enemy!=target && player->IsValidAttackTarget(enemy) && !enemy->HasAura(806697,player->GetGUID()))
                    {
                        Cast(player,enemy,806697);
                        break;
                    }
                break;
            case 704920:
                if (roll_chance_i(Named(info,500141) ? GetSpellInfo()->ProcChance : sSpellMgr->GetSpellInfo(707520)->ProcChance))
                    Cast(player,player,Named(info,500141) ? 301293 : 300354);
                break;
            case 806123:
                GetAura()->SetScriptValue(id,uint64(GameTime::GetGameTimeMS().count())+3000);
                Cast(GetTarget(),GetTarget(),502429);
                break;
            case 534267:
            {
                auto allies=Allies(player,target,Radius(801215));
                allies.remove(target);
                uint32 count=sSpellMgr->GetSpellInfo(801215)->MaxAffectedTargets;
                for (Unit* ally:allies)
                {
                    if (!count--)
                        break;
                    Copy(player,ally,801215,CalculatePct(healing,Amount(id)));
                }
                break;
            }
            case 704903:
            {
                auto enemies=Nearby(target,Radius(707774));
                if (std::find(enemies.begin(),enemies.end(),target)==enemies.end())
                    enemies.push_back(target);
                enemies.remove_if([player](Unit* unit) { return !player->IsValidAttackTarget(unit); });
                uint32 amount=CalculatePct(damage,Amount(id));
                if (enemies.size()==1)
                    AddPct(amount,50);
                for (Unit* enemy:enemies)
                    Copy(player,enemy,707774,amount);
                break;
            }
            case 704936: Copy(player,player,802598,CalculatePct(healing,Amount(id))); break;
            case 800612: Copy(player,target,807853,CalculatePct(damage,Amount(id))); break;
            case 300339: Copy(player,target,301005,CalculatePct(healing,Amount(id))); break;
            case 301005:
            {
                uint32 amount=std::max(0,GetEffect(EFFECT_0)->GetAmount());
                Unit* ally=GetTarget();
                GetAura()->Remove();
                Copy(player,ally,707522,amount);
                break;
            }
            case 680911:
                GetAura()->SetScriptValue(id,1);
                Copy(player,GetTarget(),681386,CalculatePct(damage,Amount(680911,2)));
                break;
            case 680624:
                if (AuraEffect* effect=GetEffect(EFFECT_0))
                    effect->SetAmount(int32(std::min<uint64>(INT32_MAX,uint64(std::max(0,effect->GetAmount()))+damage)));
                break;
            case 560095:
                if (GetAura()->GetCharges()>1)
                {
                    GetAura()->SetCharges(GetAura()->GetCharges()-1);
                    GetAura()->SetUsingCharges(false);
                }
                else
                    GetAura()->Remove();
                break;
            case 680888: GetAura()->Remove(); break;
            case 505342: GetAura()->Remove(); break;
        }
        State(player).event = old;
        State(player).dawnEvent = oldDawn;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_sun_cleric_event::Check);
        OnProc += AuraProcFn(aura_ascension_sun_cleric_event::Proc);
    }
};
}
void AddSC_AscensionSunClericEvents()
{
    RegisterSpellScript(aura_ascension_sun_cleric_event);
}
