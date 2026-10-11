/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum HeroDarkApotheosisSpells : uint32
{
    DarkApotheosis = 275585,
    ShieldArmorAndBlockRemoval = 275587
};

constexpr int32 THREAT_INCREASE_PCT = 260;

class hero_dark_apotheosis_threat : public GlobalScript
{
public:
    hero_dark_apotheosis_threat() : GlobalScript("hero_dark_apotheosis_threat",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != DarkApotheosis || !info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_SHAPESHIFT) ||
            info->Effects[EFFECT_2].Effect)
            return;
        SpellEffectInfo& threat = info->Effects[EFFECT_2];
        threat.Effect = SPELL_EFFECT_APPLY_AURA;
        threat.ApplyAuraName = SPELL_AURA_MOD_THREAT;
        threat.BasePoints = THREAT_INCREASE_PCT - 1;
        threat.DieSides = 1;
        threat.MiscValue = SPELL_SCHOOL_MASK_ALL;
        threat.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        threat.TargetB = SpellImplicitTargetInfo();
    }
};

class aura_hero_dark_apotheosis : public AuraScript
{
    PrepareAuraScript(aura_hero_dark_apotheosis);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ShieldArmorAndBlockRemoval});
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->CastSpell(GetTarget(), ShieldArmorAndBlockRemoval, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(ShieldArmorAndBlockRemoval, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_hero_dark_apotheosis::Apply, EFFECT_0, SPELL_AURA_MOD_SHAPESHIFT,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_hero_dark_apotheosis::Remove, EFFECT_0,
            SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};

class hero_dark_apotheosis_no_shield : public PlayerScript
{
public:
    hero_dark_apotheosis_no_shield() : PlayerScript("hero_dark_apotheosis_no_shield",
        {PLAYERHOOK_CAN_EQUIP_ITEM}) { }

    bool OnPlayerCanEquipItem(Player* player, uint8, uint16&, Item* item, bool, bool notLoading) override
    {
        ItemTemplate const* proto = item ? item->GetTemplate() : nullptr;
        return !notLoading || !proto || proto->Class != ITEM_CLASS_ARMOR ||
            proto->SubClass != ITEM_SUBCLASS_ARMOR_SHIELD || !player->HasAura(DarkApotheosis);
    }
};
}

void AddSC_AscensionHeroDarkApotheosis()
{
    new hero_dark_apotheosis_threat();
    RegisterSpellScript(aura_hero_dark_apotheosis);
    new hero_dark_apotheosis_no_shield();
}
