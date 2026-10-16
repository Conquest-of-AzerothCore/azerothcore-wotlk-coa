#ifndef COA_ASCENSION_BLOODFORGING_H
#define COA_ASCENSION_BLOODFORGING_H

#include "Define.h"

class Item;
struct ItemTemplate;

namespace Bloodforging
{
enum class Method
{
    BloodyJar,
    HighRiskDrop
};

uint32 FindEntry(ItemTemplate const& source, Method method = Method::BloodyJar);
bool Convert(Item& item, Method method = Method::BloodyJar);
bool IsBloodforged(ItemTemplate const& item);
}

#endif
