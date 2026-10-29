/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayPlacement.h"
#include "CreatureData.h"
#include "gtest/gtest.h"

#include <cmath>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <set>
#include <string>
#include <vector>

using namespace CoAGameplay;

namespace
{
constexpr float Tolerance = 1.0f;

PlacementSample OnFloor(float z, float floorZ)
{
    PlacementSample sample;
    sample.z = z;
    sample.floorZ = floorZ;
    return sample;
}

std::string WriteFile(std::string const& suffix, std::vector<uint8> const& bytes)
{
    testing::TestInfo const* test = testing::UnitTest::GetInstance()->current_test_info();
    std::filesystem::path const path =
        std::filesystem::temp_directory_path() / (std::string(test->name()) + suffix + ".dbc");
    std::ofstream(path.string(), std::ios::binary).write(reinterpret_cast<char const*>(bytes.data()), bytes.size());
    return path.string();
}

void Append(std::vector<uint8>& bytes, uint32 value)
{
    uint8 raw[sizeof(value)];
    std::memcpy(raw, &value, sizeof(value));
    bytes.insert(bytes.end(), raw, raw + sizeof(raw));
}

std::vector<uint8> TwoRecordFile(uint32 magic)
{
    std::vector<uint8> bytes;
    for (uint32 value : { magic, 2u, 2u, 8u, 1u })
        Append(bytes, value);
    for (uint32 value : { 7u, 11u, 652083u, 12u })
        Append(bytes, value);
    bytes.push_back(0);
    return bytes;
}
}

TEST(CoAGameplayPlacement, GroundedWithinTolerance)
{
    EXPECT_EQ(ClassifyPlacement(OnFloor(10.0f, 10.5f), Tolerance), PlacementVerdict::Grounded);
    EXPECT_EQ(ClassifyPlacement(OnFloor(10.0f, 9.2f), Tolerance), PlacementVerdict::Grounded);
}

TEST(CoAGameplayPlacement, LevelRaysCircleAtThreeHeights)
{
    std::vector<ClearanceRay> const& rays = LevelRays();
    ASSERT_EQ(rays.size(), 72u);
    std::set<float> heights;
    for (ClearanceRay const& ray : rays)
    {
        EXPECT_FLOAT_EQ(ray.dz, 0.0f);
        EXPECT_NEAR(std::hypot(ray.dx, ray.dy), 1.0f, 1e-5f);
        heights.insert(ray.originHeight);
    }
    EXPECT_EQ(heights, (std::set<float>{ 0.6f, 1.2f, 1.8f }));
}

TEST(CoAGameplayPlacement, HeadroomRayLooksStraightUp)
{
    std::vector<ClearanceRay> const& rays = HeadroomRays();
    ASSERT_EQ(rays.size(), 1u);
    EXPECT_FLOAT_EQ(rays.front().dx, 0.0f);
    EXPECT_FLOAT_EQ(rays.front().dy, 0.0f);
    EXPECT_FLOAT_EQ(rays.front().dz, 1.0f);
}

TEST(CoAGameplayPlacement, NearestHitIsReachWithoutHits)
{
    EXPECT_FLOAT_EQ(NearestHit(LevelRays(), [](ClearanceRay const&) { return std::optional<float>(); }),
        ClearanceReach);
}

TEST(CoAGameplayPlacement, NearestHitIsClosestWall)
{
    float const clearance = NearestHit(LevelRays(), [](ClearanceRay const& ray) -> std::optional<float>
    {
        if (ray.originHeight == 1.2f && ray.dx > 0.99f)
            return 0.4f;
        if (ray.dy > 0.99f)
            return 3.0f;
        return std::nullopt;
    });
    EXPECT_FLOAT_EQ(clearance, 0.4f);
}

TEST(CoAGameplayPlacement, NearestHitIgnoresHitsBeyondReach)
{
    EXPECT_FLOAT_EQ(NearestHit(HeadroomRays(), [](ClearanceRay const&) { return std::optional<float>(25.0f); }),
        ClearanceReach);
}

TEST(CoAGameplayPlacement, FloatingAboveTolerance)
{
    EXPECT_EQ(ClassifyPlacement(OnFloor(12.0f, 10.0f), Tolerance), PlacementVerdict::Floating);
}

TEST(CoAGameplayPlacement, UnderGroundBelowFloor)
{
    EXPECT_EQ(ClassifyPlacement(OnFloor(8.5f, 10.0f), Tolerance), PlacementVerdict::UnderGround);
}

TEST(CoAGameplayPlacement, NoFloorBelowTerrainIsUnderGround)
{
    PlacementSample sample;
    sample.z = 15.0f;
    sample.terrainZ = 20.0f;
    EXPECT_EQ(ClassifyPlacement(sample, Tolerance), PlacementVerdict::UnderGround);
}

TEST(CoAGameplayPlacement, NoFloorHighAboveTerrainIsFloating)
{
    PlacementSample sample;
    sample.z = 90.0f;
    sample.terrainZ = 20.0f;
    EXPECT_EQ(ClassifyPlacement(sample, Tolerance), PlacementVerdict::Floating);
    ASSERT_TRUE(GroundGap(sample).has_value());
    EXPECT_FLOAT_EQ(*GroundGap(sample), 70.0f);
}

TEST(CoAGameplayPlacement, MayFloatExemptsFloatingButNotUnderGround)
{
    PlacementSample high = OnFloor(30.0f, 10.0f);
    high.mayFloat = true;
    EXPECT_EQ(ClassifyPlacement(high, Tolerance), PlacementVerdict::Exempt);

    PlacementSample low = OnFloor(8.0f, 10.0f);
    low.mayFloat = true;
    EXPECT_EQ(ClassifyPlacement(low, Tolerance), PlacementVerdict::UnderGround);
}

TEST(CoAGameplayPlacement, SwimmerInLiquidIsExempt)
{
    PlacementSample swimmer = OnFloor(10.0f, 5.0f);
    swimmer.liquidLevel = 15.0f;
    swimmer.maySwim = true;
    EXPECT_EQ(ClassifyPlacement(swimmer, Tolerance), PlacementVerdict::Exempt);

    swimmer.maySwim = false;
    EXPECT_EQ(ClassifyPlacement(swimmer, Tolerance), PlacementVerdict::Floating);
}

TEST(CoAGameplayPlacement, ObjectOnLiquidSurfaceIsExempt)
{
    PlacementSample sample = OnFloor(15.3f, 5.0f);
    sample.liquidLevel = 15.0f;
    EXPECT_EQ(ClassifyPlacement(sample, Tolerance), PlacementVerdict::Exempt);
}

TEST(CoAGameplayPlacement, DeepLiquidWithoutFloorIsUnchecked)
{
    PlacementSample sample;
    sample.z = -30.0f;
    sample.liquidLevel = 0.0f;
    EXPECT_EQ(ClassifyPlacement(sample, Tolerance), PlacementVerdict::Unchecked);
}

TEST(CoAGameplayPlacement, MissingTerrainIsUnchecked)
{
    PlacementSample sample = OnFloor(30.0f, 10.0f);
    sample.terrainAvailable = false;
    EXPECT_EQ(ClassifyPlacement(sample, Tolerance), PlacementVerdict::Unchecked);
}

TEST(CoAGameplayPlacement, SubmergedOnlyBelowLiquidSurface)
{
    PlacementSample sample;
    sample.liquidLevel = 15.0f;
    sample.z = 14.0f;
    EXPECT_TRUE(IsSubmerged(sample));
    sample.z = 15.0f;
    EXPECT_FALSE(IsSubmerged(sample));
    sample.liquidLevel.reset();
    sample.z = 14.0f;
    EXPECT_FALSE(IsSubmerged(sample));
}

TEST(CoAGameplayPlacement, DisplayStateOrder)
{
    EXPECT_EQ(ClassifyDisplay(false, false), DisplayState::Missing);
    EXPECT_EQ(ClassifyDisplay(true, false), DisplayState::ServerOnly);
    EXPECT_EQ(ClassifyDisplay(false, true), DisplayState::Client);
    EXPECT_EQ(ClassifyDisplay(true, true), DisplayState::Client);
    EXPECT_LT(DisplayState::Missing, DisplayState::ServerOnly);
    EXPECT_LT(DisplayState::ServerOnly, DisplayState::Client);
    EXPECT_EQ(DisplayStateName(DisplayState::Missing), "missing");
    EXPECT_EQ(DisplayStateName(DisplayState::ServerOnly), "server_only");
    EXPECT_EQ(DisplayStateName(DisplayState::Client), "client");
}

TEST(CoAGameplayPlacement, VerdictNames)
{
    EXPECT_EQ(PlacementVerdictName(PlacementVerdict::Grounded), "grounded");
    EXPECT_EQ(PlacementVerdictName(PlacementVerdict::Floating), "floating");
    EXPECT_EQ(PlacementVerdictName(PlacementVerdict::UnderGround), "under_ground");
    EXPECT_EQ(PlacementVerdictName(PlacementVerdict::Exempt), "exempt");
    EXPECT_EQ(PlacementVerdictName(PlacementVerdict::Unchecked), "unchecked");
}

TEST(CoAGameplayPlacement, CreatureExemptions)
{
    CreatureMovementData movement;
    EXPECT_FALSE(CreatureMayFloat(movement, 0, 0));

    CreatureMovementData flying;
    flying.Flight = CreatureFlightMovementType::CanFly;
    EXPECT_TRUE(CreatureMayFloat(flying, 0, 0));

    CreatureMovementData hovering;
    hovering.Ground = CreatureGroundMovementType::Hover;
    EXPECT_TRUE(CreatureMayFloat(hovering, 0, 0));

    EXPECT_TRUE(CreatureMayFloat(movement, 0x80, 0));
    EXPECT_TRUE(CreatureMayFloat(movement, 0, 0x03));
    EXPECT_FALSE(CreatureMayFloat(movement, 0, 0x01));
}

TEST(CoAGameplayPlacement, GameObjectExemptions)
{
    EXPECT_TRUE(GameObjectMayFloat(3, 0));
    EXPECT_TRUE(GameObjectMayFloat(15, 1234));
    EXPECT_TRUE(GameObjectMayFloat(11, 1234));
    EXPECT_FALSE(GameObjectMayFloat(3, 1234));
}

TEST(CoAGameplayPlacement, ReadClientDbcIdsReadsFirstDword)
{
    std::optional<std::unordered_set<uint32>> const ids = ReadClientDbcIds(WriteFile("", TwoRecordFile(0x43424457u)));
    ASSERT_TRUE(ids.has_value());
    EXPECT_EQ(*ids, (std::unordered_set<uint32>{ 7u, 652083u }));
}

TEST(CoAGameplayPlacement, ReadClientDbcIdsRejectsUnreadableFile)
{
    std::filesystem::path const missing = std::filesystem::temp_directory_path() / "coa-placement-missing.dbc";
    std::filesystem::remove(missing);
    EXPECT_FALSE(ReadClientDbcIds(missing.string()).has_value());
    EXPECT_FALSE(ReadClientDbcIds(WriteFile("-badmagic", TwoRecordFile(0x12345678u))).has_value());
}

TEST(CoAGameplayPlacement, PositiveGameEventIdFromSpawnListIndex)
{
    EXPECT_EQ(PositiveGameEventId(10, 10), 1u);
    EXPECT_EQ(PositiveGameEventId(10, 16), 7u);
    EXPECT_EQ(PositiveGameEventId(10, 18), 9u);
    EXPECT_FALSE(PositiveGameEventId(10, 9).has_value());
    EXPECT_FALSE(PositiveGameEventId(10, 2).has_value());
}
