#include "ManastormModuleConfig.h"

#include "Config.h"
#include <algorithm>
#include "Log.h"
#include "ManastormReleaseStage.h"

namespace ManastormModuleConfig
{
    namespace
    {
        bool enabled = true;
        uint8 affixMinimumLevel = 50;
        bool weeklyCacheLockoutEnabled = true;
        uint32 weeklyCacheLockoutLimit = 5;
        ManastormClientMode clientMode = ManastormClientMode::Ascension;
        bool followReleaseStage = false;
        bool objectiveRaidSkull = true;
        bool nativeObjectiveHighlight = false;
    }

    void Load(bool reload)
    {
        bool const requestedEnabled = sConfigMgr->GetOption<bool>("Manastorm.Enable", true);
        weeklyCacheLockoutEnabled = sConfigMgr->GetOption<bool>("Manastorm.WeeklyCacheLockout.Enabled", true);
        int32 const requestedLimit = sConfigMgr->GetOption<int32>("Manastorm.WeeklyCacheLockout.Limit", 5);
        weeklyCacheLockoutLimit = requestedLimit >= 0 && requestedLimit <= 255 ? uint32(requestedLimit) : 5;
        if (requestedLimit < 0 || requestedLimit > 255)
            LOG_ERROR("module.manastorm.endless", "Invalid Manastorm.WeeklyCacheLockout.Limit={}; "
                "expected 0..255, using 5.", requestedLimit);
        uint32 const requestedMode = sConfigMgr->GetOption<uint32>("Manastorm.ClientMode", 2);
        followReleaseStage = sConfigMgr->GetOption<bool>("Manastorm.FollowReleaseStage", false);
        objectiveRaidSkull = sConfigMgr->GetOption<bool>("Manastorm.Objective.RaidSkull", true);
        nativeObjectiveHighlight = sConfigMgr->GetOption<bool>("Manastorm.Objective.NativeHighlight", false);
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

    bool WeeklyCacheLockoutEnabled()
    {
        return weeklyCacheLockoutEnabled;
    }

    uint32 WeeklyCacheLockoutLimit()
    {
        return weeklyCacheLockoutLimit;
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

    bool ObjectiveRaidSkull() { return objectiveRaidSkull; }

    bool NativeObjectiveHighlight() { return nativeObjectiveHighlight; }

    bool FollowReleaseStage()
    {
        return followReleaseStage;
    }

    uint32 ReleaseStage()
    {
        if (!followReleaseStage)
            return ManastormReleaseStage::AllReleased;

        return std::min<uint32>(RaidRelease::ReleasedStage(), ManastormReleaseStage::AllReleased);
    }

    void LogConfiguration()
    {
        LOG_INFO("module.manastorm.endless", "Manastorm owner=mod-manastorm-endless enabled={} clientMode={} ({}) "
            "followReleaseStage={}. The Ascension donor run service is not registered.", enabled, uint32(clientMode),
            IsNativeClientMode() ? "Ascension native" : "reconstructed addon", followReleaseStage);
    }
}
