-- #11908: remove the duplicate marker restore of pickup 95785, keep 6940916 at the cart
DELETE FROM `gameobject`
WHERE `guid` = 6940915 AND `id` = 95785 AND `map` = 0
  AND `position_x` BETWEEN -10469.0 AND -10468.0
  AND `position_y` BETWEEN 1943.5 AND 1944.5;
