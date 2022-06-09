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

## Usage

- Players must go ingame and do `/redeem [Transaction ID]` and they will recieve everything


## Extra Information
 Current Version is only able to support 1 package purchase at a time. Looking into ways to fix this in the future.
 
 Please leave any issues you may have here on github

# Support
Join our discord <a href='https://discord.gg/XJFNyMy3Bv'>HERE</a> for additional scripts and support!
