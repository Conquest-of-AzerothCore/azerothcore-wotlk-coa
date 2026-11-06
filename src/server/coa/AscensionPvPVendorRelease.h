#ifndef COA_ASCENSION_PVP_VENDOR_RELEASE_H
#define COA_ASCENSION_PVP_VENDOR_RELEASE_H

#include <array>
#include <cstdint>

namespace PvPVendorRelease
{
constexpr std::uint32_t StagePhaseOne = 1;
constexpr std::uint32_t StagePhaseTwo = 2;
constexpr std::uint32_t DefaultStage = StagePhaseOne;

constexpr std::uint16_t PhaseOneVendorsEvent = 197;
constexpr std::uint16_t PhaseTwoVendorsEvent = 198;

struct VendorEvent
{
    std::uint16_t eventId;
    std::uint32_t stage;
};

constexpr std::array<VendorEvent, 2> VendorEvents = {{
    { PhaseOneVendorsEvent, StagePhaseOne },
    { PhaseTwoVendorsEvent, StagePhaseTwo }
}};

constexpr bool IsReleased(VendorEvent const& vendorEvent, std::uint32_t releasedStage)
{
    return vendorEvent.stage <= releasedStage;
}

constexpr bool IsEventReleased(std::uint16_t eventId, std::uint32_t releasedStage)
{
    for (VendorEvent const& vendorEvent : VendorEvents)
        if (vendorEvent.eventId == eventId)
            return IsReleased(vendorEvent, releasedStage);
    return false;
}
}

#endif
