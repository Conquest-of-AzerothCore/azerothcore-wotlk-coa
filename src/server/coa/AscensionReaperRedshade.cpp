/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "Opcodes.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 SPELL_THRESH_DUMMY = 525058;
constexpr uint32 SPELL_THRESH = 505170;
constexpr uint32 SPELL_BLOODSHATTER_DUMMY = 525299;
constexpr uint32 SPELL_BLOODSHATTER = 505326;
constexpr uint32 SPELL_DECIMATION = 704193;
constexpr uint32 SPELL_DECIMATION_COUNTER = 573289;
constexpr uint32 SPELL_DECIMATE = 500523;

constexpr std::array<uint32, 10> ReapRanks = { 354319, 500357, 504056, 504057, 504058, 504557,
    505151, 573302, 573303, 801327 };

bool IsReap(uint32 spellId)
{
    return std::find(ReapRanks.begin(), ReapRanks.end(), spellId) != ReapRanks.end();
}

void SendTransformedBar(Player* player, uint32 replacement)
{
    if (!player->GetSession())
        return;

    WorldPacket data(SMSG_ACTION_BUTTONS, 1 + (MAX_ACTION_BUTTONS * 4));
    data << uint8(1);
    for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
    {
        ActionButton const* action = player->GetActionButton(button);
        if (!action)
        {
            data << uint32(0);
            continue;
        }

        uint32 packed = action->packedData;
        if (action->GetType() == ACTION_BUTTON_SPELL && IsReap(action->GetAction()))
            packed = replacement | (uint32(ACTION_BUTTON_SPELL) << 24);

        data << uint32(packed);
    }

    player->GetSession()->SendPacket(&data);
}

class aura_ascension_reaper_decimation_counter : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_decimation_counter);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_DECIMATE}); }

    bool Load() override
    {
        Unit* owner = GetUnitOwner();
        return owner && owner->IsPlayer() && owner->getClass() == CLASS_REAPER &&
            GetCasterGUID() == owner->GetGUID() && owner->HasAura(SPELL_DECIMATION);
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (GetStackAmount() < GetSpellInfo()->StackAmount)
            return;
        if (!player->HasActiveSpell(SPELL_DECIMATE))
            player->addSpell(SPELL_DECIMATE, player->GetActiveSpecMask(), true, true, true);
        for (uint32 rank : ReapRanks)
            if (player->HasActiveSpell(rank))
                player->SetTemporarySpellReplacement(rank, SPELL_DECIMATE);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        for (uint32 rank : ReapRanks)
            if (player->GetTemporarySpellReplacement(rank) == SPELL_DECIMATE)
                player->SetTemporarySpellReplacement(rank, 0);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_decimation_counter::Apply,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_decimation_counter::Remove,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class reaper_decimation_casts : public AllSpellScript
{
public:
    reaper_decimation_casts() : AllSpellScript("reaper_decimation_casts",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_REAPER || spell->IsTriggered())
            return;
        if (spell->GetSpellInfo()->Id == SPELL_DECIMATE)
        {
            Aura const* counter = player->GetAura(SPELL_DECIMATION_COUNTER, player->GetGUID());
            if (!counter || uint32(counter->GetStackAmount()) < counter->GetSpellInfo()->CalcMaxAuraStacks(player))
                result = SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
            return;
        }
        if (!IsReap(spell->GetSpellInfo()->Id) || player->HasAura(SPELL_THRESH_DUMMY) ||
            player->HasAura(SPELL_BLOODSHATTER_DUMMY) ||
            player->GetTemporarySpellReplacement(spell->GetSpellInfo()->Id) != SPELL_DECIMATE)
            return;
        if (Unit* target = spell->m_targets.GetUnitTarget())
        {
            player->CastSpell(target, SPELL_DECIMATE, false);
            result = SPELL_FAILED_DONT_REPORT;
        }
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (caster->IsPlayer() && caster->getClass() == CLASS_REAPER && !spell->IsTriggered() &&
            info->Id == SPELL_DECIMATE)
            caster->RemoveAurasDueToSpell(SPELL_DECIMATION_COUNTER, caster->GetGUID());
    }
};

class reaper_decimation_events : public UnitScript
{
public:
    reaper_decimation_events() : UnitScript("reaper_decimation_events", true, {UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (!unit->IsPlayer() || unit->getClass() != CLASS_REAPER || !application ||
            application->GetBase()->GetId() != SPELL_DECIMATION ||
            application->GetBase()->GetCasterGUID() != unit->GetGUID())
            return;
        unit->RemoveAurasDueToSpell(SPELL_DECIMATION_COUNTER, unit->GetGUID());
        if (Player* player = unit->ToPlayer())
        {
            for (uint32 rank : ReapRanks)
                if (player->GetTemporarySpellReplacement(rank) == SPELL_DECIMATE)
                    player->SetTemporarySpellReplacement(rank, 0);
            player->removeSpell(SPELL_DECIMATE, SPEC_MASK_ALL, true);
        }
    }
};

class aura_ascension_reaper_redshade_spells : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_redshade_spells);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_THRESH, SPELL_BLOODSHATTER });
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;

        for (uint32 spellId : { SPELL_THRESH, SPELL_BLOODSHATTER })
            if (!player->HasActiveSpell(spellId))
                player->addSpell(spellId, player->GetActiveSpecMask(), true, true, true);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;

        player->RemoveAurasDueToSpell(SPELL_THRESH_DUMMY);
        player->RemoveAurasDueToSpell(SPELL_BLOODSHATTER_DUMMY);
        for (uint32 spellId : { SPELL_THRESH, SPELL_BLOODSHATTER })
            player->removeSpell(spellId, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_redshade_spells::Apply,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_redshade_spells::Remove,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_reaper_redshade_transform : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_redshade_transform);

    uint32 Replacement() const
    {
        return GetId() == SPELL_BLOODSHATTER_DUMMY ? SPELL_BLOODSHATTER : SPELL_THRESH;
    }

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_THRESH, SPELL_BLOODSHATTER });
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetTarget()->ToPlayer())
            SendTransformedBar(player, player->HasAura(SPELL_BLOODSHATTER_DUMMY) ? SPELL_BLOODSHATTER : Replacement());
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;

        uint32 const other = GetId() == SPELL_BLOODSHATTER_DUMMY ? SPELL_THRESH_DUMMY
            : SPELL_BLOODSHATTER_DUMMY;
        if (player->HasAura(other))
            SendTransformedBar(player, other == SPELL_BLOODSHATTER_DUMMY ? SPELL_BLOODSHATTER : SPELL_THRESH);
        else
            player->SendActionButtons(1);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_redshade_transform::Apply,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_redshade_transform::Remove,
            EFFECT_0, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reaper_redshade_reap : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_redshade_reap);

    SpellCastResult CheckCast()
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->IsPlayer())
            return SPELL_CAST_OK;

        uint32 const replacement = caster->HasAura(SPELL_BLOODSHATTER_DUMMY) ? SPELL_BLOODSHATTER
            : caster->HasAura(SPELL_THRESH_DUMMY) ? SPELL_THRESH : 0;
        if (!replacement)
            return SPELL_CAST_OK;

        Unit* target = GetExplTargetUnit();
        caster->CastSpell(target ? target : caster, replacement, false);

        return SPELL_FAILED_DONT_REPORT;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_reaper_redshade_reap::CheckCast);
    }
};
}

void AddSC_AscensionReaperRedshade()
{
    new reaper_decimation_casts();
    new reaper_decimation_events();
    RegisterSpellScript(aura_ascension_reaper_decimation_counter);
    RegisterSpellScript(aura_ascension_reaper_redshade_spells);
    RegisterSpellScript(aura_ascension_reaper_redshade_transform);
    RegisterSpellScript(spell_ascension_reaper_redshade_reap);
}
