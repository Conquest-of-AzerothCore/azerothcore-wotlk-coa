# Level-60 TBC gem requirements

This candidate caps TBC gem item requirements and server-side socket enchantment minimum levels at 60.
All original stats, spells, procs, activation conditions, colors, profession restrictions and IDs remain
unchanged. Requirements already below 60 remain lower. Previously obtained gems and socketed equipment
retain their original effects. The earlier stat-reduction candidate and its client MPQ are superseded.

The pinned baseline in `apps/coa-tests/tbc_gem_rescale/baseline.json` records 232 candidates;
the conversion includes 231 TBC player gems, including meta gems. Soulbound Test Gem, the tonk-only Heavy
Tonk Armor, Juno's Test Gem, Wrath gems and other profession equipment are excluded. Of these items, 167 have item requirements above 60, and 165 original gem enchantments have
minimum levels above 60.

## Generate

```sh
python3 apps/coa-world-content/tbc_gems/build.py --output /path/to/output-directory
```

This generates the SQL and `CoATbcGemRequirementsData.h`. It produces no client data or MPQ.
The SQL changes only `item_template.RequiredLevel`. At startup, the matching server component validates
original item/property/enchantment mappings and caps only the in-memory enchantment minimum level for
eligible gems. It does not create or replace any enchantments, properties or spells. The login hook sends
fresh item queries so clients can refresh cached item requirements.

## Deployment and acceptance

The SQL remains inactive as `rev_20261122_01_coa_tbc_gems_level60.sql.draft` until deployment is authorized.
Install the matching worldserver and activate this migration during an authorized maintenance window;
let the normal updater apply it. No client patch or character database migration is provided or required
by this implementation. Do not distribute the obsolete stat-reduction MPQ.

With the realm's existing client, test socketing an ordinary gem and a meta gem on a level-60 character,
including an already-owned gem and previously socketed equipment. Check original stat/proc magnitudes,
meta activation conditions, profession restrictions and socket bonuses. Client-local socketing restrictions
have not been verified in a rendered client; a restriction there needs investigation before rollout.

## Verification

Use `tools/verify_all.py` with `source,build,harness` and harnesses `tbc_gem_rescale` and `tbc_gem_client`.
The SQL harness checks level caps, unchanged effects and other item fields, outside controls and repeat
application in a temporary database. The C++ harness exercises the actual requirement loader, preservation
of lower gates and effects, rejection of invalid mappings and repeatability. It does not launch a client.
