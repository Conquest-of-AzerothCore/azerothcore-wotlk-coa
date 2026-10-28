"""Build the verified CoA Manastorm client MPQ overlay.

The overlay contains the four corrected Interface files: the active-run I-key
fix, reward divider XML, queue safety/quality fixes and empty-spell flyout guard.

Uses the Unicode Windows StormLib API. Never modifies the input archive.
"""
import argparse
import ctypes as c
import hashlib
from pathlib import Path
import tempfile

UI_MEMBER = b"Interface\\FrameXML\\UIParent.lua"
QUEUE_MEMBER = b"Interface\\AddOns\\Ascension_Manastorm\\ManastormQueue.xml"
QUEUE_LUA_MEMBER = b"Interface\\AddOns\\Ascension_Manastorm\\ManastormQueue.lua"
FLYOUT_MEMBER = b"Interface\\AddOns\\Ascension_Manastorm\\ManastormLoadoutFlyout.lua"

# Compatibility aliases used by older regression tooling.
MEMBER = UI_MEMBER

EXPECTED_UI_PARENT = "495ecb3bad858a5af82226eff0f27e2a6276d5f936b3b5ca3c655ea16f51776c"
EXPECTED = EXPECTED_UI_PARENT

OLD = b"\telseif C_Manastorm.CanEnter(1) then"
NEW = b"\telseif C_Manastorm.IsInManastorm() or C_Manastorm.CanEnter(1) then"

QUEUE_SOURCE = (
    Path(__file__).resolve().parent
    / "overlay"
    / "Interface"
    / "AddOns"
    / "Ascension_Manastorm"
    / "ManastormQueue.xml"
)


def patch(data):
    if hashlib.sha256(data).hexdigest() != EXPECTED_UI_PARENT:
        raise ValueError(
            "Unrecognized UIParent.lua; inspect the current client before patching"
        )
    if data.count(OLD) != 1:
        raise ValueError("Expected exactly one keybinding guard")
    return data.replace(OLD, NEW, 1)


def load_queue_patch():
    data = QUEUE_SOURCE.read_bytes()
    expected = (
        b'<Texture name="$parentRewardDiv" parentKey="RewardDiv" '
        b'file="Interface\\Common\\ui-tooltipdivider-transparent">'
    )
    broken = (
        b'<Texture name="$parentRewardDiv" '
        b'file="Interface\\Common\\ui-tooltipdivider-transparent">'
    )
    if data.count(expected) != 1 or broken in data:
        raise ValueError(
            "ManastormQueue.xml does not contain the verified RewardDiv parentKey fix"
        )
    return data


def overlay_members(ui_parent):
    addon = QUEUE_SOURCE.parent
    return [
        (UI_MEMBER, ui_parent),
        (QUEUE_MEMBER, load_queue_patch()),
        (QUEUE_LUA_MEMBER, (addon / "ManastormQueue.lua").read_bytes()),
        (FLYOUT_MEMBER, (addon / "ManastormLoadoutFlyout.lua").read_bytes()),
    ]


class ArchiveAPI:
    def __init__(self, dll):
        self.lib = c.WinDLL(str(dll))
        h, d = c.c_void_p, c.c_uint32
        signatures = [
            ("SFileOpenArchive", [c.c_wchar_p, d, d, c.POINTER(h)], c.c_bool),
            ("SFileCreateArchive", [c.c_wchar_p, d, d, c.POINTER(h)], c.c_bool),
            ("SFileOpenFileEx", [h, c.c_char_p, d, c.POINTER(h)], c.c_bool),
            ("SFileGetFileSize", [h, c.POINTER(d)], d),
            ("SFileReadFile", [h, c.c_void_p, d, c.POINTER(d), h], c.c_bool),
            ("SFileCloseFile", [h], c.c_bool),
            ("SFileCloseArchive", [h], c.c_bool),
            ("SFileAddFileEx", [h, c.c_wchar_p, c.c_char_p, d, d, d], c.c_bool),
        ]
        for name, args, result in signatures:
            fn = getattr(self.lib, name)
            fn.argtypes = args
            fn.restype = result

    def read(self, archive, member=UI_MEMBER):
        handle = c.c_void_p()
        if not self.lib.SFileOpenArchive(str(archive), 0, 0x100, c.byref(handle)):
            raise OSError("Cannot open archive: " + str(archive))
        try:
            file = c.c_void_p()
            if not self.lib.SFileOpenFileEx(handle, member, 0, c.byref(file)):
                raise OSError(
                    "MPQ member missing: " + member.decode("ascii", "replace")
                )
            try:
                size = self.lib.SFileGetFileSize(file, None)
                if size > 2_000_000:
                    raise ValueError("Unexpected MPQ member size")
                buf = c.create_string_buffer(size)
                read = c.c_uint32()
                if (
                    not self.lib.SFileReadFile(
                        file, buf, size, c.byref(read), None
                    )
                    or read.value != size
                ):
                    raise OSError("Incomplete MPQ member read")
                return buf.raw
            finally:
                self.lib.SFileCloseFile(file)
        finally:
            self.lib.SFileCloseArchive(handle)

    def create(self, output, members):
        if output.exists():
            raise FileExistsError(output)

        handle = c.c_void_p()
        with tempfile.TemporaryDirectory(prefix="coa-manastorm-patch-") as tmp:
            tmp = Path(tmp)
            loose = []
            for index, (member, data) in enumerate(members):
                path = tmp / f"member-{index}.bin"
                path.write_bytes(data)
                loose.append((path, member, data))

            if not self.lib.SFileCreateArchive(str(output), 0, 16, c.byref(handle)):
                raise OSError("Cannot create overlay")

            try:
                for path, member, _ in loose:
                    if not self.lib.SFileAddFileEx(
                        handle,
                        str(path),
                        member,
                        0x200,
                        2,
                        2,
                    ):
                        raise OSError(
                            "Cannot add MPQ member: "
                            + member.decode("ascii", "replace")
                        )
            finally:
                self.lib.SFileCloseArchive(handle)

        for _, member, expected in loose:
            if self.read(output, member) != expected:
                raise ValueError(
                    "Overlay readback differs for "
                    + member.decode("ascii", "replace")
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--stormlib", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    api = ArchiveAPI(args.stormlib)
    ui_parent = patch(api.read(args.archive, UI_MEMBER))
    api.create(args.output.resolve(), overlay_members(ui_parent))
    print("Verified four-file Manastorm client overlay:", args.output)
