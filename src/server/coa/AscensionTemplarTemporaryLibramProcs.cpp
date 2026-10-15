/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 SPELL_SANCTIFY = 705274;
constexpr uint32 SPELL_SANCTIFY_BONUS = 705275;
constexpr uint32 SPELL_EONAR = 705290;
constexpr uint32 SPELL_EONAR_BONUS = 520537;
constexpr uint32 SPELL_SILVERHAND = 801465;
constexpr uint32 SPELL_LEGACY_SCOURGEBANE = 520007;
constexpr uint32 TEMPLAR_FAMILY = 25;

bool IsCurrentMainLibram(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != TEMPLAR_FAMILY ||
        (spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MELEE && spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MAGIC) ||
        !(spellInfo->SpellFamilyFlags[2] & 2048))
        return false;

    switch (spellInfo->Id)
    {
        case 801441:
        case 803890:
        case 803891:
        case 803892:
        case 803893:
        case 801461:
        case 801463:
        case 801466:
        case 805423:
            return true;
        default:
            return false;
    }
}

bool IsCurrentTemporaryLibramTalent(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != TEMPLAR_FAMILY || spellInfo->SpellFamilyFlags ||
        !spellInfo->IsPassive() || !spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) ||
        spellInfo->Effects[EFFECT_0].TargetA.GetTarget() != TARGET_UNIT_CASTER)
        return false;

    uint32 helperId = spellInfo->Id == SPELL_SANCTIFY ? SPELL_SANCTIFY_BONUS :
        spellInfo->Id == SPELL_EONAR ? SPELL_EONAR_BONUS : 0;
    if (!helperId || spellInfo->Effects[EFFECT_0].TriggerSpell != helperId)
        return false;

    SpellInfo const* helper = sSpellMgr->GetSpellInfo(helperId);
    if (!helper || helper->SpellFamilyName != TEMPLAR_FAMILY || helper->SpellFamilyFlags || helper->StackAmount ||
        helper->Effects[EFFECT_0].TargetA.GetTarget() != TARGET_UNIT_CASTER)
        return false;

    if (helperId == SPELL_SANCTIFY_BONUS)
        return helper->GetDuration() == 20000 && helper->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_MELEE_HASTE);

    return helper->GetDuration() == 15000 && helper->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_DONE) &&
        helper->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_HEALING_DONE_PERCENT) &&
        helper->Effects[EFFECT_1].TargetA.GetTarget() == TARGET_UNIT_CASTER;
}

class spell_ascension_templar_temporary_libram : public AuraScript
{
    PrepareAuraScript(spell_ascension_templar_temporary_libram);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsCurrentTemporaryLibramTalent(spellInfo);
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Player* player = owner ? owner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_MONK || GetCaster() != owner || eventInfo.GetActor() != owner ||
            !IsCurrentTemporaryLibramTalent(GetSpellInfo()))
            return false;

        SpellInfo const* castInfo = eventInfo.GetSpellInfo();
        if (IsCurrentMainLibram(castInfo))
            return true;

        return GetSpellInfo()->Id == SPELL_EONAR && castInfo && castInfo->Id == SPELL_SILVERHAND &&
            castInfo->SpellFamilyName == TEMPLAR_FAMILY &&
            (castInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE || castInfo->DmgClass == SPELL_DAMAGE_CLASS_MAGIC) &&
            castInfo->SpellFamilyFlags == flag96(0, 536870912, 0) &&
            (player->HasSpell(SPELL_LEGACY_SCOURGEBANE) || player->HasSpell(92111));
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_templar_temporary_libram::CheckProc);
    }
};
}

void AddSC_AscensionTemplarTemporaryLibramProcs()
{
    RegisterSpellScript(spell_ascension_templar_temporary_libram);
}
