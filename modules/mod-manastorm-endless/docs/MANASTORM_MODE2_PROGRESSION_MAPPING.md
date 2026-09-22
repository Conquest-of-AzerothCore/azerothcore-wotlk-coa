# Native Mode 2 progression mapping — Patch-M evidence

## Scope

This mapping uses the supplied Patch-M `ManastormMessages.dbc`, `Manastorm.dbc`, and `DungeonEncounter.dbc`. Native Mode 2 receives completed depth through opcode `0x65E`; the client renders matching message rows locally. SQL therefore records gameplay trigger/ownership state, not duplicated toast text.

## High-confidence staged boss/encounter introductions

| Content | Track(s) | Trigger | Complete | Intro segment(s) | Segment grant(s) | Message evidence |
|---|---|---:|---:|---|---|---|
| Manaclaw | Normal + Endgame | 38 | 39 | N:411, E:476 | 411, 476 | N:701→702, E:700→703 |
| Muckrake | Normal + Endgame | 65 | 66 | N:407, E:480 | 407, 480 | N:723→724, E:721→722 |
| Grol the Destroyer | Normal + Endgame | 70 | 71 | N:409, E:478 | 409, 478 | N:800→802, E:801→803 |
| Archmage Allistarj | Normal + Endgame | 75 | 76 | N:552, E:553 | 552, 553 | N:9→264, E:20→275 |
| Razelikh the Defiler | Normal + Endgame | 90 | 91 | N:542, E:543 | 542, 543 | N:727→725, E:728→726 |
| Solakar Flamewreath | Normal + Endgame | 102 | 103 | N:669, E:668 | 668, 669 | N:730→732, E:731→733 |
| Nyx and Nocturna | Endgame | 108 | 109 | E:949 | 949 | E:622→1201 |
| High Priestess Mar'li | Endgame | 115 | 116 | E:601 | 601 | E:24→278 |
| Leafborn Sentinel | Endgame | 123 | 124 | E:950 | 950 | E:1203→1204 |
| Mechatron | Endgame | 128 | 129 | E:951 | 951 | E:625→1206 |
| High Priest Thekal | Endgame | 130 | 131 | E:602 | 602 | E:25→279 |
| Jin'do the Hexxer | Endgame | 175 | 176 | E:605 | 605 | E:28→282 |
| High Priestess Jeklik | Endgame | 190 | 191 | E:606 | 606 | E:29→283 |
| Hakkar | Endgame | 205 | 206 | E:607 | 607 | E:30→284 |
| Lucifron | Endgame | 235 | 236 | E:608 | 608 | E:32→286 |
| Magmadar | Endgame | 250 | 251 | E:609 | 609 | E:33→287 |
| Garr | Endgame | 265 | 266 | E:611 | 611 | E:34→288 |
| Shazzrah | Endgame | 280 | 281 | E:612 | 612 | E:35→289 |
| Baron Geddon | Endgame | 295 | 296 | E:613 | 613 | E:36→290 |
| Sulfuron Harbinger | Endgame | 310 | 311 | E:614 | 614 | E:37→291 |
| Golemagg the Incinerator | Endgame | 335 | 336 | E:615 | 615 | E:38→292 |
| Ragnaros | Endgame | 350 | 351 | E:670 | 670 | E:500→501 |
| Onyxia | Endgame | 365 | 366 | E:707 | 707 | E:440→441 |
| Vaelastrasz the Corrupt | Endgame | 425 | 426 | E:617 | 617 | E:39→293 |
| Broodlord Lashlayer | Endgame | 440 | 441 | E:618 | 618 | E:40→294 |
| Firemaw | Endgame | 455 | 456 | E:619 | 619 | E:41→295 |
| Chromaggus | Endgame | 470 | 471 | E:620 | 620 | E:42→296 |
| General Rajaxx | Endgame | 525 | 526 | E:622 | 622 | E:44→298 |
| Buru the Gorger | Endgame | 540 | 541 | E:623 | 623 | E:45→299 |
| Ayamiss the Hunter | Endgame | 555 | 556 | E:624 | 624 | E:46→300 |
| Moam | Endgame | 570 | 571 | E:626 | 626 | E:47→301 |
| Ossirian the Unscarred | Endgame | 595 | 596 | E:625 | 625 | E:48→302 |
| Battleguard Sartura | Endgame | 625 | 626 | E:628 | 628 | E:50→304 |
| Fankriss the Unyielding | Endgame | 640 | 641 | E:629 | 629 | E:51→305 |
| Viscidus | Endgame | 655 | 656 | E:632 | 632 | E:52→306 |
| Princess Huhuran | Endgame | 670 | 671 | E:631 | 631 | E:53→307 |
| Twin Emperors | Endgame | 685 | 686 | E:634 | 634 | E:54→308 |
| Ouro | Endgame | 700 | 701 | E:633 | 633 | E:55→309 |
| C'thun | Endgame | 725 | 726 | E:635 | 635 | E:56→310 |
| Grand Widow Faerlina | Endgame | 755 | 756 | E:641 | 641 | E:58→312 |
| Maexxna | Endgame | 770 | 771 | E:642 | 642 | E:59→313 |
| Noth the Plaguebringer | Endgame | 785 | 786 | E:643 | 643 | E:60→314 |
| Heigan the Unclean | Endgame | 800 | 801 | E:644 | 644 | E:61→315 |
| Loatheb | Endgame | 815 | 816 | E:645 | 645 | E:62→316 |
| Patchwerk | Endgame | 830 | 831 | E:636 | 636 | E:63→317 |
| Grobbulus | Endgame | 845 | 846 | E:637 | 637 | E:64→318 |
| Gluth | Endgame | 860 | 861 | E:638 | 638 | E:65→319 |
| Thaddius | Endgame | 875 | 876 | E:639 | 639 | E:66→320 |
| Instructor Razuvious | Endgame | 890 | 891 | E:646 | 646 | E:67→321 |
| Gothik the Harvester | Endgame | 905 | 906 | E:647 | 647 | E:68→322 |
| Sapphiron | Endgame | 920 | 921 | E:648 | 648 | E:69→323 |
| Kel'Thuzad | Endgame | 945 | 946 | E:649 | 649 | E:70→324 |

## Explicitly excluded from automatic SQL

These are evidence boundaries, not guesses to fill.

| Content/event | Track/depth | Evidence issue | Known segment(s) |
|---|---|---|---|
| Zul'Gurub Wings | Endgame 145 | no single boss encounter family; no matching prior-depth next-Manastorm row | — |
| Admiral Seastomper | Normal 96 | multiple same-content segment variants on this track | 657, 571 |
| Archmage Adeline | Normal 8600 | no matching prior-depth next-Manastorm row | 563 |
| Admiral Seastomper | Endgame 96 | multiple same-content segment variants on this track | 570, 656 |
| Archmage Adeline | Endgame 8600 | no matching prior-depth next-Manastorm row | 562 |
| Bloodlord Mandokir | Endgame 146 | no matching prior-depth next-Manastorm row | 604 |
| Anub'Rekhan | Endgame 741 | no matching prior-depth next-Manastorm row | 640 |
| Andre Firebeard | Endgame 51 | multiple same-content segment variants on this track | 474, 653 |
| Andre Firebeard | Normal 51 | multiple same-content segment variants on this track | 413, 652, 655 |
| General Drakkisath | Normal 104 | no matching prior-depth next-Manastorm row | 658 |
| General Drakkisath | Endgame 104 | no matching prior-depth next-Manastorm row | 659 |
| Warchief Rend Blackhand | Normal 395 | no matching prior-depth next-Manastorm row | 663 |
| Warchief Rend Blackhand | Endgame 380 | no matching prior-depth next-Manastorm row | 662 |
| Xyron the Corruptor | Endgame 119 | no matching prior-depth next-Manastorm row | 948 |

Additional unresolved cases:

- Scarlet Mage Tower has a native "next Manastorm" message at depth 85 on both tracks but no matching permanent-content message at depth 86.
- Dead Mire has a distinct Endgame depth-58 message explicitly unlocking **randomized creatures**, separately from the depth-59 map+creatures milestone.
- Map+creatures milestones are not assigned a forced segment where the supplied evidence does not identify one uniquely.
- Creature replacement probability, weights, archetype matching and duplicate rules remain unknown and disabled.
- Warchief Rend Blackhand is a confirmed track asymmetry: Normal future unlock depth 395 vs Endgame depth 380.
