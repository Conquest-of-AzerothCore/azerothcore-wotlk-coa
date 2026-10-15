/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayIsolation.h"
#include "Util.h"
#include "utf8.h"
#include <stdexcept>

namespace CoAGameplay
{
    namespace
    {
        constexpr uint32 LastConcurrentLanePhase = 1u << (FirstConcurrentLaneBit + MaxLanes - 2);
        static_assert(LastConcurrentLanePhase < FixturePhaseMask);

        constexpr std::string_view LegacyNameStem = "Harness";
        constexpr char FirstLegacyActor = 'a';
        constexpr char LastLegacyActor = 'h';

        constexpr uint32 FirstCombiningMark = 0x0300;
        constexpr uint32 LastCombiningMark = 0x036F;
        constexpr uint32 LastBasicMultilingualCodePoint = 0xFFFF;

        bool IsWordCodePoint(uint32 codePoint)
        {
            if (codePoint >= FirstCombiningMark && codePoint <= LastCombiningMark)
                return true;
            if (codePoint > LastBasicMultilingualCodePoint)
                return false;

            wchar_t const character = static_cast<wchar_t>(codePoint);
            return character == L'_' || isNumeric(character) || isExtendedLatinCharacter(character) ||
                isCyrillicCharacter(character) || isEastAsianCharacter(character);
        }

        bool IsWordCharacterAt(std::string_view text, std::size_t position)
        {
            if (position >= text.size())
                return false;

            auto next = text.begin() + position;
            try
            {
                return IsWordCodePoint(utf8::next(next, text.end()));
            }
            catch (utf8::exception const&)
            {
                return true;
            }
        }

        bool IsWordCharacterBefore(std::string_view text, std::size_t position)
        {
            if (position == 0)
                return false;

            auto const end = text.begin() + position;
            auto lead = end;
            try
            {
                utf8::prior(lead, text.begin());
                uint32 const codePoint = utf8::next(lead, end);
                return lead != end || IsWordCodePoint(codePoint);
            }
            catch (utf8::exception const&)
            {
                return true;
            }
        }

        bool IsLegacyActor(char c)
        {
            return c >= FirstLegacyActor && c <= LastLegacyActor;
        }
    }

    uint32 LanePhase(uint32 lane)
    {
        if (lane >= MaxLanes)
            throw std::out_of_range("Gameplay lane " + std::to_string(lane) + " is outside 0.." +
                std::to_string(MaxLanes - 1));
        if (lane == 0)
            return FixturePhaseMask;
        return 1u << (FirstConcurrentLaneBit + lane - 1);
    }

    uint32 LanePhases(uint32 lanes)
    {
        uint32 phases = 0;
        for (uint32 lane = 0; lane < lanes; ++lane)
            phases |= LanePhase(lane);
        return phases;
    }

    std::string GeneratedName(uint64 index)
    {
        if (index >= GeneratedNameCapacity)
            throw std::out_of_range("Generated character name " + std::to_string(index) + " exceeds the capacity " +
                std::to_string(GeneratedNameCapacity));

        std::string name(GeneratedNamePrefix);
        name.resize(GeneratedNameLength);
        for (std::size_t position = GeneratedNameLength; position-- > GeneratedNamePrefix.size();)
        {
            std::string_view const letters = GeneratedNameLetters(position);
            name[position] = letters[index % letters.size()];
            index /= letters.size();
        }
        return name;
    }

    std::string NameAllocator::Next()
    {
        return GeneratedName(_next++);
    }

    std::string SubstituteLegacyNames(std::string_view text, std::map<char, std::string> const& names)
    {
        std::string result;
        result.reserve(text.size());
        std::size_t copied = 0;
        std::size_t search = 0;
        for (std::size_t found; (found = text.find(LegacyNameStem, search)) != std::string_view::npos;)
        {
            std::size_t const actor = found + LegacyNameStem.size();
            search = found + 1;
            if (actor >= text.size() || !IsLegacyActor(text[actor]))
                continue;
            if (IsWordCharacterBefore(text, found) || IsWordCharacterAt(text, actor + 1))
                continue;

            auto const name = names.find(text[actor]);
            if (name == names.end())
                continue;

            result.append(text.substr(copied, found - copied));
            result.append(name->second);
            copied = search = actor + 1;
        }
        result.append(text.substr(copied));
        return result;
    }
}
