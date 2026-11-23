#include "AscensionGuardianTravelPolicy.h"
#include <iostream>

namespace
{
int failures = 0;

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        ++failures;
    }
}

GuardianTravel::Candidate Walking(std::uint32_t entry, std::uint32_t properties)
{
    GuardianTravel::Candidate guardian;
    guardian.Entry = entry;
    guardian.Properties = properties;
    guardian.Alive = true;
    guardian.Owned = true;
    guardian.Type = GuardianTravel::TypeTimed;
    guardian.RemainingMs = 45000;
    guardian.Walks = true;
    return guardian;
}
}

int main()
{
    using namespace GuardianTravel;

    Candidate wolf = Walking(29264, 1161);
    Expect(Travels(wolf), "a walking timed guardian with time left travels");
    wolf.RemainingMs = MinimumRemainingMs - 1;
    Expect(!Travels(wolf), "a guardian about to expire stays");
    wolf.RemainingMs = MinimumRemainingMs;
    Expect(Travels(wolf), "a guardian with the minimum time left travels");
    wolf.Walks = false;
    Expect(!Travels(wolf), "a guardian that is not walking with its owner stays");

    Candidate skeleton = Walking(50065, 61);
    skeleton.Necromancer = true;
    skeleton.Walks = false;
    skeleton.Type = TypeDead;
    skeleton.RemainingMs = 0;
    Expect(Travels(skeleton), "a Necromancer minion travels without the walking test");
    skeleton.Properties = 64;
    Expect(!Travels(skeleton), "a Necromancer kind of another summon row stays");
    skeleton.Properties = 61;
    for (std::uint32_t kind : ExplodingNecromancerKinds)
    {
        skeleton.Entry = kind;
        Expect(!Travels(skeleton), "an exploding Necromancer kind stays");
    }
    skeleton.Entry = 50065;
    skeleton.Follows = false;
    Expect(!Travels(skeleton), "a Necromancer kind that does not follow its owner stays");
    skeleton.Follows = true;

    Candidate other = Walking(1000, 0);
    Expect(!Travels(other), "a summon without a summon row stays");

    Candidate gone = Walking(29264, 1161);
    gone.Type = TypeDespawned;
    Expect(!Travels(gone), "a despawned summon is never carried");
    gone.Type = 0;
    Expect(!Travels(gone), "a summon of unknown type is never carried");
    gone.Type = TypeTimed;
    gone.Leaving = true;
    Expect(!Travels(gone), "a summon being removed is never carried");
    gone.Leaving = false;
    gone.Alive = false;
    Expect(!Travels(gone), "a dead summon is never carried");
    gone.Alive = true;
    gone.Owned = false;
    Expect(!Travels(gone), "a charmed or foreign summon is never carried");
    gone.Owned = true;
    gone.Hidden = true;
    Expect(!Travels(gone), "a stowed taxi guardian is never carried");

    for (std::uint32_t type : {TypeTimedOrDead, TypeTimedOrCorpse, TypeTimed, TypeTimedOutOfCombat,
                               TypeTimedOutOfCombatAlive})
        Expect(TimerOf(type) == Timer::Countdown, "countdown kinds carry the time left");
    Expect(TimerOf(TypeCorpseTimed) == Timer::Delay, "the corpse delay is not time left");
    Expect(TimerOf(TypeDead) == Timer::None && TimerOf(8) == Timer::None, "untimed kinds have no timer");

    Expect(CopyType(TypeDespawned, 5000) == TypeTimed, "a copy is never despawned, with time it is timed");
    Expect(CopyType(TypeDespawned, 0) == TypeDead, "a copy is never despawned, without time it lasts until it dies");
    Expect(CopyType(TypeTimedOutOfCombat, 0) == TypeDead, "a timer kind without time falls back to dead");
    Expect(CopyType(TypeTimedOutOfCombat, 8000) == TypeTimedOutOfCombat, "a timer kind with time is kept");
    Expect(CopyType(TypeDead, 0) == TypeDead, "an untimed kind is kept");
    Expect(CopyType(42, 0) == TypeDead, "an unknown kind is not copied as is");

    Expect(!CarryFor(false, FarTeleport, false), "a hop of exactly 100 yards carries nothing");
    Expect(CarryFor(false, FarTeleport + 1.0f, false), "a far teleport on the same map carries");
    Expect(CarryFor(true, 0.0f, false), "a map change carries");
    Expect(!CarryFor(true, 5000.0f, true), "a battleground or arena carries nothing");

    Expect(Check(false, false, true, 0.0f, 0) == Arrival::Wait, "not in the world yet: wait");
    Expect(Check(true, true, true, 0.0f, 0) == Arrival::Wait, "still teleporting: wait");
    Expect(Check(false, false, true, 0.0f, ArrivalWaitMs + 1) == Arrival::Drop, "waited too long: drop");
    Expect(Check(true, false, false, 0.0f, 0) == Arrival::Drop, "landed on another map: drop");
    Expect(Check(true, false, true, ArrivalRadius + 1.0f, 0) == Arrival::Drop, "landed elsewhere: drop");
    Expect(Check(true, false, true, ArrivalRadius, 0) == Arrival::Restore, "landed at the destination: restore");

    Expect(Plan(true, false, 0.0f, true) == Step::Recreate, "a new map or instance makes the guardian again");
    Expect(Plan(true, true, 0.0f, false) == Step::Skip, "where the spell cannot be cast, nothing arrives");
    Expect(Plan(false, true, NearEnough + 1.0f, false) == Step::Move,
        "a present guardian on the same map is moved even where its spell cannot be cast");
    Expect(Plan(false, true, 0.0f, false) == Step::Keep, "a near guardian stays even where its spell cannot be cast");
    Expect(Plan(false, false, 0.0f, true) == Step::Skip, "a guardian that left on the same map is not replaced");
    Expect(Plan(false, true, NearEnough, true) == Step::Keep, "a guardian near the player stays");
    Expect(Plan(false, true, NearEnough + 1.0f, true) == Step::Move, "a far guardian is moved to the player");

    std::vector<Kind> const carried = {{50065, 1}, {50065, 1}, {50073, 2}};
    std::vector<bool> make = Shortfall(carried, {});
    Expect(make == std::vector<bool>({true, true, true}), "nothing present: all are made");
    make = Shortfall(carried, {{50065, 1}});
    Expect(make == std::vector<bool>({false, true, true}), "one already present is not made twice");
    make = Shortfall(carried, {{50065, 1}, {50065, 1}, {50073, 2}, {50073, 2}});
    Expect(make == std::vector<bool>({false, false, false}), "all present: none is made");
    make = Shortfall(carried, {{50065, 9}, {50073, 1}});
    Expect(make == std::vector<bool>({true, true, true}), "the same creature from another spell does not count");

    std::uint32_t left = 99;
    Expect(TimeLeft(TypeDead, 0, 4000, left) && left == 0, "untimed: no timer");
    Expect(TimeLeft(TypeCorpseTimed, 7000, 4000, left) && left == 7000, "corpse delay is kept");
    Expect(TimeLeft(TypeTimed, 45000, 4000, left) && left == 41000, "countdown loses the time spent travelling");
    Expect(!TimeLeft(TypeTimed, 4000, 4000, left), "countdown that ran out is lost");
    Expect(!TimeLeft(TypeTimed, 5000, 4000, left), "countdown nearly out is lost");
    Expect(TimeLeft(TypeTimed, 5500, 4000, left) && left == 1500, "countdown with the minimum left is kept");

    if (failures)
        return 1;
    std::cout << "PASS\n";
    return 0;
}
