#include "../../../src/server/coa/CoAZoneScalingPolicy.h"
#include <cassert>
#include <cmath>
#include <limits>

int main()
{
    using namespace ZoneScaling;
    Definition hellfire{3483, 530, 0, 0.2f, 0.2f};
    Budget ordinary{60, 100000, 1.0f, 1.0f};
    assert(Valid(hellfire) && Valid(ordinary));
    assert(Health(hellfire, ordinary) == 100000);
    Definition zangarmarsh{3521, 530, 1, 0.2f, 0.2f};
    Definition terokkar{3519, 530, 2, 0.2f, 0.2f};
    assert(Health(zangarmarsh, ordinary) == 120000);
    assert(Health(terokkar, ordinary) == 140000);
    assert(std::abs(Melee(terokkar, ordinary) - 1.4f) < 0.00001f);
    assert(std::abs(Spell(terokkar, ordinary) - 1.4f) < 0.00001f);
    zangarmarsh.damageStep = 0.1f;
    assert(Health(zangarmarsh, ordinary) == 120000);
    assert(std::abs(Melee(zangarmarsh, ordinary) - 1.1f) < 0.00001f);
    assert(Health(hellfire, Budget{63, 3600000, 1, 1}) == 3600000);
    assert(!Valid(Budget{64, 1, 1, 1}));
    assert(!Valid(Budget{60, 0, 1, 1}));
    assert(!Valid(Budget{60, 1, -1, 1}));
    assert(!Valid(Definition{3483, 530, 0, -0.1f, 0.2f}));
    assert(!Valid(Definition{3483, 530, 0, std::numeric_limits<float>::quiet_NaN(), 0.2f}));
    assert(!Valid(Budget{60, 1, std::numeric_limits<float>::infinity(), 1}));
    assert(Health(terokkar, Budget{63, std::numeric_limits<unsigned>::max(), 1, 1}) ==
        std::numeric_limits<unsigned>::max());
}
