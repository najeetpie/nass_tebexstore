local DiscordWebhook = 'CHANGE_WEBHOOK'
local redeemedCars = {}
local inProgress = false
local ESX = nil
local QBCore = nil
local NumberCharset = {}
local Charset = {}
local plateQuery = ''

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

local function GetRandomNumber(length)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

local function GetRandomLetter(length)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

local function GeneratePlate()
	local plate = Config.SpaceInLicensePlate and GetRandomLetter(Config.LicensePlateLetters)..' '..GetRandomNumber(Config.LicensePlateNumbers) or GetRandomLetter(Config.LicensePlateLetters) .. GetRandomNumber(Config.LicensePlateNumbers)
	local result = MySQL.scalar.await(plateQuery, {plate})
	return result and GeneratePlate() or plate:upper()
end

local DISCORD_NAME = "nass_tebexstore"
local DISCORD_IMAGE = "https://i.imgur.com/Q72RWcB.png"

local function SendToDiscord(name, message, color)
	if not Config.DiscordLogs then return end
	if DiscordWebhook == "CHANGE_WEBHOOK" then
		print(message)
	else
		local connect = {
			{
				["color"] = color,
				["title"] = "**".. name .."**",
				["description"] = message,
				["footer"] = {
					["text"] = "Nass Tebexstore",
				},
			}
		}
		PerformHttpRequest(DiscordWebhook, function() end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatarrl = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
	end
end

if Config.Framework == "ESX" then
	ESX = exports.es_extended:getSharedObject()

	plateQuery = 'SELECT 1 FROM owned_vehicles WHERE plate = ?'

	ESX.RegisterServerCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local xPlayer = ESX.GetPlayerFromId(source)
		if redeemedCars[xPlayer.identifier] ~= nil then
			local redeemed = redeemedCars[xPlayer.identifier] == model
			cb(redeemed, redeemed and GeneratePlate() or nil)
		else
			cb(false)
			print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: '..xPlayer.identifier)
			SendToDiscord('Attempted Exploit Detected!', '**Identifier: **'..xPlayer.identifier..'\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
			xPlayer.kick('Nice try')
		end
	end)
elseif Config.Framework == "QB" then
	QBCore = exports['qb-core']:GetCoreObject()

	plateQuery = 'SELECT 1 FROM player_vehicles WHERE plate = ?'

	QBCore.Functions.CreateCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local player = QBCore.Functions.GetPlayer(source)
		if not player then return end
		if redeemedCars[player.PlayerData.citizenid] ~= nil then
			local redeemed = redeemedCars[player.PlayerData.citizenid] == model
			cb(redeemed, redeemed and GeneratePlate() or nil)
		else
			cb(false)
			print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: '..player.PlayerData.citizenid)
			SendToDiscord('Attempted Exploit Detected!', '**Identifier: **'..player.PlayerData.citizenid..'\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
			QBCore.Functions.Kick(source, 'Nice try')
		end
	end)
else
	TriggerEvent("nass_tebexstore:notify", "nass_tebexstore: Framework in config is not set correctly. ")
end

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		local tebexConvar = GetConvar('sv_tebexSecret', '')
		if tebexConvar == '' then
			error('Tebex Secret Missing please set in server.cfg and try again. The script will not work without it.')
			StopResource(GetCurrentResourceName())
		end
		if not Config.DiscordLogs then
			print('^3Webhooks Disabled^0') -- ^3 is the yellow color code for the console, ^0 is white to reset the color for everything after this message
		end
	end
end)

RegisterCommand('redeem', function(source, _, rawCommand)
	if Config.Framework == "ESX" then
		local encode = rawCommand:sub(8)
		local xPlayer = ESX.GetPlayerFromId(source)
		local xName = xPlayer.getName()
		MySQL.query('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
			if result[1] then
				local packs = json.decode(result[1].packagename)
				for _, i in pairs (packs) do
					local packagename = i
					local showMsg = true
					for _, v in pairs (Config.Packages) do
						if v.PackageName == i then
							for j = 1, #v.Items, 1 do
								local counter = v.Items[j]
								if counter.type == 'item' then
									xPlayer.addInventoryItem(counter.name, counter.amount)
								elseif counter.type == 'weapon' then
									xPlayer.addWeapon(counter.name, counter.amount)
								elseif counter.type == 'account' then
									xPlayer.addAccountMoney(counter.name, counter.amount)
								elseif counter.type == 'car' then
									redeemedCars[xPlayer.identifier] = counter.model
									TriggerClientEvent('nass_tebexstore:spawnveh', source, counter.model)
								end

								Wait(100)
							end

							TriggerClientEvent('nass_tebexstore:notify', source, "You have successfully redeemed a code for: " .. encode)
							SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **'..xName..'\n**Identifier: **'..xPlayer.identifier, 3066993)
							showMsg = false
						end
					end
					if showMsg then
						TriggerClientEvent('nass_tebexstore:notify', source, "The "..packagename.." package is not configured by the server owner. Please contact the admin team.")
					end
				end
				MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode})
			else
				TriggerClientEvent('nass_tebexstore:notify', source, "Code is currently invalid, if you have just purchased please try this code again in a few minutes")
			end
		end)
	elseif Config.Framework == "QB" then
		local encode = rawCommand:sub(8)
		local player = QBCore.Functions.GetPlayer(source)
		if player then
			MySQL.query('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
				if result[1] then
					local packs = json.decode(result[1].packagename)
					for _, i in pairs (packs) do
						local packagename = i
						local showMsg = true
						for _, v in pairs (Config.Packages) do
							if v.PackageName == i then
								for j=1, #v.Items, 1 do
									local counter = v.Items[j]
									if counter.type == 'item' or counter.type == 'weapon' then
										player.Functions.AddItem(counter.name, counter.amount)
									elseif counter.type == 'account' then
										player.Functions.AddMoney(counter.name, counter.amount, "server-donation")
									elseif counter.type == 'car' then
										redeemedCars[player.PlayerData.citizenid] = counter.model
										TriggerClientEvent('nass_tebexstore:spawnveh', source, counter.model)
									end

									Wait(100)
								end

								TriggerClientEvent('nass_tebexstore:notify', source, "You have successfully redeemed a code for: " .. encode)
								SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **'..player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname..'\n**Identifier: **'..player.PlayerData.citizenid, 3066993)
								showMsg = false
							end
						end
						if showMsg then
							TriggerClientEvent('nass_tebexstore:notify', source, "The "..packagename.." package is not configured by the server owner. Please contact the admin team to fix this.")
						end
					end
					MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode})
				else
					TriggerClientEvent('nass_tebexstore:notify', source, "Code is currently invalid, if you have just purchased please try this code again in a few minutes")
				end
			end)
		end
	end
end, false)

RegisterCommand('purchase_package_tebex', function(source, args)
	if source == 0 then
		local dec = json.decode(args[1])
		local tbxid = dec.transid
		local packTab = {}
		while inProgress do
			Wait(1000)
		end
		inProgress = true
		MySQL.query('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = tbxid}, function(result)
			if result[1] then
				local packagetable = json.decode(result[1].packagename)
				packagetable[#packagetable+1] = dec.packagename
				MySQL.update('UPDATE codes SET packagename = ? WHERE code = ?', {json.encode(packagetable), tbxid}, function(rowsChanged)
					if rowsChanged > 0 then
						SendToDiscord('Purchase', '`'..dec.packagename..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
					else
						SendToDiscord('Error', '`'..tbxid..'` was not inserted into database. Please check for errors!', 15158332)
					end
				end)
			else
				packTab[#packTab+1] = dec.packagename
				MySQL.insert("INSERT INTO codes (code, packagename) VALUES (?, ?)", {tbxid, json.encode(packTab)}, function(rowsChanged)
					SendToDiscord('Purchase', '`'..dec.packagename..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
					print('^2Purchase '..tbxid..' was succesfully inserted into the database.^0')
				end)
			end
			inProgress = false
		end)
	else
		print(GetPlayerName(source)..' tried to give themself a donation code.')
		SendToDiscord('Attempted Exploit', GetPlayerName(source)..' tried to give themself a donation code!', 15158332)
	end
end, false)

RegisterNetEvent('nass_tebexstore:setVehicle', function (vehicleProps)
	local src = source
	if Config.Framework == "ESX" then
		local xPlayer = ESX.GetPlayerFromId(src)
		MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (?, ?, ?, ?)',
		{
			xPlayer.identifier,
			vehicleProps.plate,
			json.encode(vehicleProps),
			1,
		}, function()
			SendToDiscord('Vehicle Redeemed', GetPlayerName(src)..' redeemed their car!', 15158332)
		end)
	elseif Config.Framework == "QB" then
		local player = QBCore.Functions.GetPlayer(src)
		MySQL.insert('INSERT INTO player_vehicles (citizenid, plate, vehicle, state) VALUES (?, ?, ?, ?)',
		{
			player.PlayerData.citizenid,
			vehicleProps.plate,
			json.encode(vehicleProps),
			1,
		}, function()
			SendToDiscord('Vehicle Redeemed', GetPlayerName(src)..' redeemed their car!', 15158332)
		end)
	end
end)

RegisterNetEvent('nass_tebexstore:carNotExist', function()
	SendToDiscord('Vehicle Error', GetPlayerName(source)..' couldn\'t redeemed their car!', 15158332)
end)
