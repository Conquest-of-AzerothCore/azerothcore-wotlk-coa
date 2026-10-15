/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>

namespace
{
enum PrimalistAbilitySpells : uint32
{
    SPELL_GEODE_BARRAGE_DAMAGE = 803138,
    SPELL_GEODE_BARRAGE_RAGE = 802885
};

Player* Primalist(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_WILDWALKER ? player : nullptr;
}

class primalist_talent_events : public UnitScript
{
public:
    primalist_talent_events() : UnitScript("primalist_talent_events", true,
        {UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnDamage(Unit*, Unit* victim, uint32& damage) override
    {
        Player* player = Primalist(victim);
        if (!player || !player->IsAlive() || !damage || damage < player->GetHealth() ||
            !player->HasAura(560157) || player->HasSpellCooldown(560157))
            return;
        player->AddSpellCooldown(560157, 0, 120000);
        damage = 0;
        player->CastSpell(player, 560179, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Player* player = Primalist(unit);
        if (!player || !player->IsAlive() || !player->IsInWorld() || !application ||
            mode == AURA_REMOVE_BY_DEATH || !player->HasAura(300728))
            return;
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID())
            return;
        if (aura->GetId() == 680421 || aura->GetId() == 800094 || aura->GetId() == 503630)
            player->CastSpell(player, 503716, true);
    }
};

class aura_ascension_natural_efficiency : public AuraScript
{
    PrepareAuraScript(aura_ascension_natural_efficiency);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({707806}); }
    bool Load() override { return Primalist(GetUnitOwner()) != nullptr; }

    bool Check(ProcEventInfo& event)
    {
        Unit* caster = event.GetActor();
        SpellInfo const* info = event.GetSpellInfo();
        if (!caster || caster == GetTarget() || !info || !GetTarget()->IsAlive() ||
            !(event.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL)))
            return false;
        AuraApplication const* application = GetTarget()->GetAuraApplication(info->Id, caster->GetGUID());
        if (!application || application->GetRemoveMode() || application->IsPositive())
            return false;
        Aura* aura = application->GetBase();
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (application->GetEffectMask() & (1 << i))
                if (AuraEffect const* effect = aura->GetEffect(i))
                    if (effect->GetAuraType() == SPELL_AURA_MOD_ROOT ||
                        effect->GetAuraType() == SPELL_AURA_MOD_STUN ||
                        effect->GetAuraType() == SPELL_AURA_MOD_CONFUSE)
                        return true;
        return false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_natural_efficiency::Check);
    }
};

class primalist_talent_casts : public AllSpellScript
{
public:
    primalist_talent_casts() : AllSpellScript("primalist_talent_casts",
        {ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = Primalist(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || target == player || player->IsFriendlyTo(target) || miss != SPELL_MISS_NONE ||
            info->SpellFamilyName != 37 || info->Id != SPELL_GEODE_BARRAGE_DAMAGE ||
            spell->GetScriptValue(SPELL_GEODE_BARRAGE_RAGE))
            return;
        spell->SetScriptValue(SPELL_GEODE_BARRAGE_RAGE, 1);
        player->CastSpell(player, SPELL_GEODE_BARRAGE_RAGE, true);
    }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Primalist(spell->GetCaster());
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || !target || !player->HasAura(805336) || info->SpellFamilyName != 37 ||
            !(info->SpellFamilyFlags[0] & 8))
            return;
        for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
            if (effect->GetCasterGUID() == player->GetGUID() && effect->GetSpellInfo()->SpellFamilyName == 37 &&
                (effect->GetSpellInfo()->SpellFamilyFlags[0] & 64))
            {
                chance = 100.0f;
                break;
            }
    }
};

SpellCastResult CheckThroatClamp(Player* player, Unit* target)
{
    Pet* pet = player ? player->GetPet() : nullptr;
    if (!pet || !pet->IsAlive() || pet->GetOwnerGUID() != player->GetGUID())
        return SPELL_FAILED_NO_PET;
    if (!target || !pet->IsInMap(target) || !pet->InSamePhase(target) || !pet->IsValidAttackTarget(target))
        return SPELL_FAILED_BAD_TARGETS;
    if (pet->HasUnitState(UNIT_STATE_NOT_MOVE | UNIT_STATE_LOST_CONTROL))
        return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    SpellInfo const* helper = sSpellMgr->GetSpellInfo(500811);
    if (!helper || !pet->IsWithinDistInMap(target, helper->GetMaxRange(false, pet)))
        return SPELL_FAILED_OUT_OF_RANGE;
    if (!pet->IsWithinLOSInMap(target))
        return SPELL_FAILED_LINE_OF_SIGHT;
    return SPELL_CAST_OK;
}

class spell_ascension_throat_clamp : public SpellScript
{
    PrepareSpellScript(spell_ascension_throat_clamp);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({500811}); }
    bool Load() override { return Primalist(GetCaster()) != nullptr; }

    SpellCastResult CheckCast() { return CheckThroatClamp(Primalist(GetCaster()), GetExplTargetUnit()); }

    void Handle(SpellEffIndex)
    {
        Player* player = Primalist(GetCaster());
        Unit* target = GetHitUnit();
        if (CheckThroatClamp(player, target) == SPELL_CAST_OK)
            player->GetPet()->CastSpell(target, 500811, false);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_throat_clamp::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_throat_clamp::Handle, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class aura_ascension_earthmaker : public AuraScript
{
    PrepareAuraScript(aura_ascension_earthmaker);

    bool Check(ProcEventInfo& event)
    {
        Player* owner = Primalist(GetTarget());
        DamageInfo const* damage = event.GetDamageInfo();
        return owner && owner->IsAlive() && event.GetActor() == owner && damage && damage->GetDamage() &&
            event.GetActionTarget() && !owner->IsFriendlyTo(event.GetActionTarget());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_earthmaker::Check);
    }
};

class aura_ascension_primal_shred_critical : public AuraScript
{
    PrepareAuraScript(aura_ascension_primal_shred_critical);

    bool Load() override
    {
        Pet* pet = GetCaster() ? GetCaster()->ToPet() : nullptr;
        return pet && Primalist(pet->GetOwner()) && GetSpellInfo()->SpellFamilyName == 37 &&
            GetSpellInfo()->SpellFamilyFlags == flag96(0, 0, 32) &&
            GetSpellInfo()->DmgClass == SPELL_DAMAGE_CLASS_MELEE;
    }

    void Snapshot(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* pet = GetCaster();
        if (!pet)
            return;
        SpellInfo const* info = GetSpellInfo();
        float chance = pet->SpellDoneCritChance(GetTarget(), info, info->GetSchoolMask(), BASE_ATTACK, true);
        chance = GetTarget()->SpellTakenCritChance(pet, info, info->GetSchoolMask(), chance, BASE_ATTACK, true);
        GetEffect(EFFECT_0)->SetCritChance(std::max(0.0f, chance));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_primal_shred_critical::Snapshot,
            EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};
}

void AddSC_AscensionPrimalistTalents()
{
    new primalist_talent_events();
    new primalist_talent_casts();
    RegisterSpellScript(aura_ascension_natural_efficiency);
    RegisterSpellScript(spell_ascension_throat_clamp);
    RegisterSpellScript(aura_ascension_primal_shred_critical);
    RegisterSpellScript(aura_ascension_earthmaker);
}
