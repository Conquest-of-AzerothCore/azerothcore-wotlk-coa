#include "../../../src/server/coa/AscensionItemScalingPolicy.h"
#include <cassert>
#include <cmath>

int main()
{
    using namespace ItemScaling;
    assert(!IsScaledEntry(FirstScaledEntry - 1) && IsScaledEntry(FirstScaledEntry));
    assert(IsScaledEntry(LastScaledEntry) && !IsScaledEntry(LastScaledEntry + 1));

    assert(EligibleItem(2, ItemClassArmor, 5, 12, 0, 0) && EligibleItem(5, ItemClassWeapon, 13, 12, 0, 0));
    assert(EligibleItem(1, ItemClassArmor, 5, 4, 0, 0) && EligibleItem(0, ItemClassWeapon, 13, 4, 0, 0));
    assert(!EligibleItem(6, ItemClassArmor, 5, 12, 0, 0) && !EligibleItem(7, ItemClassArmor, 5, 12, 0, 0));
    assert(!EligibleItem(2, 0, 5, 12, 0, 0) && !EligibleItem(2, 15, 5, 12, 0, 0));
    assert(!EligibleItem(2, ItemClassArmor, 0, 12, 0, 0));
    assert(!EligibleItem(1, ItemClassArmor, InventoryTypeShirt, 12, 0, 0));
    assert(!EligibleItem(1, ItemClassArmor, InventoryTypeTabard, 12, 0, 0));
    assert(!EligibleItem(0, ItemClassWeapon, 13, 0, 0, 0));
    assert(!EligibleItem(2, ItemClassArmor, 5, 12, 1, 0) && !EligibleItem(2, ItemClassArmor, 5, 12, 0, 176));

    assert(IsWorldforgedDescription("@Worldforged@"));
    assert(IsWorldforgedDescription("@Worldforged@Salvaged from Theramore."));
    assert(!IsWorldforgedDescription("") && !IsWorldforgedDescription("@Worldforged"));
    assert(!IsWorldforgedDescription("Mad Love."));
    assert(!IsWorldforgedDescription("A @Worldforged@ item") && !IsWorldforgedDescription("@Refined@"));

    assert(QuestLift(11, 30) == 19 && QuestLift(11, 11) == 0 && QuestLift(40, 30) == 0);
    assert(QuestLift(0, 30) == 0 && QuestLift(-1, 30) == 0);
    assert(LootLift(10, 27) == 17 && LootLift(10, 0) == 0 && LootLift(30, 27) == 0);

    assert(ContentLift(12, 30, 3) == 15 && ContentLift(27, 30, 3) == 0 && ContentLift(40, 30, 3) == 0);
    assert(ContentLift(1, 3, 3) == 0 && ContentLift(1, 2, 3) == 0);

    assert(SteppedLift(0) == 0 && SteppedLift(4) == 0 && SteppedLift(5) == 5);
    assert(SteppedLift(17) == 15 && SteppedLift(19) == 15 && SteppedLift(22) == 20 && SteppedLift(79) == 75);

    assert(LiftedRequiredLevel(5, 10, 17, 80) == 22 && LiftedRequiredLevel(0, 4, 23, 80) == 22);
    assert(LiftedRequiredLevel(0, 4, 0, 80) == 0 && LiftedRequiredLevel(0, 1, 4, 80) == 0);
    assert(LiftedRequiredLevel(0, 70, 30, 80) == 80 && LiftedRequiredLevel(7, 12, 0, 80) == 7);
    assert(LiftedRequiredLevel(70, 75, 17, 80) == 80 && LiftedRequiredLevel(85, 90, 5, 80) == 85);

    assert(ScaleSigned(10, 0.5) == 10 && ScaleSigned(10, 1.25) == 13 && ScaleSigned(-4, 2.0) == -8);
    assert(ScaleUnsigned(108, 1.0) == 108 && ScaleUnsigned(108, 2.5) == 270);
    assert(ScaleUnsigned(4000000000U, 2.0) == 4294967295U);
    assert(ScaleFloat(7.0f, 0.9) == 7.0f && ScaleFloat(7.0f, 1.5) == 11.0f);
    assert(PointsRatio(0, 10) == 1.0 && PointsRatio(10, 5) == 1.0 && PointsRatio(10, 25) == 2.5);

    LevelCurve sparse;
    sparse.Add(10, 100.0);
    sparse.Add(20, 200.0);
    sparse.Finish();
    assert(sparse.At(10) == 0.0 && CurveRatio(sparse, 10, 20, 1.5) == 1.5);

    LevelCurve curve;
    curve.Add(10, 90.0);
    curve.Add(10, 100.0);
    curve.Add(10, 400.0);
    curve.Add(20, 180.0);
    curve.Add(20, 220.0);
    curve.Add(30, 150.0);
    curve.Add(40, 400.0);
    curve.Add(0, 1000.0);
    curve.Add(MaximumCurveLevel + 1, 1000.0);
    curve.Add(25, 0.0);
    curve.Finish();
    assert(curve.At(10) == 100.0 && curve.At(20) == 200.0 && curve.At(15) == 150.0);
    assert(curve.At(30) == 200.0 && curve.At(35) == 275.0 && curve.At(40) == 400.0);
    assert(curve.At(9) == 0.0 && curve.At(41) == 0.0 && curve.At(MaximumCurveLevel + 5) == 0.0);
    assert(CurveRatio(curve, 10, 20, 9.0) == 2.0 && CurveRatio(curve, 10, 50, 9.0) == 9.0);
    for (unsigned level = 11; level <= 40; ++level)
        assert(curve.At(level) >= curve.At(level - 1));

    assert(Disenchantable(61, 0) && Disenchantable(61, 300));
    assert(!Disenchantable(0, 300) && !Disenchantable(61, std::uint32_t(-1)));

    DisenchantLadder empty;
    assert(empty.AtOrBelow(80).disenchantId == 0 && empty.AtOrBelow(80).itemLevel == 0);

    DisenchantLadder sameSubClass;
    sameSubClass.Add(66, 61, 275);
    sameSubClass.Add(66, 61, 275);
    sameSubClass.Add(66, 62, 275);
    sameSubClass.Add(70, 63, 300);
    sameSubClass.Add(70, 62, 300);
    sameSubClass.Add(90, 0, 300);
    sameSubClass.Add(95, 64, std::uint32_t(-1));
    sameSubClass.Add(0, 64, 300);
    assert(sameSubClass.AtOrBelow(65).disenchantId == 0);
    DisenchantBracket const common = sameSubClass.AtOrBelow(68);
    assert(common.itemLevel == 66 && common.disenchantId == 61 && common.requiredSkill == 275);
    DisenchantBracket const tied = sameSubClass.AtOrBelow(120);
    assert(tied.itemLevel == 70 && tied.disenchantId == 62 && tied.requiredSkill == 300);

    DisenchantLadder sameSlot;
    sameSlot.Add(66, 65, 275);
    sameSlot.Add(66, 64, 300);
    sameSlot.Add(66, 64, 275);
    sameSlot.Add(100, 67, 325);
    DisenchantBracket const slotTie = sameSlot.AtOrBelow(70);
    assert(slotTie.disenchantId == 64 && slotTie.requiredSkill == 275);
    assert(NearestDisenchantBracket(sameSubClass.AtOrBelow(70), sameSlot.AtOrBelow(70)).disenchantId == 62);
    assert(NearestDisenchantBracket(sameSubClass.AtOrBelow(66), sameSlot.AtOrBelow(66)).disenchantId == 61);
    assert(NearestDisenchantBracket(sameSubClass.AtOrBelow(110), sameSlot.AtOrBelow(110)).disenchantId == 67);
    assert(NearestDisenchantBracket(empty.AtOrBelow(110), empty.AtOrBelow(110)).disenchantId == 0);
}
