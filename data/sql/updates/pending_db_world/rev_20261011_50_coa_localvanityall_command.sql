-- GM commands .localvanityall / .localtransmogall [player]: permanently grant
-- the full Ascension vanity (mounts, companions, bank unlocks, etc.) or
-- transmog/appearance collection to a player's account
-- (AscensionCompat.cpp AscensionCollectionService::GrantFullVanityCollection
-- / GrantFullAppearanceCollection), so CoA.UnlockAllVanity and
-- CoA.UnlockLocalAppearanceCatalog can stay off and still be unlocked
-- per-account on request.
DELETE FROM `command` WHERE `name` IN ('localvanityall', 'localtransmogall');
INSERT IGNORE INTO `command` (`name`, `security`, `help`) VALUES
('localvanityall', 3, 'Syntax: .localvanityall [$player]\nPermanently grants the full Ascension vanity collection (mounts, companions, bank unlocks, etc.) to $player, or yourself/your target when omitted. $player must be online.'),
('localtransmogall', 3, 'Syntax: .localtransmogall [$player]\nPermanently grants the full Ascension transmog/appearance collection to $player, or yourself/your target when omitted. $player must be online.');
