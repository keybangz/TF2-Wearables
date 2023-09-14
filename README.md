# TF2-Wearables

## Overview 

This plugin allows players on the server to give themselves Team Fortress 2 wearable affects & cosmetics through the use abusing the attribute system. I originally made this plugin for my own private community to provide players with more incentive to play on the servers I provided. All the customizations are done mainly through a menu accessible with **!wearables**, I had gotten this idea from a plugin with a similar name which intended to have the same functionality but I felt personally it had missed the mark.

## Features

- Killstreaks Effects: Allow the player to choose the level of killstreak applied to a specific weapon slot in their inventory, and is not bound to the weapon the player has chosen.
- Unusual Taunts: Allows the player to choose a unusual effect for taunting in-game. (Also known as emoting)
- MySQL support (Saves players preferences if they disconnect!)

## Commands

!wearables - Display the wearables menu to the player.

# ConVars

`tf_wearables_enabled: 1/0 (default: 1)` - Enable TF2 wearables plugin?\
`tf_wearables_db: (default: wearables)` - Name of database as inputted in databases.cfg\
`tf_wearables_table: (default: wearables)` - Name of database table plugin will generate and read/write data from.

## Preview Images

![20230914193541_1](https://github.com/keybangz/TF2-Wearables/assets/23132897/739085ff-c348-44e7-b18f-70d8e2093a13)

![20230914193644_1](https://github.com/keybangz/TF2-Wearables/assets/23132897/a92c6b49-2a62-4085-a833-89339720cf8b)

## Dependencies

- MoreColors (For compiling) - https://forums.alliedmods.net/showthread.php?t=185016
- TF2Items - https://forums.alliedmods.net/showthread.php?s=9d06c121e0d39d2dd87bf0ef107c763d&t=115100
- TF2Attributes - https://github.com/FlaminSarge/tf2attributes

## Installation

- Place plugin inside `sourcemod/plugins` folder.
- Add `wearables` MySQL entry to your `databases.cfg` located inside `sourcemod/configs`

## TODO

- Add other wearable options (Weapon unusuals, festive, australiums, etc) // NOTE: Require creating weapon entities and parenting old attributes to display correctly, currently out of scope for project.

## Credits

- asherkin - For the creation of TF2Items
- FlaminSarge - For the creation of TF2Attributes
