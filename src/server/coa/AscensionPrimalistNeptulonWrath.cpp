/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum NeptulonWrathSpells : uint32
{
    NeptulonWrath = 807467,
    NeptulonWrathBuff = 537250,
    NeptulonWrathDamage = 537252,
    Exhaustion = 573255
};

class primalist_neptulon_wrath_scaling : public UnitScript
{
public:
    primalist_neptulon_wrath_scaling() : UnitScript("primalist_neptulon_wrath_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index,
        float& value) override
    {
        if (caster && caster->IsPlayer() && caster->getClass() == CLASS_WILDWALKER &&
            info->Id == NeptulonWrath && index == EFFECT_0)
            value += std::clamp(caster->GetTotalAttackPowerValue(BASE_ATTACK) * 0.35f,
                0.0f, float(std::numeric_limits<int32>::max() / 2));
    }
};

class spell_ascension_neptulon_wrath : public SpellScript
{
    PrepareSpellScript(spell_ascension_neptulon_wrath);

    void Select(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* target)
        {
            Player* player = target->ToPlayer();
            return !player || player->HasAura(Exhaustion);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_neptulon_wrath::Select,
            EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID);
    }
};

class aura_ascension_neptulon_wrath : public AuraScript
{
    PrepareAuraScript(aura_ascension_neptulon_wrath);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->IsAlive() && event.GetActor() == owner &&
            victim && victim != owner && !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            (!event.GetSpellInfo() || event.GetSpellInfo()->Id != NeptulonWrathDamage);
    }

    void Register() override { DoCheckProc += AuraCheckProcFn(aura_ascension_neptulon_wrath::Check); }
};

class primalist_neptulon_wrath_metadata : public GlobalScript
{
public:
    primalist_neptulon_wrath_metadata() : GlobalScript("primalist_neptulon_wrath_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == NeptulonWrathBuff && info->SpellFamilyName == 37)
            info->ExcludeTargetAuraSpell = Exhaustion;
    }
};
}

void AddSC_AscensionPrimalistNeptulonWrath()
{
    new primalist_neptulon_wrath_scaling();
    new primalist_neptulon_wrath_metadata();
    RegisterSpellScript(spell_ascension_neptulon_wrath);
    RegisterSpellScript(aura_ascension_neptulon_wrath);
}
