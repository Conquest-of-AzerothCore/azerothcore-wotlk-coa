#include "Follow/Followers.h"
#include <gtest/gtest.h>
#include <map>

using namespace CoAPetBattles;

namespace
{
    class FakeFollowerWorld : public Follow::FollowerWorld
    {
    public:
        bool online = true;
        std::map<uint64_t, uint32_t> live;
        uint64_t spawned = 0;

        bool Online(uint64_t) const override { return online; }
        bool Wanted(uint64_t) const override { return true; }
        bool Owns(uint64_t, uint32_t) const override { return true; }
        std::optional<uint64_t> SpawnFollower(uint64_t, uint32_t species) override
        {
            live[++spawned] = species;
            return spawned;
        }
        void DespawnFollower(uint64_t handle) override { live.erase(handle); }
        bool Near(uint64_t, uint64_t handle) const override { return live.count(handle) != 0; }
        void Pace(uint64_t, uint64_t) override { }
        void SendFollow(uint64_t, uint32_t) override { }
        void Save(uint64_t, uint32_t) override { }
        std::optional<uint32_t> Saved(uint64_t) override { return std::nullopt; }
    };
}

TEST(CoAPetBattlesFollowers, ALoadingScreenHidesTheFollowerWithoutDroppingIt)
{
    FakeFollowerWorld world;
    Battle::Scheduler scheduler;
    Follow::Registry followers(world, scheduler);
    followers.Summon(7, 69);
    scheduler.RunUntil(300);
    ASSERT_EQ(world.live.size(), 1u);
    world.online = false;
    scheduler.RunUntil(2100);
    EXPECT_TRUE(world.live.empty());
    EXPECT_EQ(followers.Follower(7), 69u);
    world.online = true;
    scheduler.RunUntil(4100);
    EXPECT_EQ(world.live.size(), 1u);
    EXPECT_TRUE(followers.Out(7));
}

TEST(CoAPetBattlesFollowers, OnlyLogoutDropsTheFollower)
{
    FakeFollowerWorld world;
    Battle::Scheduler scheduler;
    Follow::Registry followers(world, scheduler);
    followers.Summon(7, 69);
    scheduler.RunUntil(300);
    followers.Logout(7);
    EXPECT_TRUE(world.live.empty());
    EXPECT_EQ(followers.Follower(7), 0u);
}
