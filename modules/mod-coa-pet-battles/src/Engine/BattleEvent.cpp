#include "BattleEvent.h"
#include "LuaNumber.h"

namespace CoAPetBattles::Engine
{
    std::string EscapeField(std::string const& text)
    {
        std::string escaped;
        escaped.reserve(text.size());
        for (char c : text)
        {
            if (c == '\\')
                escaped += "\\\\";
            else if (c == '\t')
                escaped += "\\t";
            else if (c == '\n')
                escaped += "\\n";
            else
                escaped += c;
        }
        return escaped;
    }

    std::string ValueText(Value const& value)
    {
        if (bool const* flag = std::get_if<bool>(&value))
            return *flag ? "true" : "false";
        if (double const* number = std::get_if<double>(&value))
            return LuaNumber(*number);
        return EscapeField(std::get<std::string>(value));
    }

    std::string Event::Canonical() const
    {
        std::string text = "k=" + EscapeField(kind);
        for (auto const& [key, value] : fields)
            text += "\t" + key + "=" + ValueText(value);
        return text;
    }

    double Event::Number(std::string const& key) const
    {
        auto const found = fields.find(key);
        if (found == fields.end())
            return 0.0;
        if (double const* number = std::get_if<double>(&found->second))
            return *number;
        return 0.0;
    }

    std::string Event::Text(std::string const& key) const
    {
        auto const found = fields.find(key);
        if (found == fields.end())
            return {};
        if (std::string const* text = std::get_if<std::string>(&found->second))
            return *text;
        return ValueText(found->second);
    }

    bool Event::Flag(std::string const& key) const
    {
        auto const found = fields.find(key);
        if (found == fields.end())
            return false;
        if (bool const* flag = std::get_if<bool>(&found->second))
            return *flag;
        return true;
    }
}
