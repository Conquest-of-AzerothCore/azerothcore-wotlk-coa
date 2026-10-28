/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Containers.h"
#include "AscensionSpecialization.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <limits>

namespace
{
enum RunemasterElementalTalentSpells : uint32
{
    SPELL_FIRE_CARVING = 706520,
    SPELL_WATER_CARVING = 707142,
    SPELL_EARTH_CARVING = 712300,
    SPELL_EARTH_CARVING_HEAL = 712356,
    SPELL_AIR_CARVING = 653253,
    SPELL_WINDSAGE_STRIKE = 706457,
    SPELL_PRIMORDIAL_BLAST = 800732
};

constexpr uint32 RUNEMASTER_SPELL_FAMILY = 38;

constexpr std::array<uint32, 4> Carvings =
{
    SPELL_FIRE_CARVING, SPELL_WATER_CARVING, SPELL_EARTH_CARVING, SPELL_AIR_CARVING
};

struct PrimordialAlteration
{
    uint32 Aura;
    uint32 Blast;
};

constexpr std::array<PrimordialAlteration, 4> Alterations =
{{
    {713003, 712668}, {717070, 712858}, {718040, 713002}, {721085, 712404}
}};

constexpr PrimordialAlteration RunicObliteration = {805742, 805794};

PrimordialAlteration const* AlterationByAura(uint32 aura)
{
    if (aura == RunicObliteration.Aura)
        return &RunicObliteration;
    auto itr = std::find_if(Alterations.begin(), Alterations.end(),
        [aura](PrimordialAlteration const& alteration) { return alteration.Aura == aura; });
    return itr == Alterations.end() ? nullptr : &*itr;
}

PrimordialAlteration const* AlterationByBlast(uint32 blast)
{
    if (blast == RunicObliteration.Blast)
        return &RunicObliteration;
    auto itr = std::find_if(Alterations.begin(), Alterations.end(),
        [blast](PrimordialAlteration const& alteration) { return alteration.Blast == blast; });
    return itr == Alterations.end() ? nullptr : &*itr;
}

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

class spell_ascension_runemaster_primeval_carving : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_primeval_carving);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo(Carvings); }

    bool Load() override { return IsRunemaster(GetCaster()); }

    void Carve(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        GetCaster()->CastSpell(GetCaster(), Acore::Containers::SelectRandomContainerElement(Carvings),
            TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_runemaster_primeval_carving::Carve, EFFECT_0,
            SPELL_EFFECT_ASCENSION_TRIGGER_RANDOM_SPELL);
    }
};

class spell_ascension_runemaster_earth_carving : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_earth_carving);

    void MissingHealth(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        uint64 missing = target->GetMaxHealth() - std::min(target->GetHealth(), target->GetMaxHealth());
        uint64 amount = missing * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_earth_carving::MissingHealth, EFFECT_0,
            SPELL_EFFECT_HEAL);
    }
};

class aura_ascension_runemaster_windsage : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_windsage);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_WINDSAGE_STRIKE}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* target = event.GetActionTarget();
        return IsRunemaster(player) && GetCaster() == player && event.GetActor() == player && target &&
            target != player && target->IsAlive() && damage && damage->GetDamage();
    }

    void Strike(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (!amount)
            return;
        GetTarget()->CastCustomSpell(SPELL_WINDSAGE_STRIKE, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), event.GetActionTarget(),
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_windsage::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_windsage::Strike, EFFECT_0, AuraType(354));
    }
};

class spell_ascension_runemaster_alteration_trigger : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_alteration_trigger);

    bool Validate(SpellInfo const*) override
    {
        for (PrimordialAlteration const& alteration : Alterations)
            if (!ValidateSpellInfo({alteration.Aura, alteration.Blast}))
                return false;
        return true;
    }

    bool Load() override { return IsRunemaster(GetCaster()); }

    void Alter(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        GetCaster()->CastSpell(GetCaster(), Acore::Containers::SelectRandomContainerElement(Alterations).Aura,
            TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_runemaster_alteration_trigger::Alter, EFFECT_0,
            SPELL_EFFECT_ASCENSION_TRIGGER_RANDOM_SPELL);
    }
};

class aura_ascension_runemaster_primordial_alteration : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_primordial_alteration);

    void Transform(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        PrimordialAlteration const* alteration = AlterationByAura(GetId());
        if (!IsRunemaster(player) || !alteration || GetCaster() != player)
            return;
        for (PrimordialAlteration const& other : Alterations)
            if (other.Aura != alteration->Aura)
                player->RemoveAurasDueToSpell(other.Aura, player->GetGUID());
        if (alteration->Aura != RunicObliteration.Aura)
            player->RemoveAurasDueToSpell(RunicObliteration.Aura, player->GetGUID());
        SynchronizeAscensionTalentReplacements(player);
    }

    void Restore(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        PrimordialAlteration const* alteration = AlterationByAura(GetId());
        if (!IsRunemaster(player) || !alteration || GetCaster() != player)
            return;
        SynchronizeAscensionTalentReplacements(player);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_runemaster_primordial_alteration::Transform, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_runemaster_primordial_alteration::Restore, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_runemaster_primordial_alteration_cast : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_primordial_alteration_cast);

    bool Load() override { return IsRunemaster(GetCaster()) && AlterationByBlast(GetSpellInfo()->Id); }

    void Consume()
    {
        if (PrimordialAlteration const* alteration = AlterationByBlast(GetSpellInfo()->Id))
            GetCaster()->RemoveAurasDueToSpell(alteration->Aura, GetCaster()->GetGUID());
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_runemaster_primordial_alteration_cast::Consume);
    }
};

class runemaster_elemental_talent_metadata : public GlobalScript
{
public:
    runemaster_elemental_talent_metadata() : GlobalScript("runemaster_elemental_talent_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != RUNEMASTER_SPELL_FAMILY)
            return;
        if (info->Id == SPELL_EARTH_CARVING_HEAL && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL_PCT &&
            info->Effects[EFFECT_0].MiscValueB == 1)
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_HEAL;
        if (info->Id == SPELL_WINDSAGE_STRIKE)
        {
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (AlterationByAura(info->Id))
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
        if (info->Id == RunicObliteration.Blast || info->Id == 807014)
        {
            if (SpellInfo const* blast = sSpellMgr->GetSpellInfo(SPELL_PRIMORDIAL_BLAST))
                info->SpellFamilyFlags |= blast->SpellFamilyFlags;
            if (info->Id == RunicObliteration.Blast)
                info->CasterAuraSpell = RunicObliteration.Aura;
        }
    }
};
}

void AddSC_AscensionRunemasterElementalTalents()
{
    new runemaster_elemental_talent_metadata();
    RegisterSpellScript(spell_ascension_runemaster_primeval_carving);
    RegisterSpellScript(spell_ascension_runemaster_earth_carving);
    RegisterSpellScript(aura_ascension_runemaster_windsage);
    RegisterSpellScript(spell_ascension_runemaster_alteration_trigger);
    RegisterSpellScript(aura_ascension_runemaster_primordial_alteration);
    RegisterSpellScript(spell_ascension_runemaster_primordial_alteration_cast);
}
