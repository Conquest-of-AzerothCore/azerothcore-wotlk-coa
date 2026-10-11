#ifndef COA_ASCENSION_CROWS_CACHE_POLICY_H
#define COA_ASCENSION_CROWS_CACHE_POLICY_H

namespace CrowsCache
{
constexpr unsigned CacheItem = 1615010;
constexpr unsigned Spite = 1005000;
constexpr unsigned HighRisk = 1004019;
constexpr unsigned CrowEntry = 994310;
constexpr unsigned ChestEntry = 994311;
constexpr unsigned DropEntry = 994312;
constexpr unsigned OpenSpell = 68398;
constexpr unsigned Tanaris = 440;
constexpr unsigned Gadgetzan = 976;
constexpr unsigned Silithus = 1377;
constexpr unsigned ThousandNeedles = 400;
constexpr unsigned Barrens = 17;
constexpr unsigned Ratchet = 392;
constexpr unsigned CenarionHold = 3425;
constexpr unsigned AbyssalSands = 1939;
constexpr unsigned RewardCount = 5;
constexpr unsigned WarningSeconds[] = {1800, 900, 300, 60};
constexpr unsigned WarningCount = 4;

constexpr unsigned PassedWarnings(unsigned remaining)
{
    unsigned mask = 0;
    for (unsigned i = 0; i < WarningCount; ++i)
        if (remaining < WarningSeconds[i])
            mask |= 1u << i;
    return mask;
}

constexpr unsigned DueWarning(unsigned mask, unsigned remaining)
{
    unsigned result = WarningCount;
    for (unsigned i = 0; i < WarningCount; ++i)
        if (!(mask & (1u << i)) && remaining <= WarningSeconds[i])
            result = i;
    return result;
}

constexpr unsigned long long NextAppearance(unsigned long long scheduled, unsigned long long now, unsigned interval)
{
    return scheduled > now ? scheduled : scheduled + ((now - scheduled) / interval + 1) * interval;
}

enum class Phase : unsigned
{
    Schedule,
    Warning,
    Available,
    Carried,
    Dropped
};

constexpr bool Eligible(unsigned level, bool highRisk, bool alive)
{
    return level == 60 && highRisk && alive;
}

constexpr bool CanClaim(Phase phase, bool completedCast)
{
    return phase == Phase::Dropped || (phase == Phase::Available && completedCast);
}

constexpr bool SafeArea(unsigned area)
{
    return area == Gadgetzan || area == CenarionHold || area == Ratchet;
}

constexpr bool CarrySlow(bool carrying, unsigned area)
{
    return carrying && !SafeArea(area);
}

constexpr bool CanOpen(bool tracked, bool eligible, unsigned area, bool combat)
{
    return tracked && eligible && SafeArea(area) && !combat;
}

constexpr bool InterruptOpening(bool moved, unsigned damage)
{
    return moved || damage > 0;
}
}

#endif
