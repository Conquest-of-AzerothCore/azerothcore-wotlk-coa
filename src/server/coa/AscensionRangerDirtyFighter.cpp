/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum DirtyFighterSpells : uint32
{
    SPELL_DIRTY_FIGHTER = 806978,
    SPELL_FIGHTING_DIRTY = 684329,
    SPELL_PLAYING_DIRTY = 681787,
    SPELL_SUCKER_PUNCH = 681235,
    SPELL_ASSAULT = 803108,
    SPELL_SKULLPIERCER = 802036
};

Player* DirtyFighter(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_RANGER ? player : nullptr;
}

bool CanSuckerPunch(Player* player)
{
    return player && player->IsAlive() && player->IsInWorld() && player->HasAura(SPELL_DIRTY_FIGHTER) &&
        player->HasAura(SPELL_PLAYING_DIRTY, player->GetGUID());
}

class aura_ascension_playing_dirty : public AuraScript
{
    PrepareAuraScript(aura_ascension_playing_dirty);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_SUCKER_PUNCH}); }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = DirtyFighter(GetTarget());
        if (!CanSuckerPunch(player) || GetCaster() != player)
            return;
        if (player->GetSpellMap().find(SPELL_SUCKER_PUNCH) == player->GetSpellMap().end())
            player->learnSpell(SPELL_SUCKER_PUNCH, true);
        for (auto const& [id, record] : player->GetSpellMap())
            if (player->HasActiveSpell(id) && sSpellMgr->GetFirstSpellInChain(id) == SPELL_ASSAULT)
                player->SetTemporarySpellReplacement(id, SPELL_SUCKER_PUNCH);
    }

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = DirtyFighter(GetTarget());
        if (!player || GetCaster() != player)
            return;
        for (auto const& [id, record] : player->GetSpellMap())
            if (sSpellMgr->GetFirstSpellInChain(id) == SPELL_ASSAULT)
                player->SetTemporarySpellReplacement(id, 0);
        player->removeSpell(SPELL_SUCKER_PUNCH, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_playing_dirty::Apply,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_playing_dirty::Clear,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_dirty_fighter : public AuraScript
{
    PrepareAuraScript(aura_ascension_dirty_fighter);

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = DirtyFighter(GetTarget()))
        {
            player->RemoveAurasDueToSpell(SPELL_FIGHTING_DIRTY, player->GetGUID());
            player->RemoveAurasDueToSpell(SPELL_PLAYING_DIRTY, player->GetGUID());
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_dirty_fighter::Clear,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class ranger_dirty_fighter_casts : public AllSpellScript
{
public:
    ranger_dirty_fighter_casts() : AllSpellScript("ranger_dirty_fighter_casts",
        {ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_CAN_PREPARE, ALLSPELLHOOK_ON_SPELL_CHECK_CAST,
            ALLSPELLHOOK_ON_BEFORE_EFFECTS}) { }

    bool IsPunch(Spell* spell) const
    {
        return spell->GetSpellInfo()->Id == SPELL_SUCKER_PUNCH && spell->GetSpellInfo()->SpellFamilyName == 27;
    }

    bool CanPrepare(Spell* spell, SpellCastTargets const*, AuraEffect const*) override
    {
        return !IsPunch(spell) || CanSuckerPunch(DirtyFighter(spell->GetCaster()));
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (IsPunch(spell) && !CanSuckerPunch(DirtyFighter(spell->GetCaster())))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const*) override
    {
        if (IsPunch(spell))
            caster->RemoveAurasDueToSpell(SPELL_PLAYING_DIRTY, caster->GetGUID());
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool critical) override
    {
        Player* player = DirtyFighter(spell->GetCaster());
        if (!player || spell->GetSpellInfo()->SpellFamilyName != 27 || spell->IsTriggered() ||
            miss != SPELL_MISS_NONE || !critical || !damage || !target || target == player ||
            player->IsFriendlyTo(target) || !player->HasAura(SPELL_DIRTY_FIGHTER) ||
            spell->GetScriptValue(SPELL_DIRTY_FIGHTER))
            return;
        uint32 root = sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id);
        if (root != SPELL_ASSAULT && root != SPELL_SKULLPIERCER)
            return;
        spell->SetScriptValue(SPELL_DIRTY_FIGHTER, 1);
        if (Aura* counter = player->AddAura(SPELL_FIGHTING_DIRTY, player))
            if (counter->GetStackAmount() == 2)
            {
                player->RemoveAurasDueToSpell(SPELL_FIGHTING_DIRTY, player->GetGUID());
                player->CastSpell(player, SPELL_PLAYING_DIRTY, true);
            }
    }
};

class ranger_dirty_fighter_contracts : public GlobalScript
{
public:
    ranger_dirty_fighter_contracts() : GlobalScript("ranger_dirty_fighter_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info && info->Id == SPELL_PLAYING_DIRTY && info->SpellFamilyName == 27)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionRangerDirtyFighter()
{
    RegisterSpellScript(aura_ascension_playing_dirty);
    RegisterSpellScript(aura_ascension_dirty_fighter);
    new ranger_dirty_fighter_casts();
    new ranger_dirty_fighter_contracts();
}
