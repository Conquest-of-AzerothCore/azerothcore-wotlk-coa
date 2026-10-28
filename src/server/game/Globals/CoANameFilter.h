#ifndef COA_NAME_FILTER_H
#define COA_NAME_FILTER_H

#include <string>
#include <string_view>

namespace CoANameFilter
{
inline std::string Normalize(std::string_view value)
{
    std::string normalized;
    normalized.reserve(value.size());
    for (char letter : value)
    {
        if (letter >= 'A' && letter <= 'Z')
            letter = char(letter - 'A' + 'a');

        switch (letter)
        {
            case '0': letter = 'o'; break;
            case '1': letter = 'i'; break;
            case '3': letter = 'e'; break;
            case '4':
            case '@': letter = 'a'; break;
            case '5':
            case '$': letter = 's'; break;
            case '7': letter = 't'; break;
            case '8': letter = 'b'; break;
            case '9': letter = 'g'; break;
            default: break;
        }

        if (letter < 'a' || letter > 'z')
            continue;

        if (normalized.empty() || normalized.back() != letter)
            normalized.push_back(letter);
    }
    return normalized;
}
}

#endif
