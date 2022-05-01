DiscordWebhook = 'CHANGE_WEBHOOK'

ESX = nil 
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 



AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
		if Config.DiscordLogs then
			SendToDiscord('Nass Tebex Store', '**Status:** *ONLINE*', 3066993)
		else
			print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
			print('^1/////////////////////////////////^4Nass Tebex Store: Webhook DISABLED.^1/////////////////////////////////')
			print('^1////////////////////////////////////////////////////////////////////////////////////////////////////////////')
		end
	end
end)



--Real code below

RegisterCommand('redeem', function(source, args, rawCommand)
    local encode = rawCommand:sub(8)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xName = xPlayer.getName()
    MySQL.Async.fetchAll('SELECT * FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result)
		if result[1] then
			local packagename = result[1].packagename
			for k,v in pairs (Config.Packages) do
				if v.PackageName == packagename then
					for i=1, #v.Items, 1 do
						local counter = v.Items[i]
						if counter.type == 'item' then
							xPlayer.addInventoryItem(counter.name, counter.amount)
						elseif counter.type == 'weapon' then
							xPlayer.addWeapon(counter.name, counter.amount)
						elseif counter.type == 'account' then
							xPlayer.addAccountMoney(counter.name, counter.amount)
						elseif counter.type == 'car' then
							TriggerClientEvent('nass_tebexstore:spawnveh', source, counter.model)
						end
						MySQL.Async.fetchAll('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode}, function(result) end)
						Wait(100)
					end

					TriggerClientEvent('nass_tebexstore:notify', source, "You have successfully redeemed a code for: " .. encode)
					if Config.DiscordLogs then
						SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **'..xName..'\n**Identifier: **'..xPlayer.identifier, 3066993)
					end
				end
			end
		else
			TriggerClientEvent('nass_tebexstore:notify', source, "You have entered an invalid code")
		end
    end)

end)


RegisterCommand('purchase_package_tebex', function(source, args)
	if source == 0 then
		local dec = json.decode(args[1])
		local tbxid = dec.transid
		print(tbxid)
		local packagename = dec.packagename
		MySQL.Async.execute("INSERT INTO codes(code,packagename,amount) VALUES (@code,@packagename,@amount)", {
			["@code"] = tbxid,
			["@packagename"] = packagename,
			["@amount"] = 1
		}, function(rowsChanged)
				if rowsChanged>0 then
					if Config.DiscordLogs then
						SendToDiscord('Purchase', '`'..packagename..'` was just purchased and inserted into the database under redeem code: `'..tbxid..'`.', 1752220)
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
		print(GetPlayerName(source)..' tried to give themself a donation code.')
		if Config.DiscordLogs then
			SendToDiscord('Attempted Exploit', GetPlayerName(source)..' tried to give themself a donation code!', 15158332)
		end
	end
end)


RegisterServerEvent('nass_tebexstore:setVehicle')
AddEventHandler('nass_tebexstore:setVehicle', function (vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (@owner, @plate, @vehicle, @stored)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps),
		['@stored']  = 1
	}, function ()
		if Config.DiscordLogs then
			SendToDiscord('Vehicle Redeemed', GetPlayerName(source)..' redeemed their car!', 15158332)
		end
	end)
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


