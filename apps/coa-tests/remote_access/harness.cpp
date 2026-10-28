#include "RASession.h"
#include <boost/asio/post.hpp>
#include <boost/asio/steady_timer.hpp>
#include <boost/asio/write.hpp>
#include <chrono>
#include <cstring>
#include <future>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>
using namespace std::chrono_literals;
#define AC_GAME_API
#define LOG_INFO(...)
using uint8 = std::uint8_t;
// ACTUAL_HOLDER
CliCommandHolder::CliCommandHolder(void* arg, char const* command, Print print, CommandFinished finished)
    : m_callbackArg(arg), m_command(strdup(command)), m_print(print), m_commandFinished(finished) { }
CliCommandHolder::~CliCommandHolder() { free(m_command); }
struct WorldFixture
{
    std::mutex mutex;
    std::vector<CliCommandHolder*> commands;
    void QueueCliCommand(CliCommandHolder* command)
    {
        std::lock_guard lock(mutex);
        commands.push_back(command);
    }
    bool Pending()
    {
        std::lock_guard lock(mutex);
        return !commands.empty();
    }
    void Complete()
    {
        std::lock_guard lock(mutex);
        for (auto* command : commands)
        {
            command->m_print(command->m_callbackArg, "done\r\n");
            command->m_commandFinished(command->m_callbackArg, true);
            delete command;
        }
        commands.clear();
    }
} world;
WorldFixture* sWorld = &world;
constexpr int DEFAULT_LOCALE = 0;
struct MotdFixture { std::string GetMotd(int) { return "welcome"; } } motd;
MotdFixture* sMotdMgr = &motd;
std::weak_ptr<RASession> lastSession;
bool RASession::CheckAccessLevel(std::string const&) { return true; }
bool RASession::CheckPassword(std::string const&, std::string const&) { return true; }
// ACTUAL_SOURCE

bool ReadPrompt(IoContextTcpSocket& socket, std::string_view marker)
{
    socket.non_blocking(true);
    std::string data;
    auto const deadline = std::chrono::steady_clock::now() + 3s;
    while (std::chrono::steady_clock::now() < deadline)
    {
        char buffer[512];
        boost::system::error_code error;
        auto const count = socket.read_some(boost::asio::buffer(buffer), error);
        data.append(buffer, count);
        if (data.find(marker) != std::string::npos)
            return true;
        if (error && error != boost::asio::error::would_block && error != boost::asio::error::try_again)
            return false;
        std::this_thread::sleep_for(2ms);
    }
    return false;
}

bool RunCase(int stage)
{
    boost::asio::io_context context;
    auto guard = boost::asio::make_work_guard(context);
    boost::asio::ip::tcp::acceptor acceptor(context, {boost::asio::ip::tcp::v4(), 0});
    IoContextTcpSocket client(context);
    client.connect({boost::asio::ip::address_v4::loopback(), acceptor.local_endpoint().port()});
    IoContextTcpSocket server(context);
    acceptor.accept(server);
    auto session = std::make_shared<RASession>(std::move(server));
    lastSession = session;
    boost::asio::post(context, [session]() { session->Start(); });
    auto worker = std::async(std::launch::async, [&context]() { context.run(); });
    bool wire = ReadPrompt(client, "Username: ");
    if (wire && stage > 0)
    {
        boost::asio::write(client, boost::asio::buffer("tester\r\n", 8));
        wire = ReadPrompt(client, "Password: ");
        if (stage == 1)
            boost::asio::write(client, boost::asio::buffer("partial", 7));
        else
        {
            boost::asio::write(client, boost::asio::buffer("password\r\n", 10));
            wire = wire && ReadPrompt(client, "AC>");
            if (stage >= 3)
            {
                boost::asio::write(client, boost::asio::buffer("server info\r\n", 13));
                auto const deadline = std::chrono::steady_clock::now() + 1s;
                while (!world.Pending() && std::chrono::steady_clock::now() < deadline)
                    std::this_thread::sleep_for(2ms);
                wire = wire && world.Pending();
                if (stage == 4)
                {
                    world.Complete();
                    wire = wire && ReadPrompt(client, "done\r\nAC>");
                }
            }
        }
    }
    session.reset();
    context.stop();
    bool stopped = worker.wait_for(300ms) == std::future_status::ready;
    if (stage != 5 || !stopped)
        world.Complete();
    boost::system::error_code error;
    client.shutdown(boost::asio::ip::tcp::socket::shutdown_both, error);
    client.close(error);
    try
    {
        worker.get();
    }
    catch (std::exception const& error)
    {
        std::cerr << error.what() << '\n';
        wire = false;
    }
    std::cout << "RA stage " << stage << ": wire=" << wire << ", stopped=" << stopped << '\n';
    return wire && stopped;
}

int main()
{
    bool passed = true;
    for (int stage = 0; stage < 6; ++stage)
    {
        passed = RunCase(stage) && passed;
        bool const released = lastSession.expired();
        std::cout << "RA stage " << stage << ": released=" << released << '\n';
        passed = released && passed;
        world.Complete();
    }
    return passed ? 0 : 1;
}
