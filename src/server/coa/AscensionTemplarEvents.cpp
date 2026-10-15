/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTemplar.h"
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

namespace
{
using namespace AscensionTemplar;
class aura_ascension_templar_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_templar_event);
    bool Check(ProcEventInfo& event)
    {
        Player* player = Owner(GetId() == 300513 ? GetCaster() : GetTarget());
        if (!player || !event.GetActionTarget())
            return false;
        SpellInfo const* info = event.GetSpellInfo();
        bool outgoing = event.GetActor() == player;
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        bool heal = event.GetHealInfo() && event.GetHealInfo()->GetEffectiveHeal();
        bool periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool crit = event.GetHitMask() & PROC_HIT_CRITICAL;
        bool melee = event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS);
        uint32 id = GetId();
        if (id == 801482 || id == 801483)
            return outgoing && damage && event.GetActionTarget() != player &&
                   (id != 801483 || !player->HasAura(801482));
        if (State(player).event)
            return false;
        if (id == 300513)
            return event.GetActor() == GetTarget() && damage && !periodic;
        if (id == 804912)
            return (!outgoing && (event.GetHitMask() & PROC_HIT_PARRY)) ||
                   (outgoing && damage && crit && (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK));
        if (id == 806353)
            return !outgoing && event.GetActionTarget() == player && damage && !periodic && player->HealthBelowPct(35);
        if (id == 705306)
            return !outgoing && damage && !periodic && event.GetActionTarget() == player && event.GetActor() &&
                   (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) &&
                   (!event.GetActor()->IsCreature() || (!event.GetActor()->ToCreature()->IsDungeonBoss() &&
                                                        !event.GetActor()->ToCreature()->isWorldBoss()));
        if (!outgoing || Derived(info))
            return false;
        switch (id)
        {
        case 92108:
            return damage && (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
                   event.GetDamageInfo()->GetAttackType() == OFF_ATTACK;
        case 92111:
        case 520007: {
            float chance = 20.0f;
            player->ApplySpellMod(520007, SPELLMOD_CHANCE_OF_SUCCESS, chance);
            return damage && !periodic && !Named(info, 804929) && (id != 520007 || !player->HasAura(92111)) &&
                   (id == 520007 || roll_chance_f(chance));
        }
        case 704116:
            return damage && crit && (Named(info, 801443) || Named(info, 801446));
        case 706385:
            return damage && periodic && Named(info, 804906);
        case 707391:
            return damage && melee && !periodic;
        case 560648:
            return damage && melee && !periodic;
        case 680397:
            return heal && !State(player).cooldowns.HasTimeUntilEvent(id);
        case 705298:
            return heal && event.GetActionTarget() == player && !State(player).cooldowns.HasTimeUntilEvent(id);
        case 801457:
            return heal && event.GetActionTarget() != player && player->IsInRaidWith(event.GetActionTarget());
        case 803158:
            return damage && melee && !periodic;
        case 706325:
            return damage && (Named(info, 804906) || Named(info, 801445) || Named(info, 803872)) &&
                   player->IsWithinMeleeRange(event.GetActionTarget());
        case 712346:
            return damage && crit && player->HasAura(803237);
        case 524620:
            return damage && periodic && Named(info, 804906);
        case 805415:
            return damage && crit && !State(player).cooldowns.HasTimeUntilEvent(id);
        case 801441:
        case 803890:
        case 803891:
        case 803892:
        case 803893:
        case 801463:
        case 801466:
        case 804932:
        case 806516:
            return damage && !periodic && Ability(info);
        default:
            return false;
        }
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = Owner(GetId() == 300513 ? GetCaster() : GetTarget());
        if (!player)
            return;
        bool processing = State(player).event;
        State(player).event = true;
        Unit* target = event.GetActionTarget();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        SpellInfo const* info = event.GetSpellInfo();
        uint32 id = GetId();
        switch (id)
        {
        case 300513:
            Cast(player, GetTarget(), 573020);
            break;
        case 92108:
        case 706325:
            Zealotry(player, target);
            break;
        case 92111:
        case 520007:
            Cast(player, target, 801832);
            break;
        case 704116:
            Copy(player, target, 801456, uint64(damage) * 50 / 100);
            break;
        case 705306:
            if (!State(player).cooldowns.HasTimeUntilEvent(id))
            {
                State(player).cooldowns.ScheduleEvent(id, 1s);
                Copy(player, event.GetActor(), 707720, uint64(damage) * 15 / 100);
            }
            break;
        case 706385:
            Copy(player, player, 707302, uint64(damage) * 75 / 100);
            break;
        case 707391:
            Copy(player, target, 525028, uint64(damage) * 30 / 100);
            Copy(player, target, 525028, uint64(damage) * 30 / 100);
            break;
        case 801482:
        case 801483:
            Copy(player, player, 803331, uint64(damage) * 50 / 100);
            break;
        case 560648:
            Reduce(player, 804929, INT32_MAX);
            Cast(player, player, 561156);
            break;
        case 680397:
            State(player).cooldowns.ScheduleEvent(id, 500ms);
            player->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), 680398, true);
            break;
        case 705298:
            State(player).cooldowns.ScheduleEvent(id, 15s);
            Cast(player, player, 705299);
            break;
        case 801457:
            Cast(player, target, 705309);
            Cast(player, player, 707307);
            break;
        case 803158:
            player->EnergizeBySpell(player, 804181, (event.GetHitMask() & PROC_HIT_CRITICAL) ? 3 : 1, POWER_ENERGY);
            break;
        case 712346:
            ReduceDebt(player, 0, true);
            break;
        case 524620:
            player->CastSpell(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), 524619, true);
            break;
        case 805415:
            State(player).cooldowns.ScheduleEvent(id, 1s);
            Cast(player, player, 805416);
            if (player->GetAuraCount(805416) >= 5 && !player->HasAura(524617))
                Cast(player, player, 524617);
            break;
        case 804912:
            Cast(player, player, 560651);
            break;
        case 806353: {
            uint32 stacks = GetStackAmount();
            GetAura()->Remove();
            for (uint32 i = 0; i < stacks; ++i)
                Cast(player, player, 806352);
            break;
        }
        case 801441:
        case 803890:
        case 803891:
        case 803892:
        case 803893:
            Cast(player, target, 804148);
            break;
        case 801463:
            Cast(player, player, 804150);
            break;
        case 801466:
            Reduce(player, 501562, std::abs(Amount(575328)));
            break;
        case 804932:
            if (!Breaker(info) && (!info || info->Id != 500689))
                Cast(player, player, 807648);
            break;
        case 806516:
            if (!player->HasAura(806517))
            {
                if (Aura* aura = player->GetAura(805390))
                    aura->SetScriptValue(805390, std::max(0, aura->GetDuration()));
                Cast(player, player, 805390);
            }
            break;
        default:
            break;
        }
        State(player).event = processing;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_templar_event::Check);
        OnProc += AuraProcFn(aura_ascension_templar_event::Proc);
    }
};
}
void AddSC_AscensionTemplarEvents()
{
    RegisterSpellScript(aura_ascension_templar_event);
}
