/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCompatOpcodes.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <deque>
#include <mutex>
#include <random>
#include <string>
#include <string_view>
#include <utility>
#include <vector>
#include <unordered_map>

namespace
{
    using namespace Acore::ChatCommands;

    constexpr uint16 PollListRequest = 0x0745;
    constexpr uint16 PollList = 0x0746;
    constexpr uint16 PollSubmit = 0x0747;
    constexpr uint16 PollResult = 0x0748;
    constexpr uint32 MaxQuestions = 3;
    constexpr uint32 MaxChoices = 10;
    constexpr std::size_t MaxFeedback = 2048;

    struct Choice
    {
        uint32 Id;
        std::string Text;
    };

    struct Question
    {
        uint32 Id;
        uint32 Type;
        bool Changeable;
        uint8 MinLevel;
        uint8 State;
        uint64 Expires;
        std::string Title;
        std::string Text;
        std::string Prompt;
        std::string Context;
        bool HasWire;
        uint32 Wire04;
        uint32 Wire50;
        uint32 Wire54;
        uint32 WireA8;
        uint32 Answer;
        std::string Feedback;
        uint64 Token;
        std::vector<Choice> Choices;
    };

    struct Request
    {
        bool Submit = false;
        bool Valid = true;
        uint32 QuestionId = 0;
        uint32 ChoiceId = 0;
        std::string Feedback;
    };

    struct Pending
    {
        ObjectGuid Guid;
        std::deque<Request> Requests;
        bool Busy = false;
        uint64 Epoch = 0;
        uint64 Generation = 0;
        uint64 Expires = 0;
    };

    std::atomic<bool> Enabled = true;
    std::atomic<uint64> Generation = 1;
    std::mutex PendingLock;
    std::unordered_map<uint32, Pending> Accounts;
    std::atomic<uint64> NextEpoch = 1;
    std::mt19937_64 Tokens(std::random_device{}());

    uint64 Now()
    {
        return GameTime::GetGameTime().count();
    }

    bool TextFits(std::string const& text, std::size_t limit, bool required = false)
    {
        return text.size() <= limit && (!required || !text.empty()) && text.find('\0') == std::string::npos;
    }

    std::vector<Question> ReadQuestions(PreparedQueryResult result)
    {
        std::vector<Question> questions;
        if (!result)
            return questions;
        do
        {
            Field* f = result->Fetch();
            uint32 const id = f[0].Get<uint32>();
            if (questions.empty() || questions.back().Id != id)
            {
                Question q{};
                q.Id = id;
                q.Type = f[1].Get<uint32>();
                q.Changeable = f[2].Get<uint8>() != 0;
                q.MinLevel = f[3].Get<uint8>();
                q.State = f[4].Get<uint8>();
                q.Expires = f[5].Get<uint64>();
                q.Title = f[6].Get<std::string>();
                q.Text = f[7].Get<std::string>();
                q.Prompt = f[8].Get<std::string>();
                q.Context = f[9].Get<std::string>();
                q.HasWire = !f[10].IsNull() && !f[11].IsNull() && !f[12].IsNull() && !f[13].IsNull();
                if (q.HasWire)
                {
                    q.Wire04 = f[10].Get<uint32>();
                    q.Wire50 = f[11].Get<uint32>();
                    q.Wire54 = f[12].Get<uint32>();
                    q.WireA8 = f[13].Get<uint32>();
                }
                q.Answer = f[14].IsNull() ? 0 : f[14].Get<uint32>();
                q.Feedback = f[15].IsNull() ? "" : f[15].Get<std::string>();
                q.Token = f[16].IsNull() ? 0 : f[16].Get<uint64>();
                questions.push_back(std::move(q));
            }
            if (!f[17].IsNull())
                questions.back().Choices.push_back({f[17].Get<uint32>(), f[18].Get<std::string>()});
        } while (result->NextRow());
        return questions;
    }

    bool ValidQuestion(Question const& q)
    {
        if (!q.Id || q.Type < 1 || q.Type > 4 || q.MinLevel < 10 || !q.HasWire ||
            !TextFits(q.Title, 256, true) || !TextFits(q.Text, 2048, true) ||
            !TextFits(q.Prompt, 512) || !TextFits(q.Context, 1024) || !TextFits(q.Feedback, MaxFeedback) ||
            q.Choices.size() > MaxChoices || (q.Type != 4 && q.Choices.empty()))
            return false;
        return std::all_of(q.Choices.begin(), q.Choices.end(), [](Choice const& choice)
        {
            return choice.Id && TextFits(choice.Text, 256, true);
        });
    }

    bool Visible(Question const& q, uint8 level)
    {
        return q.State == 1 && q.MinLevel <= level && (!q.Expires || q.Expires > Now());
    }

    void WriteQuestion(WorldPacket& packet, Question const& q)
    {
        packet << q.Id << q.Wire04 << q.Title << q.Text << q.Prompt << q.Wire50 << q.Wire54;
        packet << uint32(q.Choices.size());
        for (Choice const& choice : q.Choices)
            packet << choice.Id << choice.Text;
        packet << uint8(q.Answer != 0);
        if (q.Answer)
            packet << q.Answer;
        packet << uint8(!q.Feedback.empty());
        if (!q.Feedback.empty())
            packet << q.Feedback;
        packet << uint8(q.Changeable) << uint8(!q.Context.empty());
        if (!q.Context.empty())
            packet << q.Context;
        packet << q.WireA8 << q.Type;
    }

    void SendResult(WorldSession* session, char const* result, Question const* question = nullptr)
    {
        WorldPacket packet(PollResult, 256);
        packet << result << uint8(question != nullptr);
        if (question)
            WriteQuestion(packet, *question);
        session->SendPacket(&packet);
    }

    bool SamePlayer(WorldSession* session, ObjectGuid guid, uint64 epoch)
    {
        Player* player = session->GetPlayer();
        if (!player || player->GetGUID() != guid || !player->IsInWorld())
            return false;
        std::lock_guard lock(PendingLock);
        auto itr = Accounts.find(session->GetAccountId());
        return itr != Accounts.end() && itr->second.Guid == guid && itr->second.Epoch == epoch;
    }

    void Finish(WorldSession* session, ObjectGuid guid, uint64 epoch)
    {
        std::lock_guard lock(PendingLock);
        auto itr = Accounts.find(session->GetAccountId());
        if (itr != Accounts.end() && itr->second.Guid == guid && itr->second.Epoch == epoch)
            itr->second.Busy = false;
    }

    void RequestList(WorldSession* session, ObjectGuid guid, uint64 epoch)
    {
        uint8 const level = session->GetPlayer()->GetLevel();
        uint64 const generation = Generation.load();
        if (!Enabled)
        {
            WorldPacket packet(PollList, 4);
            packet << uint32(0);
            session->SendPacket(&packet);
            {
                std::lock_guard lock(PendingLock);
                auto itr = Accounts.find(session->GetAccountId());
                if (itr != Accounts.end() && itr->second.Epoch == epoch)
                {
                    itr->second.Generation = generation;
                    itr->second.Expires = 0;
                }
            }
            Finish(session, guid, epoch);
            return;
        }
        auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_PLAYER_POLLS);
        stmt->SetData(0, session->GetAccountId());
        stmt->SetData(1, level);
        session->QueueQueryCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback(
            [session, guid, epoch, generation, level](PreparedQueryResult result)
        {
            if (!SamePlayer(session, guid, epoch))
            {
                Finish(session, guid, epoch);
                return;
            }
            std::vector<Question> questions = ReadQuestions(result);
            if (!Enabled || questions.size() > MaxQuestions ||
                !std::all_of(questions.begin(), questions.end(), ValidQuestion))
            {
                questions.clear();
                LOG_ERROR("coa.poll", "Poll list withheld: disabled or invalid catalogue; inspect poll data.");
            }
            std::erase_if(questions, [session](Question const& q)
            {
                return !Visible(q, session->GetPlayer()->GetLevel());
            });
            WorldPacket packet(PollList, 1024);
            packet << uint32(questions.size());
            uint64 expiry = 0;
            for (Question const& q : questions)
            {
                WriteQuestion(packet, q);
                if (q.Expires && (!expiry || q.Expires < expiry))
                    expiry = q.Expires;
            }
            session->SendPacket(&packet);
            std::lock_guard lock(PendingLock);
            auto itr = Accounts.find(session->GetAccountId());
            if (itr != Accounts.end() && itr->second.Guid == guid && itr->second.Epoch == epoch)
            {
                itr->second.Busy = false;
                itr->second.Generation = session->GetPlayer()->GetLevel() == level ? generation : 0;
                itr->second.Expires = expiry;
            }
        }));
    }

    void SaveVote(WorldSession* session, ObjectGuid guid, uint64 epoch, Request const& request)
    {
        if (!Enabled || !request.Valid || !request.QuestionId || !TextFits(request.Feedback, MaxFeedback))
        {
            SendResult(session, "PLAYER_POLL_SUBMIT_REJECTED");
            Finish(session, guid, epoch);
            return;
        }
        uint64 token;
        {
            std::lock_guard lock(PendingLock);
            do
                token = Tokens();
            while (!token);
        }
        auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SAVE_PLAYER_POLL_VOTE);
        stmt->SetData(0, session->GetAccountId());
        stmt->SetData(1, guid.GetCounter());
        stmt->SetData(2, request.ChoiceId);
        stmt->SetData(3, request.Feedback);
        stmt->SetData(4, token);
        stmt->SetData(5, request.ChoiceId);
        stmt->SetData(6, request.QuestionId);
        stmt->SetData(7, session->GetPlayer()->GetLevel());
        stmt->SetData(8, request.ChoiceId);
        stmt->SetData(9, request.ChoiceId);
        stmt->SetData(10, request.Feedback);
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        transaction->Append(stmt);
        session->AddTransactionCallback(CharacterDatabase.AsyncCommitTransaction(transaction)).AfterComplete(
            [session, guid, epoch, id = request.QuestionId, token](bool committed)
        {
            if (!SamePlayer(session, guid, epoch))
            {
                Finish(session, guid, epoch);
                return;
            }
            if (!committed)
            {
                SendResult(session, "PLAYER_POLL_SUBMIT_UNAVAILABLE");
                Finish(session, guid, epoch);
                return;
            }
            auto* read = CharacterDatabase.GetPreparedStatement(CHAR_SEL_PLAYER_POLL);
            read->SetData(0, session->GetAccountId());
            read->SetData(1, id);
            session->QueueQueryCallback(CharacterDatabase.AsyncQuery(read).WithPreparedCallback(
                [session, guid, epoch, token](PreparedQueryResult result)
            {
                if (SamePlayer(session, guid, epoch))
                {
                    std::vector<Question> questions = ReadQuestions(result);
                    bool const saved = questions.size() == 1 && questions.front().Token == token;
                    Question const* update = nullptr;
                    if (Enabled && questions.size() == 1 && ValidQuestion(questions.front()) &&
                        Visible(questions.front(), session->GetPlayer()->GetLevel()))
                        update = &questions.front();
                    SendResult(session, saved ? "PLAYER_POLL_SUBMIT_OK" : "PLAYER_POLL_SUBMIT_REJECTED", update);
                    std::lock_guard lock(PendingLock);
                    auto itr = Accounts.find(session->GetAccountId());
                    if (itr != Accounts.end() && itr->second.Guid == guid && itr->second.Epoch == epoch)
                        itr->second.Generation = 0;
                }
                Finish(session, guid, epoch);
            }));
        });
    }

    void Submit(WorldSession* session, ObjectGuid guid, uint64 epoch, Request const& request)
    {
        if (!Enabled || !request.Valid || !request.QuestionId)
        {
            SendResult(session, "PLAYER_POLL_SUBMIT_REJECTED");
            Finish(session, guid, epoch);
            return;
        }
        auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_PLAYER_POLL);
        stmt->SetData(0, session->GetAccountId());
        stmt->SetData(1, request.QuestionId);
        session->QueueQueryCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback(
            [session, guid, epoch, request](PreparedQueryResult result)
        {
            if (!SamePlayer(session, guid, epoch))
            {
                Finish(session, guid, epoch);
                return;
            }
            std::vector<Question> questions = ReadQuestions(result);
            bool valid = Enabled && questions.size() == 1 && ValidQuestion(questions.front()) &&
                Visible(questions.front(), session->GetPlayer()->GetLevel());
            if (valid)
            {
                Question const& q = questions.front();
                valid = request.ChoiceId ? std::any_of(q.Choices.begin(), q.Choices.end(),
                    [&request](Choice const& choice) { return choice.Id == request.ChoiceId; }) :
                    q.Type == 4 && !request.Feedback.empty();
                bool const answered = q.Answer || (q.Type == 4 && !q.Feedback.empty());
                valid = valid && (!answered || (q.Changeable &&
                    (q.Answer != request.ChoiceId || q.Feedback != request.Feedback)));
            }
            if (!valid)
            {
                SendResult(session, "PLAYER_POLL_SUBMIT_REJECTED");
                Finish(session, guid, epoch);
                return;
            }
            SaveVote(session, guid, epoch, request);
        }));
    }

    bool ReadString(WorldPacket& packet, std::string& value)
    {
        while (packet.rpos() < packet.size())
        {
            char const byte = char(packet.read<uint8>());
            if (!byte)
                return true;
            if (value.size() == MaxFeedback)
                return false;
            value.push_back(byte);
        }
        return false;
    }

    bool Queue(WorldSession* session, WorldPacket const& received)
    {
        if (!session || session->IsBot())
            return true;
        Request request;
        request.Submit = received.GetOpcode() == PollSubmit;
        WorldPacket packet(received);
        packet.rpos(0);
        try
        {
            if (request.Submit && packet.size() >= 6 && packet.size() <= MaxFeedback + 11)
            {
                request.QuestionId = packet.read<uint32>();
                uint8 const choice = packet.read<uint8>();
                request.Valid = choice <= 1;
                if (choice == 1)
                {
                    request.ChoiceId = packet.read<uint32>();
                    request.Valid = request.Valid && request.ChoiceId != 0;
                }
                uint8 const feedback = packet.read<uint8>();
                request.Valid = request.Valid && feedback <= 1;
                if (feedback == 1)
                    request.Valid = ReadString(packet, request.Feedback) && request.Valid;
            }
            else if (request.Submit)
                request.Valid = false;
            request.Valid = request.Valid && packet.rpos() == packet.size();
        }
        catch (ByteBufferException const&)
        {
            request.Valid = false;
        }
        std::lock_guard lock(PendingLock);
        auto itr = Accounts.find(session->GetAccountId());
        if (itr == Accounts.end() || (!request.Submit && !request.Valid))
            return true;
        auto& queue = itr->second.Requests;
        if (queue.size() < 4 && (request.Submit || std::none_of(queue.begin(), queue.end(),
            [](Request const& item) { return !item.Submit; })))
            queue.push_back(std::move(request));
        return true;
    }

    class PollWorld final : public WorldScript
    {
        uint32 _timer = 1000;

    public:
        PollWorld() : WorldScript("coa_player_poll_world",
            {WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_UPDATE}) { }

        void OnAfterConfigLoad(bool) override
        {
            Enabled = sConfigMgr->GetOption<bool>("CoA.PlayerPoll.Enable", true);
            ++Generation;
        }

        void OnUpdate(uint32 diff) override
        {
            if (_timer > diff)
            {
                _timer -= diff;
                return;
            }
            _timer = 1000;
            struct Job
            {
                uint32 Account;
                ObjectGuid Guid;
                uint64 Epoch;
                Request Data;
            };
            std::vector<Job> jobs;
            {
                std::lock_guard lock(PendingLock);
                for (auto& [account, pending] : Accounts)
                {
                    if (pending.Busy)
                        continue;
                    Request request;
                    if (pending.Requests.empty())
                    {
                        if (pending.Generation == Generation.load() &&
                            (!pending.Expires || pending.Expires > Now()))
                            continue;
                    }
                    else
                    {
                        request = std::move(pending.Requests.front());
                        pending.Requests.pop_front();
                    }
                    pending.Busy = true;
                    jobs.push_back({account, pending.Guid, pending.Epoch, std::move(request)});
                }
            }
            for (Job const& job : jobs)
            {
                Player* player = ObjectAccessor::FindConnectedPlayer(job.Guid);
                if (!player || player->GetSession()->GetAccountId() != job.Account || !player->IsInWorld())
                {
                    std::lock_guard lock(PendingLock);
                    auto itr = Accounts.find(job.Account);
                    if (itr != Accounts.end() && itr->second.Epoch == job.Epoch)
                    {
                        itr->second.Busy = false;
                        if (job.Data.Submit && itr->second.Requests.size() < 4)
                            itr->second.Requests.push_front(job.Data);
                    }
                    continue;
                }
                WorldSession* session = player->GetSession();
                if (job.Data.Submit)
                    Submit(session, job.Guid, job.Epoch, job.Data);
                else
                    RequestList(session, job.Guid, job.Epoch);
            }
        }
    };

    class PollPlayers final : public PlayerScript
    {
    public:
        PollPlayers() : PlayerScript("coa_player_poll_players",
            {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_LOGOUT}) { }

        void OnPlayerLogin(Player* player) override
        {
            if (player->GetSession()->IsBot())
                return;
            std::lock_guard lock(PendingLock);
            Pending& pending = Accounts[player->GetSession()->GetAccountId()];
            pending = {};
            pending.Guid = player->GetGUID();
            pending.Epoch = NextEpoch++;
        }

        void OnPlayerLevelChanged(Player* player, uint8) override
        {
            std::lock_guard lock(PendingLock);
            auto itr = Accounts.find(player->GetSession()->GetAccountId());
            if (itr != Accounts.end())
                itr->second.Generation = 0;
        }

        void OnPlayerLogout(Player* player) override
        {
            std::lock_guard lock(PendingLock);
            Accounts.erase(player->GetSession()->GetAccountId());
        }
    };

    bool Admin(ChatHandler* handler)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        {
            handler->SendErrorMessage("Poll management requires administrator access.");
            return false;
        }
        return true;
    }

    std::vector<Question> FindQuestion(uint32 id)
    {
        auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_PLAYER_POLL);
        stmt->SetData(0, uint32(0));
        stmt->SetData(1, id);
        return ReadQuestions(CharacterDatabase.Query(stmt));
    }

    bool Draft(ChatHandler* handler, uint32 id)
    {
        std::vector<Question> questions = FindQuestion(id);
        if (questions.size() != 1 || questions.front().State != 0)
        {
            handler->SendErrorMessage("Only an existing draft can be edited. Published questions are immutable.");
            return false;
        }
        return true;
    }

    class PollCommands final : public CommandScript
    {
    public:
        PollCommands() : CommandScript("coa_player_poll_commands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable children =
            {
                {"create", Create, SEC_ADMINISTRATOR, Console::Yes},
                {"choice", AddChoice, SEC_ADMINISTRATOR, Console::Yes},
                {"publish", Publish, SEC_ADMINISTRATOR, Console::Yes},
                {"close", Close, SEC_ADMINISTRATOR, Console::Yes},
                {"list", List, SEC_ADMINISTRATOR, Console::Yes},
                {"results", Results, SEC_ADMINISTRATOR, Console::Yes}
            };
            static ChatCommandTable commands = {{"poll", children}};
            return commands;
        }

        static bool Create(ChatHandler* handler, uint32 id, uint32 type, uint32 changeable,
            uint32 minLevel, QuotedString title, QuotedString question,
            Optional<QuotedString> prompt, Optional<QuotedString> context)
        {
            if (!Admin(handler))
                return false;
            std::array<std::string, 4> const parts =
            {
                title, question, prompt ? std::string(*prompt) : "", context ? std::string(*context) : ""
            };
            if (!id || type < 1 || type > 4 || changeable > 1 || minLevel < 10 || minLevel > 255 ||
                !TextFits(parts[0], 256, true) || !TextFits(parts[1], 2048, true) ||
                !TextFits(parts[2], 512) || !TextFits(parts[3], 1024))
            {
                handler->SendErrorMessage(
                    "Invalid poll: ID must be nonzero, type 1-4, allowChange 0 or 1, level 10-255; "
                    "title/question are required and text byte limits must be respected.");
                return false;
            }
            if (!FindQuestion(id).empty())
            {
                handler->SendErrorMessage("That question ID already exists; choose an unused ID.");
                return false;
            }
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_PLAYER_POLL);
            stmt->SetData(0, id);
            stmt->SetData(1, type);
            stmt->SetData(2, changeable);
            stmt->SetData(3, minLevel);
            for (uint8 i = 0; i < 4; ++i)
                stmt->SetData(4 + i, parts[i]);
            CharacterDatabase.DirectExecute(stmt);
            std::vector<Question> questions = FindQuestion(id);
            if (questions.size() != 1 || questions.front().State != 0 ||
                questions.front().Type != type || questions.front().Changeable != bool(changeable) ||
                questions.front().MinLevel != minLevel || questions.front().Title != parts[0] ||
                questions.front().Text != parts[1] || questions.front().Prompt != parts[2] ||
                questions.front().Context != parts[3])
            {
                handler->SendErrorMessage(
                    "Poll creation could not be verified in the characters database; check worldserver SQL logs.");
                return false;
            }
            handler->PSendSysMessage(
                "Draft {} is stored. Add choices, then publish when ready.", id);
            return true;
        }

        static bool AddChoice(ChatHandler* handler, uint32 id, uint32 choice, Tail text)
        {
            if (!Admin(handler) || !Draft(handler, id) || !choice || !TextFits(std::string(text), 256, true))
                return false;
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_PLAYER_POLL_CHOICE);
            stmt->SetData(0, choice);
            stmt->SetData(1, std::string(text));
            stmt->SetData(2, id);
            CharacterDatabase.DirectExecute(stmt);
            std::vector<Question> questions = FindQuestion(id);
            bool const saved = questions.size() == 1 && std::any_of(questions.front().Choices.begin(),
                questions.front().Choices.end(), [choice, text](Choice const& item)
                { return item.Id == choice && item.Text == std::string(text); });
            if (saved)
                handler->PSendSysMessage("Choice {} stored for draft {}.", choice, id);
            return saved;
        }

        static bool Publish(ChatHandler* handler, uint32 id, uint64 expires)
        {
            if (!Admin(handler) || !Draft(handler, id))
                return false;
            std::vector<Question> questions = FindQuestion(id);
            if (questions.size() != 1 || !ValidQuestion(questions.front()) || (expires && expires <= Now()))
            {
                handler->SendErrorMessage(
                    "Invalid draft: check type, text, choices and future expiry (or 0).");
                return false;
            }
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_PUBLISH_PLAYER_POLL);
            stmt->SetData(0, expires);
            stmt->SetData(1, id);
            CharacterDatabase.DirectExecute(stmt);
            questions = FindQuestion(id);
            if (questions.size() != 1 || questions.front().State != 1)
            {
                handler->SendErrorMessage(
                    "Publication failed; at most three unexpired published questions are allowed.");
                return false;
            }
            ++Generation;
            handler->PSendSysMessage("Poll {} published; expiry {}. Online players will refresh.", id, expires);
            return true;
        }

        static bool Close(ChatHandler* handler, uint32 id)
        {
            if (!Admin(handler))
                return false;
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_CLOSE_PLAYER_POLL);
            stmt->SetData(0, id);
            CharacterDatabase.DirectExecute(stmt);
            std::vector<Question> questions = FindQuestion(id);
            if (questions.size() != 1 || questions.front().State != 2)
                return false;
            ++Generation;
            handler->PSendSysMessage("Poll {} closed. Answers retained; online players will refresh.", id);
            return true;
        }

        static bool List(ChatHandler* handler)
        {
            if (!Admin(handler))
                return false;
            PreparedQueryResult rows = CharacterDatabase.Query(
                CharacterDatabase.GetPreparedStatement(CHAR_LIST_PLAYER_POLLS));
            if (!rows)
                handler->SendSysMessage("No polls found (check database logs if unexpected).");
            else do
            {
                Field* f = rows->Fetch();
                handler->PSendSysMessage("{}: {} | state {} type {} level {} expiry {} answers {} wire {}",
                    f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<uint8>(), f[3].Get<uint32>(),
                    f[4].Get<uint8>(), f[5].Get<uint64>(), f[6].Get<uint64>(), f[7].Get<uint8>());
            } while (rows->NextRow());
            return true;
        }

        static bool Results(ChatHandler* handler, uint32 id)
        {
            if (!Admin(handler) || FindQuestion(id).empty())
                return false;
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_PLAYER_POLL_RESULTS);
            stmt->SetData(0, id);
            PreparedQueryResult rows = CharacterDatabase.Query(stmt);
            if (rows)
                do
                {
                    Field* f = rows->Fetch();
                    handler->PSendSysMessage("Choice {}: {} answers", f[0].Get<uint32>(), f[1].Get<uint64>());
                } while (rows->NextRow());
            auto* comments = CharacterDatabase.GetPreparedStatement(CHAR_PLAYER_POLL_COMMENTS);
            comments->SetData(0, id);
            rows = CharacterDatabase.Query(comments);
            if (rows)
                do
                {
                    Field* f = rows->Fetch();
                    std::string text = f[1].Get<std::string>();
                    for (char& byte : text)
                        if (byte == '|' || static_cast<unsigned char>(byte) < 32)
                            byte = ' ';
                    handler->PSendSysMessage("Account {}: {}", f[0].Get<uint32>(), text);
                } while (rows->NextRow());
            handler->SendSysMessage(
                "Comment preview: newest 20; complete comments remain in the characters database.");
            return true;
        }
    };
}

void AddSC_AscensionPlayerPoll()
{
    AscensionCompatOpcodes::Claim(PollListRequest, &Queue);
    AscensionCompatOpcodes::Claim(PollSubmit, &Queue);
    new PollWorld();
    new PollPlayers();
    new PollCommands();
}
