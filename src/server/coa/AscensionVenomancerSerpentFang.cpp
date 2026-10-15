/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"

namespace
{
enum SerpentFangSpells : uint32
{
    SPELL_SERPENTS_FANG = 800946,
    SPELL_SERPENTS_FANG_HEAL = 560202
};

class venomancer_serpent_fang : public AllSpellScript
{
public:
    venomancer_serpent_fang() : AllSpellScript("venomancer_serpent_fang", {ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_PROPHET || !player->IsAlive() || !player->IsInWorld() ||
            spell->GetSpellInfo()->SpellFamilyName != 35 ||
            sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id) != SPELL_SERPENTS_FANG ||
            !target || !target->IsInWorld() || target == player || player->IsFriendlyTo(target) ||
            player->GetMap() != target->GetMap() || !player->InSamePhase(target) || miss != SPELL_MISS_NONE ||
            spell->GetScriptValue(SPELL_SERPENTS_FANG_HEAL))
            return;
        SpellInfo const* heal = sSpellMgr->GetSpellInfo(SPELL_SERPENTS_FANG_HEAL);
        if (!heal)
            return;
        spell->SetScriptValue(SPELL_SERPENTS_FANG_HEAL, 1);
        SpellCastTargets targets;
        targets.SetDst(target->GetPosition());
        player->CastSpell(targets, heal, nullptr, TRIGGERED_FULL_MASK);
    }
};

class venomancer_serpent_fang_metadata : public GlobalScript
{
public:
    venomancer_serpent_fang_metadata() : GlobalScript("venomancer_serpent_fang_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_SERPENTS_FANG_HEAL && info->SpellFamilyName == 35)
        {
            info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
            info->_InitializeExplicitTargetMask();
        }
    }
};
}

void AddSC_AscensionVenomancerSerpentFang()
{
    new venomancer_serpent_fang();
    new venomancer_serpent_fang_metadata();
}
