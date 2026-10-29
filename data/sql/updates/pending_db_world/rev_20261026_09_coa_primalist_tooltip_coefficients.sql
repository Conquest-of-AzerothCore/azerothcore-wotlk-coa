-- Primalist abilities whose tooltips state a spell power or attack power coefficient but that had no
-- spell_bonus_data row. AscensionStockCoefficients clears the stock Spell.dbc multiplier for CoA spells, which
-- leaves spell_bonus_data as the only coefficient channel, so these dealt or healed their base value only.
-- Each row is the tooltip's own coefficient, on the chain head where the ranks are linked.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (803974, 804433, 681130, 802793, 800135, 503265, 503266);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(803974, 0.2, 0, 0.1, 0, 'Primalist: Quake - "$m3+$spn*.2+$AP*.1" Nature damage'),
(804433, 1.2675, 0, 0.12675, 0, 'Primalist: Seismic Spike - "$m1+$spn*1.2675+$AP*0.12675"'),
(681130, 0.355, 0, 0.155, 0, 'Primalist: Mountain Hammer - "$m1+$spn*0.355+$AP*0.155"'),
(802793, 1, 0, 0, 0, 'Primalist: Magma Fissure - "$m1+$spfi*1" (or $spn*1)'),
(800135, 0.3, 0, 0.2, 0, 'Primalist: Hand of the Earthmother - "$m1+$AP*0.2+$BH*0.3"'),
(503265, 0, 0.2, 0, 0.06, 'Primalist: Seismic Crash rank 9 - "$m1+$SP*.20+$AP*0.06" per tick, as the chain head 803981'),
(503266, 0, 0.2, 0, 0.06, 'Primalist: Seismic Crash rank 10 - "$m1+$SP*.20+$AP*0.06" per tick, as the chain head 803981');
