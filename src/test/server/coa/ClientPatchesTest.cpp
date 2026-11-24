#include "AscensionClientSpellPatches.h"
#include <gtest/gtest.h>

namespace
{
    bool moduleEnabled = false;
    bool IsModuleEnabled() { return moduleEnabled; }
    using Patches = Ascension::ClientPatches<struct TestPatchTag>;
}

TEST(ClientPatches, RegistersSqlOnlyRowsWithoutASelector)
{
    Patches patches;
    patches.Register(9710000);
    EXPECT_TRUE(patches.Contains(9710000));
    EXPECT_TRUE(patches.GetIds().contains(9710000));
    EXPECT_EQ(patches.GetSelector(9710000), Patches::Selector{});
    EXPECT_FALSE(patches.Contains(125));
}

TEST(ClientPatches, DisabledModulesDoNotContributeRowsOrSelectors)
{
    Patches patches;
    moduleEnabled = false;
    patches.Register(42, { 1, 2, 4 }, IsModuleEnabled);
    EXPECT_FALSE(patches.Contains(42));
    EXPECT_TRUE(patches.GetIds().empty());
    EXPECT_TRUE(patches.GetIds(true).contains(42));
    EXPECT_EQ(patches.GetSelector(42), Patches::Selector{});
    moduleEnabled = true;
    EXPECT_TRUE(patches.Contains(42));
    EXPECT_EQ(patches.GetSelector(42), (Patches::Selector{ 1, 2, 4 }));
    moduleEnabled = false;
    EXPECT_FALSE(patches.Contains(42));
    EXPECT_EQ(patches.GetSelector(42), Patches::Selector{});
}

TEST(ClientPatches, ModuleReloadPreservesIndependentRegistrations)
{
    Patches patches;
    moduleEnabled = true;
    patches.Register(42, { 1, 0, 0 });
    patches.Register(42, { 2, 4, 0 }, IsModuleEnabled);
    patches.Register(42, { 0, 8, 0 }, IsModuleEnabled);
    EXPECT_EQ(patches.GetSelector(42), (Patches::Selector{ 3, 12, 0 }));
    moduleEnabled = false;
    EXPECT_TRUE(patches.Contains(42));
    EXPECT_EQ(patches.GetSelector(42), (Patches::Selector{ 1, 0, 0 }));
}

TEST(ClientPatches, ItemAndSpellRegistriesAreIndependent)
{
    Ascension::ClientItemPatches::Instance().Register(1);
    EXPECT_FALSE(Ascension::ClientSpellPatches::Instance().Contains(1));
}

TEST(ClientPatches, ItemDeliveryPreparesRowsWithoutRegisteringLoginDelivery)
{
    Patches patches;
    moduleEnabled = false;
    patches.Register(9725122, { 1, 2, 4 }, IsModuleEnabled, Patches::Delivery::Item);
    EXPECT_TRUE(patches.GetIds(true).contains(9725122));
    EXPECT_FALSE(patches.Contains(9725122));
    EXPECT_FALSE(patches.Contains(9725122, Patches::Delivery::Item));
    moduleEnabled = true;
    EXPECT_TRUE(patches.GetIds().contains(9725122));
    EXPECT_TRUE(patches.Contains(9725122));
    EXPECT_TRUE(patches.Contains(9725122, Patches::Delivery::Item));
    EXPECT_FALSE(patches.Contains(9725122, Patches::Delivery::Login));
    EXPECT_EQ(patches.GetSelector(9725122), (Patches::Selector{ 1, 2, 4 }));
    moduleEnabled = false;
    EXPECT_FALSE(patches.Contains(9725122, Patches::Delivery::Item));
}

TEST(ClientPatches, DeliveryRegistrationsRemainIndependentAcrossModuleReload)
{
    Patches patches;
    moduleEnabled = true;
    patches.Register(42, { 1, 0, 0 }, IsModuleEnabled, Patches::Delivery::Item);
    patches.Register(42, { 0, 2, 0 });
    EXPECT_TRUE(patches.Contains(42, Patches::Delivery::Item));
    EXPECT_TRUE(patches.Contains(42, Patches::Delivery::Login));
    EXPECT_EQ(patches.GetSelector(42), (Patches::Selector{ 1, 2, 0 }));
    moduleEnabled = false;
    EXPECT_FALSE(patches.Contains(42, Patches::Delivery::Item));
    EXPECT_TRUE(patches.Contains(42, Patches::Delivery::Login));
    EXPECT_EQ(patches.GetSelector(42), (Patches::Selector{ 0, 2, 0 }));
}
