/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_SERVER_MESSAGE_TIME_H
#define ASCENSION_SERVER_MESSAGE_TIME_H

#include "Common.h"
#include <sstream>
#include <string>

namespace AscensionServerMessage
{
inline std::string ShutdownTimeString(uint64 timeInSecs)
{
    uint64 const secs = timeInSecs % MINUTE;
    uint64 const minutes = timeInSecs % HOUR / MINUTE;
    uint64 const hours = timeInSecs % DAY / HOUR;
    uint64 const days = timeInSecs / DAY;

    std::ostringstream ss;
    if (days)
        ss << days << " Day(s) ";
    if (hours)
        ss << hours << " Hour(s) ";
    if (minutes)
        ss << minutes << " Minute(s) ";
    if (secs || (!days && !hours && !minutes))
        ss << secs << " Second(s) ";

    std::string str = ss.str();
    str.pop_back();
    return str;
}
}

#endif
