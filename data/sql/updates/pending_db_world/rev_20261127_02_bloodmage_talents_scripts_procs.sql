-- Bloodmage conformance fix wave (Lot 2): talent script bindings and spell_proc corrections.
--
-- 1. spell_script_names bindings for new Bloodmage talent scripts in AscensionBloodmageTalents.cpp:
--    - 704654 Ultra Instinct: non-refreshing -1s duration cut per crit (Q-bm-8, O-10).
--    - 806182 Shadow Vigil: update target temporary threat modifiers on apply/remove (Q-bm-17, O-10).
--    - 806274 Aortic Aegis: fan cast-rank Blood Veil to target's subgroup within 45 yd (Q-bm-22, O-10).
--    - 804857 Blood Trail: suppress Effect[1] periodic trigger of 804859 for Mortal Form allies (S-9).
--    - 806212, 807780-807785 Aortic Assault: gate E2 Clotting detonation (806214) on owning 704115 (S-14).
--    - 800782 Blood Howl: add minimum threat on empty threat list and call TauntUpdate (S-18).
--    - 706605 Blood Feast: trigger Life's Essence (520312) burst on channel expiry when Arterial Bind (681077) is known.
--    - 680828 Darkfallen Lament: grant silence and interrupt immunity while channeling.
--
-- 2. spell_proc updates:
--    - 680733 Bloodcraft: set AttributesMask = 2 (PROC_ATTR_TRIGGERED_CAN_PROC) so triggered Darkfallen Lament ticks
--      (630874) can proc Bloodcraft (524182).
--    - 704633 Flesh Foundry: set ProcFlags = 104724 (add positive spell crit flags 0x8000 | 0x800) and SpellTypeMask = 3
--      (DAMAGE | HEAL) so healing critical strikes reduce Sated (532125) duration and Fleshcraft (801952) cooldown.
--    - 504711 Animated Blood Heal Passive: set AttributesMask = 2 (PROC_ATTR_TRIGGERED_CAN_PROC) so triggered Blood
--      Strike (589023) casts proc 592015 owner healing (S-11).
--    - 562572 Accursed Form: add spell_proc for E2 Marrowbite (504553) on melee auto-attacks and melee-class abilities
--      (ProcFlags = 20, SpellTypeMask = 1, SpellPhaseMask = 2, DisableEffectsMask = 3, Chance = 100) (S-15).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (
    704654, 806182, 806274,
    802313, 501662, 501663, 501664, 501665, 501666, 501667, 501668, 501669, 501670, 572116,
    804857, 804859,
    806212, 807780, 807781, 807782, 807783, 807784, 807785,
    800782, 706605, 680828
) AND `ScriptName` IN (
    'aura_ascension_bloodmage_ultra_instinct',
    'aura_ascension_bloodmage_shadow_vigil',
    'aura_ascension_bloodmage_aortic_aegis',
    'aura_ascension_bloodmage_bloodthorns',
    'aura_ascension_bloodmage_blood_trail',
    'spell_ascension_bloodmage_trail_of_blood',
    'aura_ascension_bloodmage_aortic_assault',
    'aura_ascension_bloodmage_blood_howl',
    'aura_ascension_bloodmage_blood_feast',
    'aura_ascension_bloodmage_darkfallen_lament'
);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704654, 'aura_ascension_bloodmage_ultra_instinct'),
(806182, 'aura_ascension_bloodmage_shadow_vigil'),
(806274, 'aura_ascension_bloodmage_aortic_aegis'),
(804857, 'aura_ascension_bloodmage_blood_trail'),
(806212, 'aura_ascension_bloodmage_aortic_assault'),
(807780, 'aura_ascension_bloodmage_aortic_assault'),
(807781, 'aura_ascension_bloodmage_aortic_assault'),
(807782, 'aura_ascension_bloodmage_aortic_assault'),
(807783, 'aura_ascension_bloodmage_aortic_assault'),
(807784, 'aura_ascension_bloodmage_aortic_assault'),
(807785, 'aura_ascension_bloodmage_aortic_assault'),
(800782, 'aura_ascension_bloodmage_blood_howl'),
(706605, 'aura_ascension_bloodmage_blood_feast'),
(680828, 'aura_ascension_bloodmage_darkfallen_lament');

DELETE FROM `spell_proc` WHERE `SpellId` IN (680733, 704633, 504711, 562572);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680733, 0, 26, 0, 0, 4096, 69972, 1, 2, 0, 2, 0, 0, 100, 0, 0),
(704633, 0, 0, 0, 0, 0, 104724, 3, 2, 2, 0, 0, 0, 0, 0, 0),
(504711, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 2, 0, 0, 100, 0, 0),
(562572, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 3, 0, 100, 0, 0);
