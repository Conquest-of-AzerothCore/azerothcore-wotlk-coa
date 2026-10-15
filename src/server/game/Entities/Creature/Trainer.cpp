/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Affero General Public License as published by the
 * Free Software Foundation; either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Trainer.h"
#include "Creature.h"
#include "DBCStores.h"
#include "NPCPackets.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldSession.h"

#include <limits>
#include <optional>

namespace
{
    // A Hero playing Wildcard (the game mode bit of AscensionWildcard::GAME_MODE_WILDCARD), until
    // AscensionWildcard installs its own rule.
    bool IsWildcardHero(Player const* player)
    {
        if (player->getClass() != CLASS_HERO)
            return false;
        std::optional<uint32> const mask = sScriptMgr->OnPlayerGetGameModeMask(player);
        return mask && (*mask & 0x40);
    }

    // A Wildcard Hero's trainer: its rows are already the next rank of each ability it rolled, so neither its
    // class nor the core's rank chains (which miss Ascension's added ranks) decide what it may learn.
    constexpr uint32 WILDCARD_RANK_TRAINER_ID = std::numeric_limits<uint32>::max();
    Trainer::WildcardRankRows WildcardRankRowsOf = nullptr;
    Trainer::ClassTrainerFor ClassTrainerOf = nullptr;
    Trainer::RankTrainerHero RankTrainerHeroOf = nullptr;

    bool IsRankTrainerHero(Player const* player)
    {
        return RankTrainerHeroOf ? RankTrainerHeroOf(player) : IsWildcardHero(player);
    }

    uint8 ProfessionExpansion(uint32 skill)
    {
        switch (skill)
        {
            case SKILL_JEWELCRAFTING:
                return EXPANSION_THE_BURNING_CRUSADE;
            case SKILL_INSCRIPTION:
                return EXPANSION_WRATH_OF_THE_LICH_KING;
            default:
                return EXPANSION_CLASSIC;
        }
    }

    bool TeachesProfessionBeyondExpansion(SpellInfo const* spellInfo, uint8 expansion)
    {
        for (SpellEffectInfo const& spellEffectInfo : spellInfo->GetEffects())
            if ((spellEffectInfo.IsEffect(SPELL_EFFECT_SKILL_STEP) || spellEffectInfo.IsEffect(SPELL_EFFECT_SKILL))
                && IsProfessionSkill(spellEffectInfo.MiscValue)
                && (spellEffectInfo.CalcValue() > GetMaxProfessionSkillStep(expansion)
                    || ProfessionExpansion(spellEffectInfo.MiscValue) > expansion))
                return true;

        return false;
    }

    bool TeachesOneProfession(Trainer::Trainer const& trainer)
    {
        uint32 profession = 0;
        for (Trainer::Spell const& spell : trainer.GetSpells())
        {
            if (!spell.ReqSkillLine)
                continue;

            if (profession && profession != spell.ReqSkillLine)
                return false;

            profession = spell.ReqSkillLine;
        }

        return profession != 0;
    }

    // A recipe belongs to the earliest expansion whose map holds a profession trainer that teaches it: Fel Iron
    // patterns are taught in Outland and Northrend only, Thorium ones in Kalimdor and the Eastern Kingdoms too.
    // Trainers teaching several professions (the Books of Artisans) are not evidence of anything.
    // ponytail: built once from the spawns at first use, a `.reload` of trainers or creatures does not rebuild it
    uint8 RecipeExpansion(uint32 spellId)
    {
        static std::unordered_map<uint32, uint8> const expansions = []
        {
            std::unordered_map<uint32, uint8> result;
            for (auto const& [spawnId, data] : sObjectMgr->GetAllCreatureData())
            {
                Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(data.id);
                MapEntry const* map = sMapStore.LookupEntry(data.mapid);
                if (!trainer || !map || !TeachesOneProfession(*trainer))
                    continue;

                uint8 const expansion = uint8(map->Expansion());
                for (Trainer::Spell const& spell : trainer->GetSpells())
                {
                    if (!spell.ReqSkillLine)
                        continue;

                    auto [itr, inserted] = result.try_emplace(spell.SpellId, expansion);
                    if (!inserted)
                        itr->second = std::min(itr->second, expansion);
                }
            }

            return result;
        }();

        auto itr = expansions.find(spellId);
        return itr != expansions.end() ? itr->second : EXPANSION_CLASSIC;
    }
}

namespace Trainer
{
    bool Spell::IsCastable() const
    {
        return sSpellMgr->AssertSpellInfo(SpellId)->HasEffect(SPELL_EFFECT_LEARN_SPELL);
    }

    Trainer::Trainer(uint32 trainerId, Type type, uint32 requirement, std::string greeting, std::vector<Spell> spells) : _trainerId(trainerId), _type(type), _requirement(requirement), _spells(std::move(spells))
    {
        _greeting[DEFAULT_LOCALE] = std::move(greeting);
    }

    void Trainer::SendSpells(Creature* npc, Player* player, LocaleConstant locale, bool onlyTrainable) const
    {
        float reputationDiscount = player->GetReputationPriceDiscount(npc);

        WorldPackets::NPC::TrainerList trainerList;
        trainerList.TrainerGUID = npc->GetGUID();
        trainerList.TrainerType = AsUnderlyingType(_type);
        trainerList.Greeting = GetGreeting(locale);
        trainerList.Spells.reserve(_spells.size());
        for (Spell const& trainerSpell : _spells)
        {
            if (_trainerId != WILDCARD_RANK_TRAINER_ID && !player->IsSpellFitByClassAndRace(trainerSpell.SpellId))
                continue;

            // The state is asked once and then decides both whether the row is written at all and what
            // the row reads: the same call that gates the purchase gates the window, so a trainer can
            // never leave out a spell it would have sold, or offer a row it would have refused.
            SpellState spellState = GetSpellState(player, &trainerSpell);
            if (onlyTrainable && spellState == SpellState::Unavailable)
                continue;

            SpellInfo const* trainerSpellInfo = sSpellMgr->AssertSpellInfo(trainerSpell.SpellId);

            bool primaryProfessionFirstRank = false;
            bool knownOnlyBySkillMaximum = false;
            bool teachesLearnedSpell = false;
            for (SpellEffectInfo const& spellEffectInfo : trainerSpellInfo->GetEffects())
            {
                if (!spellEffectInfo.IsEffect(SPELL_EFFECT_LEARN_SPELL))
                    continue;

                teachesLearnedSpell = true;
                if (spellState == SpellState::Known && !player->HasSpell(spellEffectInfo.TriggerSpell))
                    knownOnlyBySkillMaximum = true;

                SpellInfo const* learnedSpellInfo = sSpellMgr->GetSpellInfo(spellEffectInfo.TriggerSpell);
                if (learnedSpellInfo && learnedSpellInfo->IsPrimaryProfessionFirstRank())
                    primaryProfessionFirstRank = true;
            }

            if (knownOnlyBySkillMaximum || (onlyTrainable && spellState == SpellState::Known && teachesLearnedSpell))
                continue;

            trainerList.Spells.emplace_back();
            WorldPackets::NPC::TrainerListSpell& trainerListSpell = trainerList.Spells.back();
            trainerListSpell.SpellID = trainerSpell.SpellId;
            trainerListSpell.Usable = AsUnderlyingType(spellState);
            trainerListSpell.MoneyCost = int32(trainerSpell.MoneyCost * reputationDiscount);
            trainerListSpell.PointCost[0] = 0; // spells don't cost talent points
            trainerListSpell.PointCost[1] = (primaryProfessionFirstRank ? 1 : 0);
            trainerListSpell.ReqLevel = trainerSpell.ReqLevel;
            trainerListSpell.ReqSkillLine = trainerSpell.ReqSkillLine;
            trainerListSpell.ReqSkillRank = trainerSpell.ReqSkillRank;
            std::copy(trainerSpell.ReqAbility.begin(), trainerSpell.ReqAbility.end(), trainerListSpell.ReqAbility.begin());
        }

        player->SendDirectMessage(trainerList.Write());
    }

    void Trainer::TeachSpell(Creature* npc, Player* player, uint32 spellId)
    {
        if (!IsTrainerValidForPlayer(player))
            return;

        Spell const* trainerSpell = GetSpell(spellId);
        if (!trainerSpell)
        {
            SendTeachFailure(npc, player, spellId, FailReason::Unavailable);
            return;
        }

        if (!CanTeachSpell(player, trainerSpell))
        {
            SendTeachFailure(npc, player, spellId, FailReason::NotEnoughSkill);
            return;
        }

        float reputationDiscount = player->GetReputationPriceDiscount(npc);
        int32 moneyCost = int32(trainerSpell->MoneyCost * reputationDiscount);
        if (!player->HasEnoughMoney(moneyCost))
        {
            SendTeachFailure(npc, player, spellId, FailReason::NotEnoughMoney);
            return;
        }

        player->ModifyMoney(-moneyCost);

        npc->SendPlaySpellVisual(179); // 53 SpellCastDirected
        npc->SendPlaySpellImpact(player->GetGUID(), 362); // 113 EmoteSalute

        // learn explicitly or cast explicitly
        if (trainerSpell->IsCastable())
            player->CastSpell(player, trainerSpell->SpellId, true);
        else
            player->learnSpell(trainerSpell->SpellId, false);

        SendTeachSucceeded(npc, player, spellId);
        sScriptMgr->OnPlayerLearnTrainerSpell(player, npc, spellId);
    }

    Spell const* Trainer::GetSpell(uint32 spellId) const
    {
        auto itr = std::find_if(_spells.begin(), _spells.end(), [spellId](Spell const& trainerSpell)
        {
            return trainerSpell.SpellId == spellId;
        });

        if (itr != _spells.end())
            return &(*itr);

        return nullptr;
    }

    // A rank trainer's next rank turns trainable once the rank below it is bought, so its list is sent again.
    bool Trainer::RepublishesAfterPurchase() const
    {
        return _trainerId == WILDCARD_RANK_TRAINER_ID;
    }

    bool Trainer::CanTeachSpell(Player const* player, Spell const* trainerSpell) const
    {
        SpellState state = GetSpellState(player, trainerSpell);
        if (state != SpellState::Available)
            return false;

        SpellInfo const* trainerSpellInfo = sSpellMgr->AssertSpellInfo(trainerSpell->SpellId);

        for (SpellEffectInfo const& spellEffectInfo : trainerSpellInfo->GetEffects())
        {
            if (!spellEffectInfo.IsEffect(SPELL_EFFECT_LEARN_SPELL))
                continue;

            SpellInfo const* learnedSpellInfo = sSpellMgr->GetSpellInfo(spellEffectInfo.TriggerSpell);
            if (learnedSpellInfo && learnedSpellInfo->IsPrimaryProfessionFirstRank() && !player->GetFreePrimaryProfessionPoints())
                return false;
        }

        return true;
    }

    SpellState Trainer::GetSpellState(Player const* player, Spell const* trainerSpell) const
    {
        if (player->HasSpell(trainerSpell->SpellId))
            return SpellState::Known;

        // check race/class requirement
        bool const wildcardRanks = _trainerId == WILDCARD_RANK_TRAINER_ID;
        if (!wildcardRanks && !player->IsSpellFitByClassAndRace(trainerSpell->SpellId))
            return SpellState::Unavailable;

        // check skill requirement
        if (trainerSpell->ReqSkillLine && player->GetBaseSkillValue(trainerSpell->ReqSkillLine) < trainerSpell->ReqSkillRank)
            return SpellState::Unavailable;

        for (int32 reqAbility : trainerSpell->ReqAbility)
            if (reqAbility && !player->HasSpell(reqAbility))
                return SpellState::Unavailable;

        // check level requirement
        if (player->GetLevel() < trainerSpell->ReqLevel)
            return SpellState::Unavailable;

        // check expansion requirement of professions, their ranks and their recipes
        uint8 const expansion = player->GetSession()->Expansion();
        if (ProfessionExpansion(trainerSpell->ReqSkillLine) > expansion
            || RecipeExpansion(trainerSpell->SpellId) > expansion)
            return SpellState::Unavailable;

        SpellInfo const* trainerSpellInfo = sSpellMgr->AssertSpellInfo(trainerSpell->SpellId);
        if (TeachesProfessionBeyondExpansion(trainerSpellInfo, expansion))
            return SpellState::Unavailable;

        // check ranks
        bool hasLearnSpellEffect = false;
        bool knowsAllLearnedSpells = true;
        for (SpellEffectInfo const& spellEffectInfo : trainerSpellInfo->GetEffects())
        {
            if (!spellEffectInfo.IsEffect(SPELL_EFFECT_LEARN_SPELL))
                continue;

            if (SpellInfo const* learnedSpellInfo = sSpellMgr->GetSpellInfo(spellEffectInfo.TriggerSpell))
                if (TeachesProfessionBeyondExpansion(learnedSpellInfo, expansion))
                    return SpellState::Unavailable;

            hasLearnSpellEffect = true;
            if (SpellLearnSkillNode const* learnedSkill = sSpellMgr->GetSpellLearnSkill(spellEffectInfo.TriggerSpell))
                if (learnedSkill->maxvalue && player->GetPureMaxSkillValue(learnedSkill->skill) >= learnedSkill->maxvalue)
                    continue;

            if (!player->HasSpell(spellEffectInfo.TriggerSpell))
                knowsAllLearnedSpells = false;

            if (uint32 previousRankSpellId = sSpellMgr->GetPrevSpellInChain(spellEffectInfo.TriggerSpell))
                if (!wildcardRanks && !player->HasSpell(previousRankSpellId))
                    return SpellState::Unavailable;
        }

        if (!hasLearnSpellEffect)
        {
            if (uint32 previousRankSpellId = sSpellMgr->GetPrevSpellInChain(trainerSpell->SpellId))
                if (!wildcardRanks && !player->HasSpell(previousRankSpellId))
                    return SpellState::Unavailable;
        }
        else if (knowsAllLearnedSpells)
            return SpellState::Known;

        // check additional spell requirement
        for (auto const& requirePair : sSpellMgr->GetSpellsRequiredForSpellBounds(trainerSpell->SpellId))
            if (!player->HasSpell(requirePair.second))
                return SpellState::Unavailable;

        return SpellState::Available;
    }

    bool Trainer::IsTrainerValidForPlayer(Player const* player) const
    {
        if (!GetTrainerRequirement())
            return true;

        switch (GetTrainerType())
        {
            case Type::Class:
                // check class for class trainers; a Wildcard Hero trains its ranks at any of them
                return player->getClass() == GetTrainerRequirement() || IsRankTrainerHero(player);
            case Type::Pet:
                return player->getClass() == GetTrainerRequirement();
            case Type::Mount:
                // check race for mount trainers
                return player->getRace() == GetTrainerRequirement();
            case Type::Tradeskill:
                // check spell for profession trainers
                return player->HasSpell(GetTrainerRequirement());
            default:
                break;
        }

        return true;
    }

    void Trainer::SendTeachFailure(Creature const* npc, Player const* player, uint32 spellId, FailReason reason) const
    {
        WorldPackets::NPC::TrainerBuyFailed trainerBuyFailed;
        trainerBuyFailed.TrainerGUID = npc->GetGUID();
        trainerBuyFailed.SpellID = spellId;
        trainerBuyFailed.TrainerFailedReason = AsUnderlyingType(reason);
        player->SendDirectMessage(trainerBuyFailed.Write());
    }

    void Trainer::SendTeachSucceeded(Creature const* npc, Player const* player, uint32 spellId) const
    {
        WorldPackets::NPC::TrainerBuySucceeded trainerBuySucceeded;
        trainerBuySucceeded.TrainerGUID = npc->GetGUID();
        trainerBuySucceeded.SpellID = spellId;
        player->SendDirectMessage(trainerBuySucceeded.Write());
    }

    std::string const& Trainer::GetGreeting(LocaleConstant locale) const
    {
        if (_greeting[locale].empty())
            return _greeting[DEFAULT_LOCALE];

        return _greeting[locale];
    }

    void Trainer::AddGreetingLocale(LocaleConstant locale, std::string greeting)
    {
        _greeting[locale] = std::move(greeting);
    }

    Trainer Trainer::WithSpells(std::vector<Spell> spells) const
    {
        Trainer trainer(*this);
        trainer._spells = std::move(spells);
        return trainer;
    }

    void SetWildcardRankRows(WildcardRankRows rows)
    {
        WildcardRankRowsOf = rows;
    }

    void SetClassTrainerFor(ClassTrainerFor trainers)
    {
        ClassTrainerOf = trainers;
    }

    void SetRankTrainerHero(RankTrainerHero heroes)
    {
        RankTrainerHeroOf = heroes;
    }

    // The class's full trainer list: the largest class trainer for it, the others being starter and portal lists.
    Trainer* OwnClassTrainer(Player const* player)
    {
        Trainer const* best = nullptr;
        for (auto const& [id, candidate] : sObjectMgr->GetTrainers())
            if (candidate.GetTrainerType() == Type::Class && candidate.GetTrainerRequirement() == player->getClass() &&
                (!best || candidate.GetSpells().size() > best->GetSpells().size()))
                best = &candidate;
        return const_cast<Trainer*>(best);
    }

    Trainer* GetTrainerFor(Creature const* npc, Player const* player)
    {
        Trainer* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
        bool const rankTrainerHero = IsRankTrainerHero(player);
        if (!trainer && !rankTrainerHero && npc->HasNpcFlag(UNIT_NPC_FLAG_TRAINER_CLASS))
            trainer = OwnClassTrainer(player);
        if (trainer && trainer->GetTrainerType() == Type::Class && ClassTrainerOf)
            if (Trainer* replacement = ClassTrainerOf(*trainer, player))
                return replacement;

        bool const classTrainerUnit = trainer ? trainer->GetTrainerType() == Type::Class
                                              : npc->HasNpcFlag(UNIT_NPC_FLAG_TRAINER_CLASS);
        if (!classTrainerUnit || !WildcardRankRowsOf || !rankTrainerHero)
            return trainer;

        // ponytail: rebuilt for every request, one per thread; cache per player if the lists ever get large.
        thread_local std::optional<Trainer> wildcardRanks;
        wildcardRanks.emplace(WILDCARD_RANK_TRAINER_ID, Type::Class, 0, "", WildcardRankRowsOf(player));
        return &*wildcardRanks;
    }
}
