fx_version 'cerulean'
game 'gta5'

author 'Nass#1411'
description 'Nass Tebex system'
version '1.3.2'

shared_script 'config.lua'

client_script 'client.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
