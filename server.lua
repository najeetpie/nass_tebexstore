DiscordWebhook = 'CHANGE_WEBHOOK'

local redeemedCars = {}
local shouldStop = false
local inProgress = false
ESX = nil
QBCore = nil
if Config.Framework == "ESX" then
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 
elseif Config.Framework == "QB" then
	QBCore = exports['qb-core']:GetCoreObject()
else
	TriggerEvent("nass_tebexstore:notify", "nass_tebexstore: Framework in config is not set correctly. ")
end



AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
		local tebexConvar = GetConvar('sv_tebexSecret', '')
		if tebexConvar == '' or tebexConvar == nil then
			print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
			print('^1/////////////////////////////////^4Nass Tebex Store: Tebex Secret Missing.^1/////////////////////////////////')
			print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
			print('nass_tebexstore: Tebex Secret Missing please set in server.cfg and try again. Script will not work.')
			shouldStop = true
		end
		if Config.DiscordLogs then
			SendToDiscord('Nass Tebex Store', '**Status:** *ONLINE*', 3066993)
		else
			print('Webhook Disabled')
		end
	end
end)

CreateThread(function()
	Wait(1000)
	if shouldStop then
		print("Stopping nass_tebexstore")
		StopResource(GetCurrentResourceName())
	end
end)


--Real code below


if Config.Framework == "ESX" then
	ESX.RegisterServerCallback('nass_tebexstore:checkPlate', function(source, cb, plate)
		MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
			['@plate'] = plate
		}, function(result)
			cb(result[1] ~= nil)
		end)
	end)
elseif Config.Framework == "QB" then
	QBCore.Functions.CreateCallback('nass_tebexstore:checkPlate', function(source, cb, plate)
		MySQL.Async.fetchAll('SELECT 1 FROM player_vehicles WHERE plate = @plate', {
			['@plate'] = plate
		}, function(result)
			cb(result[1] ~= nil)
		end)
	end)
end

if Config.Framework == "ESX" then
	ESX.RegisterServerCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local xPlayer = ESX.GetPlayerFromId(source)
		if redeemedCars[xPlayer.identifier] ~= nil then
			if redeemedCars[xPlayer.identifier] == model then
				cb(true)
			else
				cb(false)
			end
		else
			cb(false)
			print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: '..xPlayer.identifier)
			if Config.DiscordLogs then
				SendToDiscord('Attempted Exploit Detected!', '**Identifier: **'..xPlayer.identifier..'\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
			end
			xPlayer.kick('Nice try')
		end
	end)
elseif Config.Framework == "QB" then
	QBCore.Functions.CreateCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local player = QBCore.Functions.GetPlayer(source)
		if player then
			

			if redeemedCars[player.PlayerData.citizenid] ~= nil then
				if redeemedCars[player.PlayerData.citizenid] == model then
					cb(true)
				else
					cb(false)
				end
			else
				
				print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: '..player.PlayerData.citizenid)
				if Config.DiscordLogs then
					SendToDiscord('Attempted Exploit Detected!', '**Identifier: **'..player.PlayerData.citizenid..'\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
				end
				QBCore.Functions.Kick(source, 'Nice try')
				cb(false)
			end
		end
	end)
end



RegisterCommand('redeem', function(source, args, rawCommand)
	if Config.Framework == "ESX" then
		local encode = rawCommand:sub(8)
		local xPlayer = ESX.GetPlayerFromId(source)
		local xName = xPlayer.getName()
		MySQL.Async.fetchAll('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
			if result[1] then
				local packs = json.decode(result[1].packagename)
				for j, i in pairs (packs) do
					local packagename = i
					local showMsg = true
					for k,v in pairs (Config.Packages) do
						if v.PackageName == i then
							for i=1, #v.Items, 1 do
								local counter = v.Items[i]
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
							if Config.DiscordLogs then
								SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **'..xName..'\n**Identifier: **'..xPlayer.identifier, 3066993)
							end
							showMsg = false
						end
					end
					if showMsg then
						TriggerClientEvent('nass_tebexstore:notify', source, "The "..packagename.." package is not configured by the server owner. Please contact the admin team to fix this.")
					end
				end
				MySQL.Async.fetchAll('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result) end)
			else
				TriggerClientEvent('nass_tebexstore:notify', source, "Code is currently invalid, if you have just purchased please try this code again in a few minutes")
			end
		end)
	elseif Config.Framework == "QB" then
		local encode = rawCommand:sub(8)
		local player = QBCore.Functions.GetPlayer(source)
		if player then
			MySQL.Async.fetchAll('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
				if result[1] then
					local packs = json.decode(result[1].packagename)
					for j, i in pairs (packs) do
						local packagename = i
						local showMsg = true
						for k,v in pairs (Config.Packages) do
							if v.PackageName == i then
								for i=1, #v.Items, 1 do
									local counter = v.Items[i]
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
								if Config.DiscordLogs then
									SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **'..xName..'\n**Identifier: **'..player.PlayerData.citizenid, 3066993)
								end
								showMsg = false
							end
						end
						if showMsg then
							TriggerClientEvent('nass_tebexstore:notify', source, "The "..packagename.." package is not configured by the server owner. Please contact the admin team to fix this.")
						end
					end
					MySQL.Async.fetchAll('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result) end)
				else
					TriggerClientEvent('nass_tebexstore:notify', source, "Code is currently invalid, if you have just purchased please try this code again in a few minutes")
				end
			end)
		end	
	end
end)


 
RegisterCommand('purchase_package_tebex', function(source, args)
    if source == 0 then
        local dec = json.decode(args[1])
        local tbxid = dec.transid
        local packTab = {}
        while inProgress do
            Wait(1000)
        end
        inProgress = true
        MySQL.Async.fetchAll('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = tbxid}, function(result)
            if result[1] then
                local packagetable = json.decode(result[1].packagename)
                table.insert(packagetable, dec.packagename)
                MySQL.Async.execute('UPDATE codes SET packagename = @packagename WHERE code = @code', {
                    ["@code"] = tbxid,
                    ["@packagename"] = json.encode(packagetable),
 
                }, function(rowsChanged)
                    if rowsChanged>0 then
                        if Config.DiscordLogs then
                            SendToDiscord('Purchase', '`'..dec.packagename..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
                        end
                        print('^3////////////////////////////////////////////////////////////////////////////////////////////////////////////')
                        print('^3//////////////////////^2Purchase '..tbxid..' was succesfully inserted into the database.^3//////////////////////')
                        print('^3////////////////////////////////////////////////////////////////////////////////////////////////////////////')
                    else
                        print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
                        print('^1///////////^4Purchase '..tbxid..' was not inserted into the database please check for errors.^1///////////')
                        print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
                        if Config.DiscordLogs then
                            SendToDiscord('Error', '`'..tbxid..'` was not inserted into database. Please check for errors!', 15158332)
                        end
                    end
                end)
            else
                table.insert(packTab, dec.packagename)
                MySQL.Async.execute("INSERT INTO codes(code,packagename) VALUES (@code,@packagename)", {
                    ["@code"] = tbxid,
                    ["@packagename"] = json.encode(packTab)
                }, function(rowsChanged)
					if rowsChanged>0 then
						if Config.DiscordLogs then
							SendToDiscord('Purchase', '`'..dec.packagename..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
						end
						print('^3////////////////////////////////////////////////////////////////////////////////////////////////////////////')
						print('^3//////////////////////^2Purchase '..tbxid..' was succesfully inserted into the database.^3//////////////////////')
						print('^3////////////////////////////////////////////////////////////////////////////////////////////////////////////')
					else
						print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
						print('^1///////////^4Purchase '..tbxid..' was not inserted into the database please check for errors.^1///////////')
						print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
						if Config.DiscordLogs then
							SendToDiscord('Error', '`'..tbxid..'` was not inserted into database. Please check for errors!', 15158332)
						end
					end
                end)
            end
            inProgress = false
        end)    
    else
        print(GetPlayerName(source)..' tried to give themself a donation code.')
        if Config.DiscordLogs then
            SendToDiscord('Attempted Exploit', GetPlayerName(source)..' tried to give themself a donation code!', 15158332)
        end
    end
end)

RegisterServerEvent('nass_tebexstore:setVehicle')
AddEventHandler('nass_tebexstore:setVehicle', function (vehicleProps)
	if Config.Framework == "ESX" then
		local xPlayer = ESX.GetPlayerFromId(source)
		MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, state) VALUES (@owner, @plate, @vehicle, @state)',
		{
			['@owner']   = xPlayer.identifier,
			['@plate']   = vehicleProps.plate,
			['@vehicle'] = json.encode(vehicleProps),
			['@state'] = 1,
		}, function ()
			if Config.DiscordLogs then
				SendToDiscord('Vehicle Redeemed', GetPlayerName(source)..' redeemed their car!', 15158332)
			end
		end)
	elseif Config.Framework == "QB" then
		local player = QBCore.Functions.GetPlayer(source)
		MySQL.Async.execute('INSERT INTO player_vehicles (citizenid, plate, vehicle, state) VALUES (@citizenid, @plate, @vehicle,, @state)',
		{
			['@citizenid']   = player.PlayerData.citizenid,
			['@plate']   = vehicleProps.plate,
			['@vehicle'] = json.encode(vehicleProps),
			['@state'] = 1,
		}, function ()
			if Config.DiscordLogs then
				SendToDiscord('Vehicle Redeemed', GetPlayerName(source)..' redeemed their car!', 15158332)
			end
		end)
	end
end)

RegisterServerEvent('nass_tebexstore:carNotExist')
AddEventHandler('nass_tebexstore:carNotExist', function()
	if Config.DiscordLogs then
		SendToDiscord('Vehicle Error', GetPlayerName(source)..' couldn\'t redeemed their car!', 15158332)
	end
end)

local DISCORD_NAME = "nass_tebexstore"
local DISCORD_IMAGE = "https://i.imgur.com/Q72RWcB.png"

function SendToDiscord(name, message, color)
	if DiscordWebhook == "CHANGE_WEBHOOK" then
		print("PLEASE CHANGE SERVER SIDE WEBHOOK")
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
		PerformHttpRequest(DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = DISCORD_NAME, embeds = connect, avatarrl = DISCORD_IMAGE}), { ['Content-Type'] = 'application/json' })
	end
end


