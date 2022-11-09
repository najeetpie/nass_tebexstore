local redeemedCars = {}
local inProgress = false

MySQL.ready(function()
	MySQL.Sync.execute(
		'CREATE TABLE IF NOT EXISTS `codes` (' ..
			'`code` varchar(50) NOT NULL DEFAULT \'\', ' ..
			'`packagename` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL, ' ..
			'PRIMARY KEY (`code`) ' ..
		') ENGINE=InnoDB DEFAULT CHARSET=latin1; '
	)
end)

if Framework == 'ESX' then
	ESX.RegisterServerCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local xPlayer = ESX.GetPlayerFromId(source)
		if redeemedCars[xPlayer.identifier] ~= nil then
			local redeemed = redeemedCars[xPlayer.identifier] == model
			cb(redeemed, redeemed and GeneratePlate() or nil)
		else
			cb(false)
			print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: ' .. xPlayer.identifier)
			SendToDiscord('Attempted Exploit Detected!', '**Identifier: **' .. xPlayer.identifier .. '\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
			if Config.EnableEasyAdmin then
				TriggerEvent('EasyAdmin:addBan', source, '[nass_tebexstore]: Tried to exploit the System', 32503676400, 'nass_tebexstore (' .. GetInvokingResource() .. ')')
			else
				xPlayer.kick('Nice try')
			end
		end
	end)
elseif Framework == 'QB' then
	QBCore.Functions.CreateCallback('nass_tebexstore:redeemCheck', function(source, cb, model)
		local player = QBCore.Functions.GetPlayer(source)
		if not player then return end
		if redeemedCars[player.PlayerData.citizenid] ~= nil then
			local redeemed = redeemedCars[player.PlayerData.citizenid] == model
			cb(redeemed, redeemed and GeneratePlate() or nil)
		else
			cb(false)
			print('[nass_tebexstore]: A player tried to exploit the vehicle spawn trigger! Identifier: ' .. player.PlayerData.citizenid)
			SendToDiscord('Attempted Exploit Detected!', '**Identifier: **' .. player.PlayerData.citizenid .. '\n**Comments:** Player has attempted to trigger the spawn vehicle event without a redemption code.', 3066993)
			if Config.EnableEasyAdmin then
				TriggerEvent('EasyAdmin:addBan', source, '[nass_tebexstore]: Tried to exploit the System', 32503676400, 'nass_tebexstore (' .. GetInvokingResource() .. ')')
			else
				QBCore.Functions.Kick(source, 'Nice try')
			end
		end
	end)
end

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		local tebexConvar = GetConvar('sv_tebexSecret', '')
		if tebexConvar == '' then
			error('Tebex Secret Missing please set in server.cfg and try again. The script will not work without it.')
			StopResource(GetCurrentResourceName())
		end
		if not SConfig.DiscordLogs then
			print('^3Webhooks Disabled^0')
		end
	end
end)

RegisterCommand('redeem', function(source, _, rawCommand)
	if Framework == 'ESX' then
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

							Config.Notification('You have successfully redeemed a code for: ' .. encode)
							SendToDiscord('Code Redeemed', '**Package Name: **'..packagename..'\n**Character Name: **' .. xName .. '\n**Identifier: **' .. xPlayer.identifier, 3066993)
							showMsg = false
						end
					end
					if showMsg then
						Config.Notification('The ' .. packagename .. ' package is not configured by the server owner. Please contact the admin team.')
					end
				end
				MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode})
			else
				Config.Notification('Code is currently invalid, if you have just purchased please try this code again in a few minutes')
			end
		end)
	elseif Framework == 'QB' then
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
										player.Functions.AddMoney(counter.name, counter.amount, 'server-donation')
									elseif counter.type == 'car' then
										redeemedCars[player.PlayerData.citizenid] = counter.model
										TriggerClientEvent('nass_tebexstore:spawnveh', source, counter.model)
									end

									Wait(100)
								end

								Config.Notification('You have successfully redeemed a code for: ' .. encode)
								SendToDiscord('Code Redeemed', '**Package Name: **' .. packagename .. '\n**Character Name: **' .. player.PlayerData.firstname .. ' ' .. player.PlayerData.lastname .. '\n**Identifier: **' .. player.PlayerData.citizenid, 3066993)
								showMsg = false
							end
						end
						if showMsg then
							Config.Notification('The ' .. packagename .. ' package is not configured by the server owner. Please contact the admin team to fix this.')
						end
					end
					MySQL.query.await('DELETE FROM codes WHERE code = @playerCode', {['@playerCode'] = encode})
				else
					Config.Notification('Code is currently invalid, if you have just purchased please try this code again in a few minutes')
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
						SendToDiscord('Purchase', '`' .. dec.packagename .. '` was just purchased and inserted into the database under redeem code: `' .. tbxid .. '`.', 1752220)
					else
						SendToDiscord('Error', '`' .. tbxid .. '` was not inserted into database. Please check for errors!', 15158332)
					end
				end)
			else
				packTab[#packTab+1] = dec.packagename
				MySQL.insert('INSERT INTO codes (code, packagename) VALUES (?, ?)', {tbxid, json.encode(packTab)}, function(rowsChanged)
					SendToDiscord('Purchase', '`' .. dec.packagename .. '` was just purchased and inserted into the database under redeem code: `' .. tbxid .. '`.', 1752220)
					print('^2Purchase ' ..tbxid.. ' was succesfully inserted into the database.^0')
				end)
			end
			inProgress = false
		end)
	else
		print(GetPlayerName(source)..' tried to give themself a donation code.')
		SendToDiscord('Attempted Exploit', GetPlayerName(source) .. ' tried to give themself a donation code!', 15158332)
	end
end, false)

RegisterNetEvent('nass_tebexstore:setVehicle', function (vehicleProps)
	local src = source
	if Framework == 'ESX' then
		local xPlayer = ESX.GetPlayerFromId(src)
		MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)',
		{
			xPlayer.identifier,
			vehicleProps.plate,
			json.encode(vehicleProps),
			1,
		}, function()
			SendToDiscord('Vehicle Redeemed', GetPlayerName(src) .. ' redeemed their car!', 15158332)
		end)
	elseif Framework == 'QB' then
		local player = QBCore.Functions.GetPlayer(src)
		MySQL.insert('INSERT INTO player_vehicles (citizenid, plate, vehicle, state) VALUES (?, ?, ?, ?)',
		{
			player.PlayerData.citizenid,
			vehicleProps.plate,
			json.encode(vehicleProps),
			1,
		}, function()
			SendToDiscord('Vehicle Redeemed', GetPlayerName(src) .. ' redeemed their car!', 15158332)
		end)
	end
end)

RegisterNetEvent('nass_tebexstore:carNotExist', function()
	SendToDiscord('Vehicle Error', GetPlayerName(source) .. ' couldn\'t redeemed their car!', 15158332)
end)