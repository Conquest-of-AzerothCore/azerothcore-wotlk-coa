/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
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
enum PrimalistSecondarySpells : uint32
{
    SPELL_ANCIENT_OF_LORE = 805105,
    SPELL_ANCIENT_SLOW = 504369,
    SPELL_VOLCANIC_BLAST = 681353,
    SPELL_HAMMER_OF_LIFE_HEAL = 806073,
    SPELL_HAMMER_OF_LIFE_DAMAGE = 807651,
    SPELL_CRACKING_EARTH = 560145,
    SPELL_CRACKING_STACK = 560146,
    SPELL_EARTHS_EMBRACE = 806143,
    SPELL_EMBRACED_BY_EARTH = 561037,
    SPELL_EMBRACE_DISORIENT = 706200,
    SPELL_GAZE = 805919,
    SPELL_GAZE_SLOW = 572908,
    SPELL_SAVAGE_FRENZY = 806549,
    SPELL_TOTEM_WARRIOR = 704099,
    SPELL_TOTEM_WARRIOR_HIT = 555732,
    SPELL_BOON_OF_THE_BEAR = 500939,
    SPELL_STONE_GRIP = 800145
};

class primalist_secondary_auras : public UnitScript
{
public:
    primalist_secondary_auras() : UnitScript("primalist_secondary_auras", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (player && player->getClass() == CLASS_WILDWALKER && aura &&
            aura->GetId() == SPELL_ANCIENT_OF_LORE && aura->GetCasterGUID() == player->GetGUID() &&
            !player->HasAura(SPELL_ANCIENT_SLOW, player->GetGUID()))
            player->AddAura(SPELL_ANCIENT_SLOW, player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_WILDWALKER || !application)
            return;
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID())
            return;
        if (aura->GetId() == SPELL_ANCIENT_OF_LORE)
            player->RemoveAurasDueToSpell(SPELL_ANCIENT_SLOW, player->GetGUID());
        if (aura->GetId() == SPELL_CRACKING_EARTH)
            player->RemoveAurasDueToSpell(SPELL_CRACKING_STACK, player->GetGUID());
        if (aura->GetId() == SPELL_EARTHS_EMBRACE && mode == AURA_REMOVE_BY_EXPIRE &&
            player->IsAlive() && player->IsInWorld() && player->HasAura(SPELL_EMBRACED_BY_EARTH, player->GetGUID()))
            player->CastSpell(player, SPELL_EMBRACE_DISORIENT, true);
    }
};

class spell_ascension_totem_warrior : public SpellScript
{
    PrepareSpellScript(spell_ascension_totem_warrior);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_TOTEM_WARRIOR, SPELL_TOTEM_WARRIOR_HIT, SPELL_BOON_OF_THE_BEAR});
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Repeat()
    {
        Unit* owner = GetCaster();
        Unit* victim = GetHitUnit();
        if (!victim || !victim->IsAlive() || owner->IsFriendlyTo(victim) || GetHitDamage() <= 0 ||
            !owner->HasAura(SPELL_BOON_OF_THE_BEAR, owner->GetGUID()))
            return;

        if (AuraEffect const* talent = owner->GetAuraEffect(SPELL_TOTEM_WARRIOR, EFFECT_0, owner->GetGUID()))
        {
            int32 amount = int32(int64(GetHitDamage()) * std::clamp(talent->GetAmount(), 0, 100) / 100);
            if (amount)
                owner->CastCustomSpell(SPELL_TOTEM_WARRIOR_HIT, SPELLVALUE_BASE_POINT0, amount, victim,
                    TRIGGERED_FULL_MASK, nullptr, talent);
        }
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_totem_warrior::Repeat);
    }
};

class aura_ascension_volcanic_blast : public AuraScript
{
    PrepareAuraScript(aura_ascension_volcanic_blast);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return player->IsPlayer() && player->getClass() == CLASS_WILDWALKER && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && victim && victim != player &&
            !player->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            (event.GetHitMask() & PROC_HIT_CRITICAL) &&
            (damage->GetSchoolMask() & (SPELL_SCHOOL_MASK_NORMAL | SPELL_SCHOOL_MASK_NATURE));
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(SPELL_VOLCANIC_BLAST, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_volcanic_blast::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_volcanic_blast::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_natures_blessing : public AuraScript
{
    PrepareAuraScript(aura_ascension_natures_blessing);

    bool Validate(SpellInfo const* info) override
    {
        return info->SpellFamilyName == 37 && info->Effects[EFFECT_0].ApplyAuraName == 354 &&
            info->Effects[EFFECT_0].TriggerSpell == 807561 && ValidateSpellInfo({807561});
    }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER;
    }

    bool Check(ProcEventInfo& event)
    {
        SpellInfo const* info = event.GetSpellInfo();
        HealInfo const* heal = event.GetHealInfo();
        Unit* target = event.GetActionTarget();
        bool seismicWave = info && (info->Id == 805462 || (info->Id >= 572873 && info->Id <= 572878));
        return seismicWave && event.GetActor() == GetTarget() && target && target->IsAlive() &&
            GetTarget()->IsFriendlyTo(target) && heal && heal->GetHeal();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetHealInfo()->GetHeal()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(807561, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
                event.GetActionTarget(), TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_natures_blessing::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_natures_blessing::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_hammer_of_life : public AuraScript
{
    PrepareAuraScript(aura_ascension_hammer_of_life);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return player->IsPlayer() && player->getClass() == CLASS_WILDWALKER && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && victim && victim != player &&
            !player->IsFriendlyTo(victim) && damage && damage->GetDamage();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (!amount)
            return;
        int32 value = int32(std::min<uint64>(amount, std::numeric_limits<int32>::max()));
        GetTarget()->CastCustomSpell(SPELL_HAMMER_OF_LIFE_HEAL, SPELLVALUE_BASE_POINT0, value, GetTarget(),
            TRIGGERED_FULL_MASK);
        GetTarget()->CastCustomSpell(SPELL_HAMMER_OF_LIFE_DAMAGE, SPELLVALUE_BASE_POINT0, value, GetTarget(),
            TRIGGERED_FULL_MASK);
    }

    void IgnoreSecondTrigger(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_hammer_of_life::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_hammer_of_life::Proc, EFFECT_0, AuraType(354));
        OnEffectProc += AuraEffectProcFn(aura_ascension_hammer_of_life::IgnoreSecondTrigger, EFFECT_2, AuraType(354));
    }
};

class primalist_volcanic_targets : public AllSpellScript
{
public:
    primalist_volcanic_targets() : AllSpellScript("primalist_volcanic_targets", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_WILDWALKER || !player->IsAlive() ||
            spell->GetSpellInfo()->Id != SPELL_VOLCANIC_BLAST || miss != SPELL_MISS_NONE ||
            !target || target == player || player->IsFriendlyTo(target) ||
            !player->HasAura(SPELL_CRACKING_EARTH, player->GetGUID()))
            return;
        uint64 count = spell->GetScriptValue(SPELL_CRACKING_STACK) + 1;
        spell->SetScriptValue(SPELL_CRACKING_STACK, count);
        if (count == 5)
            player->CastSpell(player, SPELL_CRACKING_STACK, true);
    }
};

class spell_ascension_gaze_of_theradras : public SpellScript
{
    PrepareSpellScript(spell_ascension_gaze_of_theradras);

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER; }

    void Before(SpellMissInfo miss)
    {
        Unit* target = GetHitUnit();
        _newVictim = miss == SPELL_MISS_NONE && target && target->CanHaveThreatList() &&
            target->GetVictim() != GetCaster();
    }

    void After()
    {
        Unit* target = GetHitUnit();
        if (_newVictim && target && target->IsAlive() && target->HasAura(SPELL_GAZE, GetCaster()->GetGUID()))
            GetCaster()->CastSpell(target, SPELL_GAZE_SLOW, true);
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_ascension_gaze_of_theradras::Before);
        AfterHit += SpellHitFn(spell_ascension_gaze_of_theradras::After);
    }

    bool _newVictim = false;
};

class spell_ascension_seismic_wave : public SpellScript
{
    PrepareSpellScript(spell_ascension_seismic_wave);

    void AddHealingPower(SpellEffIndex)
    {
        int32 power = GetCaster()->SpellBaseHealingBonusDone(GetSpellInfo()->GetSchoolMask());
        SetEffectValue(GetEffectValue() + int32(power * 0.3f));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_seismic_wave::AddHealingPower, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};

class primalist_secondary_metadata : public GlobalScript
{
public:
    primalist_secondary_metadata() : GlobalScript("primalist_secondary_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 37)
            return;
        if (info->Id == SPELL_SAVAGE_FRENZY)
        {
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsAura() && effect.TargetA.GetTarget() == TARGET_UNIT_PET &&
                    effect.TargetB.GetTarget() == 0)
                    effect.TargetB = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
            info->_InitializeExplicitTargetMask();
        }
        if (info->Id == SPELL_VOLCANIC_BLAST || info->Id == SPELL_TOTEM_WARRIOR_HIT)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_CRACKING_EARTH)
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            info->ProcFlags = 0;
        }
        if (info->Id == SPELL_CRACKING_STACK)
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_MAX_AFFECTED_TARGETS;
        if (info->Id == SPELL_EMBRACE_DISORIENT)
            info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
        if (info->Id == SPELL_GAZE_SLOW)
            info->ProcCharges = 1;
        if (info->Id == SPELL_ANCIENT_SLOW || info->Id == SPELL_CRACKING_STACK || info->Id == SPELL_GAZE_SLOW)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
        if (info->Id == SPELL_STONE_GRIP)
        {
            info->Effects[EFFECT_1].Effect = 0;
            info->Mechanic = MECHANIC_SAPPED;
        }
    }
};

class primalist_resources : public PlayerScript
{
public:
    primalist_resources()
        : PlayerScript("primalist_resources", {PLAYERHOOK_ON_PLAYER_HAS_ACTIVE_POWER_TYPE})
    {
    }

    bool OnPlayerHasActivePowerType(Player const* player, Powers power) override
    {
        return player && player->getClass() == CLASS_WILDWALKER && power == POWER_RAGE;
    }
};
}

void AddSC_AscensionPrimalistSecondary()
{
    new primalist_secondary_auras();
    new primalist_resources();
    new primalist_volcanic_targets();
    new primalist_secondary_metadata();
    RegisterSpellScript(aura_ascension_volcanic_blast);
    RegisterSpellScript(spell_ascension_totem_warrior);
    RegisterSpellScript(aura_ascension_natures_blessing);
    RegisterSpellScript(aura_ascension_hammer_of_life);
    RegisterSpellScript(spell_ascension_gaze_of_theradras);
    RegisterSpellScript(spell_ascension_seismic_wave);
}
