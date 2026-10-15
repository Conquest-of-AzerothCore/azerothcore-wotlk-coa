/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionGuardianCompletion.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <algorithm>
#include <array>
#include <map>
#include <set>
#include <vector>

namespace
{
constexpr std::array<uint32, 9> Conqueror = {801776, 501068, 501069, 501070, 501071, 501072, 501073, 501074, 574340};
constexpr std::array<uint32, 9> Dragonslayer = {801772, 501066, 501067, 572717, 572718, 572719, 574341, 574363, 574364};

uint32 BestBallad(Player* player, std::array<uint32, 9> const& ranks)
{
    uint32 best = 0;
    for (uint32 rank : ranks)
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(rank))
            if (info->SpellLevel <= player->GetLevel())
                best = rank;
    return best;
}

void Synchronize(Player* player)
{
    if (!player || player->getClass() != CLASS_GUARDIAN || !player->IsInWorld())
        return;
    static thread_local std::set<ObjectGuid> updating;
    if (!updating.insert(player->GetGUID()).second)
        return;
    std::vector<uint32> originals;
    for (auto const& pair : player->GetSpellMap())
    {
        uint32 id = pair.first;
        if (AscensionGuardian::Pulverize(id) || AscensionGuardian::HeavyBlow(id) || AscensionGuardian::Advance(id) ||
            sSpellMgr->GetFirstSpellInChain(id) == 805150)
            originals.push_back(id);
    }
    std::set<uint32> desired;
    std::map<uint32, uint32> replacements;
    for (uint32 id : originals)
    {
        uint32 replacement = 0;
        if (player->HasActiveSpell(id))
        {
            if (player->HasAura(505344))
            {
                if (AscensionGuardian::Pulverize(id))
                    replacement = BestBallad(player, Conqueror);
                else if (sSpellMgr->GetFirstSpellInChain(id) == 805150)
                    replacement = BestBallad(player, Dragonslayer);
            }
            if (AscensionGuardian::HeavyBlow(id) && player->HasAura(706514) && player->HasAura(707138))
                replacement = 802629;
            if (AscensionGuardian::Advance(id))
                if (Aura const* aura = player->GetAura(id))
                    if (aura->GetMaxDuration() - aura->GetDuration() >= 500)
                        replacement = 500673;
        }
        if (replacement)
            desired.insert(replacement);
        replacements[id] = replacement;
        if (player->GetTemporarySpellReplacement(id) != replacement)
            player->SetTemporarySpellReplacement(id, 0);
    }
    std::vector<uint32> candidates(Conqueror.begin(), Conqueror.end());
    candidates.insert(candidates.end(), Dragonslayer.begin(), Dragonslayer.end());
    candidates.push_back(802629);
    candidates.push_back(500673);
    std::sort(candidates.begin(), candidates.end(), [](uint32 left, uint32 right)
    {
        return sSpellMgr->GetSpellRank(left) > sSpellMgr->GetSpellRank(right);
    });
    for (uint32 id : candidates)
        if (!desired.count(id))
        {
            bool neededByHigherRank = std::any_of(desired.begin(), desired.end(), [id](uint32 rank)
            {
                return sSpellMgr->GetFirstSpellInChain(id) == sSpellMgr->GetFirstSpellInChain(rank) &&
                    sSpellMgr->GetSpellRank(id) < sSpellMgr->GetSpellRank(rank);
            });
            if (!neededByHigherRank)
                player->removeSpell(id, SPEC_MASK_ALL, true);
        }
    for (auto const& [id, replacement] : replacements)
    {
        if (replacement && !player->HasSpell(replacement) && player->GetSpellMap().find(replacement) == player->GetSpellMap().end())
            player->learnSpell(replacement, true);
        player->SetTemporarySpellReplacement(id, replacement);
    }
    updating.erase(player->GetGUID());
}

class guardian_talents : public PlayerScript
{
public:
    guardian_talents() : PlayerScript("guardian_talents", { PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_FORGOT_SPELL }) { }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        Synchronize(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 id) override
    {
        if (player->getClass() == CLASS_GUARDIAN)
            player->SetTemporarySpellReplacement(id, 0);
    }
};
}

void AddAscensionGuardianTalentScripts()
{
    new guardian_talents();
}
