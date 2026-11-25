#ifndef COA_PET_BATTLE_STORE_JOURNAL_H
#define COA_PET_BATTLE_STORE_JOURNAL_H

#include "Engine/Catalog.h"
#include <array>
#include <cstdint>
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

namespace CoAPetBattles::Store
{
    inline constexpr uint8_t TeamCount = 3;
    inline constexpr uint8_t MaxQuality = 4;

    struct OwnedPet
    {
        uint32_t species = 0;
        uint8_t level = 1;
        uint32_t xp = 0;
        std::array<uint8_t, 3> picks = { 1, 1, 1 };
        uint8_t quality = 1;
        uint32_t display = 0;
        uint32_t health = 0;
        uint32_t healthAt = 0;
        uint32_t revision = 0;
    };

    struct Team
    {
        std::array<uint32_t, 3> slots = { 0, 0, 0 };
        uint32_t revision = 0;
    };

    enum class RowKind
    {
        Pet,
        Team,
        Account,
    };

    struct RowWrite
    {
        RowKind kind = RowKind::Pet;
        uint32_t account = 0;
        uint32_t key = 0;
        uint32_t revision = 0;
    };

    struct XpGain
    {
        uint32_t gained = 0;
        uint8_t level = 0;
        uint8_t levelsGained = 0;

        bool operator==(XpGain const&) const = default;
    };

    enum class CaptureResult
    {
        Added,
        Replaced,
        Released,
    };

    enum class TeamResult
    {
        Saved,
        BadTeam,
        NotOwned,
        Duplicate,
    };

    uint32_t XpReward(Engine::Catalog const& catalog, uint8_t petLevel, uint8_t enemyLevel);
    uint32_t XpNeeded(Engine::Catalog const& catalog, uint8_t level);

    enum class FeedResult { Fed, NotOwned, FullHealth, TooWeak };

    class Journal
    {
    public:
        Journal(uint32_t account, Engine::Catalog const& catalog, std::vector<OwnedPet> pets,
            std::array<Team, TeamCount> teams, uint8_t activeTeam, uint32_t activeRevision);

        uint32_t Account() const { return _account; }
        std::vector<std::string> const& Rejected() const { return _rejected; }

        bool Owns(uint32_t species) const;
        OwnedPet const* Pet(uint32_t species) const;
        std::vector<OwnedPet const*> Pets() const;

        bool Add(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality, uint32_t display);
        CaptureResult Capture(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality,
            uint32_t display);
        uint8_t Compare(uint32_t species, uint8_t quality, uint8_t level) const;
        bool SetPicks(uint32_t species, std::array<uint8_t, 3> picks);
        bool SetDisplayOnce(uint32_t species, uint32_t display);
        std::optional<XpGain> GrantXp(uint32_t species, uint8_t enemyLevel, uint32_t now);

        uint32_t MaxHealth(OwnedPet const& pet) const;
        uint32_t CurrentHealth(OwnedPet const& pet, uint32_t now) const;
        bool SetHealth(uint32_t species, uint32_t health, uint32_t now);
        size_t HealAll();
        FeedResult Feed(uint32_t species, uint8_t foodLevel, uint32_t now);

        TeamResult SetTeam(uint8_t team, std::array<uint32_t, 3> slots);
        bool SetActiveTeam(uint8_t team);
        uint8_t ActiveTeam() const { return _activeTeam; }
        uint32_t ActiveRevision() const { return _activeRevision; }
        Team const& TeamAt(uint8_t team) const;
        std::array<uint32_t, 3> BattleTeam();

        std::vector<uint32_t> SyncCompanions(std::multimap<uint32_t, uint32_t> const& speciesSpells,
            std::function<bool(uint32_t)> const& knowsSpell);

        std::vector<RowWrite> TakeWrites();

    private:
        uint8_t MaxLevel() const;
        bool Usable(OwnedPet const& pet, std::string* reason) const;
        void Keep(OwnedPet pet);
        void WriteTeam(uint8_t team);

        uint32_t _account;
        Engine::Catalog const* _catalog;
        std::map<uint32_t, OwnedPet> _pets;
        std::set<uint32_t> _blocked;
        std::array<Team, TeamCount> _teams;
        uint8_t _activeTeam;
        uint32_t _activeRevision;
        uint32_t _revision = 0;
        std::vector<std::string> _rejected;
        std::vector<RowWrite> _writes;
        std::map<uint32_t, std::pair<uint32_t, uint32_t>> _fed;
    };
}

#endif
