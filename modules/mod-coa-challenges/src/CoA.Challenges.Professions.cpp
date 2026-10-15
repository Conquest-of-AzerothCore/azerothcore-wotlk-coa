// mod-coa-challenges (review split): CoA.Challenges.Professions.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    // ---- Profession rules -------------------------------------------------
    // Craft rarity stash: OnPlayerUpdateCraftingSkill runs before the skill-up
    // roll, OnPlayerUpdateSkill after a success. The stash carries the crafted
    // item's rarity (1 + quality) between the two for the XP computation.
    std::mutex CraftRarityMutex;
    std::unordered_map<uint32, uint32> CraftRarity; // player guid -> rarity multiplier

    uint32 CraftedItemRarity(SkillLineAbilityEntry const* ability)
    {
        if (!ability)
            return 1;
        SpellInfo const* cast = sSpellMgr->GetSpellInfo(ability->Spell);
        if (!cast)
            return 1;
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            if (cast->Effects[i].Effect != SPELL_EFFECT_CREATE_ITEM || !cast->Effects[i].ItemType)
                continue;
            if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(cast->Effects[i].ItemType))
                return 1 + std::min<uint32>(proto->Quality, 5);
        }
        return 1;
    }

    void GrantProfessionXP(Player* member, uint32 rarityMult)
    {
        if (!member || !member->IsInWorld())
            return;
        uint32 perLevel = sConfigMgr->GetOption<uint32>("CoAChallenges.ProfessionXP.PointsPerLevel", 50);
        if (!perLevel)
            perLevel = 50;
        uint32 xp = sObjectMgr->GetXPForLevel(member->GetLevel()) / perLevel * rarityMult;
        sScriptMgr->OnPlayerGiveXP(member, xp, nullptr, XPSOURCE_PROFESSION_SKILL);
        member->GiveXP(xp, nullptr);
    }
} // namespace CoAChallenges
