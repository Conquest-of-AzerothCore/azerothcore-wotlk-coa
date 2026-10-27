CLI_DESCRIPTION = """Refresh apps/coa-gameplay-test/balance/item_pool.json from item_template and two DBCs.

Queries item_template (class IN (2, 4), ScalingStatDistribution != 0, Quality IN (4, 6, 7), AllowableClass = -1)
through the configured world database (apps/coa-gameplay-test/run.py's Connection/read_config, the same
pattern apps/coa-dbc/capture_sql.py uses), tags each row with the primary stat(s) its ScalingStatDistribution
id carries (read directly from ScalingStatDistribution.dbc's StatMod array), and drops every item that also
appears in VanityCollection.dbc: those heirlooms additionally require AscensionCompat.cpp's
RequiresVanityRealmLevel/AccountHasVanityRealmLevel (an account that has reached level 60 or prestiged on this
realm), which a synthetic balance-suite fixture account never has regardless of the character's own level, and
CanEquipItem rejects them with EQUIP_ERR_CANT_DO_RIGHT_NOW below that. Also queries plain (non-scaling)
level-appropriate necklaces (class 4, subclass 0, InventoryType 2, Quality IN (1, 2, 3), RequiredLevel <= 60):
no account-unrestricted ScalingStatDistribution necklace exists below RequiredLevel 45, so generate_gear.py
falls back to the closest-item-level plain necklace for the levels that gap covers (20, 40), the deterministic
fallback this suite's design calls for when no scaling item exists for a slot. Needs the coa-verify-env image
for a MySQL client and a readable CoA dbc directory; does not need a running worldserver.
"""

import argparse
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ITEM_POOL_PATH = HERE / "item_pool.json"

ITEM_MOD_AGILITY = 3
ITEM_MOD_STRENGTH = 4
ITEM_MOD_INTELLECT = 5
STAT_MOD = {"agility": ITEM_MOD_AGILITY, "strength": ITEM_MOD_STRENGTH, "intellect": ITEM_MOD_INTELLECT}

ITEM_TEMPLATE_QUERY = (
    "SELECT JSON_OBJECT('entry', entry, 'class', class, 'subclass', subclass, 'InventoryType', InventoryType, "
    "'Quality', Quality, 'RequiredLevel', RequiredLevel, 'ItemLevel', ItemLevel, "
    "'ssd', ScalingStatDistribution) FROM item_template "
    "WHERE ScalingStatDistribution != 0 AND class IN (2, 4) AND Quality IN (4, 6, 7) AND AllowableClass = -1 "
    "ORDER BY InventoryType, subclass, entry;"
)

NECK_FALLBACK_QUERY = (
    "SELECT JSON_OBJECT('entry', entry, 'class', class, 'subclass', subclass, 'InventoryType', InventoryType, "
    "'Quality', Quality, 'RequiredLevel', RequiredLevel, 'ItemLevel', ItemLevel, 'ssd', ScalingStatDistribution) "
    "FROM item_template WHERE class = 4 AND subclass = 0 AND InventoryType = 2 AND AllowableClass = -1 "
    "AND RequiredLevel <= 60 AND Quality IN (1, 2, 3) ORDER BY entry;"
)


def run_query(config, mysql, query):
    sys.path.insert(0, str(ROOT / "apps/coa-gameplay-test"))
    import run

    settings = run.read_config(config)
    connection = run.Connection.parse(run.source_setting(settings, "WorldDatabaseInfo"))
    with tempfile.TemporaryDirectory(prefix="coa-balance-gear-") as temporary:
        defaults = Path(temporary) / "client.cnf"
        with defaults.open("x", encoding="utf-8") as stream:
            defaults.chmod(0o600)
            stream.write("[client]\n" + "\n".join(
                f"{key}={run.cnf_quote(str(value))}" for key, value in
                [("host", connection.host), ("port", connection.port), ("user", connection.user),
                 ("password", connection.password)]))
        command = [str(mysql), "--defaults-extra-file=" + str(defaults), "--batch", "--raw",
                   "--skip-column-names", "--default-character-set=utf8mb4", "--connect-timeout=10",
                   "--database=" + connection.database]
        result = subprocess.run(command, input=query, text=True, capture_output=True, timeout=60)
        if result.returncode:
            raise SystemExit("item_template query failed: " + result.stderr)
        return [json.loads(line) for line in result.stdout.splitlines() if line.strip()]


def load_wdbc_int32_records(path):
    data = Path(path).read_bytes()
    magic, record_count, field_count, record_size, _string_block_size = struct.unpack_from("<4sIIII", data, 0)
    if magic != b"WDBC":
        raise SystemExit(f"{path} is not a WDBC file")
    header_size = 20
    records = []
    for index in range(record_count):
        offset = header_size + index * record_size
        records.append(struct.unpack_from("<" + "i" * (record_size // 4), data, offset))
    return records, field_count, record_size


def scaling_stat_distributions(dbc_dir):
    records, _field_count, _record_size = load_wdbc_int32_records(Path(dbc_dir) / "ScalingStatDistribution.dbc")
    distributions = {}
    for record in records:
        ssd_id = record[0]
        distributions[ssd_id] = ({value for value in record[1:11] if value != -1}, record[21])
    return distributions


def vanity_collection_item_ids(dbc_dir):
    records, _field_count, _record_size = load_wdbc_int32_records(Path(dbc_dir) / "VanityCollection.dbc")
    return {record[1] for record in records if record[1]}


NO_SCALING_CAP_MAX_LEVEL = 999


def build_item_pool(config, mysql, dbc_dir):
    ssd_rows = run_query(config, mysql, ITEM_TEMPLATE_QUERY)
    fallback_rows = run_query(config, mysql, NECK_FALLBACK_QUERY)
    distributions = scaling_stat_distributions(dbc_dir)
    vanity_ids = vanity_collection_item_ids(dbc_dir)
    seen_entries = set()
    items = []
    for row in ssd_rows + fallback_rows:
        if row["entry"] in vanity_ids or row["entry"] in seen_entries:
            continue
        seen_entries.add(row["entry"])
        mods, max_level = distributions.get(row["ssd"], (set(), NO_SCALING_CAP_MAX_LEVEL))
        stats = sorted(name for name, mod in STAT_MOD.items() if mod in mods)
        items.append({
            "entry": row["entry"], "class": row["class"], "subclass": row["subclass"],
            "inventory_type": row["InventoryType"], "quality": row["Quality"],
            "required_level": row["RequiredLevel"], "item_level": row["ItemLevel"],
            "ssd": row["ssd"], "stats": stats, "max_level": max_level,
        })
    items.sort(key=lambda item: (item["inventory_type"], item["subclass"], item["entry"]))
    return items


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--mysql", type=Path, required=True)
    parser.add_argument("--dbc-dir", type=Path, required=True)
    args = parser.parse_args(argv)
    items = build_item_pool(args.config, args.mysql, args.dbc_dir)
    ITEM_POOL_PATH.write_text(json.dumps({
        "schema": 1,
        "source": "item_template (class IN (2, 4), ScalingStatDistribution != 0, Quality IN (4, 6, 7), "
                   "AllowableClass = -1; plus plain class 4/subclass 0/InventoryType 2 necklaces, Quality IN "
                   "(1, 2, 3), as a fallback for the levels with no scaling necklace) via the configured world "
                   "database, joined with ScalingStatDistribution.dbc's StatMod, minus every item_id in "
                   "VanityCollection.dbc (AscensionCompat.cpp's RequiresVanityRealmLevel gates those behind an "
                   "account-wide level 60/prestige flag a synthetic fixture account never has)",
        "items": items,
    }, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {ITEM_POOL_PATH} ({len(items)} items)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
