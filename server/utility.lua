local NumberCharset = {}
local Charset = {}
local plateQuery = ''

for i = 48,  57 do
	table.insert(NumberCharset, string.char(i))
end

for i = 65,  90 do
	table.insert(Charset, string.char(i))
end
for i = 97, 122 do
	table.insert(Charset, string.char(i))
end

function GetRandomNumber(length)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

function GetRandomLetter(length)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

function GeneratePlate()
    if Framework == 'ESX' then
        plateQuery = 'SELECT 1 FROM owned_vehicles WHERE plate = ?'
    elseif Framework == 'QB' then
        plateQuery = 'SELECT 1 FROM player_vehicles WHERE plate = ?'
    end
	local plate = Config.SpaceInLicensePlate and GetRandomLetter(Config.LicensePlateLetters)..' '..GetRandomNumber(Config.LicensePlateNumbers) or GetRandomLetter(Config.LicensePlateLetters) .. GetRandomNumber(Config.LicensePlateNumbers)
	local result = MySQL.scalar.await(plateQuery, {plate})
	return result and GeneratePlate() or plate:upper()
end

function SendToDiscord(name, message, color)
	if not SConfig.DiscordLogs then
		return
	end

	if not SConfig.DiscordWebhook then
		print(message)
	else
		local connect = {
			{
				['color'] = color,
				['title'] = '**'.. name ..'**',
				['description'] = message,
				['footer'] = {
					['text'] = 'Nass Tebexstore',
				},
			}
		}
		PerformHttpRequest(SConfig.DiscordWebhook, function() end, 'POST', json.encode({username = SConfig.DiscordName, embeds = connect, avatarrl = SConfig.DiscordImage}), { ['Content-Type'] = 'application/json' })
	end
end