# TF2-Wearables

## Overview 

This plugin allows players on the server to give themselves Team Fortress 2 wearable affects & cosmetics through the use abusing the attribute system. I originally made this plugin for my own private community to provide players with more incentive to play on the servers I provided. All the customizations are done mainly through a menu accessible with **!wearables**, I had gotten this idea from a plugin with a similar name which intended to have the same functionality but I felt personally it had missed the mark.

## Features

- Killstreaks Effects: Allow the player to choose the level of killstreak applied to a specific weapon slot in their inventory, and is not bound to the weapon the player has chosen.
- Unusual Taunts: Allows the player to choose a unusual effect for taunting in-game. (Also known as emoting)
- Unusual Hat Effects: Allows the player to choose a unusual hat effect. (If they are wearing a hat in-game)
- Unusual Weapon Effects: Allows the player to attach a unusual weapon effect to the desired slot. (Updates OnResupply, needs to moved to OnGiveNamedItem)
- MySQL support (Saves players preferences if they disconnect!)

## Commands

!wearables - Display the wearables menu to the player.

# ConVars

`tf_wearables_enabled: 1/0 (default: 1)` - Enable TF2 wearables plugin?\
`tf_wearables_db: (default: wearables)` - Name of database as inputted in databases.cfg\
`tf_wearables_table: (default: wearables)` - Name of database table plugin will generate and read/write data from.

## Preview Images

![20230919233340_1](https://github.com/keybangz/TF2-Wearables/assets/23132897/4667de68-bf63-4e67-9aa8-569ecba30ce9)

![20230919234314_1](https://github.com/keybangz/TF2-Wearables/assets/23132897/5de812d1-dc7d-4ca5-a452-e913e3209178)

## Dependencies

- MoreColors (For compiling) - https://forums.alliedmods.net/showthread.php?t=185016
- TF2Items - https://forums.alliedmods.net/showthread.php?s=9d06c121e0d39d2dd87bf0ef107c763d&t=115100
- TF2Attributes - https://github.com/FlaminSarge/tf2attributes
- TF2Utils - https://github.com/nosoop/SM-TFUtils
- TF Econ Data - https://github.com/nosoop/SM-TFEconData
- stocksoup/textparse - https://github.com/nosoop/stocksoup

## Installation

- Place plugin inside `sourcemod/plugins` folder.
- Add `wearables` MySQL entry to your `databases.cfg` located inside `sourcemod/configs`

## TODO

- Add other wearable options (Festive, Australiums, etc)

## Credits

- asherkin - For the creation of TF2Items
- FlaminSarge - For the creation of TF2Attributes
