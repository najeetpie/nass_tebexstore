local ESX = nil
local QBCore = nil

CreateThread(function()
	if Config.Framework == "ESX" then
		ESX = exports.es_extended:getSharedObject()
	elseif Config.Framework == "QB" then
		QBCore = exports['qb-core']:GetCoreObject()
	else
		TriggerEvent("nass_tebexstore:notify", "nass_tebexstore: Framework in config is not set correctly.")
	end
end)

RegisterNetEvent('nass_tebexstore:notify', function(message)
	if Config.Framework == "ESX" then
		ESX.ShowNotification(message)
	elseif Config.Framework == "QB" then
		QBCore.Functions.Notify(message, 'primary', 5000)
	end
end)

RegisterNetEvent('nass_tebexstore:spawnveh', function(model)
	if Config.Framework == "ESX" then
		ESX.TriggerServerCallback('nass_tebexstore:redeemCheck', function(isLegit, newPlate)
			if not isLegit or not newPlate then return end
			local carExist = false

			ESX.Game.SpawnVehicle(model, GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 10.0), 0.0, function(vehicle) -- Get vehicle info
				carExist = true

				SetEntityVisible(vehicle, false, false)
				SetEntityCollision(vehicle, false, false)
				FreezeEntityPosition(vehicle, true)

				local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
				vehicleProps.plate = newPlate
				TriggerServerEvent('nass_tebexstore:setVehicle', vehicleProps)

				ESX.Game.DeleteVehicle(vehicle)
			end, false)

			Wait(1000)
			if carExist then return end
			TriggerServerEvent('nass_tebexstore:carNotExist')
		end, model)
	elseif Config.Framework == "QB" then
		QBCore.Functions.TriggerCallback('nass_tebexstore:redeemCheck', function(isLegit, newPlate)
			if not isLegit or not newPlate then return end
			local carExist = false
			local vehCoords = GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 10.0)

			QBCore.Functions.SpawnVehicle(model, function(vehicle) -- Get vehicle info
				carExist = true

				SetEntityVisible(vehicle, false, false)
				SetEntityCollision(vehicle, false, false)
				FreezeEntityPosition(vehicle, true)

				local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
				vehicleProps.plate = newPlate
				TriggerServerEvent('nass_tebexstore:setVehicle', vehicleProps)

				QBCore.Functions.DeleteVehicle(vehicle)
			end, vector4(vehCoords.x, vehCoords.y, vehCoords.z, 0.0), false)

			Wait(1000)
			if carExist then return end
			TriggerServerEvent('nass_tebexstore:carNotExist')
		end, model)
	end
end)