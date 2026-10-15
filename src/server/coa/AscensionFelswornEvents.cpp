/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
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
using namespace AscensionFelsworn;
class aura_ascension_felsworn_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_felsworn_event);
    bool Check(ProcEventInfo& event)
    {
        uint32 id = GetId();
        Player* player = Owner(id == 707902 ? GetCaster() : GetTarget());
        if (!player || !event.GetActionTarget())
            return false;
        SpellInfo const* info = event.GetSpellInfo();
        bool outgoing = event.GetActor() == player;
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        bool periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool crit = event.GetHitMask() & PROC_HIT_CRITICAL;
        bool autoAttack = event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK;
        bool melee = autoAttack || (event.GetTypeMask() & PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS);
        bool dodge = event.GetHitMask() & PROC_HIT_DODGE;
        bool parry = event.GetHitMask() & PROC_HIT_PARRY;
        if (id == 707902)
            return outgoing && event.GetActionTarget() == GetTarget() && damage && crit;
        if (id == 520244)
            return outgoing && damage && info && info->Id == 800598;
        if (id == 560542)
            return outgoing && damage && melee && Inner(player) && !Derived(info);
        if (State(player).event)
            return false;
        if (id == 804822 || id == 805249 || id == 300476 || id == 805245)
            return !outgoing && event.GetActionTarget() == player &&
                   (id == 805245 ? (damage || dodge || parry) &&
                                       (player->HasAura(800209) || player->GetAuraOfRankedSpell(705129))
                                 : dodge || (id == 804822 && parry)) &&
                   Chance(player, id);
        if (!outgoing || !damage || Derived(info))
            return false;
        switch (id)
        {
        case 92087:
            return info && melee && crit && !periodic;
        case 300480:
            return !periodic && Chance(player, id);
        case 681376:
            return Chance(player, id);
        case 685321:
            return Twin(info) && !periodic;
        case 300474:
            return info && !periodic && info->DmgClass == SPELL_DAMAGE_CLASS_MAGIC &&
                   (info->SchoolMask & (SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_SHADOW));
        case 805998:
            return Named(info, 802060) && !periodic;
        case 806235:
            return SpenderImpact(info) && crit && !periodic;
        case 520246:
            return Named(info, 801312) && crit && !periodic;
        case 704610:
            return info && (Named(info, 801904) || info->Id == 520262 || info->Id == 572585) && !periodic &&
                   Chance(player, id);
        case 300478:
            return Named(info, 801312) && crit && !periodic && Chance(player, id, 5000);
        case 574143:
            return info && melee && crit && !periodic && Inner(player);
        case 705131:
            return Named(info, 801312) && !periodic;
        case 520833:
            return Named(info, 802060) && crit && !periodic;
        case 570077:
            return melee && Inner(player);
        case 300483:
            return info && info->Id == 802678;
        case 801899:
            return info && melee && !periodic && Chance(player, id);
        case 560639:
        case 300490:
            return periodic && Chance(player, id);
        case 704370:
            return Named(info, 704368) || (info && info->Id == 802676);
        case 570158:
            return info && (Named(info, 801904) || info->Id == 520262 || info->Id == 572585);
        case 572889:
            return crit;
        case 704606:
            return info && info->DmgClass == SPELL_DAMAGE_CLASS_MAGIC && crit && !periodic;
        case 800214:
            return crit && !periodic && Chance(player, id);
        case 300484:
            return info && (Named(info, 801904) || info->Id == 520262 || info->Id == 572585);
        case 560503:
            return Inner(player) && !periodic && (Named(info, 802060) || (info && info->Id == 803715));
        case 574145:
            return autoAttack && crit;
        case 805239:
            return melee;
        case 806111:
            return Named(info, 802060) && crit && !periodic;
        case 807461:
            return Named(info, 704368) || (info && info->Id == 802676);
        case 807426:
            return Inner(player) && autoAttack && crit;
        case 803904:
            return autoAttack && !periodic;
        default:
            return false;
        }
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint32 id = GetId();
        Player* player = Owner(id == 707902 ? GetCaster() : GetTarget());
        if (!player)
            return;
        bool old = State(player).event;
        State(player).event = true;
        Unit* target = event.GetActionTarget();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        switch (id)
        {
        case 92087: {
            uint32 count = 0;
            for (Unit* enemy : Nearby(player, 8.0f))
                if (player->IsValidAttackTarget(enemy) && player->IsWithinLOSInMap(enemy))
                {
                    Cast(player, enemy, 800598);
                    if (++count == 5)
                        break;
                }
            if (player->HasAura(705145))
                Cast(player, player, 705146);
            break;
        }
        case 300480:
            Reduce(player, 560284, INT32_MAX);
            break;
        case 681376:
            Cast(player, player, 572782);
            break;
        case 685321:
            Cast(player, target, 563271);
            break;
        case 520244:
            Reduce(player, 555738, std::abs(Amount(520816)));
            break;
        case 804822:
            Cast(player, player, 807163);
            break;
        case 300474:
            Cast(player, target, 300475);
            break;
        case 805998:
            SpreadCripple(player, target);
            break;
        case 806235:
            Extend(player, Amount(806236));
            Cast(player, target, 572792);
            break;
        case 520246:
        case 520833:
        case 560639:
        case 805245:
            Gain(player, 1);
            break;
        case 704610:
            Cast(player, target, 520262);
            break;
        case 300478:
            Cast(player, player, 300486);
            Cast(player, player, 301290);
            break;
        case 574143:
            Cast(player, player, 592521);
            break;
        case 705131:
            Cast(player, target, 707360);
            break;
        case 570077:
            Cast(player, target, 567578);
            break;
        case 300483:
            if (Aura* aura = target->GetAura(704371, player->GetGUID()))
            {
                int32 duration = aura->GetDuration() + Amount(560643);
                aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
                aura->SetDuration(duration);
            }
            Cast(player, player, 300481);
            break;
        case 801899:
            Reduce(player, 801903, INT32_MAX);
            Cast(player, player, 801902);
            break;
        case 300490:
            Cast(player, player, 806104);
            break;
        case 805249:
            Cast(player, player, 521210);
            break;
        case 704370:
            Cast(player, target, 707511);
            break;
        case 570158:
            Cast(player, target, 570159);
            break;
        case 572889:
            Cast(player, player, 705148);
            break;
        case 704606:
            Cast(player, player, 524898);
            break;
        case 300476:
            Cast(player, event.GetActor(), 804336);
            Cast(player, player, 520256);
            break;
        case 800214:
            Cast(player, target, 802678);
            Cast(player, player, 800239);
            break;
        case 300484:
            Cast(player, target, 300482);
            break;
        case 560503:
            Copy(player, target, 705124, uint64(damage) * 20 / 100);
            break;
        case 560542:
            Copy(player, player, 560627, uint64(damage) * 15 / 100);
            break;
        case 574145:
            Copy(player, target, 574166, uint64(damage) * 75 / 100);
            break;
        case 805239:
            Copy(player, target, 807347, uint64(damage) * 50 / 100);
            break;
        case 806111:
            CopyDot(player, target, 806112, uint64(damage) * 50 / 100);
            break;
        case 807461: {
            uint32 count = 0;
            for (Unit* enemy : Nearby(target, 8.0f))
                if (enemy != target && player->IsValidAttackTarget(enemy) && target->IsWithinLOSInMap(enemy))
                {
                    Copy(player, enemy, 807554, damage / 2);
                    if (++count == 8)
                        break;
                }
            break;
        }
        case 807426:
            Copy(player, player, 560839, damage / 2);
            break;
        case 803904:
        case 707902: {
            uint64 remaining = GetAura()->GetScriptValue(id);
            if (remaining)
                GetAura()->SetScriptValue(id, --remaining);
            if (id == 803904 && player->IsAlive())
                Unit::DealDamage(player, player, player->CountPctFromMaxHealth(5), nullptr, NODAMAGE,
                                 SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
            if (!remaining)
                GetAura()->Remove();
            break;
        }
        default:
            break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_felsworn_event::Check);
        OnProc += AuraProcFn(aura_ascension_felsworn_event::Proc);
    }
};
}
void AddSC_AscensionFelswornEvents()
{
    RegisterSpellScript(aura_ascension_felsworn_event);
}
