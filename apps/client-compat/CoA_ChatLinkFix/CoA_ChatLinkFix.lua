-- Shift-clicking an item in AtlasLoot produces two problems for a dot command.
--
-- First the link ends in "|r|r"; the second terminator closes nothing and the
-- client refuses the whole message with "Invalid escape code in chat message",
-- so the .additem never leaves the edit box.
--
-- Then the link itself is the short form, "|Hitem:50363|h[Name]|h|r" with none
-- of the trailing item fields. The server's hyperlink parser requires the full
-- set and answers "Provided link has invalid link data".
--
-- Commands take a bare item id just as happily, so collapse the terminators for
-- every message and reduce any item link in a dot command to its number.
-- Ordinary chat keeps its links.
local nativeSendChatMessage = SendChatMessage
if nativeSendChatMessage then
    SendChatMessage = function(message, ...)
        if type(message) == "string" then
            while message:find("|r|r", 1, true) do
                message = message:gsub("|r|r", "|r")
            end

            if message:sub(1, 1) == "." then
                message = message:gsub("|c%x+|Hitem:(%d+)[^|]*|h%[.-%]|h|r", "%1")
                message = message:gsub("|Hitem:(%d+)[^|]*|h%[.-%]|h", "%1")
            end
        end
        return nativeSendChatMessage(message, ...)
    end
end
