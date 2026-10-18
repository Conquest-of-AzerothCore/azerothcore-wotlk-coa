#include "ManastormModuleConfig.h"

#include "Config.h"
#include <algorithm>
#include "Log.h"

namespace ManastormModuleConfig
{
    namespace
    {
        bool enabled = true;
        uint8 affixMinimumLevel = 50;
        ManastormClientMode clientMode = ManastormClientMode::Ascension;
    }

    void Load(bool reload)
    {
        bool const requestedEnabled = sConfigMgr->GetOption<bool>("Manastorm.Enable", true);
        uint32 const requestedMode = sConfigMgr->GetOption<uint32>("Manastorm.ClientMode", 2);
        if (reload)
        {
            // Switching transport or disabling hooks during a run strands its
            // private-instance ownership and the client's active-state cache.
            if (requestedEnabled != enabled || requestedMode != uint32(clientMode))
                LOG_WARN("module.manastorm.endless", "Manastorm.Enable/ClientMode changes require a restart; "
                    "keeping enabled={} clientMode={} for this process.", enabled, uint32(clientMode));
            return;
        }
        affixMinimumLevel = uint8(std::clamp(sConfigMgr->GetOption<uint32>("Manastorm.AffixMinimumLevel", 50), 1u, 80u));
        enabled = requestedEnabled;
        clientMode = requestedMode == 2 ? ManastormClientMode::Ascension : ManastormClientMode::Reconstructed;
        if (requestedMode != 1 && requestedMode != 2)
            LOG_ERROR("module.manastorm.endless", "Invalid Manastorm.ClientMode={}; using Mode 1.", requestedMode);
    }

    uint8 AffixMinimumLevel()
    {
        return affixMinimumLevel;
    }

    bool Enabled()
    {
        return enabled;
    }

    ManastormClientMode ClientMode()
    {
        return clientMode;
    }

    bool IsReconstructedClientMode()
    {
        return clientMode == ManastormClientMode::Reconstructed;
    }

    bool IsNativeClientMode()
    {
        return clientMode == ManastormClientMode::Ascension;
    }

    void LogConfiguration()
    {
        LOG_INFO("module.manastorm.endless", "Manastorm owner=mod-manastorm-endless enabled={} clientMode={} ({}). "
            "The Ascension donor run service is not registered.", enabled, uint32(clientMode),
            IsNativeClientMode() ? "Ascension native" : "reconstructed addon");
    }
}
