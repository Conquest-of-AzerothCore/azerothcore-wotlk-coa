/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <limits>

namespace
{
enum StormbringerLightningSpells : uint32
{
    SPELL_FLUX_ARC = 705643,
    SPELL_FLUX_ARC_MARK = 804832,
    SPELL_FLUX_ARC_SPLASH = 705644,
    SPELL_SPARKS = 301298,
    SPELL_SPARKS_CRIT_DEBUFF = 706729,
    SPELL_THUNDER_WAVE = 705692,
    SPELL_THUNDER_WAVE_STRIKE = 707220,
    SPELL_FORKED_LIGHTNING_FIRST_RANK = 801851,
    SPELL_ARM_OF_THORIM_FIRST_RANK = 801847,
    SPELL_CALL_LIGHTNING = 500040,
    SPELL_ELECTROCUTE_FIRST_RANK = 801844
};

class stormbringer_lightning_procs : public AllSpellScript
{
public:
    stormbringer_lightning_procs() : AllSpellScript("stormbringer_lightning_procs",
        {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* owner = spell->GetCaster()->ToPlayer();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!owner || owner->getClass() != CLASS_STORMBRINGER || info->SpellFamilyName != 22 ||
            !target || !target->IsAlive() || !owner->IsValidAttackTarget(target) ||
            miss != SPELL_MISS_NONE || !damage)
            return;

        uint32 source = sSpellMgr->GetFirstSpellInChain(info->Id);
        MarkFluxArc(owner, target, source);
        SplashFluxArc(owner, target, source, damage);
        ApplySparks(owner, target, source);
        StrikeThunderWave(spell, owner, target, source);
    }

private:
    void MarkFluxArc(Player* owner, Unit* target, uint32 source) const
    {
        if ((source != SPELL_FORKED_LIGHTNING_FIRST_RANK && source != SPELL_ARM_OF_THORIM_FIRST_RANK) ||
            !owner->HasAura(SPELL_FLUX_ARC))
            return;
        owner->CastSpell(target, SPELL_FLUX_ARC_MARK, true);
    }

    void SplashFluxArc(Player* owner, Unit* target, uint32 source, uint32 damage) const
    {
        AuraEffect const* share = owner->GetAuraEffect(SPELL_FLUX_ARC, EFFECT_0);
        if (source != SPELL_CALL_LIGHTNING || !share ||
            !target->HasAura(SPELL_FLUX_ARC_MARK, owner->GetGUID()))
            return;

        uint64 amount = uint64(damage) * uint64(std::max(0, share->GetAmount())) / 100;
        if (amount)
            owner->CastCustomSpell(SPELL_FLUX_ARC_SPLASH, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, true);
    }

    void ApplySparks(Player* owner, Unit* target, uint32 source) const
    {
        if ((source != SPELL_ELECTROCUTE_FIRST_RANK && source != SPELL_ARM_OF_THORIM_FIRST_RANK) ||
            !owner->HasAura(SPELL_SPARKS))
            return;
        owner->CastSpell(target, SPELL_SPARKS_CRIT_DEBUFF, true);
    }

    void StrikeThunderWave(Spell* spell, Player* owner, Unit* target, uint32 source) const
    {
        SpellInfo const* talent = sSpellMgr->GetSpellInfo(SPELL_THUNDER_WAVE);
        if (source != SPELL_FORKED_LIGHTNING_FIRST_RANK || spell->IsTriggered() || !talent ||
            !owner->HasAura(SPELL_THUNDER_WAVE) || spell->GetScriptValue(SPELL_THUNDER_WAVE) ||
            !roll_chance_i(int32(talent->ProcChance)))
            return;

        spell->SetScriptValue(SPELL_THUNDER_WAVE, 1);
        owner->CastSpell(target, SPELL_THUNDER_WAVE_STRIKE, true);
    }
};
}

void AddSC_AscensionStormbringerLightning()
{
    new stormbringer_lightning_procs();
}
