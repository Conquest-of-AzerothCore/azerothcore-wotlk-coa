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
    ManastormClientMode ClientMode();
    bool IsReconstructedClientMode();
    bool IsNativeClientMode();
    void LogConfiguration();
}

#endif
