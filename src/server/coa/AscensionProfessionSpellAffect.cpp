/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <unordered_set>

namespace
{
constexpr uint32 SPELLFAMILY_ASCENSION_PROFESSION = SPELLFAMILY_UNK2;
constexpr uint32 SPELL_KHAZGOROTHS_BLESSING = 1008013;

uint64 PairKey(uint32 modifierSpellId, uint32 affectedSpellId)
{
    return (uint64(modifierSpellId) << 32) | affectedSpellId;
}

std::unordered_set<uint64> const& ProfessionModifierTargets()
{
    static std::unordered_set<uint64> const targets = []
    {
        std::unordered_set<uint64> pairs;
        for (SpellAffectEntry const* entry : sSpellAffectStore)
        {
            SpellInfo const* modifier = sSpellMgr->GetSpellInfo(entry->ModifierSpellID);
            if (modifier && modifier->SpellFamilyName == SPELLFAMILY_ASCENSION_PROFESSION)
                pairs.insert(PairKey(entry->ModifierSpellID, entry->AffectedSpellID));
        }
        return pairs;
    }();
    return targets;
}

class ascension_profession_spell_affect : public GlobalScript
{
public:
    ascension_profession_spell_affect()
        : GlobalScript("ascension_profession_spell_affect", {GLOBALHOOK_ON_IS_AFFECTED_BY_SPELL_MOD_CHECK}) { }

    bool OnIsAffectedBySpellModCheck(SpellInfo const* affectSpell, SpellInfo const* checkSpell,
        SpellModifier const*) override
    {
        return affectSpell->SpellFamilyName != SPELLFAMILY_ASCENSION_PROFESSION ||
            !ProfessionModifierTargets().count(PairKey(affectSpell->Id, checkSpell->Id));
    }
};

class ascension_khazgoroths_blessing : public AllSpellScript
{
public:
    ascension_khazgoroths_blessing()
        : AllSpellScript("ascension_khazgoroths_blessing", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell*, Unit* caster, SpellInfo const* spellInfo, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (player && ProfessionModifierTargets().count(PairKey(SPELL_KHAZGOROTHS_BLESSING, spellInfo->Id)))
            player->CastSpell(player, SPELL_KHAZGOROTHS_BLESSING, true);
    }
};
}

void AddSC_AscensionProfessionSpellAffect()
{
    new ascension_profession_spell_affect();
    new ascension_khazgoroths_blessing();
}
