/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionReaperTalents.h"
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
enum ReaperSecondarySpells : uint32
{
    SPELL_GHOST = 8326,
    SPELL_SPIRIT_WALKER = 561082,
    SPELL_SPIRIT_WALKER_SPEED = 561093,
    SPELL_ENDBRINGER = 800922,
    SPELL_GRAVESITE = 572213,
    SPELL_GRAVESITE_AREA = 804722,
    SPELL_ENDBRINGER_AMOUNT = 801341,
    SPELL_ENDBRINGER_HEAL = 520419,
    SPELL_DIRGE = 801328,
    SPELL_DIRGE_HIT = 801311,
    SPELL_REAPED_SOUL = 500363,
    SPELL_SPECTRE_HIT = 803742,
    SPELL_SPECTRE_ROOT = 803942,
    SPELL_MURDER = 500376,
    SPELL_HARD_BARGAIN = 300569,
    SPELL_TORMENTED_SOULS = 500481,
    SPELL_HARD_BARGAIN_HELPER = 572300,
    SPELL_CRIMSON_THIRST = 807415,
    SPELL_CRIMSON_STACK = 807416,
    SPELL_CRIMSON_AMOUNT = 807417,
    SPELL_CRIMSON_HEAL = 807545,
    SPELL_GHOSTLY_WEAPON = 803997,
    SPELL_GHOSTLY_WEAPON_FROST = 804474,
    SPELL_LAMENTING = 705397,
    SPELL_LAMENTING_HEAL = 807420,
    SPELL_SHADE = 573038
};

void HealFromDamage(Player* player, uint32 reference, uint32 helper, uint32 damage)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(reference);
    if (!info || !damage)
        return;
    uint64 amount = uint64(damage) * std::clamp(info->Effects[EFFECT_0].CalcValue(player), 0, 100) / 100;
    if (amount)
        player->CastCustomSpell(helper, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), player, TRIGGERED_FULL_MASK);
}

class reaper_ghost_speed : public UnitScript
{
public:
    reaper_ghost_speed() : UnitScript("reaper_ghost_speed", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !aura ||
            aura->GetCasterGUID() != player->GetGUID() ||
            (aura->GetId() != SPELL_GHOST && aura->GetId() != SPELL_SPIRIT_WALKER))
            return;
        if (player->HasAura(SPELL_GHOST, player->GetGUID()) &&
            player->HasAura(SPELL_SPIRIT_WALKER, player->GetGUID()) &&
            !player->HasAura(SPELL_SPIRIT_WALKER_SPEED, player->GetGUID()))
            player->CastSpell(player, SPELL_SPIRIT_WALKER_SPEED, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !application)
            return;
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() == player->GetGUID() &&
            (aura->GetId() == SPELL_GHOST || aura->GetId() == SPELL_SPIRIT_WALKER))
            player->RemoveAurasDueToSpell(SPELL_SPIRIT_WALKER_SPEED, player->GetGUID());
    }
};

class reaper_hard_bargain : public UnitScript
{
public:
    reaper_hard_bargain() : UnitScript("reaper_hard_bargain", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !aura ||
            aura->GetCasterGUID() != player->GetGUID() ||
            (aura->GetId() != SPELL_HARD_BARGAIN && aura->GetId() != SPELL_TORMENTED_SOULS))
            return;

        if (player->HasAura(SPELL_HARD_BARGAIN, player->GetGUID()) &&
            player->HasAura(SPELL_TORMENTED_SOULS, player->GetGUID()) &&
            !player->HasAura(SPELL_HARD_BARGAIN_HELPER, player->GetGUID()))
            player->CastSpell(player, SPELL_HARD_BARGAIN_HELPER, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !application)
            return;

        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() == player->GetGUID() &&
            (aura->GetId() == SPELL_HARD_BARGAIN || aura->GetId() == SPELL_TORMENTED_SOULS))
            player->RemoveAurasDueToSpell(SPELL_HARD_BARGAIN_HELPER, player->GetGUID());
    }
};

class reaper_secondary_hits : public AllSpellScript
{
public:
    reaper_secondary_hits() : AllSpellScript("reaper_secondary_hits",
        {ALLSPELLHOOK_ON_BEFORE_EFFECTS, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (caster->IsPlayer() && caster->getClass() == CLASS_REAPER && !spell->IsTriggered() &&
            sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_MURDER)
            if (Aura const* stacks = caster->GetAura(SPELL_CRIMSON_STACK, caster->GetGUID()))
                spell->SetScriptValue(SPELL_CRIMSON_STACK, stacks->GetStackAmount());
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (info->Id == SPELL_ENDBRINGER && caster->IsPlayer() && caster->getClass() == CLASS_REAPER &&
            !spell->IsTriggered() && caster->HasAura(SPELL_GRAVESITE, caster->GetGUID()))
            caster->CastSpell(caster, SPELL_GRAVESITE_AREA, true);

        if (caster->IsPlayer() && caster->getClass() == CLASS_REAPER && !spell->IsTriggered() &&
            sSpellMgr->GetFirstSpellInChain(info->Id) == SPELL_MURDER &&
            spell->GetScriptValue(SPELL_CRIMSON_STACK))
            caster->RemoveAurasDueToSpell(SPELL_CRIMSON_STACK, caster->GetGUID());
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_REAPER || !player->IsAlive() || !player->IsInWorld() ||
            miss != SPELL_MISS_NONE || !target || target == player || player->IsFriendlyTo(target))
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (id == SPELL_DIRGE_HIT && player->HasAura(SPELL_ENDBRINGER, player->GetGUID()))
            HealFromDamage(player, SPELL_ENDBRINGER_AMOUNT, SPELL_ENDBRINGER_HEAL, damage);
        if (id == SPELL_GHOSTLY_WEAPON_FROST && player->HasAura(SPELL_LAMENTING, player->GetGUID()))
            HealFromDamage(player, SPELL_LAMENTING, SPELL_LAMENTING_HEAL, damage);
        if (id == SPELL_SPECTRE_HIT && target->IsAlive())
            player->CastSpell(target, SPELL_SPECTRE_ROOT, true);
        if (spell->IsTriggered())
            return;
        uint32 root = sSpellMgr->GetFirstSpellInChain(id);
        if (root == SPELL_DIRGE && player->HasAura(SPELL_ENDBRINGER, player->GetGUID()) &&
            !spell->GetScriptValue(SPELL_REAPED_SOUL))
        {
            spell->SetScriptValue(SPELL_REAPED_SOUL, 1);
            for (uint8 i = 0; i < 3; ++i)
                HandleAscensionReaperResource(player, SPELL_REAPED_SOUL, 1);
        }
        if (root == SPELL_MURDER && spell->GetScriptValue(SPELL_CRIMSON_STACK) >= 5)
            HealFromDamage(player, SPELL_CRIMSON_AMOUNT, SPELL_CRIMSON_HEAL, damage);
    }
};

class aura_ascension_gravesite : public AuraScript
{
    PrepareAuraScript(aura_ascension_gravesite);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* victim = event.GetActionTarget();
        if (!player->IsPlayer() || player->getClass() != CLASS_REAPER || GetCaster() != player ||
            event.GetActor() != player || !victim || victim == player || player->IsFriendlyTo(victim) ||
            !event.GetDamageInfo() || !event.GetDamageInfo()->GetDamage() ||
            !(event.GetHitMask() & PROC_HIT_CRITICAL) ||
            (event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC)))
            return false;

        return victim->HasAura(SPELL_GRAVESITE_AREA);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_gravesite::Check);
    }
};

class aura_ascension_crimson_thirst : public AuraScript
{
    PrepareAuraScript(aura_ascension_crimson_thirst);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* victim = event.GetActionTarget();
        return player->IsPlayer() && player->getClass() == CLASS_REAPER && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && victim && victim != player &&
            !player->IsFriendlyTo(victim) && event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() &&
            (event.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
    }

    void Proc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SPELL_CRIMSON_STACK, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_CRIMSON_STACK, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_crimson_thirst::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_crimson_thirst::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_crimson_thirst::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_reaper_shade : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_shade);

    bool Validate(SpellInfo const* info) override
    {
        SpellEffectInfo const& effect = info->Effects[EFFECT_0];
        return info->Id == SPELL_SHADE &&
            effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_TRANSFORM &&
            effect.TargetA.GetTarget() == TARGET_UNIT_CASTER;
    }

    void RemoveImpairment(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* target = GetTarget();
        if (target)
            target->RemoveMovementImpairingAuras(true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_shade::RemoveImpairment,
            EFFECT_0, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_ghostly_weapon : public AuraScript
{
    PrepareAuraScript(aura_ascension_ghostly_weapon);

    bool Validate(SpellInfo const* info) override
    {
        SpellInfo const* frost = sSpellMgr->GetSpellInfo(SPELL_GHOSTLY_WEAPON_FROST);
        return info->Id == SPELL_GHOSTLY_WEAPON && info->Effects[EFFECT_0].ApplyAuraName == 354 &&
            frost && frost->SchoolMask == SPELL_SCHOOL_MASK_FROST &&
            frost->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE;
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* spell = event.GetSpellInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_REAPER && owner->IsAlive() &&
            GetCasterGUID() == owner->GetGUID() && event.GetActor() == owner && victim &&
            victim->IsAlive() && !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            damage->GetDamageType() != DOT && (!spell || spell->Id != SPELL_GHOSTLY_WEAPON_FROST) &&
            (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS));
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::max(0, effect->GetAmount()) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(SPELL_GHOSTLY_WEAPON_FROST, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_ghostly_weapon::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_ghostly_weapon::Proc, EFFECT_0, AuraType(354));
    }
};

class reaper_secondary_metadata : public GlobalScript
{
public:
    reaper_secondary_metadata() : GlobalScript("reaper_secondary_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 36)
            return;
        if (info->Id == SPELL_ENDBRINGER)
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
            info->ProcFlags = 0;
        }
        if (info->Id == SPELL_ENDBRINGER_HEAL)
            info->DmgClass = SPELL_DAMAGE_CLASS_NONE;
        if (info->Id == SPELL_SPIRIT_WALKER_SPEED || info->Id == SPELL_CRIMSON_STACK ||
            info->Id == SPELL_HARD_BARGAIN_HELPER)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
        if (info->Id == SPELL_GHOSTLY_WEAPON_FROST)
            info->AscensionInheritsResolvedAmount = true;
    }
};
}

void AddSC_AscensionReaperSecondary()
{
    new reaper_ghost_speed();
    new reaper_hard_bargain();
    new reaper_secondary_hits();
    new reaper_secondary_metadata();
    RegisterSpellScript(aura_ascension_gravesite);
    RegisterSpellScript(aura_ascension_crimson_thirst);
    RegisterSpellScript(aura_ascension_reaper_shade);
    RegisterSpellScript(aura_ascension_ghostly_weapon);
}
