/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBarbarianCompletion.h"
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
#include <limits>

namespace
{
using namespace AscensionBarbarian;

bool Damage(ProcEventInfo const& event)
{
    return event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
}

bool Direct(ProcEventInfo const& event)
{
    return Damage(event) && !(event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC));
}

bool Melee(ProcEventInfo const& event)
{
    return Direct(event) &&
        (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS));
}

bool Ranged(ProcEventInfo const& event)
{
    return Direct(event) &&
        (event.GetTypeMask() & (PROC_FLAG_DONE_RANGED_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS) ||
        Family(event.GetSpellInfo(), 1, 8));
}

void Bleed(Unit* owner, Unit* target, uint32 id, uint32 damage, uint32 percent)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
    if (!target || !target->IsAlive() || !info || !info->Effects[EFFECT_0].Amplitude || info->GetDuration() <= 0)
        return;
    uint32 ticks = info->GetDuration() / info->Effects[EFFECT_0].Amplitude;
    uint64 total = uint64(damage) * percent / 100;
    if (AuraEffect const* old = target->GetAuraEffect(id, EFFECT_0, owner->GetGUID()))
        total += uint64(std::max(0, old->GetAmount())) *
            std::max(0, old->GetTotalTicks() - int32(old->GetTickNumber()));
    int32 value = int32(std::min<uint64>(total / std::max(1u, ticks), std::numeric_limits<int32>::max()));
    owner->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, value, target,
        TriggerCastFlags(TRIGGERED_FULL_MASK & ~TRIGGERED_NO_PERIODIC_RESET));
}

class aura_ascension_ancestral_evolution : public AuraScript
{
    PrepareAuraScript(aura_ascension_ancestral_evolution);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == 806229 && info->SpellFamilyName == 18 &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY);
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Player* caster = Owner(GetCaster());
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* attacker = damage ? damage->GetAttacker() : nullptr;
        SpellInfo const* source = event.GetSpellInfo();
        return caster && owner->IsAlive() && attacker && attacker->IsAlive() && attacker != owner &&
            owner->IsValidAttackTarget(attacker) && damage->GetDamage() && (!source || source->Id != GetId());
    }

    void Reflect(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* attacker = damage->GetAttacker();
        uint32 const amount = uint32(uint64(damage->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100);
        if (!amount || attacker->IsImmunedToDamage(damage->GetSchoolMask()))
            return;
        uint32 const dealt = Unit::DealDamage(owner, attacker, amount, nullptr, SPELL_DIRECT_DAMAGE,
            damage->GetSchoolMask(), GetSpellInfo(), false);
        owner->SendSpellNonMeleeDamageLog(attacker, GetSpellInfo(), dealt, damage->GetSchoolMask(), 0, 0, false, 0);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ancestral_evolution::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ancestral_evolution::Reflect, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_barbarian_event : public AuraScript
{
    PrepareAuraScript(aura_ascension_barbarian_event);
    ObjectGuid _challenge;
    bool _executing = false;
    int32 _startingDuration = -1;
    int32 _extensionUsed = 0;

    void ExtendLimited(int32 amount, int32 cap)
    {
        Aura* aura = GetAura();
        if (!aura || aura->GetDuration() <= 0)
            return;
        if (_startingDuration < 0)
            _startingDuration = aura->GetMaxDuration();
        int32 granted = std::min(amount, std::max(0, cap - _startingDuration - _extensionUsed));
        _extensionUsed += granted;
        int32 duration = aura->GetDuration() + granted;
        aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
        aura->SetDuration(duration);
    }

    void ResetExtension(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (effect->GetEffIndex() == EFFECT_0)
        {
            _startingDuration = -1;
            _extensionUsed = 0;
        }
    }

    bool Check(ProcEventInfo& event)
    {
        if (_executing)
            return false;
        Unit* owner = GetTarget();
        uint32 id = GetId();
        Player* player = Owner(owner);
        bool ale = id == 805780 || id == 573064 || id == 573224 || id == 573225 || id == 573077;
        if (!player && !ale && id != 805804)
            return false;
        bool outgoing = event.GetActor() == owner;
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        SpellInfo const* info = event.GetSpellInfo();
        uint32 sid = info ? info->Id : 0;
        Unit* other = event.GetActionTarget();
        if (ale)
            return outgoing && Direct(event) &&
                (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) && other != owner;
        switch (id)
        {
            case 707389: return outgoing && Direct(event) && critical && Family(info, 0, 1024);
            case 800131: return outgoing && (event.GetTypeMask() & PROC_FLAG_KILL);
            case 560880: return outgoing && Direct(event) && sid == 520577;
            case 300499: return outgoing && Direct(event) && critical && Family(info, 1, 2048);
            case 801549:
            case 560364:
            case 707764: return !outgoing && Direct(event);
            case 705240: return outgoing && Direct(event) && (event.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
            case 804745: return outgoing && Direct(event) && Family(info, 1, 64);
            case 804746: return outgoing && Direct(event) && (sid == 500919 || (sid >= 504912 && sid <= 504916));
            case 520539: return outgoing && Melee(event);
            case 805997: return outgoing && Direct(event) && critical && Spear(info);
            case 805893: return outgoing && Direct(event) && sid == 255846;
            case 705238: return outgoing && Damage(event) && info &&
                (info->GetAllEffectsMechanicMask() & (1u << MECHANIC_BLEED));
            case 560450:
            case 573256:
            case 705162: return outgoing && Damage(event) && critical;
            case 800943: return outgoing && Direct(event) && owner->HealthBelowPct(35) &&
                (!info || Family(info, 1, 1048576 | 262144));
            case 560939: return outgoing && Direct(event) && sid == 800152;
            case 561360: return outgoing && Damage(event) && critical && other && other != owner &&
                (other->HealthAbovePct(80) || other->HealthBelowPct(20));
            case 712673:
            case 705158: return outgoing && Direct(event) && Family(info, 1, 16777216);
            case 807861: return outgoing && ((event.GetTypeMask() & PROC_FLAG_KILL) ||
                (Direct(event) && critical && !player->HasSpellCooldown(807861)));
            case 805811: return outgoing && Direct(event) && (Family(info, 1, 1) || sid == 805809);
            case 805804: return outgoing && Direct(event) && (event.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK);
            case 706354: return outgoing && Direct(event) && info && critical;
            case 801782: return outgoing && Direct(event) && sid != 801783 &&
                (event.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
            case 706804: return outgoing && Direct(event) && Spear(info);
            case 561397: return outgoing && Ranged(event) && critical && Enraged(owner) && !owner->HasAura(804141);
            case 705211: return outgoing && Damage(event) && critical &&
                (event.GetSchoolMask() & SPELL_SCHOOL_MASK_FROST);
            case 560586:
            case 561332: return outgoing && info && Family(info, 0, 262144) && other && other != owner;
            case 706821: return outgoing && Melee(event);
            case 705214: return outgoing && Direct(event) && Family(info, 1, 134217728);
            case 805821: return !outgoing && Damage(event) && owner->GetHealthPct() <= 35.0f;
            case 704240: return outgoing && Direct(event) && (sid == 800628 || sid == 355597);
            case 500061: return event.GetHealInfo() && event.GetHealInfo()->GetTarget() == owner &&
                event.GetHealInfo()->GetEffectiveHeal() && Ancestor(player);
            case 801759:
            case 803499: return outgoing && Damage(event) && critical &&
                (event.GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
            case 804141: return outgoing && info && Ranged(event) && sid != 520518 &&
                !(event.GetTypeMask() & PROC_FLAG_DONE_RANGED_AUTO_ATTACK) && event.GetProcSpell() &&
                event.GetProcSpell()->TryMarkScriptEventHandled(27);
            case 712468: return outgoing && (event.GetTypeMask() & PROC_FLAG_KILL);
            default: return false;
        }
    }

    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        _executing = true;
        Unit* owner = GetTarget();
        Player* player = Owner(owner);
        Unit* other = event.GetActor() == owner ? event.GetActionTarget() : event.GetActor();
        uint32 id = GetId();
        uint32 damage = event.GetDamageInfo() ? event.GetDamageInfo()->GetDamage() : 0;
        bool critical = event.GetHitMask() & PROC_HIT_CRITICAL;
        auto cast = [&](uint32 sid, bool self = true)
        {
            Unit* target = self ? owner : other;
            if (target && target->IsAlive())
                owner->CastSpell(target, sid, true, nullptr, GetEffect(EFFECT_0));
        };
        switch (id)
        {
            case 707389:
            case 801549:
            case 800943:
            case 712468: cast(560521); break;
            case 800131: cast(802760); break;
            case 560880:
                cast(561019, false);
                if (critical)
                    cast(561019, false);
                break;
            case 300499: Bleed(owner, other, 783054, damage, 30); break;
            case 705240: cast(706393); break;
            case 804745: cast(570739, false); break;
            case 804746: cast(560916); break;
            case 520539:
                owner->CastCustomSpell(524675, SPELLVALUE_BASE_POINT0, int32(damage / 10), owner, TRIGGERED_FULL_MASK);
                cast(524684);
                break;
            case 560364: cast(561312); break;
            case 805997: cast(804143, false); break;
            case 805893: Bleed(owner, other, 782801, damage, 100); break;
            case 705238: cast(783102); break;
            case 560450: cast(705188); break;
            case 560939: cast(560937, false); break;
            case 561360:
                if (Unit* previous = ObjectAccessor::GetUnit(*owner, _challenge))
                {
                    previous->RemoveAurasDueToSpell(801753, owner->GetGUID());
                    previous->RemoveAurasDueToSpell(803908, owner->GetGUID());
                }
                _challenge = other->GetGUID();
                cast(other->HealthAbovePct(80) ? 803908 : 801753, false);
                break;
            case 573256: cast(560821); break;
            case 712673: cast(803513, false); break;
            case 807861:
                if (event.GetTypeMask() & PROC_FLAG_KILL)
                    Extend(owner, 801761, 500);
                else
                {
                    Extend(owner, 801761, 500);
                    player->AddSpellCooldown(807861, 0, 1000);
                }
                break;
            case 805811: cast(583020, false); break;
            case 805804: ExtendLimited(2000, sSpellMgr->GetSpellInfo(805807)->GetDuration()); break;
            case 706354: cast(562323); break;
            case 801782:
                cast(801783, false);
                if (owner->HasAura(500061))
                    cast(805813);
                if (owner->HasAura(804768) && Ancestor(player))
                    cast(804769);
                break;
            case 706804:
                owner->CastCustomSpell(707660, SPELLVALUE_BASE_POINT0,
                    int32(uint64(damage) * 40 / 100), other, TRIGGERED_FULL_MASK);
                break;
            case 561397: cast(804141); break;
            case 705211:
            case 706821:
                if (owner->HasAura(500061))
                    cast(805813);
                break;
            case 560586: cast(560626, false); break;
            case 561332: cast(561333, false); break;
            case 705162: Extend(owner, 560946, 1000); break;
            case 705158: Bleed(owner, other, 300870, damage, 30); break;
            case 705214: cast(560125, false); break;
            case 805821: cast(805822); break;
            case 704240: cast(800645); break;
            case 500061:
                if (Unit* pet = Ancestor(player))
                    owner->CastCustomSpell(500534, SPELLVALUE_BASE_POINT0,
                        int32(uint64(event.GetHealInfo()->GetEffectiveHeal()) * 30 / 100), pet, TRIGGERED_FULL_MASK);
                break;
            case 801759:
            case 803499: ExtendLimited(1000, owner->HasAura(300497) ? 20000 : 10000); break;
            case 804141:
            {
                float chance = 20.0f;
                player->ApplySpellMod(id, SPELLMOD_CHANCE_OF_SUCCESS, chance);
                if (roll_chance_f(chance))
                    cast(520518, false);
                cast(572531);
                break;
            }
            case 707764: cast(525010); break;
            case 805780:
            case 573064:
            case 573224:
            case 573225:
            case 573077:
                if (Unit* caster = GetCaster())
                {
                    uint32 child = GetSpellInfo()->Effects[EFFECT_0].TriggerSpell;
                    SpellInfo const* helper = sSpellMgr->GetSpellInfo(child);
                    int32 base = id == 573077 ? GetEffect(EFFECT_0)->GetAmount() :
                        helper ? helper->Effects[EFFECT_0].CalcValue(caster) : 0;
                    int32 value = base + int32(caster->GetTotalAttackPowerValue(BASE_ATTACK) * 0.2f);
                    owner->CastCustomSpell(805785, SPELLVALUE_BASE_POINT0, value, other,
                        TRIGGERED_FULL_MASK, nullptr, GetEffect(EFFECT_0), caster->GetGUID());
                }
                break;
            default: break;
        }
        _executing = false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_barbarian_event::Check);
        OnProc += AuraProcFn(aura_ascension_barbarian_event::Proc);
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_barbarian_event::ResetExtension,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class spell_ascension_barbarian_conversion : public SpellScript
{
    PrepareSpellScript(spell_ascension_barbarian_conversion);

    void Convert(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        int32 value = GetSpellValue()->EffectBasePoints[index] + (GetSpellInfo()->Effects[index].DieSides ? 1 : 0);
        if (GetSpellInfo()->Effects[index].Effect == SPELL_EFFECT_HEAL)
            SetHitHeal(std::max(0, value));
        else
            SetHitDamage(std::max(0, value));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_barbarian_conversion::Convert,
            EFFECT_0, SPELL_EFFECT_ANY);
    }
};

class aura_ascension_barbarian_bleed : public AuraScript
{
    PrepareAuraScript(aura_ascension_barbarian_bleed);

    void Amount(AuraEffect const*, int32&, bool& recalculate) { recalculate = false; }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_barbarian_bleed::Amount,
            EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

class barbarian_grisly_meal : public PlayerScript
{
public:
    barbarian_grisly_meal() : PlayerScript("barbarian_grisly_meal",
        {PLAYERHOOK_ON_PVP_KILL, PLAYERHOOK_ON_CREATURE_KILL}) { }

    void OnPlayerPVPKill(Player* killer, Player* killed) override { Reward(killer, killed); }
    void OnPlayerCreatureKill(Player* killer, Creature* killed) override { Reward(killer, killed); }

private:
    static void Reward(Player* player, Unit* killed)
    {
        if (player->getClass() != CLASS_BARBARIAN || !player->isHonorOrXPTarget(killed))
            return;
        for (uint32 rank : {804765u, 807946u, 807947u, 807948u})
            if (player->HasSpell(rank))
            {
                player->CastSpell(player, 804755, true);
                return;
            }
    }
};

class barbarian_killing_spree : public PlayerScript
{
public:
    barbarian_killing_spree() : PlayerScript("barbarian_killing_spree",
        {PLAYERHOOK_ON_PVP_KILL, PLAYERHOOK_ON_CREATURE_KILL}) { }

    void OnPlayerPVPKill(Player* killer, Player*) override { Ready(killer); }
    void OnPlayerCreatureKill(Player* killer, Creature*) override { Ready(killer); }

private:
    static void Ready(Player* player)
    {
        if (Player* barbarian = Owner(player))
            ReadyToKill(barbarian);
    }
};
}

void AddAscensionBarbarianEventScripts()
{
    RegisterSpellScript(aura_ascension_barbarian_event);
    RegisterSpellScript(aura_ascension_ancestral_evolution);
    RegisterSpellScript(spell_ascension_barbarian_conversion);
    RegisterSpellScript(aura_ascension_barbarian_bleed);
    new barbarian_grisly_meal();
    new barbarian_killing_spree();
}
