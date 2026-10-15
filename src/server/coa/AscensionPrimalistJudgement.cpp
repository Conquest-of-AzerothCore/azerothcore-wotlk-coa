/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum JudgementSpells : uint32
{
    JudgementDamage = 520468,
    MountainHammer = 681130
};

class aura_ascension_primalist_judgement : public AuraScript
{
    PrepareAuraScript(aura_ascension_primalist_judgement);

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            GetCaster() == owner && event.GetActor() == owner && victim && victim != owner &&
            !owner->IsFriendlyTo(victim) && damage && damage->GetDamage() &&
            damage->GetDamageType() != DOT && (!info || info->Id != JudgementDamage);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_primalist_judgement::Check);
    }
};

class primalist_judgement_metadata : public GlobalScript
{
public:
    primalist_judgement_metadata() : GlobalScript("primalist_judgement_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == JudgementDamage && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN))
        {
            info->Effects[EFFECT_1].Effect = 0;
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_NONE;
            info->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(0);
            info->Effects[EFFECT_1].TargetB = SpellImplicitTargetInfo(0);
        }
    }
};

class primalist_judgement_damage : public AllSpellScript
{
public:
    primalist_judgement_damage() : AllSpellScript("primalist_judgement_damage",
        {ALLSPELLHOOK_ON_CALCULATED_TARGET}) { }

    void OnSpellCalculatedTarget(Spell* spell, Unit*, TargetInfo& hit) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_WILDWALKER ||
            spell->GetSpellInfo()->Id != JudgementDamage || hit.damage <= 0)
            return;
        player->ApplySpellMod(MountainHammer, SPELLMOD_DAMAGE, hit.damage);
        player->ApplySpellMod(MountainHammer, SPELLMOD_DAMAGE, hit.damageBeforeTakenMods);
    }
};
}

void AddSC_AscensionPrimalistJudgement()
{
    RegisterSpellScript(aura_ascension_primalist_judgement);
    new primalist_judgement_metadata();
    new primalist_judgement_damage();
}
