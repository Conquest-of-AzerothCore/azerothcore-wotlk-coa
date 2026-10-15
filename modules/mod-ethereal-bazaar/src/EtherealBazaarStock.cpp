/*
 * The rotating half of the Ethereal Bazaar: pool, draw, and the vendor list.
 */

#include "EtherealBazaar.h"

#include "Configuration/Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Random.h"

#include <algorithm>
#include <unordered_set>

namespace
{
    // How many slots each band contributes to one rotation.
    //
    // The numbers are not symmetric on purpose. The pool is lopsided - about
    // 3300 cheap items against 190 expensive ones - so equal slot counts would
    // make the expensive band come round SEVENTEEN TIMES more often than the
    // cheap one, which is the opposite of what an expensive item should feel
    // like. Slots therefore follow the size of the band, not the intent.
    uint32 SlotsFor(BazaarBand band)
    {
        switch (band)
        {
            case BazaarBand::Mid:
                return sConfigMgr->GetOption<uint32>("EtherealBazaar.Slots.Mid", 8);
            case BazaarBand::Expensive:
                return sConfigMgr->GetOption<uint32>("EtherealBazaar.Slots.Expensive", 2);
            case BazaarBand::Cheap:
            default:
                return sConfigMgr->GetOption<uint32>("EtherealBazaar.Slots.Cheap", 79);
        }
    }

    char const* BandName(BazaarBand band)
    {
        switch (band)
        {
            case BazaarBand::Mid:       return "mid";
            case BazaarBand::Expensive: return "expensive";
            default:                    return "cheap";
        }
    }
}

BazaarStock* BazaarStock::instance()
{
    static BazaarStock instance;
    return &instance;
}

void BazaarStock::Load()
{
    for (auto& band : _pool)
        band.clear();
    _stock.clear();

    QueryResult result = WorldDatabase.Query(
        "SELECT item, extended_cost, price, band FROM ethereal_bazaar_pool");
    if (!result)
    {
        LOG_WARN("module.bazaar",
                 "Ethereal Bazaar: ethereal_bazaar_pool is empty or missing. "
                 "Tiraxis will have nothing to rotate.");
        return;
    }

    do
    {
        Field* f = result->Fetch();
        BazaarPoolEntry e;
        e.item = f[0].Get<uint32>();
        e.extendedCost = f[1].Get<uint32>();
        e.price = f[2].Get<uint32>();

        uint8 const band = f[3].Get<uint8>();
        if (band >= BAZAAR_BAND_COUNT)
        {
            LOG_ERROR("module.bazaar", "Ethereal Bazaar: item {} has band {}, which does not exist. Skipped.",
                      e.item, band);
            continue;
        }
        e.band = static_cast<BazaarBand>(band);

        // An item without an ItemExtendedCost row cannot be charged for, and
        // the vendor frame would offer it for nothing. Better to drop it here
        // than to hand out free cosmetics.
        if (!e.extendedCost)
        {
            LOG_ERROR("module.bazaar", "Ethereal Bazaar: item {} has no extended cost. Skipped.", e.item);
            continue;
        }

        if (!sObjectMgr->GetItemTemplate(e.item))
        {
            LOG_ERROR("module.bazaar", "Ethereal Bazaar: item {} is not in item_template. Skipped.", e.item);
            continue;
        }

        _pool[static_cast<std::size_t>(e.band)].push_back(e);
    } while (result->NextRow());

    LOG_INFO("module.bazaar", "Ethereal Bazaar: pool loaded - {} cheap, {} mid, {} expensive.",
             PoolSize(BazaarBand::Cheap), PoolSize(BazaarBand::Mid), PoolSize(BazaarBand::Expensive));

    // A rotation that is still running keeps its stock across a restart. The
    // alternative - redrawing on every startup - would let anyone reroll the
    // shop by asking an admin to restart the server.
    QueryResult saved = CharacterDatabase.Query(
        "SELECT item, extended_cost, band FROM ethereal_bazaar_stock");
    QueryResult when = CharacterDatabase.Query(
        "SELECT value FROM ethereal_bazaar_meta WHERE name = 'next_rotation'");

    _nextRotation = when ? when->Fetch()[0].Get<uint64>() : 0;

    if (saved && _nextRotation > static_cast<uint64>(GameTime::GetGameTime().count()))
    {
        do
        {
            Field* f = saved->Fetch();
            BazaarPoolEntry e;
            e.item = f[0].Get<uint32>();
            e.extendedCost = f[1].Get<uint32>();
            e.band = static_cast<BazaarBand>(std::min<uint8>(f[2].Get<uint8>(), BAZAAR_BAND_COUNT - 1));
            _stock.push_back(e);
        } while (saved->NextRow());

        ApplyToVendor();
        LOG_INFO("module.bazaar", "Ethereal Bazaar: resumed a running rotation with {} items, {} seconds left.",
                 _stock.size(), _nextRotation - GameTime::GetGameTime().count());
        return;
    }

    Rotate();
}

std::size_t BazaarStock::PoolSize(BazaarBand band) const
{
    return _pool[static_cast<std::size_t>(band)].size();
}

uint32 BazaarStock::RollInterval() const
{
    uint32 const minHours = sConfigMgr->GetOption<uint32>("EtherealBazaar.RotationMinHours", 3);
    uint32 const maxHours = sConfigMgr->GetOption<uint32>("EtherealBazaar.RotationMaxHours", 6);
    uint32 const lo = std::max<uint32>(1, minHours);
    uint32 const hi = std::max(lo, maxHours);
    return urand(lo * HOUR, hi * HOUR);
}

void BazaarStock::Rotate()
{
    ClearVendor();
    _stock.clear();

    for (uint8 b = 0; b < BAZAAR_BAND_COUNT; ++b)
    {
        auto const& pool = _pool[b];
        if (pool.empty())
            continue;

        uint32 const want = std::min<uint32>(SlotsFor(static_cast<BazaarBand>(b)),
                                             static_cast<uint32>(pool.size()));

        // Draw without replacement: the same item twice in one stock would
        // look like a bug to a player, and it wastes a slot.
        std::unordered_set<std::size_t> taken;
        while (taken.size() < want)
            taken.insert(urand(0, static_cast<uint32>(pool.size()) - 1));

        for (std::size_t idx : taken)
            _stock.push_back(pool[idx]);
    }

    _nextRotation = static_cast<uint64>(GameTime::GetGameTime().count()) + RollInterval();

    ApplyToVendor();
    SaveStock();

    LOG_INFO("module.bazaar", "Ethereal Bazaar: rotated - {} items in stock, next rotation in {} minutes.",
             _stock.size(), (_nextRotation - GameTime::GetGameTime().count()) / MINUTE);

    for (uint8 b = 0; b < BAZAAR_BAND_COUNT; ++b)
    {
        uint32 n = 0;
        for (auto const& e : _stock)
            if (e.band == static_cast<BazaarBand>(b))
                ++n;
        LOG_DEBUG("module.bazaar", "Ethereal Bazaar:   {} {}", n, BandName(static_cast<BazaarBand>(b)));
    }
}

void BazaarStock::ClearVendor() const
{
    // persist = false throughout: the rotation lives in memory and in the
    // characters database, and must never write itself into npc_vendor. That
    // table holds the two FIXED lists, and a rotation that leaked into it
    // would grow without end.
    for (auto const& e : _stock)
        sObjectMgr->RemoveVendorItem(BAZAAR_NPC_TIRAXIS, e.item, false);
}

void BazaarStock::ApplyToVendor() const
{
    for (auto const& e : _stock)
        sObjectMgr->AddVendorItem(BAZAAR_NPC_TIRAXIS, e.item,
                                  /*maxcount*/ 0, /*incrtime*/ 0, e.extendedCost, false);
}

void BazaarStock::SaveStock() const
{
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    trans->Append("TRUNCATE TABLE ethereal_bazaar_stock");
    for (auto const& e : _stock)
        trans->Append("INSERT INTO ethereal_bazaar_stock (item, extended_cost, band) VALUES ({}, {}, {})",
                      e.item, e.extendedCost, static_cast<uint32>(e.band));
    trans->Append("REPLACE INTO ethereal_bazaar_meta (name, value) VALUES ('next_rotation', {})",
                  _nextRotation);
    CharacterDatabase.CommitTransaction(trans);
}

void BazaarStock::Update(uint32 diff)
{
    // A shop that changes every few hours does not need to be asked more than
    // once a minute, and the world update runs on every tick.
    _sinceCheck += diff;
    if (_sinceCheck < MINUTE * IN_MILLISECONDS)
        return;
    _sinceCheck = 0;

    if (_nextRotation && static_cast<uint64>(GameTime::GetGameTime().count()) >= _nextRotation)
        Rotate();
}
