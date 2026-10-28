/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_CLOCK_H
#define COA_GAMEPLAY_CLOCK_H

#include "Duration.h"
#include <optional>
#include <span>

namespace CoAGameplay
{
    inline constexpr Milliseconds MinimumStep{1};
    inline constexpr Milliseconds MaximumStep{2000};

    struct ClockPolicy
    {
        Milliseconds step{3};
        Milliseconds activeWaitCap{25};
        Milliseconds pollCap{10};
    };

    enum class LaneActivity
    {
        Unconstrained,
        Stepping,
        Waiting,
        Polling
    };

    struct StepRequest
    {
        LaneActivity activity{LaneActivity::Unconstrained};
        Milliseconds remaining{0};
        Milliseconds caseCap{0};
        bool databaseQuiet{true};
    };

    std::optional<Milliseconds> ChooseStep(std::span<StepRequest const> requests, ClockPolicy const& policy);
}

#endif
