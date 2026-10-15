/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterCompletion.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
using namespace AscensionWitchHunter;

constexpr uint8 DESECRATE_SHADOWSTORM_EVENT = 22;

bool Damage(ProcEventInfo const& event)
{
    return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
}

bool Direct(ProcEventInfo const& event)
{
    return Damage(event) && !(event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC));
}

bool Ranged(ProcEventInfo const& event)
{
    return Direct(event) &&
           (event.GetTypeMask() & (PROC_FLAG_DONE_RANGED_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS));
}

bool Extra(SpellInfo const* info)
{
    if (!info)
        return false;
    switch (info->Id)
    {
        case 500159:
        case 681392:
        case 681489:
        case 567570:
        case 680532:
        case 807262:
        case 802850:
        case 681415:
        case 520265:
        case 804025:
            return true;
        default:
            return false;
    }
}

bool HasOwnedTormentor(Unit* target, ObjectGuid caster)
{
    for (auto const& [key, application] : target->GetAppliedAuras())
        if (Aura* aura = application->GetBase(); aura->GetCasterGUID() == caster &&
            Family(aura->GetSpellInfo(), 2, 268435456))
            return true;
    return false;
}

void CarryDamage(Unit* caster, Unit* target, uint32 id, uint64 amount)
{
    if (!caster || !target)
        return;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    uint32 ticks = std::max(1, info->GetDuration() / int32(info->Effects[EFFECT_0].Amplitude));
    if (AuraEffect* previous = target->GetAuraEffect(id, EFFECT_0, caster->GetGUID()))
        amount += uint64(std::max(0, previous->GetAmount())) *
                  std::max(0, int32(previous->GetTotalTicks()) - int32(previous->GetTickNumber()));
    caster->CastCustomSpell(id, SPELLVALUE_BASE_POINT0,
                            int32(std::min<uint64>(amount / ticks, std::numeric_limits<int32>::max())), target,
                            TriggerCastFlags(TRIGGERED_FULL_MASK | TRIGGERED_NO_PERIODIC_RESET));
}

void StrikeShadowRage(Unit* attacker, AuraEffect* rage, Unit* target)
{
    Player* caster = Owner(rage->GetCaster());
    if (!caster)
        return;
    uint32 stacks = std::max<uint32>(1, rage->GetBase()->GetStackAmount());
    int32 value = rage->GetAmount() + int32(stacks * caster->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.15f);
    attacker->CastCustomSpell(567570, SPELLVALUE_BASE_POINT0, value, target, TRIGGERED_FULL_MASK, nullptr, rage,
                              caster->GetGUID());
}

void CleaveShadowRage(Unit* hound, Unit* target, ProcEventInfo& event)
{
    Aura* rage = hound->GetAura(804192);
    SpellProcEntry const* proc = sSpellMgr->GetSpellProcEntry(804192);
    if (rage && proc && roll_chance_f(rage->CalcProcChance(*proc, event)))
        StrikeShadowRage(hound, rage->GetEffect(EFFECT_2), target);
}

class aura_ascension_witch_hunter_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_hunter_event);
    bool _executing = false;
    std::array<uint32, 3> _health = {};
    uint32 _nextHealth = 0;

    bool Check(ProcEventInfo& event)
    {
        if (_executing)
            return false;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        uint32 id = GetId();
        if (!player && id != 804192 && id != 562027 && id != 570726)
            return false;
        bool outgoing = event.GetActor() == owner;
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        bool avoid = event.GetHitMask() & (PROC_HIT_DODGE | PROC_HIT_PARRY);
        SpellInfo const* info = event.GetSpellInfo();
        if (outgoing && Extra(info))
            return false;
        bool autoMelee = event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK;
        bool autoRanged = event.GetTypeMask() & PROC_FLAG_DONE_RANGED_AUTO_ATTACK;
        switch (id)
        {
            case 681181:
                return (!outgoing && avoid) ||
                       (critical && ((!outgoing && Direct(event) && (event.GetSchoolMask() & 126)) ||
                                     (outgoing && Direct(event) && info && !autoMelee && !autoRanged &&
                                      player->HasSpell(804193))));
            case 92091:
            case 804404:
                return outgoing && Ranged(event);
            case 92093:
                return outgoing && Direct(event) && autoRanged;
            case 705496:
                return outgoing && Damage(event) && critical;
            case 560207:
                return outgoing && Direct(event) && Family(info, 1, 1073741824) && info && info->Id != 520865 &&
                       roll_chance_i(GetSpellInfo()->ProcChance +
                                     (owner->HasAura(803422)
                                          ? sSpellMgr->GetSpellInfo(803422)->Effects[EFFECT_2].CalcValue(owner)
                                          : 0));
            case 504470:
                return outgoing && Direct(event) && critical && Family(info, 2, 1024) && event.GetProcSpell() &&
                       event.GetProcSpell()->TryMarkScriptEventHandled(28);
            case 705515:
                return outgoing && Ranged(event) && critical && info && !autoRanged;
            case 705531:
                return outgoing && Direct(event) && autoRanged && critical;
            case 504742:
                return outgoing && Damage(event) && (event.GetSchoolMask() & SPELL_SCHOOL_MASK_SHADOW);
            case 707064:
            case 707860:
                return outgoing && Direct(event) && autoMelee && player->IsTwoHandUsed();
            case 503659:
                return !outgoing && (event.GetHitMask() & PROC_HIT_PARRY);
            case 680516:
                return outgoing && Direct(event) && info && !autoMelee && !autoRanged;
            case 805346:
                return outgoing && Direct(event) && info && player->IsTwoHandUsed() && event.GetProcSpell() &&
                       event.GetProcSpell()->TryMarkScriptEventHandled(29);
            case 680528:
            case 680504:
            case 680530:
            case 806188:
                return outgoing && Direct(event) && Dawn(info);
            case 680599:
                return outgoing && Direct(event) && critical && (event.GetSchoolMask() & 1);
            case 680544:
                return outgoing && Direct(event) && autoMelee;
            case 680538:
                return outgoing && Direct(event) && (Dusk(info) || (info && info->Id == 803502));
            case 520277:
                if (outgoing && Direct(event) && Desecrate(info))
                {
                    if (Spell const* spell = event.GetProcSpell();
                        spell && spell->TryMarkScriptEventHandled(DESECRATE_SHADOWSTORM_EVENT))
                        Cast(owner, event.GetActionTarget(), 520278);
                    return false;
                }
                return outgoing && Direct(event) && Family(info, 2, 33554432);
            case 681092:
                return !outgoing && Direct(event) && (event.GetSchoolMask() & 126);
            case 680497:
                return (!outgoing && avoid) || (outgoing && Direct(event) && autoMelee);
            case 524970:
                return outgoing && Direct(event) && critical && Family(info, 0, 65536);
            case 503681:
                return outgoing && Direct(event) && (Heartseeking(info) || Family(info, 2, 32));
            case 503680:
                return outgoing && Direct(event) && info && info->Id == 805753;
            case 706260:
                return outgoing && Direct(event) && critical;
            case 705484:
                return outgoing && Damage(event) && (event.GetSchoolMask() & SPELL_SCHOOL_MASK_FIRE);
            case 300571:
                return outgoing && Damage(event) && (event.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
            case 681329:
            case 681488:
                return outgoing && Direct(event) && autoMelee && event.GetDamageInfo()->GetAttackType() == OFF_ATTACK;
            case 806195:
                return !outgoing && avoid;
            case 804024:
                return outgoing && Direct(event) && info && !autoMelee && !autoRanged;
            case 681152:
                return !outgoing && Direct(event) && critical && (event.GetSchoolMask() & (32 | 64));
            case 705534:
                return !outgoing && (Direct(event) || avoid);
            case 139778:
                return outgoing && Ranged(event);
            case 680275:
                return outgoing && Direct(event) && autoRanged;
            case 804192:
            case 562027:
            case 570726:
                return outgoing && Direct(event) && autoMelee;
            case 578336:
                return event.GetHealInfo() && event.GetHealInfo()->GetTarget() == owner &&
                       event.GetHealInfo()->GetEffectiveHeal() && Hound(player);
            default:
                return false;
        }
    }

    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        _executing = true;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        Unit* other = event.GetActor() == owner ? event.GetActionTarget() : event.GetActor();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        auto self = [&](uint32 id) { Cast(owner, owner, id); };
        switch (GetId())
        {
            case 681181:
                if (event.GetActor() == owner)
                    self(680244);
                else
                {
                    if (event.GetHitMask() & (PROC_HIT_DODGE | PROC_HIT_PARRY))
                        self(803166);
                    if ((event.GetHitMask() & PROC_HIT_CRITICAL) && player->HasSpell(805770))
                        self(805771);
                }
                break;
            case 92091:
                Cast(owner, other, 500159);
                self(504247);
                break;
            case 92093:
                owner->EnergizeBySpell(owner, 92093, 50, POWER_RAGE);
                break;
            case 804404:
                self(500161);
                break;
            case 705496:
                self(504690);
                break;
            case 560207:
            case 503681:
            case 503680:
                owner->CastSpell(other, event.GetSpellInfo()->Id, true, nullptr, GetEffect(EFFECT_0));
                break;
            case 504470:
                owner->EnergizeBySpell(owner, GetId(), std::max(0, event.GetProcSpell()->GetPowerCost()) / 2,
                                       Powers(event.GetSpellInfo()->PowerType));
                break;
            case 705515:
                if (other)
                    for (auto const& [key, application] : other->GetAppliedAuras())
                    {
                        Aura* aura = application->GetBase();
                        if (aura->GetCasterGUID() != owner->GetGUID() || !Family(aura->GetSpellInfo(), 2, 268435456))
                            continue;
                        AuraEffect const* dot = aura->GetEffect(EFFECT_0);
                        if (!dot)
                            continue;
                        for (Unit* target : Nearby(other, 10.0f))
                            if (target != other && owner->IsValidAttackTarget(target) &&
                                !HasOwnedTormentor(target, owner->GetGUID()))
                            {
                                if (Aura* copy = owner->AddAura(aura->GetId(), target))
                                {
                                    copy->SetDuration(aura->GetDuration());
                                    if (AuraEffect* copied = copy->GetEffect(EFFECT_0))
                                    {
                                        copied->ChangeAmount(dot->GetAmount());
                                        copied->SetPeriodicTimer(dot->GetPeriodicTimer());
                                    }
                                    break;
                                }
                            }
                        break;
                    }
                break;
            case 705531:
                for (Unit* pet : Nearby(owner, 60.0f))
                    if ((pet->GetEntry() == 50124 || pet->GetEntry() == 50224) &&
                        pet->GetOwnerGUID() == owner->GetGUID())
                        Cast(owner, pet, 573266);
                break;
            case 504742:
                self(500566);
                break;
            case 707064:
            case 707860:
                Cast(owner, other, 680483);
                break;
            case 503659:
            {
                uint32 heal = (owner->GetMaxHealth() - owner->GetHealth()) / 20;
                owner->CastCustomSpell(574335, SPELLVALUE_BASE_POINT0, int32(heal), owner, TRIGGERED_FULL_MASK);
                owner->EnergizeBySpell(owner, GetId(),
                                       (owner->GetMaxPower(POWER_RAGE) - owner->GetPower(POWER_RAGE)) / 20, POWER_RAGE);
                break;
            }
            case 680516:
                Cast(owner, other, 680517);
                break;
            case 805346:
                for (auto const& [id, state] : player->GetSpellMap())
                    if (state->State != PLAYERSPELL_REMOVED && Family(sSpellMgr->GetSpellInfo(id), 2, 512))
                        player->ModifySpellCooldown(id, -1000);
                self(805347);
                break;
            case 680528:
            {
                Cast(owner, other, 680517);
                SpellInfo const* dot = sSpellMgr->GetSpellInfo(680532);
                uint32 ticks = std::max(1, dot->GetDuration() / int32(dot->Effects[EFFECT_0].Amplitude));
                CarryDamage(owner, other, 680532,
                            uint64(damage) * std::max(0, GetEffect(EFFECT_1)->GetAmount()) / 100 * ticks);
                break;
            }
            case 680504:
                if (owner->HealthBelowPct(75))
                    self(680495);
                break;
            case 680530:
            {
                _health[_nextHealth++ % _health.size()] = damage * 15ull / 100;
                uint32 sum = _health[0] + _health[1] + _health[2];
                if (!owner->HasAura(524669))
                {
                    _health = {uint32(damage * 15ull / 100), 0, 0};
                    sum = _health[0];
                    _nextHealth = 1;
                }
                owner->CastCustomSpell(524669, SPELLVALUE_BASE_POINT0, int32(sum), owner, TRIGGERED_FULL_MASK);
                break;
            }
            case 680599:
                self(1257670);
                break;
            case 680544:
                Cast(owner, other, event.GetDamageInfo()->GetAttackType() == OFF_ATTACK ? 681523 : 681413);
                break;
            case 680538:
                self(680539);
                break;
            case 520277:
                Cast(owner, other, 520278);
                break;
            case 681092:
            {
                int32 value = int32(damage * 3ull / 100);
                owner->CastCustomSpell(681270, SPELLVALUE_BASE_POINT0, value, owner, TRIGGERED_FULL_MASK);
                owner->EnergizeBySpell(owner, 681270, value, POWER_MANA);
                break;
            }
            case 680497:
                self(681390);
                break;
            case 806188:
                CarryDamage(owner, other, 807262, damage);
                break;
            case 524970:
                self(524815);
                break;
            case 706260:
                Cast(owner, Hound(player), 800528);
                break;
            case 705484:
            case 300571:
                self(GetId() == 705484 ? 503658 : 504713);
                if (owner->HasAura(503664))
                {
                    Aura* dawn = owner->GetAura(503658);
                    Aura* dusk = owner->GetAura(504713);
                    if (dawn && dusk && dawn->GetStackAmount() >= 20 && dusk->GetStackAmount() >= 20)
                    {
                        owner->RemoveAurasDueToSpell(503658);
                        owner->RemoveAurasDueToSpell(504713);
                        self(504790);
                    }
                }
                break;
            case 681329:
            case 681488:
                Cast(owner, other, 681392);
                Cast(owner, other, 681392);
                self(1257670);
                break;
            case 806195:
                self(806194);
                break;
            case 804024:
                Cast(owner, other, 804025);
                break;
            case 681152:
                player->ModifySpellCooldown(805770, -10000);
                break;
            case 705534:
                Cast(owner, other, 520265);
                break;
            case 139778:
                Reset(player, 802273);
                break;
            case 680275:
            case 804192:
                StrikeShadowRage(owner, GetEffect(EFFECT_2), other);
                break;
            case 562027:
            case 570726:
                if (Unit* caster = GetCaster())
                    for (Unit* target : Nearby(other, 5.0f))
                        if (target != other && owner->IsValidAttackTarget(target))
                        {
                            owner->CastCustomSpell(567570, SPELLVALUE_BASE_POINT0, int32(damage), target,
                                                   TRIGGERED_FULL_MASK, nullptr, GetEffect(EFFECT_0),
                                                   caster->GetGUID());
                            CleaveShadowRage(owner, target, event);
                            break;
                        }
                break;
            case 578336:
                if (Unit* pet = Hound(player))
                    owner->CastCustomSpell(574335, SPELLVALUE_BASE_POINT0,
                                           int32(event.GetHealInfo()->GetEffectiveHeal() *
                                                 uint64(std::max(0, GetEffect(EFFECT_0)->GetAmount())) / 100),
                                           pet, TRIGGERED_FULL_MASK);
                break;
        }
        _executing = false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_witch_hunter_event::Check);
        OnProc += AuraProcFn(aura_ascension_witch_hunter_event::Proc);
    }
};
}

void AddAscensionWitchHunterEventScripts()
{
    RegisterSpellScript(aura_ascension_witch_hunter_event);
}
