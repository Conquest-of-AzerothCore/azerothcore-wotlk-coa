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

#ifndef Trainer_h__
#define Trainer_h__

#include "Common.h"
#include <array>
#include <vector>

class Creature;
class ObjectMgr;
class Player;

namespace Trainer
{
    enum class Type : uint32
    {
        Class = 0,
        Mount = 1,
        Tradeskill = 2,
        Pet = 3
    };

    enum class SpellState : uint8
    {
        Available = 0,
        Unavailable = 1,
        Known = 2
    };

    enum class FailReason : uint32
    {
        Unavailable = 0,
        NotEnoughMoney = 1,
        NotEnoughSkill = 2
    };

    struct AC_GAME_API Spell
    {
        uint32 SpellId = 0;
        uint32 MoneyCost = 0;
        uint32 ReqSkillLine = 0;
        uint32 ReqSkillRank = 0;
        std::array<uint32, 3> ReqAbility = { };
        uint8 ReqLevel = 0;

        [[nodiscard]] bool IsCastable() const;
    };

    class AC_GAME_API Trainer
    {
        public:
            Trainer(uint32 trainerId, Type type, uint32 requirement, std::string greeting, std::vector<Spell> spells);

            [[nodiscard]] Spell const* GetSpell(uint32 spellId) const;
            [[nodiscard]] std::vector<Spell> const& GetSpells() const { return _spells; }
            /// Writes the trainer window. `onlyTrainable` drops the rows of `_spells` the player cannot
            /// buy yet - the upper ranks of a ladder they have not climbed, and every other unavailable
            /// one - and the ranks they already hold, which the client would redraw as available on the
            /// next spell learned; it keeps the rest: the steps open to them and the recipes they know.
            void SendSpells(Creature* npc, Player* player, LocaleConstant locale, bool onlyTrainable = false) const;
            bool CanTeachSpell(Player const* player, Spell const* trainerSpell) const;
            bool RepublishesAfterPurchase() const;
            void TeachSpell(Creature* npc, Player* player, uint32 spellId);

            [[nodiscard]] uint32 GetTrainerId() const { return _trainerId; }
            [[nodiscard]] Type GetTrainerType() const { return _type; }
            [[nodiscard]] uint32 GetTrainerRequirement() const { return _requirement; }
            bool IsTrainerValidForPlayer(Player const* player) const;
            /// This trainer, greetings included, teaching `spells` instead of its own.
            [[nodiscard]] Trainer WithSpells(std::vector<Spell> spells) const;

            private:
            SpellState GetSpellState(Player const* player, Spell const* trainerSpell) const;
            void SendTeachFailure(Creature const* npc, Player const* player, uint32 spellId, FailReason reason) const;
            void SendTeachSucceeded(Creature const* npc, Player const* player, uint32 spellId) const;
            [[nodiscard]] std::string const& GetGreeting(LocaleConstant locale) const;

            friend ObjectMgr;
            void AddGreetingLocale(LocaleConstant locale, std::string greeting);

            uint32 _trainerId;
            Type _type;
            uint32 _requirement;
            std::vector<Spell> _spells;
            std::array<std::string, TOTAL_LOCALES> _greeting;
    };

    /// The rows a Wildcard Hero trains: the next rank of each Wildcard ability it knows, set by AscensionWildcard.
    using WildcardRankRows = std::vector<Spell> (*)(Player const* player);
    AC_GAME_API void SetWildcardRankRows(WildcardRankRows rows);

    /// Whether this Hero trains those rows: a Wildcard Hero, or any Hero on a classless realm, set by AscensionWildcard.
    using RankTrainerHero = bool (*)(Player const* player);
    AC_GAME_API void SetRankTrainerHero(RankTrainerHero heroes);

    /// The class trainer a realm serves this player in place of `trainer`, or nullptr to keep it.
    using ClassTrainerFor = Trainer* (*)(Trainer const& trainer, Player const* player);
    AC_GAME_API void SetClassTrainerFor(ClassTrainerFor trainers);

    /// The trainer that serves this player at this unit: its own, or the class trainer the realm puts in its place,
    /// except that a rank-training Hero is taught the next rank of each ability it knows at any class trainer or
    /// Book of Ascension. A class trainer unit without a trainer of its own (a Book of Ascension) serves the player's
    /// own class trainer. Valid until the next call on this thread.
    AC_GAME_API Trainer* GetTrainerFor(Creature const* npc, Player const* player);
}

#endif // Trainer_h__
