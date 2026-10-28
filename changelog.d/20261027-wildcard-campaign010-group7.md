## Campaign010 group7 — resumed session

- 270662 Faithful Light: implemented. Existing caster-owned Beacon direct-Holy-heal proc was active, but native effect177 selected any caster Beacon. Shared duration handler now prefers caster-owned ranked aura, preserving legacy fallback except Faithful Light requires own53563. Native30second extension and10%physical mitigation retained; no duplicate proc added.
- 270694 Victorious Charge: partial. Existing Charge cast rule grants native32216 with6000ms rule cooldown; native one-charge Victory Rush consumption present. No confirmed missing route; static-only, not runtime verified or counted.
- 270697 Battle Charge: partial. Native charge movement,90rage units, triggered70%weapon helper270693 and Charge family modifiers present. No missing effect dispatcher found; shapeshift/melee-range behavior remains runtime-unverified, no speculative edits/count.
- 270699 Crushing Charge: implemented. Added missing physical melee ability damage proc requiring caster-owned Crushing Impact270698; native270703 reduces Battle Charge cooldown3000ms, with3000ms internal cooldown. Autos, periodic damage and another caster debuff excluded.
- 278510 Brilliance of Faith: blocked. Preserved user pending-native-data decision: conflicting empower charges/target counts between278513/278514/278515 and parent. No design reconstruction or invented charge behavior.

Cumulative90/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
