fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

authors {
	'Nass#1411',
	'!zRxnx#0001'
}
description 'Nass Tebex system - FORK'
version '1.4.0'

shared_scripts {
	'configuration/config.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'configuration/serverconfig.lua',
	'server/*.lua'
}