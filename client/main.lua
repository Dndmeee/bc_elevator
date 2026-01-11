-- bc_elevator
-- Copyright (c) 2026 Dndmee
-- Licensed under Custom Non-Commercial License

local isOpen = false
local currentElevator = nil
local lastUse = 0
local lastPanelCoords = nil
local lastFloorId = nil

-- FUNCTIONS
local function getPlayerJob()
    local data = exports.qbx_core:GetPlayerData()
    if data and data.job and data.job.name then
        return data.job.name
    end
    return "unemployed"
end

local function isNearPanel()
    if not lastPanelCoords then return false end
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    return #(pcoords - lastPanelCoords) <= Config.MaxUseDistance
end

local function getClosestFloorId(elevatorKey)
    local elevator = Config.Elevators[elevatorKey]
    if not elevator then return nil end

    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)

    local closest = nil
    local closestDist = 999999.0

    for _, floor in ipairs(elevator.floors) do
        local dist = #(pcoords - vec3(floor.coords.x, floor.coords.y, floor.coords.z))
        if dist < closestDist then
            closestDist = dist
            closest = floor.id
        end
    end

    return closest
end

local function openUI(elevatorKey, panelCoords)
    local now = GetGameTimer()

    if now - lastUse < Config.CooldownMs then
        lib.notify({
            title = "Elevator",
            description = "Please wait a moment...",
            type = "error"
        })
        return
    end

    if Config.UseDistanceCheck then
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        if #(pcoords - panelCoords) > Config.MaxUseDistance then
            lib.notify({
                title = "Elevator",
                description = "You are too far from the elevator panel.",
                type = "error"
            })
            return
        end
    end

    lastUse = now
    isOpen = true
    currentElevator = elevatorKey
    lastPanelCoords = panelCoords

    local elevator = Config.Elevators[elevatorKey]
    local closestFloorId = lastFloorId or getClosestFloorId(elevatorKey)
    local jobName = getPlayerJob()

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "open",
        elevator = {
            key = elevatorKey,
            label = elevator.label,
            floors = elevator.floors,
            currentFloorId = closestFloorId,
            job = jobName
        }
    })
end

local function closeUI()
    isOpen = false
    currentElevator = nil
    lastPanelCoords = nil

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

local function playTravelSequence(travelTime)
    local ped = PlayerPedId()

    RequestAnimDict("anim@apt_trans@buzzer")
    while not HasAnimDictLoaded("anim@apt_trans@buzzer") do Wait(0) end

    TaskPlayAnim(ped, "anim@apt_trans@buzzer", "buzz_reg", 8.0, -8.0, 1500, 49, 0, false, false, false)
    Wait(800)

    lib.progressBar({
        duration = travelTime,
        label = 'Elevator moving...',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true }
    })
end

local function playSoundDing()
    if not Config.UseSounds then return end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

CreateThread(function()
    for key, data in pairs(Config.Elevators) do
        for i, panel in ipairs(data.panels) do
            exports.ox_target:addBoxZone({
                coords = panel.coords,
                size = panel.size,
                rotation = panel.heading,
                debug = Config.Debug,
                options = {
                    {
                        name = ("elevator_%s_%s"):format(key, i),
                        icon = "fa-solid fa-elevator",
                        label = ("Use Elevator (%s)"):format(data.label),
                        onSelect = function()
                            openUI(key, panel.coords)
                        end
                    }
                }
            })
        end
    end
end)

-- NUI callbacks
RegisterNUICallback("close", function(_, cb)
    closeUI()
    cb("ok")
end)

RegisterNUICallback("selectFloor", function(data, cb)
    if not currentElevator then cb("fail") return end

    if Config.UseDistanceCheck and not isNearPanel() then
        lib.notify({
            title = "Elevator",
            description = "You moved too far from the elevator panel.",
            type = "error"
        })
        closeUI()
        cb("fail")
        return
    end

    TriggerServerEvent("bc_elevator:requestFloor", currentElevator, data.floorId)
    cb("ok")
end)

-- CLIENT EVENT
RegisterNetEvent("bc_elevator:deny", function(reason)
    lib.notify({
        title = "Elevator",
        description = reason or "Access denied.",
        type = "error"
    })
end)

RegisterNetEvent("bc_elevator:travel", function(floor, travelTime)
    if not floor or not floor.coords then return end

    lastFloorId = floor.id
    closeUI()

    playTravelSequence(travelTime or 2500)

    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(0) end
    Wait(400)

    local ped = PlayerPedId()
    SetEntityCoords(ped, floor.coords.x, floor.coords.y, floor.coords.z, false, false, false, false)
    SetEntityHeading(ped, floor.coords.w)

    Wait(350)
    DoScreenFadeIn(800)

    playSoundDing()

    lib.notify({
        title = "Elevator",
        description = ("You arrived at %s"):format(floor.label),
        type = "success"
    })
end)
