UPDATE `command`
SET `help` = 'Syntax: .poll create <id> <type:1-4> <allowChange:0-or-1> <minLevel:10-255> "<title>" "<question>" ["<feedback prompt>"] ["<context>"]. Separate fields with spaces; use "" for empty feedback before a context.'
WHERE `name` = 'poll create';
