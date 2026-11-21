#include "AreaDefines.h"
#include "Position.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"

void CoAAddDungeonReleaseCheckpoint(uint32 mapId, uint32 bossId, Position const& position);

namespace
{
    struct BossCheckpoint
    {
        uint32 bossId;
        Position position;
    };

    BossCheckpoint const BOSS_CHECKPOINTS[] =
    {
        { DATA_MARLI, { -12111.865f, -1794.2035f, 80.478745f, 2.6665816f } },
        { DATA_MANDOKIR, { -12111.865f, -1794.2035f, 80.478745f, 2.6665816f } },
        { DATA_ARLOKK, { -11617.389f, -1617.7999f, 38.90633f, 1.5104696f } },
        { DATA_EDGE_OF_MADNESS, { -11945.865f, -1813.931f, 52.090435f, 0.07633516f } },
        { DATA_JEKLIK, { -11940.951f, -1549.5022f, 39.647f, 4.4934187f } },
        { DATA_JINDO, { -11657.934f, -1516.3619f, 39.839127f, 2.8283699f } },
        { DATA_THEKAL, { -11714.241f, -1851.3381f, 40.527004f, 5.9236217f } },
    };
}

void AddCoaZulGurubCheckpoints()
{
    for (BossCheckpoint const& checkpoint : BOSS_CHECKPOINTS)
        CoAAddDungeonReleaseCheckpoint(MAP_ZUL_GURUB, checkpoint.bossId, checkpoint.position);
}
