#include "Battle/Battles.h"
#include "FixtureReader.h"
#include "Follow/Followers.h"
#include "Protocol/AddonMessage.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <set>
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
        std::map<uint32_t, uint8_t> foods;
        std::map<uint64_t, std::map<uint32_t, uint32_t>> items;
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
        row.pet.id = 100000000 + row.pet.species;
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
                    list.push_back({ f[2], {}, {}, {}, {}, {}, {}, {} });
                else if (f[0] == "FOOD")
                    list.back().foods[static_cast<uint32_t>(std::stoul(f[1]))] =
                        static_cast<uint8_t>(std::stoul(f[2]));
                else if (f[0] == "ITEM")
                    list.back().items[Low(f[1])][static_cast<uint32_t>(std::stoul(f[2]))] =
                        static_cast<uint32_t>(std::stoul(f[3]));
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

    class ReplayWorld : public CoAPetBattles::Battle::World, public Follow::FollowerWorld
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

        explicit ReplayWorld(Scheduler& scheduler) : _scheduler(scheduler), followers(*this, scheduler) { }

        std::map<uint64_t, State> players;
        std::map<uint32_t, uint8_t> foods;
        std::map<uint64_t, std::map<uint32_t, uint32_t>> items;
        std::map<uint32_t, std::unique_ptr<Store::Journal>> journals;
        std::vector<std::string> produced;
        std::map<uint64_t, std::string> lastTurn;
        std::set<uint64_t> refusedPending;

        void Refused(uint64_t character, std::string const&) override { refusedPending.insert(character); }

        void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) override
        {
            if (module == "pbt" && action == "turn")
            {
                if (refusedPending.erase(character) && lastTurn[character] == payload)
                    return;
                lastTurn[character] = payload;
            }
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

        void Show(uint64_t, uint64_t, Cue const& cue) override
        {
            static char const* const names[] = { "cast", "effect", "aura", "unaura", "emote", "face", "lunge", "back",
                "jump", "health", "crate", "uncrate" };
            std::string line = "WORLD " + std::to_string(_scheduler.Now()) + " cue " +
                names[static_cast<size_t>(cue.kind)] + " " + Engine::SideName(cue.side) + " " +
                std::to_string(cue.value);
            if (cue.kind == CueKind::Cast)
                line += " " + Engine::SideName(cue.target) + (cue.ranged ? " ranged" : "") + (cue.heal ? " heal" : "");
            produced.push_back(line);
        }

        void Prime(uint64_t, uint32_t entry, uint32_t species, uint32_t display) override
        {
            uint32_t shown = display;
            if (!shown)
            {
                auto const found = WorldData().displays.find(species);
                shown = found == WorldData().displays.end() || found->second.empty() ? 0 : found->second.front();
            }
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " prime " + std::to_string(entry) + " " +
                std::to_string(shown));
        }

        std::optional<uint32_t> PrimeAll(uint64_t character) override
        {
            uint32_t const now = UnixNow();
            auto const last = _primed.find(character);
            if (last != _primed.end() && now - last->second < 5)
                return std::nullopt;
            _primed[character] = now;
            Store::Journal* journal = JournalOf(character);
            uint32_t count = 0;
            for (auto const& [species, row] : Data().species)
            {
                if (!WorldData().displays.count(species))
                    continue;
                ++count;
                Store::OwnedPet const* owned = journal ? journal->PetOfSpecies(species) : nullptr;
                Prime(character, species, species, owned ? owned->display : 0);
            }
            return count;
        }
        std::optional<uint8_t> FoodLevel(uint32_t item) override
        {
            auto const found = foods.find(item);
            return found == foods.end() ? std::nullopt : std::optional<uint8_t>(found->second);
        }
        bool HasItem(uint64_t character, uint32_t item) override { return items[character][item] > 0; }
        void TakeItem(uint64_t character, uint32_t item) override
        {
            --items[character][item];
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " item take " + std::to_string(item));
        }
        void Summon(uint64_t character, uint32_t petId) override { followers.Summon(character, petId); }
        void Dismiss(uint64_t character) override { followers.Dismiss(character); }
        uint32_t Follower(uint64_t character) override
        {
            Store::Journal const* journal = JournalOf(character);
            return journal ? journal->SpeciesForPet(followers.Follower(character)) : 0;
        }
        void Suppress(uint64_t character, bool on) override { followers.Suppress(character, on); }
        uint32_t SweepStandIns(uint64_t, float) override { return 0; }

        bool Wanted(uint64_t character) const override { return players.at(character).alive; }
        bool Owns(uint64_t character, uint32_t petId) const override
        {
            auto const found = journals.find(players.at(character).account);
            return found != journals.end() && found->second->Pet(petId);
        }
        std::optional<uint64_t> SpawnFollower(uint64_t character, uint32_t petId) override
        {
            Store::Journal* journal = JournalOf(character);
            Store::OwnedPet const* pet = journal ? journal->Pet(petId) : nullptr;
            uint32_t const species = pet ? pet->species : 0;
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " follow spawn " +
                std::to_string(species));
            auto const displays = WorldData().displays.find(species);
            if (pet && !pet->display && displays != WorldData().displays.end() && !displays->second.empty() &&
                journal->SetDisplayOnce(petId, displays->second.front()))
                Prime(character, species, species, displays->second.front());
            return ++_followerHandles;
        }
        void DespawnFollower(uint64_t) override
        {
            produced.push_back("WORLD " + std::to_string(_scheduler.Now()) + " follow despawn");
        }
        bool Near(uint64_t, uint64_t) const override { return true; }
        void Pace(uint64_t, uint64_t) override { }
        void SendFollow(uint64_t character, uint32_t petId) override
        {
            Store::Journal const* journal = JournalOf(character);
            Send(character, "pbj", "follow", std::to_string(journal ? journal->SpeciesForPet(petId) : 0));
        }
        void Save(uint64_t character, uint32_t petId) override { _saved[character] = petId; }
        std::optional<uint32_t> Saved(uint64_t character) override
        {
            auto const found = _saved.find(character);
            return found == _saved.end() ? std::nullopt : std::optional<uint32_t>(found->second);
        }

    private:
        Scheduler& _scheduler;

    public:
        Follow::Registry followers;

    private:
        std::map<uint64_t, uint32_t> _primed;
        std::map<uint64_t, uint32_t> _saved;
        uint64_t _followerHandles = 0;
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
        std::stable_sort(rows.begin(), rows.end(), [](JournalRow const& a, JournalRow const& b)
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
        world.foods = session.foods;
        world.items = session.items;
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
                        world.followers.Logout(character);
                        state.online = false;
                    }
                    else if (event == "login")
                    {
                        state.online = true;
                        world.followers.Login(character);
                    }
                    else if (event.rfind("grant ", 0) == 0)
                    {
                        std::istringstream words(event.substr(6));
                        uint32_t species = 0;
                        uint32_t level = 0;
                        words >> species >> level;
                        world.JournalOf(character)->Add(species, static_cast<uint8_t>(level), { 1, 1, 1 }, 1, 0);
                    }
                    else if (event.rfind("sethp ", 0) == 0)
                    {
                        std::istringstream words(event.substr(6));
                        uint32_t species = 0;
                        uint32_t health = 0;
                        words >> species >> health;
                        Store::Journal* journal = world.JournalOf(character);
                        journal->SetHealth(journal->PetIdForSpecies(species), health, world.UnixNow());
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
    size_t recorded = 0;
    std::string first;
    for (SessionFixture const& session : Sessions())
    {
        if (session.name == "capture_replaced" || session.name == "capture_released")
            continue;
        ++recorded;
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
    EXPECT_EQ(recorded + 2, Sessions().size());
    EXPECT_EQ(failed, 0u) << failed << " of " << recorded << " sessions differ; first: " << first;
}

TEST(CoAPetBattlesSessions, DuplicateCapturesRetainBothOwnedPets)
{
    size_t tested = 0;
    for (SessionFixture session : Sessions())
    {
        if (session.name == "capture_replaced")
        {
            std::erase_if(session.records, [](Record const& record)
            {
                return record.time == 21550 && (record.text.starts_with("prime 15668 ") ||
                    record.text.starts_with("p7 pbj|pet|15668,"));
            });
            for (Record& record : session.records)
                if (record.text == "p7 pbt|msg|You captured Grimscale Murloc! It replaces the one you had.")
                    record.text = "p7 pbt|msg|You captured Grimscale Murloc!";
            auto const old = std::find_if(session.journal.begin(), session.journal.end(),
                [](JournalRow const& row) { return row.pet.species == 15668; });
            auto const placed = std::find_if(session.after.begin(), session.after.end(),
                [](JournalRow const& row) { return row.pet.species == 15668; });
            ASSERT_NE(old, session.journal.end());
            ASSERT_NE(placed, session.after.end());
            session.after.insert(placed, *old);
        }
        else if (session.name == "capture_released")
        {
            auto const message = std::find_if(session.records.begin(), session.records.end(), [](Record const& record)
            {
                return record.text ==
                    "p7 pbt|msg|You captured Shadowpine Catlord, but you already own a better one, so it was released.";
            });
            ASSERT_NE(message, session.records.end());
            message->text = "p7 pbt|msg|You captured Shadowpine Catlord!";
            session.records.insert(std::next(message), { "OUT", 78000, "p7 pbt|got|1,Shadowpine Catlord" });
            session.rolls.insert(session.rolls.end(), { { 1, 2, 1 }, { 1, 2, 2 }, { 1, 2, 1 } });
            JournalRow caught;
            caught.low = 7;
            caught.pet.species = 16345;
            caught.pet.level = 8;
            caught.pet.quality = 1;
            caught.pet.display = 592;
            caught.pet.picks = { 1, 2, 1 };
            session.after.push_back(caught);
        }
        else
            continue;
        ++tested;
        Outcome const outcome = Replay(session);
        EXPECT_TRUE(outcome.failure.empty()) << outcome.failure;
    }
    EXPECT_EQ(tested, 2u);
}
