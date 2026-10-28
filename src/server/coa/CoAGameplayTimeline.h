/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_GAMEPLAY_TIMELINE_H
#define COA_GAMEPLAY_TIMELINE_H

#include "Define.h"
#include "ObjectGuid.h"
#include <optional>
#include <vector>

namespace CoAGameplay
{
    enum class TimelineEventKind : uint8
    {
        Cast,
        AuraApplied,
        AuraRemoved,
        Death,
        EnterCombat,
        Evade,
        Spawn,
        BossState
    };

    struct TimelineEvent
    {
        uint64 atMs{0};
        TimelineEventKind kind{TimelineEventKind::Cast};
        ObjectGuid source;
        ObjectGuid target;
        uint32 sourceEntry{0};
        uint32 spell{0};
        uint32 value{0};
    };

    struct TimelineFilter
    {
        TimelineEventKind kind{TimelineEventKind::Cast};
        std::optional<uint32> spell;
        std::optional<uint32> sourceEntry;
        std::optional<uint32> value;
        std::vector<ObjectGuid> targets;
        std::vector<ObjectGuid> excludedTargets;
    };

    bool RecordsUnit(uint32 encounterMapId, uint32 encounterInstanceId, uint32 unitMapId, uint32 unitInstanceId);

    class Timeline
    {
    public:
        void Start(uint64 nowMs);
        bool Started() const;
        void Record(TimelineEvent event);
        void MarkEngaged(uint64 nowMs);
        std::vector<TimelineEvent> const& Events() const;
        uint32 Count(TimelineFilter const& filter) const;
        std::optional<int64> FirstMs(TimelineFilter const& filter) const;
        std::vector<uint64> Intervals(TimelineFilter const& filter) const;

    private:
        bool Matches(TimelineEvent const& event, TimelineFilter const& filter) const;

        bool _started{false};
        uint64 _startMs{0};
        std::optional<uint64> _engagedAtMs;
        std::vector<TimelineEvent> _events;
    };
}

#endif
