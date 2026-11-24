#include "FixtureReader.h"
#include "Wild/Wild.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <map>
#include <sstream>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Wild;

namespace
{
    constexpr uint32_t BaseTime = 1700000000;

    struct Situation
    {
        std::string name;
        std::vector<std::vector<std::string>> setup;
        std::vector<Engine::RecordedRoll> rolls;
        std::vector<std::pair<uint64_t, std::string>> inputs;
        std::vector<std::vector<std::string>> expected;
    };

    struct WildFixture
    {
        std::vector<Situation> situations;
        std::map<uint32_t, std::pair<uint32_t, uint32_t>> templates;
        std::map<uint32_t, std::vector<uint32_t>> displays;
        std::map<uint32_t, std::pair<double, double>> modelInfo;
        DataSet data;
    };

    std::string Format(char const* pattern, double value)
    {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), pattern, value);
        return buffer;
    }

    WildFixture const& Fixture()
    {
        static WildFixture const fixture = []
        {
            WildFixture f;
            f.data = Fixtures::LoadData();
            for (std::string const& line : Fixtures::FixtureLines("battle_world.txt"))
            {
                std::vector<std::string> const v = Fixtures::SplitLine(line);
                uint32_t const id = static_cast<uint32_t>(std::stoul(v[1]));
                if (v[0] == "DISPLAYS")
                    for (size_t i = 2; i < v.size(); ++i)
                        f.displays[id].push_back(static_cast<uint32_t>(std::stoul(v[i])));
                else if (v[0] == "MODELINFO")
                    f.modelInfo[id] = { std::stod(v[2]), std::stod(v[3]) };
                else if (v[0] == "MODELSIZE")
                    f.data.modelSizes[id] = { id, std::stof(v[2]), std::stof(v[3]), std::stof(v[4]) };
                else if (v[0] == "DISPLAYSIZE")
                    f.data.displaySizes[id] = { id, std::stof(v[2]) };
            }
            for (std::string const& line : Fixtures::FixtureLines("wild.txt"))
            {
                std::vector<std::string> const v = Fixtures::SplitLine(line);
                std::string const& tag = v[0];
                if (tag == "ZONE")
                {
                    auto const u8 = [&v](size_t i) { return static_cast<uint8_t>(std::stoul(v[i])); };
                    uint32_t const zone = static_cast<uint32_t>(std::stoul(v[1]));
                    f.data.zones[zone] = { zone, v[2], u8(3), u8(4), u8(5), u8(6) };
                }
                else if (tag == "ZONESPECIES")
                    for (size_t i = 2; i < v.size(); ++i)
                        f.data.zoneSpecies.push_back({ static_cast<uint32_t>(std::stoul(v[1])),
                            static_cast<uint32_t>(std::stoul(v[i])) });
                else if (tag == "TEMPLATE")
                    f.templates[static_cast<uint32_t>(std::stoul(v[1]))] = {
                        static_cast<uint32_t>(std::stoul(v[2])), static_cast<uint32_t>(std::stoul(v[3])) };
                else if (tag == "SITUATION")
                    f.situations.push_back({ v[2], {}, {}, {}, {} });
                else if (tag == "ROLL")
                    f.situations.back().rolls.push_back({ std::stoi(v[1]), std::stoi(v[2]), std::stoi(v[3]) });
                else if (tag == "ROLL_F")
                {
                    Engine::RecordedRoll roll;
                    roll.fraction = true;
                    roll.real = std::stod(v[1]);
                    f.situations.back().rolls.push_back(roll);
                }
                else if (tag == "IN")
                    f.situations.back().inputs.push_back({ std::stoull(v[1]), v[2] });
                else if (tag == "OUT")
                    f.situations.back().expected.push_back(v);
                else
                    f.situations.back().setup.push_back(v);
            }
            return f;
        }();
        return fixture;
    }

    std::shared_ptr<Engine::Catalog const> const& WildCatalog()
    {
        static std::shared_ptr<Engine::Catalog const> const catalog =
            std::make_shared<Engine::Catalog const>(Fixture().data, Settings());
        return catalog;
    }

    Battle::PetScale const& Scale()
    {
        static Battle::PetScale const scale(Fixture().data, [](uint32_t species)
            -> std::optional<std::pair<double, double>>
        {
            auto const found = Fixture().modelInfo.find(species);
            return found == Fixture().modelInfo.end() ? std::nullopt : std::optional(found->second);
        });
        return scale;
    }

    struct Person
    {
        uint32_t map = 0;
        uint32_t zone = 0;
        double x = 0;
        double y = 0;
        double z = 0;
        bool bot = false;
        bool alive = true;
        bool combat = false;
        bool battle = false;
    };

    struct Thing
    {
        uint32_t entry = 0;
        uint32_t map = 0;
        double x = 0;
        double y = 0;
        double z = 0;
        uint32_t level = 0;
        bool db = true;
        bool alive = true;
        bool combat = false;
        bool mob = false;
        size_t order = 0;
    };

    struct Rect
    {
        uint32_t map;
        double x1, y1, x2, y2;
        std::optional<double> z;
    };

    class FakeWorld : public WildWorld
    {
    public:
        uint64_t clock = 0;
        bool startOk = true;
        std::map<uint64_t, Person> people;
        std::map<uint64_t, Thing> things;
        std::map<uint32_t, double> ground;
        std::vector<Rect> rects;
        std::vector<std::string> produced;
        uint64_t lastSpawn = 900000;

        void Out(std::string const& text) { produced.push_back(std::to_string(clock) + " " + text); }

        std::vector<WildPlayer> Players() override
        {
            std::vector<WildPlayer> list;
            for (auto const& [low, p] : people)
                if (!p.bot)
                    list.push_back({ low, p.map, p.zone, p.x, p.y, p.z,
                        p.alive && !p.combat && !p.battle && Fixture().data.zones.count(p.zone) != 0 });
            return list;
        }

        std::vector<RealCreature> RealCreaturesNear(uint64_t character, double range) override
        {
            Person const& p = people.at(character);
            std::vector<std::pair<size_t, RealCreature>> found;
            for (auto const& [guid, t] : things)
            {
                double const d = std::sqrt((t.x - p.x) * (t.x - p.x) + (t.y - p.y) * (t.y - p.y) +
                    (t.z - p.z) * (t.z - p.z));
                if (t.mob && t.alive && t.db && !t.combat && t.map == p.map && d <= range)
                    found.push_back({ t.order, { guid, t.entry, t.x, t.y, t.z, t.level } });
            }
            std::sort(found.begin(), found.end(), [](auto const& a, auto const& b) { return a.first < b.first; });
            std::vector<RealCreature> list;
            for (auto const& entry : found)
                list.push_back(entry.second);
            return list;
        }

        std::optional<double> Ground(uint32_t map, double x, double y) override
        {
            std::optional<double> z;
            if (auto const found = ground.find(map); found != ground.end())
                z = found->second;
            for (Rect const& r : rects)
                if (r.map == map && x >= r.x1 && x <= r.x2 && y >= r.y1 && y <= r.y2)
                    z = r.z;
            return z;
        }

        std::optional<SpawnedPet> Spawn(uint32_t species, Spot at, double facing) override
        {
            uint64_t const key = ++lastSpawn;
            auto const found = Fixture().displays.find(species);
            uint32_t const display = found == Fixture().displays.end() || found->second.empty() ? 0 :
                found->second.front();
            Thing thing;
            thing.entry = species;
            thing.map = at.map;
            thing.x = at.x;
            thing.y = at.y;
            thing.z = at.z;
            things[key] = thing;
            Out("spawn " + std::to_string(key) + " " + std::to_string(species) + " " + Format("%.2f", at.x) + " " +
                Format("%.2f", at.y) + " " + Format("%.2f", at.z) + " " + Format("%.4f", facing));
            return SpawnedPet { key, display };
        }

        void Scale(uint64_t key, double scale) override
        {
            Out("scale " + std::to_string(key) + " " + Format("%.4f", scale));
        }

        void Settle(uint64_t key, Spot at) override
        {
            Out("settle " + std::to_string(key) + " " + Format("%.2f", at.x) + " " + Format("%.2f", at.y) + " " +
                Format("%.2f", at.z));
        }

        void Wander(uint64_t key, double radius) override
        {
            Out("wander " + std::to_string(key) + " " + Format("%.2f", radius));
        }

        std::optional<Spot> Where(uint64_t key) override
        {
            auto const found = things.find(key);
            if (found == things.end())
                return std::nullopt;
            return Spot { found->second.map, found->second.x, found->second.y, found->second.z };
        }

        void Adopt(uint64_t key) override { Out("adopt " + std::to_string(key)); }

        void Release(uint64_t key) override
        {
            auto const found = Fixture().templates.find(things.at(key).entry);
            ASSERT_NE(found, Fixture().templates.end());
            Out("release " + std::to_string(key) + " " + std::to_string(found->second.first) + " " +
                std::to_string(found->second.second));
        }

        void Despawn(uint64_t key) override
        {
            if (things.erase(key))
                Out("despawn " + std::to_string(key));
        }

        void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) override
        {
            Out("send " + std::to_string(character) + " " + std::string(module) + "|" + std::string(action) + "|" +
                payload);
        }

        void Say(uint64_t character, std::string const& text) override
        {
            Out("say " + std::to_string(character) + " " + text);
        }

        bool StartBattle(uint64_t character, std::vector<Battle::EnemySpec> enemies) override
        {
            std::string text = "start " + std::to_string(character);
            for (Battle::EnemySpec const& e : enemies)
                text += " " + std::to_string(e.species) + ":" + std::to_string(static_cast<int>(e.level)) + ":" +
                    Format("%.4f", e.quality) + ":" + std::to_string(e.display);
            Out(text);
            return startOk;
        }

        uint32_t UnixNow() const override { return BaseTime + static_cast<uint32_t>(clock / 1000); }
    };

    std::vector<std::string> Words(std::string const& text)
    {
        std::istringstream stream(text);
        std::vector<std::string> words;
        for (std::string word; stream >> word;)
            words.push_back(word);
        return words;
    }

    void Prepare(FakeWorld& world, Situation const& situation)
    {
        size_t order = 0;
        for (std::vector<std::string> const& v : situation.setup)
        {
            if (v[0] == "GROUND")
                world.ground[static_cast<uint32_t>(std::stoul(v[1]))] = std::stod(v[2]);
            else if (v[0] == "GROUND_RECT")
                world.rects.push_back({ static_cast<uint32_t>(std::stoul(v[1])), std::stod(v[2]), std::stod(v[3]),
                    std::stod(v[4]), std::stod(v[5]), v[6] == "none" ? std::nullopt : std::optional(std::stod(v[6])) });
            else if (v[0] == "PLAYER")
            {
                Person p;
                p.map = static_cast<uint32_t>(std::stoul(v[2]));
                p.zone = static_cast<uint32_t>(std::stoul(v[3]));
                p.x = std::stod(v[4]);
                p.y = std::stod(v[5]);
                p.z = std::stod(v[6]);
                p.bot = v[7] == "bot";
                world.people[std::stoull(v[1])] = p;
            }
            else if (v[0] == "MOB")
            {
                Thing t;
                t.mob = true;
                t.order = ++order;
                t.entry = static_cast<uint32_t>(std::stoul(v[2]));
                t.map = static_cast<uint32_t>(std::stoul(v[3]));
                t.x = std::stod(v[4]);
                t.y = std::stod(v[5]);
                t.z = std::stod(v[6]);
                t.level = static_cast<uint32_t>(std::stoul(v[7]));
                t.db = v[8] == "db";
                t.alive = v[9] == "alive";
                t.combat = v[10] == "combat";
                world.things[std::stoull(v[1])] = t;
            }
        }
    }

    void Apply(FakeWorld& world, Registry& registry, std::string const& input)
    {
        std::vector<std::string> const w = Words(input);
        std::string const& kind = w[0];
        if (kind == "tick")
            registry.Tick();
        else if (kind == "blips")
            registry.Blips();
        else if (kind == "move")
        {
            Person& p = world.people.at(std::stoull(w[1]));
            p.x = std::stod(w[2]);
            p.y = std::stod(w[3]);
            p.z = std::stod(w[4]);
            if (w.size() > 5)
            {
                p.map = static_cast<uint32_t>(std::stoul(w[5]));
                p.zone = static_cast<uint32_t>(std::stoul(w[6]));
            }
        }
        else if (kind == "combat" || kind == "battle" || kind == "alive")
        {
            Person& p = world.people.at(std::stoull(w[1]));
            bool const on = w[2] == "on";
            (kind == "combat" ? p.combat : kind == "battle" ? p.battle : p.alive) = on;
        }
        else if (kind == "start")
            world.startOk = w[1] == "ok";
        else if (kind == "hello")
        {
            uint64_t const key = std::stoull(w[2]);
            if (!world.things.count(key))
                return;
            if (std::optional<std::string> text = registry.Hello(key))
            {
                world.Out("menu " + w[1] + " " + w[2] + " " + *text);
                world.Out("menu " + w[1] + " " + w[2] + " Never mind");
            }
        }
        else if (kind == "select")
        {
            uint64_t const key = std::stoull(w[2]);
            if (!world.things.count(key))
                return;
            Person const& p = world.people.at(std::stoull(w[1]));
            registry.Select(std::stoull(w[1]), key, static_cast<uint32_t>(std::stoul(w[3])), p.x, p.y);
        }
        else if (kind == "vanish")
            world.things.erase(std::stoull(w[1]));
        else if (kind == "wander")
        {
            Thing& t = world.things.at(std::stoull(w[1]));
            t.x = std::stod(w[2]);
            t.y = std::stod(w[3]);
        }
        else if (kind == "shutdown")
            registry.EndAll();
        else
            FAIL() << "unknown input " << input;
    }
}

TEST(CoAPetBattlesWild, EveryRecordedSituationReplays)
{
    ASSERT_EQ(Fixture().situations.size(), 24u);
    for (Situation const& situation : Fixture().situations)
    {
        FakeWorld world;
        Prepare(world, situation);
        Engine::ReplayRng rng(situation.rolls);
        Registry registry(WildCatalog(), Fixture().data, WildSettings(), Scale(), world, rng);
        for (auto const& [time, input] : situation.inputs)
        {
            world.clock = time;
            Apply(world, registry, input);
        }
        std::vector<std::string> expected;
        for (std::vector<std::string> const& v : situation.expected)
            expected.push_back(v[1] + " " + v[2]);
        size_t const common = std::min(expected.size(), world.produced.size());
        size_t first = 0;
        while (first < common && expected[first] == world.produced[first])
            ++first;
        EXPECT_EQ(first, expected.size()) << situation.name << ": first difference at line " << first
            << "\n  recorded: " << (first < expected.size() ? expected[first] : "<end>")
            << "\n  produced: " << (first < world.produced.size() ? world.produced[first] : "<end>")
            << "\n  rng: " << rng.Divergence() << " (used " << rng.Used() << ")";
        EXPECT_EQ(world.produced.size(), expected.size()) << situation.name;
        EXPECT_FALSE(expected.empty()) << situation.name;
        EXPECT_TRUE(rng.Divergence().empty()) << situation.name << ": " << rng.Divergence();
        EXPECT_TRUE(rng.Exhausted()) << situation.name << " used " << rng.Used() << " of " << situation.rolls.size();
        EXPECT_EQ(registry.Count(), 0u) << situation.name;
    }
}
