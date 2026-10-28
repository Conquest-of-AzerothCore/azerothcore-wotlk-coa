/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
enum StormflowSpells : uint32
{
    SPELL_BLESSING_OF_LEI_SHEN = 561228,
    SPELL_BLESSING_OF_LEI_SHEN_HEAL = 561308,
    SPELL_STORM_SYNERGY = 578300,
    SPELL_CONDUCTIVE = 567559,
    SPELL_UNSTABLE = 705723,
    SPELL_UNSTABLE_PERIOD = 707222,
    SPELL_AMPED_FLOW = 806411,
    SPELL_AMPED_FLOW_TARGETS = 567556,
    SPELL_UNBRIDLED_FLOW = 578299
};

enum StormflowFamilyFlags : uint32
{
    STORMFLOW_FLAG_ONE = 65536,
    ELECTROCUTE_FLAG_ZERO = 33554432,
    ELECTROCUTE_FLAG_TWO = 32
};

enum StormflowUnportedAuras : uint32
{
    AURA_STORMFLOW_ALLOWED_SPELLS = 353,
    AURA_HEAL_FOR_DAMAGE_DEALT = 354
};

bool IsStormflow(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 22 && (info->SpellFamilyFlags[1] & STORMFLOW_FLAG_ONE);
}

bool IsElectrocute(SpellInfo const* info)
{
    return info && info->SpellFamilyName == 22 && (info->SpellFamilyFlags[0] & ELECTROCUTE_FLAG_ZERO) &&
        (info->SpellFamilyFlags[2] & ELECTROCUTE_FLAG_TWO);
}

Spell* StormflowChannel(Player* player)
{
    Spell* channel = player->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
    if (!channel || channel->getState() == SPELL_STATE_FINISHED || !IsStormflow(channel->GetSpellInfo()))
        return nullptr;
    return channel;
}

void RederiveChannelPeriod(Unit* owner)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    Spell* channel = player ? StormflowChannel(player) : nullptr;
    if (!channel)
        return;
    Unit* victim = channel->m_targets.GetUnitTarget();
    if (!victim)
        return;
    if (AuraEffect* periodic = victim->GetAuraEffect(channel->GetSpellInfo()->Id, EFFECT_0, player->GetGUID()))
        periodic->CalculatePeriodic(player);
}

class stormbringer_stormflow_contracts : public GlobalScript
{
public:
    stormbringer_stormflow_contracts() : GlobalScript("stormbringer_stormflow_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 22)
            return;
        if (info->Id == SPELL_UNBRIDLED_FLOW &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_EFFECT3)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        auto dummy = [info](uint8 slot)
        {
            info->Effects[slot].ApplyAuraName = SPELL_AURA_DUMMY;
            info->Effects[slot].TriggerSpell = 0;
        };
        if (info->Id == SPELL_BLESSING_OF_LEI_SHEN || info->Id == SPELL_STORM_SYNERGY ||
            info->Id == SPELL_UNSTABLE || info->Id == SPELL_AMPED_FLOW)
        {
            for (uint8 slot = 0; slot < MAX_SPELL_EFFECTS; ++slot)
                if (info->Effects[slot].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL ||
                    info->Effects[slot].ApplyAuraName == AURA_HEAL_FOR_DAMAGE_DEALT)
                    dummy(slot);
            info->ProcFlags = info->ProcCharges = 0;
        }
        if (IsStormflow(info) && info->Effects[EFFECT_1].ApplyAuraName == AURA_STORMFLOW_ALLOWED_SPELLS)
            dummy(EFFECT_1);
    }
};

class stormbringer_unbridled_flow : public UnitScript
{
public:
    stormbringer_unbridled_flow() : UnitScript("stormbringer_unbridled_flow", true,
        {UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN}) { }

    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& amount, SpellInfo const* info) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_STORMBRINGER || !player->IsAlive() || !info ||
            info->SpellFamilyName != 22 || amount <= 0 || !target || target == player ||
            player->IsFriendlyTo(target) || !StormflowChannel(player) ||
            (!(info->SpellFamilyFlags[0] & 2048) && !(info->SpellFamilyFlags[1] & 128)))
            return;
        AuraEffect const* effect = player->GetAuraEffect(SPELL_UNBRIDLED_FLOW, EFFECT_0, player->GetGUID());
        if (!effect || effect->GetAmount() <= 0)
            return;
        uint64 const result = uint64(amount) * (100 + uint64(effect->GetAmount())) / 100;
        amount = int32(std::min<uint64>(result, std::numeric_limits<int32>::max()));
    }
};

class stormbringer_stormflow_blessing : public UnitScript
{
public:
    stormbringer_stormflow_blessing() : UnitScript("stormbringer_stormflow_blessing", true,
        {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) { }

    void OnPeriodicDamageResult(Unit*, Unit* caster, uint32 damage, SpellInfo const* info) override
    {
        if (!caster || !damage || !IsStormflow(info))
            return;
        Player* owner = caster->ToPlayer();
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || !owner->IsAlive())
            return;
        AuraEffect const* blessing = owner->GetAuraEffect(SPELL_BLESSING_OF_LEI_SHEN, EFFECT_0);
        if (!blessing)
            return;
        owner->CastCustomSpell(SPELL_BLESSING_OF_LEI_SHEN_HEAL, SPELLVALUE_BASE_POINT0,
            int32(CalculatePct(damage, blessing->GetAmount())), owner, true);
    }
};

class stormbringer_stormflow_hits : public AllSpellScript
{
public:
    stormbringer_stormflow_hits() : AllSpellScript("stormbringer_stormflow_hits",
        {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool critical) override
    {
        Player* player = spell->GetCaster() ? spell->GetCaster()->ToPlayer() : nullptr;
        SpellInfo const* info = spell->GetSpellInfo();
        if (!player || player->getClass() != CLASS_STORMBRINGER || info->SpellFamilyName != 22 ||
            !target || target == player || player->IsFriendlyTo(target) || miss != SPELL_MISS_NONE ||
            !damage || spell->IsTriggered())
            return;

        if (IsElectrocute(info) && player->HasAura(SPELL_STORM_SYNERGY) && StormflowChannel(player))
            player->CastSpell(player, SPELL_CONDUCTIVE, true);

        if (critical && player->HasAura(SPELL_UNSTABLE))
            player->CastSpell(player, SPELL_UNSTABLE_PERIOD, true);
    }
};

class aura_ascension_stormflow : public AuraScript
{
    PrepareAuraScript(aura_ascension_stormflow);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_AMPED_FLOW_TARGETS}); }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        if (!caster || caster != GetTarget() || !caster->HasAura(SPELL_AMPED_FLOW))
            return;
        int32 channelled = GetAura()->GetDuration();
        Aura* extra = caster->AddAura(SPELL_AMPED_FLOW_TARGETS, caster);
        if (extra && channelled > 0)
        {
            extra->SetMaxDuration(channelled);
            extra->SetDuration(channelled);
        }
    }

    void OnRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetCasterGUID() == GetTarget()->GetGUID())
            GetTarget()->RemoveAurasDueToSpell(SPELL_AMPED_FLOW_TARGETS);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_stormflow::Apply,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_stormflow::OnRemove,
            EFFECT_1, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_unstable : public AuraScript
{
    PrepareAuraScript(aura_ascension_unstable);

    void Rederive(AuraEffect const*, AuraEffectHandleModes)
    {
        RederiveChannelPeriod(GetTarget());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_unstable::Rederive,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_unstable::Rederive,
            EFFECT_0, SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void AddSC_AscensionStormbringerStormflow()
{
    new stormbringer_stormflow_contracts();
    new stormbringer_unbridled_flow();
    new stormbringer_stormflow_blessing();
    new stormbringer_stormflow_hits();
    RegisterSpellScript(aura_ascension_stormflow);
    RegisterSpellScript(aura_ascension_unstable);
}
