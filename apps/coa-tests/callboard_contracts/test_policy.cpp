#include "../../../src/server/coa/AscensionCallboardContractsPolicy.h"
#include <cassert>
#include <cstring>
#include <iostream>
#include <stdexcept>

namespace
{
using namespace CallboardContracts;

struct ByteBufferLikePacket
{
    std::vector<std::uint8_t> bytes;

    bool empty() const { return bytes.empty(); }
    std::size_t size() const { return bytes.size(); }

    std::uint8_t const* contents() const
    {
        if (bytes.empty())
            throw std::runtime_error("empty buffer has no contents");
        return bytes.data();
    }
};

std::uint32_t U32At(std::vector<std::uint8_t> const& bytes, std::size_t& at)
{
    assert(at + 4 <= bytes.size());
    std::uint32_t const value = ReadU32(bytes.data() + at);
    at += 4;
    return value;
}

std::string StringAt(std::vector<std::uint8_t> const& bytes, std::size_t& at)
{
    std::string text;
    while (bytes.at(at) != 0)
        text.push_back(static_cast<char>(bytes[at++]));
    ++at;
    return text;
}

std::vector<std::uint8_t> ActivationBytes(std::string const& type, std::uint8_t flag, std::uint32_t count)
{
    Writer out;
    out.U32(static_cast<std::uint32_t>(type.size()));
    std::vector<std::uint8_t> bytes = out.Take();
    bytes.insert(bytes.end(), type.begin(), type.end());
    bytes.push_back(flag);
    for (int shift = 0; shift < 32; shift += 8)
        bytes.push_back(static_cast<std::uint8_t>(count >> shift));
    return bytes;
}

void Days()
{
    std::int64_t const weekly = 1'000'000;
    assert(DaysBegun(weekly - 6 * DaySeconds, weekly) == 1);
    assert(DaysBegun(weekly - 6 * DaySeconds + 1, weekly) == 2);
    assert(DaysBegun(weekly - 5 * DaySeconds, weekly) == 2);
    assert(DaysBegun(weekly - DaySeconds, weekly) == 6);
    assert(DaysBegun(weekly, weekly) == 7);
    assert(DaysBegun(weekly - 9 * DaySeconds, weekly) == 1);
    assert(DaysBegun(weekly + 1, weekly) == 7);
    assert(WeekStart(weekly) == weekly - 7 * DaySeconds);

    assert(Remaining(1, 1, 0) == 1);
    assert(Remaining(6, 1, 0) == 6);
    assert(Remaining(6, 1, 2) == 4);
    assert(Remaining(3, 2, 6) == 0);
    assert(Remaining(3, 2, 9) == 0);
    assert(Remaining(7, 3, 1) == 20);

    assert(Spare(4, 1) == 3);
    assert(Spare(1, 1) == 0);
    assert(Spare(1, 3) == 0);
}

void Prices()
{
    assert(MoneyCost(0, 1.0, 100000) == 100000);
    assert(MoneyCost(250000, 1.0, 100000) == 250000);
    assert(MoneyCost(250000, 1.5, 100000) == 375000);
    assert(MoneyCost(5, 0.0, 0) == 1);
    assert(MoneyCost(5, -2.0, 3) == 3);
    assert(MoneyCost(4'000'000'000u, 1.0, 1) == MaxMoneyCost);
    assert(TokenCost(40, 2.0, 50) == 80);
    assert(TokenCost(0, 2.0, 50) == 50);
    assert(TokenCost(25, 0.5, 1) == 13);

    assert(DisplayedCachePoints(0) == 0);
    assert(DisplayedCachePoints(20) == 2);
    assert(DisplayedCachePoints(25) == 3);
}

void Names()
{
    assert(DisplayName("OpenWorldVanillaZoneKill1") == "Open World Vanilla Zone Kill 1");
    assert(DisplayName("TBCZoneDailies") == "TBC Zone Dailies");
    assert(DisplayName("TBCHighRiskWarInZone") == "TBC High Risk War In Zone");
    assert(DisplayName("CallToArms") == "Call To Arms");
    assert(DisplayName("Duel") == "Duel");

    assert(IsValidTypeName("OpenWorldVanillaZoneKill1"));
    assert(!IsValidTypeName(""));
    assert(!IsValidTypeName("Kill'1"));
    assert(!IsValidTypeName("Kill 1"));
    assert(!IsValidTypeName(std::string(MaxTypeNameLength + 1, 'A')));

    static_assert(RequiredReleaseStage("VanillaHeroicDungeonCrawling") == RaidRelease::StageHeroicDungeons);
    static_assert(RequiredReleaseStage("VanillaMythicDungeonCrawling") == RaidRelease::StageMythicDungeons);
    assert(RequiredReleaseStage("VanillaNormalDungeonCrawling") == 0);
    assert(!IsContractReleased("VanillaHeroicDungeonCrawling", 0));
    assert(IsContractReleased("VanillaHeroicDungeonCrawling", RaidRelease::StageHeroicDungeons));
    assert(!IsContractReleased("VanillaMythicDungeonCrawling", RaidRelease::StageHeroicDungeons));
    assert(IsContractReleased("VanillaMythicDungeonCrawling", RaidRelease::StageMythicDungeons));
    assert(IsContractReleased("VanillaMythicDungeonCrawling", RaidRelease::AllReleased));
    assert(IsContractReleased("VanillaNormalDungeonCrawling", 0));

    assert(ContentTypes.size() == 5);
    for (char const* key : { "PvE", "PvP", "Profession", "HighRisk", "Misc" })
        assert(IsContentType(key));
    assert(!IsContentType("pve") && !IsContentType(""));
}

void View()
{
    SubCategory kill;
    kill.type = "OpenWorldVanillaZoneKill1";
    kill.name = "Open World Vanilla Zone Kill 1";
    kill.remaining = 3;
    kill.moneyCost = 100000;
    kill.tokenCost = 80;
    kill.minimumLevel = 60;
    kill.reward.cachePoints = 2;
    kill.reward.items = { { 375250, 2000 }, { BazaarToken, 40 } };

    SubCategory dungeon;
    dungeon.type = "VanillaHeroicDungeonCrawling";
    dungeon.name = "Vanilla Heroic Dungeon Crawling";
    dungeon.remaining = 0;
    dungeon.moneyCost = 0;
    dungeon.tokenCost = 0;
    dungeon.reward.items = { { 1615001, 1 } };

    SubCategory duel;
    duel.type = "Duel";
    duel.remaining = 2;
    duel.moneyCost = 7;
    duel.tokenCost = 9;
    duel.reward.honor = 5;
    duel.reward.items = { { BazaarToken, 10 } };

    Category pve{ "PvE", "PvE", { kill, dungeon } };
    CategoryTotal const total = Summarize(pve);
    assert(total.remaining == 3);
    assert(total.moneyCost == 300000 && total.tokenCost == 240);
    assert(total.reward.cachePoints == 6);
    assert(total.reward.items.size() == 2 && total.reward.ItemAmount(375250) == 6000);
    assert(total.reward.ItemAmount(BazaarToken) == 120 && total.reward.ItemAmount(1615001) == 0);

    Category empty{ "Misc", "Miscellaneous", {} };
    CategoryTotal const none = Summarize(empty);
    assert(none.remaining == 0 && none.moneyCost == 1 && none.tokenCost == 1);

    Category mixed{ "PvP", "PvP", { duel, duel } };
    CategoryTotal const pvp = Summarize(mixed);
    assert(pvp.remaining == 4 && pvp.moneyCost == 28 && pvp.tokenCost == 36);
    assert(pvp.reward.honor == 20 && pvp.reward.items.size() == 1 && pvp.reward.ItemAmount(BazaarToken) == 40);

    std::vector<std::uint8_t> const bytes = SerializeView({ pve, empty });
    std::size_t at = 0;
    assert(U32At(bytes, at) == 2);

    assert(StringAt(bytes, at) == "PvE" && StringAt(bytes, at) == "PvE");
    assert(U32At(bytes, at) == 3 && U32At(bytes, at) == 300000 && U32At(bytes, at) == 240);
    assert(U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 6);
    assert(U32At(bytes, at) == 2);
    assert(U32At(bytes, at) == 375250 && U32At(bytes, at) == 6000);
    assert(U32At(bytes, at) == BazaarToken && U32At(bytes, at) == 120);
    assert(U32At(bytes, at) == 2);

    assert(StringAt(bytes, at) == kill.type && StringAt(bytes, at) == kill.name);
    assert(U32At(bytes, at) == 3 && U32At(bytes, at) == 100000 && U32At(bytes, at) == 80 && U32At(bytes, at) == 60);
    assert(U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 2);
    assert(U32At(bytes, at) == 2);
    assert(U32At(bytes, at) == 375250 && U32At(bytes, at) == 2000);
    assert(U32At(bytes, at) == BazaarToken && U32At(bytes, at) == 40);

    assert(StringAt(bytes, at) == dungeon.type && StringAt(bytes, at) == dungeon.name);
    assert(U32At(bytes, at) == 0 && U32At(bytes, at) == 1 && U32At(bytes, at) == 1 && U32At(bytes, at) == 0);
    assert(U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 0 && U32At(bytes, at) == 0);
    assert(U32At(bytes, at) == 1);
    assert(U32At(bytes, at) == 1615001 && U32At(bytes, at) == 1);

    assert(StringAt(bytes, at) == "Misc" && StringAt(bytes, at) == "Miscellaneous");
    assert(U32At(bytes, at) == 0 && U32At(bytes, at) == 1 && U32At(bytes, at) == 1);
    for (int i = 0; i < 5; ++i)
        assert(U32At(bytes, at) == 0);
    assert(U32At(bytes, at) == 0);
    assert(at == bytes.size());
}

void Activations()
{
    std::vector<std::uint8_t> const gold = ActivationBytes("Duel", 1, 0);
    std::optional<Activation> const parsed = ParseActivation(gold.data(), gold.size());
    assert(parsed && parsed->type == "Duel" && parsed->payWithGold && parsed->count == 0);
    assert(parsed->Completions() == 1);

    std::vector<std::uint8_t> const tokens = ActivationBytes("OpenWorldVanillaZoneKill2", 0, 5);
    std::optional<Activation> const many = ParseActivation(tokens.data(), tokens.size());
    assert(many && many->type == "OpenWorldVanillaZoneKill2" && !many->payWithGold && many->Completions() == 5);

    assert(!ParseActivation(gold.data(), gold.size() - 1));
    assert(!ParseActivation(nullptr, 0));
    assert(!ParseActivation(gold.data(), 3));
    std::vector<std::uint8_t> const quote = ActivationBytes("Du'l", 1, 0);
    assert(!ParseActivation(quote.data(), quote.size()));
    std::vector<std::uint8_t> const empty = ActivationBytes("", 1, 0);
    assert(!ParseActivation(empty.data(), empty.size()));
    std::vector<std::uint8_t> huge = ActivationBytes("Duel", 1, 0);
    huge[3] = 0x7F;
    assert(!ParseActivation(huge.data(), huge.size()));
}

void ActivationPackets()
{
    assert(!ParseActivationPacket(ByteBufferLikePacket{}));

    ByteBufferLikePacket const packet{ ActivationBytes("Duel", 0, 2) };
    std::optional<Activation> const parsed = ParseActivationPacket(packet);
    assert(parsed && parsed->type == "Duel" && !parsed->payWithGold && parsed->Completions() == 2);
}

void Pending()
{
    PendingRequests::Clock::time_point const now{};
    PendingRequests pending;
    assert(pending.Size() == 0 && !pending.Take(1, now).view);

    pending.RequestView(1, now);
    pending.RequestView(1, now);
    assert(pending.Size() == 1);
    assert(pending.Activate(1, { "Duel", true, 0 }, now));
    assert(pending.Activate(2, { "CallToArms", false, 3 }, now));
    assert(pending.Size() == 3);

    Requests first = pending.Take(1, now);
    assert(first.view && first.activations.size() == 1 && first.activations[0].type == "Duel");
    assert(pending.Size() == 1);
    assert(!pending.Take(1, now).view);

    Requests second = pending.Take(2, now);
    assert(!second.view && second.activations.size() == 1 && second.activations[0].count == 3);
    assert(pending.Size() == 0);

    for (std::size_t i = 0; i < PendingRequests::MaxActivationsPerAccount; ++i)
        assert(pending.Activate(3, { "Duel", true, 0 }, now));
    assert(!pending.Activate(3, { "Duel", true, 0 }, now));
    assert(pending.Size() == PendingRequests::MaxActivationsPerAccount);
    assert(pending.Take(3, now).activations.size() == PendingRequests::MaxActivationsPerAccount);
    assert(pending.Size() == 0);
}

void PendingExpiry()
{
    PendingRequests::Clock::time_point const queued{};
    PendingRequests::Clock::time_point const fresh = queued + PendingRequests::MaxAge;
    PendingRequests::Clock::time_point const stale = fresh + std::chrono::seconds(1);
    PendingRequests pending;

    pending.RequestView(1, queued);
    assert(pending.Activate(1, { "Duel", true, 0 }, queued));
    assert(pending.Take(1, fresh).view);

    pending.RequestView(1, queued);
    assert(pending.Activate(1, { "Duel", true, 0 }, queued));
    Requests expired = pending.Take(1, stale);
    assert(!expired.view && expired.activations.empty() && pending.Size() == 0);

    pending.RequestView(1, queued);
    assert(pending.Activate(1, { "Duel", true, 0 }, queued));
    pending.RequestView(2, fresh);
    pending.DropExpired(fresh);
    assert(pending.Size() == 3);
    pending.DropExpired(stale);
    assert(pending.Size() == 1);
    assert(!pending.Take(1, stale).view);
    assert(pending.Take(2, stale).view && pending.Size() == 0);
}

void Ledger()
{
    WeekLedger ledger;
    assert(ledger.Completions("Duel", 100) == 0);
    ledger.Roll(100);
    assert(ledger.Add("Duel") == 1 && ledger.Add("Duel") == 2);
    ledger.Set("CallToArms", 4);
    assert(ledger.Completions("Duel", 100) == 2 && ledger.Completions("CallToArms", 100) == 4);
    assert(ledger.Completions("Duel", 200) == 0);

    ledger.Roll(100);
    assert(ledger.Completions("Duel", 100) == 2);
    ledger.Roll(200);
    assert(ledger.WeekStartTime() == 200);
    assert(ledger.Completions("Duel", 200) == 0 && ledger.Completions("CallToArms", 200) == 0);
    assert(ledger.Add("Duel") == 1);

    std::uint32_t const days = DaysBegun(200 + 7 * DaySeconds - 4 * DaySeconds, 200 + 7 * DaySeconds);
    assert(days == 3);
    assert(Spare(Remaining(days, 1, ledger.Completions("Duel", 200)), 1) == 1);
}

void LedgerMerge()
{
    WeekLedger stored;
    stored.Roll(100);
    stored.Set("Duel", 3);
    stored.Set("CallToArms", std::numeric_limits<std::uint32_t>::max());

    WeekLedger live;
    live.Roll(100);
    assert(live.Add("Duel") == 1);
    std::vector<std::string> const unsaved = live.Types();
    assert(unsaved.size() == 1 && unsaved[0] == "Duel");
    live.Add("CallToArms");

    live.Merge(stored);
    assert(live.Completions("Duel", 100) == 4);
    assert(live.Completions("CallToArms", 100) == std::numeric_limits<std::uint32_t>::max());

    WeekLedger rolled;
    rolled.Roll(200);
    rolled.Add("Duel");
    rolled.Merge(stored);
    assert(rolled.Completions("Duel", 200) == 1 && rolled.Completions("CallToArms", 200) == 0);

    WeekLedger empty;
    empty.Roll(100);
    assert(empty.Types().empty());
    empty.Merge(stored);
    assert(empty.Completions("Duel", 100) == 3);
}
}

int main()
{
    assert(RequestViewOpcode == 0x055F && ActivateOpcode == 0x055B && ViewOpcode == 0x0589);
    assert(BazaarToken == 975001);
    Days();
    Prices();
    Names();
    View();
    Activations();
    ActivationPackets();
    Pending();
    PendingExpiry();
    Ledger();
    LedgerMerge();
    std::cout << "callboard contracts policy checks passed\n";
    return 0;
}
