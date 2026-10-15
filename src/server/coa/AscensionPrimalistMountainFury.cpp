/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum MountainSpells : uint32
{
    MountainFury = 806185,
    MountainFuryCone = 807724,
    MountainFuryHit = 806186,
    MountainFuryDefense = 807434
};

class primalist_mountain_metadata : public GlobalScript
{
public:
    primalist_mountain_metadata() : GlobalScript("primalist_mountain_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 37)
            return;
        if (info->Id == MountainFuryCone &&
            info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CONE_ENEMY_54)
            info->Effects[EFFECT_0].RadiusEntry = sSpellRadiusStore.LookupEntry(13);
        if (info->Id == MountainFury && info->Effects[EFFECT_1].TriggerSpell == MountainFuryDefense)
        {
            info->Effects[EFFECT_1].Effect = 0;
            info->_InitializeExplicitTargetMask();
        }
    }
};

class primalist_mountain_scaling : public UnitScript
{
public:
    primalist_mountain_scaling() : UnitScript("primalist_mountain_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (!caster || !caster->IsPlayer() || caster->getClass() != CLASS_WILDWALKER ||
            info->SpellFamilyName != 37 || info->Id != MountainFuryHit || index != EFFECT_1 ||
            info->Effects[index].Effect != SPELL_EFFECT_SCHOOL_DAMAGE)
            return;
        value = std::clamp(value + caster->GetStat(STAT_STAMINA) * 1.25f,
            -float(std::numeric_limits<int32>::max() / 2), float(std::numeric_limits<int32>::max() / 2));
    }
};

class spell_ascension_mountain_fury_pull : public SpellScript
{
    PrepareSpellScript(spell_ascension_mountain_fury_pull);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MountainFuryDefense}); }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Defend(SpellEffIndex)
    {
        Unit* owner = GetCaster();
        Unit* target = GetHitUnit();
        if (owner->IsAlive() && target && target->IsAlive() && GetExplTargetDest() &&
            owner->IsValidAttackTarget(target))
            owner->CastSpell(owner, MountainFuryDefense, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_mountain_fury_pull::Defend,
            EFFECT_0, SPELL_EFFECT_PULL_TOWARDS_DEST);
    }
};
}

void AddSC_AscensionPrimalistMountainFury()
{
    new primalist_mountain_metadata();
    new primalist_mountain_scaling();
    RegisterSpellScript(spell_ascension_mountain_fury_pull);
}
