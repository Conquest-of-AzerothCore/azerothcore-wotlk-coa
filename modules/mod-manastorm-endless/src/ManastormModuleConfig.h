#ifndef MANASTORM_MODULE_CONFIG_H
#define MANASTORM_MODULE_CONFIG_H

#include "Define.h"

enum class ManastormClientMode : uint8
{
    Reconstructed = 1,
    Ascension = 2
};

namespace ManastormModuleConfig
{
    void Load(bool reload);
    bool Enabled();
    uint8 AffixMinimumLevel();
    bool WeeklyCacheLockoutEnabled();
    uint32 WeeklyCacheLockoutLimit();
    bool CoALootModeEnabled();
    bool CoAFirstClearEnabled();
    bool CoARepeatEnabled();
    bool CoAFirstClearResetsWithWindow();
    uint32 CoATokenCap();
    uint32 CoATokenWindowSeconds();
    ManastormClientMode ClientMode();
    bool IsReconstructedClientMode();
    bool IsNativeClientMode();
    bool ObjectiveRaidSkull();
    bool NativeObjectiveHighlight();
    bool FollowReleaseStage();
    uint32 ReleaseStage();
    void LogConfiguration();
}

#endif
