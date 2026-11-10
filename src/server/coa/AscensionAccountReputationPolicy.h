#ifndef ASCENSION_ACCOUNT_REPUTATION_POLICY_H
#define ASCENSION_ACCOUNT_REPUTATION_POLICY_H

#include "DBCEnums.h"
#include "Define.h"

#include <map>
#include <vector>

namespace AccountReputation
{
    struct SiblingStanding
    {
        uint32 faction;
        int32 standing;
        bool shared;
    };

    inline bool IsShared(bool sameTeam, int32 siblingBase, int32 ownBase, uint32 ownDefaultFlags)
    {
        if (ownDefaultFlags & FACTION_FLAG_HIDDEN)
            return false;

        return sameTeam || siblingBase == ownBase;
    }

    inline bool HasEarned(int32 standingAboveBase)
    {
        return standingAboveBase > 0;
    }

    template <typename CurrentStanding>
    std::map<uint32, int32> StandingsToRaise(std::vector<SiblingStanding> const& siblings, CurrentStanding current)
    {
        std::map<uint32, int32> best;
        for (SiblingStanding const& sibling : siblings)
        {
            if (!sibling.shared)
                continue;

            auto [itr, inserted] = best.try_emplace(sibling.faction, sibling.standing);
            if (!inserted && sibling.standing > itr->second)
                itr->second = sibling.standing;
        }

        std::map<uint32, int32> raises;
        for (auto const& [faction, standing] : best)
            if (standing > current(faction))
                raises.emplace(faction, standing);

        return raises;
    }
}

#endif
