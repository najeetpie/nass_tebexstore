ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('nass_tebexstore:notify')
AddEventHandler('nass_tebexstore:notify', function(message)
    -- Place notification system info here, ex: exports['mythic_notify']:SendAlert('inform', message)
    ESX.ShowNotification(message)
end)

RegisterNetEvent('nass_tebexstore:spawnveh')
AddEventHandler('nass_tebexstore:spawnveh', function(model)
	local carExist  = false

	ESX.Game.SpawnVehicle(model, vector3(0.0, 0.0, -10.0), 0.0, function(vehicle) --get vehicle info
		if DoesEntityExist(vehicle) then
			carExist = true
			SetEntityVisible(vehicle, false, false)
			SetEntityCollision(vehicle, false)
			
			local newPlate     = exports.t1ger_dealerships:GeneratePlate()
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
end)