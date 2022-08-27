# nass_tebexstore
This resource was created for servers to connect their Tebex stores to their FiveM Servers

## Features:
- Store Automation
- Ability to add Items, Cars, and Weapons
- Logs to discord
- Easily configurable 


## Installation

- Download 
- Put script in your `resources` directory


- Import `codes.sql` to your database.
- Add `ensure nass_tebexstore` in your `server.cfg`

 - In Tebex, go to the package you would like to add
 - Add a game server command to your server of choice
 - Set the command `When the package is purchased`
 - Add `purchase_package_tebex {"transid":"{transaction}", "packagename":"{packageName}"}` as the command
 - Press the settings icon on the right and change the command to `Execute the command even if the player is offline`
 - Press Update

 - Depending on which garage system is being used, you may have to make your own modifications in the script's vehicle assignment code. server.lua, line 229 or 240 depending on the framework, in the `nass_tebexstore:setVehicle` event.

## Usage

- Players must go ingame and do `/redeem [Transaction ID]` and they will recieve everything


## Extra Information


 Please leave any issues you may have here on github

# Support
Join our discord <a href='https://discord.gg/XJFNyMy3Bv'>HERE</a> for additional scripts and support!
