resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"

description 'QB:Weapons'

ui_page 'html/index.html'


server_scripts {
    "server/main.lua",
}

client_scripts {
	"client/*.lua"
}

shared_scripts {
    "config.lua",
}

exports {
	'CanShoot',
} 

files {
    'html/index.html',
    'html/js/script.js',
    'html/css/style.css',
}
