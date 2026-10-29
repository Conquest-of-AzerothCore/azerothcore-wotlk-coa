/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef WorldBaseline_h__
#define WorldBaseline_h__

#include "Define.h"
#include <filesystem>
#include <vector>

class AC_DATABASE_API WorldBaseline
{
public:
    static std::vector<std::filesystem::path> Extract(std::filesystem::path const& manifest,
        std::filesystem::path const& directory);
};

#endif // WorldBaseline_h__
