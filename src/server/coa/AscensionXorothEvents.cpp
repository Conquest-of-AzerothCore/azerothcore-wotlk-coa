/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionXoroth.h"
#include "Pet.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
namespace
{
using namespace AscensionXoroth;
class aura_ascension_xoroth_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_xoroth_event);
    Player* GetOwner()
    {
        Player* player = Owner(GetTarget());
        return player ? player : Owner(GetTarget()->GetOwner());
    }
    bool Check(ProcEventInfo& e)
    {
        Player* player = GetOwner();
        if (!player || !e.GetActionTarget() || State(player).event)
            return false;
        auto info = e.GetSpellInfo();
        uint32 id = GetId();
        bool outgoing = e.GetActor() == GetTarget(), crit = e.GetHitMask() & PROC_HIT_CRITICAL;
        bool periodic = e.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        bool autoAttack = e.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK;
        bool melee = autoAttack || (e.GetTypeMask() & PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS);
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        bool block = e.GetHitMask() & PROC_HIT_BLOCK, parry = e.GetHitMask() & PROC_HIT_PARRY,
             dodge = e.GetHitMask() & PROC_HIT_DODGE;
        if (GetTarget() != player)
        {
            if (!outgoing || !damage || Derived(info))
                return false;
            if (id == 802602)
                return autoAttack;
            if (id == 520662)
                return info && (info->SchoolMask & SPELL_SCHOOL_MASK_FIRE) && Chance(player, 500578);
            if (id == 800443 || id == 562029)
                return Chance(player, 706565);
            return (id == 802603 || id == 802604 || id == 802605) && roll_chance_i(GetSpellInfo()->ProcChance);
        }
        if (!outgoing && e.GetActionTarget() == player)
            switch (id)
            {
            case 92104:
                return block && Chance(player, id, 3000);
            case 560546:
                return block;
            case 560630:
                return parry;
            case 573034:
                return (damage || block || parry || dodge) && Chance(player, id);
            case 681449:
                return damage && crit && Chance(player, id, 3000);
            case 704971:
                return block && Chance(player, id, 5000);
            case 801065:
                return (block || parry || dodge) && Chance(player, id);
            case 804345:
                return damage &&
                       Chance(player, id, 0, player->HasAura(300387) ? float(Amount(300387)) : 0);
            default:
                return false;
            }
        if (!outgoing)
            return false;
        if (id == 706590)
            return periodic && (damage || (e.GetHealInfo() && e.GetHealInfo()->GetEffectiveHeal())) &&
                   Chance(player, id);
        if (!damage || Derived(info))
            return false;
        switch (id)
        {
        case 300376:
            return crit;
        case 302548:
            return periodic && Chance(player, id, 0, Count(player, 500906) * 2.0f);
        case 520372:
            return crit && (!info || (info->SchoolMask & SPELL_SCHOOL_MASK_NORMAL));
        case 524920:
            return melee && !periodic;
        case 704972:
            return info && (info->SchoolMask & SPELL_SCHOOL_MASK_FIRE);
        case 704979:
            return melee && crit && !periodic;
        case 704991:
            return crit && !periodic;
        case 706502:
            return Chance(player, id);
        case 800997:
            return melee && !periodic && (!info || (info->SchoolMask & SPELL_SCHOOL_MASK_NORMAL));
        case 800702:
            return !periodic && player->GetHealthPct() > 75 && (!info || (info->SchoolMask & SPELL_SCHOOL_MASK_NORMAL));
        default:
            return false;
        }
    }
    void Proc(ProcEventInfo& e)
    {
        PreventDefaultAction();
        Player* player = GetOwner();
        if (!player)
            return;
        bool old = State(player).event;
        State(player).event = true;
        Unit* target = e.GetActionTarget();
        uint32 id = GetId();
        uint32 damage = e.GetDamageInfo() ? e.GetDamageInfo()->GetDamage() : 0;
        switch (id)
        {
        case 92104:
            Summon(player, 50301, ImpPosition(player), sSpellMgr->GetSpellInfo(805966)->GetDuration());
            break;
        case 300376:
            Cast(player, player, 805799);
            break;
        case 302548:
            Reduce(player, 804169, std::abs(Amount(302550)));
            break;
        case 520372:
            Cast(player, target, 520542);
            break;
        case 524920:
            if (e.GetHitMask() & PROC_HIT_CRITICAL)
                Cast(player, target, 524919);
            if (uint64 left = GetAura()->GetScriptValue(id); left > 1)
                SetRemainingUses(GetAura(), uint8(left - 1));
            else
                GetAura()->Remove();
            break;
        case 560546:
            Cast(player, player, 560630);
            break;
        case 560630:
            GetAura()->Remove();
            break;
        case 573034:
            Gain(player, 1);
            break;
        case 681449:
            Gain(player, 1);
            Cast(player, player, 521452);
            break;
        case 704971:
            Unleash(player, player, .5f);
            break;
        case 704972:
            Cast(player, target, 572860);
            break;
        case 704979:
            Reduce(player, 524920, std::abs(Amount(707379)));
            break;
        case 704991:
            if (Aura* aura = player->GetAura(803889))
                aura->SetDuration(std::min(aura->GetMaxDuration(), aura->GetDuration() + std::abs(Amount(680727))));
            break;
        case 706502:
            Cast(player, player, 707131);
            if (Count(player, 707131) >= 10)
            {
                player->RemoveAurasDueToSpell(707131);
                Cast(player, player, 712294);
            }
            break;
        case 706590:
            Gain(player, 1);
            break;
        case 800997:
            Blood(player);
            break;
        case 801065:
            Cast(player, player, 801019);
            break;
        case 804345:
            Cast(player, player, 521226);
            Blood(player);
            break;
        case 800702:
            Cast(player, player, 800703);
            break;
        case 520662:
            Cast(player, player, 500605);
            break;
        case 800443:
        case 562029:
            Cast(GetTarget(), target, 800444);
            Cast(GetTarget(), target, 578318);
            break;
        case 802603:
            Cast(GetTarget(), target, 520418);
            break;
        case 802604:
            Cast(player, player, 803254);
            break;
        case 802605:
            Cast(GetTarget(), target, 803255);
            break;
        case 802602: {
            auto info = sSpellMgr->GetSpellInfo(802608);
            uint32 ticks = std::max(1, info->GetDuration() / int32(info->Effects[0].Amplitude));
            uint32 values[6] = {damage / 10 / ticks};
            if (Aura* previous = target->GetAura(802608, GetTarget()->GetGUID()))
                for (uint32 i = 1; i < 6; ++i)
                    values[i] = uint32(previous->GetScriptValue(802608 + i - 1));
            Copy(GetTarget(), target, 802608, values[0]);
            if (Aura* aura = target->GetAura(802608, GetTarget()->GetGUID()))
            {
                uint64 total = 0;
                for (uint32 i = 0; i < 6; ++i)
                {
                    aura->SetScriptValue(802608 + i, values[i]);
                    total += values[i];
                }
                if (AuraEffect* effect = aura->GetEffect(EFFECT_0))
                    effect->ChangeAmount(int32(std::min<uint64>(INT32_MAX, total)));
            }
            break;
        }
        default:
            break;
        }
        State(player).event = old;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_xoroth_event::Check);
        OnProc += AuraProcFn(aura_ascension_xoroth_event::Proc);
    }
};
}
void AddSC_AscensionXorothEvents()
{
    RegisterSpellScript(aura_ascension_xoroth_event);
}
