/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayClock.h"
#include <algorithm>

namespace CoAGameplay
{
    namespace
    {
        Milliseconds BoundedWait(Milliseconds remaining, Milliseconds cap)
        {
            return std::max(MinimumStep, std::min(remaining, cap));
        }

        Milliseconds ActivityStep(StepRequest const& request, ClockPolicy const& policy)
        {
            switch (request.activity)
            {
                case LaneActivity::Waiting:
                    if (request.remaining > Milliseconds::zero())
                        return BoundedWait(request.remaining, policy.activeWaitCap);
                    return policy.step;
                case LaneActivity::Polling:
                    return BoundedWait(request.remaining, policy.pollCap);
                case LaneActivity::Unconstrained:
                case LaneActivity::Stepping:
                    break;
            }
            return policy.step;
        }

        Milliseconds LaneStep(StepRequest const& request, ClockPolicy const& policy)
        {
            Milliseconds step = ActivityStep(request, policy);
            if (!request.databaseQuiet)
                step = std::min(step, policy.step);
            if (request.caseCap > Milliseconds::zero())
                step = std::min(step, request.caseCap);
            return step;
        }
    }

    std::optional<Milliseconds> ChooseStep(std::span<StepRequest const> requests, ClockPolicy const& policy)
    {
        std::optional<Milliseconds> chosen;
        for (StepRequest const& request : requests)
        {
            if (request.activity == LaneActivity::Unconstrained)
                continue;

            Milliseconds const step = LaneStep(request, policy);
            if (!chosen || step < *chosen)
                chosen = step;
        }

        if (chosen)
            chosen = std::clamp(*chosen, MinimumStep, MaximumStep);
        return chosen;
    }
}
