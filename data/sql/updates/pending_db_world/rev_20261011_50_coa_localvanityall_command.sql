-- GM commands .localvanityall / .localtransmogall / .localmysticaltarall
-- [player]: permanently grant the full Ascension vanity (mounts,
-- companions, bank unlocks, etc.) or transmog/appearance collection to a
-- player's account (AscensionCompat.cpp
-- AscensionCollectionService::GrantFullVanityCollection /
-- GrantFullAppearanceCollection / GrantMysticAltarVanityItems), so
-- CoA.UnlockAllVanity and CoA.UnlockLocalAppearanceCatalog can stay off and
-- still be unlocked per-account on request. .localmysticaltarall grants the
-- 17 Mystic Altar vanity items regardless of this realm's
-- CoA.RealmOffersMysticAltars setting, since account_vanity_collection
-- ownership isn't realm-scoped.
DELETE FROM `command` WHERE `name` IN ('localvanityall', 'localtransmogall', 'localmysticaltarall');
INSERT IGNORE INTO `command` (`name`, `security`, `help`) VALUES
('localvanityall', 3, 'Syntax: .localvanityall [$player]\nPermanently grants the full Ascension vanity collection (mounts, companions, bank unlocks, etc.) to $player, or yourself/your target when omitted. $player must be online.'),
('localtransmogall', 3, 'Syntax: .localtransmogall [$player]\nPermanently grants the full Ascension transmog/appearance collection to $player, or yourself/your target when omitted. $player must be online.'),
('localmysticaltarall', 3, 'Syntax: .localmysticaltarall [$player]\nPermanently grants the 17 Mystic Altar vanity items to $player''s account, regardless of whether this realm offers Mystic Altars. $player must be online.');
