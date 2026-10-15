#pragma once
#include <array>
#include <cstdint>

namespace GuardianStandards
{
struct Contract
{
    std::uint32_t spell;
    std::uint32_t creature;
    std::uint32_t field;
};
inline constexpr std::array<Contract, 14> Contracts =
{{
    {500260, 50053, 500266},
    {500263, 50055, 500265},
    {500547, 220871, 500548},
    {706805, 50153, 500602},
    {800346, 60065, 500299},
    {800319, 50057, 800315},
    {803931, 60057, 501538},
    {803932, 60058, 501539},
    {803933, 60059, 501540},
    {803934, 60060, 501541},
    {803935, 60061, 501542},
    {803936, 60062, 501543},
    {803937, 60063, 501544},
    {803938, 60064, 501545}
}};
}
