local myIdentifiers = {}

ESX = nil 

Citizen.CreateThread(function() 
    while ESX == nil do 
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 
        Citizen.Wait(0) 
    end 
end)

local loadingscreenEnded = false

RegisterNetEvent('kratex_register:alreadyRegistered')
AddEventHandler('kratex_register:alreadyRegistered', function()
	while not loadingscreenEnded do
		Citizen.Wait(100)
	end

	TriggerEvent('esx_skin:playerRegistered')
end)

AddEventHandler('esx:loadingScreenOff', function()
	loadingscreenEnded = true
end)

local nuiopened, isDead = false, false

AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true
end)

AddEventHandler('esx:onPlayerSpawn', function(spawn)
    isDead = false
end)

function Nui(state)
    SetNuiFocus(state, state)
    nuiopened = state

    SendNUIMessage({
        type = "openregister",
        value = state
    })
end

RegisterNetEvent('kratex_register:saveID')
AddEventHandler('kratex_register:saveID', function(data)
	myIdentifiers = data
end)

RegisterNetEvent('kratex_register:openRegister')
AddEventHandler('kratex_register:openRegister', function()
	TriggerEvent('esx_skin:resetFirstSpawn')

	if not isDead then
		Nui(true)
	end
end)

RegisterNUICallback('register', function(data, cb)
	ESX.TriggerServerCallback('kratex_register:registerCharacter', function(callback)
		if callback then
			TriggerEvent('esx_skin:openSaveableMenu', myIdentifiers.id)
			ESX.ShowNotification(Config.Translate['thank_you_for_registering'])
			Nui(false)
		else
			ESX.ShowNotification(Config.Translate['registration_error'])
		end
	end, data)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5)
        sleep = true
		if nuiopened then
            sleep = false
			DisableControlAction(0, 1,   true)
			DisableControlAction(0, 2,   true)
			DisableControlAction(0, 106, true)
			DisableControlAction(0, 142, true)
			DisableControlAction(0, 30,  true)
			DisableControlAction(0, 31,  true)
			DisableControlAction(0, 21,  true)
			DisableControlAction(0, 24,  true)
			DisableControlAction(0, 25,  true)
			DisableControlAction(0, 47,  true)
			DisableControlAction(0, 58,  true)
			DisableControlAction(0, 263, true)
			DisableControlAction(0, 264, true)
			DisableControlAction(0, 257, true)
			DisableControlAction(0, 140, true)
			DisableControlAction(0, 141, true)
			DisableControlAction(0, 143, true)
			DisableControlAction(0, 75,  true)
			DisableControlAction(27, 75, true)
		end
        if sleep then
            Citizen.Wait(1500)
        end
	end
end)