/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_CREATURE_SCALING_POLICY_H
#define COA_CREATURE_SCALING_POLICY_H

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <map>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace CreatureScaling
{
enum class Context
{
    None,
    World,
    Dungeon,
    Raid
};

class Formula
{
public:
    Formula() : Formula(1.0f) { }

    Formula(float constant)
    {
        _nodes.push_back({ Op::Number, constant, -1, -1 });
        _root = 0;
        std::ostringstream stream;
        stream << constant;
        _text = stream.str();
    }

    static std::optional<Formula> Parse(std::string const& text)
    {
        Formula formula;
        formula._nodes.clear();
        formula._text.clear();
        for (char c : text)
            if (!std::isspace(static_cast<unsigned char>(c)))
                formula._text += c;
        if (formula._text.empty())
            return std::nullopt;

        Parser parser{ text, 0, formula._nodes };
        int const root = parser.Expression();
        parser.Skip();
        if (root < 0 || parser.position != text.size())
            return std::nullopt;
        formula._root = root;
        return formula;
    }

    static Formula Of(std::string const& text)
    {
        std::optional<Formula> formula = Parse(text);
        return formula ? *formula : Formula(1.0f);
    }

    [[nodiscard]] float Evaluate(std::uint8_t level) const
    {
        double const value = Evaluate(_root, level);
        if (!(value > 0.0) || value > double(std::numeric_limits<float>::max()))
            return 0.0f;
        return float(value);
    }

    [[nodiscard]] std::string const& Text() const { return _text; }

    [[nodiscard]] bool UsesLevel() const
    {
        for (Node const& node : _nodes)
            if (node.op == Op::Level)
                return true;
        return false;
    }

    bool operator==(Formula const& other) const { return _text == other._text; }

private:
    enum class Op
    {
        Number,
        Level,
        Add,
        Subtract,
        Multiply,
        Divide,
        Negate,
        Min,
        Max
    };

    struct Node
    {
        Op op;
        double value;
        int left;
        int right;
    };

    struct Parser
    {
        std::string const& text;
        std::size_t position;
        std::vector<Node>& nodes;

        int Add(Op op, double value, int left, int right)
        {
            nodes.push_back({ op, value, left, right });
            return int(nodes.size()) - 1;
        }

        void Skip()
        {
            while (position < text.size() && std::isspace(static_cast<unsigned char>(text[position])))
                ++position;
        }

        bool Accept(char c)
        {
            Skip();
            if (position < text.size() && text[position] == c)
            {
                ++position;
                return true;
            }
            return false;
        }

        bool AcceptWord(char const* word)
        {
            Skip();
            std::size_t length = 0;
            while (word[length])
                ++length;
            if (text.compare(position, length, word) != 0)
                return false;
            std::size_t const end = position + length;
            if (end < text.size() && (std::isalnum(static_cast<unsigned char>(text[end])) || text[end] == '_'))
                return false;
            position = end;
            return true;
        }

        int Expression()
        {
            int left = Term();
            while (left >= 0)
            {
                if (Accept('+'))
                    left = Binary(Op::Add, left, Term());
                else if (Accept('-'))
                    left = Binary(Op::Subtract, left, Term());
                else
                    break;
            }
            return left;
        }

        int Term()
        {
            int left = Factor();
            while (left >= 0)
            {
                if (Accept('*'))
                    left = Binary(Op::Multiply, left, Factor());
                else if (Accept('/'))
                    left = Binary(Op::Divide, left, Factor());
                else
                    break;
            }
            return left;
        }

        int Binary(Op op, int left, int right)
        {
            return right < 0 ? -1 : Add(op, 0.0, left, right);
        }

        int Factor()
        {
            if (Accept('-'))
            {
                int const operand = Factor();
                return operand < 0 ? -1 : Add(Op::Negate, 0.0, operand, -1);
            }
            if (Accept('('))
            {
                int const inner = Expression();
                return inner >= 0 && Accept(')') ? inner : -1;
            }
            if (AcceptWord("level"))
                return Add(Op::Level, 0.0, -1, -1);
            for (auto const& [word, op] : { std::pair{ "min", Op::Min }, std::pair{ "max", Op::Max } })
            {
                if (!AcceptWord(word))
                    continue;
                if (!Accept('('))
                    return -1;
                int const first = Expression();
                if (first < 0 || !Accept(','))
                    return -1;
                int const second = Expression();
                if (second < 0 || !Accept(')'))
                    return -1;
                return Add(op, 0.0, first, second);
            }
            return Number();
        }

        int Number()
        {
            Skip();
            std::size_t const start = position;
            while (position < text.size() && (std::isdigit(static_cast<unsigned char>(text[position])) || text[position] == '.'))
                ++position;
            if (position == start)
                return -1;
            std::string const digits = text.substr(start, position - start);
            char* end = nullptr;
            double const value = std::strtod(digits.c_str(), &end);
            if (end != digits.c_str() + digits.size())
                return -1;
            return Add(Op::Number, value, -1, -1);
        }
    };

    double Evaluate(int index, std::uint8_t level) const
    {
        Node const& node = _nodes[std::size_t(index)];
        switch (node.op)
        {
            case Op::Number:
                return node.value;
            case Op::Level:
                return double(level);
            case Op::Add:
                return Evaluate(node.left, level) + Evaluate(node.right, level);
            case Op::Subtract:
                return Evaluate(node.left, level) - Evaluate(node.right, level);
            case Op::Multiply:
                return Evaluate(node.left, level) * Evaluate(node.right, level);
            case Op::Divide:
            {
                double const divisor = Evaluate(node.right, level);
                return divisor == 0.0 ? 0.0 : Evaluate(node.left, level) / divisor;
            }
            case Op::Negate:
                return -Evaluate(node.left, level);
            case Op::Min:
            {
                double const a = Evaluate(node.left, level);
                double const b = Evaluate(node.right, level);
                return a < b ? a : b;
            }
            case Op::Max:
            {
                double const a = Evaluate(node.left, level);
                double const b = Evaluate(node.right, level);
                return a > b ? a : b;
            }
        }
        return 0.0;
    }

    std::vector<Node> _nodes;
    int _root = -1;
    std::string _text;
};

struct Multipliers
{
    Formula world;
    Formula dungeon;
    Formula raid;
    std::map<std::uint32_t, Formula> maps;
};

inline constexpr char WorldDefault[] = "1.17 + 0.013 * level";

struct Settings
{
    bool enabled = false;
    Multipliers health{ Formula::Of(WorldDefault), 2.5f, 2.2f,
        { { 36, 2.2f }, { 43, 2.0f }, { 229, 4.0f }, { 389, 3.0f }, { 469, 5.0f } } };
    Multipliers damage{ Formula::Of(WorldDefault), 1.5f, 1.0f, {} };
    Multipliers damageSpread{ 1.55f, 0.0f, 0.0f, {} };
};

inline Context ContextOf(bool battlegroundOrArena, bool scriptedPrivateInstance, bool regularDifficulty, bool raid,
    bool dungeon)
{
    if (battlegroundOrArena || scriptedPrivateInstance || !regularDifficulty)
        return Context::None;
    if (raid)
        return Context::Raid;
    return dungeon ? Context::Dungeon : Context::World;
}

inline float Multiplier(Multipliers const& multipliers, Context context, std::uint32_t mapId, std::uint8_t level)
{
    if (context == Context::None)
        return 1.0f;
    if (auto itr = multipliers.maps.find(mapId); itr != multipliers.maps.end())
        return itr->second.Evaluate(level);
    switch (context)
    {
        case Context::World:
            return multipliers.world.Evaluate(level);
        case Context::Dungeon:
            return multipliers.dungeon.Evaluate(level);
        default:
            return multipliers.raid.Evaluate(level);
    }
}

inline void ScaleRange(float& minDamage, float& maxDamage, float multiplier, float spread)
{
    if (multiplier > 0.0f)
    {
        minDamage *= multiplier;
        maxDamage *= multiplier;
    }
    if (spread > 1.0f && maxDamage > 0.0f)
    {
        float const average = (minDamage + maxDamage) / 2.0f;
        minDamage = average * 2.0f / (1.0f + spread);
        maxDamage = minDamage * spread;
    }
}

inline std::uint32_t Scaled(std::uint32_t value, float multiplier)
{
    if (multiplier <= 0.0f || value == 0)
        return value;
    double const scaled = double(value) * multiplier + 0.5;
    if (scaled >= double(std::numeric_limits<std::uint32_t>::max()))
        return std::numeric_limits<std::uint32_t>::max();
    return scaled < 1.0 ? 1 : std::uint32_t(scaled);
}

inline std::string FormatMapMultipliers(std::map<std::uint32_t, Formula> const& maps)
{
    std::ostringstream stream;
    for (auto const& [mapId, formula] : maps)
        stream << (stream.tellp() > 0 ? " " : "") << mapId << ':' << formula.Text();
    return stream.str();
}

inline std::map<std::uint32_t, Formula> ParseMapMultipliers(std::string const& text)
{
    std::map<std::uint32_t, Formula> result;
    char const separator = text.find(';') != std::string::npos ? ';' : ' ';
    std::istringstream stream(text);
    std::string token;
    while (separator == ';' ? bool(std::getline(stream, token, ';')) : bool(stream >> token))
    {
        std::size_t const colon = token.find(':');
        if (colon == std::string::npos)
            continue;
        std::string mapText;
        for (char c : token.substr(0, colon))
            if (!std::isspace(static_cast<unsigned char>(c)))
                mapText += c;
        if (mapText.empty() || mapText.find_first_not_of("0123456789") != std::string::npos)
            continue;
        unsigned long long const mapId = std::strtoull(mapText.c_str(), nullptr, 10);
        std::optional<Formula> const formula = Formula::Parse(token.substr(colon + 1));
        if (!formula || mapId > std::numeric_limits<std::uint32_t>::max())
            continue;
        if (!formula->UsesLevel() && formula->Evaluate(0) <= 0.0f)
            continue;
        result[std::uint32_t(mapId)] = *formula;
    }
    return result;
}
}

#endif
