/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef MOD_PATH_TO_ASCENSION_H
#define MOD_PATH_TO_ASCENSION_H

#include "Define.h"

#include <array>
#include <map>
#include <optional>
#include <string>
#include <vector>

class Player;
class WorldSession;
class WorldPacket;

namespace PathToAscension
{
    struct Reward
    {
        uint32 rowId;
        uint32 itemId;
        uint32 count;
    };

    struct Objective
    {
        uint32 id;
        uint32 type;
        std::array<uint32, 4> data;
        std::string text;
    };

    // Tutorial.dbc keeps its complete physical record; the fields are addressed by index below.
    struct Tutorial
    {
        std::array<uint32, 93> fields;
        std::string icon;
        std::string auxiliaryText;
        std::string name;
        std::string pages;
        std::string hint;
        std::vector<Reward> rewards;
        std::vector<Objective> objectives;

        uint32 Id() const { return fields[0]; }
        uint32 CategoryId() const { return fields[1]; }
        uint32 AchievementId() const { return fields[2]; }
        uint32 QuestId() const { return fields[3]; }
    };

    namespace TutorialField
    {
        constexpr uint32 FirstPrevious = 4;
        constexpr uint32 LastPrevious = 13;
        constexpr uint32 RaceMask = 15;
        constexpr uint32 ClassMaskLow = 16;
        constexpr uint32 ClassMaskHigh = 17;
        constexpr uint32 FirstRequiredSpell = 22;
        constexpr uint32 LastRequiredSpell = 30;
        constexpr uint32 RequiredGameModes = 31;
        constexpr uint32 ExcludedGameModes = 32;
        constexpr uint32 Expansion = 33;
        constexpr uint32 FirstRealmAvailability = 88;
    }

    constexpr uint32 AnyExpansion = 3;
    constexpr uint32 ExpectedTutorials = 262;
    constexpr uint32 ExpectedQuests = 196;

    class Catalog
    {
    public:
        bool Load(std::string const& dbcDirectory, std::string& error);
        std::map<uint32, Tutorial> const& Tutorials() const { return _tutorials; }
        std::map<uint32, std::vector<uint32>> const& Quests() const { return _quests; }
        Tutorial const* Find(uint32 id) const;

    private:
        std::map<uint32, Tutorial> _tutorials;
        std::map<uint32, std::vector<uint32>> _quests;
        std::map<uint32, std::string> _categories;
    };

    enum class RealmProfile : uint8
    {
        Live = 0,
        Seasonal = 1,
        League = 2,
        PTR = 3,
        Development = 4
    };

    constexpr uint32 RealmAvailabilityField(RealmProfile profile)
    {
        return TutorialField::FirstRealmAvailability + uint32(profile);
    }

    struct Settings
    {
        bool browser = false;
        bool verifiedProgress = false;
        bool rewards = false;
        bool tracking = false;
        bool legacyContent = false;
        uint32 expansion = 0;
        uint32 clientExpansion = 2;
        RealmProfile realm = RealmProfile::Live;
        RealmProfile client = RealmProfile::Live;
    };

    Settings const& GetSettings();
    Catalog const& GetCatalog();
    bool IsLoaded();

    constexpr char VerifiedSetting[] = "core.ascension.tutorial_verified";
    constexpr char ClaimSetting[] = "core.ascension.tutorial_rewards";
    constexpr char EventSetting[] = "core.ascension.tutorial_events";
    constexpr char TrackingSetting[] = "core.ascension.tutorial_tracking";
    constexpr char RidingSetting[] = "core.ascension.tutorial_riding";
    constexpr char AppearanceSetting[] = "core.ascension.tutorial_appearances";

    uint32 SettingValue(Player const* player, char const* source, uint32 index);
    bool MatchesRaceAndClass(Player const* player, Tutorial const& tutorial);
    std::optional<uint32> GameModeMask(Player const* player);

    void CompleteVerifiedTutorial(Player* player, uint32 tutorialId);
    void RecordTutorialEvent(Player* player, uint32 tutorialId, uint32 bit);
    bool IsLegacyAvailable(uint32 tutorialId);
    bool IsExpansionOffered(Tutorial const& tutorial);
    bool IsCallbackImplemented(uint32 tutorialId);
    bool IsStarterMountQuest(uint32 questId);
    bool IsCallBoard(uint32 entry);

    void ConfigureRewards();
    bool IsTrackingQuest(uint32 questId);
    bool IsQuestAvailable(Player const* player, uint32 questId);
    void SyncTracking(Player* player, uint32 tutorialId);
    void StartTrackedQuest(Player* player, uint32 questId);
    uint32 NpcRewardTutorial(Player const* player, uint32 questId);
    void Claim(Player* player, uint32 tutorialId);
    bool QueueClientRequest(WorldSession* session, WorldPacket const& packet);
    void LoginRewards(Player* player);
    void PrestigeRewards(Player* player);
    void LogoutRewards(Player* player);
    void UpdateRewards(Player* player);
}

void AddPathToAscensionProgressScripts();
void AddPathToAscensionRewardScripts();

#endif
