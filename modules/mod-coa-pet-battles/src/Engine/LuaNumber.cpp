#include "LuaNumber.h"
#include <cstdio>

namespace CoAPetBattles::Engine
{
    std::string LuaNumber(double value)
    {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%.14g", value);
        return buffer;
    }
}
