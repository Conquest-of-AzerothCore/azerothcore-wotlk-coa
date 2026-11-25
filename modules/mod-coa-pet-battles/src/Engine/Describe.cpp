#include "Describe.h"
#include "LuaNumber.h"
#include "Rules.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>

namespace CoAPetBattles::Engine
{
    namespace
    {
        bool IsSpace(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r'; }
        bool IsDigit(char c) { return c >= '0' && c <= '9'; }
        bool IsAlpha(char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'); }
        bool IsAlnum(char c) { return IsAlpha(c) || IsDigit(c); }
        bool IsHex(char c) { return IsDigit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'); }

        std::string Lower(std::string text)
        {
            for (char& c : text)
                if (c >= 'A' && c <= 'Z')
                    c = static_cast<char>(c - 'A' + 'a');
            return text;
        }

        std::string Trim(std::string const& text)
        {
            size_t begin = 0;
            size_t end = text.size();
            while (begin < end && IsSpace(text[begin]))
                ++begin;
            while (end > begin && IsSpace(text[end - 1]))
                --end;
            return text.substr(begin, end - begin);
        }

        class ExpressionParser
        {
        public:
            explicit ExpressionParser(std::string const& text) : _text(text) { }

            std::optional<double> Parse()
            {
                std::optional<double> value = Expression();
                Skip();
                if (!value || _failed || _pos < _text.size())
                    return std::nullopt;
                return value;
            }

        private:
            void Skip()
            {
                while (_pos < _text.size() && _text[_pos] == ' ')
                    ++_pos;
                if (_pos + 1 < _text.size() && _text[_pos] == '-' && _text[_pos + 1] == '-')
                    _pos = _text.size();
            }

            bool Peek(char c)
            {
                Skip();
                return _pos < _text.size() && _text[_pos] == c;
            }

            std::optional<double> Expression()
            {
                std::optional<double> value = Term();
                while (value)
                {
                    if (Peek('+'))
                    {
                        ++_pos;
                        std::optional<double> right = Term();
                        if (!right)
                            return std::nullopt;
                        value = *value + *right;
                    }
                    else if (Peek('-'))
                    {
                        ++_pos;
                        std::optional<double> right = Term();
                        if (!right)
                            return std::nullopt;
                        value = *value - *right;
                    }
                    else
                        break;
                }
                return value;
            }

            std::optional<double> Term()
            {
                std::optional<double> value = Unary();
                while (value)
                {
                    if (Peek('*'))
                    {
                        ++_pos;
                        std::optional<double> right = Unary();
                        if (!right)
                            return std::nullopt;
                        value = *value * *right;
                    }
                    else if (Peek('/'))
                    {
                        ++_pos;
                        std::optional<double> right = Unary();
                        if (!right)
                            return std::nullopt;
                        value = *value / *right;
                    }
                    else
                        break;
                }
                return value;
            }

            std::optional<double> Unary()
            {
                if (Peek('-'))
                {
                    ++_pos;
                    std::optional<double> value = Unary();
                    return value ? std::optional<double>(-*value) : std::nullopt;
                }
                return Primary();
            }

            std::optional<double> Primary()
            {
                Skip();
                if (_pos >= _text.size())
                    return std::nullopt;
                if (_text[_pos] == '(')
                {
                    ++_pos;
                    std::optional<double> value = Expression();
                    if (!value || !Peek(')'))
                        return std::nullopt;
                    ++_pos;
                    return value;
                }
                char const c = _text[_pos];
                if (!IsDigit(c) && !(c == '.' && _pos + 1 < _text.size() && IsDigit(_text[_pos + 1])))
                    return std::nullopt;
                size_t const start = _pos;
                while (_pos < _text.size() && (IsDigit(_text[_pos]) || _text[_pos] == '.'))
                    ++_pos;
                std::string const token = _text.substr(start, _pos - start);
                char* end = nullptr;
                double const value = std::strtod(token.c_str(), &end);
                if (end != token.c_str() + token.size())
                {
                    _failed = true;
                    return std::nullopt;
                }
                return value;
            }

            std::string const& _text;
            size_t _pos = 0;
            bool _failed = false;
        };

        struct FoundFx
        {
            std::optional<uint16_t> prop;
            std::array<double, 6> p { 0, 100, 0, 0, 0, 0 };
        };

        std::optional<size_t> LuaIndex(double index, size_t size)
        {
            if (index < 1 || index != std::floor(index) || index > static_cast<double>(size))
                return std::nullopt;
            return static_cast<size_t>(index) - 1;
        }

        class Resolver
        {
        public:
            Resolver(Catalog const& catalog, DescribeSource const& ability, double power, bool* fallback)
                : _catalog(catalog), _ability(ability), _power(power), _fallback(fallback) { }

            std::string Resolve(std::string const& expr)
            {
                std::string e = expr;
                int guard = 0;
                bool changed = false;
                do
                {
                    changed = ReplaceFirstCall(e);
                    ++guard;
                } while (changed && guard <= 20);
                if (std::optional<double> v = LuaArith(e))
                    return LuaNumber(std::floor(*v + 0.5));
                if (e.empty() || e.find_first_of("()?") != std::string::npos)
                    return "?";
                return e;
            }

        private:
            std::vector<Turn> const& Turns() const
            {
                static std::vector<Turn> const none;
                return _ability.turns ? *_ability.turns : none;
            }

            bool Reaches(std::vector<Turn> const* turns, double aura, int depth) const
            {
                if (depth > 3 || !turns)
                    return false;
                for (Turn const& turn : *turns)
                    for (Fx const& fx : turn.fx)
                    {
                        if (fx.aura == aura)
                            return true;
                        if (fx.aura != 0)
                        {
                            AbilityDef const* next = _catalog.Ability(fx.aura);
                            if (Reaches(next ? &next->turns : nullptr, aura, depth + 1))
                                return true;
                        }
                    }
                return false;
            }

            FoundFx Find(double t, double e, std::optional<double> aura) const
            {
                if (aura)
                {
                    bool applies = (_ability.id && static_cast<double>(*_ability.id) == *aura) ||
                        Reaches(&Turns(), *aura, 1);
                    for (Turn const& turn : Turns())
                        for (Fx const& fx : turn.fx)
                            if (fx.aura == *aura)
                                applies = true;
                    if (!applies)
                        for (Turn const& turn : Turns())
                            for (Fx const& fx : turn.fx)
                                if (!applies && fx.aura != 0 && _catalog.Ability(fx.aura))
                                {
                                    aura = static_cast<double>(fx.aura);
                                    applies = true;
                                }
                }
                std::vector<Turn> const* source = &Turns();
                if (aura && *aura >= 0 && *aura == std::floor(*aura))
                    if (AbilityDef const* def = _catalog.Ability(static_cast<uint32_t>(*aura)))
                        source = &def->turns;
                std::vector<Turn const*> main;
                for (Turn const& turn : *source)
                    if (turn.event == 255)
                        main.push_back(&turn);
                if (main.empty())
                    for (Turn const& turn : *source)
                        main.push_back(&turn);
                if (std::optional<size_t> ti = LuaIndex(t, main.size()))
                    if (std::optional<size_t> ei = LuaIndex(e, main[*ti]->fx.size()))
                    {
                        Fx const& fx = main[*ti]->fx[*ei];
                        return { fx.prop, fx.p };
                    }
                for (Turn const* turn : main)
                    for (Fx const& fx : turn->fx)
                        if (fx.p[0] != 0)
                            return { fx.prop, fx.p };
                return {};
            }

            static double Num(std::string const& text)
            {
                return LuaArith(text).value_or(0.0);
            }

            FoundFx FindArgs(std::vector<std::string> const& a) const
            {
                std::optional<double> aura;
                if (a.size() > 2)
                    aura = LuaToNumber(a[2]);
                return Find(Num(a.size() > 0 ? a[0] : ""), Num(a.size() > 1 ? a[1] : ""), aura);
            }

            std::optional<std::string> StateMod(std::vector<std::string> const& a) const
            {
                std::string const sid = a.size() > 0 ? a[0] : "";
                std::string key = sid.rfind("STATE_", 0) == 0 ? sid.substr(6) : sid;
                if (std::optional<double> n = LuaToNumber(sid))
                    if (std::string const* name = _catalog.StateName(*n))
                        key = *name;
                States const* st = nullptr;
                std::optional<double> stId = a.size() > 1 ? LuaToNumber(a[1]) : std::nullopt;
                double const lookup = stId.value_or(0);
                if (lookup >= 0 && lookup == std::floor(lookup))
                    st = _catalog.StatesOf(static_cast<uint32_t>(lookup));
                std::optional<double> v;
                if (st && st->count(key))
                    v = st->at(key);
                if (!v)
                    for (Turn const& turn : Turns())
                        for (Fx const& fx : turn.fx)
                            if (!v && fx.aura != 0)
                                if (States const* fs = _catalog.StatesOf(fx.aura); fs && fs->count(key))
                                    v = fs->at(key);
                if (!v && _ability.id)
                    if (States const* own = _catalog.StatesOf(*_ability.id); own && own->count(key))
                        v = own->at(key);
                if (!v && st && !st->empty())
                {
                    v = st->begin()->second;
                    if (_fallback)
                        *_fallback = true;
                }
                return LuaNumber(v.value_or(0));
            }

            std::optional<std::string> Call(std::string const& name, std::string const& args) const
            {
                std::vector<std::string> a;
                size_t start = 0;
                std::string const list = args + ",";
                for (size_t comma = list.find(','); comma != std::string::npos; comma = list.find(',', start))
                {
                    a.push_back(Trim(list.substr(start, comma - start)));
                    start = comma + 1;
                }
                std::string const lname = Lower(name);
                double const bonus = 1 + _power / 20;
                if (lname == "abs")
                    return LuaNumber(std::fabs(Num(a[0])));
                if (lname == "attackbonus")
                    return LuaNumber(bonus);
                if (lname == "abilitystatemod")
                    return StateMod(a);
                if (lname == "standarddamage" || lname == "simpledamage")
                    return LuaNumber(std::floor(FindArgs(a).p[0] * bonus + 0.5));
                if (lname == "standardhealing")
                    return LuaNumber(Heal(FindArgs(a).p[0], _power));
                if (lname == "formatdamage")
                    return LuaNumber(std::floor(Num(a[0]) + 0.5));
                if (lname == "standardaccuracy" || lname == "accuracy")
                {
                    FoundFx const fx = FindArgs(a);
                    return LuaNumber(fx.prop && *fx.prop == 172 ? fx.p[5] : fx.p[1]) + "%";
                }
                if (lname == "duration" || lname == "pointsincreaseperuse")
                    return LuaNumber(FindArgs(a).p[2]);
                if (lname == "statechange" || lname == "points" || lname == "percentage")
                    return LuaNumber(FindArgs(a).p[0]);
                if (lname == "pointsmax")
                    return LuaNumber(FindArgs(a).p[3]);
                if (lname == "numturns")
                {
                    std::optional<double> n = LuaToNumber(a[0]);
                    if (n && *n >= 0 && *n == std::floor(*n))
                        if (AbilityDef const* def = _catalog.Ability(static_cast<uint32_t>(*n)))
                            return LuaNumber(static_cast<double>(def->turns.size()));
                    return LuaNumber(static_cast<double>(Turns().size()));
                }
                if (lname == "school" || lname == "pettypename")
                    return FamilyAt(_ability.family + 1).value_or("Magic");
                if (lname == "abilitypettype")
                    return LuaNumber(_ability.family);
                if (lname == "getprocindex")
                    return "1";
                return std::nullopt;
            }

            bool ReplaceFirstCall(std::string& e) const
            {
                for (size_t i = 0; i < e.size(); ++i)
                {
                    if (!IsAlpha(e[i]) && e[i] != '_')
                        continue;
                    size_t j = i;
                    while (j < e.size() && (IsAlnum(e[j]) || e[j] == '_'))
                        ++j;
                    size_t k = j;
                    while (k < e.size() && IsSpace(e[k]))
                        ++k;
                    if (k >= e.size() || e[k] != '(')
                        continue;
                    size_t m = k + 1;
                    while (m < e.size() && e[m] != '(' && e[m] != ')')
                        ++m;
                    if (m >= e.size() || e[m] != ')')
                        continue;
                    std::optional<std::string> v = Call(e.substr(i, j - i), e.substr(k + 1, m - k - 1));
                    e = e.substr(0, i) + v.value_or("?") + e.substr(m + 1);
                    return true;
                }
                return false;
            }

            Catalog const& _catalog;
            DescribeSource const& _ability;
            double _power;
            bool* _fallback;
        };

        std::string RemoveCurrent(std::string const& text)
        {
            std::string const marker = "(Current: [";
            std::string out;
            size_t i = 0;
            while (i < text.size())
            {
                size_t k = i;
                while (k < text.size() && IsSpace(text[k]))
                    ++k;
                if (text.compare(k, marker.size(), marker) == 0)
                {
                    size_t const close = text.find(']', k + marker.size());
                    if (close != std::string::npos && close + 1 < text.size() && text[close + 1] == ')')
                    {
                        i = close + 2;
                        continue;
                    }
                }
                out += text[i++];
            }
            return out;
        }

        std::string ResolveBrackets(std::string const& text, Resolver& resolver)
        {
            std::string out;
            size_t i = 0;
            while (i < text.size())
            {
                if (text[i] == '[')
                {
                    size_t const close = text.find(']', i + 1);
                    if (close != std::string::npos)
                    {
                        out += resolver.Resolve(text.substr(i + 1, close - i - 1));
                        i = close + 1;
                        continue;
                    }
                }
                out += text[i++];
            }
            return out;
        }

        std::string RemoveColors(std::string const& text)
        {
            std::string first;
            for (size_t i = 0; i < text.size();)
            {
                if (text[i] == '|' && i + 1 < text.size() && text[i + 1] == 'c' && i + 10 <= text.size() &&
                    std::all_of(text.begin() + i + 2, text.begin() + i + 10, IsHex))
                {
                    i += 10;
                    continue;
                }
                first += text[i++];
            }
            std::string out;
            for (size_t i = 0; i < first.size();)
            {
                if (first[i] == '|' && i + 1 < first.size() && first[i + 1] == 'r')
                {
                    i += 2;
                    continue;
                }
                out += first[i++];
            }
            return out;
        }

        std::string Plurals(std::string const& text)
        {
            std::string out;
            size_t i = 0;
            while (i < text.size())
            {
                if (IsAlnum(text[i]))
                {
                    size_t j = i;
                    while (j < text.size() && IsAlnum(text[j]))
                        ++j;
                    if (text.compare(j, 3, " |4") == 0)
                    {
                        size_t a = j + 3;
                        size_t b = a;
                        while (b < text.size() && IsAlpha(text[b]))
                            ++b;
                        if (b > a && b < text.size() && text[b] == ':')
                        {
                            size_t c = b + 1;
                            size_t d = c;
                            while (d < text.size() && IsAlpha(text[d]))
                                ++d;
                            if (d > c)
                            {
                                std::string const n = text.substr(i, j - i);
                                std::optional<double> number = LuaToNumber(n);
                                bool const one = (number && *number == 1) || Lower(n) == "one";
                                out += n + " " + (one ? text.substr(a, b - a) : text.substr(c, d - c));
                                i = (d < text.size() && text[d] == ';') ? d + 1 : d;
                                continue;
                            }
                        }
                    }
                    out += text.substr(i, j - i);
                    i = j;
                    continue;
                }
                out += text[i++];
            }
            return out;
        }

        std::string Percents(std::string const& text)
        {
            std::string out;
            for (size_t i = 0; i < text.size();)
            {
                if (text[i] == '%' && i + 1 < text.size() && text[i + 1] == '%')
                {
                    out += '%';
                    i += 2;
                    continue;
                }
                out += text[i++];
            }
            return out;
        }

        std::string HitChance(std::string const& text)
        {
            std::string const tail = " Hit Chance";
            std::string out;
            size_t i = 0;
            while (i < text.size())
            {
                if (IsDigit(text[i]))
                {
                    size_t j = i;
                    while (j < text.size() && IsDigit(text[j]))
                        ++j;
                    if (j < text.size() && text[j] == '%' && text.compare(j + 1, tail.size(), tail) == 0)
                    {
                        size_t k = j + 1 + tail.size();
                        while (k < text.size() && IsSpace(text[k]))
                            ++k;
                        out += text.substr(i, j - i) + "% hit chance. ";
                        i = k;
                        continue;
                    }
                    out += text.substr(i, j - i);
                    i = j;
                    continue;
                }
                out += text[i++];
            }
            return out;
        }

        std::string CollapseSpaces(std::string const& text)
        {
            std::string out;
            for (size_t i = 0; i < text.size();)
            {
                if (IsSpace(text[i]))
                {
                    while (i < text.size() && IsSpace(text[i]))
                        ++i;
                    out += ' ';
                    continue;
                }
                out += text[i++];
            }
            return out;
        }

        std::map<std::string, std::string> const StateText = {
            { "untargettable", "Cannot be hit." }, { "Stat_Dodge", "Chance to dodge attacks." },
            { "Mechanic_IsStunned", "Stunned: cannot act." }, { "Mod_SpeedPercent", "Speed changed." },
            { "Mod_DamageTakenPercent", "Changes the damage taken." },
            { "Mod_DamageDealtPercent", "Changes the damage dealt." },
            { "Mod_HealingTakenPercent", "Changes the healing received." },
            { "Mod_HealingDealtPercent", "Changes the healing done." },
            { "Mechanic_IsBleeding", "Bleeding: takes damage every round." },
            { "Mechanic_IsBurning", "Burning: takes damage every round." },
            { "Mechanic_IsPoisoned", "Poisoned: takes damage every round." },
            { "Add_FlatDamageTaken", "Changes the damage of every attack against it." },
            { "Stat_Accuracy", "Changes hit chance." },
        };
    }

    std::optional<double> LuaToNumber(std::string const& text)
    {
        char const* start = text.c_str();
        char* end = nullptr;
        double const value = std::strtod(start, &end);
        if (end == start)
            return std::nullopt;
        while (*end && IsSpace(*end))
            ++end;
        if (*end)
            return std::nullopt;
        return value;
    }

    std::optional<double> LuaArith(std::string const& text)
    {
        bool const arithmetic = !text.empty() && std::all_of(text.begin(), text.end(), [](char c)
        {
            return IsDigit(c) || c == '.' || c == '+' || c == '-' || c == '*' || c == '/' || c == '(' || c == ')' ||
                c == ' ';
        });
        if (arithmetic && text.find("..") == std::string::npos)
            if (std::optional<double> value = ExpressionParser(text).Parse())
                return value;
        return LuaToNumber(text);
    }

    std::string Describe(Catalog const& catalog, DescribeSource const& ability, double power,
        bool* usedUnorderedFallback)
    {
        if (ability.text.empty())
            return "";
        Resolver resolver(catalog, ability, power, usedUnorderedFallback);
        std::string text = RemoveCurrent(ability.text);
        text = ResolveBrackets(text, resolver);
        text = RemoveColors(text);
        text = Plurals(text);
        text = Percents(text);
        text = HitChance(text);
        text = CollapseSpaces(text);
        return Trim(text);
    }

    std::string AuraTip(Catalog const& catalog, uint32_t id, double power)
    {
        std::string text;
        if (AbilityDef const* def = catalog.Ability(id))
            text = Describe(catalog, { def->text, &def->turns, def->family, id }, power);
        if (text.empty())
        {
            std::vector<std::string> parts;
            if (States const* states = catalog.StatesOf(id))
                for (auto const& [key, value] : *states)
                    if (auto found = StateText.find(key); found != StateText.end())
                        parts.push_back(found->second);
            std::sort(parts.begin(), parts.end());
            for (std::string const& part : parts)
                text += (text.empty() ? "" : " ") + part;
        }
        return text;
    }
}
