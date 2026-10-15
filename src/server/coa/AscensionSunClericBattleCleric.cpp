/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum BattleClericSpells : uint32
{
    SPELL_BATTLE_CLERIC = 300347,
    SPELL_BATTLE_CLERIC_EFFECTS = 562316,
    SPELL_PARAGON = 680639
};

class aura_ascension_battle_cleric : public AuraScript
{
    PrepareAuraScript(aura_ascension_battle_cleric);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_BATTLE_CLERIC_EFFECTS}); }

    bool Load() override
    {
        return GetCaster() && GetCaster() == GetUnitOwner() && GetCaster()->IsPlayer() &&
            GetCaster()->getClass() == CLASS_SUN_CLERIC;
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* player = GetTarget();
        uint32 required = GetId() == SPELL_PARAGON ? SPELL_BATTLE_CLERIC : SPELL_PARAGON;
        if (!player->HasAura(required, player->GetGUID()))
            return;
        Aura* helper = player->GetAura(SPELL_BATTLE_CLERIC_EFFECTS, player->GetGUID());
        if (!helper)
            helper = player->AddAura(SPELL_BATTLE_CLERIC_EFFECTS, player);
        if (helper)
        {
            helper->SetMaxDuration(-1);
            helper->SetDuration(-1);
        }
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_BATTLE_CLERIC_EFFECTS, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_battle_cleric::Apply,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_battle_cleric::Remove,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class sun_cleric_battle_cleric_metadata : public GlobalScript
{
public:
    sun_cleric_battle_cleric_metadata() : GlobalScript("sun_cleric_battle_cleric_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 33)
            return;
        if (info->Id == SPELL_BATTLE_CLERIC)
        {
            SpellEffectInfo& cooldown = info->Effects[EFFECT_0];
            cooldown.Effect = SPELL_EFFECT_APPLY_AURA;
            cooldown.ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
            cooldown.BasePoints = -240000;
            cooldown.DieSides = 0;
            cooldown.MiscValue = SPELLMOD_COOLDOWN;
            cooldown.SpellClassMask = flag96(0, 0, 8388608);
            cooldown.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
            info->_InitializeExplicitTargetMask();
        }
        if (info->Id == SPELL_BATTLE_CLERIC_EFFECTS)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionSunClericBattleCleric()
{
    new sun_cleric_battle_cleric_metadata();
    RegisterSpellScript(aura_ascension_battle_cleric);
}
