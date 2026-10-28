import ctypes
import os
import re
import struct
from pathlib import Path

LIBC = ctypes.CDLL("libc.so.6", use_errno=True)

IMAGE_BASE = 0x00400000
TLS_S_CURMGR_RVA = 0x00DD2008
PAGE_SIZE = 0x1000

OBJ_PLAYER_GUID_OFFSET = 0xC0
OBJ_FULLLIST_OFFSET = 0x04

CGOBJECT_MOBJ_OFFSET = 0x08
CGOBJECT_TYPEID_OFFSET = 0x14
CGOBJECTDATA_GUID_OFFSET = 0x00

CGUNIT_MUNIT_OFFSET = 0xD0
CGUNITDATA_HEALTH_OFFSET = 0x48
CGUNITDATA_MAXHEALTH_OFFSET = 0x68

AURAS_OFFSET = 0xC50
AURA_ENTRY_SIZE = 0x18
AURA_SPELLID_OFFSET = 0x08
AURA_COUNT_OFFSET = 0x180
AURA_AC_ALLOC_OFFSET = 0x00
AURA_AC_COUNT_OFFSET = 0x04
AURA_AC_DATA_OFFSET = 0x08

NAME_CACHE = 0x00C5D938
NAME_CACHE_HT_OFFSET = 0x08
NAME_CACHE_LIST_OFFSET = 0x04
NAME_CACHE_GUID_LOW_OFFSET = 0x18
NAME_CACHE_GUID_HIGH_OFFSET = 0x1C
NAME_CACHE_NAME_OFFSET = 0x20
NAME_CACHE_NAME_MAXLEN = 48

PLAYER_TYPE_ID = 4


class GuardError(Exception):
    pass


class MemoryError_(Exception):
    pass


class _IOVec(ctypes.Structure):
    _fields_ = [("iov_base", ctypes.c_void_p), ("iov_len", ctypes.c_size_t)]


def read_bytes(pid: int, addr: int, size: int) -> bytes:
    if addr <= 0 or size <= 0:
        raise MemoryError_(f"bad read request: addr={addr:#x} size={size}")
    buf = ctypes.create_string_buffer(size)
    local = _IOVec(ctypes.cast(buf, ctypes.c_void_p), size)
    remote = _IOVec(ctypes.c_void_p(addr), size)
    n = LIBC.process_vm_readv(pid, ctypes.byref(local), 1, ctypes.byref(remote), 1, 0)
    if n < 0:
        err = ctypes.get_errno()
        raise MemoryError_(f"process_vm_readv({pid}, {addr:#x}, {size}) failed: {os.strerror(err)}")
    if n != size:
        raise MemoryError_(f"process_vm_readv({pid}, {addr:#x}, {size}) short read: {n} bytes")
    return buf.raw


def read_u32(pid: int, addr: int) -> int:
    return struct.unpack("<I", read_bytes(pid, addr, 4))[0]


def read_i32(pid: int, addr: int) -> int:
    return struct.unpack("<i", read_bytes(pid, addr, 4))[0]


def read_u64(pid: int, addr: int) -> int:
    return struct.unpack("<Q", read_bytes(pid, addr, 8))[0]


def read_cstring(pid: int, addr: int, maxlen: int) -> str:
    if addr == 0:
        return ""
    data = read_bytes(pid, addr, maxlen)
    end = data.find(b"\x00")
    return data[: end if end >= 0 else maxlen].decode("latin1", "replace")


def check_warden_disabled(descriptor: dict) -> None:
    conf_path = descriptor.get("worldserver_conf")
    try:
        text = Path(conf_path).read_text()
    except (OSError, TypeError) as error:
        raise GuardError(f"cannot read worldserver_conf {conf_path}: {error}") from None
    match = re.search(r"^\s*Warden\.Enabled\s*=\s*(\S+)", text, re.MULTILINE)
    if not match or match.group(1).strip('"') != "0":
        raise GuardError(f"{conf_path} does not have Warden.Enabled = 0; refusing to read this slot's client")


def _maps_ascension_under(pid: int, client_dir: str, proc_root: Path) -> bool:
    try:
        maps_text = (proc_root / str(pid) / "maps").read_text()
    except OSError:
        return False
    client_dir_real = str(Path(client_dir).resolve())
    for line in maps_text.splitlines():
        parts = line.split(maxsplit=5)
        if len(parts) != 6 or not parts[5].endswith("Ascension.exe"):
            continue
        exe_real = str(Path(parts[5]).resolve())
        if exe_real == client_dir_real or exe_real.startswith(client_dir_real + os.sep):
            return True
    return False


def find_lab_client_pid(descriptor: dict, proc_root: Path = Path("/proc")) -> int:
    check_warden_disabled(descriptor)
    client_dir = descriptor.get("client_dir")
    if not client_dir:
        raise GuardError("lab descriptor has no client_dir; refusing to look for the lab client")
    matches = []
    for entry in proc_root.iterdir():
        if not entry.name.isdigit():
            continue
        if _maps_ascension_under(int(entry.name), client_dir, proc_root):
            matches.append(int(entry.name))
    if not matches:
        raise GuardError(f"no process maps Ascension.exe under {client_dir}")
    if len(matches) > 1:
        raise GuardError(f"more than one process maps Ascension.exe under {client_dir}: {matches}")
    return matches[0]


def parse_tls_directory(pid: int, image_base: int = IMAGE_BASE) -> dict:
    dos = read_bytes(pid, image_base, 64)
    e_lfanew = struct.unpack_from("<I", dos, 0x3C)[0]
    nt = read_bytes(pid, image_base + e_lfanew, 24)
    if nt[:4] != b"PE\x00\x00":
        raise MemoryError_("no PE signature at the expected NT header offset")
    _, _, _, _, _, opt_size, _ = struct.unpack_from("<HHIIIHH", nt, 4)
    opt = read_bytes(pid, image_base + e_lfanew + 24, opt_size)
    tls_rva, _tls_size = struct.unpack_from("<II", opt, 96 + 9 * 8)
    if tls_rva == 0:
        raise MemoryError_("no TLS directory in this image")
    tls_dir = read_bytes(pid, image_base + tls_rva, 24)
    start_rva, end_rva, index_addr, _callbacks_addr, _, _ = struct.unpack("<IIIIII", tls_dir)
    index = read_u32(pid, index_addr)
    if not (start_rva <= TLS_S_CURMGR_RVA < end_rva):
        raise MemoryError_(f"s_curMgr RVA {TLS_S_CURMGR_RVA:#x} is outside the TLS block "
                            f"[{start_rva:#x}, {end_rva:#x})")
    return {"tls_index": index, "s_curmgr_delta": TLS_S_CURMGR_RVA - start_rva}


def _rw_anon_regions(pid: int):
    regions = []
    with open(f"/proc/{pid}/maps") as handle:
        for line in handle:
            parts = line.split(maxsplit=5)
            addr_range, perms = parts[0], parts[1]
            name = parts[5] if len(parts) == 6 else ""
            if not perms.startswith("rw") or name:
                continue
            start_s, end_s = addr_range.split("-")
            regions.append((int(start_s, 16), int(end_s, 16)))
    return regions


def find_teb64_candidates(pid: int, regions=None) -> list:
    found = []
    for start, end in (regions if regions is not None else _rw_anon_regions(pid)):
        addr = start
        while addr < end:
            try:
                data = read_bytes(pid, addr, 0x38)
            except MemoryError_:
                addr += PAGE_SIZE
                continue
            if struct.unpack_from("<Q", data, 0x30)[0] == addr:
                found.append(addr)
            addr += PAGE_SIZE
    return found


def resolve_object_manager(pid: int, tls: dict) -> int:
    tls_index, delta = tls["tls_index"], tls["s_curmgr_delta"]
    for teb64 in find_teb64_candidates(pid):
        teb32 = teb64 + 0x2000
        try:
            teb32_data = read_bytes(pid, teb32, 0x30)
        except MemoryError_:
            continue
        if struct.unpack_from("<I", teb32_data, 0x18)[0] != (teb32 & 0xFFFFFFFF):
            continue
        tls_array = struct.unpack_from("<I", teb32_data, 0x2C)[0]
        if tls_array == 0:
            continue
        try:
            tls_slot = read_u32(pid, tls_array + tls_index * 4)
        except MemoryError_:
            continue
        if tls_slot == 0:
            continue
        try:
            mgr = read_u32(pid, tls_slot + delta)
        except MemoryError_:
            continue
        if mgr != 0:
            return mgr
    raise MemoryError_("could not resolve the object manager: no thread's TLS slot held a non-null s_curMgr")


def walk_objects(pid: int, mgr: int, limit: int = 4096) -> list:
    list_base = mgr + OBJ_FULLLIST_OFFSET
    link_offset = read_u32(pid, list_base)
    terminator_addr = list_base + 4
    raw_first = read_u32(pid, terminator_addr + 4)
    current = raw_first & ~1
    nodes, seen = [], set()
    while current != terminator_addr and current != 0 and current not in seen and len(nodes) < limit:
        seen.add(current)
        nodes.append(current)
        try:
            raw_next = read_u32(pid, current + link_offset + 4)
        except MemoryError_:
            break
        current = raw_next & ~1
    return nodes


def read_cgobject(pid: int, node: int) -> dict:
    m_obj = read_u32(pid, node + CGOBJECT_MOBJ_OFFSET)
    type_id = read_u32(pid, node + CGOBJECT_TYPEID_OFFSET)
    guid = read_u64(pid, m_obj + CGOBJECTDATA_GUID_OFFSET)
    return {"node": node, "guid": guid, "type_id": type_id}


def find_node_by_guid(pid: int, mgr: int, guid: int) -> int:
    for node in walk_objects(pid, mgr):
        try:
            obj = read_cgobject(pid, node)
        except MemoryError_:
            continue
        if obj["guid"] == guid:
            return node
    raise MemoryError_(f"no object with guid {guid:#x} in the object manager")


def read_unit_health(pid: int, node: int) -> dict:
    cgd = read_u32(pid, node + CGUNIT_MUNIT_OFFSET)
    return {"health": read_u32(pid, cgd + CGUNITDATA_HEALTH_OFFSET),
            "max_health": read_u32(pid, cgd + CGUNITDATA_MAXHEALTH_OFFSET)}


def read_auras(pid: int, node: int) -> list:
    base = node + AURAS_OFFSET
    outer_count = read_u32(pid, base + AURA_COUNT_OFFSET)
    if 0 <= outer_count <= 16:
        count, entry_base = outer_count, base
    else:
        alloc = read_u32(pid, base + AURA_AC_ALLOC_OFFSET)
        inner_count = read_u32(pid, base + AURA_AC_COUNT_OFFSET)
        data_ptr = read_u32(pid, base + AURA_AC_DATA_OFFSET)
        count, entry_base = min(inner_count, alloc), data_ptr
    entries = []
    for index in range(count):
        entry = entry_base + index * AURA_ENTRY_SIZE
        spell_id = read_i32(pid, entry + AURA_SPELLID_OFFSET)
        if spell_id != 0:
            entries.append({"spell_id": spell_id})
    return entries


def read_player_name(pid: int, guid: int) -> str:
    list_base = NAME_CACHE + NAME_CACHE_HT_OFFSET + NAME_CACHE_LIST_OFFSET
    link_offset = read_u32(pid, list_base)
    terminator_addr = list_base + 4
    raw_current = read_u32(pid, terminator_addr + 4)
    current = raw_current & ~1
    seen = set()
    while current != terminator_addr and current != 0 and current not in seen:
        seen.add(current)
        low = read_u32(pid, current + NAME_CACHE_GUID_LOW_OFFSET)
        high = read_u32(pid, current + NAME_CACHE_GUID_HIGH_OFFSET)
        if (low | (high << 32)) == guid:
            return read_cstring(pid, current + NAME_CACHE_NAME_OFFSET, NAME_CACHE_NAME_MAXLEN)
        try:
            raw_next = read_u32(pid, current + link_offset + 4)
        except MemoryError_:
            break
        current = raw_next & ~1
    return ""


def read_active_player(pid: int) -> dict:
    tls = parse_tls_directory(pid)
    mgr = resolve_object_manager(pid, tls)
    guid = read_u64(pid, mgr + OBJ_PLAYER_GUID_OFFSET)
    node = find_node_by_guid(pid, mgr, guid)
    obj = read_cgobject(pid, node)
    if obj["type_id"] != PLAYER_TYPE_ID:
        raise MemoryError_(f"active player object at guid {guid:#x} has type_id {obj['type_id']}, not player")
    health = read_unit_health(pid, node)
    return {"guid": guid, "name": read_player_name(pid, guid), "health": health["health"],
            "max_health": health["max_health"], "auras": read_auras(pid, node)}
