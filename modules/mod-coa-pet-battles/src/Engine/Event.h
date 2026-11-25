#ifndef COA_PET_BATTLE_ENGINE_EVENT_H
#define COA_PET_BATTLE_ENGINE_EVENT_H

#include <map>
#include <string>
#include <variant>

namespace CoAPetBattles::Engine
{
    using Value = std::variant<double, std::string, bool>;

    struct Event
    {
        std::string kind;
        std::map<std::string, Value> fields;

        std::string Canonical() const;
        bool Has(std::string const& key) const { return fields.count(key) != 0; }
        double Number(std::string const& key) const;
        std::string Text(std::string const& key) const;
        bool Flag(std::string const& key) const;
    };

    std::string EscapeField(std::string const& text);
    std::string ValueText(Value const& value);
}

#endif
