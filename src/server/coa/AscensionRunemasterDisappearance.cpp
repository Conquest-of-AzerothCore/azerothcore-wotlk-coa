/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "WorldPacket.h"
#include <algorithm>

namespace
{
enum DisappearanceSpells : uint32
{
    SPELL_PHASE_OUT = 500671,
    SPELL_PHASE_OUT_STEALTH = 560269,
    SPELL_RUNESHROUD = 500288,
    SPELL_GLYPH_OF_DISAPPEARANCE = 560037,
    SPELL_DISAPPEARANCE_WINDOW = 561059
};

class spell_ascension_runemaster_phase_out : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_phase_out);

    bool Validate(SpellInfo const* info) override
    {
        SpellEffectInfo const& effect = info->Effects[EFFECT_2];
        return info->Id == SPELL_PHASE_OUT_STEALTH &&
            effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN &&
            effect.MiscValue == int32(SPELL_RUNESHROUD) &&
            ValidateSpellInfo({SPELL_RUNESHROUD});
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_SPIRIT_MAGE;
    }

    void ApplyRuneshroud(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (Unit* target = GetHitUnit())
            target->CastSpell(target, SPELL_RUNESHROUD, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_phase_out::ApplyRuneshroud,
            EFFECT_2, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class runemaster_glyph_of_disappearance : public AllSpellScript
{
public:
    runemaster_glyph_of_disappearance() : AllSpellScript("runemaster_glyph_of_disappearance",
        {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || info->Id != SPELL_PHASE_OUT ||
            spell->IsTriggered())
            return;

        if (Aura* window = player->GetAura(SPELL_DISAPPEARANCE_WINDOW, player->GetGUID()))
        {
            window->SetScriptValue(SPELL_PHASE_OUT, 0);
            window->Remove();
            return;
        }

        AuraEffect* glyph = player->GetAuraEffect(SPELL_GLYPH_OF_DISAPPEARANCE, EFFECT_0, player->GetGUID());
        if (!glyph)
            return;

        uint32 const deferredCooldown = player->GetSpellCooldownDelay(SPELL_PHASE_OUT);
        player->CastSpell(player, SPELL_DISAPPEARANCE_WINDOW, TRIGGERED_FULL_MASK, nullptr, glyph);
        if (Aura* window = player->GetAura(SPELL_DISAPPEARANCE_WINDOW, player->GetGUID()))
            window->SetScriptValue(SPELL_PHASE_OUT, deferredCooldown);
    }
};

class spell_ascension_runemaster_disappearance_window : public AuraScript
{
    PrepareAuraScript(spell_ascension_runemaster_disappearance_window);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer();
    }

    void IncurDeferredCooldown(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        uint64 const deferredCooldown = GetAura()->GetScriptValue(SPELL_PHASE_OUT);
        if (!player || !player->IsInWorld() || !deferredCooldown)
            return;

        int32 const elapsed = std::max(0, GetAura()->GetMaxDuration() - std::max(0, GetAura()->GetDuration()));
        if (deferredCooldown <= uint64(elapsed))
            return;

        uint32 const remaining = uint32(deferredCooldown - uint64(elapsed));
        if (remaining <= player->GetSpellCooldownDelay(SPELL_PHASE_OUT))
            return;

        player->AddSpellCooldown(SPELL_PHASE_OUT, 0, remaining, true);
        WorldPacket cooldown;
        player->BuildCooldownPacket(cooldown, SPELL_COOLDOWN_FLAG_NONE, SPELL_PHASE_OUT, remaining);
        player->SendDirectMessage(&cooldown);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_runemaster_disappearance_window::IncurDeferredCooldown,
            EFFECT_1, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionRunemasterDisappearance()
{
    new runemaster_glyph_of_disappearance();
    RegisterSpellScript(spell_ascension_runemaster_disappearance_window);
    RegisterSpellScript(spell_ascension_runemaster_phase_out);
}
