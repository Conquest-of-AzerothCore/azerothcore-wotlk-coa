-- Preserved Ascension creature cache: Goldilocks 80539 / display 89251;
-- Trade Prince Gallywix 80540 / display 75730. Spawn either with .npc add.
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`,
 `HealthModifier`, `ManaModifier`, `ScriptName`)
VALUES
(80539, 'Goldilocks', 'Gallywix''s Lottery', 60, 60, 35, 1, 1, 7, 1.25, 1, 'npc_coa_lottery'),
(80540, 'Trade Prince Gallywix', 'Leader of the Bilgewater Cartel', 60, 60, 35, 1, 1, 7, 1.25, 1, 'npc_coa_lottery')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`),
`npcflag` = `npcflag` | 1, `ScriptName` = VALUES(`ScriptName`);

INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `type`, `AIName`)
VALUES (80541, 'Goldilocks', 1, 1, 35, 0, 1, 8, 'CritterAI')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`),
`npcflag` = VALUES(`npcflag`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`), `ScriptName` = '';

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (80539, 80540, 80541);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(80539, 0, 89251, 1, 1, 12340),
(80540, 0, 75730, 1, 1, 12340),
(80541, 0, 89251, 0.33, 1, 12340);

-- The base LotteryUI requires a valid bonus item even when no bonus is awarded.
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `description`)
VALUES (9000805, 15, 0, 'No bonus reward', 7798, 1, 'This lottery awards gold only.')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `displayid` = VALUES(`displayid`),
`description` = VALUES(`description`);

-- Restore the preserved companion item rather than its generic appearance placeholder.
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `ItemLevel`, `bonding`,
 `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellid_2`, `spelltrigger_2`, `description`, `BagFamily`)
VALUES
(97393, 15, 2, 'Sigil of Goldilocks', 139944, 6, 64, 60, 3,
55884, 0, -1, 92453, 6,
'This cosmetic item is added to your vanity collection and is usable on all of your characters.  This is a non-combat companion.', 4224)
ON DUPLICATE KEY UPDATE `class` = VALUES(`class`), `subclass` = VALUES(`subclass`), `name` = VALUES(`name`),
`displayid` = VALUES(`displayid`), `Quality` = VALUES(`Quality`), `Flags` = VALUES(`Flags`),
`ItemLevel` = VALUES(`ItemLevel`), `bonding` = VALUES(`bonding`),
`spellid_1` = VALUES(`spellid_1`), `spelltrigger_1` = VALUES(`spelltrigger_1`),
`spellcharges_1` = VALUES(`spellcharges_1`), `spellid_2` = VALUES(`spellid_2`),
`spelltrigger_2` = VALUES(`spelltrigger_2`), `description` = VALUES(`description`), `BagFamily` = VALUES(`BagFamily`);

INSERT IGNORE INTO `creature_template_movement` (`CreatureId`, `Ground`, `Flight`)
VALUES (80541, 1, 0);

UPDATE `creature_template_movement`
SET `Ground` = 1, `Flight` = 0
WHERE `CreatureId` = 80541;

DELETE FROM `command` WHERE `name` IN (
  'lottery', 'lottery refund', 'lottery info', 'lottery enable', 'lottery disable',
  'lottery start', 'lottery stop', 'lottery restart', 'lottery draw', 'lottery help'
);

INSERT INTO `command` (`name`, `security`, `help`) VALUES
('lottery', 2, 'Syntax: .lottery <refund|info|enable|disable|start|stop|restart|draw|advertise|help>. GM lottery management;
  also available in the server console.'),
('lottery refund', 2, 'Syntax: .lottery refund *|<character name>. Mail the full actual amount paid for current
  tickets, remove those tickets and their pot contribution, and keep the round going. House tickets are unchanged.
  Deleted recipients are skipped.'),
('lottery info', 2, 'Syntax: .lottery info [character name]. Without a name: duration, remaining time, pause state,
  house tickets, pot, bonus item and top 10 ticket holders by count. With a name: current ticket count. Output goes
  to the invoking GM or server console.'),
('lottery enable', 2, 'Syntax: .lottery enable. Resume a paused countdown and restore the managed NPCs and
  advertisements; if stopped, start a configured round. This state persists across restarts.'),
('lottery disable', 2, 'Syntax: .lottery disable. Pause the current countdown, hide the managed NPCs and stop
  advertisements. Tickets and pot remain. This state persists across restarts.'),
('lottery start', 2, 'Syntax: .lottery start [duration] [fakeTickets] [bonusItemId]. Only starts when no round
  exists, including paused rounds. Duration: seconds or Ns/Nm/Nh/Nd/Nw, 60s to 365d. Omitted values use config;
  omitted bonus randomly selects the configured prize pool; 0 means no item. Enables the new round.'),
('lottery stop', 2, 'Syntax: .lottery stop. Atomically refund all current paid tickets by mail, cancel the current
  round and disable the lottery. It stays stopped across server restarts; no winner is recorded. House/seed gold is
  discarded.'),
('lottery restart', 2, 'Syntax: .lottery restart. Atomically refund/cancel the current round and start a new
  enabled round with configured terms and a new random configured prize. House/seed gold is discarded.'),
('lottery draw', 2, 'Syntax: .lottery draw [character name]. Immediately draw a running or paused round and start a
  fresh enabled configured round. An optional named character wins; if not entered, one complimentary ticket adds
  10g to the payout and is recorded in winner history. Cannot exceed the pot/ticket cap. An empty round without
  house tickets requires a named winner.'),
('lottery help', 2, 'Syntax: .lottery help. Print usage for all lottery GM commands. They require GM security level 2 or higher, or the server console.');

DELETE FROM `command` WHERE `name` = 'lottery advertise';

INSERT INTO `command` (`name`, `security`, `help`) VALUES ('lottery advertise', 2, 'Syntax: .lottery advertise.
  Make Gallywix yell a random lottery advertisement across the zone immediately, using the current pot,
  time remaining and nearby players. The lottery must be running and Gallywix spawning enabled.
  Works even if automatic advertisements are disabled. Does not reset their timer.');
