# TF2-Wearables

## Overview 

This plugin allows players on the server to give themselves Team Fortress 2 wearable affects & cosmetics through the use abusing the attribute system. I originally made this plugin for my own private community to provide players with more incentive to play on the servers I provided. All the customizations are done mainly through a menu accessible with **!wearables**, I had gotten this idea from a plugin with a similar name which intended to have the same functionality but I felt personally it had missed the mark.

## Features

- Killstreaks Effects: Allow the player to choose the level of killstreak applied to a specific weapon slot in their inventory, and is not bound to the weapon the player has chosen.
- Weapon Unusuals: Allows the player to give themselves a weapon unusual effect to a desired weapon slot.
- Unusual Taunts: Allows the player to choose a unusual effect for taunting in-game. (Also known as emoting)
- War Paints: (In progress) Allows the player to choose a specified warpaint for the weapon in the slot chosen.
- Dynamic saving: This plugin uses cookies to save the chosen affects on the player and reapplies them when they join the server, no SQL required!

## Commands

!wearables - Display the wearables menu to the player.
!warpaint - Test command used to a static warpaint to a desired weapon.

## Preview Images

To be added soon.

## Dependencies

- TF2Items - https://forums.alliedmods.net/showthread.php?s=9d06c121e0d39d2dd87bf0ef107c763d&t=115100
- TF2Attributes - https://github.com/FlaminSarge/tf2attributes
- TF Econ Data - https://github.com/nosoop/SM-TFEconData

## Installation

Simply place the compiled smx into your Sourcemod plugins folder, this plugin does not require external gamedata or anything of the sort.
(sourcemod/plugins/*)

## Compile Requirements

- MoreColors - https://forums.alliedmods.net/showthread.php?t=185016

## TODO

- Rewrite plugin and utilize TF Econ Data a lot more to provide easier ways to retrieve & utilize in-game attributes
- Add commands which allow players to apply wearable attributes without the use of the menu.
- Fix particle system overload. (Presumably because some particles are not temporary entities & instead stay in server memory until map change.)

## Credits

- 404 - Helping me with the list of weapons available to have warpaints applied.
- asherkin - For the creation of TF2Items
- FlaminSarge - For the creation of TF2Attributes
- nosoop - For the creation of TF Econ Data

Everyone else who may have helped me during the writing of this plugin, I do not remember every little detail! If you wish to be added to the list, feel free to open a PR.
