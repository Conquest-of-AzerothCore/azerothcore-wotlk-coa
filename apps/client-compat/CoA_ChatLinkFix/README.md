# CoA_ChatLinkFix

A shift-clicked item link cannot be used in a dot command on this client. Two things go wrong,
and both are in the link the client builds, not in the command:

1. **The link ends in `|r|r`.** The second colour terminator closes nothing, and the client
   refuses the whole message with *"Invalid escape code in chat message"*, so the command never
   leaves the edit box. AtlasLoot's `ChatEdit_InsertLink` path is the one that produces it, but
   any addon appending its own terminator hits the same wall.

2. **The link is the short form.** `|Hitem:50363|h[Name]|h|r` carries none of the trailing item
   fields, and the server's hyperlink parser requires the full set, so a link that does reach the
   server is answered with *"Provided link has invalid link data"*.

Commands take a bare item id just as happily. The addon collapses runs of terminators in every
message, and in a message that starts with `.` it reduces each item link to its id. Ordinary chat
keeps its links.

## Installing

Copy the `CoA_ChatLinkFix` folder into `Interface/AddOns` and restart the client. There is no
configuration and nothing to enable.
