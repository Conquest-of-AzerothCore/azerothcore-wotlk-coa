#include "Engine/LuaNumber.h"
#include "Engine/PetFactory.h"
#include "Engine/Round.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <map>
#include <sstream>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    Catalog const& ReplayCatalog()
    {
        static DataSet const data = Fixtures::LoadData();
        static Catalog const catalog(data, Settings());
        return catalog;
    }

    std::vector<std::string> StateRow(Battle const& battle, Side side, int32_t index)
    {
        Pet const& pet = battle.At(side, index);
        std::vector<std::string> auras;
        for (Aura const& aura : pet.auras)
            auras.push_back(LuaNumber(static_cast<double>(aura.id)) + ":" + LuaNumber(aura.left));
        std::sort(auras.begin(), auras.end());
        std::string auraText;
        for (std::string const& aura : auras)
            auraText += (auraText.empty() ? "" : ",") + aura;
        return { SideName(side), LuaNumber(index), LuaNumber(pet.hp), LuaNumber(pet.max), LuaNumber(pet.power),
            LuaNumber(Speed(nullptr, pet)), LuaNumber(pet.cd[0]) + "," + LuaNumber(pet.cd[1]) + "," +
            LuaNumber(pet.cd[2]), auraText, StatusString(ReplayCatalog(), pet) };
    }

    bool ContainsText(std::string const& text, std::string const& part)
    {
        return text.find(part) != std::string::npos;
    }

    PetAbility LibraryAbility(uint32_t id)
    {
        AbilityDef const& def = *ReplayCatalog().Ability(id);
        PetAbility ability;
        ability.id = id;
        ability.name = def.name;
        ability.retailName = def.name;
        ability.text = def.text;
        ability.family = def.family;
        ability.cooldown = def.cooldown;
        for (Turn const& turn : def.turns)
            (turn.event == 255 ? ability.turns : ability.procs).push_back(turn);
        if (ability.turns.empty())
        {
            ability.turns = def.turns;
            ability.procs.clear();
        }
        ability.priority = ContainsText(def.text, "always goes first");
        for (Turn const& turn : ability.procs)
            for (Fx const& fx : turn.fx)
                if (fx.prop == 79 || fx.prop == 145 || fx.prop == 107)
                    ability.priority = true;
        return ability;
    }

    std::string Join(std::vector<std::string> const& fields)
    {
        std::string text;
        for (std::string const& field : fields)
            text += (text.empty() ? "" : "\t") + field;
        return text;
    }

    std::string FirstDifference(std::vector<std::string> const& expected, std::vector<std::string> const& actual)
    {
        for (size_t i = 0; i < std::max(expected.size(), actual.size()); ++i)
        {
            std::string const want = i < expected.size() ? expected[i] : "<none>";
            std::string const got = i < actual.size() ? actual[i] : "<none>";
            if (want != got)
                return "line " + std::to_string(i) + "\n expected: " + want + "\n actual:   " + got;
        }
        return "";
    }

    struct ReplayOutcome
    {
        std::string failure;
        size_t rounds = 0;
        size_t invalidCommands = 0;
    };

    ReplayOutcome Replay(Fixtures::TraceBattle const& trace)
    {
        ReplayOutcome outcome;
        ReplayRng rng(trace.rolls);
        std::vector<Pet> mine;
        std::vector<Pet> theirs;
        for (Fixtures::TracePet const& recorded : trace.pets)
        {
            double const quality = RollQuality(ReplayCatalog(), rng);
            Pet pet = NewPet(ReplayCatalog(), recorded.species, recorded.level, recorded.picks, rng, quality,
                recorded.hp);
            for (auto const& [slot, ability] : recorded.library)
                pet.abil[static_cast<size_t>(slot) - 1] = LibraryAbility(ability);
            (recorded.side == "P" ? mine : theirs).push_back(std::move(pet));
        }
        if (!rng.Divergence().empty())
        {
            outcome.failure = "battle " + std::to_string(trace.id) + " pets: " + rng.Divergence();
            return outcome;
        }
        Battle battle(ReplayCatalog(), std::move(mine), std::move(theirs), rng);
        if (trace.weather)
            battle.weather = Weather { trace.weather->first, trace.weather->second };
        for (size_t r = 0; r < trace.rounds.size(); ++r)
        {
            Fixtures::TraceRound const& round = trace.rounds[r];
            std::string const where = "battle " + std::to_string(trace.id) + " round " + std::to_string(r + 1);
            Pet const& active = battle.Current(Side::P);
            char const kind = round.commandP.empty() ? ' ' : round.commandP[0];
            if ((kind == 'T' && !CanTrap(battle)) ||
                (kind == 'A' && !active.channel && !Ready(active, std::stoi(round.commandP.substr(1)))))
                ++outcome.invalidCommands;
            std::string const enemy = AI(battle, Side::E);
            if (enemy != round.commandE)
            {
                outcome.failure = where + ": AI chose " + enemy + ", upstream " + round.commandE;
                return outcome;
            }
            RoundResult const result = Round(battle, round.commandP, enemy);
            if (!rng.Divergence().empty())
            {
                outcome.failure = where + ": " + rng.Divergence();
                return outcome;
            }
            std::vector<std::string> events;
            for (Event const& event : result.events)
                events.push_back(event.Canonical());
            if (std::string diff = FirstDifference(round.events, events); !diff.empty())
            {
                outcome.failure = where + " events: " + diff;
                return outcome;
            }
            if (result.status != round.status)
            {
                outcome.failure = where + ": status " + result.status + ", upstream " + round.status;
                return outcome;
            }
            std::vector<std::string> expectedStates;
            std::vector<std::string> actualStates;
            for (std::vector<std::string> const& state : round.states)
            {
                expectedStates.push_back(Join(state));
                Side const side = state[0] == "P" ? Side::P : Side::E;
                actualStates.push_back(Join(StateRow(battle, side, std::stoi(state[1]))));
            }
            if (std::string diff = FirstDifference(expectedStates, actualStates); !diff.empty())
            {
                outcome.failure = where + " state: " + diff;
                return outcome;
            }
            ++outcome.rounds;
        }
        if (!rng.Exhausted())
            outcome.failure = "battle " + std::to_string(trace.id) + ": " +
                std::to_string(trace.rolls.size() - rng.Used()) + " recorded rolls never used";
        else if (!UnknownEffects(battle).empty())
            outcome.failure = "battle " + std::to_string(trace.id) + ": unknown effect handler fired";
        return outcome;
    }
}

TEST(CoAPetBattlesEngine, EveryRecordedBattleReplays)
{
    std::vector<Fixtures::TraceBattle> const battles = Fixtures::LoadTraces();
    size_t rounds = 0;
    size_t failed = 0;
    std::string firstFailure;
    for (Fixtures::TraceBattle const& trace : battles)
    {
        ReplayOutcome const outcome = Replay(trace);
        rounds += outcome.rounds;
        if (!outcome.failure.empty())
        {
            ++failed;
            if (firstFailure.empty())
                firstFailure = outcome.failure;
        }
    }
    EXPECT_EQ(failed, 0u) << failed << " of " << battles.size() << " battles differ; first: " << firstFailure;
    EXPECT_GT(rounds, 0u);
}

TEST(CoAPetBattlesEngine, LibraryOnlyBranchesReplay)
{
    std::map<uint32_t, size_t> battlesWith;
    size_t weathered = 0;
    for (Fixtures::TraceBattle const& trace : Fixtures::LoadTraces())
    {
        bool library = false;
        for (Fixtures::TracePet const& pet : trace.pets)
            for (auto const& [slot, ability] : pet.library)
            {
                ++battlesWith[ability];
                library = true;
            }
        if (!library)
            continue;
        weathered += trace.weather ? 1 : 0;
        ReplayOutcome const outcome = Replay(trace);
        EXPECT_TRUE(outcome.failure.empty()) << outcome.failure;
        EXPECT_GT(outcome.rounds, 0u) << "battle " << trace.id;
    }
    EXPECT_GE(battlesWith[190], 2u);
    EXPECT_GE(battlesWith[2102], 2u);
    EXPECT_GE(battlesWith[268], 2u);
    EXPECT_GE(weathered, 2u);
}

TEST(CoAPetBattlesEngine, WrongRollRangeIsReportedAsDivergence)
{
    Fixtures::TraceBattle trace = Fixtures::LoadTraces().front();
    ReplayRng building(trace.rolls);
    for (Fixtures::TracePet const& recorded : trace.pets)
        NewPet(ReplayCatalog(), recorded.species, recorded.level, recorded.picks, building,
            RollQuality(ReplayCatalog(), building), recorded.hp);
    size_t const firstRoundRoll = building.Used();
    ASSERT_LT(firstRoundRoll, trace.rolls.size());

    Fixtures::TraceBattle duringPets = trace;
    duringPets.rolls[0].hi += 1;
    EXPECT_NE(Replay(duringPets).failure.find("roll 0: recorded"), std::string::npos) << Replay(duringPets).failure;

    Fixtures::TraceBattle duringRound = trace;
    duringRound.rolls[firstRoundRoll].hi += 1;
    std::string const failure = Replay(duringRound).failure;
    EXPECT_NE(failure.find("roll " + std::to_string(firstRoundRoll) + ": recorded"), std::string::npos) << failure;
}

TEST(CoAPetBattlesEngine, InvalidCommandsMatchUpstream)
{
    size_t invalid = 0;
    for (Fixtures::TraceBattle const& trace : Fixtures::LoadTraces())
    {
        ReplayOutcome const outcome = Replay(trace);
        ASSERT_TRUE(outcome.failure.empty()) << outcome.failure;
        invalid += outcome.invalidCommands;
    }
    EXPECT_GT(invalid, 0u);
}
