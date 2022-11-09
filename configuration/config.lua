Framework = nil

if GetResourceState('es_extended') == 'started' or GetResourceState('es_extended') == 'starting' then
	ESX = exports['es_extended']:getSharedObject()
    Framework = 'ESX'
elseif GetResourceState('qb-core') == 'started' or GetResourceState('qb-core') == 'starting' then
	QBCore = exports['qb-core']:GetCoreObject()
	Framework = 'QB'
else
	Config.Notification('nass_tebexstore: No framework could be initialised.')
end

Config = {}
Config.SpaceInLicensePlate = false --| Set to true if you want a space in license plate for vehicle reward
--[[ IMPORTANT ]]--
--[[ MAX PLATE LENGTH IS 8 CHARACTERS + SPACES!!! ]]--
Config.LicensePlateLetters = 4 --| Amount of letters in plate for vehicle reward
Config.LicensePlateNumbers = 4 --| Amount of numbers in plate for vehicle reward
Config.EnableEasyAdmin = false --| Enable EasyAdmin ban system if a user get flagged?
Config.Packages = {

	{
		PackageName = 'Money Package', --| Exact package name from tebex
		Items = {
			{
				name = 'money', --| Item or account name depending on type specified below
				amount = 2000000, --| Amount of item or money
				type = 'account' --| Four types: account, item, or weapon and car
			},
		},
	},

	{
		PackageName = 'Item Package', --| Exact package name from tebex
		Items = {
			{
				name = 'bandage', --| Item or account name depending on type specified below
				amount = 1, --| Amount of item or money
				type = 'item' --| Four types: account, item, or weapon and car
			},
		},
	},

	{
		PackageName = 'Weapons Package', --| Exact package name from tebex
		Items = {
			{
				name = 'weapon_pistol', --| Item or account name depending on type specified below
				amount = 51, --| Amount of item or money
				type = 'weapon' --| Four types: account, item, or weapon and car
			},
			{
				name = 'weapon_assaultrifle_mk2', --| Item or account name depending on type specified below
				amount = 551, --| Amount of item or money
				type = 'weapon' --| Four types: account, item, or weapon and car
			},
		},
	},

	{
		PackageName = 'Vehicles Package', --| Exact package name from tebex
		Items = {
			{
				model = 'zentorno', --| Item or account name depending on type specified below
				type = 'car' --| Four types: account, item, or weapon and car
			},
		},
	},
}

Config.Notification = function(message, type, time)
    message = message or 'No message input'
    time = time or 3000
	if IsDuplicityVersion() then
		if Framwork == 'ESX' then
			--[[ CHANGEABLE ]]--

			type = type or 'info'
			TriggerClientEvent('esx:showNotification', source, message, type, time)

		elseif Framework == 'QB' then
			--[[ CHANGEABLE ]]--

			type = type or 'primary'
			TriggerClientEvent('QBCore:Notify', source, message)

		end
	else
		if Framwork == 'ESX' then
			--[[ CHANGEABLE ]]--

			type = type or 'info'
			ESX.ShowNotification(message, type, time)

		elseif Framework == 'QB' then
			--[[ CHANGEABLE ]]--

			type = type or 'primary'
			QBCore.Functions.Notify(message, type, time)

		end
	end
end