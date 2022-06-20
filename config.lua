Config = {}
Config.Framework = "ESX" -- "ESX" or "QB"
Config.DiscordLogs = true -- Set webhook in server.lua Line 1
Config.SpaceInLicensePlate = false -- Set to true if you want a space in license plate for vehicle reward
Config.LicensePlateLetters = 3 -- Amount of letters in plate for vehicle reward
Config.LicensePlateNumbers = 3 -- Amount of numbers in plate for vehicle reward
Config.Packages = {
	{
		PackageName = "Money Package", -- Exact package name from tebex
		Items = {
			{
				name = "money", -- Item or account name depending on type specified below
				amount = 2000000, -- Amount of item or money
				type = "account" -- Four types: account, item, or weapon and car
			},
		},
	},
	{
		PackageName = "Item Package", -- Exact package name from tebex
		Items = {
			{
				name = "bandage", -- Item or account name depending on type specified below
				amount = 1, -- Amount of item or money
				type = "item" -- Four types: account, item, or weapon and car
			},
		},
	},
	{
		PackageName = "Weapons Package", -- Exact package name from tebex
		Items = {
			{
				name = "weapon_pistol", -- Item or account name depending on type specified below
				amount = 51, -- Amount of item or money
				type = "weapon" -- Four types: account, item, or weapon and car
			},
			{
				name = "weapon_assaultrifle_mk2", -- Item or account name depending on type specified below
				amount = 551, -- Amount of item or money
				type = "weapon" -- Four types: account, item, or weapon and car
			},
		},
	},
	{
		PackageName = "Vehicles Package", -- Exact package name from tebex
		Items = {
			{
				model = "zentorno", -- Item or account name depending on type specified below
				type = "car" -- Four types: account, item, or weapon and car
			},
		},
	},
}