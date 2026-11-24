#include "Battle/Battles.h"
#include "FixtureReader.h"
#include "Protocol/AddonMessage.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <sstream>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Battle;

namespace
{
    constexpr uint32_t BaseTime = 1700000000;

    struct Record
    {
        std::string kind;
        uint64_t time = 0;
        std::string text;
    };

    struct PlayerRow
    {
        uint64_t low = 0;
        uint32_t account = 0;
        int32_t rank = 0;
        bool bot = false;
    };

    struct JournalRow
    {
        uint64_t low = 0;
        Store::OwnedPet pet;
    };

    struct SessionFixture
    {
        std::string name;
        std::vector<PlayerRow> players;
        std::vector<JournalRow> journal;
        std::vector<JournalRow> after;
        std::vector<Engine::RecordedRoll> rolls;
        std::vector<Record> records;
    };

    struct WorldFixture
    {
        std::map<uint32_t, std::vector<uint32_t>> displays;
        std::map<uint32_t, std::pair<double, double>> modelInfo;
    };

    uint64_t Low(std::string const& player)
    {
        return std::stoull(player.substr(1));
    }

    JournalRow ReadJournal(std::vector<std::string> const& f)
    {
        JournalRow row;
        row.low = Low(f[1]);
        row.pet.species = static_cast<uint32_t>(std::stoul(f[2]));
        row.pet.level = static_cast<uint8_t>(std::stoul(f[3]));
        row.pet.xp = static_cast<uint32_t>(std::stoul(f[4]));
        row.pet.picks = { static_cast<uint8_t>(std::stoul(f[5])), static_cast<uint8_t>(std::stoul(f[6])),
            static_cast<uint8_t>(std::stoul(f[7])) };
        row.pet.quality = static_cast<uint8_t>(std::stoul(f[8]));
        row.pet.display = static_cast<uint32_t>(std::stoul(f[9]));
        row.pet.health = static_cast<uint32_t>(std::stoul(f[10]));
        row.pet.healthAt = static_cast<uint32_t>(std::stoul(f[11]));
        return row;
    }

    std::vector<SessionFixture> const& Sessions()
    {
        static std::vector<SessionFixture> const sessions = []
        {
            std::vector<SessionFixture> list;
            for (std::string const& line : Fixtures::FixtureLines("sessions.txt"))
            {
                std::vector<std::string> const f = Fixtures::SplitLine(line);
                if (f[0] == "SESSION")
                    list.push_back({ f[2], {}, {}, {}, {}, {} });
                else if (f[0] == "PLAYER")
                    list.back().players.push_back({ Low(f[1]), static_cast<uint32_t>(std::stoul(f[2])),
                        std::stoi(f[3]), f[4] == "1" });
                else if (f[0] == "JOURNAL")
                    list.back().journal.push_back(ReadJournal(f));
                else if (f[0] == "JOURNAL_AFTER")
                    list.back().after.push_back(ReadJournal(f));
                else if (f[0] == "ROLL")
                    list.back().rolls.push_back({ std::stoi(f[1]), std::stoi(f[2]), std::stoi(f[3]) });
                else if (f[0] == "ROLL_F")
                {
                    Engine::RecordedRoll roll;
                    roll.fraction = true;
                    roll.real = std::stod(f[1]);
                    list.back().rolls.push_back(roll);
                }
                else if (f[0] == "IN" || f[0] == "OUT" || f[0] == "WORLD")
                    list.back().records.push_back({ f[0], std::stoull(f[1]), f[2] });
            }
            return list;
        }();
        return sessions;
    }

    WorldFixture const& WorldData()
    {
        static WorldFixture const world = []
        {
            WorldFixture fixture;
            for (std::string const& line : Fixtures::FixtureLines("battle_world.txt"))
            {
                std::vector<std::string> const f = Fixtures::SplitLine(line);
                if (f[0] == "DISPLAYS")
                    for (size_t i = 2; i < f.size(); ++i)
                        fixture.displays[static_cast<uint32_t>(std::stoul(f[1]))].push_back(
                            static_cast<uint32_t>(std::stoul(f[i])));
                else if (f[0] == "MODELINFO")
                    fixture.modelInfo[static_cast<uint32_t>(std::stoul(f[1]))] = { std::stod(f[2]), std::stod(f[3]) };
            }
            return fixture;
        }();
        return world;
    }

    DataSet const& Data()
    {
        static DataSet const data = []
        {
            DataSet d = Fixtures::LoadData();
            for (std::string const& line : Fixtures::FixtureLines("battle_world.txt"))
            {
                std::vector<std::string> const f = Fixtures::SplitLine(line);
                if (f[0] == "MODELSIZE")
                    d.modelSizes[static_cast<uint32_t>(std::stoul(f[1]))] = { static_cast<uint32_t>(std::stoul(f[1])),
                        std::stof(f[2]), std::stof(f[3]), std::stof(f[4]) };
                else if (f[0] == "DISPLAYSIZE")
                    d.displaySizes[static_cast<uint32_t>(std::stoul(f[1]))] = { static_cast<uint32_t>(std::stoul(f[1])),
                        std::stof(f[2]) };
            }
            return d;
        }();
        return data;
    }

    std::shared_ptr<Engine::Catalog const> const& ReplayCatalog()
    {
        static std::shared_ptr<Engine::Catalog const> const catalog =
            std::make_shared<Engine::Catalog const>(Data(), Settings());
        return catalog;
    }

    class ReplayWorld : public CoAPetBattles::Battle::World
    {
    public:
        struct State
        {
            uint32_t account = 0;
            bool gm = false;
            bool bot = false;
            bool online = true;
            bool alive = true;
            bool combat = false;
            bool away = false;
        };

        explicit ReplayWorld(Scheduler& scheduler) : _scheduler(scheduler) { }

        std::map<uint64_t, State> players;
        std::map<uint32_t, std::unique_ptr<Store::Journal>> journals;
        std::vector<std::string> produced;

        void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) override
        {
            produced.push_back("OUT " + std::to_string(_scheduler.Now()) + " p" + std::to_string(character) + " " +
                std::string(module) + "|" + std::string(action) + "|" + payload);
        }
        bool Online(uint64_t character) const override { return players.at(character).online; }
        bool Alive(uint64_t character) const override { return players.at(character).alive; }
        bool InCombat(uint64_t character) const override { return players.at(character).combat; }
        bool Gm(uint64_t character) const override { return players.at(character).gm; }
        uint32_t Account(uint64_t character) const override { return players.at(character).account; }
        void MarkOrigin(uint64_t) override { }
        bool Away(uint64_t character) const override { return players.at(character).away; }
        std::optional<Spawned> Spawn(uint64_t, Side, uint32_t species, uint32_t display) override
        {
            _spawned[++_handles] = species;
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " spawn " + std::to_string(species));
            if (display)
                return Spawned { _handles, display };
            auto const found = WorldData().displays.find(species);
            return Spawned { _handles, found == WorldData().displays.end() || found->second.empty() ? 0u :
                found->second.front() };
        }
        void Scale(uint64_t, double) override { }
        void Despawn(uint64_t handle) override
        {
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " despawn " +
                std::to_string(_spawned.at(handle)));
            _spawned.erase(handle);
        }
        std::vector<uint32_t> Displays(uint32_t species) const override
        {
            auto const found = WorldData().displays.find(species);
            return found == WorldData().displays.end() ? std::vector<uint32_t>() : found->second;
        }
        uint32_t UnixNow() const override { return BaseTime + static_cast<uint32_t>(_scheduler.Now() / 1000); }
        Store::Journal* JournalOf(uint64_t character) override
        {
            auto const found = journals.find(players.at(character).account);
            return found == journals.end() ? nullptr : found->second.get();
        }
        void Flush(Store::Journal& journal) override { journal.TakeWrites(); }
        void SyncCompanions(uint64_t) override { }

    private:
        Scheduler& _scheduler;
        std::map<uint64_t, uint32_t> _spawned;
        uint64_t _handles = 0;
    };

    std::string Expected(Record const& record)
    {
        return record.kind + " " + std::to_string(record.time) + " " + record.text;
    }

    std::vector<std::string> SortPetRuns(std::vector<std::string> lines)
    {
        size_t i = 0;
        while (i < lines.size())
        {
            if (lines[i].find(" pbj|pet|") == std::string::npos)
            {
                ++i;
                continue;
            }
            size_t j = i;
            std::string const time = lines[i].substr(0, lines[i].find(' ', 4));
            while (j < lines.size() && lines[j].find(" pbj|pet|") != std::string::npos &&
                lines[j].substr(0, lines[j].find(' ', 4)) == time)
                ++j;
            std::sort(lines.begin() + static_cast<std::ptrdiff_t>(i), lines.begin() + static_cast<std::ptrdiff_t>(j));
            i = j;
        }
        return lines;
    }

    std::string JournalText(Store::Journal const& journal)
    {
        std::ostringstream text;
        for (Store::OwnedPet const* pet : journal.Pets())
            text << pet->species << " L" << int(pet->level) << " xp" << pet->xp << " picks" << int(pet->picks[0])
                 << int(pet->picks[1]) << int(pet->picks[2]) << " q" << int(pet->quality) << " d" << pet->display
                 << " hp" << pet->health << "@" << pet->healthAt << "\n";
        return text.str();
    }

    std::string ExpectedJournal(std::vector<JournalRow> rows)
    {
        std::sort(rows.begin(), rows.end(), [](JournalRow const& a, JournalRow const& b)
        {
            return a.pet.species < b.pet.species;
        });
        std::ostringstream text;
        for (JournalRow const& row : rows)
            text << row.pet.species << " L" << int(row.pet.level) << " xp" << row.pet.xp << " picks"
                 << int(row.pet.picks[0]) << int(row.pet.picks[1]) << int(row.pet.picks[2]) << " q"
                 << int(row.pet.quality) << " d" << row.pet.display << " hp" << row.pet.health << "@"
                 << row.pet.healthAt << "\n";
        return text.str();
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

    struct Outcome
    {
        std::string failure;
        size_t inputs = 0;
    };

    Outcome Replay(SessionFixture const& session)
    {
        Outcome outcome;
        Scheduler scheduler;
        ReplayWorld world(scheduler);
        Engine::ReplayRng rng(session.rolls);
        std::map<uint32_t, std::vector<Store::OwnedPet>> owned;
        for (PlayerRow const& player : session.players)
        {
            world.players[player.low] = { player.account, player.rank >= 2, player.bot };
            owned[player.account];
        }
        for (JournalRow const& row : session.journal)
            owned[world.players.at(row.low).account].push_back(row.pet);
        for (auto& [account, pets] : owned)
            world.journals[account] = std::make_unique<Store::Journal>(account, *ReplayCatalog(), pets,
                std::array<Store::Team, Store::TeamCount> {}, 1, 0);
        Battles battles(ReplayCatalog(), Data(), [](uint32_t species) -> std::optional<std::pair<double, double>>
        {
            auto const found = WorldData().modelInfo.find(species);
            return found == WorldData().modelInfo.end() ? std::nullopt : std::optional(found->second);
        }, world, scheduler, rng);
        scheduler.Every(5000, [&battles] { battles.Watchdog(); });

        std::vector<std::string> expected;
        std::vector<std::pair<size_t, Record>> inputs;
        for (Record const& record : session.records)
        {
            if (record.kind == "IN")
                inputs.push_back({ expected.size(), record });
            else
                expected.push_back(Expected(record));
        }
        uint64_t const lastTime = session.records.empty() ? 0 : session.records.back().time;
        size_t next = 0;
        for (size_t guard = 0; guard < 2000000; ++guard)
        {
            if (next < inputs.size() && world.produced.size() >= inputs[next].first)
            {
                if (world.produced.size() > inputs[next].first)
                    break;
                Record const& input = inputs[next].second;
                while (scheduler.NextDue() && *scheduler.NextDue() < input.time)
                    scheduler.Step();
                if (world.produced.size() != inputs[next].first)
                    break;
                scheduler.SetNow(input.time);
                size_t const space = input.text.find(' ');
                uint64_t const character = Low(input.text.substr(0, space));
                std::string const text = input.text.substr(space + 1);
                ++next;
                ++outcome.inputs;
                ReplayWorld::State& state = world.players.at(character);
                if (text.rfind("event ", 0) == 0)
                {
                    std::string const event = text.substr(6);
                    if (event == "combat 1")
                        state.combat = true;
                    else if (event == "dead")
                        state.alive = false;
                    else if (event.rfind("move ", 0) == 0 || event.rfind("map ", 0) == 0)
                        state.away = true;
                    else if (event == "logout")
                    {
                        battles.Logout(character);
                        state.online = false;
                    }
                    continue;
                }
                if (state.bot || !state.online)
                    continue;
                std::optional<Protocol::AddonMessage> const message = Protocol::ParseAddonMessage(text);
                if (message)
                    battles.Message(character, message->module, message->action, message->payload);
                continue;
            }
            if (next >= inputs.size() && scheduler.PendingOnce() == 0 && world.produced.size() >= expected.size())
                break;
            if (scheduler.Now() > lastTime + 3600000 || !scheduler.Step())
                break;
        }
        if (!rng.Divergence().empty())
        {
            outcome.failure = session.name + ": " + rng.Divergence();
            return outcome;
        }
        if (std::string diff = FirstDifference(SortPetRuns(expected), SortPetRuns(world.produced)); !diff.empty())
        {
            outcome.failure = session.name + " " + diff;
            return outcome;
        }
        if (next != inputs.size())
        {
            outcome.failure = session.name + ": only " + std::to_string(next) + " of " +
                std::to_string(inputs.size()) + " inputs were reached";
            return outcome;
        }
        std::map<uint32_t, std::vector<JournalRow>> after;
        for (JournalRow const& row : session.after)
            after[world.players.at(row.low).account].push_back(row);
        for (auto const& [account, journal] : world.journals)
        {
            std::string const want = ExpectedJournal(after[account]);
            std::string const got = JournalText(*journal);
            if (want != got)
            {
                outcome.failure = session.name + " journal of account " + std::to_string(account) + "\n expected:\n" +
                    want + " actual:\n" + got;
                return outcome;
            }
        }
        if (!rng.Exhausted())
            outcome.failure = session.name + ": " + std::to_string(session.rolls.size() - rng.Used()) +
                " recorded rolls never used";
        return outcome;
    }
}

TEST(CoAPetBattlesSessions, EveryRecordedSessionReplays)
{
    size_t failed = 0;
    size_t inputs = 0;
    std::string first;
    for (SessionFixture const& session : Sessions())
    {
        Outcome const outcome = Replay(session);
        inputs += outcome.inputs;
        if (!outcome.failure.empty())
        {
            ++failed;
            if (first.empty())
                first = outcome.failure;
        }
    }
    EXPECT_GT(Sessions().size(), 30u);
    EXPECT_GT(inputs, 0u);
    EXPECT_EQ(failed, 0u) << failed << " of " << Sessions().size() << " sessions differ; first: " << first;
}
