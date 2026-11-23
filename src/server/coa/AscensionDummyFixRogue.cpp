/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "CellImpl.h"
#include "Containers.h"
#include "DynamicObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <list>
#include <vector>

namespace
{
template <std::size_t Count>
bool IsAnyOf(std::array<uint32, Count> const& ids, uint32 id)
{
    return std::find(ids.begin(), ids.end(), id) != ids.end();
}

bool HasDamageEffect(SpellInfo const* info)
{
    for (SpellEffectInfo const& effect : info->Effects)
    {
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
                return true;
            default:
                break;
        }
        if (effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE))
            return true;
    }
    return false;
}

bool SpellHasEffect(SpellInfo const* info, SpellEffects type)
{
    return std::any_of(std::begin(info->Effects), std::end(info->Effects),
        [type](SpellEffectInfo const& effect) { return effect.Effect == type; });
}

uint32 BleedsFrom(Unit const* target, ObjectGuid caster)
{
    uint32 count = 0;
    for (auto const& [id, application] : target->GetAppliedAuras())
    {
        Aura const* aura = application->GetBase();
        if (aura->GetCasterGUID() == caster &&
            (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (uint64(1) << MECHANIC_BLEED)))
            ++count;
    }
    return count;
}

void CastAt(Unit* caster, Unit* target, uint32 spellId, int32 const* bp0, AuraEffect const* triggeredBy)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    if (!info)
        return;
    SpellCastTargets targets;
    targets.SetUnitTarget(target);
    targets.SetDst(*target);
    CustomSpellValues values;
    if (bp0)
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, *bp0);
    caster->CastSpell(targets, info, &values, TRIGGERED_FULL_MASK, nullptr, triggeredBy);
}

int32 CustomPoints(uint32 spellId, int32 amount)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    return info && info->Effects[EFFECT_0].DieSides ? amount - 1 : amount;
}

enum FinisherFlags : uint8
{
    FINISHER_DAMAGING          = 0x01,
    FINISHER_ROGUE             = 0x02,
    FINISHER_MELEE             = 0x04,
    FINISHER_NOT_SHAPESHIFTED  = 0x08,
    FINISHER_BLADE_FLURRY      = 0x10,
    FINISHER_DAGGER            = 0x20,
};

struct FinisherProc
{
    uint32 Aura;
    uint8 Effect;
    float ChancePerPoint;
    uint32 Trigger;
    uint8 Flags;
};

constexpr std::array<FinisherProc, 13> FINISHER_PROCS = {{
    { 285279, EFFECT_0, 0.0f, 285283, 0 },
    { 1589466, EFFECT_0, 20.0f, 1589467, 0 },
    { 283833, EFFECT_0, 0.0f, 0, 0 },
    { 977856, EFFECT_0, 0.0f, 0, 0 },
    { 285111, EFFECT_0, 20.0f, 285115, FINISHER_NOT_SHAPESHIFTED },
    { 983110, EFFECT_1, 0.0f, 0, FINISHER_DAMAGING | FINISHER_NOT_SHAPESHIFTED },
    { 277924, EFFECT_0, 0.0f, 277923, FINISHER_DAMAGING | FINISHER_ROGUE | FINISHER_DAGGER },
    { 285017, EFFECT_0, 0.0f, 0, 0 },
    { 284148, EFFECT_0, 0.0f, 979105, 0 },
    { 979106, EFFECT_0, 0.0f, 979105, 0 },
    { 275094, EFFECT_0, 0.0f, 275096, 0 },
    { 285477, EFFECT_0, 20.0f, 0, FINISHER_DAMAGING | FINISHER_MELEE | FINISHER_BLADE_FLURRY },
    { 986038, EFFECT_0, 20.0f, 0, FINISHER_DAMAGING | FINISHER_MELEE | FINISHER_BLADE_FLURRY },
}};

constexpr std::array<uint32, 3> BLADE_FLURRY = { 13877, 1113877, 1213877 };

FinisherProc const* FinisherProcByAura(uint32 id)
{
    for (FinisherProc const& rule : FINISHER_PROCS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_rogue_finisher_proc : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_finisher_proc);

    ObjectGuid _target;

    bool Validate(SpellInfo const* info) override
    {
        FinisherProc const* rule = FinisherProcByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Trigger ? rule->Trigger : info->Effects[rule->Effect].TriggerSpell });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        _target.Clear();
        FinisherProc const* rule = FinisherProcByAura(GetId());
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !info || !player || !info->NeedsComboPoints())
            return false;
        if ((rule->Flags & FINISHER_DAMAGING) && !HasDamageEffect(info))
            return false;
        if ((rule->Flags & FINISHER_ROGUE) && info->SpellFamilyName != SPELLFAMILY_ROGUE)
            return false;
        if ((rule->Flags & FINISHER_MELEE) && info->DmgClass != SPELL_DAMAGE_CLASS_MELEE)
            return false;
        if (rule->Flags & FINISHER_NOT_SHAPESHIFTED)
        {
            ShapeshiftForm const form = player->GetShapeshiftForm();
            if (form != FORM_NONE && form != FORM_STEALTH && form != FORM_SHADOW_DANCE)
                return false;
        }
        if ((rule->Flags & FINISHER_BLADE_FLURRY) &&
            std::none_of(BLADE_FLURRY.begin(), BLADE_FLURRY.end(), [player](uint32 id) { return player->HasAura(id); }))
            return false;
        if (rule->Flags & FINISHER_DAGGER)
        {
            Item const* weapon = player->GetWeaponForAttack(BASE_ATTACK, true);
            if (!weapon || weapon->GetTemplate()->SubClass != ITEM_SUBCLASS_WEAPON_DAGGER)
                return false;
        }
        uint8 const points = player->GetComboPoints();
        if (!points)
            return false;
        float const perPoint = rule->ChancePerPoint > 0.0f ? rule->ChancePerPoint :
            GetSpellInfo()->Effects[rule->Effect].PointsPerComboPoint;
        if (!roll_chance_f(perPoint * points))
            return false;
        if (Spell const* spell = eventInfo.GetProcSpell())
            if (Unit* target = spell->m_targets.GetUnitTarget())
                _target = target->GetGUID();
        return true;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        FinisherProc const* rule = FinisherProcByAura(GetId());
        if (!rule || aurEff->GetEffIndex() != rule->Effect)
            return;
        SpellInfo const* trigger = sSpellMgr->GetSpellInfo(rule->Trigger ? rule->Trigger :
            GetSpellInfo()->Effects[rule->Effect].TriggerSpell);
        if (!trigger)
            return;
        Unit* owner = GetTarget();
        Unit* enemy = nullptr;
        if (!_target.IsEmpty())
            if (Unit* unit = ObjectAccessor::GetUnit(*owner, _target))
                if (unit->IsAlive())
                    enemy = unit;
        SpellImplicitTargetInfo const& aim = trigger->Effects[EFFECT_0].TargetA;
        if (aim.GetReferenceType() == TARGET_REFERENCE_TYPE_DEST)
        {
            WorldObject const* at = enemy ? static_cast<WorldObject const*>(enemy) : owner;
            owner->CastSpell(at->GetPositionX(), at->GetPositionY(), at->GetPositionZ(), trigger->Id, true, nullptr, aurEff);
            return;
        }
        owner->CastSpell(aim.GetTarget() == TARGET_UNIT_TARGET_ENEMY && enemy ? enemy : owner, trigger, true, nullptr,
            aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_finisher_proc::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_finisher_proc::HandleProc, EFFECT_ALL, SPELL_AURA_DUMMY);
    }
};

struct LearnWith
{
    uint32 Aura;
    uint8 Effect;
};

constexpr std::array<LearnWith, 3> LEARN_WITH = {{
    { 979113, EFFECT_0 },
    { 979080, EFFECT_1 },
    { 977810, EFFECT_0 },
}};

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(sSpellMgr->GetFirstSpellInChain(spell)); rank;
         rank = rank->GetNextRankSpell())
        if (player->HasSpell(rank->Id))
            return true;
    return false;
}

class spell_dummyfix_rogue_learn_with : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_learn_with);

    bool _taught = false;

    bool Mine(AuraEffect const* aurEff) const
    {
        uint32 const id = GetId();
        uint8 const effIndex = aurEff->GetEffIndex();
        return std::any_of(LEARN_WITH.begin(), LEARN_WITH.end(),
            [id, effIndex](LearnWith const& rule) { return rule.Aura == id && rule.Effect == effIndex; });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !Mine(aurEff))
            return;
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[aurEff->GetEffIndex()];
        uint32 const required = uint32(effect.MiscValue);
        uint32 const taught = uint32(effect.MiscValueB);
        if (!sSpellMgr->GetSpellInfo(required) || !sSpellMgr->GetSpellInfo(taught) || player->HasSpell(taught) ||
            !KnowsAnyRank(player, required))
            return;
        player->learnSpell(taught, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught || !Mine(aurEff))
            return;
        _taught = false;
        player->removeSpell(uint32(GetSpellInfo()->Effects[aurEff->GetEffIndex()].MiscValueB), SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_rogue_learn_with::HandleApply, EFFECT_ALL, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_rogue_learn_with::HandleRemove, EFFECT_ALL, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

struct PoisonBombRule
{
    uint32 Spell;
    uint8 Stacks;
};

constexpr std::array<PoisonBombRule, 6> POISON_BOMBS = {{
    { 284169, 2 }, { 979114, 2 }, { 1586625, 1 },
    { 284171, 1 }, { 979115, 1 }, { 1586626, 1 },
}};
constexpr uint32 DEADLY_POISON_FIRST = 2818;

class spell_dummyfix_rogue_poison_bomb : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_poison_bomb);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DEADLY_POISON_FIRST });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || !caster->IsValidAttackTarget(target))
            return;
        uint32 const id = GetSpellInfo()->Id;
        auto const rule = std::find_if(POISON_BOMBS.begin(), POISON_BOMBS.end(),
            [id](PoisonBombRule const& r) { return r.Spell == id; });
        SpellInfo const* poison = sSpellMgr->GetSpellInfo(sSpellMgr->GetLastSpellInChain(DEADLY_POISON_FIRST));
        while (poison && poison->SpellLevel > caster->GetLevel() && poison->GetPrevRankSpell())
            poison = poison->GetPrevRankSpell();
        if (rule == POISON_BOMBS.end() || !poison)
            return;
        for (uint8 i = 0; i < rule->Stacks; ++i)
            caster->CastSpell(target, poison, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_rogue_poison_bomb::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 SHADOW_BLADES_DAMAGE = 1180001;

class spell_dummyfix_rogue_shadow_blades : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_shadow_blades);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SHADOW_BLADES_DAMAGE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return info && damage && damage->GetDamage() && eventInfo.GetProcTarget() && !info->NeedsComboPoints() &&
            info->DmgClass == SPELL_DAMAGE_CLASS_MELEE && SpellHasEffect(info, SPELL_EFFECT_ADD_COMBO_POINTS) &&
            !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        int32 amount = CustomPoints(SHADOW_BLADES_DAMAGE,
            int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount())));
        if (amount > 0)
            owner->CastCustomSpell(target, SHADOW_BLADES_DAMAGE, &amount, nullptr, nullptr, true, nullptr, aurEff);
        owner->AddComboPoints(target, 1);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_shadow_blades::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_shadow_blades::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 INSTIGATOR = 977915;
constexpr std::array<uint32, 5> GHOSTLY_STRIKE = { 14278, 1114278, 1214278, 1398241, 1464278 };

class spell_dummyfix_rogue_instigator : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_instigator);

    void HandleHit()
    {
        Unit* target = GetHitUnit();
        AuraEffect const* instigator = GetCaster()->GetAuraEffect(INSTIGATOR,
            IsAnyOf(GHOSTLY_STRIKE, GetSpellInfo()->Id) ? EFFECT_0 : EFFECT_1);
        if (!target || !instigator || !GetHitDamage() || !target->HealthAbovePct(75))
            return;
        int32 damage = GetHitDamage();
        AddPct(damage, instigator->GetAmount());
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_dummyfix_rogue_instigator::HandleHit);
    }
};

constexpr std::array<uint32, 2> CONSUMED_BY_SHADOWS = { 285859, 997217 };
constexpr uint32 SHADOWFORM = 15473;

class spell_dummyfix_rogue_stealth : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_stealth);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->IsAlive() || GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            return;
        if (std::none_of(CONSUMED_BY_SHADOWS.begin(), CONSUMED_BY_SHADOWS.end(),
                [player](uint32 id) { return player->HasAura(id); }))
            return;
        if (!player->HasSpell(SHADOWFORM))
            return;
        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([player, guid]()
        {
            if (player->IsInWorld() && player->GetGUID() == guid && player->IsAlive() && !player->HasAura(SHADOWFORM))
                player->CastSpell(player, SHADOWFORM, true);
        }, 1ms);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_rogue_stealth::HandleRemove, EFFECT_ALL,
            SPELL_AURA_MOD_STEALTH, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_dummyfix_rogue_bathe_in_blood : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_bathe_in_blood);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ 275862, 983095 });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target)
            return;
        uint32 const buff = GetSpellInfo()->Id == 983097 ? 983095 : 275862;
        uint32 const bleeds = BleedsFrom(target, caster->GetGUID());
        for (uint32 i = 0; i < bleeds; ++i)
            caster->CastSpell(caster, buff, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_rogue_bathe_in_blood::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 FREEZING_BLOOD = 284205;
constexpr uint32 FREEZING_BLOOD_BUFF = 284210;

class spell_dummyfix_rogue_cold_blood : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_cold_blood);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FREEZING_BLOOD_BUFF });
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* owner = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_DEFAULT || !owner->IsAlive() ||
            !owner->HasAura(FREEZING_BLOOD))
            return;
        owner->CastSpell(owner, FREEZING_BLOOD_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_rogue_cold_blood::HandleRemove, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 GLYPH_OF_PREPARATION_CLASSLESS = 118438;
constexpr uint32 GLYPH_OF_PREPARATION = 56819;

class spell_dummyfix_rogue_preparation : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_preparation);

    void HandleDummy(SpellEffIndex )
    {
        Player* caster = GetCaster()->ToPlayer();
        if (!caster || !caster->HasAura(GLYPH_OF_PREPARATION_CLASSLESS) || caster->HasAuraOrTwin(GLYPH_OF_PREPARATION))
            return;
        std::vector<uint32> resets;
        for (auto const& [id, spell] : caster->GetSpellMap())
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            if (!info || info->SpellFamilyName != SPELLFAMILY_ROGUE)
                continue;
            if ((info->SpellFamilyFlags[1] & SPELLFAMILYFLAG1_ROGUE_DISMANTLE) ||
                (info->SpellFamilyFlags[0] & SPELLFAMILYFLAG_ROGUE_KICK) ||
                ((info->SpellFamilyFlags[0] & SPELLFAMILYFLAG_ROGUE_BLADE_FLURRY) &&
                 (info->SpellFamilyFlags[1] & SPELLFAMILYFLAG1_ROGUE_BLADE_FLURRY)))
                resets.push_back(id);
        }
        for (uint32 id : resets)
            caster->RemoveSpellCooldown(id, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_rogue_preparation::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 MASSACRE_TALENT = 283139;
constexpr uint32 MASSACRE_DEBUFF = 283135;
constexpr uint32 MASSACRE_ENCHANT = 415001;
constexpr std::array<uint32, 3> KILLING_SPREE = { 51690, 1151690, 1251690 };

class spell_dummyfix_rogue_massacre : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_massacre);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MASSACRE_DEBUFF });
    }

    void HandleAfterCast()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (!target || target == caster || !caster->HasAura(MASSACRE_TALENT) || caster->HasAura(MASSACRE_ENCHANT) ||
            std::none_of(KILLING_SPREE.begin(), KILLING_SPREE.end(), [caster](uint32 id) { return caster->HasAura(id); }))
            return;
        caster->CastSpell(target, MASSACRE_DEBUFF, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_rogue_massacre::HandleAfterCast);
    }
};

constexpr uint32 DUAL_WIELD_SPECIALIZATION = 913715;

class spell_dummyfix_rogue_dual_wield_specialization : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_dual_wield_specialization);

    void CalcAmount(AuraEffect const* , int32& amount, bool& canBeRecalculated)
    {
        canBeRecalculated = true;
        Player* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        if (!player || !player->GetWeaponForAttack(OFF_ATTACK, true))
            amount = 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_rogue_dual_wield_specialization::CalcAmount, EFFECT_0,
            SPELL_AURA_MOD_CRIT_PCT);
    }
};

class dummyfix_rogue_player_hooks : public PlayerScript
{
public:
    dummyfix_rogue_player_hooks() : PlayerScript("dummyfix_rogue_player_hooks",
        { PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT }) { }

    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item* ) override
    {
        if (!player || (slot != EQUIPMENT_SLOT_MAINHAND && slot != EQUIPMENT_SLOT_OFFHAND) ||
            !player->HasAura(DUAL_WIELD_SPECIALIZATION))
            return;
        ObjectGuid const guid = player->GetGUID();
        player->m_Events.AddEventAtOffset([player, guid]()
        {
            if (!player->IsInWorld() || player->GetGUID() != guid)
                return;
            if (AuraEffect* effect = player->GetAuraEffect(DUAL_WIELD_SPECIALIZATION, EFFECT_0))
                effect->RecalculateAmount();
        }, 1ms);
    }
};

struct SpreeRule
{
    uint32 Spree;
    uint32 Blitz;
};

constexpr std::array<SpreeRule, 5> SPREES = {{
    { 913465, 913466 }, { 913462, 913463 }, { 913450, 913451 }, { 913456, 913457 }, { 913459, 913460 },
}};
constexpr uint32 KILLING_SPREE_TELEPORT = 57840;

SpreeRule const* SpreeBySpell(uint32 id)
{
    for (SpreeRule const& rule : SPREES)
        if (rule.Spree == id)
            return &rule;
    return nullptr;
}

#define DummyFixRogueSpreeScriptName "spell_dummyfix_rogue_spree"

class spell_dummyfix_rogue_spree_aura : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_spree_aura);

    GuidList _targets;

    bool Validate(SpellInfo const* info) override
    {
        SpreeRule const* rule = SpreeBySpell(info->Id);
        return rule && ValidateSpellInfo({ rule->Blitz, KILLING_SPREE_TELEPORT });
    }

    void HandlePeriodic(AuraEffect const* )
    {
        SpreeRule const* rule = SpreeBySpell(GetId());
        Unit* owner = GetTarget();
        if (!rule)
            return;
        while (!_targets.empty())
        {
            ObjectGuid const guid = Acore::Containers::SelectRandomContainerElement(_targets);
            Unit* target = ObjectAccessor::GetUnit(*owner, guid);
            if (!target || !owner->IsValidAttackTarget(target) || target->HasStealthAura() || target->HasInvisibilityAura())
            {
                _targets.remove(guid);
                continue;
            }
            owner->CastSpell(target, KILLING_SPREE_TELEPORT, true);
            if (Player* player = owner->ToPlayer())
                if (player->IsBeingTeleportedNear())
                {
                    WorldLocation const& dest = player->GetTeleportDest();
                    player->UpdatePosition(dest, true);
                }
            owner->CastSpell(target, rule->Blitz, TriggerCastFlags(TRIGGERED_FULL_MASK & ~TRIGGERED_DONT_REPORT_CAST_ERROR));
            break;
        }
    }

public:
    void AddTarget(Unit* target)
    {
        _targets.push_back(target->GetGUID());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_rogue_spree_aura::HandlePeriodic, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_dummyfix_rogue_spree : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_spree);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        if (targets.empty() || GetCaster()->GetVehicleBase() || GetCaster()->HasUnitState(UNIT_STATE_ROOT))
            FinishCast(SPELL_FAILED_OUT_OF_RANGE);
        else
        {
            GetCaster()->RemoveAurasWithInterruptFlags(AURA_INTERRUPT_FLAG_CAST);
            GetCaster()->RemoveAurasWithInterruptFlags(AURA_INTERRUPT_FLAG_SPELL_ATTACK);
        }
    }

    void HandleDummy(SpellEffIndex )
    {
        Aura* aura = GetCaster()->GetAura(GetSpellInfo()->Id);
        Unit* target = GetHitUnit();
        if (!aura || !target)
            return;
        if (auto* script = dynamic_cast<spell_dummyfix_rogue_spree_aura*>(aura->GetScriptByName(DummyFixRogueSpreeScriptName)))
            script->AddTarget(target);
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_rogue_spree::FilterTargets, EFFECT_1,
            TARGET_UNIT_DEST_AREA_ENEMY);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_rogue_spree::HandleDummy, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint8 APPRENTICE_STACKS = 3;

class spell_dummyfix_rogue_apprentice_of_shadows : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_apprentice_of_shadows);

    bool CheckStacks(AuraEffect const* , ProcEventInfo& )
    {
        return GetStackAmount() >= APPRENTICE_STACKS;
    }

    void ConsumeStacks(AuraEffect const* , ProcEventInfo& )
    {
        ModStackAmount(-int32(APPRENTICE_STACKS));
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_dummyfix_rogue_apprentice_of_shadows::CheckStacks, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_apprentice_of_shadows::ConsumeStacks, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SHADOW_OF_DEATH_DAMAGE = 272815;
constexpr uint32 ROGUE_SHADOWSTEP_FLAG_1 = 0x00000200;
constexpr uint32 ROGUE_AMBUSH_FLAG = 0x00000200;
constexpr uint32 DRUID_RAVAGE_FLAG = 0x00010000;

class spell_dummyfix_rogue_shadow_of_death : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_shadow_of_death);

    bool _armed = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SHADOW_OF_DEATH_DAMAGE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info)
            return false;
        if (info->SpellFamilyName == SPELLFAMILY_ROGUE && (info->SpellFamilyFlags[1] & ROGUE_SHADOWSTEP_FLAG_1) &&
            (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST))
        {
            _armed = true;
            return false;
        }
        bool const empowered =
            (info->SpellFamilyName == SPELLFAMILY_ROGUE && (info->SpellFamilyFlags[0] & ROGUE_AMBUSH_FLAG)) ||
            (info->SpellFamilyName == SPELLFAMILY_DRUID && (info->SpellFamilyFlags[0] & DRUID_RAVAGE_FLAG));
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return _armed && empowered && (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) && damage &&
            damage->GetDamage() && eventInfo.GetProcTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        _armed = false;
        int32 amount = CustomPoints(SHADOW_OF_DEATH_DAMAGE,
            int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount())));
        if (amount > 0)
            CastAt(GetTarget(), eventInfo.GetProcTarget(), SHADOW_OF_DEATH_DAMAGE, &amount, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_shadow_of_death::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_shadow_of_death::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SHADOW_MARK = 272811;
constexpr uint32 ROGUE_DEADLY_THROW_FLAG_1 = 0x00000001;

class spell_dummyfix_rogue_swift_shadows : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_swift_shadows);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({ SHADOW_MARK, info->Effects[EFFECT_0].TriggerSpell });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Unit* target = eventInfo.GetProcTarget();
        if (!info || !target || !target->HasAura(SHADOW_MARK, GetTarget()->GetGUID()))
            return false;
        return (info->SpellFamilyName == SPELLFAMILY_ROGUE && ((info->SpellFamilyFlags[0] & ROGUE_AMBUSH_FLAG) ||
                    (info->SpellFamilyFlags[1] & ROGUE_DEADLY_THROW_FLAG_1))) ||
            (info->SpellFamilyName == SPELLFAMILY_DRUID && (info->SpellFamilyFlags[0] & DRUID_RAVAGE_FLAG));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), GetSpellInfo()->Effects[EFFECT_0].TriggerSpell, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_swift_shadows::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_swift_shadows::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SWORD_AND_BOARD_FIRST = 46951;
constexpr uint32 SWORD_AND_BOARD_BUFF = 50227;
constexpr uint32 ROGUE_HEMORRHAGE_FLAGS = 0x02800000;
constexpr uint32 ROGUE_GHOSTLY_STRIKE_FLAGS = 0x44000000;

class spell_dummyfix_rogue_bloody_resets : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_bloody_resets);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SWORD_AND_BOARD_FIRST, SWORD_AND_BOARD_BUFF });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info || info->SpellFamilyName != SPELLFAMILY_ROGUE || info->SpellFamilyFlags[1] || info->SpellFamilyFlags[2] ||
            (info->SpellFamilyFlags[0] != ROGUE_HEMORRHAGE_FLAGS && info->SpellFamilyFlags[0] != ROGUE_GHOSTLY_STRIKE_FLAGS))
            return false;
        Aura const* talent = GetTarget()->GetAuraOfRankedSpell(SWORD_AND_BOARD_FIRST);
        return talent && roll_chance_i(talent->GetSpellInfo()->ProcChance);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), SWORD_AND_BOARD_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_bloody_resets::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_bloody_resets::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 INSATIABLE_BLOOD = 102220;
constexpr std::array<std::array<uint32, 3>, 2> SOULFLAYER = {{ { 275865, 275862, 275863 }, { 983070, 983095, 983096 } }};

class spell_dummyfix_rogue_hunger_for_blood : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_hunger_for_blood);

    void HandleAfterCast()
    {
        Player* player = GetCaster()->ToPlayer();
        AuraEffect const* talent = player ? player->GetAuraEffect(INSATIABLE_BLOOD, EFFECT_1) : nullptr;
        if (!talent || talent->GetAmount() >= 0)
            return;
        Unit* target = GetExplTargetUnit();
        if (!target)
            target = player->GetSelectedUnit();
        if (!target || target == player)
            return;
        if (uint32 const bleeds = BleedsFrom(target, player->GetGUID()))
            player->ModifySpellCooldown(GetSpellInfo()->Id, talent->GetAmount() * int32(bleeds));
    }

    void HandleFavour()
    {
        Unit* caster = GetCaster();
        for (auto const& [talent, bathe, favour] : SOULFLAYER)
        {
            if (!caster->HasAura(talent) || !caster->HasAura(bathe))
                continue;
            caster->RemoveAurasDueToSpell(bathe);
            caster->CastSpell(caster, favour, true);
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_dummyfix_rogue_hunger_for_blood::HandleAfterCast);
        AfterCast += SpellCastFn(spell_dummyfix_rogue_hunger_for_blood::HandleFavour);
    }
};

constexpr uint32 EXPUNGE = 1584004;

class spell_dummyfix_rogue_cobra_venom : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_cobra_venom);

    bool _expunged = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ EXPUNGE });
    }

    void Expunge()
    {
        Unit* caster = GetCaster();
        if (_expunged || !caster || !caster->IsInWorld())
            return;
        _expunged = true;
        caster->CastSpell(GetTarget(), EXPUNGE, true);
    }

    void HandleStacks(AuraEffect const* , AuraEffectHandleModes )
    {
        if (_expunged || GetStackAmount() < GetSpellInfo()->StackAmount)
            return;
        Expunge();
        Unit* target = GetTarget();
        ObjectGuid const targetGuid = target->GetGUID();
        ObjectGuid const casterGuid = GetCasterGUID();
        uint32 const id = GetId();
        target->m_Events.AddEventAtOffset([target, targetGuid, casterGuid, id]()
        {
            if (target->IsInWorld() && target->GetGUID() == targetGuid)
                target->RemoveAurasDueToSpell(id, casterGuid);
        }, 1ms);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            Expunge();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_rogue_cobra_venom::HandleStacks, EFFECT_1,
            SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_rogue_cobra_venom::HandleRemove, EFFECT_1,
            SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 RELENTLESS_EVISCERATE = 986053;

class spell_dummyfix_rogue_relentless : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_relentless);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ RELENTLESS_EVISCERATE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetProcTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        int32 amount = int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount()));
        if (amount > 0)
            GetTarget()->CastCustomSpell(eventInfo.GetProcTarget(), RELENTLESS_EVISCERATE, &amount, nullptr, nullptr, true,
                nullptr, aurEff);
    }

    void PreventTrigger(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_relentless::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_relentless::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_relentless::PreventTrigger, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SINISTER_FINISHER_DAMAGE = 1180392;
constexpr float SINISTER_FINISHER_RANGE = 8.0f;

class spell_dummyfix_rogue_sinister_finisher : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_sinister_finisher);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SINISTER_FINISHER_DAMAGE });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && eventInfo.GetProcTarget();
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* primary = eventInfo.GetProcTarget();
        std::list<Unit*> enemies;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(primary, owner, SINISTER_FINISHER_RANGE);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(primary, enemies, check);
        Cell::VisitObjects(primary, searcher, SINISTER_FINISHER_RANGE);
        enemies.remove_if([owner, primary](Unit* unit)
            { return unit == primary || !unit->IsAlive() || !owner->IsValidAttackTarget(unit); });
        if (!enemies.empty())
        {
            Unit* extra = *std::min_element(enemies.begin(), enemies.end(),
                [primary](Unit* a, Unit* b) { return primary->GetExactDist(a) < primary->GetExactDist(b); });
            int32 amount = CustomPoints(SINISTER_FINISHER_DAMAGE,
                int32(CalculatePct(eventInfo.GetDamageInfo()->GetDamage(), aurEff->GetAmount())));
            if (amount > 0)
                owner->CastCustomSpell(extra, SINISTER_FINISHER_DAMAGE, &amount, nullptr, nullptr, true, nullptr, aurEff);
        }
        ModStackAmount(-1);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_rogue_sinister_finisher::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_sinister_finisher::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 ROGUE_SLICE_AND_DICE_FLAG = 0x00040000;

class spell_dummyfix_rogue_remorseless_attacks : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_rogue_remorseless_attacks);

    void HandleAfterProc(AuraEffect const* , ProcEventInfo& )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        AuraEffect* haste = player->GetAuraEffect(SPELL_AURA_MOD_MELEE_HASTE, SPELLFAMILY_ROGUE, ROGUE_SLICE_AND_DICE_FLAG,
            0, 0, player->GetGUID());
        if (!haste)
            return;
        Aura* sliceAndDice = haste->GetBase();
        int32 duration = sliceAndDice->GetSpellInfo()->GetMaxDuration();
        player->ApplySpellMod(sliceAndDice->GetId(), SPELLMOD_DURATION, duration);
        if (duration <= 0)
            return;
        sliceAndDice->SetMaxDuration(duration);
        sliceAndDice->SetDuration(duration);
    }

    void Register() override
    {
        AfterEffectProc += AuraEffectProcFn(spell_dummyfix_rogue_remorseless_attacks::HandleAfterProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 EDGE_OF_FURY_TALENT = 276397;
constexpr uint32 EDGE_OF_FURY_TOGGLE = 985227;

class spell_dummyfix_rogue_edge_of_fury_teleport : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_rogue_edge_of_fury_teleport);

    void HandleTeleport(SpellEffIndex effIndex)
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(EDGE_OF_FURY_TALENT) || caster->HasAura(EDGE_OF_FURY_TOGGLE))
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_rogue_edge_of_fury_teleport::HandleTeleport, EFFECT_0,
            SPELL_EFFECT_TELEPORT_UNITS);
    }
};

constexpr std::array<uint32, 4> SMOKE_BOMB_CLOUDS = { 954501, 954502, 2304501, 2304502 };

bool CrossesSmokeBombEdge(Unit* caster, Unit* target)
{
    std::vector<Unit*> owners = { caster, target };
    for (Unit* unit : { caster, target })
        for (uint32 cloudId : SMOKE_BOMB_CLOUDS)
        {
            auto const range = unit->GetAppliedAuras().equal_range(cloudId);
            for (auto itr = range.first; itr != range.second; ++itr)
                if (Unit* owner = itr->second->GetBase()->GetCaster())
                    owners.push_back(owner);
        }

    for (Unit* owner : owners)
    {
        if (owner == caster || !owner->IsInMap(caster) || !owner->IsValidAttackTarget(caster))
            continue;
        for (uint32 cloudId : SMOKE_BOMB_CLOUDS)
            if (DynamicObject* cloud = owner->GetDynObject(cloudId))
                if (cloud->IsWithinDistInMap(caster, cloud->GetRadius()) != cloud->IsWithinDistInMap(target, cloud->GetRadius()))
                    return true;
    }
    return false;
}

class dummyfix_rogue_smoke_bomb_targeting : public AllSpellScript
{
public:
    dummyfix_rogue_smoke_bomb_targeting() : AllSpellScript("dummyfix_rogue_smoke_bomb_targeting",
        { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

    void OnSpellCheckCast(Spell* spell, bool , SpellCastResult& result) override
    {
        if (result != SPELL_CAST_OK || spell->IsTriggered())
            return;
        Unit* caster = spell->GetCaster();
        Unit* target = spell->m_targets.GetUnitTarget();
        if (!caster || !target || caster == target || !caster->IsInMap(target))
            return;
        if (CrossesSmokeBombEdge(caster, target))
            result = SPELL_FAILED_LINE_OF_SIGHT;
    }
};

void SetPowerBonus(SpellInfo* spellInfo, bool periodic, float square)
{
    for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
    {
        SpellEffectInfo const& effect = spellInfo->Effects[i];
        if (periodic ? effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE) : effect.IsEffect(SPELL_EFFECT_SCHOOL_DAMAGE))
        {
            spellInfo->ComboPointPowerSquare[i] = square;
            spellInfo->ComboPointPowerFlat[i] = 0.0f;
            return;
        }
    }
}

bool InRanks(uint32 id, uint32 first, uint32 count)
{
    return id >= first && id < first + count;
}

constexpr std::array<uint32, 6> ELEMENTAL_FINISHES = { 904840, 904860, 904880, 904900, 904920, 904940 };
constexpr std::array<uint32, 6> ELEMENTAL_RUPTURES = { 904960, 904980, 907000, 907020, 907040, 907060 };
}

void ApplyAscensionDummyFixRogueContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    uint32 const id = spellInfo->Id;
    for (uint32 first : ELEMENTAL_FINISHES)
        if (InRanks(id, first, 12))
            SetPowerBonus(spellInfo, false, 0.02f);
    for (uint32 first : ELEMENTAL_RUPTURES)
        if (InRanks(id, first, 9))
            SetPowerBonus(spellInfo, true, 0.0039f);
    if (InRanks(id, 92789, 12))
        SetPowerBonus(spellInfo, false, 0.08f);
    else if (id == 277021 || id == 277022 || InRanks(id, 277031, 11))
        SetPowerBonus(spellInfo, false, 0.015f);
    else if (InRanks(id, 1578462, 3))
        SetPowerBonus(spellInfo, false, 0.01f);

    switch (id)
    {
        case 14179:
        case 58422:
        case 58423:
        case 913976:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_TARGET_TRIGGER;
                if (id == 913976)
                {
                    spellInfo->Effects[EFFECT_0].TriggerSpell = 13977;
                    spellInfo->Effects[EFFECT_0].BasePoints = 32;
                    spellInfo->Effects[EFFECT_0].DieSides = 1;
                    spellInfo->Effects[EFFECT_0].SpellClassMask = flag96(0x700, 0, 0);
                }
            }
            break;
        case 13801:
        case 13802:
        case 13803:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_MELEE_HASTE;
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_ARMOR_PENETRATION_PCT;
            break;
        case 914156:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 14157;
            }
            break;
        case 913715:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_CRIT_PCT;
                spellInfo->Effects[EFFECT_0].BasePoints = 1;
                spellInfo->Effects[EFFECT_0].DieSides = 1;
            }
            break;
        case 277924:
            spellInfo->EquippedItemClass = -1;
            spellInfo->EquippedItemSubClassMask = 0;
            break;
        case 1584004:
            if (spellInfo->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY)
            {
                spellInfo->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_TARGET_ENEMY);
                spellInfo->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
            }
            break;
        case 978302:
            if (spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_MOD_RATING_FROM_STAT;
                spellInfo->Effects[EFFECT_2].MiscValue = 1 << CR_CRIT_MELEE;
                spellInfo->Effects[EFFECT_2].MiscValueB = STAT_INTELLECT;
                spellInfo->Effects[EFFECT_2].BasePoints = 49;
                spellInfo->Effects[EFFECT_2].DieSides = 1;
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixRogueScripts()
{
    RegisterSpellScript(spell_dummyfix_rogue_finisher_proc);
    RegisterSpellScript(spell_dummyfix_rogue_learn_with);
    RegisterSpellScript(spell_dummyfix_rogue_poison_bomb);
    RegisterSpellScript(spell_dummyfix_rogue_shadow_blades);
    RegisterSpellScript(spell_dummyfix_rogue_instigator);
    RegisterSpellScript(spell_dummyfix_rogue_stealth);
    RegisterSpellScript(spell_dummyfix_rogue_bathe_in_blood);
    RegisterSpellScript(spell_dummyfix_rogue_cold_blood);
    RegisterSpellScript(spell_dummyfix_rogue_preparation);
    RegisterSpellScript(spell_dummyfix_rogue_massacre);
    RegisterSpellScript(spell_dummyfix_rogue_dual_wield_specialization);
    RegisterSpellAndAuraScriptPair(spell_dummyfix_rogue_spree, spell_dummyfix_rogue_spree_aura);
    RegisterSpellScript(spell_dummyfix_rogue_apprentice_of_shadows);
    RegisterSpellScript(spell_dummyfix_rogue_shadow_of_death);
    RegisterSpellScript(spell_dummyfix_rogue_swift_shadows);
    RegisterSpellScript(spell_dummyfix_rogue_bloody_resets);
    RegisterSpellScript(spell_dummyfix_rogue_hunger_for_blood);
    RegisterSpellScript(spell_dummyfix_rogue_cobra_venom);
    RegisterSpellScript(spell_dummyfix_rogue_relentless);
    RegisterSpellScript(spell_dummyfix_rogue_sinister_finisher);
    RegisterSpellScript(spell_dummyfix_rogue_remorseless_attacks);
    RegisterSpellScript(spell_dummyfix_rogue_edge_of_fury_teleport);
    new dummyfix_rogue_player_hooks();
    new dummyfix_rogue_smoke_bomb_targeting();
}
