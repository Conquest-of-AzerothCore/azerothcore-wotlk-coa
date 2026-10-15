/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_SUMMONED_EFFECTS_H
#define ASCENSION_SUMMONED_EFFECTS_H

#include <cstdint>

namespace AscensionSummonedEffects
{
enum class Behaviour : std::uint8_t
{
    Anchor,
    Spawn,
    Pulse,
    Delay,
    Tick,
    Expire,
    Aura,
    PullOwner,
    Freeze,
    Heal,
    Store,
    Attack,
    Turret,
    Mine,
    Vortex,
    Return,
    Ravager
};

enum class Motion : std::uint8_t
{
    Stay,
    Forward,
    OutAndBack
};

struct Summon
{
    std::uint32_t SummonSpell;
    std::uint32_t Creature;
    Behaviour Kind;
    std::uint32_t Helper = 0;
    std::uint32_t Payload = 0;
    std::uint32_t Extra = 0;
    std::uint32_t Milliseconds = 0;
    Motion Path = Motion::Stay;
    float Yards = 0.0f;
};

constexpr std::uint32_t LIGHTWELL_CHARGES = 10;
constexpr float LIGHTWELL_RANGE = 20.0f;
constexpr std::uint32_t LIGHTWELL_HEALTH_PCT = 50;
constexpr float MINE_TRIGGER_RADIUS = 3.0f;
constexpr float VORTEX_RADIUS = 5.0f;
constexpr float SLOW_ON_HIT_RATE = 0.1f;

constexpr bool SlowsOnHit(std::uint32_t creature)
{
    return creature == 840047 || creature == 2110014;
}

constexpr Summon Ranked(std::uint32_t summon, std::uint32_t creature, Behaviour kind, std::uint32_t helper,
    std::uint32_t payload, std::uint32_t extra = 0, Motion path = Motion::Stay, float yards = 0.0f)
{
    return { summon, creature, kind, helper, payload, extra, 0, path, yards };
}

constexpr Summon Timed(std::uint32_t summon, std::uint32_t creature, Behaviour kind, std::uint32_t payload,
    std::uint32_t milliseconds, std::uint32_t extra = 0)
{
    return { summon, creature, kind, 0, payload, extra, milliseconds };
}

constexpr Summon Still(std::uint32_t summon, std::uint32_t creature)
{
    return { summon, creature, Behaviour::Anchor };
}

constexpr Summon SUMMONS[] = {
    Timed(954514, 105927, Behaviour::Pulse, 954515, 1000, 954568),
    Timed(2304514, 2304514, Behaviour::Pulse, 2304515, 1000, 2304568),
    Timed(955062, 105938, Behaviour::Spawn, 954805, 0),
    Timed(2305062, 2305062, Behaviour::Spawn, 2304805, 0),
    Timed(1180271, 105930, Behaviour::Spawn, 1180272, 0),
    Still(1180271, 840189),
    Timed(282977, 80624, Behaviour::Spawn, 92557, 0),
    Timed(92560, 80624, Behaviour::Spawn, 92557, 0),
    Timed(1583210, 80624, Behaviour::Spawn, 1583190, 0),
    Timed(272031, 840033, Behaviour::Spawn, 272059, 0),
    Timed(954381, 840033, Behaviour::Spawn, 954377, 0),
    Timed(1569734, 840133, Behaviour::Spawn, 1569715, 0),

    Timed(954518, 105928, Behaviour::Delay, 954519, 2000),
    Timed(954588, 105931, Behaviour::Delay, 954519, 2000),
    Timed(954589, 105932, Behaviour::Delay, 954519, 2000),
    Timed(954590, 105933, Behaviour::Delay, 954519, 2000),
    Timed(954591, 105934, Behaviour::Delay, 954519, 2000),
    Timed(954592, 105935, Behaviour::Delay, 954519, 2000),
    Timed(954593, 105936, Behaviour::Delay, 954519, 2000),
    Timed(954594, 105937, Behaviour::Delay, 954519, 2000),
    Timed(2304518, 2304518, Behaviour::Delay, 2304519, 2000),
    Timed(2304588, 105931, Behaviour::Delay, 2304519, 2000),
    Timed(2304589, 105932, Behaviour::Delay, 2304519, 2000),
    Timed(2304590, 105933, Behaviour::Delay, 2304519, 2000),
    Timed(2304591, 105934, Behaviour::Delay, 2304519, 2000),
    Timed(2304592, 105935, Behaviour::Delay, 2304519, 2000),
    Timed(2304593, 105936, Behaviour::Delay, 2304519, 2000),
    Timed(2304594, 105937, Behaviour::Delay, 2304519, 2000),
    Timed(956046, 903581, Behaviour::Delay, 2304121, 3000),
    Timed(2306046, 903581, Behaviour::Delay, 2304121, 3000),
    Timed(1584421, 840048, Behaviour::Delay, 1584423, 2000),

    Ranked(954802, 105939, Behaviour::Tick, 954847, 954848, 954849),
    Ranked(954909, 105941, Behaviour::Tick, 954915, 954921, 954927),
    Ranked(954910, 105942, Behaviour::Tick, 954916, 954922, 954928),
    Ranked(954911, 105943, Behaviour::Tick, 954917, 954923, 954929),
    Ranked(954912, 105944, Behaviour::Tick, 954918, 954924, 954930),
    Ranked(954913, 105945, Behaviour::Tick, 954919, 954925, 954931),
    Ranked(954914, 105946, Behaviour::Tick, 954920, 954926, 954932),
    Ranked(2304802, 2304802, Behaviour::Tick, 2304847, 2304848, 2304849),
    Ranked(2304909, 2304909, Behaviour::Tick, 2304915, 2304921, 2304927),
    Ranked(2304910, 2304910, Behaviour::Tick, 2304916, 2304922, 2304928),
    Ranked(2304911, 2304911, Behaviour::Tick, 2304917, 2304923, 2304929),
    Ranked(2304912, 2304912, Behaviour::Tick, 2304918, 2304924, 2304930),
    Ranked(2304913, 2304913, Behaviour::Tick, 2304919, 2304925, 2304931),
    Ranked(2304914, 2304914, Behaviour::Tick, 2304920, 2304926, 2304932),

    Ranked(954861, 840037, Behaviour::Tick, 954834, 954833),
    Ranked(954862, 840037, Behaviour::Tick, 955063, 954868),
    Ranked(954863, 840037, Behaviour::Tick, 955064, 954869),
    Ranked(954864, 840037, Behaviour::Tick, 955065, 954870),
    Ranked(954865, 840037, Behaviour::Tick, 955066, 954871),
    Ranked(954866, 840037, Behaviour::Tick, 955067, 954872),
    Ranked(954867, 840037, Behaviour::Tick, 955068, 954873),
    Ranked(2304861, 2304861, Behaviour::Tick, 2304834, 2304833),
    Ranked(2304862, 2304861, Behaviour::Tick, 2305063, 2304868),
    Ranked(2304863, 2304861, Behaviour::Tick, 2305064, 2304869),
    Ranked(2304864, 2304861, Behaviour::Tick, 2305065, 2304870),
    Ranked(2304865, 2304861, Behaviour::Tick, 2305066, 2304871),
    Ranked(2304866, 2304861, Behaviour::Tick, 2305067, 2304872),
    Ranked(2304867, 2304861, Behaviour::Tick, 2305068, 2304873),
    Ranked(1186384, 2404861, Behaviour::Tick, 1186383, 1186385),

    Ranked(955032, 840040, Behaviour::Tick, 955033, 955034, 955054, Motion::Forward, 35.0f),
    Ranked(955036, 840040, Behaviour::Tick, 955042, 955048, 955054, Motion::Forward, 35.0f),
    Ranked(955037, 840040, Behaviour::Tick, 955043, 955049, 955054, Motion::Forward, 35.0f),
    Ranked(955038, 840040, Behaviour::Tick, 955044, 955050, 955054, Motion::Forward, 35.0f),
    Ranked(955039, 840040, Behaviour::Tick, 955045, 955051, 955054, Motion::Forward, 35.0f),
    Ranked(955040, 840040, Behaviour::Tick, 955046, 955052, 955054, Motion::Forward, 35.0f),
    Ranked(955041, 840040, Behaviour::Tick, 955047, 955053, 955054, Motion::Forward, 35.0f),
    Ranked(2305032, 840076, Behaviour::Tick, 2305033, 2305034, 2305054, Motion::Forward, 35.0f),
    Ranked(2305036, 840076, Behaviour::Tick, 2305042, 2305048, 2305054, Motion::Forward, 35.0f),
    Ranked(2305037, 840076, Behaviour::Tick, 2305043, 2305049, 2305054, Motion::Forward, 35.0f),
    Ranked(2305038, 840076, Behaviour::Tick, 2305044, 2305050, 2305054, Motion::Forward, 35.0f),
    Ranked(2305039, 840076, Behaviour::Tick, 2305045, 2305051, 2305054, Motion::Forward, 35.0f),
    Ranked(2305040, 840076, Behaviour::Tick, 2305046, 2305052, 2305054, Motion::Forward, 35.0f),
    Ranked(2305041, 840076, Behaviour::Tick, 2305047, 2305053, 2305054, Motion::Forward, 35.0f),

    Ranked(760014, 840047, Behaviour::Tick, 760015, 760016, 0, Motion::Forward, 40.0f),
    Ranked(760019, 840047, Behaviour::Tick, 760033, 760026, 0, Motion::Forward, 40.0f),
    Ranked(760020, 840047, Behaviour::Tick, 760034, 760027, 0, Motion::Forward, 40.0f),
    Ranked(760021, 840047, Behaviour::Tick, 760035, 760028, 0, Motion::Forward, 40.0f),
    Ranked(760022, 840047, Behaviour::Tick, 760036, 760029, 0, Motion::Forward, 40.0f),
    Ranked(760023, 840047, Behaviour::Tick, 760037, 760030, 0, Motion::Forward, 40.0f),
    Ranked(760024, 840047, Behaviour::Tick, 760038, 760031, 0, Motion::Forward, 40.0f),
    Ranked(760025, 840047, Behaviour::Tick, 760039, 760032, 0, Motion::Forward, 40.0f),
    Ranked(2110014, 2110014, Behaviour::Tick, 2110015, 2110016, 0, Motion::Forward, 40.0f),
    Ranked(2110019, 2110014, Behaviour::Tick, 2110033, 2110026, 0, Motion::Forward, 40.0f),
    Ranked(2110020, 2110014, Behaviour::Tick, 2110034, 2110027, 0, Motion::Forward, 40.0f),
    Ranked(2110021, 2110014, Behaviour::Tick, 2110035, 2110028, 0, Motion::Forward, 40.0f),
    Ranked(2110022, 2110014, Behaviour::Tick, 2110036, 2110029, 0, Motion::Forward, 40.0f),
    Ranked(2110023, 2110014, Behaviour::Tick, 2110037, 2110030, 0, Motion::Forward, 40.0f),
    Ranked(2110024, 2110014, Behaviour::Tick, 2110038, 2110031, 0, Motion::Forward, 40.0f),
    Ranked(2110025, 2110014, Behaviour::Tick, 2110039, 2110032, 0, Motion::Forward, 40.0f),

    Ranked(760060, 840056, Behaviour::Tick, 760061, 760062, 0, Motion::OutAndBack, 30.0f),
    Ranked(760063, 840056, Behaviour::Tick, 760149, 760070, 0, Motion::OutAndBack, 30.0f),
    Ranked(760064, 840056, Behaviour::Tick, 760150, 760071, 0, Motion::OutAndBack, 30.0f),
    Ranked(760065, 840056, Behaviour::Tick, 760151, 760072, 0, Motion::OutAndBack, 30.0f),
    Ranked(760066, 840056, Behaviour::Tick, 760152, 760073, 0, Motion::OutAndBack, 30.0f),
    Ranked(760067, 840056, Behaviour::Tick, 760153, 760074, 0, Motion::OutAndBack, 30.0f),
    Ranked(760068, 840056, Behaviour::Tick, 760154, 760075, 0, Motion::OutAndBack, 30.0f),
    Ranked(760069, 840056, Behaviour::Tick, 760155, 760076, 0, Motion::OutAndBack, 30.0f),
    Ranked(2110060, 840078, Behaviour::Tick, 2110061, 2110062, 2110108, Motion::OutAndBack, 30.0f),
    Ranked(2110063, 840078, Behaviour::Tick, 2110149, 2110070, 2110109, Motion::OutAndBack, 30.0f),
    Ranked(2110064, 840078, Behaviour::Tick, 2110150, 2110071, 2110110, Motion::OutAndBack, 30.0f),
    Ranked(2110065, 840078, Behaviour::Tick, 2110151, 2110072, 2110111, Motion::OutAndBack, 30.0f),
    Ranked(2110066, 840078, Behaviour::Tick, 2110152, 2110073, 2110112, Motion::OutAndBack, 30.0f),
    Ranked(2110067, 840078, Behaviour::Tick, 2110153, 2110074, 2110113, Motion::OutAndBack, 30.0f),
    Ranked(2110068, 840078, Behaviour::Tick, 2110154, 2110075, 2110114, Motion::OutAndBack, 30.0f),
    Ranked(2110069, 840078, Behaviour::Tick, 2110155, 2110076, 2110115, Motion::OutAndBack, 30.0f),
    Ranked(1180063, 840091, Behaviour::Tick, 1180064, 1180065, 0, Motion::Forward, 30.0f),

    Ranked(760040, 840048, Behaviour::Expire, 760041, 760042),
    Ranked(760156, 840048, Behaviour::Expire, 760162, 760168),
    Ranked(760157, 840048, Behaviour::Expire, 760163, 760169),
    Ranked(760158, 840048, Behaviour::Expire, 760164, 760170),
    Ranked(760159, 840048, Behaviour::Expire, 760165, 760171),
    Ranked(760160, 840048, Behaviour::Expire, 760166, 760172),
    Ranked(760161, 840048, Behaviour::Expire, 760167, 760173),
    Ranked(2110040, 840048, Behaviour::Expire, 2110041, 2110042),
    Ranked(2110156, 840048, Behaviour::Expire, 2110162, 2110168),
    Ranked(2110157, 840048, Behaviour::Expire, 2110163, 2110169),
    Ranked(2110158, 840048, Behaviour::Expire, 2110164, 2110170),
    Ranked(2110159, 840048, Behaviour::Expire, 2110165, 2110171),
    Ranked(2110160, 840048, Behaviour::Expire, 2110166, 2110172),
    Ranked(2110161, 840048, Behaviour::Expire, 2110167, 2110173),
    Ranked(954239, 840048, Behaviour::Expire, 954238, 954240),
    Ranked(284758, 840039, Behaviour::Expire, 956020, 982623),
    Ranked(284759, 840039, Behaviour::Expire, 956021, 982623),
    Ranked(284760, 840039, Behaviour::Expire, 956022, 982623),
    Ranked(284761, 840039, Behaviour::Expire, 956023, 982623),
    Ranked(284762, 840039, Behaviour::Expire, 956024, 982623),
    Ranked(284763, 840039, Behaviour::Expire, 956025, 982623),
    Ranked(284764, 840039, Behaviour::Expire, 956026, 982623),
    Ranked(284765, 840039, Behaviour::Expire, 956027, 982623),
    Ranked(284766, 840039, Behaviour::Expire, 956028, 982623),
    Ranked(284767, 840039, Behaviour::Expire, 956029, 982623),
    Ranked(982612, 840039, Behaviour::Expire, 956020, 982623),
    Ranked(982613, 840039, Behaviour::Expire, 956021, 982623),
    Ranked(982614, 840039, Behaviour::Expire, 956022, 982623),
    Ranked(982615, 840039, Behaviour::Expire, 956023, 982623),
    Ranked(982616, 840039, Behaviour::Expire, 956024, 982623),
    Ranked(982617, 840039, Behaviour::Expire, 956025, 982623),
    Ranked(982618, 840039, Behaviour::Expire, 956026, 982623),
    Ranked(982619, 840039, Behaviour::Expire, 956027, 982623),
    Ranked(982620, 840039, Behaviour::Expire, 956028, 982623),
    Ranked(982621, 840039, Behaviour::Expire, 956029, 982623),
    Ranked(1588070, 840039, Behaviour::Expire, 1588051, 1588080),
    Ranked(1588071, 840039, Behaviour::Expire, 1588052, 1588080),
    Ranked(1588072, 840039, Behaviour::Expire, 1588053, 1588080),
    Ranked(1588073, 840039, Behaviour::Expire, 1588054, 1588080),
    Ranked(1588074, 840039, Behaviour::Expire, 1588055, 1588080),
    Ranked(1588075, 840039, Behaviour::Expire, 1588056, 1588080),
    Ranked(1588076, 840039, Behaviour::Expire, 1588057, 1588080),
    Ranked(1588077, 840039, Behaviour::Expire, 1588058, 1588080),
    Ranked(1588078, 840039, Behaviour::Expire, 1588059, 1588080),
    Ranked(1588079, 840039, Behaviour::Expire, 1588060, 1588080),
    Ranked(283151, 940029, Behaviour::Expire, 417803, 417802),
    Ranked(283152, 940029, Behaviour::Expire, 417803, 417816),
    Ranked(283153, 940029, Behaviour::Expire, 417803, 417817),
    Ranked(283154, 940029, Behaviour::Expire, 417803, 417818),
    Ranked(283155, 940029, Behaviour::Expire, 417803, 417819),
    Ranked(417801, 940029, Behaviour::Expire, 417803, 417802),
    Ranked(417812, 940029, Behaviour::Expire, 417803, 417816),
    Ranked(417813, 940029, Behaviour::Expire, 417803, 417817),
    Ranked(417814, 940029, Behaviour::Expire, 417803, 417818),
    Ranked(417815, 940029, Behaviour::Expire, 417803, 417819),
    Ranked(1583722, 940029, Behaviour::Expire, 1583723, 1583720),

    Ranked(954854, 840036, Behaviour::Freeze, 954857, 954855, 954856),
    Ranked(2304854, 840044, Behaviour::Freeze, 2304857, 2304855, 2304856),
    Ranked(760053, 840058, Behaviour::Aura, 760054, 0),
    Ranked(2110053, 840058, Behaviour::Aura, 760054, 0),
    Ranked(285234, 350004, Behaviour::Aura, 983482, 0),
    Ranked(983481, 350004, Behaviour::Aura, 983482, 0),
    Timed(1589309, 350004, Behaviour::Pulse, 1589311, 3000),
    Timed(760056, 840057, Behaviour::PullOwner, 760057, 0),
    Timed(760094, 840057, Behaviour::PullOwner, 760091, 0),
    Timed(2110094, 840057, Behaviour::PullOwner, 760091, 0),
    Timed(2110056, 840079, Behaviour::PullOwner, 2110057, 0),

    Ranked(954504, 840034, Behaviour::Vortex, 954505, 954506),
    Ranked(2304504, 840034, Behaviour::Vortex, 2304505, 2304506),
    Ranked(86401, 80221, Behaviour::Return, 86401, 0),
    Ranked(1436401, 1436401, Behaviour::Return, 1436401, 0),

    Still(760080, 840059),
    Still(2110080, 840059),
    Still(997495, 160000),
    Still(276922, 160001),
    Still(997494, 160001),
    Still(1578139, 160001),
    Still(284579, 300099),
    Still(982477, 300099),
    Still(1587655, 300099),
    Still(271986, 840031),
    Still(954328, 840031),
    Still(1569647, 840100),
    Still(1133050, 840081),
    Timed(293180, 840082, Behaviour::Ravager, 293181, 1000, 293182),
    Still(1143180, 840082),
    Still(290063, 841091),
    Still(901308, 841103),
    Still(277776, 841104),

    Timed(724, 960124, Behaviour::Heal, 7001, 1000),
    Timed(27870, 960124, Behaviour::Heal, 27873, 1000),
    Timed(27871, 960124, Behaviour::Heal, 27874, 1000),
    Timed(28275, 960124, Behaviour::Heal, 28276, 1000),
    Timed(48086, 960124, Behaviour::Heal, 48084, 1000),
    Timed(48087, 960124, Behaviour::Heal, 48085, 1000),

    Ranked(760009, 841000, Behaviour::Store, 760010, 760011, 30),
    Ranked(2110009, 2110009, Behaviour::Store, 2110010, 2110011, 40),

    Timed(954611, 855350, Behaviour::Attack, 413110, 2000),
    Timed(2304612, 855352, Behaviour::Attack, 1413110, 2000),
    Timed(32986, 300182, Behaviour::Attack, 0, 0),
    Timed(32987, 300183, Behaviour::Attack, 0, 0),
    Timed(285959, 350001, Behaviour::Attack, 0, 0),
    Timed(997295, 350001, Behaviour::Attack, 0, 0),
    Timed(1590635, 350001, Behaviour::Attack, 0, 0),
    Timed(81249, 43286, Behaviour::Attack, 0, 0, 81413),
    Timed(281618, 43286, Behaviour::Attack, 0, 0, 81413),
    Timed(1580417, 43286, Behaviour::Attack, 0, 0, 1580397),

    Timed(285951, 350003, Behaviour::Turret, 997290, 0),
    Timed(997289, 350003, Behaviour::Turret, 997290, 0),
    Timed(1590628, 350003, Behaviour::Turret, 1590630, 0),
    Timed(92385, 80475, Behaviour::Turret, 92395, 2000),
    Timed(92386, 80476, Behaviour::Turret, 92396, 2000),
    Timed(92387, 80477, Behaviour::Turret, 92397, 2000),
    Timed(92388, 80478, Behaviour::Turret, 92398, 2000),
    Timed(92389, 80479, Behaviour::Turret, 92399, 2000),
    Timed(92390, 80480, Behaviour::Turret, 92400, 2000),
    Timed(92391, 80481, Behaviour::Turret, 92401, 2000),
    Timed(92392, 80482, Behaviour::Turret, 92402, 2000),
    Timed(92393, 80483, Behaviour::Turret, 92403, 2000),
    Timed(92394, 80484, Behaviour::Turret, 92404, 2000),
    Timed(282905, 80475, Behaviour::Turret, 92395, 2000),
    Timed(282907, 80476, Behaviour::Turret, 92396, 2000),
    Timed(282908, 80477, Behaviour::Turret, 92397, 2000),
    Timed(282909, 80478, Behaviour::Turret, 92398, 2000),
    Timed(282910, 80479, Behaviour::Turret, 92399, 2000),
    Timed(282911, 80480, Behaviour::Turret, 92400, 2000),
    Timed(282912, 80481, Behaviour::Turret, 92401, 2000),
    Timed(282913, 80482, Behaviour::Turret, 92402, 2000),
    Timed(282914, 80483, Behaviour::Turret, 92403, 2000),
    Timed(282915, 80484, Behaviour::Turret, 92404, 2000),
    Timed(1583072, 80475, Behaviour::Turret, 1583043, 2000),
    Timed(1583073, 80476, Behaviour::Turret, 1583044, 2000),
    Timed(1583074, 80477, Behaviour::Turret, 1583045, 2000),
    Timed(1583075, 80478, Behaviour::Turret, 1583046, 2000),
    Timed(1583076, 80479, Behaviour::Turret, 1583047, 2000),
    Timed(1583077, 80480, Behaviour::Turret, 1583048, 2000),
    Timed(1583078, 80481, Behaviour::Turret, 1583049, 2000),
    Timed(1583079, 80482, Behaviour::Turret, 1583050, 2000),
    Timed(1583080, 80483, Behaviour::Turret, 1583051, 2000),
    Timed(1583081, 80484, Behaviour::Turret, 1583052, 2000),

    Timed(92420, 80486, Behaviour::Mine, 92419, 0),
    Timed(282942, 80486, Behaviour::Mine, 92419, 0),
    Timed(1583130, 80486, Behaviour::Mine, 1583110, 0),

    Still(283494, 840051),
    Still(283494, 840052),
    Still(955108, 840051),
    Still(955108, 840052),
    Still(1584780, 840051),
    Still(1584780, 840052)
};

constexpr Summon const* Find(std::uint32_t summonSpell, std::uint32_t creature)
{
    for (Summon const& summon : SUMMONS)
        if (summon.SummonSpell == summonSpell && summon.Creature == creature)
            return &summon;
    return nullptr;
}

constexpr Summon const* FindByHelper(std::uint32_t helper, Behaviour kind)
{
    for (Summon const& summon : SUMMONS)
        if (summon.Helper == helper && summon.Kind == kind)
            return &summon;
    return nullptr;
}

constexpr bool UsesHelper(Behaviour kind)
{
    return kind == Behaviour::Tick || kind == Behaviour::Expire || kind == Behaviour::Aura ||
        kind == Behaviour::Freeze;
}
}

#endif
