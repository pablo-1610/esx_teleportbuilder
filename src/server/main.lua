local teleportZones = {}

-- Register a new tp zone and store it in database
local function registerTeleportZone(teleportZone, cb)
    MySQL.Async.insert("INSERT INTO esx_teleportbuilder (data) VALUES (@data)", {
        ["@data"] = json.encode(teleportZone)
    }, function(id)
        table.insert(teleportZones, teleportZone)
        cb(id ~= nil)
    end)
end

-- Notify all players for a new tp zone
local function notifyNewTeleportZone(teleportZone)
    TriggerClientEvent("esx_teleportbuilder:newZone", -1, teleportZone)
end

-- Player request all zones
RegisterNetEvent("esx_teleportbuilder:requestZones", function()
    local _src <const> = source
    TriggerClientEvent("esx_teleportbuilder:cbZones", _src, teleportZones)
end)

-- Admin register new tp zone
RegisterNetEvent("esx_teleportbuilder:registerTp", function(builder)
    local _src <const> = source
    local xPlayer <const> = ESX.GetPlayerFromId(_src)

    if (xPlayer.getGroup() ~= "superadmin") then
        TriggerClientEvent("esx:showNotification", _src, "Vous n'avez pas la permission de faire cette action")
        return
    end
    if (not (validateTpBuilder(builder))) then
        TriggerClientEvent("esx:showNotification", _src, "Une erreur est survenue dans la création de la zone")
        return
    end
    registerTeleportZone(builder, function(success)
        TriggerClientEvent("esx:showNotification", _src, success and "Zone de téléportation ~g~crée" or "Une ~r~erreur~s~ est survenue dans la création de la zone de téléportation")
        notifyNewTeleportZone(builder)
    end)
end)

CreateThread(function()
    MySQL.Async.fetchAll("SELECT * FROM esx_teleportbuilder", {}, function(rows)
        if (not (rows) or #rows <= 0) then
            return
        end

        for _, row in pairs(rows) do
            local data <const> = json.decode(row.data)
            data.point_a.coords.position = vector3(data.point_a.coords.position.x, data.point_a.coords.position.y, data.point_a.coords.position.z)
            data.point_b.coords.position = vector3(data.point_b.coords.position.x, data.point_b.coords.position.y, data.point_b.coords.position.z)
            table.insert(teleportZones, data)
        end

        print(("Loaded ^3%i^7 teleportation zone(s)"):format(#rows))
    end)
end)