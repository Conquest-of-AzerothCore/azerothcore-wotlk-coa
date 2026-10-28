CLI_DESCRIPTION = """Check the native player ticket service without a server.

Compiles src/server/coa/CoAPlayerTicketService.h into a program that drives tickets the way the
CMSG 0x0703/0x0705/0x0707/0x0719/0x071D handlers and the .support commands do, and decodes every
written ticket record with the field order of the Extensions.dll ticket reader.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'coa_config/run.py'))['method']

MAIN = r"""
#include "CoAPlayerTicketService.h"
#include <cstdio>
#include <fstream>
#include <string>

using namespace CoAPlayerTicket;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

Author Player(std::uint32_t account = 7)
{
    return { account, 42, "Tester", "enUS" };
}

Request Issue(std::string title = "Quest broken", std::string description = "The quest giver is missing.")
{
    return { 1, 8, std::move(title), std::move(description), std::string(AffectedAll) };
}

void Dump(std::string const& path, Ticket const& ticket, std::string const& viewer)
{
    ByteBuffer buffer;
    WritePlayerTicket(buffer, ticket, viewer);
    std::ofstream file(path, std::ios::binary);
    file.write(reinterpret_cast<char const*>(buffer.contents()), buffer.size());
}
}

int main(int, char** argv)
{
    std::string const out = argv[1];
    std::uint32_t const now = 1790000000;
    Desk desk;

    Request badPriority = Issue();
    badPriority.Priority = PriorityCount;
    Request badCategory = Issue();
    badCategory.Category = CategoryCount;
    Check(desk.Create(Player(), badPriority, now).Result == CreateInvalid, "an unknown priority is refused");
    Check(desk.Create(Player(), badCategory, now).Result == CreateInvalid, "an unknown category is refused");
    Check(desk.Create(Player(), Issue("   "), now).Result == CreateInvalid, "a blank title is refused");
    Check(desk.Create(Player(), Issue("Two\nlines"), now).Result == CreateInvalid, "a title with a newline is refused");
    Check(desk.Create(Player(), Issue(std::string(MaxTitleLetters + 1, 'a')), now).Result == CreateInvalid,
          "a title past the client's 128 letters is refused");
    Check(desk.Create(Player(), Issue("Title", "\xff\xfe"), now).Result == CreateInvalid,
          "a description that is not UTF-8 is refused");
    Check(desk.Create(Player(), Issue("Title", "bell\a"), now).Result == CreateInvalid,
          "a description with a control character is refused");
    std::string letters;
    for (std::size_t index = 0; index < MaxTitleLetters; ++index)
        letters += "\xc3\xa9";
    Outcome created = desk.Create(Player(), Issue(letters, "Line one\nLine two"), now);
    Check(created.Result == CreateOk && created.Changed && created.Changed->Id == 1 &&
              created.Changed->Title == letters,
          "a 128-letter multibyte title and a multi-line description open ticket 1");
    Check(created.Sent && created.Sent->Id == 1 && created.Sent->Text == "Line one\nLine two" &&
              !created.Sent->FromGameMaster,
          "the description is the ticket's first player message");
    Check(desk.Create(Player(), Issue(), now).Result == CreateAlreadyOpen, "an account holds one current ticket");
    Check(desk.Create(Player(8), Issue(), now).Result == CreateOk && desk.Current(8)->Id == 2,
          "another account opens its own ticket");

    Check(desk.PlayerSend(Player(), std::string("2"), "Hello", false, now + 1).Result == SendNoTicket,
          "a message naming another ticket is refused");
    Check(desk.PlayerSend(Player(), std::nullopt, "Hello", true, now + 1).Result == SendInvalid,
          "a player cannot write a GM-only note");
    Outcome sent = desk.PlayerSend(Player(), std::string("1"), "Any news?", false, now + 10);
    Check(sent.Result == SendOk && sent.Sent->Id == 2 && desk.Find(1)->State == Status::WaitingForGameMaster,
          "a player message waits for a GM");
    Check(desk.Reply(1, "Gamemaster", "Internal: check spawn", true, now + 20) &&
              desk.Find(1)->State == Status::WaitingForGameMaster,
          "a GM note does not change who the ticket waits for");
    Check(desk.Reply(1, "Gamemaster", "Fixed, please retry.", false, now + 30) &&
              desk.Find(1)->State == Status::WaitingForPlayer,
          "a GM reply waits for the player");
    Check(PlayerMessages(*desk.Find(1)).size() == 3, "the player sees three messages, never the GM note");
    Dump(out + "unseen", *desk.Find(1), "Tester");

    Check(desk.PlayerMarkSeen(Player(), std::nullopt, 4, now + 40).Result == MarkUnknownMessage,
          "marking a message past the player's list is refused");
    Check(desk.PlayerMarkSeen(Player(), std::nullopt, 0, now + 40).Result == MarkUnknownMessage,
          "message ids start at 1");
    Check(!desk.PlayerMarkSeen(Player(), std::nullopt, 1, now + 40).Changed,
          "marking the player's own message changes nothing");
    Outcome seen = desk.PlayerMarkSeen(Player(), std::nullopt, 3, now + 40);
    Check(seen.Result == MarkOk && seen.Changed && desk.Find(1)->Messages[3].ReadTime == now + 40 &&
              desk.Find(1)->Messages[3].ReadBy == "Tester",
          "the third visible message is the GM reply and is marked read");
    Check(!desk.PlayerMarkSeen(Player(), std::nullopt, 3, now + 50).Changed, "a second mark changes nothing");
    Dump(out + "seen", *desk.Find(1), "Alt");

    Check(desk.Assign(1, "Gamemaster") && desk.Close(1, now + 60) && !desk.Close(1, now + 61),
          "a GM assigns and closes the ticket once");
    Check(desk.PlayerSend(Player(), std::nullopt, "Still broken", false, now + 70).Result == SendClosed,
          "a closed ticket takes no player message");
    Check(!desk.Reply(1, "Gamemaster", "Reply", false, now + 70) && desk.Reply(1, "Gamemaster", "Note", true, now + 70),
          "a closed ticket takes GM notes but no replies");
    Dump(out + "closed", *desk.Find(1), "Tester");
    Check(desk.PlayerReopen(Player(), std::nullopt).Result == ReopenOk && desk.Find(1)->State == Status::Open &&
              !desk.Find(1)->Closed,
          "the player reopens a closed ticket");
    Check(desk.PlayerReopen(Player(), std::nullopt).Result == ReopenNotClosed, "an open ticket cannot be reopened");

    Outcome resolved = desk.PlayerClose(Player(), std::string("1"), now + 80);
    Check(resolved.Result == CloseOk && resolved.Changed->ClosedByCreator && resolved.Changed->Closed == now + 80,
          "the player closes the ticket");
    Dump(out + "resolved", *resolved.Changed, "Tester");
    Check(!desk.Current(7), "a ticket closed by its creator is no longer current");
    Check(desk.PlayerClose(Player(), std::nullopt, now + 81).Result == CloseNoTicket &&
              desk.PlayerReopen(Player(), std::nullopt).Result == ReopenNoTicket &&
              desk.PlayerMarkSeen(Player(), std::nullopt, 1, now + 81).Result == MarkNoTicket,
          "without a current ticket close, reopen and mark are refused");
    desk.Forget(1);
    Check(desk.Create(Player(), Issue(), now + 90).Changed->Id == 3, "a new ticket takes the next id");

    Ticket const stored = *desk.Current(7);
    std::size_t accepted = 0;
    std::string_view refused;
    while ((refused = desk.PlayerSend(Player(), std::nullopt, "More", false, now + 100).Result) == SendOk)
        ++accepted;
    Check(accepted == MaxMessages - 1 && refused == SendLimit && desk.Current(7)->Messages.size() == MaxMessages,
          "a ticket holds at most 200 messages");

    Desk loaded;
    Ticket reloaded = stored;
    reloaded.Id = 17;
    loaded.Load(reloaded);
    loaded.ReserveIds(20);
    Check(loaded.Current(7) && loaded.Current(7)->Id == 17 && loaded.Create(Player(9), Issue(), now).Changed->Id == 21,
          "loaded tickets are current again and new ids follow the highest stored id");

    return failures ? 1 : 0;
}
"""


class Reader:
    def __init__(self, data):
        self.data = data
        self.offset = 0

    def take(self, fmt):
        value = struct.unpack_from(fmt, self.data, self.offset)[0]
        self.offset += struct.calcsize(fmt)
        return value

    def string(self):
        end = self.data.index(b'\0', self.offset)
        value = self.data[self.offset:end].decode('utf-8')
        self.offset = end + 1
        return value

    def optional(self, read):
        return read() if self.take('<B') else None

    def many(self, read):
        return [read() for _ in range(self.take('<I'))]


def read_message(reader):
    message = {'ticket': reader.string(), 'id': reader.take('<I'), 'from_gm': reader.take('<B'),
               'sender': reader.string(), 'text': reader.optional(reader.string), 'gm_only': reader.take('<B'),
               'time': reader.take('<I')}
    message['receipts'] = reader.many(lambda: (reader.string(), reader.take('<I'), reader.string(),
                                               reader.take('<I')))
    return message


def read_ticket(data):
    reader = Reader(data)
    ticket = {'id': reader.string(), 'title': reader.string(), 'created': reader.take('<I'),
              'last_message': reader.optional(lambda: reader.take('<I')), 'creator': reader.string(),
              'status': reader.take('<B'), 'suggestion': reader.optional(reader.string),
              'commands': reader.many(lambda: (reader.string(), reader.string())),
              'sql': reader.many(lambda: (reader.string(), reader.string())),
              'bug_reports': reader.many(lambda: (reader.take('<I'), reader.string())),
              'summary': reader.optional(reader.string), 'messages': reader.many(lambda: read_message(reader)),
              'assigned': reader.many(reader.string), 'last_unseen': reader.take('<B'),
              'any_unseen': reader.take('<B'), 'last_from_gm': reader.take('<B'), 'priority': reader.take('<B'),
              'category': reader.take('<B'), 'closed_by_creator': reader.take('<B'),
              'closed': reader.optional(lambda: reader.take('<I')), 'locale': reader.string(),
              'online': reader.optional(reader.string)}
    assert reader.offset == len(data)
    return ticket


def check_records(out):
    now = 1790000000
    unseen = read_ticket((out / 'unseen').read_bytes())
    assert unseen['id'] == '1' and unseen['title'] == 'é' * 128 and unseen['created'] == now
    assert unseen['creator'] == 'Tester' and unseen['status'] == 3 and unseen['last_message'] == now + 30
    assert (unseen['suggestion'], unseen['commands'], unseen['sql'], unseen['bug_reports'], unseen['summary']) == \
        (None, [], [], [], None)
    assert [message['id'] for message in unseen['messages']] == [1, 2, 3]
    assert [message['text'] for message in unseen['messages']] == \
        ['Line one\nLine two', 'Any news?', 'Fixed, please retry.']
    assert [(message['from_gm'], message['gm_only']) for message in unseen['messages']] == [(0, 0), (0, 0), (1, 0)]
    assert all(message['ticket'] == '1' for message in unseen['messages'])
    assert unseen['messages'][0]['receipts'] == [('1', 1, 'Tester', now)]
    assert unseen['messages'][2]['receipts'] == []
    assert (unseen['last_unseen'], unseen['any_unseen'], unseen['last_from_gm']) == (1, 1, 1)
    assert (unseen['priority'], unseen['category'], unseen['closed_by_creator'], unseen['closed']) == (1, 8, 0, None)
    assert (unseen['assigned'], unseen['locale'], unseen['online']) == ([], 'enUS', 'Tester')

    seen = read_ticket((out / 'seen').read_bytes())
    assert seen['messages'][2]['receipts'] == [('1', 3, 'Alt', now + 40)]
    assert seen['messages'][1]['receipts'] == [('1', 2, 'Alt', now + 10)]
    assert (seen['last_unseen'], seen['any_unseen'], seen['online']) == (0, 0, 'Alt')

    closed = read_ticket((out / 'closed').read_bytes())
    assert (closed['status'], closed['closed'], closed['assigned']) == (2, now + 60, ['Gamemaster'])
    assert len(closed['messages']) == 3

    resolved = read_ticket((out / 'resolved').read_bytes())
    assert (resolved['status'], resolved['closed_by_creator'], resolved['closed']) == (2, 1, now + 80)
    print('PASS: every record decodes with the DLL field order: GM notes stay hidden, player ids run 1..n, '
          'read receipts follow the viewer, and status, assignment and close fields follow the ticket')


def main():
    argparse.ArgumentParser(description=CLI_DESCRIPTION).parse_args()
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    buffer_source = (ROOT / 'src/server/shared/Packets/ByteBuffer.cpp').read_text()
    support = '\n'.join(method(buffer_source, signature) for signature in (
        'void ByteBuffer::append(uint8 const* src, std::size_t cnt)',
        'ByteBufferPositionException::ByteBufferPositionException(',
    ))
    with tempfile.TemporaryDirectory(prefix='coa-player-ticket-') as directory:
        out = Path(directory)
        (out / 'main.cpp').write_text('#include "ByteBuffer.h"\n#include <cassert>\n#include <sstream>\n'
                                      '#define ASSERT(condition, ...) assert(condition)\n' + support + MAIN)
        include_dirs = [ROOT / 'src/server/coa', ROOT / 'src/common', ROOT / 'src/common/Utilities',
                        ROOT / 'src/server/shared/Packets', ROOT / 'deps/utf8cpp']
        command = [compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror']
        command += [flag for path in include_dirs for flag in ('-I', str(path))]
        command += [str(out / 'main.cpp'), '-o', str(out / 'test')]
        subprocess.run(command, check=True)
        result = subprocess.run([str(out / 'test'), str(out) + '/'], capture_output=True, text=True)
        print(result.stdout, end='')
        if result.returncode:
            raise SystemExit(result.returncode)
        check_records(out)


if __name__ == '__main__':
    main()
