/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "GameTime.h"
#include "ObjectAccessor.h"
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
using namespace AscensionVenomancer;
class aura_ascension_venomancer_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_venomancer_event);
    Player* Caster()
    {
        if (GetId() == 300855 || GetId() == 504352 || GetId() == 808082 || GetId() == 808083)
            return Owner(GetCaster());
        return Owner(GetTarget());
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
        bool received = event.GetActionTarget() == GetTarget();
        bool own = event.GetActor() == player;
        if (id == 300855)
            return event.GetActor() == GetTarget() && damage && !Derived(info) && (!info || info->Id != 803178) &&
                roll_chance_i(GetSpellInfo()->ProcChance);
        if (id == 808082)
            return own && received && healing && !Derived(info);
        if (received && damage)
        {
            switch (id)
            {
                case 504352: case 808083: return !periodic;
                case 804963: return true;
                case 803210: return !player->HasAura(803211) && Chance(player,id);
                case 503960: return !periodic && Chance(player,id,1000);
                case 705998: return !periodic && Chance(player,id,3000);
                case 805098: return !periodic && player->HasAura(Beetle) && Chance(player,id);
                case 504406: return !periodic && Chance(player,id);
                case 800892: return event.GetDamageInfo() &&
                    (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
                case 705961: return event.GetDamageInfo() &&
                    (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC);
            }
        }
        if (id == 705969)
            return received && (event.GetHitMask() & PROC_HIT_DODGE);
        if (!own || Derived(info))
            return false;
        Unit* target = event.GetActionTarget();
        switch (id)
        {
            case 92142: return damage && !periodic && !Any(info,{504543,503925}) && Chance(player,id);
            case 503812: return damage && Any(info,{803196,803208});
            case 503851: return damage && periodic && Chance(player,id);
            case 503854: return damage && Any(info,{800880,504705});
            case 503856: return (damage || healing) && Chance(player,id);
            case 503919: case 573307: return damage && Named(info,804982);
            case 503976: return damage && critical && Any(info,{800869,803193,800880,504705});
            case 504355: return damage && Named(info,804983);
            case 504361: return damage && critical;
            case 504375: return damage && !periodic && critical && Any(info,{800880,504705,800882});
            case 504402: return damage && Any(info,{803196,803208,803570});
            case 560200: return healing && periodic && Named(info,800901) && Chance(player,id);
            case 560264: return damage && periodic && Chance(player,id);
            case 560281: return healing && periodic && Chance(player,id);
            case 574354: return (damage && automatic && player->HasAura(805776) && Chance(player,id)) ||
                (damage && critical);
            case 680768: return healing && !periodic && Named(info,504342);
            case 680800: return healing && info && info->Id == 560202;
            case 704264: return damage && automatic && player->HasAura(Beetle) &&
                roll_chance_i(sSpellMgr->GetSpellInfo(560988)->ProcChance);
            case 705959: return damage && Named(info,803193);
            case 705980: return damage && Named(info,803570);
            case 705982: return damage && critical && Any(info,{803570,803199,803193});
            case 705993: return (damage || healing) && Chance(player,id);
            case 706001: return damage && Named(info,803199);
            case 706016: return healing && critical;
            case 706018: return healing && !periodic && Chance(player,id);
            case 706030: return damage && periodic && Chance(player,id);
            case 706035: return (damage || healing) && critical && Chance(player,id,5000);
            case 706271: return damage && periodic && Chance(player,id,2000);
            case 706938: return healing && Named(info,504342);
            case 707224: return damage && Named(info,804986);
            case 707233: return damage && periodic && (!info || info->Id != 707234) && Chance(player,id);
            case 707382: return damage && critical && info && info->Id == 504705;
            case 707620: return damage && critical && !periodic;
            case 707668:
                return damage && critical && player->HasAura(Spider) &&
                    target->HasAura(712455, player->GetGUID()) &&
                    (!event.GetProcSpell() || !event.GetProcSpell()->GetScriptValue(SpiderlingVenomSource));
            case 804981: return damage && periodic && Chance(player,id);
            case 805884: return healing && periodic && critical;
            case 805933: return damage && target->GetHealthPct() < 35;
            case 806449: return healing;
            case 806603: return damage && ((critical && roll_chance_i(sSpellMgr->GetSpellInfo(806604)->ProcChance)) ||
                (periodic && Chance(player,id)));
            case 806604: return damage && critical && info && (info->SchoolMask & SPELL_SCHOOL_MASK_NATURE) &&
                !player->HasAura(806603) && Chance(player,id);
            case 504792: return (damage || healing) && !periodic &&
                (Any(info,{800946,800880,504705,803198}) || (info && info->Id == 560202)) &&
                (target->HasAura(504377,player->GetGUID()) || target->HasAura(504802,player->GetGUID()));
            case 706021: return healing && periodic && critical;
            case 706370: return damage && periodic && Named(info,804982) && Chance(player,id);
            case 706455: return damage && !periodic && Any(info,{800869,800946}) &&
                target->HasAura(804979,player->GetGUID());
            case 804987: return damage && info && (info->SchoolMask & (SPELL_SCHOOL_MASK_NATURE | SPELL_SCHOOL_MASK_SHADOW)) &&
                Chance(player,id);
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
        Unit* target = event.GetActionTarget();
        Unit* actor = event.GetActor();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = event.GetHealInfo() ? event.GetHealInfo()->GetEffectiveHeal() : 0;
        bool old = State(player).event;
        State(player).event = true;
        switch (id)
        {
            case 300855: Cast(player,target,803178); break;
            case 92142:
                Reduce(player,800946,INT32_MAX);
                Cast(player,player,706032);
                Cast(player,player,1257670);
                break;
            case 503812: Cast(player,target,570153); break;
            case 503851:
            {
                uint32 left = sSpellMgr->GetSpellInfo(503857)->MaxAffectedTargets;
                if (player->IsValidAttackTarget(target))
                {
                    Cast(player,target,503857);
                    if (left)
                        --left;
                }
                for (Unit* enemy : Nearby(target,Radius(503857)))
                    if (enemy != target && player->IsValidAttackTarget(enemy) && left)
                    {
                        Cast(player,enemy,503857);
                        --left;
                    }
                break;
            }
            case 503854: Cast(player,target,572055); break;
            case 503856: Cast(player,target,healing ? 504802 : 504377); break;
            case 503919: Cast(player,target,572059); break;
            case 503960: Cast(player,player,503953); break;
            case 503976: Cast(player,player,503977); break;
            case 504352: GetTarget()->CastSpell(GetTarget(),504351,true); break;
            case 504355: Reduce(player,800910,std::abs(Amount(504354))); break;
            case 504361: ExtendOwned(player,target,804982,std::abs(Amount(504360))); break;
            case 504375:
                Copy(player,target,504794,CalculatePct(damage,Amount(504375)));
                if (roll_chance_i(GetSpellInfo()->ProcChance))
                    ExtendOwned(player,target,804977,std::abs(Amount(504795)));
                break;
            case 504402: case 705982: Cast(player,target,705985); break;
            case 560200: Cast(player,player,560201); break;
            case 560264: Cast(player,player,560265); break;
            case 560281: Cast(player,player,1257670); break;
            case 573307: Cast(player,target,804979); break;
            case 574354:
                if ((event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) && player->HasAura(805776))
                    Cast(player,target,805896);
                if (event.GetHitMask() & PROC_HIT_CRITICAL)
                    Cast(player,target,572056);
                break;
            case 680768:
                for (Unit* ally : Allies(player,target,Radius(681417)))
                    if (ally != target)
                    {
                        Spread(player,target,ally,800901);
                        break;
                    }
                break;
            case 680800: Cast(player,target,505203); break;
            case 704264: Summon(player,target,560989); break;
            case 705959:
            {
                bool consumed = false;
                for (auto const& pair : target->GetAppliedAuras())
                {
                    Aura* aura = pair.second->GetBase();
                    if (aura->GetCasterGUID() == player->GetGUID() && aura->GetId() == 572058)
                    {
                        consumed = aura->GetDuration() >= std::abs(Amount(803202,1));
                        if (consumed)
                            aura->SetDuration(aura->GetDuration()-std::abs(Amount(803202,1)));
                        break;
                    }
                }
                if (consumed)
                    player->CastSpell(target->GetPositionX(),target->GetPositionY(),target->GetPositionZ(),803202,true);
                break;
            }
            case 705961:
                for (uint32 school = SPELL_SCHOOL_HOLY; school < MAX_SPELL_SCHOOL; ++school)
                    if ((event.GetDamageInfo()->GetSchoolMask() & (1u << school)) &&
                        !State(player).timers.HasTimeUntilEvent(705961 + school))
                    {
                        State(player).timers.ScheduleEvent(705961 + school,30s);
                        constexpr uint32 helpers[] = {0,503990,503989,503992,503996,503993,503997};
                        Cast(player,player,helpers[school]);
                    }
                break;
            case 705969: Cast(player,player,572909); break;
            case 705980: Cast(player,player,561230); break;
            case 705993: Cast(player,player,504341); break;
            case 705998:
                player->CastSpell(actor->GetPositionX(),actor->GetPositionY(),actor->GetPositionZ(),704347,true);
                break;
            case 706001:
                player->CastSpell(target,704347,true);
                break;
            case 706016: Cast(player,target,706017); break;
            case 706018:
            {
                Aura* amulet = player->GetAura(800914);
                if (!amulet)
                {
                    Cast(player,player,800914);
                    if (Aura* added = player->GetAura(800914))
                        added->SetDuration(std::min(5000,added->GetMaxDuration()));
                }
                else
                    amulet->SetDuration(std::min(amulet->GetMaxDuration(),amulet->GetDuration()+5000));
                break;
            }
            case 706030:
                ReducePercent(player,800946,20);
                ReducePercent(player,504344,20);
                break;
            case 706035: Cast(player,player,504211); break;
            case 706271: Cast(player,player,706272); break;
            case 706938: Cast(player,player,707097); break;
            case 707224:
                for (ObjectGuid guid : State(player).summons)
                    if (Unit* unit = ObjectAccessor::GetUnit(*player,guid); unit && unit->GetEntry() == 45896)
                        Cast(player,unit,805431);
                break;
            case 707233: Cast(player,target,707234); break;
            case 707382: Resource(player,Brood,1); break;
            case 707620:
                Cast(player,player,504404);
                if (Count(player,504404) >= sSpellMgr->GetSpellInfo(504404)->StackAmount)
                {
                    player->RemoveAurasDueToSpell(504404);
                    Reduce(player,805094,std::abs(Amount(504403)));
                }
                break;
            case 707668: Summon(player,target,807702); break;
            case 800892:
                if (Aura* harden = player->GetAura(800960))
                {
                    Cast(player,player,680839);
                    harden->ModStackAmount(-1);
                }
                break;
            case 804963:
                player->CastSpell(player->GetPositionX(),player->GetPositionY(),player->GetPositionZ(),630869,true);
                break;
            case 804981: Mana(player,CalculatePct(player->GetCreateMana(),Amount(681318))); break;
            case 805098: Expose(player,1); break;
            case 805884:
                Mana(player,CalculatePct(player->GetMaxPower(POWER_MANA)-player->GetPower(POWER_MANA),Amount(681289)));
                break;
            case 805933: Reduce(player,804964,std::abs(Amount(805934))); break;
            case 806449: Cast(player,target,806454); break;
            case 806603: case 806604: Cast(player,player,806602); break;
            case 504406: Copy(player,actor,503793,CalculatePct(damage,Amount(504406))); break;
            case 504792:
                Copy(player,target,healing ? 504803 : 504796,CalculatePct(healing ? healing : damage,Amount(504792)));
                Cast(player,player,504376);
                break;
            case 706021: Copy(player,target,707594,CalculatePct(healing,Amount(706021,2))); break;
            case 706370: Copy(player,target,706392,damage); break;
            case 706455:
                AddFungic(player,target,damage);
                break;
            case 803210: Cast(player,player,803211); break;
            case 804987: Cast(player,target,804971); break;
            case 808082:
                if (AuraEffect* stored = GetAura()->GetEffect(EFFECT_1))
                    stored->SetAmount(int32(std::min<uint64>(INT32_MAX,uint64(std::max(0,stored->GetAmount())) +
                        CalculatePct(healing,Amount(808082)))));
                break;
            case 808083:
                Copy(player,GetTarget(),808084,uint32(std::max(0,GetAura()->GetEffect(EFFECT_0)->GetAmount())));
                if (GetAura()->GetCharges() > 1)
                    GetAura()->SetCharges(GetAura()->GetCharges()-1);
                else
                    GetAura()->Remove();
                break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_venomancer_event::Check);
        OnProc += AuraProcFn(aura_ascension_venomancer_event::Proc);
    }
};
}
void AddSC_AscensionVenomancerEvents()
{
    RegisterSpellScript(aura_ascension_venomancer_event);
}
