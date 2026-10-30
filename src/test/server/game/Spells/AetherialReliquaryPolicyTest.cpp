#include "AscensionAetherialReliquaryPolicy.h"
#include <gtest/gtest.h>

namespace
{
constexpr std::size_t AuraOfExperience = 0;
constexpr std::size_t PotionOfExperience = 1;

AetherialReliquary::StoredBuffs Stored(std::uint32_t aura, std::uint32_t potionMs)
{
    AetherialReliquary::StoredBuffs stored;
    stored.values[AuraOfExperience] = aura;
    stored.values[PotionOfExperience] = potionMs;
    return stored;
}
}

TEST(AetherialReliquary, StoresTheAuraAndPotionOfExperience)
{
    EXPECT_EQ(AetherialReliquary::StorableBuffs[AuraOfExperience].spellId, 818059u);
    EXPECT_EQ(AetherialReliquary::StorableBuffs[AuraOfExperience].kind, AetherialReliquary::BuffKind::Toggle);
    EXPECT_EQ(AetherialReliquary::StorableBuffs[PotionOfExperience].spellId, 818046u);
    EXPECT_EQ(AetherialReliquary::StorableBuffs[PotionOfExperience].kind, AetherialReliquary::BuffKind::Timed);
    EXPECT_TRUE(AetherialReliquary::HasUniqueEntries());
}

TEST(AetherialReliquary, StoredBoostsUseASettingSavedWithoutOptionalPlayerSettings)
{
    EXPECT_TRUE(AetherialReliquary::SettingSource.starts_with(AetherialReliquary::PersistentSettingPrefix));
    EXPECT_EQ(AetherialReliquary::PersistentSettingPrefix, "core.");
}

TEST(AetherialReliquary, NothingStoredIsEmpty)
{
    EXPECT_TRUE(AetherialReliquary::StoredBuffs{}.Empty());
    EXPECT_FALSE(Stored(1, 0).Empty());
    EXPECT_FALSE(Stored(0, 1).Empty());
}

TEST(AetherialReliquary, AuraIsKeptWhenEitherCaptureHadIt)
{
    EXPECT_EQ(AetherialReliquary::Merge(Stored(0, 0), Stored(1, 0)), Stored(1, 0));
    EXPECT_EQ(AetherialReliquary::Merge(Stored(1, 0), Stored(0, 0)), Stored(1, 0));
    EXPECT_EQ(AetherialReliquary::Merge(Stored(1, 0), Stored(1, 0)), Stored(1, 0));
}

TEST(AetherialReliquary, PotionTimeAccumulates)
{
    EXPECT_EQ(AetherialReliquary::Merge(Stored(0, 3600000), Stored(0, 1800000)), Stored(0, 5400000));
    EXPECT_EQ(AetherialReliquary::Merge(Stored(1, 1200), Stored(0, 0)), Stored(1, 1200));
}

TEST(AetherialReliquary, MergingNothingChangesNothing)
{
    EXPECT_EQ(AetherialReliquary::Merge(Stored(1, 7000), AetherialReliquary::StoredBuffs{}), Stored(1, 7000));
    EXPECT_EQ(AetherialReliquary::Merge(AetherialReliquary::StoredBuffs{}, Stored(1, 7000)), Stored(1, 7000));
}

TEST(AetherialReliquary, PotionTimeNeverExceedsAnAuraDuration)
{
    std::uint32_t const max = AetherialReliquary::MaxStoredDurationMs;
    EXPECT_EQ(AetherialReliquary::Merge(Stored(0, max - 10), Stored(0, 20)), Stored(0, max));
    EXPECT_EQ(AetherialReliquary::Merge(Stored(0, max), Stored(0, max)), Stored(0, max));
    EXPECT_EQ(AetherialReliquary::Merge(Stored(0, 0xFFFFFFFFu), Stored(0, 1)), Stored(0, max));
}
