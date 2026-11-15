# AutoTarget

An optional client add-on, off by default. When you press a damaging ability with no living enemy
target, it targets an enemy first and then lets the ability fire, so you do not need to tab-target.
It works with the keyboard and mouse, and with a controller that presses action bar keys.

## What it does

On a key press that is bound to an action bar button holding a harmful action, the add-on picks a
target in this order and stops at the first that applies:

1. You already have a living hostile target: it is kept.
2. A living enemy is under the mouse (or under the crosshair): it is targeted.
3. The living enemy whose nameplate is nearest the middle of the screen, inside an aim circle
   (default radius 18% of the screen height; the vertical distance counts half).
4. Optionally (on by default) the game's own nearest enemy, when nobody is inside the aim circle.

The real ability then fires as usual, so cooldowns, range colours and paging keep working.
Only harmful actions are touched. Heals, buffs, mounts, potions that are not harmful and macros
are pressed exactly as before. A spell that both heals and harms (for example Holy Shock) keeps a
living friendly target.

It works with the default action bars and with ElvUI 7.27's bars: the add-on puts its own hidden
secure button in front of the key and clicks the real bar button, so nothing of the bars is changed
or written to. Each key press clicks the real button once.

## Install

1. Close the game. Copy this entire `AutoTarget` directory into the client's `Interface/AddOns`
   directory.
2. Start the client and enable **AutoTarget** in the character-selection AddOns list.
3. Turn it on: Esc > Interface > AddOns > AutoTarget, or `/autotarget on`.

To remove it, close the game and delete `Interface/AddOns/AutoTarget`. The saved settings are in
`WTF/Account/<account>/SavedVariables/AutoTargetDB.lua`.

## Options

Esc > Interface > AddOns > AutoTarget:

- **Target automatically when I press an ability** (default off).
- **Also start auto attack**: auto attack starts when an attack picks or keeps an enemy (default off).
- **Aim at the enemy in the middle of the screen** (default on once the add-on is on): step 3.
- **Aim circle size**: 5% to 40% of the screen height.
- **Nearest enemy if nobody is in my aim** (default on): step 4. Off: nothing is targeted and the
  ability says you have no target.
- **Show enemy nameplates**: a button that turns enemy nameplates on when they are off.

## Commands

- `/autotarget on | off`
- `/autotarget attack on | off`
- `/autotarget aim on | off | size N | nearest on | off | plates`
- `/autotarget aim who [label]`: prints which enemy would be picked now and why (plates seen, dead,
  friendly, off screen, outside the circle). Safe to use out of combat.
- `/autotarget check`: lists the keys taken over and what each one does.
- `/autotarget clicks auto | down | up | split | single`: how the real button is clicked; `auto` (default)
  matches the button's own key-down or key-up setting.
- `/autotarget options`

## Limits

- Step 3 needs enemy nameplates to be shown. With enemy nameplates off, it finds nobody and step 4
  (or nothing) applies.
- Nameplates show through walls and at range. The pick can be an enemy you cannot hit yet; the game
  then reports out of range or not in line of sight.
- Mouse clicks on bar buttons are not covered; only keys (and a controller pressing those keys).
- A client without nameplate unit tokens (`nameplate1`, `nameplate2`, ...) cannot do step 3: the
  option is greyed out and the add-on uses steps 1, 2 and 4 only.
- Changes made during combat apply when combat ends.

## Tests

`client/test_autotarget.py` runs the rule and the chooser (middle beats nearer-at-the-side; dead and
friendly plates skipped; nobody in the circle) in Lua 5.1 through `lupa`, like the other tests under
`client/`. See `client/requirements-test.txt`.

## License

Part of this repository and licensed under the same terms: GNU General Public License v2 (see the
`LICENSE` file at the repository root).
