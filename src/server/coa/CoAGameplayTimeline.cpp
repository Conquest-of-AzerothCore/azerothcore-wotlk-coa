/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayTimeline.h"
#include <algorithm>

namespace CoAGameplay
{
    namespace
    {
        bool Contains(std::vector<ObjectGuid> const& guids, ObjectGuid guid)
        {
            return std::find(guids.begin(), guids.end(), guid) != guids.end();
        }
    }

    bool RecordsUnit(uint32 encounterMapId, uint32 encounterInstanceId, uint32 unitMapId, uint32 unitInstanceId)
    {
        return encounterMapId == unitMapId && encounterInstanceId == unitInstanceId;
    }

    void Timeline::Start(uint64 nowMs)
    {
        _started = true;
        _startMs = nowMs;
        _engagedAtMs.reset();
        _events.clear();
    }

    bool Timeline::Started() const
    {
        return _started;
    }

    void Timeline::Record(TimelineEvent event)
    {
        if (!_started || event.atMs < _startMs)
            return;

        event.atMs -= _startMs;
        _events.push_back(event);
    }

    void Timeline::MarkEngaged(uint64 nowMs)
    {
        if (!_started || _engagedAtMs)
            return;

        _engagedAtMs = nowMs > _startMs ? nowMs - _startMs : 0;
    }

    std::vector<TimelineEvent> const& Timeline::Events() const
    {
        return _events;
    }

    bool Timeline::Matches(TimelineEvent const& event, TimelineFilter const& filter) const
    {
        if (event.kind != filter.kind)
            return false;
        if (filter.spell && event.spell != *filter.spell)
            return false;
        if (filter.sourceEntry && event.sourceEntry != *filter.sourceEntry)
            return false;
        if (filter.value && event.value != *filter.value)
            return false;
        if (!filter.targets.empty() && !Contains(filter.targets, event.target))
            return false;
        return !Contains(filter.excludedTargets, event.target);
    }

    uint32 Timeline::Count(TimelineFilter const& filter) const
    {
        return static_cast<uint32>(std::count_if(_events.begin(), _events.end(),
            [&](TimelineEvent const& event) { return Matches(event, filter); }));
    }

    std::optional<int64> Timeline::FirstMs(TimelineFilter const& filter) const
    {
        auto const first = std::find_if(_events.begin(), _events.end(),
            [&](TimelineEvent const& event) { return Matches(event, filter); });
        if (first == _events.end())
            return std::nullopt;

        return static_cast<int64>(first->atMs) - static_cast<int64>(_engagedAtMs.value_or(0));
    }

    std::vector<uint64> Timeline::Intervals(TimelineFilter const& filter) const
    {
        std::vector<uint64> intervals;
        std::optional<uint64> previous;
        for (TimelineEvent const& event : _events)
        {
            if (!Matches(event, filter))
                continue;
            if (previous)
                intervals.push_back(event.atMs - *previous);
            previous = event.atMs;
        }
        return intervals;
    }
}
