# Equip grant (`behaviour_metric_delta`, `kind: "equip_grant"`, ADR 1198)

A passive that allows a weapon in the off hand ("Allows you to dual wield and to wield a Two-Handed Mace, Sword, or
Polearm in each hand"), read on the equip result itself. After the base steps the skill line of every pair is set,
`spell` is unlearned, and for each of `pairs` (`{main_hand, off_hand, skill_line, source}`) the main-hand item is
equipped and the off-hand equip is sent with `rejected: true` (the harness fails the step when it is accepted). `spell`
is then learned and every pair is equipped again from the bags (no second add), the off hand now without `rejected`. Each arm reads `equipped_item`
on slots 15 and 16.

The verdict is `ok` when every pair holds its main hand in both arms, does not hold its off-hand item without the
grant and holds it with the grant; any other reading alerts and a missing read is not judged. The derived metric
`equip_grant_accepted` is an event: the server's equip handler acting on the request, not a stored value read back.

Sun Cleric: Valkyr's Grip 707072, pairs 2524 / 30754 (dual wield), 2529 (two-hand sword), 1197 (two-hand mace) and
11864 (polearm), each two-hander in both hands.
