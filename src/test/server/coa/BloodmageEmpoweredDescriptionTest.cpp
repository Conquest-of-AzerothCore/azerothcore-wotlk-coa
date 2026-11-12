#include "AscensionPooledVitality.h"
#include <gtest/gtest.h>

using namespace AscensionBloodmage;

TEST(BloodmageEmpoweredDescription, SanguineMendShowsItsEmpoweredLineForThePooledVitalityPassive)
{
    std::string const mend = "healing them for ${$m1+0+$SPI*0.25+$AP*.2+$SP*.58}.$?s680688[\r\n\r\n"
        "|cFFE53935Empowered|r: Becomes instant cast and heals yourself for $680033s1% of the heal value.][]";
    std::string const shown = RuntimeEmpoweredDescription(BloodmageSpellFamily, mend);
    EXPECT_EQ(shown, "healing them for ${$m1+0+$SPI*0.25+$AP*.2+$SP*.58}.$?s681078[\r\n\r\n"
        "|cFFE53935Empowered|r: Becomes instant cast and heals yourself for $680033s1% of the heal value.][]");
    EXPECT_EQ(RuntimeEmpoweredDescription(BloodmageSpellFamily, shown), shown);
}

TEST(BloodmageEmpoweredDescription, LeavesOtherFamiliesAndLongerSpellIdsAlone)
{
    std::string const mend = "$?s680688[Empowered][]";
    EXPECT_EQ(RuntimeEmpoweredDescription(BloodmageSpellFamily + 1, mend), mend);
    EXPECT_EQ(RuntimeEmpoweredDescription(BloodmageSpellFamily, "$?s6806881[x][]"), "$?s6806881[x][]");
    EXPECT_EQ(RuntimeEmpoweredDescription(BloodmageSpellFamily, "$?s680688[a][]$?s680688[b][]"),
        "$?s681078[a][]$?s681078[b][]");
}
