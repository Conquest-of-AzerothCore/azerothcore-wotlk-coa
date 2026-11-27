#include "JournalSql.h"
#include <initializer_list>

namespace CoAPetBattles::Store
{
    namespace
    {
        std::string Upsert(std::string const& table, std::initializer_list<char const*> keys,
            std::initializer_list<char const*> columns, std::initializer_list<uint64_t> values)
        {
            std::string sql = "INSERT INTO `" + table + "` (";
            bool first = true;
            for (char const* column : keys)
            {
                sql += std::string(first ? "" : ", ") + "`" + column + "`";
                first = false;
            }
            for (char const* column : columns)
                sql += std::string(", `") + column + "`";
            sql += ", `revision`) VALUES (";
            first = true;
            for (uint64_t value : values)
            {
                sql += (first ? "" : ", ") + std::to_string(value);
                first = false;
            }
            sql += ") ON DUPLICATE KEY UPDATE ";
            for (char const* column : columns)
                sql += std::string("`") + column + "` = IF(VALUES(`revision`) > `revision`, VALUES(`" + column +
                    "`), `" + column + "`), ";
            return sql + "`revision` = IF(VALUES(`revision`) > `revision`, VALUES(`revision`), `revision`)";
        }
    }

    std::string UpsertStatement(Journal const& journal, RowWrite const& write)
    {
        switch (write.kind)
        {
            case RowKind::Pet:
            {
                OwnedPet const* pet = journal.Pet(write.key);
                if (!pet)
                    return "";
                return Upsert("coa_pet_journal", { "account", "pet_id" },
                    { "species", "level", "xp", "ability1", "ability2", "ability3", "quality", "display", "health",
                      "health_at", "breed", "source" },
                    { write.account, pet->id, pet->species, pet->level, pet->xp, pet->picks[0], pet->picks[1],
                      pet->picks[2], pet->quality, pet->display, pet->health, pet->healthAt, pet->breed,
                      static_cast<uint8_t>(pet->source), write.revision });
            }
            case RowKind::Release:
                return Upsert("coa_pet_journal", { "account", "pet_id" }, { "species", "source" },
                    { write.account, write.key, 0, static_cast<uint8_t>(PetSource::Released), write.revision });
            case RowKind::Team:
            {
                if (write.key < 1 || write.key > TeamCount)
                    return "";
                Team const& team = journal.TeamAt(static_cast<uint8_t>(write.key));
                return Upsert("coa_pet_team", { "account", "team" }, { "slot1", "slot2", "slot3" },
                    { write.account, write.key, team.slots[0], team.slots[1], team.slots[2], write.revision });
            }
            case RowKind::Account:
                return Upsert("coa_pet_account", { "account" }, { "active_team" },
                    { write.account, journal.ActiveTeam(), write.revision });
        }
        return "";
    }
}
