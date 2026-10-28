from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = r'''
#include "XPHotspotRules.h"
#include <cassert>
#include <limits>
int main()
{
    using namespace XPHotspots;
    Location r;
    r.Name = "Test";
    r.Map = 0;
    r.Zone = 44;
    r.Enabled = true;
    assert(Valid(r));
    assert(Contains(r, 0, 44, {150,0}));
    assert(!Contains(r, 0, 44, {150.01,0}));
    assert(!Contains(r, 1, 44, {0,0}));
    r.Kind = "zone";
    assert(Contains(r, 0, 44, {10000,10000}));
    assert(!Contains(r, 0, 45, {0,0}));
    r.Kind = "polygon";
    r.Points = {{0,0},{10,0},{10,10},{0,10}};
    assert(Valid(r) && Contains(r,0,44,{5,5}) && Contains(r,0,44,{10,5}));
    assert(!Contains(r,0,44,{11,5}));
    r.Points = {{0,0},{10,10},{0,10},{10,0}};
    assert(!Valid(r));
    r.Points = {{0,0},{10,0},{5,0},{5,5}};
    assert(!Valid(r));
    r.Kind = "circle";
    assert(Eligible(r,0,10000));
    r.Continent = 1;
    assert(!Eligible(r,0,10000) && Eligible(r,1,10000));
    r.LastEnd = 9000;
    assert(!Eligible(r,1,10000));
    r.Queued = 9999;
    assert(Eligible(r,1,10000));
    r.Weight = 0;
    assert(Eligible(r,1,10000));
    r.Queued = 0;
    assert(!Eligible(r,1,10000));
    r.Queued = 9999;
    r.Ends = 10001;
    assert(!Eligible(r,1,10000));
    r.Ends = 0;
    r.Enabled = false;
    assert(!Eligible(r,1,10000));
    r.Radius = std::numeric_limits<double>::quiet_NaN();
    assert(!Valid(r));
    Location a, b;
    a.Id = 1;
    a.Weight = 1;
    b.Id = 2;
    b.Weight = 3;
    std::vector<Location> candidates{a,b};
    assert(Select(candidates,1)->Id == 1);
    assert(Select(candidates,2)->Id == 2);
    assert(Select(candidates,4)->Id == 2);
    assert(!Select(candidates,0) && !Select(candidates,5));
    candidates[0].Queued = 10;
    candidates[1].Queued = 11;
    assert(Select(candidates,1)->Id == 2);
    candidates[0].Queued = 12;
    assert(Select(candidates,4)->Id == 1);
}
'''
with tempfile.TemporaryDirectory() as directory:
    out = Path(directory)
    (out/'test.cpp').write_text(source)
    subprocess.run(['c++','-std=c++20','-I'+str(root/'src/server/coa'),str(out/'test.cpp'),
                    '-o',str(out/'test')],check=True)
    subprocess.run([str(out/'test')],check=True)
print('Hotspot geometry, realm restrictions and eligibility passed')
