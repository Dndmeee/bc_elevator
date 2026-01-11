fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Dndmee'
description 'Elevator system for Blackcard Roleplay'
version '1.0.0'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'ui/build/index.html'

files {
    'ui/build/index.html',
    'ui/build/assets/**',
}
