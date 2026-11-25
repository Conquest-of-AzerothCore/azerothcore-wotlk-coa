# Pet battle client addons

Upstream's client addons from azerothcore-linux-server commit 22bb7f3, unchanged. Players need all three; the server
speaks their protocol (`mod-coa-pet-battles`). Copy the folders in `AddOns/` into the client's `Interface/AddOns/`.

- `AcoreLib` — the hidden addon-whisper transport (`ACORE` prefix) and the hello/ping handshake.
- `wotlk_petbattle` — the battle window: abilities, swaps, the trap, health bars, damage numbers. `/pbtest` holds GM
  tools.
- `wotlk_pets` — the pet journal (`/pets`): pets, abilities, teams, feeding, the follower, the 3D previews, the zone
  levels on the world map and the wild pet blips on the minimap.

`MANIFEST.sha256` pins every file; `tools/pet_data/test_client_addons.py` checks the copies against it (and against an
upstream checkout when `PET_BATTLES_UPSTREAM` names one). Change a file only with a reason recorded in the phase 5
design, then refresh the manifest.
