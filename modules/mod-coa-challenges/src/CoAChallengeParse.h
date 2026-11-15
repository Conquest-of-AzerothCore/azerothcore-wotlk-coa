/*
 * mod-coa-challenges: pure parsing/matching helpers (no core dependencies).
 *
 * Extracted so they can be unit-tested without a Player/DB. The generated
 * config encodes lists as "TYPE:V1/V2/V3;TYPE:V1/V2/V3;...".
 */
#ifndef MOD_COA_CHALLENGES_PARSE_H
#define MOD_COA_CHALLENGES_PARSE_H

#include <cstdint>
#include <string>
#include <vector>

namespace CoAParse
{
    struct Entry
    {
        std::string type; // enum name, e.g. CHALLENGE_REQUIREMENT_TYPE_...
        uint32_t v1 = 0;
        uint32_t v2 = 0;
        uint32_t v3 = 0;
        std::string key;  // raw "TYPE:V1/V2/V3" token (stable per-character id)
    };

    inline std::vector<std::string> Split(std::string const& list, char sep)
    {
        std::vector<std::string> out;
        size_t start = 0;
        while (start <= list.size())
        {
            size_t end = list.find(sep, start);
            if (end == std::string::npos)
                end = list.size();
            if (end > start)
                out.push_back(list.substr(start, end - start));
            if (end == list.size())
                break;
            start = end + 1;
        }
        return out;
    }

    // Strict unsigned parse: rejects sign, partial ("12abc") and overflow.
    // std::stoul would accept "-1" (wrapping to ULONG_MAX) and stop at the first
    // non-digit, silently corrupting definition values.
    inline uint32_t ToU32(std::string const& s)
    {
        if (s.empty())
            return 0;
        uint64_t value = 0;
        for (char c : s)
        {
            if (c < '0' || c > '9')
                return 0;
            value = value * 10 + uint64_t(c - '0');
            if (value > 0xFFFFFFFFull)
                return 0;
        }
        return static_cast<uint32_t>(value);
    }

    // Split preserving empty fields: "1//3" must keep the middle slot empty so
    // values stay aligned with V1/V2/V3 (Split drops empties and would shift).
    inline std::vector<std::string> SplitKeepEmpty(std::string const& list, char sep)
    {
        std::vector<std::string> out;
        size_t start = 0;
        while (true)
        {
            size_t end = list.find(sep, start);
            if (end == std::string::npos)
            {
                out.push_back(list.substr(start));
                break;
            }
            out.push_back(list.substr(start, end - start));
            start = end + 1;
        }
        return out;
    }

    // Parse a "TYPE:V1/V2/V3;..." list. Tokens without a ':' keep type = token.
    inline std::vector<Entry> ParseEntries(std::string const& list)
    {
        std::vector<Entry> out;
        for (std::string const& token : Split(list, ';'))
        {
            Entry e;
            e.key = token;
            size_t colon = token.find(':');
            e.type = (colon == std::string::npos) ? token : token.substr(0, colon);
            if (colon != std::string::npos)
            {
                std::vector<std::string> vals = SplitKeepEmpty(token.substr(colon + 1), '/');
                if (vals.size() > 0) e.v1 = ToU32(vals[0]);
                if (vals.size() > 1) e.v2 = ToU32(vals[1]);
                if (vals.size() > 2) e.v3 = ToU32(vals[2]);
            }
            out.push_back(e);
        }
        return out;
    }

    // Objectives tracked by the module (level-restricted). DUO/TRIO are static
    // party-size gates: they have no event/level (V1..V3 = 0/0/0), the party
    // size is enforced by CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE at activation,
    // and they are recorded as done right after a successful activation so the
    // client shows them as met criteria and completion accounts for them.
    inline bool IsTrackedObjective(std::string const& type)
    {
        return type == "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL"
            || type == "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL"
            || type == "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL"
            || type == "CHALLENGE_REQUIREMENT_TYPE_EARN_MONEY_BEFORE_LEVEL"
            || type == "CHALLENGE_REQUIREMENT_TYPE_DUO"
            || type == "CHALLENGE_REQUIREMENT_TYPE_TRIO";
    }

    inline bool IsCountedLootObjective(std::string const& type)
    {
        return type == "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL";
    }

    inline uint32_t ObjectiveTarget(Entry const& e)
    {
        return IsCountedLootObjective(e.type) ? e.v2 : e.v1;
    }

    inline uint32_t ObjectiveGateLevel(Entry const& e)
    {
        return IsCountedLootObjective(e.type) ? e.v3 : e.v2;
    }

    // Client-side CHALLENGE_REQUIREMENT_TYPE_* enum order, recovered from the
    // reflection table in Extensions.dll: the static {name,len} pointer array
    // sits contiguously at file 0xB30A60 (RVA 0xB31C60) and the 0x59A criteria
    // handler (RVA 0x137030) indexes it directly with the u32 at wire+0xc.
    // Order below is table order, not alphabetical. Unknown -> 0 (NONE).
    inline uint32_t RequirementTypeIndex(std::string const& type)
    {
        static char const* const kTypes[] =
        {
            "CHALLENGE_REQUIREMENT_TYPE_NONE",                                    // 0
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEFORE_LEVEL",             // 1
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_WITHIN_TIME",                    // 2
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_WITHOUT_DEATH",                  // 3
            "CHALLENGE_REQUIREMENT_TYPE_DUO",                                     // 4
            "CHALLENGE_REQUIREMENT_TYPE_TRIO",                                    // 5
            "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_BEFORE_LEVEL",              // 6
            "CHALLENGE_REQUIREMENT_TYPE_EARN_MONEY_BEFORE_LEVEL",                 // 7
            "CHALLENGE_REQUIREMENT_TYPE_FALL_WITHOUT_DYING",                      // 8
            "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_BEFORE_LEVEL",                  // 9
            "CHALLENGE_REQUIREMENT_TYPE_CREATE_ITEM_BEFORE_LEVEL",                // 10
            "CHALLENGE_REQUIREMENT_TYPE_REACH_REPUTATION_BEFORE_LEVEL",           // 11
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_NUM_QUESTS_BEFORE_LEVEL",        // 12
            "CHALLENGE_REQUIREMENT_TYPE_KILL_NUM_CREATURES_BEFORE_LEVEL",         // 13
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_NUM_QUESTS_IN_ZONE_BEFORE_LEVEL",// 14
            "CHALLENGE_REQUIREMENT_TYPE_KILL_CREATURE_WITHIN_TIME",               // 15
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_WITHIN_TIME",              // 16
            "CHALLENGE_REQUIREMENT_TYPE_LOOT_ITEM_WITHIN_TIME",                   // 17
            "CHALLENGE_REQUIREMENT_TYPE_CREATE_ITEM_WITHIN_TIME",                 // 18
            "CHALLENGE_REQUIREMENT_TYPE_KILL_NUM_CREATURES_WITHIN_TIME",          // 19
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_NUM_QUESTS_WITHIN_TIME",         // 20
            "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_NUM_QUESTS_IN_ZONE_WITHIN_TIME", // 21
            "CHALLENGE_REQUIREMENT_TYPE_REACH_REPUTATION_WITHIN_TIME",            // 22
        };
        for (uint32_t i = 0; i < sizeof(kTypes) / sizeof(kTypes[0]); ++i)
            if (type == kTypes[i])
                return i;
        return 0;
    }

    inline constexpr uint8_t LevelScalingBlockCreature = 0x1;
    inline constexpr uint8_t LevelScalingBlockQuest = 0x2;

    inline constexpr char const* LevelScalingRules[] =
    {
        "CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING",
        "CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING",
        "CHALLENGE_RULES_TYPE_NO_PLAYER_LEVEL_SCALING",
    };

    inline uint8_t LevelScalingBlockBits(std::string const& rule)
    {
        if (rule == "CHALLENGE_RULES_TYPE_NO_CREATURE_LEVEL_SCALING")
            return LevelScalingBlockCreature;
        if (rule == "CHALLENGE_RULES_TYPE_NO_QUEST_LEVEL_SCALING")
            return LevelScalingBlockQuest;
        if (rule == "CHALLENGE_RULES_TYPE_NO_PLAYER_LEVEL_SCALING")
            return LevelScalingBlockCreature | LevelScalingBlockQuest;
        return 0;
    }

    // Exact membership test on a "A;B;C" list (no substring false positives).
    inline bool ListContains(std::string const& list, std::string const& value)
    {
        for (std::string const& item : Split(list, ';'))
            if (item == value)
                return true;
        return false;
    }
}

#endif
