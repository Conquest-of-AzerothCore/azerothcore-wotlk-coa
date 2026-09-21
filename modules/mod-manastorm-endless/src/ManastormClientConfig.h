#ifndef MANASTORM_CLIENT_CONFIG_H
#define MANASTORM_CLIENT_CONFIG_H

#include "NativeClientConfig.h"

namespace ManastormClientConfig
{
    inline void Apply(NativeClientConfig& config, bool enabled)
    {
        config.SetInt("CONFIG_MANASTORM_LOADOUTS_MAX", 4);
        config.SetBool("CONFIG_MANASTORM_ENABLED", enabled);
        config.SetBool("CONFIG_MANASTORM_END_GAME_ENABLED", enabled);
        config.SetBool("CONFIG_MANASTORM_LOADOUTS_ENABLED", enabled);
    }
}

#endif
