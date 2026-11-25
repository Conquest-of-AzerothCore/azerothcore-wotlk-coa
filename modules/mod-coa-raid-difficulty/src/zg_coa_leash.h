#ifndef COA_ZG_LEASH_H
#define COA_ZG_LEASH_H

#include "AreaBoundary.h"
#include "CreatureAI.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"

#include <array>
#include <utility>
#include <vector>

namespace coa_zg
{
    struct LeashLine
    {
        float anchorX;
        float anchorY;
        float markX;
        float markY;
    };

    constexpr bool InsideLeash(LeashLine const& line, float x, float y)
    {
        return (x - line.markX) * (line.markX - line.anchorX) + (y - line.markY) * (line.markY - line.anchorY) <= 0.0f;
    }

    class LeashLineBoundary : public AreaBoundary
    {
    public:
        explicit LeashLineBoundary(LeashLine const& line) : AreaBoundary(false), _line(line) { }

    protected:
        bool IsWithinBoundaryArea(Position const* pos) const override
        {
            return InsideLeash(_line, pos->GetPositionX(), pos->GetPositionY());
        }

    private:
        LeashLine const _line;
    };

    struct BossLeash
    {
        uint32 bossId;
        LeashLine line;
    };

    constexpr LeashLine LEASH_JEKLIK = { -12291.9f, -1380.08f, -12104.915f, -1478.2906f };

    constexpr std::array<BossLeash, 7> BOSS_LEASHES = { {
        { DATA_JEKLIK, LEASH_JEKLIK },
        { DATA_VENOXIS, { -12029.8f, -1707.9f, -11992.385f, -1657.1074f } },
        { DATA_MARLI, { -12326.5f, -1577.1f, -12240.448f, -1680.7545f } },
        { DATA_THEKAL, { -11700.8f, -1998.9f, -11716.085f, -1864.5771f } },
        { DATA_MANDOKIR, { -12167.8f, -1927.2f, -12285.58f, -1905.0387f } },
        { DATA_JINDO, { -11515.8f, -1275.5f, -11614.576f, -1360.4701f } },
        { DATA_EDGE_OF_MADNESS, { -11901.229f, -1906.366f, -11939.485f, -1843.0857f } },
    } };

    static_assert(InsideLeash(LEASH_JEKLIK, -12273.9f, -1407.8f));

    inline CreatureBoundary const* LeashFor(uint32 bossId)
    {
        static std::vector<std::pair<uint32, CreatureBoundary>> const boundaries = []
        {
            std::vector<std::pair<uint32, CreatureBoundary>> result;
            for (BossLeash const& leash : BOSS_LEASHES)
                result.emplace_back(leash.bossId, CreatureBoundary{ new LeashLineBoundary(leash.line) });
            return result;
        }();

        for (auto const& [id, boundary] : boundaries)
            if (id == bossId)
                return &boundary;

        return nullptr;
    }
}

#endif
