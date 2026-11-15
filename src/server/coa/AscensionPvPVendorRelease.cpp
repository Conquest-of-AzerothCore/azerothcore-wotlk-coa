/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionPvPVendorRelease.h"
#include "Config.h"
#include "GameEventMgr.h"
#include "ScriptMgr.h"

namespace
{
void ApplyReleasedStage()
{
    uint32 const releasedStage = sConfigMgr->GetOption<uint32>("Ascension.PvPVendors.ReleaseStage",
        PvPVendorRelease::DefaultStage);
    for (PvPVendorRelease::VendorEvent const& vendorEvent : PvPVendorRelease::VendorEvents)
    {
        bool const released = PvPVendorRelease::IsReleased(vendorEvent, releasedStage);
        if (sGameEventMgr->IsActiveEvent(vendorEvent.eventId) == released)
            continue;
        if (released)
            sGameEventMgr->StartInternalEvent(vendorEvent.eventId);
        else
            sGameEventMgr->StopEvent(vendorEvent.eventId, true);
    }
}

class ascension_pvp_vendor_release : public WorldScript
{
public:
    ascension_pvp_vendor_release()
        : WorldScript("ascension_pvp_vendor_release", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        ApplyReleasedStage();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            ApplyReleasedStage();
    }
};
}

void AddSC_AscensionPvPVendorRelease()
{
    new ascension_pvp_vendor_release();
}
