#include "AscensionMysticEnchantCatalog.h"
#include <cassert>
int main(){using namespace AscensionMysticEnchant;
 Catalog c; std::set<unsigned> owned; std::map<unsigned,unsigned> limits;
 for(unsigned i=1;i<=7;++i){Entry e;e.Spell=i;e.Quality=i==1?5:i<6?4:3;e.Level=1;c.BySpell[i]=e;owned.insert(i);limits[i]=3;}
 Slots s{};s[0]=6;s[4]=1;s[5]=2;s[6]=3;s[7]=4;
 assert(!ValidateSlots(c,s,80,owned,limits)); // failing positional baseline
 assert(ArrangeSlots(c,s));assert(ValidateSlots(c,s,80,owned,limits));auto stable=s;assert(ArrangeSlots(c,s)&&s==stable);
 s[8]=1;auto old=s;assert(!ArrangeSlots(c,s)&&s==old); // second legendary, no destructive rejection
 s=stable;s[8]=5;assert(!ArrangeSlots(c,s)); // fifth epic-or-legendary
 s={};s[0]=999;assert(!ArrangeSlots(c,s));
 s={};s[0]=6;s[1]=6;s[2]=6;s[3]=6;assert(ArrangeSlots(c,s));assert(!ValidateSlots(c,s,80,owned,limits));
 s={};s[0]=1;assert(!ValidateSlots(c,s,0,owned,limits));owned.erase(1);assert(!ValidateSlots(c,s,80,owned,limits));
}
