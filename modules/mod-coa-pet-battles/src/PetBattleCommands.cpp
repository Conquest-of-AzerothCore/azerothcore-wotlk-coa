#include "Battle/PetBattles.h"
#include "Chat.h"
#include "Protocol/AddonMessage.h"
#include "CommandScript.h"
#include "Engine/Sim.h"
#include "GameTime.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "Store/PetJournalStore.h"
#include "Wild/WildPets.h"
#include "WorldSession.h"
#include <random>

using namespace Acore::ChatCommands;
using CoAPetBattles::Store::Journal;
using CoAPetBattles::Store::OwnedPet;
using CoAPetBattles::Store::TeamResult;

namespace
{
    struct Target
    {
        Player* player = nullptr;
        Journal* journal = nullptr;
    };

    std::optional<Target> JournalOf(ChatHandler* handler)
    {
        Player* player = handler->getSelectedPlayerOrSelf();
        Journal* journal = sPetJournals->For(player);
        if (!journal)
        {
            handler->SendErrorMessage("no pet journal for " + (player ? player->GetName() : std::string("nobody")),
                false);
            return std::nullopt;
        }
        return Target { player, journal };
    }

    std::string SpeciesName(uint32 species)
    {
        std::shared_ptr<CoAPetBattles::Engine::Catalog const> const catalog = sPetBattleData->Catalog();
        CoAPetBattles::Engine::SpeciesDef const* def = catalog ? catalog->Species(species) : nullptr;
        return def ? def->name : "species " + std::to_string(species);
    }

    uint32 Now()
    {
        return static_cast<uint32>(GameTime::GetGameTime().count());
    }

    std::string TeamLine(Journal const& journal, uint8 team)
    {
        auto const& slots = journal.TeamAt(team).slots;
        return "Team " + std::to_string(team) + ": " + std::to_string(journal.SpeciesForPet(slots[0])) + " " + std::to_string(journal.SpeciesForPet(slots[1])) + " " +
            std::to_string(journal.SpeciesForPet(slots[2]));
    }

    class PetBattleCommands : public CommandScript
    {
    public:
        PetBattleCommands() : CommandScript("coa_pet_battles_commands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable teamCommands =
            {
                { "active", HandleTeamActive, SEC_GAMEMASTER, Console::No },
                { "", HandleTeam, SEC_GAMEMASTER, Console::No },
            };
            static ChatCommandTable petBattleCommands =
            {
                { "sim", HandleSim, SEC_GAMEMASTER, Console::Yes },
                { "journal", HandleJournal, SEC_GAMEMASTER, Console::No },
                { "grant", HandleGrant, SEC_GAMEMASTER, Console::No },
                { "xp", HandleXp, SEC_GAMEMASTER, Console::No },
                { "health", HandleHealth, SEC_GAMEMASTER, Console::No },
                { "heal", HandleHeal, SEC_GAMEMASTER, Console::No },
                { "picks", HandlePicks, SEC_GAMEMASTER, Console::No },
                { "team", teamCommands },
                { "reload", HandleReload, SEC_GAMEMASTER, Console::No },
                { "fight", HandleFight, SEC_GAMEMASTER, Console::No },
                { "send", HandleSend, SEC_GAMEMASTER, Console::No },
                { "state", HandleState, SEC_GAMEMASTER, Console::No },
                { "wild", HandleWild, SEC_GAMEMASTER, Console::No },
                { "follower", HandleFollower, SEC_GAMEMASTER, Console::No },
                { "challenge", HandleChallenge, SEC_GAMEMASTER, Console::No },
            };
            static ChatCommandTable commands =
            {
                { "petbattle", petBattleCommands },
            };
            return commands;
        }

        static bool HandleSim(ChatHandler* handler, uint32 speciesA, uint32 speciesB, Optional<uint32> level,
            Optional<uint32> seed)
        {
            std::shared_ptr<CoAPetBattles::Engine::Catalog const> const catalog = sPetBattleData->Catalog();
            if (!sPetBattleData->IsLoaded() || !catalog)
            {
                handler->SendErrorMessage("pet battle data is not loaded", false);
                return false;
            }
            uint32 const chosenSeed = seed ? *seed : std::random_device {}();
            int32 const chosenLevel = level ? static_cast<int32>(std::min<uint32>(*level, 1000)) : 25;
            CoAPetBattles::Engine::SimResult const result =
                CoAPetBattles::Engine::RunSim(*catalog, speciesA, speciesB, chosenLevel, chosenSeed);
            if (!result.error.empty())
            {
                handler->SendErrorMessage(result.error, false);
                return false;
            }
            for (std::string const& line : result.lines)
                handler->SendSysMessage(line);
            return true;
        }

        static bool HandleJournal(ChatHandler* handler)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            Journal const& journal = *target->journal;
            std::vector<OwnedPet const*> const pets = journal.Pets();
            handler->SendSysMessage("[Pet journal] " + std::to_string(pets.size()) + " pets, active team " +
                std::to_string(journal.ActiveTeam()));
            uint32 const now = Now();
            std::shared_ptr<CoAPetBattles::Engine::Catalog const> const catalog = sPetBattleData->Catalog();
            for (OwnedPet const* pet : pets)
                handler->SendSysMessage(std::to_string(pet->species) + " " + SpeciesName(pet->species) + " L" +
                    std::to_string(pet->level) + " q" + std::to_string(pet->quality) + " xp " + std::to_string(pet->xp) +
                    "/" + std::to_string(catalog ? CoAPetBattles::Store::XpNeeded(*catalog, pet->level) : 0) +
                    " picks " + std::to_string(pet->picks[0]) + std::to_string(pet->picks[1]) +
                    std::to_string(pet->picks[2]) + " hp " + std::to_string(journal.CurrentHealth(*pet, now)) + "/" +
                    std::to_string(journal.MaxHealth(*pet)));
            for (uint8 team = 1; team <= CoAPetBattles::Store::TeamCount; ++team)
                handler->SendSysMessage(TeamLine(journal, team));
            return true;
        }

        static bool HandleGrant(ChatHandler* handler, uint32 species, Optional<uint8> level, Optional<uint8> quality)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            std::shared_ptr<CoAPetBattles::Engine::Catalog const> const catalog = sPetBattleData->Catalog();
            if (!catalog || !catalog->Species(species))
            {
                handler->SendErrorMessage("unknown pet species " + std::to_string(species), false);
                return false;
            }
            if (!target->journal->Add(species, level.value_or(1), { 1, 1, 1 }, quality.value_or(1), 0))
            {
                handler->SendErrorMessage("already owned", false);
                return false;
            }
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage("Added " + SpeciesName(species) + " L" +
                std::to_string(target->journal->PetOfSpecies(species)->level));
            return true;
        }

        static bool HandleXp(ChatHandler* handler, uint32 species, uint8 enemyLevel)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            std::optional<CoAPetBattles::Store::XpGain> const gain =
                target->journal->GrantXp(target->journal->PetIdForSpecies(species), enemyLevel, Now());
            if (!gain)
            {
                handler->SendErrorMessage("not owned", false);
                return false;
            }
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage(SpeciesName(species) + " gains " + std::to_string(gain->gained) + " xp, now L" +
                std::to_string(gain->level));
            return true;
        }

        static bool HandleHealth(ChatHandler* handler, uint32 species, uint32 health)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            uint32 const now = Now();
            if (!target->journal->SetHealth(target->journal->PetIdForSpecies(species), health, now))
            {
                handler->SendErrorMessage("not owned", false);
                return false;
            }
            sPetJournals->Flush(*target->journal);
            OwnedPet const& pet = *target->journal->PetOfSpecies(species);
            handler->SendSysMessage(SpeciesName(species) + " health " +
                std::to_string(target->journal->CurrentHealth(pet, now)) + "/" +
                std::to_string(target->journal->MaxHealth(pet)));
            return true;
        }

        static bool HandleHeal(ChatHandler* handler)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            size_t const healed = target->journal->HealAll();
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage("Healed " + std::to_string(healed) + " pets");
            return true;
        }

        static bool HandlePicks(ChatHandler* handler, uint32 species, uint8 first, uint8 second, uint8 third)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            if (!target->journal->SetPicks(target->journal->PetIdForSpecies(species), { first, second, third }))
            {
                handler->SendErrorMessage("picks must be 1 or 2 for an owned pet", false);
                return false;
            }
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage(SpeciesName(species) + " picks " + std::to_string(first) + std::to_string(second) +
                std::to_string(third));
            return true;
        }

        static bool HandleTeam(ChatHandler* handler, uint8 team, uint32 first, uint32 second, uint32 third)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            std::array<uint32_t, 3> slots = { first, second, third };
            for (uint32_t& slot : slots)
            {
                if (!slot)
                    continue;
                slot = target->journal->PetIdForSpecies(slot);
                if (!slot)
                {
                    handler->SendErrorMessage("every pet in a team must be owned", false);
                    return false;
                }
            }
            switch (target->journal->SetTeam(team, slots))
            {
                case TeamResult::BadTeam:
                    handler->SendErrorMessage("team must be 1-3", false);
                    return false;
                case TeamResult::NotOwned:
                    handler->SendErrorMessage("every pet in a team must be owned", false);
                    return false;
                case TeamResult::Duplicate:
                    handler->SendErrorMessage("a pet can be in a team only once", false);
                    return false;
                case TeamResult::Saved:
                    break;
            }
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage("Team " + std::to_string(team) + " set: " + std::to_string(first) + " " +
                std::to_string(second) + " " + std::to_string(third));
            return true;
        }

        static bool HandleTeamActive(ChatHandler* handler, uint8 team)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            if (!target->journal->SetActiveTeam(team))
            {
                handler->SendErrorMessage("team must be 1-3", false);
                return false;
            }
            sPetJournals->Flush(*target->journal);
            handler->SendSysMessage("Active team " + std::to_string(team));
            return true;
        }

        static bool HandleFight(ChatHandler* handler, Tail enemies)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            if (!sPetBattles->Challenge(target->player, std::string(enemies)))
            {
                handler->SendErrorMessage("no pet battle started", false);
                return false;
            }
            handler->SendSysMessage("Pet battle started");
            return true;
        }

        static bool HandleSend(ChatHandler* handler, Tail text)
        {
            Player* player = handler->getSelectedPlayerOrSelf();
            std::optional<CoAPetBattles::Protocol::AddonMessage> const message =
                CoAPetBattles::Protocol::ParseAddonMessage(std::string(text));
            if (!player || !message)
            {
                handler->SendErrorMessage("expected <module>|<action>|<payload>", false);
                return false;
            }
            sPetBattles->Message(player, message->module, message->action, message->payload);
            return true;
        }

        static bool HandleState(ChatHandler* handler)
        {
            Player* player = handler->getSelectedPlayerOrSelf();
            if (!player)
                return false;
            handler->SendSysMessage(std::string("Pet battle: ") + (sPetBattles->InBattle(player) ? "active" : "none") +
                ", stand-ins " + std::to_string(sPetBattles->StandIns(player)));
            return true;
        }

        static bool HandleWild(ChatHandler* handler)
        {
            Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            if (!player)
                return false;
            std::vector<std::string> const lines = sWildPets->Describe(player);
            handler->SendSysMessage("Wild pets near you: " + std::to_string(lines.size()) + " of " +
                std::to_string(sWildPets->Count()));
            for (std::string const& line : lines)
                handler->SendSysMessage(line);
            return true;
        }

        static bool HandleFollower(ChatHandler* handler)
        {
            Player* player = handler->getSelectedPlayerOrSelf();
            if (!player)
                return false;
            uint64_t const character = player->GetGUID().GetCounter();
            Journal const* journal = sPetJournals->For(player);
            uint32_t const petId = sPetBattles->Followers().Follower(character);
            uint32_t const species = journal ? journal->SpeciesForPet(petId) : 0;
            if (!species)
                handler->SendSysMessage("Follower: none");
            else
                handler->SendSysMessage("Follower: " + std::to_string(species) + " " +
                    (sPetBattles->Followers().Out(character) ? "out" : "hidden"));
            return true;
        }

        static bool HandleChallenge(ChatHandler* handler)
        {
            Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
            if (!player)
                return false;
            if (!sWildPets->ChallengeNearest(player))
            {
                handler->SendErrorMessage("no wild pet near you", false);
                return false;
            }
            return true;
        }

        static bool HandleReload(ChatHandler* handler)
        {
            std::optional<Target> target = JournalOf(handler);
            if (!target)
                return false;
            uint32 const account = target->player->GetSession()->GetAccountId();
            if (size_t const pending = sPetJournals->Pending(account))
            {
                handler->SendErrorMessage(std::to_string(pending) + " pet journal writes still pending", false);
                return false;
            }
            if (!sPetJournals->Reload(account))
            {
                handler->SendErrorMessage("pet journal could not be reloaded", false);
                return false;
            }
            handler->SendSysMessage("Reloaded " + std::to_string(sPetJournals->Get(account)->Pets().size()) + " pets");
            return true;
        }
    };
}

void AddSC_coa_pet_battles_commands()
{
    new PetBattleCommands();
}
