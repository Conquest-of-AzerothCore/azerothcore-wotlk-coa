/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 AdvantageCompanions[] = {520614, 704337, 801429, 801700, 802612};

class aura_ascension_ranger_advantage : public AuraScript
{
    PrepareAuraScript(aura_ascension_ranger_advantage);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({520614, 704337, 801429, 801700, 802612}); }

    bool Load() override
    {
        return GetCaster() && GetCaster() == GetUnitOwner() && GetCaster()->IsPlayer() &&
            GetCaster()->getClass() == CLASS_RANGER;
    }

    void Sync(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* player = GetTarget();
        for (uint32 id : AdvantageCompanions)
        {
            Aura* companion = player->GetAura(id, player->GetGUID());
            if (!companion)
                companion = player->AddAura(sSpellMgr->GetSpellInfo(id),
                    id == 520614 ? (1 << EFFECT_1) : MAX_EFFECT_MASK, player);
            if (companion && companion->GetStackAmount() != GetStackAmount())
                companion->SetStackAmount(GetStackAmount());
        }
    }

    void Clear(AuraEffect const*, AuraEffectHandleModes)
    {
        for (uint32 id : AdvantageCompanions)
            GetTarget()->RemoveAurasDueToSpell(id, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_ranger_advantage::Sync,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_ranger_advantage::Clear,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

class ranger_secondary_hits : public AllSpellScript
{
public:
    ranger_secondary_hits() : AllSpellScript("ranger_secondary_hits",
        {ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (caster->IsPlayer() && caster->getClass() == CLASS_RANGER && info->SpellFamilyName == 27 &&
            !spell->IsTriggered() && sSpellMgr->GetFirstSpellInChain(info->Id) == 804712)
            if (Aura const* advantage = caster->GetAura(804329, caster->GetGUID()))
                spell->SetScriptValue(801935, 2000 * advantage->GetStackAmount());
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_RANGER || spell->GetSpellInfo()->SpellFamilyName != 27 ||
            miss != SPELL_MISS_NONE || !target || target == player || player->IsFriendlyTo(target))
            return;
        if (!spell->IsTriggered() && sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id) == 804712 &&
            !spell->GetScriptValue(804712))
        {
            spell->SetScriptValue(804712, 1);
            if (uint64 duration = spell->GetScriptValue(801935))
                if (SpellInfo const* flare = sSpellMgr->GetSpellInfo(801935))
                {
                    SpellCastTargets targets;
                    targets.SetUnitTarget(target);
                    targets.SetDst(target->GetPosition());
                    CustomSpellValues values;
                    values.AddSpellMod(SPELLVALUE_AURA_DURATION, int32(duration));
                    player->CastSpell(targets, flare, &values, TRIGGERED_FULL_MASK);
                }
        }
        if (spell->GetSpellInfo()->Id != 803105 || !target->IsAlive() ||
            !target->HasAuraState(AURA_STATE_BLEEDING) || spell->GetScriptValue(803106))
            return;
        spell->SetScriptValue(803106, 1);
        player->CastSpell(target, 803106, true);
    }
};

class ranger_secondary_contracts : public GlobalScript
{
public:
    ranger_secondary_contracts() : GlobalScript("ranger_secondary_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 27)
            return;
        if (info->Id == 807001 || info->Id == 520640)
            for (auto& effect : info->Effects)
                if (effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN)
                    effect.BasePoints = -2001;
        if (info->Id == 806342)
        {
            info->Effects[EFFECT_0].ChainTarget = info->MaxAffectedTargets;
            info->Effects[EFFECT_1].ChainTarget = info->MaxAffectedTargets;
        }
        if (info->Id == 520621)
            info->ProcFlags |= PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS;
        if (info->Id == 560805)
            info->ExcludeTargetAuraSpell = 570167;
        if (info->Id == 801935)
            info->UseRangedAttackPowerForDamage = true;
        for (uint32 id : AdvantageCompanions)
            if (info->Id == id)
            {
                info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
                info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
            }
    }
};

class spell_ascension_ranger_whipvine_targets : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_whipvine_targets);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_RANGER;
    }

    void Select(std::list<WorldObject*>& targets)
    {
        Unit* primary = GetExplTargetUnit();
        Aura const* advantage = GetCaster()->GetAura(804329, GetCaster()->GetGUID());
        uint32 const count = advantage ? std::min<uint32>(advantage->GetStackAmount(), 5) : 0;
        if (!primary || !count)
        {
            targets.clear();
            return;
        }
        float const radius = GetSpellInfo()->Effects[EFFECT_0].CalcRadius(GetCaster());
        targets.remove_if([primary, radius](WorldObject* object)
        {
            Unit* unit = object ? object->ToUnit() : nullptr;
            return !unit || !primary->IsWithinDistInMap(unit, radius) || !primary->IsWithinLOSInMap(unit);
        });
        targets.sort([primary](WorldObject const* left, WorldObject const* right)
        {
            return primary->GetExactDistSq(left) < primary->GetExactDistSq(right);
        });
        if (targets.size() > count)
            targets.resize(count);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_whipvine_targets::Select,
            EFFECT_0, TARGET_UNIT_TARGET_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_ranger_whipvine_targets::Select,
            EFFECT_1, TARGET_UNIT_TARGET_ENEMY);
    }
};

class spell_ascension_ranger_polearm_gate : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_polearm_gate);

    SpellCastResult CheckPolearm()
    {
        Player* player = GetCaster()->ToPlayer();
        Item* weapon = player ? player->GetWeaponForAttack(BASE_ATTACK, true) : nullptr;
        return weapon && weapon->IsFitToSpellRequirements(GetSpellInfo())
            ? SPELL_CAST_OK : SPELL_FAILED_EQUIPPED_ITEM_CLASS_MAINHAND;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_ranger_polearm_gate::CheckPolearm);
    }
};
}

void AddSC_AscensionRangerSecondary()
{
    RegisterSpellScript(aura_ascension_ranger_advantage);
    new ranger_secondary_hits();
    new ranger_secondary_contracts();
    RegisterSpellScript(spell_ascension_ranger_polearm_gate);
    RegisterSpellScript(spell_ascension_ranger_whipvine_targets);
}
