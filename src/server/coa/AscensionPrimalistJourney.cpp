/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>

namespace
{
enum JourneySpells : uint32
{
    JourneyGround = 302534,
    CragDamage = 302590
};

class aura_ascension_journey_damage : public AuraScript
{
    PrepareAuraScript(aura_ascension_journey_damage);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && damage && damage->GetDamage();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_journey_damage::Check);
    }
};

class primalist_journey_metadata : public GlobalScript
{
public:
    primalist_journey_metadata() : GlobalScript("primalist_journey_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 37)
            return;
        if (info->Id == JourneyGround && info->Effects[EFFECT_1].TriggerSpell == CragDamage)
        {
            info->Effects[EFFECT_1].Effect = 0;
            info->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(0);
            info->Effects[EFFECT_1].TargetB = SpellImplicitTargetInfo(0);
        }
        else if (info->Id == CragDamage)
        {
            SpellInfo const* ground = sSpellMgr->GetSpellInfo(JourneyGround);
            if (!ground)
                return;
            info->MaxAffectedTargets = ground->MaxAffectedTargets;
            for (SpellEffIndex index : {EFFECT_0, EFFECT_1})
            {
                info->Effects[index].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
                info->Effects[index].TargetB = SpellImplicitTargetInfo(0);
                info->Effects[index].RadiusEntry = ground->Effects[EFFECT_0].RadiusEntry;
            }
        }
    }
};

class spell_ascension_journey_ground : public SpellScript
{
    PrepareSpellScript(spell_ascension_journey_ground);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({JourneyGround, CragDamage}); }

    void ScheduleBurst()
    {
        WorldLocation const* destination = GetExplTargetDest();
        if (!destination)
            return;
        Unit* caster = GetCaster();
        ObjectGuid owner = caster->GetGUID();
        WorldLocation location = *destination;
        uint32 map = caster->GetMapId();
        uint32 instance = caster->GetInstanceId();
        uint32 phase = caster->GetPhaseMask();
        caster->m_Events.AddEventAtOffset([owner, location, map, instance, phase]()
        {
            Player* player = ObjectAccessor::FindPlayer(owner);
            if (!player || !player->IsInWorld() || !player->IsAlive() ||
                player->GetMapId() != map || player->GetInstanceId() != instance || player->GetPhaseMask() != phase)
                return;
            player->CastSpell(location.GetPositionX(), location.GetPositionY(), location.GetPositionZ(),
                CragDamage, true);
        }, Milliseconds(std::max(1, GetSpellInfo()->GetDuration())));
    }

    void Register() override { AfterCast += SpellCastFn(spell_ascension_journey_ground::ScheduleBurst); }
};

class aura_ascension_journey_ground : public AuraScript
{
    PrepareAuraScript(aura_ascension_journey_ground);

    void SuppressPerVictimBurst(AuraEffect const*) { PreventDefaultAction(); }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_journey_ground::SuppressPerVictimBurst,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionPrimalistJourney()
{
    new primalist_journey_metadata();
    RegisterSpellScript(aura_ascension_journey_damage);
    RegisterSpellScript(spell_ascension_journey_ground);
    RegisterSpellScript(aura_ascension_journey_ground);
}
