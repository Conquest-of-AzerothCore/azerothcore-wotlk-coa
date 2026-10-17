from pathlib import Path
import os
import re
import shutil
import socket
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[3]
REPACK = ROOT / "ManastormTestRepack"


class DualRealmTests(unittest.TestCase):
    def test_card_override_follows_realm_id_with_global_fallback(self):
        source = (ROOT / "src/server/apps/authserver/Server/AuthSession.cpp").read_text()
        start = source.index('    if (_expversion & POST_BC_EXP_FLAG && sConfigMgr->GetOption<bool>("RealmCards.Enable"')
        end = source.index('    if (_expversion & POST_BC_EXP_FLAG)', start + 1)
        block = source[start:end]
        fixture = r"""
#include <cassert>
#include <cstdint>
#include <map>
#include <string>
#include <vector>
using uint8=std::uint8_t;
using uint32=std::uint32_t;
constexpr uint32 POST_BC_EXP_FLAG=1, REALM_TYPE_NORMAL=0, REALM_FLAG_OFFLINE=2;
struct RealmCardStyle {uint32 Expansion,GameMode; std::string Image;};
struct Config {
    std::map<std::string,std::string> values;
    template<class T> T GetOption(std::string const& key,T fallback,bool=true) {
        auto found=values.find(key);
        if(found==values.end()) return fallback;
        if constexpr (std::is_same_v<T,std::string>) return found->second;
        else return static_cast<T>(std::stoul(found->second));
    }
} config;
auto sConfigMgr=&config;
std::vector<std::pair<std::string,uint32>> cards;
std::string BuildRealmCardName(std::string const& name,RealmCardStyle const& style,std::size_t) {
    cards.emplace_back(name,style.GameMode); return name;
}
std::size_t GetRealmCardSlot(std::size_t order) {return order;}
struct Packet {template<class T> Packet& operator<<(T const&) {return *this;}};
void render(std::vector<std::pair<uint32,std::string>> const& listedRealms) {
    uint32 _expversion=1,RealmListSize=0;
    Packet pkt;
""" + block + r"""
    assert(RealmListSize==listedRealms.size());
}
int main() {
    config.values["RealmCards.Realm.2.GameMode"]="6";
    render({{7,"Other CoA"},{2,"Wildcard"},{1,"CoA"}});
    assert(cards.size()==3);
    assert(cards[0].second==11 && cards[1].second==6 && cards[2].second==11);
    cards.clear(); config.values["RealmCards.GameMode"]="0";
    render({{2,"Wildcard"},{7,"Freepick"}});
    assert(cards[0].second==6 && cards[1].second==0);
    cards.clear(); config.values["RealmCards.Enable"]="0";
    render({}); assert(cards.empty());
}
"""
        with tempfile.TemporaryDirectory(prefix="manastorm-realms-") as directory:
            temporary=Path(directory)
            (temporary/"fixture.cpp").write_text(fixture,encoding="utf-8")
            if os.name=="nt":
                installs=Path(os.environ.get("ProgramFiles","C:/Program Files"))/"Microsoft Visual Studio"
                vcvars=next(installs.glob("2022/*/VC/Auxiliary/Build/vcvars64.bat"),None)
                self.assertIsNotNone(vcvars)
                command=f'cmd.exe /d /c call "{vcvars}" >nul && cl /nologo /std:c++20 /EHsc fixture.cpp /Fe:fixture.exe /Fo:fixture.obj'
                executable=temporary/"fixture.exe"
            else:
                compiler=shutil.which("c++")
                self.assertIsNotNone(compiler)
                command=[compiler,"-std=c++20","fixture.cpp","-o","fixture"]
                executable=temporary/"fixture"
            compiled=subprocess.run(command,cwd=temporary,capture_output=True,text=True)
            self.assertEqual(compiled.returncode,0,compiled.stdout+compiled.stderr)
            executed=subprocess.run([str(executable)],cwd=temporary,capture_output=True,text=True)
            self.assertEqual(executed.returncode,0,executed.stdout+executed.stderr)

    @unittest.skipUnless(os.environ.get("MANASTORM_REPACK_VERIFY")=="1","local repack validation opt-in")
    def test_both_realm_startups_with_shared_auth(self):
        mysql=Path(r"C:/Program Files/MySQL/MySQL Server 8.4/bin/mysql.exe")
        def query(sql):
            result=subprocess.run([str(mysql),"--defaults-file="+str(REPACK/"Database/client.ini"),
                                   "--batch","--raw","--skip-column-names","--execute="+sql],
                                  capture_output=True,text=True,check=True)
            return result.stdout.strip()
        self.assertEqual(query("SELECT @@port"),"13317")
        self.assertEqual(query("SELECT COUNT(*) FROM manastorm_wildcard_characters.characters"),"0")
        self.assertEqual(query("SELECT COUNT(*) FROM acore_auth.realmlist WHERE (id=1 AND port=18085) OR (id=2 AND port=18086)"),"2")
        coa=(REPACK/"configs/modules/coa.conf").read_text()
        wildcard=(REPACK/"Wildcard/configs/modules/coa.conf").read_text()
        for text,key,value in ((coa,"CoA.GameModeMask","0"),(wildcard,"CoA.GameModeMask","64"),
                               (wildcard,"CoA.ClassModel",'"hero"'),(wildcard,"CoA.MapClass10ToWarrior","0")):
            self.assertRegex(text,r"(?m)^"+re.escape(key)+r"\s*=\s*"+re.escape(value)+r"\s*$")
        logs=REPACK/"Logs/DualRealmVerification"
        logs.mkdir(exist_ok=True)
        processes=[]
        handles=[]
        def listening(port):
            with socket.socket() as connection:
                connection.settimeout(.2)
                return connection.connect_ex(("127.0.0.1",port))==0
        try:
            for name,cwd,port in (("authserver",REPACK,13724),("worldserver",REPACK,18085),
                                  ("worldserver",REPACK/"Wildcard",18086)):
                self.assertFalse(listening(port),f"Port {port} is already in use; preserving running server")
                output=(logs/f"{port}.log").open("wb")
                handles.append(output)
                process=subprocess.Popen([str(REPACK/"Server"/(name+".exe")),"-c",f"configs/{name}.conf"],
                                         cwd=cwd,stdin=subprocess.PIPE,stdout=output,stderr=subprocess.STDOUT)
                processes.append((process,name,port))
            deadline=time.monotonic()+180
            while time.monotonic()<deadline:
                for process,name,port in processes:
                    self.assertIsNone(process.poll(),f"{name} on {port} exited; inspect {logs}")
                if all(listening(port) for _,_,port in processes):
                    break
                time.sleep(1)
            else:
                self.fail(f"Both realms did not become ready; inspect {logs}")
            self.assertEqual(query("SELECT COUNT(*) FROM acore_auth.realmlist WHERE id IN (1,2) AND (flag & 2)=0"),"2")
            for name in ("acore_world","manastorm_wildcard_world"):
                self.assertEqual(query(f"SELECT COUNT(*) FROM {name}.manastorm_private_creature"),"14")
                self.assertEqual(query(f"SELECT COUNT(*) FROM {name}.manastorm_segment WHERE enabled=1"),"296")
            for process,name,_ in processes:
                if name=="worldserver":
                    process.stdin.write(b"server shutdown 1\n"); process.stdin.flush()
            for process,name,_ in processes:
                if name=="worldserver":
                    self.assertEqual(process.wait(timeout=45),0)
        finally:
            for process,name,_ in processes:
                if process.poll() is None:
                    if name=="worldserver":
                        process.stdin.write(b"server shutdown 1\n"); process.stdin.flush()
                        try: process.wait(timeout=30)
                        except subprocess.TimeoutExpired: process.terminate()
                    else: process.terminate()
                    process.wait(timeout=15)
                if process.stdin: process.stdin.close()
            for handle in handles: handle.close()


if __name__=="__main__":
    unittest.main()
