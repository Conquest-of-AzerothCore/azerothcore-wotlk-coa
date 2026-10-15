/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum HeavyEarthSpells : uint32
{
    HeavyEarthTalent = 706160,
    HeavyEarthBuff = 560142,
    HeavyEarthDamage = 561198,
    Earthshaping = 680441,
    GolemForm = 805335,
    Stoneshard = 680448,
    GeodeBarrageDamage = 803138
};

class spell_ascension_heavy_earth : public SpellScript
{
    PrepareSpellScript(spell_ascension_heavy_earth);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({HeavyEarthTalent, HeavyEarthBuff, Earthshaping, GolemForm});
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Consume()
    {
        Unit* owner = GetCaster();
        if (!owner->HasAura(HeavyEarthTalent, owner->GetGUID()))
            return;
        Aura const* resource = owner->GetAura(Earthshaping, owner->GetGUID());
        if (!resource || !resource->GetStackAmount())
            return;

        uint8 stacks = resource->GetStackAmount();
        Aura* reward = owner->AddAura(HeavyEarthBuff, owner);
        if (!reward)
            return;
        reward->GetEffect(EFFECT_0)->ChangeAmount(5 * int32(stacks));
        reward->RefreshDuration();
        owner->RemoveAurasDueToSpell(Earthshaping, owner->GetGUID());
        if (Aura* form = owner->GetAura(GolemForm, owner->GetGUID()))
            form->RefreshDuration();
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_heavy_earth::Consume);
    }
};

class aura_ascension_heavy_earth : public AuraScript
{
    PrepareAuraScript(aura_ascension_heavy_earth);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == HeavyEarthBuff && info->Effects[EFFECT_0].ApplyAuraName == 354 &&
            ValidateSpellInfo({HeavyEarthDamage});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        SpellInfo const* spell = event.GetSpellInfo();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCasterGUID() == owner->GetGUID() && event.GetActor() == owner &&
            victim && !owner->IsFriendlyTo(victim) && spell && spell->SpellFamilyName == 37 &&
            (spell->Id == GeodeBarrageDamage || spell->GetFirstRankSpell()->Id == Stoneshard) &&
            damage && damage->GetDamage() && damage->GetDamageType() != DOT;
    }

    void Repeat(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::max(0, effect->GetAmount()) / 100;
        if (amount)
            GetTarget()->CastCustomSpell(HeavyEarthDamage, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
                event.GetActionTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_heavy_earth::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_heavy_earth::Repeat, EFFECT_0, AuraType(354));
    }
};

class primalist_heavy_earth_metadata : public GlobalScript
{
public:
    primalist_heavy_earth_metadata() : GlobalScript("primalist_heavy_earth_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == HeavyEarthDamage && info->SpellFamilyName == 37)
            info->AscensionInheritsResolvedAmount = true;
    }
};
}

void AddSC_AscensionPrimalistHeavyEarth()
{
    new primalist_heavy_earth_metadata();
    RegisterSpellScript(spell_ascension_heavy_earth);
    RegisterSpellScript(aura_ascension_heavy_earth);
}
