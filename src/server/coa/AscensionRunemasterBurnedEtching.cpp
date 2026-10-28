/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
enum RunemasterBurnedEtchingSpells : uint32
{
    SPELL_FIRE_ENGRAVING = 653211,
    SPELL_BURNED_ETCHING = 500476,
    SPELL_BURNED_ETCHING_EMPOWERMENT = 500475,
    SPELL_BURNED_ETCHING_FIRE = 500474
};

constexpr uint32 RUNEMASTER_SPELL_FAMILY = 38;

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

bool IsBurnedEtchingSource(uint32 spellId)
{
    return spellId == SPELL_FIRE_ENGRAVING || spellId == SPELL_BURNED_ETCHING;
}

void SyncBurnedEtching(Player* player)
{
    bool const engraved = player->HasAura(SPELL_FIRE_ENGRAVING, player->GetGUID()) &&
        player->HasAura(SPELL_BURNED_ETCHING, player->GetGUID());
    if (!engraved)
        player->RemoveAurasDueToSpell(SPELL_BURNED_ETCHING_EMPOWERMENT, player->GetGUID());
    else if (!player->HasAura(SPELL_BURNED_ETCHING_EMPOWERMENT, player->GetGUID()))
        player->AddAura(SPELL_BURNED_ETCHING_EMPOWERMENT, player);
}

class runemaster_burned_etching_engraving : public UnitScript
{
public:
    runemaster_burned_etching_engraving() : UnitScript("runemaster_burned_etching_engraving", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (IsRunemaster(unit) && aura && IsBurnedEtchingSource(aura->GetId()))
            SyncBurnedEtching(unit->ToPlayer());
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (IsRunemaster(unit) && application && IsBurnedEtchingSource(application->GetBase()->GetId()))
            SyncBurnedEtching(unit->ToPlayer());
    }
};

class aura_ascension_runemaster_burned_etching : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_burned_etching);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_BURNED_ETCHING_FIRE}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* target = event.GetActionTarget();
        return IsRunemaster(player) && GetCaster() == player && event.GetActor() == player && target &&
            target != player && target->IsAlive() && damage && damage->GetDamage();
    }

    void Burn(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (!amount)
            return;
        GetTarget()->CastCustomSpell(SPELL_BURNED_ETCHING_FIRE, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), event.GetActionTarget(),
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_burned_etching::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_burned_etching::Burn, EFFECT_0, AuraType(354));
    }
};

class runemaster_burned_etching_metadata : public GlobalScript
{
public:
    runemaster_burned_etching_metadata() : GlobalScript("runemaster_burned_etching_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != RUNEMASTER_SPELL_FAMILY)
            return;
        if (info->Id == SPELL_BURNED_ETCHING_FIRE)
        {
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_BURNED_ETCHING_EMPOWERMENT)
        {
            info->AttributesEx2 |= SPELL_ATTR2_ALLOW_DEAD_TARGET;
            info->AttributesEx3 |= SPELL_ATTR3_ALLOW_AURA_WHILE_DEAD;
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionRunemasterBurnedEtching()
{
    new runemaster_burned_etching_engraving();
    new runemaster_burned_etching_metadata();
    RegisterSpellScript(aura_ascension_runemaster_burned_etching);
}
