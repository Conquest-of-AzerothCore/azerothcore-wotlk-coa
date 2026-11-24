#include "AddonMessage.h"

namespace CoAPetBattles::Protocol
{
    namespace
    {
        bool WordChar(char c)
        {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
        }

        size_t Word(std::string_view text, size_t from)
        {
            size_t end = from;
            while (end < text.size() && WordChar(text[end]))
                ++end;
            return end;
        }
    }

    std::optional<AddonMessage> ParseAddonMessage(std::string_view text)
    {
        if (text.size() > MaxReceived)
            return std::nullopt;
        size_t const moduleEnd = Word(text, 0);
        if (moduleEnd == 0 || moduleEnd >= text.size() || text[moduleEnd] != '|')
            return std::nullopt;
        size_t const actionEnd = Word(text, moduleEnd + 1);
        if (actionEnd == moduleEnd + 1)
            return std::nullopt;
        size_t payloadStart = actionEnd;
        if (payloadStart < text.size() && text[payloadStart] == '|')
            ++payloadStart;
        return AddonMessage { std::string(text.substr(0, moduleEnd)),
            std::string(text.substr(moduleEnd + 1, actionEnd - moduleEnd - 1)), std::string(text.substr(payloadStart)) };
    }

    std::optional<std::string> FormatAddonMessage(std::string_view module, std::string_view action,
        std::string_view payload)
    {
        std::string text;
        text.reserve(module.size() + action.size() + payload.size() + 2);
        text.append(module).append("|").append(action).append("|").append(payload);
        if (text.size() > MaxSent)
            return std::nullopt;
        return text;
    }

    std::vector<std::string> Chunks(std::vector<std::string> const& parts)
    {
        std::vector<std::string> chunks;
        for (size_t i = 0; i < parts.size(); ++i)
            chunks.push_back(std::to_string(i + 1) + "/" + std::to_string(parts.size()) + ";" + parts[i]);
        return chunks;
    }

    void AddonPeers::Hello(uint64_t character, std::string_view payload)
    {
        std::set<std::string, std::less<>> names;
        size_t at = 0;
        while (at < payload.size())
        {
            if (!WordChar(payload[at]))
            {
                ++at;
                continue;
            }
            size_t const end = Word(payload, at);
            names.emplace(payload.substr(at, end - at));
            at = end;
        }
        _addons[character] = std::move(names);
    }

    void AddonPeers::Forget(uint64_t character)
    {
        _addons.erase(character);
    }

    bool AddonPeers::Has(uint64_t character, std::string_view addon) const
    {
        auto const found = _addons.find(character);
        return found != _addons.end() && found->second.find(addon) != found->second.end();
    }
}
