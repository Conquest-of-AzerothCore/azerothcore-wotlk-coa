from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = r'''
#include "XPHotspotPainting.h"
#include <iostream>
#include <sstream>
#include <cassert>
using namespace XPHotspots;
int main(){
 Location r;r.Kind="polygon";r.Name="test";r.Map=1;r.Zone=14;
 Point prev{0,0};unsigned accepted=0;
 for(unsigned i=0;i<192;++i){Point to{double(i)*25,120*std::sin(i*0.2)};if(!Paint(r,prev,to,75,false))break;prev=to;++accepted;}
 assert(accepted == 192 && r.Points.size() <= 256);

 auto saved=r.Points;std::string reason;
 assert(!Paint(r,{12000,12000},{12000,12000},75,false,&reason));assert(!reason.empty());
 assert(r.Points.size()==saved.size());for(size_t i=0;i<saved.size();++i)assert(saved[i].X==r.Points[i].X && saved[i].Y==r.Points[i].Y);
 Location tooLong;tooLong.Kind="polygon";tooLong.Name="limit";std::string edits;
 for(unsigned i=0;i<193;++i)edits+="B 0 0 0 0 75 0;";
 assert(!ApplyLocalPaint(tooLong,edits,&reason));assert(tooLong.Points.empty());
 assert(!Paint(tooLong,{0,0},{19001,0},75,false,&reason));assert(tooLong.Points.empty());


 std::ostringstream trace;trace<<"T;";for(unsigned i=0;i<180;++i){double a=i*6.283185307179586/180;trace<<"P "<<500*std::cos(a)<<" "<<500*std::sin(a)<<";";}
 Location t;t.Kind="polygon";t.Name="trace";assert(ApplyLocalPaint(t,trace.str()));
}
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder)
    (path / 'test.cpp').write_text(source)
    subprocess.run(['g++', '-std=c++20', '-O2', '-I', str(root / 'src/server/coa'),
                    str(path / 'test.cpp'), '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True)
