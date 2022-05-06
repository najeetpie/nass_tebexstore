
fx_version 'cerulean'
games { 'gta5' }

author 'Nass#1411'
description 'Nass Tebex system'
version '1.2.2'

client_script 'config.lua'
client_script 'client.lua'


server_scripts {
    "@mysql-async/lib/MySQL.lua",
    'config.lua',
    'server.lua'
}
