-- Standard of Recovery 500260 is the only Guardian Standard whose cast tooltip
-- bills the wrong amount. Its description read
-- '${$500248m1+$500248ppl1+$STR*.25}', but 500248 is the direct heal that the
-- standard's own aura 500266 triggers: 500248's effect 0 is EffectBasePoints 1
-- with EffectDieSides 1, so $500248m1 renders 2, and the cast tooltip
-- advertised 2 + 0.25 x Strength (33 at the reporter's 124 Strength) while the
-- aura actually restores its own effect amount, 79 + 1 = 80, plus the same
-- Strength term (111). That 80 is exactly what the buff's own aura tooltip in
-- Spell.dbc column 187 already advertises as '${$w1+$STR*.25}', and what
-- aura_ascension_guardian_recovery::Tick now applies. Every other Standard's
-- cast text references its own aura spell (500263 -> $500265, 500547 ->
-- $500548, 501538 -> $501538's aura, 706805 -> $500602, 800346 -> $500299),
-- so 500260's reference to the triggered heal is the outlier, not the pattern.
--
-- The client's Spell.dbc cannot be edited from this repository, so publish the
-- spell's own text with that one term re-pointed at the aura: '$500266m1' is
-- the standard's own effect amount, the same value the tick applies and the
-- buff tooltip advertises. Every other clause is the client's, and every one of
-- them already describes what the spell does: '$d' is 500260's DurationIndex
-- 608 (5 min, the summon's lifetime), '$500266a' the aura's EffectRadiusIndex
-- 217 (30 yds), '$500266t1' its EffectAmplitude 3000 (3 sec),
-- '${$500266m1+$STR*.25}' its effect 0 amount 80 plus the owner's Strength at
-- 0.25, which is the term the tick applies from
-- owner->GetStat(STAT_STRENGTH), and '$500266s2' its effect 1 amount 6, aura
-- 319 SPELL_AURA_ASCENSION_MOD_HEALING_RECEIVED_PCT, which Unit.cpp applies to
-- the ally as a healing-taken multiplier.
--
-- The '@ext:...:ext@' wrapper around the last sentence is dropped rather than
-- republished: no row in this table carries an '@ext:' or ':ext@' tag, and the
-- reporter's client renders that wrapper literally in this very tooltip, so a
-- tag the client never strips is a visible defect rather than the intended
-- shift-reveal. The sentence itself is kept.
--
-- AscensionCompat already streams coa_client_spell_description rows to the
-- client as SMSG_PATCH_SPELL, so no code change is needed (#6604).

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (500260);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(500260,'Throw down a |cffffffffStandard of Recovery|r for $d, healing allies within $500266a yds for ${$500266m1+$STR*.25} health every $500266t1 sec, scaling with your Strength, and increasing all healing they receive by $500266s2%.\r\n\r\nOnly 1 |cffffffffStandard|r can be active at a time.');
