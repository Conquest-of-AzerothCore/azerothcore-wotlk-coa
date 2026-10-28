/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionStarcaller.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
namespace
{
using namespace AscensionStarcaller;
class aura_ascension_starcaller_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_starcaller_event);
    Player* GetOwner()
    {
        return GetId() == 804735 ? Owner(GetCaster()) : Owner(GetTarget());
    }
    bool Check(ProcEventInfo& e)
    {
        Player* player = GetOwner();
        if (!player || !e.GetActor() || !e.GetActionTarget() || State(player).event)
            return false;
        SpellInfo const* info = e.GetSpellInfo();
        uint32 id = GetId();
        bool outgoing = e.GetActor() == GetTarget();
        bool crit = e.GetHitMask() & PROC_HIT_CRITICAL;
        bool periodic = e.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool automatic = e.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_RANGED_AUTO_ATTACK);
        bool melee = e.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS);
        bool ranged = e.GetTypeMask() & (PROC_FLAG_DONE_RANGED_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS);
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = e.GetHealInfo() ? e.GetHealInfo()->GetEffectiveHeal() : 0;
        if (Derived(info))
            return false;
        if (id == 804735)
            return outgoing && damage && GetAura()->GetStackAmount();
        if (!outgoing && e.GetActionTarget() == player)
        {
            bool block = e.GetHitMask() & PROC_HIT_BLOCK;
            bool parry = e.GetHitMask() & PROC_HIT_PARRY;
            bool avoid = block || parry || (e.GetHitMask() & PROC_HIT_DODGE);
            bool meleeTaken =
                e.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS);
            switch (id)
            {
            case 300992:
                return block;
            case 560501:
                return avoid && meleeTaken && Chance(player, id, 1000);
            case 805505:
                return (block || parry) && Chance(player, id);
            case 807659:
                return parry && Chance(player, id, 1000);
            case 536217:
                return parry;
            case 801155:
                return damage != 0;
            case 704777:
                return !periodic && meleeTaken && damage && player->HasInArc(float(M_PI), e.GetActor()) &&
                       State(player).counters[e.GetActor()->GetGUID()] <= State(player).clock;
            case 806155:
                return !periodic && damage && info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC);
            default:
                return false;
            }
        }
        if (!outgoing || (!damage && !healing && !(id == 504001 && criticalHeal(e, info))))
            return false;
        switch (id)
        {
        case 801128:
        case 805356:
        case 800510:
        case 803887:
        case 803888:
            return automatic && damage;
        case 801123:
            return (melee || ranged) && damage && !periodic;
        case 800394:
            return damage && Chance(player, id);
        case 504001:
            return criticalHeal(e, info);
        case 504628:
            return !periodic && Chance(player, id, 1000);
        case 504786:
            return crit && Chance(player, id, 1000);
        case 524642:
        case 706230:
        case 801143:
            return info && info->Id == 804995 && damage && Chance(player, id);
        case 536216:
            return crit && damage && Any(info, {801127, 805550});
        case 560440:
            return crit && damage;
        case 560539:
            return crit && damage && Named(info, 801972);
        case 560956:
            return damage && info && info->Id == 804995;
        case 561022:
            return damage && info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_ARCANE) && Chance(player, id);
        case 680784:
            return melee && damage && crit;
        case 801145:
        case 706575:
            return damage && crit;
        case 801231:
            return crit && !periodic;
        case 805439:
            return damage && crit && Chance(player, id);
        case 804733:
            return healing && info && info->Id != 804736;
        case 704741:
            return damage && ranged && Chance(player, id);
        case 680215:
            return damage && (automatic || Any(info, {800496, 801127})) &&
                   (State(player).chargeReady || player->HasAura(State(player).chargeAura));
        default:
            return false;
        }
    }
    bool criticalHeal(ProcEventInfo& e, SpellInfo const* info)
    {
        return (e.GetHitMask() & PROC_HIT_CRITICAL) && e.GetHealInfo() && info && info->Id == 801990;
    }
    void Proc(ProcEventInfo& e)
    {
        PreventDefaultAction();
        Player* player = GetOwner();
        if (!player)
            return;
        bool old = State(player).event;
        State(player).event = true;
        uint32 id = GetId();
        Unit* target = e.GetActor() == GetTarget() ? e.GetActionTarget() : e.GetActor();
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        uint32 healing = e.GetHealInfo() ? e.GetHealInfo()->GetEffectiveHeal() : 0;
        switch (id)
        {
        case 801128:
        case 805356:
        case 800510:
        case 803887:
        case 803888:
            Aspect(player, target, damage);
            break;
        case 801123:
            Aspect(player, target, damage);
            if (player->HasAura(300772))
                Cast(player, player, 300773);
            break;
        case 300992:
        case 680784:
        case 800394:
        case 704741:
            Stars(player, target);
            break;
        case 504001:
            Cast(player, target, 504027);
            break;
        case 504628:
            Cast(player, player, damage ? 504630 : 504631);
            break;
        case 504786:
            GainPhase(player);
            break;
        case 524642:
            player->RestoreSpellCharge(Highest(player, 520590));
            break;
        case 536216:
            Cast(player, player, 536217);
            break;
        case 536217:
            GetAura()->Remove();
            break;
        case 560440:
            Cast(player, target, 572181);
            break;
        case 560501:
            Cast(player, target, 560500);
            break;
        case 560539:
            for (Unit* ally : Nearby(player, 40))
                if (ally->IsPlayer() && player->IsValidAssistTarget(ally) &&
                    (ally == player || player->IsInRaidWith(ally)))
                {
                    Cast(player, ally, 560634);
                    break;
                }
            break;
        case 560956:
            Cast(player, player, 680465);
            break;
        case 561022:
            Cast(player, player, 561046);
            break;
        case 801145:
            Reduce(player, 805508, 1000);
            break;
        case 801231: {
            ReduceHealing(player, 10);
            uint32 remaining = 5;
            for (Unit* enemy : Nearby(target, 5))
                if (player->IsValidAttackTarget(enemy))
                {
                    Stars(player, enemy);
                    if (!--remaining)
                        break;
                }
            break;
        }
        case 805439:
            Cast(player, target, Highest(player, 805508));
            break;
        case 805505:
            Cast(player, player, 807660);
            break;
        case 807659:
            Cast(player, target, 805506);
            break;
        case 801155:
            Mana(player, damage * 30 / 100, 801149);
            break;
        case 704777:
            State(player).counters[target->GetGUID()] = State(player).clock + 1000;
            Copy(player, target, 707759, damage);
            break;
        case 806155:
            Cast(player, target, 806453);
            Cast(player, target, 806156);
            break;
        case 804733:
            Cast(player, target, 804735);
            if (Aura* aura = target->GetAura(804735, player->GetGUID()))
                aura->SetScriptValue(706287, std::max<uint64>(1, healing / 10));
            break;
        case 804735: {
            uint32 amount = uint32(std::min<uint64>(INT32_MAX, GetAura()->GetScriptValue(706287)));
            if (!amount)
                amount = std::max(0, Amount(804736, 0, player));
            GetAura()->ModStackAmount(-1);
            Copy(player, GetTarget(), 804736, amount);
            break;
        }
        case 706230:
            Cast(player, target, 504002);
            break;
        case 801143:
            Reduce(player, 805563, INT32_MAX);
            Cast(player, player, 801243);
            break;
        case 706575:
            Cast(player, player, 680821);
            break;
        case 680215:
            if (uint32 aura = State(player).chargeAura)
            {
                FinishCharge(player);
                player->RemoveAurasDueToSpell(aura);
            }
            State(player).chargeReady = false;
            Cast(player, target, 805006);
            State(player).chargeDistance = 0;
            break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_starcaller_event::Check);
        OnProc += AuraProcFn(aura_ascension_starcaller_event::Proc);
    }
};
}
void AddSC_AscensionStarcallerEvents()
{
    RegisterSpellScript(aura_ascension_starcaller_event);
}
