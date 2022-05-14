ESX = nil
QBCore = nil
Citizen.CreateThread(function()
	if Config.Framework == "ESX" then
		while ESX == nil do
			TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
			Citizen.Wait(0)
		end
	elseif Config.Framework == "QB" then
		QBCore = exports['qb-core']:GetCoreObject()
	else
		TriggerEvent("nass_tebexstore:notify", "nass_tebexstore: Framework in config is not set correctly. ")
	end
end)

RegisterNetEvent('nass_tebexstore:notify')
AddEventHandler('nass_tebexstore:notify', function(message)
	if Config.Framework == "ESX" then
		ESX.ShowNotification(message)
	elseif Config.Framework == "QB" then
		QBCore.Functions.Notify(message, 'primary', 5000)
	end
end)



generatePlate = function()
    local plate
    local breakLoop = false
    while true do
        Wait(5)
        math.randomseed(GetGameTimer())
        if Config.SpaceInLicensePlate then
            plate = string.upper(GetRandomLetter(Config.LicensePlateLetters).. ' '..GetRandomNumber(Config.LicensePlateNumbers))
        else
            plate = string.upper(GetRandomLetter(Config.LicensePlateLetters) ..GetRandomNumber(Config.LicensePlateNumbers))
        end
		if Config.Framework == "ESX" then
			ESX.TriggerServerCallback('nass_tebexstore:checkPlate', function(taken)
				if not taken then
					breakLoop = true
				end
			end, plate)
		elseif Config.Framework == "QB" then
			QBCore.Functions.TriggerCallback('nass_tebexstore:checkPlate', function(taken)
				if not taken then
					breakLoop = true
				end
			end, plate)
		end
        
        if breakLoop then
            break
        end
    end
    return plate
end


RegisterNetEvent('nass_tebexstore:spawnveh')
AddEventHandler('nass_tebexstore:spawnveh', function(model)
	if Config.Framework == "ESX" then
		ESX.TriggerServerCallback('nass_tebexstore:redeemCheck', function(isLegit)
			if isLegit then
				local carExist  = false
	
				ESX.Game.SpawnVehicle(model, vector3(0.0, 0.0, -10.0), 0.0, function(vehicle) --get vehicle info
					if DoesEntityExist(vehicle) then
						carExist = true
						SetEntityVisible(vehicle, false, false)
						SetEntityCollision(vehicle, false)
						
						local newPlate     = generatePlate()
						local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
						vehicleProps.plate = newPlate
						TriggerServerEvent('nass_tebexstore:setVehicle', vehicleProps)
						ESX.Game.DeleteVehicle(vehicle)	
								
					end		
				end)
				
				Wait(1000)
				if not carExist then
					TriggerServerEvent('nass_tebexstore:carNotExist')		
				end
			end
		end, model)
	elseif Config.Framework == "QB" then
		QBCore.Functions.TriggerCallback('nass_tebexstore:redeemCheck', function(isLegit)
			if isLegit then
				local carExist  = false

				QBCore.Functions.SpawnVehicle(model, function(vehicle)
						carExist = true
						SetEntityVisible(vehicle, false, false)
						SetEntityCollision(vehicle, false)
						local newPlate     = generatePlate()
						local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
						vehicleProps.plate = newPlate
						TriggerServerEvent('nass_tebexstore:setVehicle', vehicleProps)
						QBCore.Functions.DeleteVehicle(vehicle)	
				end, vector4(0.0, 0.0, -10.0, 0.0), false)
				
				Wait(1000)
				if not carExist then
					TriggerServerEvent('nass_tebexstore:carNotExist')		
				end
			end
		end, model)
	end
end)
