/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 BloomingShot = 276884;
constexpr uint32 BloomingHeal = 276926;
constexpr uint32 Blooming = 276897;
constexpr uint32 NaturesPower = 276927;
constexpr uint32 BloomingReduction = 276933;

void StartBlooming(Player* player)
{
    if (player->HasSpell(BloomingShot) && !player->HasAura(Blooming) && !player->HasAura(NaturesPower))
        player->CastSpell(player, Blooming, true);
}

class blooming_shot_player : public PlayerScript
{
public:
    blooming_shot_player() : PlayerScript("blooming_shot_player",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL}) { }

    void OnPlayerLogin(Player* player) override
    {
        StartBlooming(player);
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (spellId == BloomingShot)
            StartBlooming(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        if (spellId != BloomingShot)
            return;
        player->RemoveAurasDueToSpell(Blooming);
        player->RemoveAurasDueToSpell(NaturesPower);
    }
};

class blooming_shot_contracts : public GlobalScript
{
public:
    blooming_shot_contracts() : GlobalScript("blooming_shot_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == NaturesPower)
            for (uint8 effect : {EFFECT_0, EFFECT_1})
                info->Effects[effect].SpellClassMask = flag96(2048, 0, 0);
    }

    void OnSpellModFamilyMask(SpellInfo const* affect, SpellInfo const* check,
        SpellModifier const*, bool& affected) override
    {
        if (affect->Id == NaturesPower)
            affected = check->Id == BloomingShot || check->Id == BloomingHeal;
    }
};

class aura_ascension_blooming : public AuraScript
{
    PrepareAuraScript(aura_ascension_blooming);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({NaturesPower});
    }

    void Complete(AuraEffect const*, AuraEffectHandleModes)
    {
        auto const mode = GetTargetApplication()->GetRemoveMode();
        Player* player = GetTarget()->ToPlayer();
        if (player && player->IsAlive() && player->HasSpell(BloomingShot) &&
            (mode == AURA_REMOVE_BY_EXPIRE || mode == AURA_REMOVE_BY_DEFAULT))
            player->CastSpell(player, NaturesPower, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_blooming::Complete,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_natures_power : public AuraScript
{
    PrepareAuraScript(aura_ascension_natures_power);

    bool Check(ProcEventInfo& event)
    {
        SpellInfo const* info = event.GetSpellInfo();
        return info && event.GetActor() == GetTarget() &&
            (info->Id == BloomingShot || info->Id == BloomingHeal);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_natures_power::Check);
    }
};

class blooming_shot_casts : public AllSpellScript
{
public:
    blooming_shot_casts() : AllSpellScript("blooming_shot_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || spell->IsTriggered() || !player->HasSpell(BloomingShot))
            return;
        if (info->Id == BloomingShot)
            player->CastSpell(player, Blooming, true);
        else if (info->SpellFamilyName == SPELLFAMILY_HUNTER &&
            info->DmgClass == SPELL_DAMAGE_CLASS_RANGED && info->Id != 75 && player->HasAura(Blooming))
            player->CastSpell(player, BloomingReduction, true);
    }
};
}

void AddAscensionHeroBloomingShotScripts()
{
    new blooming_shot_player();
    new blooming_shot_contracts();
    new blooming_shot_casts();
    RegisterSpellScript(aura_ascension_blooming);
    RegisterSpellScript(aura_ascension_natures_power);
}
