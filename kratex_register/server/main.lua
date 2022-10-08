local playerIdentity = {}
local alreadyRegistered = {}

ESX = nil 

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) 

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
	deferrals.defer()
	local playerId, identifier = source, ESX.GetIdentifier(source)
	Citizen.Wait(40)

	if identifier then
		MySQL.Async.fetchAll('SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			if result[1] then
				if result[1].firstname then
					playerIdentity[identifier] = {
						firstName = result[1].firstname,
						lastName = result[1].lastname,
						dateOfBirth = result[1].dateofbirth,
						sex = result[1].sex,
						height = result[1].height
					}

					alreadyRegistered[identifier] = true

					deferrals.done()
				else
					playerIdentity[identifier] = nil
					alreadyRegistered[identifier] = false
					deferrals.done()
				end
			else
				playerIdentity[identifier] = nil
				alreadyRegistered[identifier] = false
				deferrals.done()
			end
		end)
	else
		deferrals.done(Config.Translate['no_identity'])
	end
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(300)

		while not ESX do
			Citizen.Wait(10)
		end

		local xPlayers = ESX.GetPlayers()
		for _, xPlayer in pairs(xPlayers) do
			local igrac = ESX.GetPlayerFromId(xPlayer)
			if xPlayer then	
				checkIdentity(igrac)
			end
		end
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local myID = {
		steamid = xPlayer.identifier,
		playerid = playerId
	}

	TriggerClientEvent('esx_identity:saveID', playerId, myID)

	local currentIdentity = playerIdentity[xPlayer.identifier]
	if currentIdentity and alreadyRegistered[xPlayer.identifier] == true then

		xPlayer.setName(('%s %s'):format(currentIdentity.firstName, currentIdentity.lastName))
		xPlayer.set('firstName', currentIdentity.firstName)
		xPlayer.set('lastName', currentIdentity.lastName)
		xPlayer.set('dateofbirth', currentIdentity.dateOfBirth)
		xPlayer.set('sex', currentIdentity.sex)
		xPlayer.set('height', currentIdentity.height)

		if currentIdentity.saveToDatabase then
			saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
		end

		Citizen.Wait(10)
		TriggerClientEvent('kratex_register:alreadyRegistered', xPlayer.source)

		playerIdentity[xPlayer.identifier] = nil
	else
		TriggerClientEvent('kratex_register:openRegister', xPlayer.source)
	end
end)

ESX.RegisterServerCallback('kratex_register:registerCharacter', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        if not alreadyRegistered[xPlayer.identifier] then
            if checkNameFormat(data.firstname) and checkNameFormat(data.lastname) and checkSexFormat(data.sex) and checkDOBFormat(data.dateofbirth) and checkHeightFormat(data.height) then
                playerIdentity[xPlayer.identifier] = {
                    firstName = formatName(data.firstname),
                    lastName = formatName(data.lastname),
                    dateOfBirth = data.dateofbirth,
                    sex = data.sex,
                    height = data.height
                }

                local currentIdentity = playerIdentity[xPlayer.identifier]

                xPlayer.setName(('%s %s'):format(currentIdentity.firstName, currentIdentity.lastName))
                xPlayer.set('firstName', currentIdentity.firstName)
                xPlayer.set('lastName', currentIdentity.lastName)
                xPlayer.set('dateofbirth', currentIdentity.dateOfBirth)
                xPlayer.set('sex', currentIdentity.sex)
                xPlayer.set('height', currentIdentity.height)

                saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
                alreadyRegistered[xPlayer.identifier] = true
        
                playerIdentity[xPlayer.identifier] = nil
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end
end)

function checkIdentity(xPlayer)
    MySQL.Async.fetchAll('SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            if result[1].firstname then
                playerIdentity[xPlayer.identifier] = {
                    firstName = result[1].firstname,
                    lastName = result[1].lastname,
                    dateOfBirth = result[1].dateofbirth,
                    sex = result[1].sex,
                    height = result[1].height
                }

                alreadyRegistered[xPlayer.identifier] = true

                setIdentity(xPlayer)
            else
                playerIdentity[xPlayer.identifier] = nil
                alreadyRegistered[xPlayer.identifier] = false
                TriggerClientEvent('kratex_register:openRegister', xPlayer.source)
            end
        else
            TriggerClientEvent('kratex_register:openRegister', xPlayer.source)
        end
    end)
end

function setIdentity(xPlayer)
    if alreadyRegistered[xPlayer.identifier] then
        local currentIdentity = playerIdentity[xPlayer.identifier]

        xPlayer.setName(('%s %s'):format(currentIdentity.firstName, currentIdentity.lastName))
        xPlayer.set('firstName', currentIdentity.firstName)
        xPlayer.set('lastName', currentIdentity.lastName)
        xPlayer.set('dateofbirth', currentIdentity.dateOfBirth)
        xPlayer.set('sex', currentIdentity.sex)
        xPlayer.set('height', currentIdentity.height)

        if currentIdentity.saveToDatabase then
            saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
        end

        playerIdentity[xPlayer.identifier] = nil
    end
end

function deleteIdentity(xPlayer)
	if alreadyRegistered[xPlayer.identifier] then
		xPlayer.setName(('%s %s'):format(nil, nil))
		xPlayer.set('firstName', nil)
		xPlayer.set('lastName', nil)
		xPlayer.set('dateofbirth', nil)
		xPlayer.set('sex', nil)
		xPlayer.set('height', nil)

		deleteIdentityFromDatabase(xPlayer)
	end
end

function saveIdentityToDatabase(identifier, identity)
	MySQL.Sync.execute('UPDATE users SET firstname = @firstname, lastname = @lastname, dateofbirth = @dateofbirth, sex = @sex, height = @height WHERE identifier = @identifier', {
		['@identifier']  = identifier,
		['@firstname'] = identity.firstName,
		['@lastname'] = identity.lastName,
		['@dateofbirth'] = identity.dateOfBirth,
		['@sex'] = identity.sex,
		['@height'] = identity.height
	})
end

function deleteIdentityFromDatabase(xPlayer)
	MySQL.Sync.execute('UPDATE users SET firstname = @firstname, lastname = @lastname, dateofbirth = @dateofbirth, sex = @sex, height = @height , skin = @skin WHERE identifier = @identifier', {
		['@identifier']  = xPlayer.identifier,
		['@firstname'] = NULL,
		['@lastname'] = NULL,
		['@dateofbirth'] = NULL,
		['@sex'] = NULL,
		['@height'] = NULL,
		['@skin'] = NULL
	})
end

function checkNameFormat(name)
	if not checkAlphanumeric(name) then
		if not checkForNumbers(name) then
			local stringLength = string.len(name)
			if stringLength > 0 and stringLength < Config.MaxNameLength then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function checkDOBFormat(dob)
	local date = tostring(dob)
	if checkDate(date) then
		return true
	else
		return false
	end
end

function checkSexFormat(sex)
	if sex == "m" or sex == "M" or sex == "f" or sex == "F" then
		return true
	else
		return false
	end
end

function checkHeightFormat(height)
	local numHeight = tonumber(height)
	if numHeight < Config.MinHeight and numHeight > Config.MaxHeight then
		return false
	else
		return true
	end
end

function formatName(name)
	local loweredName = convertToLowerCase(name)
	local formattedName = convertFirstLetterToUpper(loweredName)
	return formattedName
end

function convertToLowerCase(str)
	return string.lower(str)
end

function convertFirstLetterToUpper(str)
	return str:gsub("^%l", string.upper)
end

function checkAlphanumeric(str)
	return (string.match(str, "%W"))
end

function checkForNumbers(str)
	return (string.match(str,"%d"))
end

function checkDate(str)
	if string.match(str, '(%d%d)/(%d%d)/(%d%d%d%d)') ~= nil then
		local m, d, y = string.match(str, '(%d+)/(%d+)/(%d+)')
		m = tonumber(m)
		d = tonumber(d)
		y = tonumber(y)
		if ((d <= 0) or (d > 31)) or ((m <= 0) or (m > 12)) or ((y <= Config.LowestYear) or (y > Config.HighestYear)) then
			return false
		elseif m == 4 or m == 6 or m == 9 or m == 11 then
			if d > 30 then
				return false
			else
				return true
			end
		elseif m == 2 then
			if y%400 == 0 or (y%100 ~= 0 and y%4 == 0) then
				if d > 29 then
					return false
				else
					return true
				end
			else
				if d > 28 then
					return false
				else
					return true
				end
			end
		else
			if d > 31 then
				return false
			else
				return true
			end
		end
	else
		return false
	end
end
