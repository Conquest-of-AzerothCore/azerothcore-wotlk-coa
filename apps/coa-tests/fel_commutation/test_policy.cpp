#include "../../../src/server/coa/AscensionFelCommutationPolicy.h"
#include <cassert>
#include <iostream>
#include <numeric>
#include <string>

int main()
{
    using namespace FelCommutation;
    unsigned checked = 0;

    for (unsigned slot = 0; slot <= 21; ++slot)
    {
        bool const expected = slot >= 1 && slot <= 19 && slot != 4 && slot != 19;
        assert(Insurable(slot) == expected);
        ++checked;
    }

    assert(ToggleResult::Ok == DecideToggle(false, true, true, false));
    assert(ToggleResult::Ok == DecideToggle(true, false, true, false));
    assert(ToggleResult::NoAltarNearby == DecideToggle(true, false, false, false));
    assert(ToggleResult::Ok == DecideToggle(true, false, false, true));
    assert(ToggleResult::AlreadyActive == DecideToggle(true, true, true, false));
    assert(ToggleResult::AlreadyInactive == DecideToggle(false, false, false, false));
    assert(ToggleResult::NoAltarNearby == DecideToggle(false, true, false, false));
    assert(ToggleResult::Ok == DecideToggle(false, true, false, true));
    assert(std::string(ToggleResultName(ToggleResult::Ok)) == "TOGGLE_FEL_COMMUTATION_OK");
    assert(std::string(ToggleResultName(ToggleResult::NoAltarNearby)) == "TOGGLE_FEL_COMMUTATION_NO_ALTAR_NEARBY");
    assert(std::string(ToggleResultName(ToggleResult::AlreadyActive)) == "TOGGLE_FEL_COMMUTATION_ALREADY_ACTIVE");
    assert(std::string(ToggleResultName(ToggleResult::AlreadyInactive)) == "TOGGLE_FEL_COMMUTATION_ALREADY_INACTIVE");
    assert(std::string(ToggleResultName(ToggleResult::Unknown)) == "TOGGLE_FEL_COMMUTATION_UNKNOWN");

    assert(CopperPerLevel(0) == 28 && CopperPerLevel(25) == 28);
    assert(CopperPerLevel(26) == 85 && CopperPerLevel(35) == 85);
    assert(CopperPerLevel(36) == 256 && CopperPerLevel(45) == 256);
    assert(CopperPerLevel(46) == 361 && CopperPerLevel(54) == 361);
    assert(CopperPerLevel(55) == 1250 && CopperPerLevel(62) == 1250);
    assert(CopperPerLevel(63) == 1500 && CopperPerLevel(105) == 1500);
    assert(CopperPerLevel(106) == 2000 && CopperPerLevel(114) == 2000);
    assert(CopperPerLevel(115) == 2500 && CopperPerLevel(123) == 2500);
    assert(CopperPerLevel(124) == 2750 && CopperPerLevel(500) == 2750);

    assert(ClientCost(60.0f, false) == 60 * 1250);
    assert(ClientCost(60.0f, true) == 60 * 1250 + 100000);
    assert(ClientCost(60.9f, false) == 60 * 1250);
    assert(ClientCost(179.0f, false) == 492250);
    assert(ClientCost(179.99f, false) == 492250);
    assert(ClientCost(0.0f, false) == 0);
    assert(ClientCost(0.0f, true) == 100000);
    assert(ClientCost(-5.0f, false) == 0);
    assert(ClientCost(115.0f, false) == 115 * 2500);
    assert(ClientCost(123.0f, false) == 123 * 2500);
    assert(ClientCost(124.0f, false) == 124 * 2750);

    assert(ItemFee(179, 1.0) == 492250);
    assert(ItemFee(60, 1.0) == 60 * 1250);
    assert(ItemFee(25, 1.0) == 25 * 28);
    assert(ItemFee(26, 1.0) == 26 * 85);
    assert(ItemFee(179, 2.0) == 984500);
    assert(ItemFee(179, 0.0) == 0);
    assert(ItemFee(179, -1.0) == 0);
    assert(ItemFee(0, 1.0) == 0);

    {
        Settlement const settlement = Settle(179.0f, false, 1.0, 2, 1000000);
        assert(settlement.total == 492250 && settlement.covered);
        assert(settlement.perItem.size() == 2 && settlement.perItem[0] + settlement.perItem[1] == 492250);
    }
    assert(Settle(179.0f, false, 1.0, 2, 492250).covered);
    assert(!Settle(179.0f, false, 1.0, 2, 492249).covered);
    assert(Settle(179.0f, false, 1.0, 0, 0).perItem.empty());
    assert(Settle(179.0f, false, 0.5, 3, 0).total == 246125);
    assert(Settle(179.0f, false, 2.0, 3, 0).total == 984500);
    assert(Settle(179.0f, false, 0.0, 3, 0).total == 0 && Settle(179.0f, false, 0.0, 3, 0).covered);
    assert(Settle(179.0f, false, -4.0, 3, 0).total == 0);

    assert(FormatMoney(0) == "0g 0s 0c");
    assert(FormatMoney(492250) == "49g 22s 50c");
    assert(FormatMoney(517450) == "51g 74s 50c");
    assert(FormatMoney(1009700) == "100g 97s 0c");
    assert(FormatMoney(99) == "0g 0s 99c" && FormatMoney(10000) == "1g 0s 0c");

    for (std::size_t items = 1; items <= 19; ++items)
    {
        for (float level = 1.0f; level < 200.0f; level += 7.3f)
        {
            Settlement const settlement = Settle(level, level > 100.0f, 0.777, items, 0);
            std::uint64_t const sum = std::accumulate(settlement.perItem.begin(), settlement.perItem.end(),
                std::uint64_t(0));
            assert(sum == settlement.total);
            std::uint64_t const low = *std::min_element(settlement.perItem.begin(), settlement.perItem.end());
            std::uint64_t const high = *std::max_element(settlement.perItem.begin(), settlement.perItem.end());
            assert(high - low <= 1);
            ++checked;
        }
    }

    std::cout << checked << " rate band, cost, settlement and toggle checks verified\n";
}
