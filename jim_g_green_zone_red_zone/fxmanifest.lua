fx_version 'cerulean'
game 'gta5'

author 'Jim-G'
description 'Zone Script with Greenzones and Redzones'
version '1.0.2'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'cl/client.lua'
}

server_scripts {
    'sv/server.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/ui.css',
    'html/ui.js'
}

dependencies {
    'community_bridge',
    'ox_lib'
}