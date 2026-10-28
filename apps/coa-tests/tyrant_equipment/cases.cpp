int main()
{
    for (uint32 mainType : {1, 5, 8, 6, 10, 20})
        for (uint32 offType : {1, 5, 8, 6, 10, 20})
        {
            Player player;
            player.fixtureMain.info.SubClass = mainType;
            player.fixtureOff.info.SubClass = offType;
            bool allowed = mainType != 10 && mainType != 20 && offType != 10 && offType != 20;
            assert(player.FindTwoHandSlot(&player.fixtureOff.info) == allowed);
            assert((player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_OK) == allowed);
            player.AutoUnequipOffhandIfNeed();
            assert(player.removed != allowed);
            if (allowed)
            {
                assert(!player.penalty);
                player.known.clear();
                player.removed = false;
                assert(!player.CanTitanGrip());
                assert(!player.FindTwoHandSlot(&player.fixtureOff.info));
                player.AutoUnequipOffhandIfNeed();
                assert(player.removed);
            }
            player.known = {92089};
            player.cls = CLASS_WARRIOR;
            player.m_canTitanGrip = true;
            bool warrior = mainType != 6 && offType != 6 && allowed;
            assert(player.FindTwoHandSlot(&player.fixtureOff.info) == warrior);
            assert((player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_OK) == warrior);
            player.penalty = true;
            player.UpdateTitansGrip();
            assert(player.penalty && player.aura.recalculations);
        }
    Player player;
    player.level = 9;
    assert(!player.CanTitanGrip());
    player.level = 10;
    player.cls = CLASS_GUARDIAN;
    assert(!player.CanTitanGrip());
    player.cls = 14;
    player.dual = false;
    assert(!player.FindTwoHandSlot(&player.fixtureOff.info));
    assert(player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_CANT_DUAL_WIELD);
    player.AutoUnequipOffhandIfNeed();
    assert(player.removed);
    player.dual = true;
    player.fixtureOff.info.InventoryType = INVTYPE_WEAPON;
    player.fixtureOff.info.SubClass = 0;
    assert(player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_OK);
    player.fixtureMain.info.InventoryType = INVTYPE_WEAPON;
    player.fixtureMain.info.SubClass = 0;
    player.fixtureOff.info.InventoryType = INVTYPE_2HWEAPON;
    player.fixtureOff.info.SubClass = 6;
    assert(player.FindTwoHandSlot(&player.fixtureOff.info));
    assert(player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_OK);
    player.hasMain = false;
    assert(!player.FindTwoHandSlot(&player.fixtureOff.info));
    player.hasMain = true;
    player.cls = CLASS_GUARDIAN;
    player.known = {802299};
    player.fixtureMain.info = {2, 6, 17};
    player.fixtureOff.info = {4, 6, 14};
    assert(player.CheckEquip(&player.fixtureOff.info, 16) == EQUIP_ERR_OK);
    player.removed = false;
    player.AutoUnequipOffhandIfNeed();
    assert(!player.removed);
    ItemTemplate bag{2, 8, 17};
    player.cls = CLASS_DEMON_HUNTER;
    player.level = 10;
    player.dual = true;
    player.known = {92089};
    player.m_canTitanGrip = false;
    player.hasMain = true;
    player.hasOff = true;
    player.fixtureMain.info = {2, 1, 17};
    player.fixtureOff.info = {2, 7, 13};
    assert(player.FindSwapSlot(&bag) == EQUIPMENT_SLOT_OFFHAND);
    player.fixtureOff.info = {2, 8, 17};
    assert(player.FindSwapSlot(&bag) == EQUIPMENT_SLOT_MAINHAND);
    player.cls = CLASS_WARRIOR;
    player.m_canTitanGrip = true;
    player.fixtureOff.info = {2, 7, 13};
    assert(player.FindSwapSlot(&bag) == EQUIPMENT_SLOT_MAINHAND);
    player.cls = CLASS_DEMON_HUNTER;
    player.known.clear();
    assert(player.FindSwapSlot(&bag) == EQUIPMENT_SLOT_MAINHAND);
    player.known = {92089};
    player.fixtureOff.info = {2, 7, 13};
    ItemTemplate oneHand{2, 7, 13};
    assert(player.FindSwapSlot(&oneHand) == EQUIPMENT_SLOT_OFFHAND);
    ItemTemplate polearm{2, 6, 13};
    assert(player.FindSwapSlot(&polearm) == EQUIPMENT_SLOT_MAINHAND);
    player.fixtureOff.info = {2, 8, 17};
    assert(player.FindSwapSlot(&oneHand) == EQUIPMENT_SLOT_OFFHAND);
    assert(player.FindSwapSlot(&bag) == EQUIPMENT_SLOT_MAINHAND);
}
