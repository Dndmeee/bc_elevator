local lastFloorByPlayer = {}
local lastRequestAt = {}

local function findFloor(elevator, floorId)
    for _, floor in ipairs(elevator.floors) do
        if floor.id == floorId then
            return floor
        end
    end
    return nil
end

local function getDefaultFloor(elevator)
    return elevator.floors[1]
end

local function isJobAllowed(floor, jobName)
    if not floor.allowedJobs then return true end
    for _, job in ipairs(floor.allowedJobs) do
        if job == jobName then return true end
    end
    return false
end

local function isNearAnyPanel(src, elevator)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local pcoords = GetEntityCoords(ped)
    local maxDist = (Config.MaxUseDistance or 3.0) + 0.75

    for _, panel in ipairs(elevator.panels or {}) do
        local dx = pcoords.x - panel.coords.x
        local dy = pcoords.y - panel.coords.y
        local dz = pcoords.z - panel.coords.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

        if dist <= maxDist then
            return true
        end
    end

    return false
end

RegisterNetEvent("bc_elevator:requestFloor", function(elevatorKey, floorId)
    local src = source

    local now = os.clock()
    if lastRequestAt[src] and (now - lastRequestAt[src]) < 1.5 then
        TriggerClientEvent("bc_elevator:deny", src, "Please wait a moment...")
        return
    end
    lastRequestAt[src] = now

    if type(elevatorKey) ~= "string" or type(floorId) ~= "string" then
        TriggerClientEvent("bc_elevator:deny", src, "Invalid request.")
        return
    end

    local elevator = Config.Elevators[elevatorKey]
    if not elevator then
        TriggerClientEvent("bc_elevator:deny", src, "Elevator not found.")
        return
    end
    if Config.UseDistanceCheck and not isNearAnyPanel(src, elevator) then
        TriggerClientEvent("bc_elevator:deny", src, "You must be near the elevator panel.")
        return
    end

    local targetFloor = findFloor(elevator, floorId)
    if not targetFloor then
        TriggerClientEvent("bc_elevator:deny", src, "Floor not found.")
        return
    end

    local jobName = "unemployed"
    if exports.qbx_core then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name then
            jobName = player.PlayerData.job.name
        end
    end

    if not isJobAllowed(targetFloor, jobName) then
        TriggerClientEvent("bc_elevator:deny", src, "You do not have access to this floor.")
        return
    end

    local last = lastFloorByPlayer[src]
    if last == targetFloor.id then
        TriggerClientEvent("bc_elevator:deny", src, "You are already on this floor.")
        return
    end

    local fromFloor = last and findFloor(elevator, last) or getDefaultFloor(elevator)
    local fromOrder = (fromFloor and fromFloor.order) or 1
    local toOrder = targetFloor.order or 1

    local diff = math.abs(toOrder - fromOrder)
    local travelTime = (Config.BaseTravelTime or 1600) + (diff * (Config.TravelTimePerFloor or 1200))

    lastFloorByPlayer[src] = targetFloor.id

    TriggerClientEvent("bc_elevator:travel", src, elevatorKey, targetFloor.id, travelTime)
end)

AddEventHandler("playerDropped", function()
    local src = source
    lastFloorByPlayer[src] = nil
    lastRequestAt[src] = nil
end)
