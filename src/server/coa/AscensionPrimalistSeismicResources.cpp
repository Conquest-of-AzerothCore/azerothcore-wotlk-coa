/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"

namespace
{
enum SeismicResourceSpells : uint32
{
    SeismicCrash = 803981,
    SeismicSpike = 804433,
    CrashRage = 681355,
    SpikeRage = 681356
};

Player* PrimalistCaster(Spell* spell)
{
    if (!spell || spell->IsTriggered() || spell->GetSpellInfo()->SpellFamilyName != 37)
        return nullptr;
    Player* player = spell->GetCaster()->ToPlayer();
    return player && player->getClass() == CLASS_WILDWALKER && player->IsAlive() ? player : nullptr;
}

class primalist_seismic_resources : public AllSpellScript
{
public:
    primalist_seismic_resources() : AllSpellScript("primalist_seismic_resources",
        {ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellCast(Spell* spell, Unit*, SpellInfo const* info, bool) override
    {
        Player* player = PrimalistCaster(spell);
        if (player && info->GetFirstRankSpell()->Id == SeismicCrash)
            player->CastSpell(player, CrashRage, true);
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = PrimalistCaster(spell);
        if (!player || !target || target == player || player->IsFriendlyTo(target) || miss != SPELL_MISS_NONE ||
            spell->GetSpellInfo()->GetFirstRankSpell()->Id != SeismicSpike)
            return;
        player->CastSpell(player, SpikeRage, true);
    }
};
}

void AddSC_AscensionPrimalistSeismicResources()
{
    new primalist_seismic_resources();
}
