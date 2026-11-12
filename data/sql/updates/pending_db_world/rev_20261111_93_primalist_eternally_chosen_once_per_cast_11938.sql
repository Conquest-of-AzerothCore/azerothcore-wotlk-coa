-- Eternally Chosen (802888) summons two Spirits of Life for a Spirit Charge or Primal Rush cast, but it procs on every
-- spell event of the cast, so a pull with many enemies summoned two spirits per enemy hit (#11938). Both spells have a
-- 25-30 sec cooldown: a 1.5 sec proc cooldown keeps one summon per cast.
UPDATE `spell_proc` SET `Cooldown` = 1500 WHERE `SpellId` = 802888;
