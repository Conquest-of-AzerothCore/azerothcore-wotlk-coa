/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef DEF_SUNKEN_TEMPLE_H
#define DEF_SUNKEN_TEMPLE_H

#define DataHeader "STR"

enum DataTypes
{
    DATA_STATUES                = 10,
    DATA_DEFENDER_KILLED        = 11,
    DATA_ERANIKUS_FIGHT         = 12,
    DATA_AWAKEN_SOULFLAYER      = 13,
    MAX_STATUE_PHASE            = 6,
    DEFENDERS_COUNT             = 6,

    TYPE_ATAL_ALARION           = 0,
    TYPE_JAMMAL_AN              = 1,
    TYPE_HAKKAR_EVENT           = 2,
    MAX_ENCOUNTERS              = 3
};

enum GoIds
{
    GO_ATALAI_STATUE1           = 148830,
    GO_ATALAI_STATUE2           = 148831,
    GO_ATALAI_STATUE3           = 148832,
    GO_ATALAI_STATUE4           = 148833,
    GO_ATALAI_STATUE5           = 148834,
    GO_ATALAI_STATUE6           = 148835,
    GO_ATALAI_IDOL              = 148836,
    GO_IDOL_OF_HAKKAR           = 148838,
    GO_ATALAI_LIGHT2            = 148937,
    GO_FORCEFIELD               = 149431,
    GO_HAKKAR_WORSHIP_ALTAR     = 2310500,
    GO_ETERNAL_FLAME1           = 148418,
    GO_ETERNAL_FLAME2           = 148419,
    GO_ETERNAL_FLAME3           = 148420,
    GO_ETERNAL_FLAME4           = 148421
};

enum CreatureIds
{
    NPC_MALFURION_STORMRAGE     = 15362,
    NPC_JAMMAL_AN_THE_PROPHET   = 5710,
    NPC_SHADE_OF_ERANIKUS       = 5709,
    NPC_SHADE_OF_HAKKAR         = 8440,
    NPC_HAKKARI_BLOODKEEPER     = 8438,
    NPC_AVATAR_OF_HAKKAR        = 8443,
    NPC_OGOM_THE_WRETCHED       = 5711,
    NPC_MORPHAZ                 = 5719,
    NPC_WEAVER                  = 5720,
    NPC_DREAMSCYTHE             = 5721,
    NPC_HAZZAS                  = 5722,
};

enum SpellIds
{
    HEX_OF_JAMMAL_AN            = 12480,
    HEX_OF_JAMMAL_AN_CHARM      = 12483
};

#endif
