#include "ManastormModuleConfig.h"

#include "Config.h"
#include "AscensionFreepick.h"
#include <algorithm>
#include <cmath>
#include "Log.h"
#include "ManastormReleaseStage.h"

namespace ManastormModuleConfig
{
    namespace
    {
        bool enabled = true;
        uint8 affixMinimumLevel = 50;
        constexpr double DefaultExperienceRate = 0.3;
        double experienceRate = DefaultExperienceRate;
        bool weeklyCacheLockoutEnabled = true;
        uint32 weeklyCacheLockoutLimit = 5;
        bool coaLootModeEnabled = false;
        bool coaFirstClearEnabled = true;
        bool coaRepeatEnabled = true;
        bool coaFirstClearResetsWithWindow = true;
        uint32 coaTokenCap = 1000;
        uint32 coaTokenWindowSeconds = 86400;
        ManastormClientMode clientMode = ManastormClientMode::Ascension;
        bool followReleaseStage = false;
        bool objectiveRaidSkull = true;
        bool nativeObjectiveHighlight = false;
    }

    void Load(bool reload)
    {
        bool const requestedEnabled = sConfigMgr->GetOption<bool>("Manastorm.Enable", true);
        bool const requestedCoALootMode = sConfigMgr->GetOption<bool>("Manastorm.CoALootMode.Enabled", false) &&
            AscensionFreepick::ReadRealm().ConquestOfAzeroth;
        if (!reload)
            coaLootModeEnabled = requestedCoALootMode;
        else if (requestedCoALootMode != coaLootModeEnabled)
            LOG_WARN("module.manastorm.endless", "Manastorm.CoALootMode.Enabled changes require a restart.");
        coaFirstClearEnabled = sConfigMgr->GetOption<bool>("Manastorm.CoALootMode.FirstClear.Enabled", true);
        coaRepeatEnabled = sConfigMgr->GetOption<bool>("Manastorm.CoALootMode.Repeat.Enabled", true);
        coaFirstClearResetsWithWindow =
            sConfigMgr->GetOption<bool>("Manastorm.CoALootMode.FirstClear.ResetWithWindow", true);
        coaTokenCap = std::clamp(sConfigMgr->GetOption<int32>("Manastorm.CoALootMode.TokenCap", 1000), 0, 1000000);
        coaTokenWindowSeconds = uint32(std::clamp(
            sConfigMgr->GetOption<int32>("Manastorm.CoALootMode.WindowHours", 24), 1, 168)) * 3600;
        weeklyCacheLockoutEnabled = sConfigMgr->GetOption<bool>("Manastorm.WeeklyCacheLockout.Enabled", true);
        int32 const requestedLimit = sConfigMgr->GetOption<int32>("Manastorm.WeeklyCacheLockout.Limit", 5);
        weeklyCacheLockoutLimit = requestedLimit >= 0 && requestedLimit <= 255 ? uint32(requestedLimit) : 5;
        if (requestedLimit < 0 || requestedLimit > 255)
            LOG_ERROR("module.manastorm.endless", "Invalid Manastorm.WeeklyCacheLockout.Limit={}; "
                "expected 0..255, using 5.", requestedLimit);
        float const requestedRate =
            sConfigMgr->GetOption<float>("Manastorm.ExperienceRate", float(DefaultExperienceRate));
        bool const validRate = std::isfinite(requestedRate) && requestedRate >= 0.0f;
        experienceRate = validRate ? double(requestedRate) : DefaultExperienceRate;
        if (!validRate)
            LOG_ERROR("module.manastorm.endless", "Invalid Manastorm.ExperienceRate={}; expected 0 or more, using {}.",
                requestedRate, DefaultExperienceRate);
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

    bool CoALootModeEnabled() { return coaLootModeEnabled; }
    bool CoAFirstClearEnabled() { return coaFirstClearEnabled; }
    bool CoARepeatEnabled() { return coaRepeatEnabled; }
    bool CoAFirstClearResetsWithWindow() { return coaFirstClearResetsWithWindow; }
    uint32 CoATokenCap() { return coaTokenCap; }
    uint32 CoATokenWindowSeconds() { return coaTokenWindowSeconds; }

    uint32 WeeklyCacheLockoutLimit()
    {
        return weeklyCacheLockoutLimit;
    }

    uint8 AffixMinimumLevel()
    {
        return affixMinimumLevel;
    }

    double ExperienceRate() { return experienceRate; }

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
