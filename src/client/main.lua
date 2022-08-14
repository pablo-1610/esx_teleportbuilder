local teleportZones = {}

local xPlayer

local active = false
local teleporting = false

local mainMenu <const> = RageUI.CreateMenu("Teleport builder", "Créez vos zones de téléportation")
local builderMenu <const> = RageUI.CreateSubMenu(mainMenu, "Customisation du tp", "Créez la zone de téléportation")

local builder = {
    point_a = {},
    point_b = {}
}

local function valueOrDefine(value)
    return (value ~= nil and ("~g~%s"):format(value) or "~y~Définir")
end

local function valueOrToDefine(value)
    return (value ~= nil and "~g~Défini" or "~y~Définir")
end

local function teleport(dest)
    local tpCoords = vector3(dest.position.x, dest.position.y, dest.position.z - 0.98)

    if (teleporting) then
        return
    end
    teleporting = true
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(1)
    end
    Wait(500)
    SetEntityCoords(PlayerPedId(), tpCoords)
    SetEntityHeading(PlayerPedId(), dest.heading)
    Wait(200)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do
        Wait(1)
    end
    teleporting = false
end

mainMenu.Closed = function()
    active = false
end

RegisterCommand("teleportbuilder", function()
    if (active) then
        return
    end
    if (xPlayer.group ~= "superadmin") then
        ESX.ShowNotification("Vous n'avez pas la permission de faire cette commande !")
        return
    end
    active = true
    RageUI.Visible(mainMenu, true)
    CreateThread(function()
        while (active) do
            RageUI.IsVisible(mainMenu, function()
                RageUI.Separator("Gérer vos zones de tp")
                RageUI.Button("Créer une zone de téléportation", "Cliquez pour créer une nouvelle zone", { RightLabel = "→" }, true, {}, builderMenu)
            end)

            RageUI.IsVisible(builderMenu, function()
                RageUI.Separator("Customisation de la zone de tp")
                RageUI.Button("Nom Point A:", nil, { RightLabel = valueOrDefine(builder.point_a.label) }, true, {
                    onSelected = function()
                        local label = keyboard("Nom du point", "", 50, false)
                        if (label) then
                            builder.point_a.label = label
                        end
                    end
                })
                RageUI.Button("Nom Point B:", nil, { RightLabel = valueOrDefine(builder.point_b.label) }, true, {
                    onSelected = function()
                        local label = keyboard("Nom du point", "", 50, false)
                        if (label) then
                            builder.point_b.label = label
                        end
                    end
                })
                RageUI.Button(("Point A: %s"):format(valueOrToDefine(builder.point_a.coords)), nil, { RightBadge = RageUI.BadgeStyle.Star }, true, {
                    onSelected = function()
                        builder.point_a.coords = { position = GetEntityCoords(PlayerPedId()), heading = GetEntityHeading(PlayerPedId()) }
                    end
                })
                RageUI.Button(("Point B: %s"):format(valueOrToDefine(builder.point_b.coords)), nil, { RightBadge = RageUI.BadgeStyle.Star }, true, {
                    onSelected = function()
                        builder.point_b.coords = { position = GetEntityCoords(PlayerPedId()), heading = GetEntityHeading(PlayerPedId()) }
                    end
                })
                RageUI.Separator("Actions")
                RageUI.Button("Créer ma zone de téléportation", nil, { RightBadge = RageUI.BadgeStyle.Tick }, validateTpBuilder(builder), {
                    onSelected = function()
                        if (not (validateTpBuilder(builder))) then
                            return
                        end
                        TriggerServerEvent("esx_teleportbuilder:registerTp", builder)
                        RageUI.CloseAll()
                        active = false
                    end
                })
            end)

            Wait(0)
        end
    end)
end)

local function invokeZones()
    while (true) do
        local interval = 500

        if (not (teleporting)) then
            local playerCoords <const> = GetEntityCoords(PlayerPedId())

            for _, teleportZone in pairs(teleportZones) do
                local pApos <const> = teleportZone.point_a.coords.position
                local pBpos <const> = teleportZone.point_b.coords.position

                -- Point A
                local dist = #(playerCoords - pApos)
                if (dist <= 10) then
                    interval = 0
                    DrawMarker(25, pApos.x, pApos.y, (pApos.z - 0.98), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 255, false, true, 2, false, false, false, false)
                    if (dist <= 1) then
                        ESX.ShowHelpNotification(teleportZone.point_b.label and ("Appuyez sur ~INPUT_CONTEXT~ pour aller jusqu'à ~y~%s"):format(teleportZone.point_b.label) or "Appuyez sur ~INPUT_CONTEXT~ pour vous téléporter")
                        if (IsControlJustPressed(0, 51)) then
                            teleport(teleportZone.point_b.coords)
                        end
                    end
                end

                -- Point B
                dist = #(playerCoords - pBpos)
                if (dist <= 10) then
                    interval = 0
                    DrawMarker(25, pBpos.x, pBpos.y, (pBpos.z - 0.98), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 255, false, true, 2, false, false, false, false)
                    if (dist <= 1) then
                        ESX.ShowHelpNotification(teleportZone.point_a.label and ("Appuyez sur ~INPUT_CONTEXT~ pour aller jusqu'à ~y~%s"):format(teleportZone.point_a.label) or "Appuyez sur ~INPUT_CONTEXT~ pour vous téléporter")
                        if (IsControlJustPressed(0, 51)) then
                            teleport(teleportZone.point_a.coords)
                        end
                    end
                end
            end
        end

        Wait(interval)
    end
end


-- Get back zones from server
RegisterNetEvent("esx_teleportbuilder:cbZones", function(zones)
    teleportZones = zones
    invokeZones()
end)

-- Get a new zone from the server
RegisterNetEvent("esx_teleportbuilder:newZone", function(zone)
    table.insert(teleportZones, zone)
end)

SetTimeout(1500, function()
    xPlayer = ESX.GetPlayerData()
    TriggerServerEvent("esx_teleportbuilder:requestZones")
end)

