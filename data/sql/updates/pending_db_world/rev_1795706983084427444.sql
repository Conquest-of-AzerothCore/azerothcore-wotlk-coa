-- Set scoped TBC five-player dungeon boss/form Mythic health to 0.5 of the original Mythic budgets.
-- Derive Normal and Heroic from that Mythic target using the existing 1 / 1.44 / 1.88 health ladder.
-- Only explicit boss/form entries across all 16 listed converted TBC five-player maps are changed; raids, world bosses,
-- trash, damage multipliers, spell multipliers and attack timings remain unchanged. Old Hillsbrad (560) is a
-- Classic-expansion instance; Magtheridon (544) and Serpentshrine Cavern (548) are raids and are excluded.

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17879 THEN 406824
        WHEN 17880 THEN 508484
        WHEN 17881 THEN 635606
    END
WHERE `map_id` = 269 AND `difficulty` = 0 AND `entry` IN (17879, 17880, 17881);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17879 THEN 585826
        WHEN 17880 THEN 732217
        WHEN 17881 THEN 915273
    END
WHERE `map_id` = 269 AND `difficulty` = 1 AND `entry` IN (17879, 17880, 17881);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17879 THEN 764829
        WHEN 17880 THEN 955950
        WHEN 17881 THEN 1194940
    END
WHERE `map_id` = 269 AND `difficulty` = 2 AND `entry` IN (17879, 17880, 17881);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 16807 THEN 345802
        WHEN 16808 THEN 508484
        WHEN 16809 THEN 508484
        WHEN 20923 THEN 254242
    END
WHERE `map_id` = 540 AND `difficulty` = 0 AND `entry` IN (16807, 16808, 16809, 20923);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 16807 THEN 497955
        WHEN 16808 THEN 732217
        WHEN 16809 THEN 732217
        WHEN 20923 THEN 366109
    END
WHERE `map_id` = 540 AND `difficulty` = 1 AND `entry` IN (16807, 16808, 16809, 20923);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 16807 THEN 650108
        WHEN 16808 THEN 955950
        WHEN 16809 THEN 955950
        WHEN 20923 THEN 477975
    END
WHERE `map_id` = 540 AND `difficulty` = 2 AND `entry` IN (16807, 16808, 16809, 20923);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17377 THEN 240328
        WHEN 17380 THEN 213624
        WHEN 17381 THEN 305092
    END
WHERE `map_id` = 542 AND `difficulty` = 0 AND `entry` IN (17377, 17380, 17381);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17377 THEN 346072
        WHEN 17380 THEN 307618
        WHEN 17381 THEN 439333
    END
WHERE `map_id` = 542 AND `difficulty` = 1 AND `entry` IN (17377, 17380, 17381);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17377 THEN 451816
        WHEN 17380 THEN 401613
        WHEN 17381 THEN 573573
    END
WHERE `map_id` = 542 AND `difficulty` = 2 AND `entry` IN (17377, 17380, 17381);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17306 THEN 292380
        WHEN 17307 THEN 104710
        WHEN 17308 THEN 325460
        WHEN 17536 THEN 254242
        WHEN 17537 THEN 254242
    END
WHERE `map_id` = 543 AND `difficulty` = 0 AND `entry` IN (17306, 17307, 17308, 17536, 17537);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17306 THEN 421027
        WHEN 17307 THEN 150783
        WHEN 17308 THEN 468663
        WHEN 17536 THEN 366109
        WHEN 17537 THEN 366109
    END
WHERE `map_id` = 543 AND `difficulty` = 1 AND `entry` IN (17306, 17307, 17308, 17536, 17537);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17306 THEN 549674
        WHEN 17307 THEN 196855
        WHEN 17308 THEN 611865
        WHEN 17536 THEN 477975
        WHEN 17537 THEN 477975
    END
WHERE `map_id` = 543 AND `difficulty` = 2 AND `entry` IN (17306, 17307, 17308, 17536, 17537);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17796 THEN 343228
        WHEN 17797 THEN 200000
        WHEN 17798 THEN 508484
    END
WHERE `map_id` = 545 AND `difficulty` = 0 AND `entry` IN (17796, 17797, 17798);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17796 THEN 494248
        WHEN 17797 THEN 288000
        WHEN 17798 THEN 732217
    END
WHERE `map_id` = 545 AND `difficulty` = 1 AND `entry` IN (17796, 17797, 17798);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17796 THEN 645268
        WHEN 17797 THEN 376000
        WHEN 17798 THEN 955950
    END
WHERE `map_id` = 545 AND `difficulty` = 2 AND `entry` IN (17796, 17797, 17798);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17770 THEN 330516
        WHEN 17826 THEN 264436
        WHEN 17882 THEN 335630
        WHEN 18105 THEN 317804
    END
WHERE `map_id` = 546 AND `difficulty` = 0 AND `entry` IN (17770, 17826, 17882, 18105);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17770 THEN 475943
        WHEN 17826 THEN 380788
        WHEN 17882 THEN 483307
        WHEN 18105 THEN 457638
    END
WHERE `map_id` = 546 AND `difficulty` = 1 AND `entry` IN (17770, 17826, 17882, 18105);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17770 THEN 621370
        WHEN 17826 THEN 497140
        WHEN 17882 THEN 630984
        WHEN 18105 THEN 597472
    END
WHERE `map_id` = 546 AND `difficulty` = 2 AND `entry` IN (17770, 17826, 17882, 18105);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17941 THEN 345802
        WHEN 17942 THEN 508484
        WHEN 17991 THEN 508484
    END
WHERE `map_id` = 547 AND `difficulty` = 0 AND `entry` IN (17941, 17942, 17991);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17941 THEN 497955
        WHEN 17942 THEN 732217
        WHEN 17991 THEN 732217
    END
WHERE `map_id` = 547 AND `difficulty` = 1 AND `entry` IN (17941, 17942, 17991);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17941 THEN 650108
        WHEN 17942 THEN 955950
        WHEN 17991 THEN 955950
    END
WHERE `map_id` = 547 AND `difficulty` = 2 AND `entry` IN (17941, 17942, 17991);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 20870 THEN 355972
        WHEN 20885 THEN 508484
        WHEN 20886 THEN 508484
        WHEN 20912 THEN 508530
    END
WHERE `map_id` = 552 AND `difficulty` = 0 AND `entry` IN (20870, 20885, 20886, 20912);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 20870 THEN 512600
        WHEN 20885 THEN 732217
        WHEN 20886 THEN 732217
        WHEN 20912 THEN 732283
    END
WHERE `map_id` = 552 AND `difficulty` = 1 AND `entry` IN (20870, 20885, 20886, 20912);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 20870 THEN 669228
        WHEN 20885 THEN 955950
        WHEN 20886 THEN 955950
        WHEN 20912 THEN 956036
    END
WHERE `map_id` = 552 AND `difficulty` = 2 AND `entry` IN (20870, 20885, 20886, 20912);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17975 THEN 335630
        WHEN 17976 THEN 355940
        WHEN 17977 THEN 508484
        WHEN 17978 THEN 315290
        WHEN 17980 THEN 355940
    END
WHERE `map_id` = 553 AND `difficulty` = 0 AND `entry` IN (17975, 17976, 17977, 17978, 17980);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17975 THEN 483307
        WHEN 17976 THEN 512553
        WHEN 17977 THEN 732217
        WHEN 17978 THEN 454017
        WHEN 17980 THEN 512553
    END
WHERE `map_id` = 553 AND `difficulty` = 1 AND `entry` IN (17975, 17976, 17977, 17978, 17980);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17975 THEN 630984
        WHEN 17976 THEN 669167
        WHEN 17977 THEN 955950
        WHEN 17978 THEN 592745
        WHEN 17980 THEN 669167
    END
WHERE `map_id` = 553 AND `difficulty` = 2 AND `entry` IN (17975, 17976, 17977, 17978, 17980);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 19218 THEN 254242
        WHEN 19219 THEN 355940
        WHEN 19220 THEN 345802
        WHEN 19221 THEN 335630
        WHEN 19710 THEN 254242
    END
WHERE `map_id` = 554 AND `difficulty` = 0 AND `entry` IN (19218, 19219, 19220, 19221, 19710);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 19218 THEN 366109
        WHEN 19219 THEN 512553
        WHEN 19220 THEN 497955
        WHEN 19221 THEN 483307
        WHEN 19710 THEN 366109
    END
WHERE `map_id` = 554 AND `difficulty` = 1 AND `entry` IN (19218, 19219, 19220, 19221, 19710);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 19218 THEN 477975
        WHEN 19219 THEN 669167
        WHEN 19220 THEN 650108
        WHEN 19221 THEN 630984
        WHEN 19710 THEN 477975
    END
WHERE `map_id` = 554 AND `difficulty` = 2 AND `entry` IN (19218, 19219, 19220, 19221, 19710);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18667 THEN 508484
        WHEN 18708 THEN 1398332
        WHEN 18731 THEN 508484
        WHEN 18732 THEN 345802
    END
WHERE `map_id` = 555 AND `difficulty` = 0 AND `entry` IN (18667, 18708, 18731, 18732);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18667 THEN 732217
        WHEN 18708 THEN 2013598
        WHEN 18731 THEN 732217
        WHEN 18732 THEN 497955
    END
WHERE `map_id` = 555 AND `difficulty` = 1 AND `entry` IN (18667, 18708, 18731, 18732);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18667 THEN 955950
        WHEN 18708 THEN 2628864
        WHEN 18731 THEN 955950
        WHEN 18732 THEN 650108
    END
WHERE `map_id` = 555 AND `difficulty` = 2 AND `entry` IN (18667, 18708, 18731, 18732);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18472 THEN 302634
        WHEN 18473 THEN 302634
        WHEN 23035 THEN 508530
    END
WHERE `map_id` = 556 AND `difficulty` = 0 AND `entry` IN (18472, 18473, 23035);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18472 THEN 435793
        WHEN 18473 THEN 435793
        WHEN 23035 THEN 732283
    END
WHERE `map_id` = 556 AND `difficulty` = 1 AND `entry` IN (18472, 18473, 23035);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18472 THEN 568952
        WHEN 18473 THEN 568952
        WHEN 23035 THEN 956036
    END
WHERE `map_id` = 556 AND `difficulty` = 2 AND `entry` IN (18472, 18473, 23035);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18341 THEN 394076
        WHEN 18343 THEN 355940
        WHEN 18344 THEN 345802
    END
WHERE `map_id` = 557 AND `difficulty` = 0 AND `entry` IN (18341, 18343, 18344);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18341 THEN 567470
        WHEN 18343 THEN 512553
        WHEN 18344 THEN 497955
    END
WHERE `map_id` = 557 AND `difficulty` = 1 AND `entry` IN (18341, 18343, 18344);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18341 THEN 740863
        WHEN 18343 THEN 669167
        WHEN 18344 THEN 650108
    END
WHERE `map_id` = 557 AND `difficulty` = 2 AND `entry` IN (18341, 18343, 18344);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18371 THEN 335630
        WHEN 18373 THEN 335630
    END
WHERE `map_id` = 558 AND `difficulty` = 0 AND `entry` IN (18371, 18373);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18371 THEN 483307
        WHEN 18373 THEN 483307
    END
WHERE `map_id` = 558 AND `difficulty` = 1 AND `entry` IN (18371, 18373);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 18371 THEN 630984
        WHEN 18373 THEN 630984
    END
WHERE `map_id` = 558 AND `difficulty` = 2 AND `entry` IN (18371, 18373);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17848 THEN 508484
        WHEN 17862 THEN 406824
        WHEN 18096 THEN 635606
    END
WHERE `map_id` = 560 AND `difficulty` = 0 AND `entry` IN (17848, 17862, 18096);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17848 THEN 732217
        WHEN 17862 THEN 585826
        WHEN 18096 THEN 915273
    END
WHERE `map_id` = 560 AND `difficulty` = 1 AND `entry` IN (17848, 17862, 18096);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 17848 THEN 955950
        WHEN 17862 THEN 764829
        WHEN 18096 THEN 1194940
    END
WHERE `map_id` = 560 AND `difficulty` = 2 AND `entry` IN (17848, 17862, 18096);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 24560 THEN 81366
        WHEN 24664 THEN 635664
        WHEN 24723 THEN 635664
        WHEN 24744 THEN 447508
    END
WHERE `map_id` = 585 AND `difficulty` = 0 AND `entry` IN (24560, 24664, 24723, 24744);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 24560 THEN 117167
        WHEN 24664 THEN 915356
        WHEN 24723 THEN 915356
        WHEN 24744 THEN 644411
    END
WHERE `map_id` = 585 AND `difficulty` = 1 AND `entry` IN (24560, 24664, 24723, 24744);

UPDATE `coa_dungeon_rescale_budget`
SET `health` = CASE `entry`
        WHEN 24560 THEN 152968
        WHEN 24664 THEN 1195048
        WHEN 24723 THEN 1195048
        WHEN 24744 THEN 841315
    END
WHERE `map_id` = 585 AND `difficulty` = 2 AND `entry` IN (24560, 24664, 24723, 24744);
