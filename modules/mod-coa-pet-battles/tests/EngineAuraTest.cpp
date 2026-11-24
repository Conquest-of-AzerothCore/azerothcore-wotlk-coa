#include "Engine/Battle.h"
#include "Engine/Describe.h"
#include <gtest/gtest.h>
#include <type_traits>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    DataSet AuraData()
    {
        DataSet data;
        data.abilities[10] = { 10, "Howl", 7, 0, "", 0 };
        data.abilities[11] = { 11, "Poison", 4, 0, "", 0 };
        data.abilities[12] = { 12, "Pumped", 8, 0, "", 0 };
        data.abilities[13] = { 13, "Speed Server Only", 0, 0, "", 0 };
        data.abilities[20] = { 20, "Blizzard", 6, 0, "", 0 };
        data.abilities[30] = { 30, "Rally", 7, 0, "", 0 };
        data.turns = { { 30, 1, 0, 255 } };
        data.effects = { { 30, 1, 1, 26, 10, { 0, 100, 2, 0, 0, 0 } } };
        data.auraStates = {
            { 10, "Mod_DamageDealtPercent", 25 },
            { 11, "Mechanic_IsPoisoned", 1 },
            { 12, "Mod_DamageDealtPercent", 10 },
            { 13, "Mod_SpeedPercent", 5 },
            { 20, "Mechanic_IsChilled", 1 },
        };
        return data;
    }

    Catalog const& AuraCatalog()
    {
        static DataSet const data = AuraData();
        static Catalog const catalog(data, Settings());
        return catalog;
    }

    Aura MakeAura(uint32_t id, double left, bool perm = false)
    {
        Aura aura;
        aura.id = id;
        aura.left = left;
        aura.perm = perm;
        if (States const* states = AuraCatalog().StatesOf(id))
            aura.states = *states;
        return aura;
    }

    Pet MakePet(std::string const& family)
    {
        Pet pet;
        pet.family = family;
        pet.level = 25;
        pet.max = 1000;
        pet.baseMax = 1000;
        pet.hp = 1000;
        pet.speed = 100;
        return pet;
    }
}

TEST(CoAPetBattlesEngine, ModSumsAurasAndWeather)
{
    Pet beast = MakePet("Beast");
    beast.auras = { MakeAura(10, 2), MakeAura(12, 2) };
    EXPECT_EQ(Mod(nullptr, beast, "Mod_DamageDealtPercent"), 35);

    SeededRng rng(1);
    Battle battle(AuraCatalog(), { MakePet("Beast") }, { MakePet("Elemental") }, rng);
    battle.weather = Weather { 20, 3 };
    EXPECT_EQ(Mod(&battle, battle.Current(Side::P), "Mechanic_IsChilled"), 0);
    battle.resolving = true;
    EXPECT_EQ(Mod(&battle, battle.Current(Side::P), "Mechanic_IsChilled"), 1);
    EXPECT_EQ(Mod(&battle, battle.Current(Side::E), "Mechanic_IsChilled"), 0);
}

TEST(CoAPetBattlesEngine, TypeOverrideChangesFamily)
{
    Pet pet = MakePet("Beast");
    Aura ward = MakeAura(10, 2);
    ward.states["Special_TypeOverride"] = 2;
    pet.auras = { ward };
    EXPECT_EQ(EffFam(pet), "Dragonkin");
    pet.auras.front().states["Special_TypeOverride"] = 11;
    EXPECT_EQ(EffFam(pet), "Beast");
    pet.auras.clear();
    EXPECT_EQ(EffFam(pet), "Beast");
}

TEST(CoAPetBattlesEngine, PerkUpRaisesMaxAndClampsHp)
{
    Pet pet = MakePet("Beast");
    Aura perk = MakeAura(10, 2);
    perk.states["maxHealthBonus"] = 400;
    pet.auras = { perk };
    SyncMax(pet);
    EXPECT_EQ(pet.max, 1100);
    pet.hp = 1100;
    pet.auras.clear();
    SyncMax(pet);
    EXPECT_EQ(pet.max, 1000);
    EXPECT_EQ(pet.hp, 1000);
}

TEST(CoAPetBattlesEngine, StatusStringFormatsAurasLikeUpstream)
{
    Pet pet = MakePet("Beast");
    pet.auras = { MakeAura(10, 2), MakeAura(11, 1), MakeAura(11, 3), MakeAura(12, 99, true), MakeAura(13, 2) };
    EXPECT_EQ(StatusString(AuraCatalog(), pet),
        "Howl~Spell_Holy_PowerWordShield~2~1~0;Poison~Ability_Rogue_DualWeild~3~2~1;"
        "Pumped~Spell_Holy_PowerWordShield~0~1~0");
    EXPECT_EQ(TagText(AuraCatalog(), pet), "Howl  Poison x2  Pumped");
    EXPECT_EQ(Speed(nullptr, pet), 105);
}

TEST(CoAPetBattlesEngine, FlavoredAuraWithoutTextFallsBackToTheAuraTip)
{
    Pet caster = MakePet("Beast");
    PetAbility flavored;
    flavored.id = 30;
    flavored.name = "Battle Cry";
    caster.abil[0] = flavored;
    StatusEntry entry;
    entry.aid = 10;
    entry.power = 100;
    entry.src = &caster;
    std::string const expected = AuraTip(AuraCatalog(), 10, 100);
    ASSERT_FALSE(expected.empty());
    EXPECT_EQ(StatusTip(AuraCatalog(), entry), expected);
    caster.abil[0]->text = "Rallies the team.";
    EXPECT_EQ(StatusTip(AuraCatalog(), entry), "Rallies the team.");
}

TEST(CoAPetBattlesEngine, MovingAurasKeepsTheirList)
{
    static_assert(std::is_nothrow_move_constructible_v<AuraTable>);
    static_assert(std::is_nothrow_move_assignable_v<AuraTable>);
    AuraTable source { MakeAura(10, 2), MakeAura(11, 1) };
    auto const list = source.Share();
    AuraTable moved(std::move(source));
    EXPECT_EQ(moved.Share(), list);
    EXPECT_EQ(moved.size(), 2u);
    EXPECT_TRUE(source.empty());
    source.push_back(MakeAura(12, 3));
    EXPECT_EQ(source.size(), 1u);
    EXPECT_EQ(moved.size(), 2u);

    AuraTable assigned;
    assigned = std::move(moved);
    EXPECT_EQ(assigned.Share(), list);
    EXPECT_TRUE(moved.empty());

    Pet pet = MakePet("Beast");
    pet.auras = assigned;
    auto const petList = pet.auras.Share();
    Pet movedPet(std::move(pet));
    EXPECT_EQ(movedPet.auras.Share(), petList);
}
