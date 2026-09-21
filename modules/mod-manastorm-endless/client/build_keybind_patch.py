"""Build a one-file MPQ overlay from the verified installed Ascension UIParent.
Uses the Unicode Windows StormLib API. Never modifies the input archive.
"""
import argparse
import ctypes as c
import hashlib
from pathlib import Path

MEMBER = b"Interface\\FrameXML\\UIParent.lua"
EXPECTED = "495ecb3bad858a5af82226eff0f27e2a6276d5f936b3b5ca3c655ea16f51776c"
OLD = b"\telseif C_Manastorm.CanEnter(1) then"
NEW = b"\telseif C_Manastorm.IsInManastorm() or C_Manastorm.CanEnter(1) then"

def patch(data):
    if hashlib.sha256(data).hexdigest() != EXPECTED:
        raise ValueError("Unrecognized UIParent.lua; inspect the current client before patching")
    if data.count(OLD) != 1:
        raise ValueError("Expected exactly one keybinding guard")
    return data.replace(OLD, NEW, 1)

class ArchiveAPI:
    def __init__(self, dll):
        self.lib = c.WinDLL(str(dll))
        h, d = c.c_void_p, c.c_uint32
        signatures = [
            ("SFileOpenArchive", [c.c_wchar_p,d,d,c.POINTER(h)],c.c_bool),
            ("SFileCreateArchive", [c.c_wchar_p,d,d,c.POINTER(h)],c.c_bool),
            ("SFileOpenFileEx", [h,c.c_char_p,d,c.POINTER(h)],c.c_bool),
            ("SFileGetFileSize", [h,c.POINTER(d)],d),
            ("SFileReadFile", [h,c.c_void_p,d,c.POINTER(d),h],c.c_bool),
            ("SFileCloseFile", [h],c.c_bool),
            ("SFileCloseArchive", [h],c.c_bool),
            ("SFileAddFileEx", [h,c.c_wchar_p,c.c_char_p,d,d,d],c.c_bool),
        ]
        for name,args,result in signatures:
            fn=getattr(self.lib,name);fn.argtypes=args;fn.restype=result

    def read(self, archive):
        handle=c.c_void_p()
        if not self.lib.SFileOpenArchive(str(archive),0,0x100,c.byref(handle)):
            raise OSError("Cannot open archive: " + str(archive))
        try:
            file=c.c_void_p()
            if not self.lib.SFileOpenFileEx(handle,MEMBER,0,c.byref(file)):
                raise OSError("UIParent.lua missing")
            try:
                size=self.lib.SFileGetFileSize(file,None)
                if size > 2_000_000:
                    raise ValueError("Unexpected UIParent size")
                buf=c.create_string_buffer(size);read=c.c_uint32()
                if not self.lib.SFileReadFile(file,buf,size,c.byref(read),None) or read.value != size:
                    raise OSError("Incomplete UIParent read")
                return buf.raw
            finally:
                self.lib.SFileCloseFile(file)
        finally:
            self.lib.SFileCloseArchive(handle)

    def create(self, output, data):
        if output.exists():
            raise FileExistsError(output)
        loose=output.with_suffix('.UIParent.lua')
        with loose.open('xb') as f:
            f.write(data)
        handle=c.c_void_p()
        try:
            if not self.lib.SFileCreateArchive(str(output),0,8,c.byref(handle)):
                raise OSError("Cannot create overlay")
            try:
                if not self.lib.SFileAddFileEx(handle,str(loose),MEMBER,0x200,2,2):
                    raise OSError("Cannot add UIParent")
            finally:
                self.lib.SFileCloseArchive(handle)
        finally:
            loose.unlink()
        if self.read(output) != data:
            raise ValueError("Overlay readback differs")

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--stormlib',type=Path,required=True)
    parser.add_argument('--archive',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    api=ArchiveAPI(args.stormlib)
    data=patch(api.read(args.archive))
    api.create(args.output.resolve(),data)
    print('Verified one-file UIParent overlay:',args.output)
