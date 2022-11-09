local NumberCharset = {}
local Charset = {}
local plateQuery = ''
local curVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
local resourceName = 'nass_tebexstore'

CreateThread(function()
    if GetCurrentResourceName() ~= 'nass_tebexstore' then
        resourceName = 'nass_tebexstore (' .. GetCurrentResourceName() .. ')'
    end

    while true do
        PerformHttpRequest('https://api.github.com/repos/zrxnx/nass_tebexstore/releases/latest', CheckVersion, 'GET')
        Wait(3600000)
    end
end)

function CheckVersion(err, responseText, headers)
    local repoVersion, repoURL = GetRepoInformations()

    CreateThread(function()
        if curVersion ~= repoVersion then
            Wait(4000)
            print('^0[^3WARNING^0] ' .. resourceName .. ' is ^1NOT ^0up to date!')
            print('^0[^3WARNING^0] Your Version: ^1' .. curVersion .. '^0')
            print('^0[^3WARNING^0] Latest Version: ^2' .. repoVersion .. '^0')
            print('^0[^3WARNING^0] Get the latest Version from: ^2' .. repoURL .. '^0')
        end
    end)
end

function GetRepoInformations()
    local repoVersion, repoURL = curVersion, 'https://github.com/zrxnx/nass_tebexstore'

    PerformHttpRequest('https://api.github.com/repos/zrxnx/nass_tebexstore/releases/latest', function(err, response, headers)
        if err == 200 then
            local data = json.decode(response)

            repoVersion = data.tag_name
            repoURL = data.html_url
        end
    end, 'GET')

    repeat
        Wait(50)
    until (repoVersion and repoURL)

    return repoVersion, repoURL
end


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