import importlib.machinery
import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "lab_memory.py"
loader = importlib.machinery.SourceFileLoader("coa_lab_memory", str(SCRIPT))
spec = importlib.util.spec_from_loader("coa_lab_memory", loader)
mem = importlib.util.module_from_spec(spec)
loader.exec_module(mem)


class FakeMemory:
    def __init__(self):
        self.chunks = []

    def write(self, addr: int, data: bytes):
        self.chunks.append((addr, data))

    def write_u32(self, addr: int, value: int):
        self.write(addr, struct.pack("<I", value & 0xFFFFFFFF))

    def write_i32(self, addr: int, value: int):
        self.write(addr, struct.pack("<i", value))

    def write_u64(self, addr: int, value: int):
        self.write(addr, struct.pack("<Q", value & 0xFFFFFFFFFFFFFFFF))

    def read(self, pid, addr, size):
        for start, data in self.chunks:
            if start <= addr and addr + size <= start + len(data):
                return data[addr - start: addr - start + size]
        raise mem.MemoryError_(f"unmapped read at {addr:#x} size {size}")


def patch_memory(test_case, fake: FakeMemory):
    original = mem.read_bytes
    mem.read_bytes = fake.read
    test_case.addCleanup(lambda: setattr(mem, "read_bytes", original))


class ReadPrimitivesTest(unittest.TestCase):
    def test_read_cstring_stops_at_nul(self):
        fake = FakeMemory()
        fake.write(0x1000, (b"Coalabone\x00garbage").ljust(32, b"\x00"))
        patch_memory(self, fake)
        self.assertEqual(mem.read_cstring(None, 0x1000, 32), "Coalabone")

    def test_read_cstring_of_null_pointer_is_empty(self):
        self.assertEqual(mem.read_cstring(None, 0, 32), "")

    def test_unmapped_read_raises(self):
        fake = FakeMemory()
        patch_memory(self, fake)
        with self.assertRaises(mem.MemoryError_):
            mem.read_u32(None, 0x5000)


def build_fake_pe(fake: FakeMemory, image_base: int, tls_rva: int, start_rva: int, end_rva: int,
                   index_addr_rva: int, tls_index: int):
    e_lfanew = 0x80
    fake.write(image_base, b"MZ" + b"\x00" * 0x3A + struct.pack("<I", e_lfanew))
    coff = struct.pack("<HHIIIHH", 0x14C, 0, 0, 0, 0, 224, 0)
    fake.write(image_base + e_lfanew, b"PE\x00\x00" + coff)
    opt = bytearray(224)
    struct.pack_into("<II", opt, 96 + 9 * 8, tls_rva, 24)
    fake.write(image_base + e_lfanew + 24, bytes(opt))
    fake.write(image_base + tls_rva, struct.pack("<IIIIII", start_rva, end_rva, index_addr_rva, 0, 0, 0))
    fake.write(index_addr_rva, struct.pack("<I", tls_index))


class TlsDirectoryTest(unittest.TestCase):
    def test_resolves_index_and_delta(self):
        fake = FakeMemory()
        build_fake_pe(fake, mem.IMAGE_BASE, tls_rva=0x6AEF70, start_rva=0xDD2000, end_rva=0xDD2018,
                      index_addr_rva=0xD439BC, tls_index=0)
        patch_memory(self, fake)
        result = mem.parse_tls_directory(None)
        self.assertEqual(result["tls_index"], 0)
        self.assertEqual(result["s_curmgr_delta"], mem.TLS_S_CURMGR_RVA - 0xDD2000)

    def test_curmgr_outside_tls_block_raises(self):
        fake = FakeMemory()
        build_fake_pe(fake, mem.IMAGE_BASE, tls_rva=0x6AEF70, start_rva=0x100, end_rva=0x110,
                      index_addr_rva=0xD439BC, tls_index=0)
        patch_memory(self, fake)
        with self.assertRaises(mem.MemoryError_):
            mem.parse_tls_directory(None)


class TebDiscoveryTest(unittest.TestCase):
    def test_finds_self_pointing_teb64(self):
        fake = FakeMemory()
        teb_addr = 0x200000
        data = bytearray(0x38)
        struct.pack_into("<Q", data, 0x30, teb_addr)
        fake.write(teb_addr, bytes(data))
        fake.write(teb_addr + mem.PAGE_SIZE, b"\x00" * 0x38)
        patch_memory(self, fake)
        found = mem.find_teb64_candidates(None, regions=[(teb_addr, teb_addr + 2 * mem.PAGE_SIZE)])
        self.assertEqual(found, [teb_addr])


def build_object_manager(fake: FakeMemory, mgr: int, player_guid: int, nodes: list):
    link_offset = nodes[0][1] if nodes else 0x24
    list_base = mgr + mem.OBJ_FULLLIST_OFFSET
    terminator_addr = list_base + 4
    fake.write_u32(list_base, link_offset)
    fake.write_u64(mgr + mem.OBJ_PLAYER_GUID_OFFSET, player_guid)
    chain = [n[0] for n in nodes] + [terminator_addr]
    fake.write_u32(terminator_addr + 4, chain[0] if nodes else terminator_addr)
    for i, (node_addr, _link, obj_addr, guid, type_id) in enumerate(nodes):
        fake.write_u32(node_addr + mem.CGOBJECT_MOBJ_OFFSET, obj_addr)
        fake.write_u32(node_addr + mem.CGOBJECT_TYPEID_OFFSET, type_id)
        fake.write_u64(obj_addr + mem.CGOBJECTDATA_GUID_OFFSET, guid)
        fake.write_u32(node_addr + link_offset + 4, chain[i + 1])


class ObjectManagerTest(unittest.TestCase):
    def test_walk_objects_flat_list(self):
        fake = FakeMemory()
        mgr = 0x3000000
        nodes = [(0x4000000, 0x24, 0x4000100, 1, 4), (0x4001000, 0x24, 0x4001100, 42, 3)]
        build_object_manager(fake, mgr, player_guid=1, nodes=nodes)
        patch_memory(self, fake)
        self.assertEqual(mem.walk_objects(None, mgr), [0x4000000, 0x4001000])

    def test_find_node_by_guid(self):
        fake = FakeMemory()
        mgr = 0x3000000
        nodes = [(0x4000000, 0x24, 0x4000100, 1, 4), (0x4001000, 0x24, 0x4001100, 42, 3)]
        build_object_manager(fake, mgr, player_guid=1, nodes=nodes)
        patch_memory(self, fake)
        self.assertEqual(mem.find_node_by_guid(None, mgr, 42), 0x4001000)
        with self.assertRaises(mem.MemoryError_):
            mem.find_node_by_guid(None, mgr, 999)

    def test_single_node_list_terminates_through_the_tag_bit(self):
        fake = FakeMemory()
        mgr = 0x3000000
        list_base = mgr + mem.OBJ_FULLLIST_OFFSET
        terminator_addr = list_base + 4
        link_offset = 0x24
        node = 0x4000000
        fake.write_u32(list_base, link_offset)
        fake.write_u32(terminator_addr + 4, node)
        fake.write_u32(node + link_offset + 4, terminator_addr | 1)
        fake.write_u32(node + mem.CGOBJECT_MOBJ_OFFSET, 0x4000100)
        fake.write_u32(node + mem.CGOBJECT_TYPEID_OFFSET, 4)
        fake.write_u64(0x4000100 + mem.CGOBJECTDATA_GUID_OFFSET, 1)
        patch_memory(self, fake)
        self.assertEqual(mem.walk_objects(None, mgr), [node])


class UnitHealthTest(unittest.TestCase):
    def test_reads_health_and_max_health(self):
        fake = FakeMemory()
        node, cgd = 0x5000000, 0x5000200
        fake.write_u32(node + mem.CGUNIT_MUNIT_OFFSET, cgd)
        fake.write_u32(cgd + mem.CGUNITDATA_HEALTH_OFFSET, 144)
        fake.write_u32(cgd + mem.CGUNITDATA_MAXHEALTH_OFFSET, 200)
        patch_memory(self, fake)
        result = mem.read_unit_health(None, node)
        self.assertEqual(result["health"], 144)
        self.assertEqual(result["max_health"], 200)


class AurasTest(unittest.TestCase):
    def write_aura(self, fake, entry_addr, spell_id):
        fake.write_i32(entry_addr + mem.AURA_SPELLID_OFFSET, spell_id)

    def test_no_auras(self):
        fake = FakeMemory()
        node = 0x6000000
        fake.write_u32(node + mem.AURAS_OFFSET + mem.AURA_COUNT_OFFSET, 0)
        patch_memory(self, fake)
        self.assertEqual(mem.read_auras(None, node), [])

    def test_inline_auras_active_only(self):
        fake = FakeMemory()
        node = 0x6000000
        base = node + mem.AURAS_OFFSET
        self.write_aura(fake, base + 0 * mem.AURA_ENTRY_SIZE, 589)
        self.write_aura(fake, base + 1 * mem.AURA_ENTRY_SIZE, 0)
        self.write_aura(fake, base + 2 * mem.AURA_ENTRY_SIZE, 1130)
        fake.write_u32(base + mem.AURA_COUNT_OFFSET, 3)
        patch_memory(self, fake)
        self.assertEqual([e["spell_id"] for e in mem.read_auras(None, node)], [589, 1130])

    def test_dynamic_auras_over_sixteen(self):
        fake = FakeMemory()
        node = 0x6000000
        base = node + mem.AURAS_OFFSET
        heap = 0x7000000
        spell_ids = list(range(100, 119))
        for i, spell_id in enumerate(spell_ids):
            self.write_aura(fake, heap + i * mem.AURA_ENTRY_SIZE, spell_id)
        fake.write_u32(base + mem.AURA_COUNT_OFFSET, 0xFFFFFFFF)
        fake.write_u32(base + mem.AURA_AC_ALLOC_OFFSET, 20)
        fake.write_u32(base + mem.AURA_AC_COUNT_OFFSET, 19)
        fake.write_u32(base + mem.AURA_AC_DATA_OFFSET, heap)
        patch_memory(self, fake)
        self.assertEqual([e["spell_id"] for e in mem.read_auras(None, node)], spell_ids)


class NameCacheTest(unittest.TestCase):
    def test_player_name_via_name_cache_single_entry(self):
        fake = FakeMemory()
        list_base = mem.NAME_CACHE + mem.NAME_CACHE_HT_OFFSET + mem.NAME_CACHE_LIST_OFFSET
        terminator_addr = list_base + 4
        link_offset = 0xC
        entry = 0x9000000
        fake.write_u32(list_base, link_offset)
        fake.write_u32(terminator_addr + 4, entry)
        fake.write_u32(entry + link_offset + 4, terminator_addr | 1)
        fake.write_u32(entry + mem.NAME_CACHE_GUID_LOW_OFFSET, 1)
        fake.write_u32(entry + mem.NAME_CACHE_GUID_HIGH_OFFSET, 0)
        fake.write(entry + mem.NAME_CACHE_NAME_OFFSET, b"Coalabone\x00".ljust(mem.NAME_CACHE_NAME_MAXLEN, b"\x00"))
        patch_memory(self, fake)
        self.assertEqual(mem.read_player_name(None, 1), "Coalabone")
        self.assertEqual(mem.read_player_name(None, 2), "")


class ReadActivePlayerTest(unittest.TestCase):
    def test_reads_name_health_and_active_auras(self):
        fake = FakeMemory()
        mgr = 0x3000000
        node, obj, cgd = 0x4000000, 0x4000100, 0x4000200
        teb64 = 0x200000
        teb32 = teb64 + 0x2000
        tls_array, tls_slot = 0x300000, 0x301000
        build_fake_pe(fake, mem.IMAGE_BASE, tls_rva=0x6AEF70, start_rva=0xDD2000, end_rva=0xDD2018,
                      index_addr_rva=0xD439BC, tls_index=0)
        teb64_data = bytearray(0x38)
        struct.pack_into("<Q", teb64_data, 0x30, teb64)
        fake.write(teb64, bytes(teb64_data))
        teb32_data = bytearray(0x30)
        struct.pack_into("<I", teb32_data, 0x18, teb32 & 0xFFFFFFFF)
        struct.pack_into("<I", teb32_data, 0x2C, tls_array)
        fake.write(teb32, bytes(teb32_data))
        fake.write_u32(tls_array, tls_slot)
        fake.write_u32(tls_slot + (mem.TLS_S_CURMGR_RVA - 0xDD2000), mgr)
        build_object_manager(fake, mgr, player_guid=1, nodes=[(node, 0x24, obj, 1, mem.PLAYER_TYPE_ID)])
        fake.write_u32(node + mem.CGUNIT_MUNIT_OFFSET, cgd)
        fake.write_u32(cgd + mem.CGUNITDATA_HEALTH_OFFSET, 144)
        fake.write_u32(cgd + mem.CGUNITDATA_MAXHEALTH_OFFSET, 144)
        self.write_aura(fake, node + mem.AURAS_OFFSET + 0 * mem.AURA_ENTRY_SIZE, 589)
        fake.write_u32(node + mem.AURAS_OFFSET + mem.AURA_COUNT_OFFSET, 1)
        list_base = mem.NAME_CACHE + mem.NAME_CACHE_HT_OFFSET + mem.NAME_CACHE_LIST_OFFSET
        terminator_addr = list_base + 4
        link_offset = 0xC
        entry = 0x9000000
        fake.write_u32(list_base, link_offset)
        fake.write_u32(terminator_addr + 4, entry)
        fake.write_u32(entry + link_offset + 4, terminator_addr | 1)
        fake.write_u32(entry + mem.NAME_CACHE_GUID_LOW_OFFSET, 1)
        fake.write_u32(entry + mem.NAME_CACHE_GUID_HIGH_OFFSET, 0)
        fake.write(entry + mem.NAME_CACHE_NAME_OFFSET, b"Coalabone\x00".ljust(mem.NAME_CACHE_NAME_MAXLEN, b"\x00"))
        patch_memory(self, fake)
        original_candidates = mem.find_teb64_candidates
        mem.find_teb64_candidates = lambda pid: [teb64]
        self.addCleanup(lambda: setattr(mem, "find_teb64_candidates", original_candidates))
        result = mem.read_active_player(None)
        self.assertEqual(result["name"], "Coalabone")
        self.assertEqual(result["health"], 144)
        self.assertEqual(result["max_health"], 144)
        self.assertEqual([a["spell_id"] for a in result["auras"]], [589])

    def write_aura(self, fake, entry_addr, spell_id):
        fake.write_i32(entry_addr + mem.AURA_SPELLID_OFFSET, spell_id)


class GuardsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def descriptor(self, **overrides):
        base = {"slot": 2, "client_dir": str(self.root / "client-lab/ascension-lab"),
                "worldserver_conf": str(self.root / "worldserver.conf")}
        base.update(overrides)
        return base

    def test_warden_enabled_is_refused(self):
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 1\n")
        with self.assertRaises(mem.GuardError):
            mem.check_warden_disabled(self.descriptor(worldserver_conf=str(conf)))

    def test_warden_disabled_is_accepted(self):
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 0\n")
        mem.check_warden_disabled(self.descriptor(worldserver_conf=str(conf)))

    def test_missing_worldserver_conf_is_refused(self):
        with self.assertRaises(mem.GuardError):
            mem.check_warden_disabled(self.descriptor(worldserver_conf=str(self.root / "missing.conf")))

    def test_find_lab_client_pid_matches_exactly_one_process(self):
        client_dir = self.root / "client-lab/ascension-lab"
        client_dir.mkdir(parents=True)
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 0\n")
        proc_root = self.root / "proc"
        for pid, exe in ((100, client_dir / "Ascension.exe"), (200, self.root / "other/Ascension.exe")):
            (proc_root / str(pid)).mkdir(parents=True)
            (proc_root / str(pid) / "maps").write_text(
                f"00400000-00401000 r-xp 00000000 08:01 1 {exe}\n")
        descriptor = self.descriptor(client_dir=str(client_dir), worldserver_conf=str(conf))
        self.assertEqual(mem.find_lab_client_pid(descriptor, proc_root), 100)

    def test_find_lab_client_pid_rejects_no_match(self):
        client_dir = self.root / "client-lab/ascension-lab"
        client_dir.mkdir(parents=True)
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 0\n")
        proc_root = self.root / "proc"
        proc_root.mkdir()
        descriptor = self.descriptor(client_dir=str(client_dir), worldserver_conf=str(conf))
        with self.assertRaises(mem.GuardError):
            mem.find_lab_client_pid(descriptor, proc_root)

    def test_find_lab_client_pid_rejects_more_than_one_match(self):
        client_dir = self.root / "client-lab/ascension-lab"
        client_dir.mkdir(parents=True)
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 0\n")
        proc_root = self.root / "proc"
        for pid in (100, 101):
            (proc_root / str(pid)).mkdir(parents=True)
            (proc_root / str(pid) / "maps").write_text(
                f"00400000-00401000 r-xp 00000000 08:01 1 {client_dir / 'Ascension.exe'}\n")
        descriptor = self.descriptor(client_dir=str(client_dir), worldserver_conf=str(conf))
        with self.assertRaises(mem.GuardError):
            mem.find_lab_client_pid(descriptor, proc_root)

    def test_find_lab_client_pid_refuses_a_descriptor_without_client_dir(self):
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 0\n")
        descriptor = self.descriptor(client_dir=None, worldserver_conf=str(conf))
        with self.assertRaises(mem.GuardError):
            mem.find_lab_client_pid(descriptor, self.root / "proc-not-created")

    def test_find_lab_client_pid_checks_warden_before_scanning_proc(self):
        client_dir = self.root / "client-lab/ascension-lab"
        client_dir.mkdir(parents=True)
        conf = self.root / "worldserver.conf"
        conf.write_text("Warden.Enabled = 1\n")
        descriptor = self.descriptor(client_dir=str(client_dir), worldserver_conf=str(conf))
        with self.assertRaises(mem.GuardError):
            mem.find_lab_client_pid(descriptor, self.root / "proc-not-created")


if __name__ == "__main__":
    unittest.main()
