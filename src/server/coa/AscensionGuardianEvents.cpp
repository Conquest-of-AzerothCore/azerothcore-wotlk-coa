/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGuardianCompletion.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
bool Direct(ProcEventInfo const& event)
{
    return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
        !(event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC));
}

bool CastByPlayer(ProcEventInfo const& event)
{
    return event.GetProcSpell() && !event.GetProcSpell()->IsTriggered();
}

void CarryBleed(Unit* caster, Unit* target, uint32 id, uint32 damage, uint32 percent)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!info || !info->Effects[EFFECT_0].Amplitude || info->GetDuration() <= 0)
        return;
    uint32 ticks = info->GetDuration() / info->Effects[EFFECT_0].Amplitude;
    if (!ticks)
        return;
    uint64 total = uint64(damage) * percent * ticks / 100;
    if (AuraEffect const* old = target->GetAuraEffect(id, EFFECT_0, caster->GetGUID()))
        total += uint64(std::max(0, old->GetAmount())) *
            std::max(0, old->GetTotalTicks() - int32(old->GetTickNumber()));
    int32 amount = int32(std::min<uint64>(total / ticks, std::numeric_limits<int32>::max()));
    caster->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, amount, target,
        TriggerCastFlags(TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET));
}

class aura_ascension_guardian_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_event);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        uint32 id = GetId();
        uint32 spell = event.GetSpellInfo() ? event.GetSpellInfo()->Id : 0;
        bool outgoing = event.GetActor() == owner;
        bool block = !outgoing && (event.GetHitMask() & (PROC_HIT_BLOCK | PROC_HIT_FULL_BLOCK));
        switch (id)
        {
            case 706807:
                return outgoing && Direct(event) && CastByPlayer(event) &&
                    (AscensionGuardian::Centurion(spell) || sSpellMgr->GetFirstSpellInChain(spell) == 805150);
            case 705379:
                return outgoing && Direct(event) && CastByPlayer(event) && (AscensionGuardian::HeavyBlow(spell) || spell == 802629);
            case 524694:
                return outgoing && Direct(event) && CastByPlayer(event) && AscensionGuardian::Ram(spell);
            case 804891:
                return !outgoing && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
            case 801121:
                return !outgoing && (block || (event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
                    (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL)));
            case 505202:
                return outgoing && Direct(event) && spell == 572612;
            case 582901:
            case 653386:
            case 653281:
            case 803432:
            case 706514:
                return block;
            case 653410:
                return block && owner->HealthBelowPct(75);
            case 707137:
                return block && owner->HasAura(800317);
            case 804383:
                return block || (outgoing && Direct(event));
            case 300927:
                return !outgoing && spell && ((event.GetHitMask() & PROC_HIT_REFLECT) || Direct(event));
            case 707170:
            case 802188:
            case 504910:
                return !outgoing && !(event.GetHitMask() & (PROC_HIT_EVADE | PROC_HIT_IMMUNE));
            case 560093:
                return !outgoing;
            case 503634:
                return outgoing && Direct(event) && spell != 573275 &&
                    (!event.GetProcSpell() || !event.GetProcSpell()->IsTriggered());
            case 803524:
                return outgoing && owner != GetCaster() && event.GetDamageInfo() &&
                    event.GetDamageInfo()->GetDamage() && spell != 572612 && spell != 575831;
            case 570759:
                return outgoing && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
                    spell != 572612 && spell != 575831;
            case 801774:
            case 524932:
            case 520651:
                return outgoing && Direct(event);
            case 653303:
                return outgoing && Direct(event) && (!spell || CastByPlayer(event));
            default:
                return false;
        }
    }

    void Proc(ProcEventInfo& event)
    {
        if (GetId() == 802188 || GetId() == 520651)
            return;
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* other = event.GetActor() == owner ? event.GetActionTarget() : event.GetActor();
        AuraEffect const* effect = GetEffect(EFFECT_0);
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        auto cast = [&](uint32 id, bool self = true)
        {
            Unit* target = self ? owner : other;
            if (target && target->IsAlive())
                owner->CastSpell(target, id, true, nullptr, effect);
        };
        switch (GetId())
        {
            case 706807:
            case 705379:
                if (other && other->IsAlive())
                    CarryBleed(owner, other, effect->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell, damage,
                        uint32(std::max(0, effect->GetAmount())));
                break;
            case 524694:
                if (other && other->IsAlive())
                {
                    int32 amount = int32(std::min<uint64>(uint64(damage) * std::max(0, effect->GetAmount()) / 100,
                        std::numeric_limits<int32>::max()));
                    owner->CastCustomSpell(effect->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell, SPELLVALUE_BASE_POINT0,
                        amount, other, TRIGGERED_FULL_MASK, nullptr, effect);
                }
                break;
            case 804891:
            {
                int64 amount = damage / 20;
                if (AuraEffect const* old = owner->GetAuraEffect(572158, EFFECT_0))
                    amount += old->GetAmount();
                amount = std::clamp<int64>(amount, 0, std::min<uint64>(owner->GetMaxHealth() / 5,
                    std::numeric_limits<int32>::max()));
                owner->CastCustomSpell(572158, SPELLVALUE_BASE_POINT0, int32(amount), owner,
                    TRIGGERED_FULL_MASK, nullptr, effect);
                break;
            }
            case 801121: cast(803135); break;
            case 505202: cast(803721, false); break;
            case 582901: cast(573212, false); break;
            case 653386: cast(803131, false); break;
            case 653410: cast(653305); break;
            case 653281: cast(653303); break;
            case 707137: cast(707140); break;
            case 804383: cast(804384); break;
            case 706514:
                AscensionGuardian::AddParagon(owner->ToPlayer(), 1);
                break;
            case 803432: cast(712295); break;
            case 300927:
                if (event.GetHitMask() & PROC_HIT_REFLECT)
                    Remove();
                else
                    cast(500493);
                break;
            case 707170:
                if (event.GetHitMask() & PROC_HIT_PARRY)
                    cast(707722, false);
                break;
            case 504910:
            case 653303:
                break;
            case 560093:
                if (Player* player = owner->ToPlayer())
                    player->ModifySpellCooldown(300983, -int32(player->GetSpellCooldownDelay(300983) / 10));
                break;
            case 503634:
                if (Unit* source = GetCaster())
                {
                    int32 amount = int32(source->GetTotalAttackPowerValue(BASE_ATTACK) * 0.28f);
                    if (other && other->IsAlive())
                        owner->CastCustomSpell(573275, SPELLVALUE_BASE_POINT0, amount, other,
                            TRIGGERED_FULL_MASK, nullptr, effect, source->GetGUID());
                }
                break;
            case 524932: cast(572714, false); break;
            case 801774:
            case 803524:
            case 570759:
                cast(572612);
                break;
            default:
                break;
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_guardian_event::Check);
        OnProc += AuraProcFn(aura_ascension_guardian_event::Proc);
    }
};

class spell_ascension_guardian_converted_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_guardian_converted_damage);

    void Damage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        int64 value = int64(GetSpellValue()->EffectBasePoints[index]) +
            (GetSpellInfo()->Effects[index].DieSides ? 1 : 0);
        SetHitDamage(int32(std::clamp<int64>(value, 0, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_guardian_converted_damage::Damage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class aura_ascension_guardian_converted_bleed : public AuraScript
{
    PrepareAuraScript(aura_ascension_guardian_converted_bleed);

    void Amount(AuraEffect const*, int32&, bool& recalculate)
    {
        recalculate = false;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_guardian_converted_bleed::Amount,
            EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

void CaptureGuardianEcho(Spell* spell)
{
    if (!spell || spell->IsTriggered())
        return;
    Unit* caster = spell->GetCaster();
    AuraEffect const* echo = caster->GetAuraEffect(801778, EFFECT_0);
    if (!echo)
        return;
    SpellInfo const* info = spell->GetSpellInfo();
    if (!info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) && !info->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE) &&
        !info->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL) && !info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) &&
        !info->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG) && !info->HasEffect(SPELL_EFFECT_HEALTH_LEECH))
        return;
    spell->SetScriptDamageEchoPercent(std::clamp(echo->GetAmount(), 0, 1000));
    caster->RemoveAurasDueToSpell(801778);
}

void ApplyGuardianEcho(Spell* spell, Unit* target, uint32 damage)
{
    if (!spell || !target || !target->IsAlive() || !damage || !spell->GetScriptDamageEchoPercent())
        return;
    Unit* caster = spell->GetCaster();
    if (!caster->IsValidAttackTarget(target))
        return;
    int32 amount = int32(std::min<uint64>(uint64(damage) * spell->GetScriptDamageEchoPercent() / 100,
        std::numeric_limits<int32>::max()));
    caster->CastCustomSpell(575831, SPELLVALUE_BASE_POINT0, amount, target, TRIGGERED_FULL_MASK);
}

class guardian_echo : public AllSpellScript
{
public:
    guardian_echo() : AllSpellScript("guardian_echo", { ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_HIT_RESULT }) { }

    void OnSpellBeforeEffects(Spell* spell, Unit*, SpellInfo const*) override
    {
        CaptureGuardianEcho(spell);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8, uint32 damage, uint32, bool) override
    {
        ApplyGuardianEcho(spell, target, damage);
    }
};
}

void AddAscensionGuardianEventScripts()
{
    RegisterSpellScript(aura_ascension_guardian_event);
    RegisterSpellScript(spell_ascension_guardian_converted_damage);
    RegisterSpellScript(aura_ascension_guardian_converted_bleed);
    new guardian_echo();
}
