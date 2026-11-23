#include "Engine/Round.h"
#include "Engine/Rules.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    constexpr uint32_t Strike = 900001;
    constexpr uint32_t WindUp = 900002;
    constexpr uint32_t Oddity = 900003;
    constexpr uint32_t StunAura = 900010;
    constexpr uint32_t DodgeAura = 900011;
    constexpr uint32_t StormAura = 900020;

    class ConstantRng : public Rng
    {
    public:
        explicit ConstantRng(int32_t value) : _value(value) { }
        int32_t Roll(int32_t lo, int32_t hi) override { return std::clamp(_value, lo, hi); }

    private:
        int32_t _value;
    };

    void AddAbility(DataSet& data, uint32_t id, std::string const& name, int8_t family,
        std::vector<std::vector<CoAPetBattles::AbilityEffect>> const& turns)
    {
        data.abilities[id] = { id, name, family, 0, "", 0 };
        for (size_t t = 0; t < turns.size(); ++t)
        {
            data.turns.push_back({ id, static_cast<uint8_t>(t + 1), 0, 255 });
            for (size_t e = 0; e < turns[t].size(); ++e)
            {
                CoAPetBattles::AbilityEffect effect = turns[t][e];
                effect.ability = id;
                effect.turnIndex = static_cast<uint8_t>(t + 1);
                effect.effectIndex = static_cast<uint8_t>(e + 1);
                data.effects.push_back(effect);
            }
        }
    }

    CoAPetBattles::AbilityEffect Effect(uint16_t prop, std::array<int32_t, 6> params, uint32_t aura = 0)
    {
        return { 0, 0, 0, prop, aura, params };
    }

    Catalog const& MechanicCatalog()
    {
        static DataSet const data = []
        {
            DataSet d = Fixtures::LoadData();
            AddAbility(d, Strike, "Strike", 7, { { Effect(24, { 20, 100, 0, 0, 0, 0 }) } });
            AddAbility(d, WindUp, "Wind Up", 7, { { Effect(22, { 0, 0, 0, 0, 0, 0 }) },
                { Effect(24, { 20, 100, 0, 0, 0, 0 }) } });
            AddAbility(d, Oddity, "Oddity", 7, { { Effect(999, { 0, 0, 0, 0, 0, 0 }) } });
            AddAbility(d, StunAura, "Stunned", 7, {});
            AddAbility(d, DodgeAura, "Dodge", 7, {});
            AddAbility(d, StormAura, "Storm", 7, {});
            d.auraStates.push_back({ StunAura, "Mechanic_IsStunned", 1 });
            d.auraStates.push_back({ DodgeAura, "Stat_Dodge", 50 });
            d.auraStates.push_back({ StormAura, "Mod_PetTypeDamageDealtPercent", 25 });
            d.auraStates.push_back({ StormAura, "Mod_PetType_ID", 8 });
            return d;
        }();
        static Catalog const catalog(data, Settings());
        return catalog;
    }

    PetAbility AbilityOf(uint32_t id)
    {
        AbilityDef const& def = *MechanicCatalog().Ability(id);
        PetAbility ability;
        ability.id = id;
        ability.name = def.name;
        ability.retailName = def.name;
        ability.text = def.text;
        ability.family = def.family;
        ability.cooldown = def.cooldown;
        for (Turn const& turn : def.turns)
            (turn.event == 255 ? ability.turns : ability.procs).push_back(turn);
        return ability;
    }

    Pet MakePet(uint32_t ability, std::string const& family, double hp = 1000)
    {
        Pet pet;
        pet.name = family + " pet";
        pet.family = family;
        pet.level = 25;
        pet.quality = 4;
        pet.max = 1000;
        pet.baseMax = 1000;
        pet.hp = hp;
        pet.power = 100;
        pet.speed = 100;
        pet.abil[0] = AbilityOf(ability);
        return pet;
    }

    Aura AuraOf(uint32_t id, double left)
    {
        Aura aura;
        aura.id = id;
        aura.left = left;
        if (States const* states = MechanicCatalog().StatesOf(id))
            aura.states = *states;
        return aura;
    }

    Pet Stunned(Pet pet)
    {
        pet.auras.push_back(AuraOf(StunAura, 5));
        return pet;
    }

    size_t Count(std::vector<Event> const& events, std::string const& kind)
    {
        return static_cast<size_t>(std::count_if(events.begin(), events.end(),
            [&kind](Event const& event) { return event.kind == kind; }));
    }

    Event const* First(std::vector<Event> const& events, std::string const& kind)
    {
        for (Event const& event : events)
            if (event.kind == kind)
                return &event;
        return nullptr;
    }

    bool HasAura(Pet const& pet, uint32_t id)
    {
        for (Aura const& aura : pet.auras)
            if (aura.id == id)
                return true;
        return false;
    }
}

TEST(CoAPetBattlesMechanics, StunSkipsTurn)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    RoundResult const result = Round(battle, "A1", "A1");
    EXPECT_EQ(Count(result.events, "act"), 1u);
    Event const* stunned = First(result.events, "stunned");
    ASSERT_NE(stunned, nullptr);
    EXPECT_EQ(stunned->Text("side"), "E");
}

TEST(CoAPetBattlesMechanics, WallBlocksChargesThenBreaks)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    battle.wall = Wall { 326, 2, Side::E };
    for (int i = 0; i < 2; ++i)
    {
        RoundResult const blocked = Round(battle, "A1", "A1");
        Event const* dodge = First(blocked.events, "dodge");
        ASSERT_NE(dodge, nullptr);
        EXPECT_EQ(dodge->Text("text"), "Blocked!");
        EXPECT_EQ(Count(blocked.events, "dmg"), 0u);
    }
    EXPECT_FALSE(battle.wall.has_value());
    EXPECT_EQ(Count(Round(battle, "A1", "A1").events, "dmg"), 1u);
}

TEST(CoAPetBattlesMechanics, WeatherChangesDamage)
{
    ConstantRng plainRng(100);
    Battle plain(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, plainRng);
    ConstantRng stormRng(100);
    Battle storm(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, stormRng);
    storm.weather = Weather { StormAura, 5 };
    Event const plainHit = *First(Round(plain, "A1", "A1").events, "dmg");
    Event const stormHit = *First(Round(storm, "A1", "A1").events, "dmg");
    EXPECT_EQ(plainHit.Number("dmg"), Damage(20, 100, "Beast", "Critter", 0, 0));
    EXPECT_EQ(stormHit.Number("dmg"), Damage(20, 100, "Beast", "Critter", 25, 0));
    EXPECT_GT(stormHit.Number("dmg"), plainHit.Number("dmg"));
}

TEST(CoAPetBattlesMechanics, DeathForcesSwap)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { Stunned(MakePet(Strike, "Beast", 1)), MakePet(Strike, "Beast") },
        { MakePet(Strike, "Critter") }, rng);
    RoundResult const death = Round(battle, "A1", "A1");
    EXPECT_EQ(death.status, "force");
    EXPECT_NE(First(death.events, "faint"), nullptr);
    RoundResult const swap = Round(battle, "S2", "A1");
    ASSERT_GE(swap.events.size(), 2u);
    EXPECT_EQ(swap.events[0].kind, "swap");
    EXPECT_TRUE(swap.events[0].Flag("free"));
    EXPECT_EQ(swap.events[1].kind, "turn");
    EXPECT_EQ(swap.status, "turn");
    EXPECT_EQ(battle.Active(Side::P), 2);
}

TEST(CoAPetBattlesMechanics, ChannelContinues)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(WindUp, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    RoundResult const windUp = Round(battle, "A1", "A1");
    EXPECT_EQ(Count(windUp.events, "dmg"), 0u);
    ASSERT_TRUE(battle.Current(Side::P).channel.has_value());
    EXPECT_EQ(AI(battle, Side::P), "A1");
    RoundResult const release = Round(battle, "A3", "A1");
    EXPECT_EQ(Count(release.events, "dmg"), 1u);
    EXPECT_FALSE(battle.Current(Side::P).channel.has_value());
}

TEST(CoAPetBattlesMechanics, TrapOnlyAtOrBelowThreshold)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { MakePet(Strike, "Critter", 350) }, rng);
    EXPECT_TRUE(CanTrap(battle));
    battle.Current(Side::E).hp = 351;
    EXPECT_FALSE(CanTrap(battle));
    battle.Current(Side::E).hp = 0;
    EXPECT_FALSE(CanTrap(battle));
}

TEST(CoAPetBattlesMechanics, CritAndDodgeWithForcedRolls)
{
    ConstantRng critRng(1);
    Battle crit(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, critRng);
    Event const critical = *First(Round(crit, "A1", "A1").events, "dmg");
    EXPECT_TRUE(critical.Flag("crit"));
    EXPECT_EQ(critical.Number("dmg"), 2 * Damage(20, 100, "Beast", "Critter", 0, 0));

    ConstantRng normalRng(100);
    Battle normal(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, normalRng);
    EXPECT_FALSE(First(Round(normal, "A1", "A1").events, "dmg")->Flag("crit"));

    ConstantRng dodgeRng(1);
    Pet dodger = Stunned(MakePet(Strike, "Critter"));
    dodger.auras.push_back(AuraOf(DodgeAura, 5));
    Battle dodge(MechanicCatalog(), { MakePet(Strike, "Beast") }, { dodger }, dodgeRng);
    RoundResult const dodged = Round(dodge, "A1", "A1");
    Event const* miss = First(dodged.events, "dodge");
    ASSERT_NE(miss, nullptr);
    EXPECT_FALSE(miss->Has("text"));
    EXPECT_EQ(Count(dodged.events, "dmg"), 0u);
}

TEST(CoAPetBattlesMechanics, Prop67Handler)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(277, "Beast", 100) }, { Stunned(MakePet(Strike, "Critter", 900)) },
        rng);
    Round(battle, "A1", "A1");
    EXPECT_EQ(battle.Current(Side::P).hp, 500);
    EXPECT_EQ(battle.Current(Side::E).hp, 500);
}

TEST(CoAPetBattlesMechanics, Prop168Handler)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(522, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    Round(battle, "A1", "A1");
    Pet const& enemy = battle.Current(Side::E);
    auto const nevermore = std::find_if(enemy.auras.begin(), enemy.auras.end(),
        [](Aura const& aura) { return aura.id == 738; });
    ASSERT_NE(nevermore, enemy.auras.end());
    EXPECT_EQ(nevermore->left, 2);
}

TEST(CoAPetBattlesMechanics, Prop150Handler)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(325, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    RoundResult const result = Round(battle, "A1", "A1");
    ASSERT_TRUE(battle.wall.has_value());
    EXPECT_EQ(battle.wall->id, 326u);
    EXPECT_EQ(battle.wall->charges, 2);
    Event const* buff = First(result.events, "buff");
    ASSERT_NE(buff, nullptr);
    EXPECT_EQ(buff->Text("what"), "beaver dam");
    EXPECT_EQ(buff->Number("turns"), 2);
}

TEST(CoAPetBattlesMechanics, Prop223Handler)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(1344, "Critter"), MakePet(Strike, "Critter"),
        MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    Round(battle, "A1", "A1");
    EXPECT_TRUE(HasAura(battle.At(Side::P, 1), 759));
    EXPECT_TRUE(HasAura(battle.At(Side::P, 2), 759));
    EXPECT_FALSE(HasAura(battle.At(Side::P, 3), 759));
}

TEST(CoAPetBattlesMechanics, Prop137Handler)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(1073, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    Round(battle, "A1", "A1");
    EXPECT_TRUE(HasAura(battle.Current(Side::P), 1074));
    EXPECT_FALSE(HasAura(battle.Current(Side::P), 1075));
    battle.Current(Side::P).cd = { 0, 0, 0 };
    Round(battle, "A1", "A1");
    EXPECT_TRUE(HasAura(battle.Current(Side::P), 1075));
}

TEST(CoAPetBattlesMechanics, MalformedCommandsAreHandledSafely)
{
    auto events = [](std::string const& command)
    {
        ConstantRng rng(100);
        Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
        std::vector<std::string> canonical;
        for (Event const& event : Round(battle, command, "A1").events)
            canonical.push_back(event.Canonical());
        return canonical;
    };
    EXPECT_EQ(events(""), events("A1"));
    EXPECT_EQ(events("A"), events("A1"));
    EXPECT_EQ(events("A1e10"), events("A1"));
    EXPECT_EQ(events("A-99999999999"), events("A1"));

    for (std::string const command : { "S0", "S9", "Sx", "S", "S1e12", "S2" })
    {
        ConstantRng rng(100);
        Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { MakePet(Strike, "Critter") }, rng);
        RoundResult const result = Round(battle, command, "A1");
        EXPECT_EQ(result.status, "invalid") << command;
        EXPECT_TRUE(result.events.empty()) << command;
        EXPECT_EQ(battle.round, 0) << command;
        EXPECT_EQ(battle.Active(Side::P), 1) << command;
    }
}

TEST(CoAPetBattlesMechanics, NevermoreLocksTheNextAbility)
{
    ConstantRng rng(100);
    Pet enemy = MakePet(Strike, "Critter");
    Battle battle(MechanicCatalog(), { MakePet(522, "Beast") }, { enemy }, rng);
    RoundResult const first = Round(battle, "A1", "A1");
    double lockout = 0;
    for (Turn const& turn : MechanicCatalog().Ability(738)->turns)
        for (Fx const& fx : turn.fx)
            if (fx.prop == 129)
                lockout = fx.p[0];
    ASSERT_EQ(lockout, 5);
    EXPECT_EQ(Count(first.events, "act"), 2u);
    EXPECT_FALSE(HasAura(battle.Current(Side::E), 738));
    EXPECT_EQ(battle.Current(Side::E).cd[0], lockout);
    RoundResult const second = Round(battle, "A1", "A1");
    Event const* pass = First(second.events, "stunned");
    ASSERT_NE(pass, nullptr);
    EXPECT_TRUE(pass->Flag("pass"));
    EXPECT_EQ(battle.Current(Side::E).cd[0], lockout - 1);
}

TEST(CoAPetBattlesMechanics, DarkRebirthRevivesAtFullHealth)
{
    ConstantRng rng(100);
    Pet reborn = Stunned(MakePet(Strike, "Beast", 1));
    reborn.auras.push_back(AuraOf(795, 99));
    Battle battle(MechanicCatalog(), { reborn }, { MakePet(Strike, "Critter") }, rng);
    RoundResult const result = Round(battle, "A1", "A1");
    bool revived = false;
    for (Event const& event : result.events)
        if (event.kind == "heal" && event.Flag("revive"))
        {
            revived = true;
            EXPECT_EQ(event.Number("amt"), 1000);
            EXPECT_EQ(event.Text("side"), "P");
        }
    EXPECT_TRUE(revived);
    EXPECT_EQ(First(result.events, "faint"), nullptr);
    EXPECT_GT(battle.Current(Side::P).hp, 0);
    EXPECT_FALSE(HasAura(battle.Current(Side::P), 795));
    EXPECT_TRUE(HasAura(battle.Current(Side::P), 796));
}

TEST(CoAPetBattlesMechanics, ReflectiveShieldReturnsHalfTheHit)
{
    ConstantRng rng(100);
    Pet shielded = Stunned(MakePet(Strike, "Critter"));
    shielded.auras.push_back(AuraOf(1104, 3));
    Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") }, { shielded }, rng);
    RoundResult const result = Round(battle, "A1", "A1");
    double const hit = Damage(20, 100, "Beast", "Critter", 0, 0);
    double const reflected = std::floor(hit * 50 / 100);
    bool found = false;
    for (Event const& event : result.events)
        if (event.kind == "dmg" && event.Flag("reflect"))
        {
            found = true;
            EXPECT_EQ(event.Number("dmg"), reflected);
            EXPECT_EQ(event.Text("tside"), "P");
        }
    EXPECT_TRUE(found);
    EXPECT_EQ(battle.Current(Side::P).hp, 1000 - reflected);
    EXPECT_EQ(battle.Current(Side::E).hp, 1000 - hit);
}

TEST(CoAPetBattlesMechanics, BombDetonatesOnTheNextPet)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(Strike, "Beast") },
        { Stunned(MakePet(Strike, "Critter", 1)), MakePet(Strike, "Critter") }, rng);
    Pet& layer = battle.At(Side::P, 1);
    battle.bomb[static_cast<size_t>(Side::E)] = Bomb { 385, 3, &layer, layer.power };
    RoundResult const result = Round(battle, "A1", "A1");
    double const blast = std::floor(std::floor(30 * (1 + layer.power / 20) + 0.5) * Matchup("Mechanical", "Critter"));
    Event const* spawn = First(result.events, "spawn");
    ASSERT_NE(spawn, nullptr);
    bool found = false;
    for (Event const& event : result.events)
        if (event.kind == "dmg" && event.Flag("reflect") && event.Text("tside") == "E" && event.Number("tidx") == 2)
        {
            found = true;
            EXPECT_EQ(event.Number("dmg"), blast);
        }
    EXPECT_TRUE(found);
    EXPECT_EQ(battle.At(Side::E, 2).hp, 1000 - blast);
    EXPECT_FALSE(battle.bomb[static_cast<size_t>(Side::E)].has_value());
}

TEST(CoAPetBattlesMechanics, UnknownPropertyIsCounted)
{
    ConstantRng rng(100);
    Battle battle(MechanicCatalog(), { MakePet(Oddity, "Beast") }, { Stunned(MakePet(Strike, "Critter")) }, rng);
    Round(battle, "A1", "A1");
    ASSERT_EQ(UnknownEffects(battle).count(999), 1u);
    EXPECT_EQ(UnknownEffects(battle).at(999), 1);
}
