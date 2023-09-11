# TF2-Wearables

## Overview 

This plugin allows players on the server to give themselves Team Fortress 2 wearable affects & cosmetics through the use abusing the attribute system. I originally made this plugin for my own private community to provide players with more incentive to play on the servers I provided. All the customizations are done mainly through a menu accessible with **!wearables**, I had gotten this idea from a plugin with a similar name which intended to have the same functionality but I felt personally it had missed the mark.

## Features

- Killstreaks Effects: Allow the player to choose the level of killstreak applied to a specific weapon slot in their inventory, and is not bound to the weapon the player has chosen.
- Unusual Taunts: Allows the player to choose a unusual effect for taunting in-game. (Also known as emoting)

## Commands

!wearables - Display the wearables menu to the player.

## Preview Images

![20230522123527_1](https://github.com/cigzag/TF2-Wearables/assets/23132897/5acf03a5-4316-41e9-861e-f6966fd583de)

![20230522123541_1](https://github.com/cigzag/TF2-Wearables/assets/23132897/d4d270eb-8bbc-4d5d-8ca9-5d4bc0414a79)

## Dependencies

- MoreColors (For compiling) - https://forums.alliedmods.net/showthread.php?t=185016
- TF2Items - https://forums.alliedmods.net/showthread.php?s=9d06c121e0d39d2dd87bf0ef107c763d&t=115100
- TF2Attributes - https://github.com/FlaminSarge/tf2attributes

## Installation

Simply place the compiled smx into your Sourcemod plugins folder, this plugin does not require external gamedata or anything of the sort.
(sourcemod/plugins/*)

## TODO

- Add MySQL / SQLite support.
- Add refire timers for unusual taunts which have an expiry time.
- Add other wearable options (Weapon unusuals, festive, australiums, etc) // NOTE: Require creating weapon entities and parenting old attributes to display correctly, currently out of scope for project.

## Credits

- asherkin - For the creation of TF2Items
- FlaminSarge - For the creation of TF2Attributes