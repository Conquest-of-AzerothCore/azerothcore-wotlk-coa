#ifndef COA_PET_BATTLE_DATA_H
#define COA_PET_BATTLE_DATA_H

#include <array>
#include <cstdint>
#include <functional>
#include <map>
#include <optional>
#include <string>
#include <vector>

namespace CoAPetBattles
{
    constexpr uint32_t StandInBase = 9800000;
    constexpr uint32_t StandInLimit = 9849999;
    constexpr uint32_t ExplicitStandInBase = 9850000;
    constexpr uint32_t ExplicitStandInLimit = 9899999;

    struct Species
    {
        uint32_t entry = 0;
        std::string name;
        uint32_t kit = 0;
        bool wild = false;
        bool companion = false;
        bool critter = false;
        bool synthetic = false;
        bool standin = false;
        std::string icon;
        float scale = 0.0f;
    };

    struct Kit
    {
        uint32_t id = 0;
        std::string name;
        uint8_t family = 0;
        int16_t power = 0;
        int16_t speed = 0;
        int16_t stamina = 0;
    };

    struct KitAbility
    {
        uint32_t kit = 0;
        uint8_t slot = 0;
        uint8_t unlockLevel = 0;
        uint32_t ability = 0;
    };

    struct Ability
    {
        uint32_t id = 0;
        std::string name;
        int8_t family = 0;
        uint8_t cooldown = 0;
        std::string description;
        uint32_t base = 0;
    };

    struct AbilityTurn
    {
        uint32_t ability = 0;
        uint8_t turnIndex = 0;
        uint8_t turn = 0;
        uint8_t event = 0;
    };

    struct AbilityEffect
    {
        uint32_t ability = 0;
        uint8_t turnIndex = 0;
        uint8_t effectIndex = 0;
        uint16_t property = 0;
        uint32_t aura = 0;
        std::array<int32_t, 6> params {};
    };

    struct EffectPropertyLabel
    {
        uint16_t property = 0;
        uint8_t paramIndex = 0;
        std::string label;
    };

    struct State
    {
        uint16_t id = 0;
        std::string name;
    };

    struct AuraState
    {
        uint32_t aura = 0;
        std::string state;
        int32_t value = 0;
    };

    struct XpLevel
    {
        uint8_t level = 0;
        uint16_t wins = 0;
        uint16_t xpPerWin = 0;
    };

    struct Zone
    {
        uint32_t zone = 0;
        std::string name;
        uint8_t petLevelMin = 0;
        uint8_t petLevelMax = 0;
        uint8_t mobLevelMin = 0;
        uint8_t mobLevelMax = 0;
    };

    struct ZoneSpecies
    {
        uint32_t zone = 0;
        uint32_t species = 0;
    };

    struct Presentation
    {
        uint32_t species = 0;
        uint8_t slot = 0;
        uint8_t option = 0;
        uint8_t unlockLevel = 0;
        uint32_t ability = 0;
        std::string name;
        std::string retailName;
        std::string icon;
        std::string tooltip;
        uint32_t visualSpell = 0;
        bool ranged = false;
        std::string visualMode;
        uint32_t preSpell = 0;
        bool hop = false;
        bool spellDealsDamage = false;
        bool goesFirst = false;
    };

    struct ModelSize
    {
        uint32_t species = 0;
        float width = 0.0f;
        float height = 0.0f;
        float silhouette = 0.0f;
    };

    struct DisplaySize
    {
        uint32_t display = 0;
        float silhouette = 0.0f;
    };

    struct Companion
    {
        uint32_t spell = 0;
        uint32_t species = 0;
    };

    inline constexpr uint8_t BalancedBreed = 3;

    struct BreedStats
    {
        int16_t stamina = 0;
        int16_t power = 0;
        int16_t speed = 0;
    };

    struct DataSet
    {
        std::map<uint32_t, Species> species;
        std::map<uint32_t, Kit> kits;
        std::map<uint32_t, Ability> abilities;
        std::map<uint32_t, Zone> zones;
        std::map<uint32_t, ModelSize> modelSizes;
        std::map<uint32_t, DisplaySize> displaySizes;
        std::map<uint32_t, Companion> companions;
        std::map<uint32_t, std::map<uint8_t, BreedStats>> breeds;
        std::map<uint8_t, BreedStats> defaultBreeds;
        std::map<uint16_t, State> states;
        std::map<uint8_t, XpLevel> xp;
        std::map<uint32_t, uint32_t> standIns;
        std::vector<KitAbility> kitAbilities;
        std::vector<AbilityTurn> turns;
        std::vector<AbilityEffect> effects;
        std::vector<EffectPropertyLabel> labels;
        std::vector<AuraState> auraStates;
        std::vector<ZoneSpecies> zoneSpecies;
        std::vector<Presentation> presentations;
    };

    struct Report
    {
        std::vector<std::string> errors;
        std::vector<std::string> warnings;
    };

    struct Settings
    {
        uint8_t maxLevel = 25;
        std::array<uint32_t, 4> qualityWeights = { 55, 28, 13, 4 };
        double captureHealth = 0.35;
        uint32_t regenPercent = 1;
        uint32_t regenSeconds = 10;
        uint32_t fedPercent = 10;
        uint32_t fedStepSeconds = 2;
        uint32_t fedSeconds = 20;
        double xpStep = 0.20;
    };

    struct WildSettings
    {
        bool enabled = true;
        uint32_t tickMs = 5000;
        uint32_t blipMs = 1000;
        float search = 60;
        float spacing = 90;
        uint32_t maxArea = 3;
        uint32_t cooldownSeconds = 90;
        uint32_t lifetimeSeconds = 600;
        float leave = 90;
        uint32_t awayGraceSeconds = 60;
        float moveRescan = 25;
        uint32_t rescanIdleSeconds = 45;
        float talkRange = 12;
        uint8_t soloMaxLevel = 2;
        float spotMin = 5;
        float spotMax = 50;
        float maxHeightDifference = 2.5f;
        uint32_t tries = 8;
        float fallbackDistance = 3;
        float wander = 3;
    };

    uint32_t StandInEntry(DataSet const& data, uint32_t species);
    uint8_t PetLevel(DataSet const& data, uint8_t maxLevel, uint32_t mobLevel, uint32_t zone);
    Report Validate(DataSet const& data, std::function<bool(uint32_t)> const& creatureTemplateExists);
    std::optional<std::array<uint32_t, 4>> ParseQualityWeights(std::string const& text);
    std::optional<double> ParseDecimal(std::string const& text);
    std::string DecimalText(double value);
}

#endif
