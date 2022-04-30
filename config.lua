Config = {}
Config.DiscordLogs = true --Set webhook in server.lua Line 1
Config.Packages = {
    {
        PackageName = "test", --Exact package name from tebex
        Items = {
            {
                name = "money", --Item or account name depending on type specified below
                amount = 2000000, -- Amount of item or money
                type = 'account' --Three types: account, item, or weapon(If using items for weapons, use item for type) and car
            },
            {
                model = "zentorno", --Item or account name depending on type specified below
                type = 'car' --Three types: account, item, or weapon(If using items for weapons, use item for type) and car
            },
        },
    },	
    {
        PackageName = "test2", --Exact package name from tebex
        Items = {
            {
                name = "sandwich", --Item or account name depending on type specified below
                amount = 5, -- Amount of item or money
                type = 'item' --Three types: account, item, or weapon(If using items for weapons, use item for type) and car
            },
        },
    },	
    {
        PackageName = "test3", --Exact package name from tebex
        Items = {
            {
                name = "weapon_pistol", --Item or account name depending on type specified below
                amount = 51, -- Amount of item or money
                type = 'weapon' --Three types: account, item, or weapon(If using items for weapons, use item for type) and car
            },
        },
    },
}



