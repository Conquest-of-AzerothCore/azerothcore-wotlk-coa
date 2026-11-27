#include "Battle/Battles.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Battle;

namespace
{
    DataSet const& LifecycleData()
    {
        static DataSet const data = Fixtures::LoadData();
        return data;
    }

    std::shared_ptr<Engine::Catalog const> NewCatalog()
    {
        return std::make_shared<Engine::Catalog const>(LifecycleData(), Settings());
    }

    class LiveWorld : public CoAPetBattles::Battle::World
    {
    public:
        LiveWorld(Scheduler& scheduler, Engine::Catalog const& catalog, uint8_t secondLevel = 10)
            : _scheduler(scheduler)
        {
            std::vector<uint32_t> const species = catalog.SpeciesIds();
            std::vector<Store::OwnedPet> pets;
            for (size_t i = 0; i < 3; ++i)
            {
                Store::OwnedPet pet;
                pet.species = species[i];
                pet.id = species[i];
                pet.level = i == 1 ? secondLevel : 10;
                pets.push_back(pet);
            }
            enemy = species[3];
            journal = std::make_unique<Store::Journal>(1, catalog, pets,
                std::array<Store::Team, Store::TeamCount> {}, 1, 0);
        }

        uint32_t enemy = 0;
        bool online = true;
        std::unique_ptr<Store::Journal> journal;
        std::map<uint64_t, uint32_t> live;
        std::vector<std::string> sent;
        uint64_t spawned = 0;
        std::vector<uint32_t> displays;
        std::vector<uint64_t> shownTo;
        std::vector<uint64_t> stale;
        std::vector<uint64_t> cueCharacters;

        void Send(uint64_t, std::string_view module, std::string_view action, std::string const& payload) override
        {
            sent.push_back(std::string(module) + "|" + std::string(action) + "|" + payload);
        }
        bool Online(uint64_t) const override { return online; }
        bool Alive(uint64_t) const override { return true; }
        bool InCombat(uint64_t) const override { return false; }
        bool Gm(uint64_t) const override { return true; }
        uint32_t Account(uint64_t) const override { return 1; }
        void MarkOrigin(uint64_t) override { }
        bool Away(uint64_t) const override { return false; }
        std::optional<Spawned> Spawn(uint64_t, Side, uint32_t species, uint32_t display) override
        {
            displays.push_back(display);
            live[++spawned] = species;
            return Spawned { spawned, display };
        }
        void Scale(uint64_t, double) override { }
        void Despawn(uint64_t handle) override { live.erase(handle); }
        std::vector<uint32_t> Displays(uint32_t) const override { return {}; }
        uint32_t UnixNow() const override { return 1700000000 + static_cast<uint32_t>(_scheduler.Now() / 1000); }
        Store::Journal* JournalOf(uint64_t) override { return online ? journal.get() : nullptr; }
        void Flush(Store::Journal& target) override { target.TakeWrites(); }
        void SyncCompanions(uint64_t) override { }
        void Show(uint64_t handle, uint64_t, Cue const& cue) override
        {
            cueCharacters.push_back(cue.character);
            shownTo.push_back(handle);
            if (!live.count(handle))
                stale.push_back(handle);
        }
        void Prime(uint64_t, uint32_t, uint32_t, uint32_t) override { }
        std::optional<uint32_t> PrimeAll(uint64_t) override { return std::nullopt; }
        std::optional<uint8_t> FoodLevel(uint32_t) override { return std::nullopt; }
        bool HasItem(uint64_t, uint32_t) override { return false; }
        void TakeItem(uint64_t, uint32_t) override { }
        void Summon(uint64_t, uint32_t) override { }
        void Dismiss(uint64_t) override { }
        uint32_t Follower(uint64_t) override { return 0; }
        void Suppress(uint64_t, bool) override { }
        uint32_t SweepStandIns(uint64_t, float) override { return 0; }
        void Refused(uint64_t, std::string const& command) override { refused.push_back(command); }

        std::vector<std::string> refused;

        bool SentStartingWith(std::string const& prefix) const
        {
            return std::any_of(sent.begin(), sent.end(),
                [&prefix](std::string const& line) { return line.rfind(prefix, 0) == 0; });
        }

        bool Sent(std::string const& text) const
        {
            return std::any_of(sent.begin(), sent.end(), [&text](std::string const& line) { return line == text; });
        }

    private:
        Scheduler& _scheduler;
    };

    struct Arena
    {
        explicit Arena(std::shared_ptr<Engine::Catalog const> catalog = NewCatalog(), uint8_t secondLevel = 10)
            : rng(7), world(scheduler, *catalog, secondLevel),
              battles(catalog, LifecycleData(), nullptr, world, scheduler, rng)
        {
        }

        void Start() { battles.Message(7, "pbt", "start", std::to_string(world.enemy) + "@1"); }
        void RunFor(uint64_t ms) { scheduler.RunUntil(scheduler.Now() + ms); }

        Scheduler scheduler;
        Engine::SeededRng rng;
        LiveWorld world;
        Battles battles;
    };
}

TEST(CoAPetBattlesLifecycle, RefusedAbilityAfterASwapGivesTheTurnBack)
{
    Arena arena(NewCatalog(), 1);
    arena.Start();
    arena.RunFor(3000);
    ASSERT_TRUE(arena.world.SentStartingWith("pbt|turn|go;"));
    ASSERT_TRUE(arena.world.SentStartingWith("pbt|st|P,3,1,"));
    arena.world.sent.clear();
    arena.battles.Message(7, "pbt", "cmd", "S3");
    arena.RunFor(15000);
    ASSERT_TRUE(arena.world.SentStartingWith("pbt|turn|go;"));
    arena.world.sent.clear();
    arena.battles.Message(7, "pbt", "cmd", "A3");
    arena.RunFor(100);
    EXPECT_TRUE(arena.world.SentStartingWith("pbt|turn|go;"));
    EXPECT_FALSE(arena.world.SentStartingWith("pbt|act|"));
    arena.battles.Message(7, "pbt", "cmd", "A1");
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.SentStartingWith("pbt|act|P,3,"));
}

TEST(CoAPetBattlesLifecycle, RefusedCommandIsReported)
{
    Arena arena(NewCatalog(), 1);
    arena.Start();
    arena.RunFor(3000);
    arena.battles.Message(7, "pbt", "cmd", "S3");
    arena.RunFor(15000);
    arena.battles.Message(7, "pbt", "cmd", "A3");
    EXPECT_EQ(arena.world.refused, std::vector<std::string> { "A3" });
}

TEST(CoAPetBattlesLifecycle, RestartRightAfterAnEndKeepsTheNewStandIns)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    ASSERT_EQ(arena.world.live.size(), 2u);
    uint64_t const firstBattle = arena.world.spawned;
    arena.battles.Message(7, "pbt", "quit", "");
    arena.RunFor(100);
    arena.Start();
    arena.RunFor(5000);
    ASSERT_EQ(arena.world.live.size(), 2u);
    for (auto const& [handle, species] : arena.world.live)
        EXPECT_GT(handle, firstBattle);
    arena.battles.Message(7, "pbt", "quit", "");
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.live.empty());
}

TEST(CoAPetBattlesLifecycle, ReplacedBattleSpawnsNothingMore)
{
    Arena arena;
    arena.Start();
    arena.RunFor(100);
    arena.Start();
    arena.RunFor(3000);
    EXPECT_EQ(arena.world.live.size(), 2u);
    EXPECT_EQ(arena.world.spawned, 2u);
}

TEST(CoAPetBattlesLifecycle, LogoutRightAfterAnEndRemovesItsStandIns)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    arena.battles.Message(7, "pbt", "quit", "");
    arena.RunFor(100);
    ASSERT_FALSE(arena.world.live.empty());
    arena.battles.Logout(7);
    arena.world.online = false;
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.live.empty());
}

TEST(CoAPetBattlesLifecycle, CatalogReloadKeepsRunningBattlesOnTheirCatalog)
{
    std::shared_ptr<Engine::Catalog const> first = NewCatalog();
    std::weak_ptr<Engine::Catalog const> const watched = first;
    Arena arena(first);
    arena.Start();
    arena.RunFor(3000);
    arena.battles.UseCatalog(NewCatalog());
    first.reset();
    EXPECT_FALSE(watched.expired());
    arena.battles.Message(7, "pbt", "quit", "");
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.live.empty());
    EXPECT_TRUE(watched.expired());
}

TEST(CoAPetBattlesLifecycle, ShutdownCancelsBattlesWithoutPenalty)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    arena.battles.EndAll();
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.live.empty());
    EXPECT_TRUE(arena.world.Sent("pbt|end|interrupted"));
    EXPECT_FALSE(arena.world.Sent("pbt|end|loss"));
    for (Store::OwnedPet const* pet : arena.world.journal->Pets())
        EXPECT_EQ(pet->health, 0u) << pet->species;
    EXPECT_FALSE(arena.battles.InBattle(7));
}

TEST(CoAPetBattlesLifecycle, ShutdownKickCancelsTheBattleWithoutPenalty)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    arena.battles.Abandon(7);
    arena.RunFor(5000);
    EXPECT_TRUE(arena.world.live.empty());
    EXPECT_FALSE(arena.world.Sent("pbt|end|loss"));
    for (Store::OwnedPet const* pet : arena.world.journal->Pets())
        EXPECT_EQ(pet->health, 0u) << pet->species;
    EXPECT_FALSE(arena.battles.InBattle(7));
}

TEST(CoAPetBattlesLifecycle, WildEnemyWearsTheGivenDisplay)
{
    Arena arena;
    EnemySpec enemy;
    enemy.species = arena.world.enemy;
    enemy.display = 4321;
    ASSERT_TRUE(arena.battles.Start(7, std::vector<EnemySpec> { enemy }));
    arena.RunFor(3000);
    EXPECT_NE(std::find(arena.world.displays.begin(), arena.world.displays.end(), 4321u), arena.world.displays.end());
}

TEST(CoAPetBattlesLifecycle, CuesForADespawnedStandInAreDropped)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    ASSERT_FALSE(arena.world.shownTo.empty());
    arena.battles.Message(7, "pbt", "cmd", "A1");
    arena.RunFor(700);
    arena.battles.Message(7, "pbt", "quit", "");
    arena.RunFor(10000);
    EXPECT_TRUE(arena.world.live.empty());
    EXPECT_TRUE(arena.world.stale.empty());
}

TEST(CoAPetBattlesLifecycle, EveryCueNamesItsCharacter)
{
    Arena arena;
    arena.Start();
    arena.RunFor(3000);
    arena.battles.Message(7, "pbt", "cmd", "A1");
    arena.RunFor(6000);
    ASSERT_FALSE(arena.world.cueCharacters.empty());
    for (uint64_t character : arena.world.cueCharacters)
        EXPECT_EQ(character, 7u);
}

TEST(CoAPetBattlesLifecycle, OwnedJournalReleasesOnlyTheConfirmedWildCopy)
{
    Arena arena;
    Store::Journal& journal = *arena.world.journal;
    constexpr std::array<uint8_t, 3> picks = { 1, 1, 1 };
    Store::OwnedPet const* first = journal.Capture(arena.world.enemy, 8, picks, 3, 0);
    Store::OwnedPet const* second = journal.Capture(arena.world.enemy, 8, picks, 3, 0);
    ASSERT_NE(first, nullptr);
    ASSERT_NE(second, nullptr);
    uint32_t const released = first->id;
    uint32_t const kept = second->id;
    std::string const id = std::to_string(released);
    std::string const other = std::to_string(kept);
    arena.battles.Message(7, "pbj", "list2", "");
    EXPECT_TRUE(arena.world.SentStartingWith("pbj|pet2|" + id + ","));
    EXPECT_TRUE(arena.world.SentStartingWith("pbj|pet2|" + other + ","));
    EXPECT_TRUE(arena.world.Sent("pbj|done2|"));
    arena.battles.Message(7, "pbj", "setteam2", "2," + id + "," + other + ",0");
    EXPECT_EQ(journal.TeamAt(2).slots, (std::array<uint32_t, 3> { released, kept, 0 }));
    arena.battles.Message(7, "pbj", "setabil2", other + ",1,2");
    EXPECT_EQ(journal.Pet(kept)->picks[0], 2u);
    EXPECT_EQ(journal.Pet(released)->picks[0], 1u);

    arena.Start();
    ASSERT_TRUE(arena.battles.InBattle(7));
    arena.battles.Message(8, "pbj", "release2", id);
    EXPECT_NE(journal.Pet(released), nullptr);
    EXPECT_TRUE(arena.world.SentStartingWith("pbj|releaseerror2|"));
    arena.battles.Logout(7);

    arena.battles.Message(7, "pbj", "release2", id);
    EXPECT_EQ(journal.Pet(released), nullptr);
    EXPECT_NE(journal.Pet(kept), nullptr);
    EXPECT_EQ(journal.TeamAt(2).slots, (std::array<uint32_t, 3> { 0, kept, 0 }));
    EXPECT_TRUE(arena.world.Sent("pbj|removed2|" + id));
    EXPECT_TRUE(arena.world.Sent("pbj|team2|2,0," + other + ",0"));
}
