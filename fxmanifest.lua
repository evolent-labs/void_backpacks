use_experimental_fxv2_oal 'yes'
lua54 'yes'

fx_version 'cerulean'
game 'gta5'

name 'void_backpacks'
author 'Void Development'
version '1.0'

dependencies {
    'ox_lib',
    'ox_inventory',
}

shared_script '@ox_lib/init.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

file 'config.lua'
