/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionChronomancerTalents.h"
#include "Group.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <vector>

namespace
{
enum ChronomancerTalentSpells : uint32
{
    SPELL_ROLL_BACK = 804490,
    SPELL_TIME_SKIP = 804451,
    SPELL_SHIMMERING_SHARD = 806302,
    SPELL_SHIMMER = 806303,
    SPELL_THROUGH_THE_AEONS = 560310,
    SPELL_THROUGH_THE_AEONS_BUFF = 560311,
    SPELL_AEON_RENEWAL = 806290,
    SPELL_AEON_RESILIENCE = 806291,
    SPELL_AEON_PROTECTION = 806292,
    SPELL_AEON_OBLIVION = 806293,
    SPELL_DIMENSIONAL_DIVERGENCE = 802790,
    SPELL_DIVERGENCE_SLOW = 803301,
    SPELL_DIVERGENCE_SPEED = 803703,
    SPELL_UNMAKER_OF_REALITIES = 706107,
    SPELL_HASTEN = 801304,
    SPELL_HASTEN_STRIKE_SOURCE = 803382,
    SPELL_HASTY_STRIKE = 803706,
    SPELL_TIMEGUARD = 804441,
    SPELL_MARK_OF_ORDER_ADD_STACK = 806270,
    SPELL_IDEAL_TIME_BUFF = 807210,
    SPELL_NOZDORMUS_GAZE = 807691,
    SPELL_DESTABILIZE_TIME_SLOW = 570761,
    SPELL_THE_VAST_INFINITE = 706083,
    SPELL_THE_VAST_INFINITE_SHARE = 707600,
    SPELL_THE_VAST_INFINITE_HEAL = 707601
};

constexpr uint32 TimeguardHeavyHitPercent = 20;
constexpr uint16 AscensionReduceRemainingCooldownPctEffect = 192;

bool IsAeonActivation(uint32 id)
{
    return id == SPELL_AEON_RENEWAL || id == SPELL_AEON_RESILIENCE ||
        id == SPELL_AEON_PROTECTION || id == SPELL_AEON_OBLIVION;
}

bool CanSwapPlayers(Player* player, Player* target)
{
    if (!player || !target || player == target || player->getClass() != CLASS_CHRONOMANCER ||
        !player->IsAlive() || !target->IsAlive() || !player->IsInWorld() || !target->IsInWorld() ||
        player->GetMap() != target->GetMap() || !player->InSamePhase(target))
        return false;
    if (player->IsBeingTeleported() || target->IsBeingTeleported() || player->IsInFlight() || target->IsInFlight() ||
        player->GetTransport() || target->GetTransport() || player->GetVehicle() || target->GetVehicle())
        return false;
    return player->IsWithinLOSInMap(target) &&
        (player->IsValidAttackTarget(target) || player->IsValidAssistTarget(target));
}

class spell_ascension_dimensional_divergence : public SpellScript
{
    PrepareSpellScript(spell_ascension_dimensional_divergence);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_DIVERGENCE_SLOW, SPELL_DIVERGENCE_SPEED});
    }

    SpellCastResult CheckSwap()
    {
        Unit* target = GetExplTargetUnit();
        return CanSwapPlayers(GetCaster()->ToPlayer(), target ? target->ToPlayer() : nullptr)
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    void Swap(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* hit = GetHitUnit();
        Player* target = hit ? hit->ToPlayer() : nullptr;
        if (!CanSwapPlayers(player, target))
            return;
        Position origin = player->GetPosition();
        Position destination = target->GetPosition();
        bool hostile = player->IsValidAttackTarget(target);
        target->NearTeleportTo(origin);
        player->NearTeleportTo(destination, true);
        if (hostile)
        {
            player->CastSpell(target, SPELL_DIVERGENCE_SLOW, true);
            if (target->HasAura(SPELL_DIVERGENCE_SLOW, player->GetGUID()))
                player->CastSpell(player, SPELL_DIVERGENCE_SPEED, true);
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_dimensional_divergence::CheckSwap);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_dimensional_divergence::Swap, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_unmaker_of_realities : public AuraScript
{
    PrepareAuraScript(spell_ascension_unmaker_of_realities);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_HASTEN_STRIKE_SOURCE, SPELL_HASTY_STRIKE});
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!caster || caster->getClass() != CLASS_CHRONOMANCER || !caster->HasSpell(SPELL_UNMAKER_OF_REALITIES))
            return false;
        DamageInfo* damage = eventInfo.GetDamageInfo();
        if (!damage || !damage->GetDamage() || !eventInfo.GetActionTarget())
            return false;
        SpellInfo const* procSpell = eventInfo.GetSpellInfo();
        return !procSpell || procSpell->Id != SPELL_HASTY_STRIKE;
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        Unit* striker = GetTarget();
        Unit* victim = eventInfo.GetActionTarget();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        SpellInfo const* source = sSpellMgr->GetSpellInfo(SPELL_HASTEN_STRIKE_SOURCE);
        if (!striker || !victim || !damage || !source)
            return;
        int32 percent = std::clamp(source->Effects[EFFECT_0].CalcValue(), 0, 100);
        uint64 amount = uint64(damage->GetDamage()) * uint64(percent) / 100;
        if (!amount)
            return;
        striker->CastCustomSpell(SPELL_HASTY_STRIKE, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, uint64(std::numeric_limits<int32>::max()))), victim, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_unmaker_of_realities::CheckProc);
        OnProc += AuraProcFn(spell_ascension_unmaker_of_realities::HandleProc);
    }
};

class spell_ascension_destabilize_time : public AuraScript
{
    PrepareAuraScript(spell_ascension_destabilize_time);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_DESTABILIZE_TIME_SLOW});
    }

    void MatchSlow(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (!caster || !target)
            return;
        Aura* slow = target->GetAura(SPELL_DESTABILIZE_TIME_SLOW, caster->GetGUID());
        if (!slow)
            slow = caster->AddAura(SPELL_DESTABILIZE_TIME_SLOW, target);
        if (!slow)
            return;
        slow->SetMaxDuration(GetMaxDuration());
        slow->SetDuration(GetDuration());
        if (slow->GetStackAmount() != GetStackAmount())
            slow->SetStackAmount(GetStackAmount());
    }

    void RemoveSlow(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_DESTABILIZE_TIME_SLOW, GetCasterGUID());
    }

    void GainStackOnCast(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (uint32(GetStackAmount()) < GetSpellInfo()->StackAmount)
            GetAura()->SetStackAmount(uint8(GetStackAmount() + 1));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_destabilize_time::MatchSlow, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_destabilize_time::RemoveSlow, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        OnEffectProc += AuraEffectProcFn(spell_ascension_destabilize_time::GainStackOnCast, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_timeguard : public AuraScript
{
    PrepareAuraScript(spell_ascension_timeguard);

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        Unit* target = GetTarget();
        AuraEffect const* threshold = GetEffect(EFFECT_1);
        AuraEffect const* reduction = GetEffect(EFFECT_2);
        if (!target || !threshold || !reduction)
            return;
        if (damage.GetDamageType() != DIRECT_DAMAGE && damage.GetDamageType() != SPELL_DIRECT_DAMAGE)
            return;
        uint64 incoming = damage.GetDamage();
        uint64 maxHealth = target->GetMaxHealth();
        if (!incoming || !maxHealth)
            return;
        uint64 floorHealth = maxHealth * uint64(std::clamp(threshold->GetAmount(), 0, 100)) / 100;
        bool heavy = incoming * 100 > maxHealth * uint64(TimeguardHeavyHitPercent);
        bool lethal = uint64(target->GetHealth()) < incoming + floorHealth;
        if (!heavy && !lethal)
            return;
        amount = uint32(std::min<uint64>(incoming * uint64(std::clamp(reduction->GetAmount(), 0, 100)) / 100,
            uint64(std::numeric_limits<int32>::max())));
        if (amount)
            GetAura()->DropCharge();
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_timeguard::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_timeguard::Absorb, EFFECT_0);
    }
};

class spell_ascension_the_bieko_effect : public SpellScript
{
    PrepareSpellScript(spell_ascension_the_bieko_effect);

    void ReduceRemainingCooldown(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetHitUnit() ? GetHitUnit()->ToPlayer() : nullptr;
        int32 const spellId = GetSpellInfo()->Effects[effIndex].MiscValue;
        if (!player || spellId <= 0)
            return;
        if (uint32 const remaining = player->GetSpellCooldownDelay(uint32(spellId)))
            player->ModifySpellCooldown(uint32(spellId),
                -int32(CalculatePct(remaining, std::clamp(GetEffectValue(), 0, 100))));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_the_bieko_effect::ReduceRemainingCooldown, EFFECT_ALL,
            AscensionReduceRemainingCooldownPctEffect);
    }
};

class spell_ascension_the_vast_infinite : public AuraScript
{
    PrepareAuraScript(spell_ascension_the_vast_infinite);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_THE_VAST_INFINITE_SHARE, SPELL_THE_VAST_INFINITE_HEAL});
    }

    std::vector<Player*> Holders(Player* victim) const
    {
        std::vector<Player*> holders;
        if (Group* group = victim->GetGroup())
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
                if (Player* member = ref->GetSource(); member && member->IsInMap(victim) && member->IsAlive() &&
                    member->GetAura(SPELL_THE_VAST_INFINITE, GetCasterGUID()))
                    holders.push_back(member);
        if (holders.empty())
            holders.push_back(victim);
        return holders;
    }

    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        amount = -1;
        recalculate = false;
    }

    void Absorb(AuraEffect*, DamageInfo& damage, uint32& amount)
    {
        amount = 0;
        SpellInfo const* source = damage.GetSpellInfo();
        if (source && source->Id == SPELL_THE_VAST_INFINITE_SHARE)
            return;
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[EFFECT_0];
        uint64 const capacity = CalculatePct(uint64(GetTarget()->GetMaxHealth()), std::max(0, effect.MiscValueB));
        uint64 const absorbed = GetAura()->GetScriptValue(SPELL_THE_VAST_INFINITE);
        if (absorbed >= capacity)
            return;
        uint64 const portion = CalculatePct(uint64(damage.GetDamage()), std::clamp(effect.CalcValue(), 0, 100));
        amount = uint32(std::min(portion, capacity - absorbed));
    }

    void Share(AuraEffect*, DamageInfo&, uint32& amount)
    {
        Player* victim = GetTarget()->ToPlayer();
        if (!amount || !victim)
            return;
        GetAura()->SetScriptValue(SPELL_THE_VAST_INFINITE, GetAura()->GetScriptValue(SPELL_THE_VAST_INFINITE) + amount);
        std::vector<Player*> const holders = Holders(victim);
        uint32 const share = amount / uint32(holders.size());
        uint32 const remainder = amount - share * uint32(holders.size());
        for (Player* holder : holders)
        {
            uint32 const portion = share + (holder == victim ? remainder : 0);
            Aura* link = holder->GetAura(SPELL_THE_VAST_INFINITE, GetCasterGUID());
            if (!portion || !link)
                continue;
            link->SetScriptValue(SPELL_THE_VAST_INFINITE_SHARE,
                link->GetScriptValue(SPELL_THE_VAST_INFINITE_SHARE) + portion);
            holder->m_Events.AddEventAtOffset([holder, portion]()
            {
                if (holder->IsAlive())
                    holder->CastCustomSpell(SPELL_THE_VAST_INFINITE_SHARE, SPELLVALUE_BASE_POINT0, int32(portion),
                        holder, true);
            }, 1ms);
        }
    }

    void Heal(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        uint64 const shared = GetAura()->GetScriptValue(SPELL_THE_VAST_INFINITE_SHARE);
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE || !target->IsAlive() || !shared)
            return;
        target->CastCustomSpell(SPELL_THE_VAST_INFINITE_HEAL, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(shared, uint64(std::numeric_limits<int32>::max()))), target, true);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_the_vast_infinite::Amount,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_the_vast_infinite::Absorb, EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_the_vast_infinite::Share, EFFECT_0);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_the_vast_infinite::Heal, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL);
    }
};

class chronomancer_talent_casts : public AllSpellScript
{
public:
    chronomancer_talent_casts() : AllSpellScript("chronomancer_talent_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_CHRONOMANCER || info->SpellFamilyName != 28 ||
            spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_GCD) || !IsAeonActivation(info->Id))
            return;
        if (player->HasAura(SPELL_SHIMMERING_SHARD))
            player->CastSpell(player, SPELL_SHIMMER, true);
        if (player->HasAura(SPELL_THROUGH_THE_AEONS))
            player->CastSpell(player, SPELL_THROUGH_THE_AEONS_BUFF, true);
    }
};

constexpr uint32 BlackHoleRank1 = 707557;
constexpr uint32 BlackHoleRank2 = 707743;
constexpr uint32 MeltRealityAndUnmakeFamilyFlags1 = 512 | 33554432;

void ApplyBlackHoleSlowedDamageContract(SpellInfo* info)
{
    if (info->Id != BlackHoleRank1 && info->Id != BlackHoleRank2)
        return;

    SpellEffectInfo& effect = info->Effects[EFFECT_0];
    bool const copied = effect.ApplyAuraName == SPELL_AURA_OVERRIDE_CLASS_SCRIPTS &&
        effect.MiscValue == ASCENSION_CLASSMASK_AURASTATE_DAMAGE && effect.MiscValueB == ASCENSION_TARGET_SLOWED;
    bool const converted = effect.ApplyAuraName == SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE &&
        effect.MiscValue == ASCENSION_TARGET_SLOWED && effect.MiscValueB == ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
    if (effect.Effect != SPELL_EFFECT_APPLY_AURA || (!copied && !converted) ||
        effect.SpellClassMask != flag96(0, MeltRealityAndUnmakeFamilyFlags1, 0) ||
        effect.TargetA.GetTarget() != TARGET_UNIT_CASTER || effect.TargetB.GetTarget())
    {
        LOG_ERROR("coa", "Skipped unexpected Black Hole record {}", info->Id);
        return;
    }

    effect.ApplyAuraName = SPELL_AURA_MOD_DAMAGE_DONE_VERSUS_AURASTATE;
    effect.MiscValue = ASCENSION_TARGET_SLOWED;
    effect.MiscValueB = ASCENSION_CLASSMASK_AURASTATE_DAMAGE;
}
}

void ApplyAscensionChronomancerTalentContracts(SpellInfo* info)
{
    if (info->SpellFamilyName != 28)
        return;
    ApplyBlackHoleSlowedDamageContract(info);
    if (info->Id == SPELL_ROLL_BACK)
    {
        info->Effects[EFFECT_0].Effect = SPELL_EFFECT_DISPEL;
        info->Effects[EFFECT_0].BasePoints = 0;
        info->Effects[EFFECT_0].DieSides = 1;
        info->Effects[EFFECT_0].MiscValue = DISPEL_ALL;
        info->_InitializeExplicitTargetMask();
    }
    if (info->Id == SPELL_TIME_SKIP)
    {
        info->ProcFlags = 0;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_0].TriggerSpell = 0;
    }
    if (info->Id == SPELL_THROUGH_THE_AEONS)
    {
        info->ProcFlags = 0;
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_0].TriggerSpell = 0;
    }
    if (info->Id == SPELL_DIMENSIONAL_DIVERGENCE)
    {
        info->Effects[EFFECT_1].Effect = 0;
        info->Effects[EFFECT_2].Effect = 0;
        info->_InitializeExplicitTargetMask();
    }
    if (info->Id == SPELL_MARK_OF_ORDER_ADD_STACK)
    {
        info->Effects[EFFECT_0].MiscValue = info->Effects[EFFECT_0].MiscValueB;
    }
    if (info->Id == SPELL_NOZDORMUS_GAZE)
    {
        info->Effects[EFFECT_0].MiscValue = SPELLMOD_EFFECT2;
    }
    if (info->Id == SPELL_IDEAL_TIME_BUFF)
    {
        info->ProcCharges = 1;
    }
    if (info->Id == SPELL_THE_VAST_INFINITE_SHARE || info->Id == SPELL_THE_VAST_INFINITE_HEAL)
    {
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AscensionInheritsResolvedAmount = true;
    }
    if (info->Id != SPELL_SHIMMER)
        return;
    info->Effects[EFFECT_1].BasePoints = info->Effects[EFFECT_0].BasePoints;
    info->Effects[EFFECT_1].DieSides = info->Effects[EFFECT_0].DieSides;
}

void AddSC_AscensionChronomancerTalents()
{
    new chronomancer_talent_casts();
    RegisterSpellScript(spell_ascension_dimensional_divergence);
    RegisterSpellScript(spell_ascension_unmaker_of_realities);
    RegisterSpellScript(spell_ascension_destabilize_time);
    RegisterSpellScript(spell_ascension_timeguard);
    RegisterSpellScript(spell_ascension_the_bieko_effect);
    RegisterSpellScript(spell_ascension_the_vast_infinite);
}
