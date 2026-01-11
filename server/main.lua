local lastFloorByPlayer = {}

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
    if not floor.allowedJobs then
        return true
    end

    for _, job in ipairs(floor.allowedJobs) do
        if job == jobName then
            return true
        end
    end

    return false
end

RegisterNetEvent("bc_elevator:requestFloor", function(elevatorKey, floorId)
    local src = source

    if type(elevatorKey) ~= "string" or type(floorId) ~= "string" then
        TriggerClientEvent("bc_elevator:deny", src, "Invalid request.")
        return
    end

    local elevator = Config.Elevators[elevatorKey]
    if not elevator then
        TriggerClientEvent("bc_elevator:deny", src, "Elevator not found.")
        return
    end

    local targetFloor = findFloor(elevator, floorId)
    if not targetFloor then
        TriggerClientEvent("bc_elevator:deny", src, "Floor not found.")
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    local jobName = "unemployed"

    if player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name then
        jobName = player.PlayerData.job.name
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
    local travelTime = Config.BaseTravelTime + (diff * Config.TravelTimePerFloor)

    lastFloorByPlayer[src] = targetFloor.id

    TriggerClientEvent("bc_elevator:travel", src, {
        id = targetFloor.id,
        label = targetFloor.label,
        coords = {
            x = targetFloor.coords.x,
            y = targetFloor.coords.y,
            z = targetFloor.coords.z,
            w = targetFloor.coords.w,
        }
    }, travelTime)
end)

AddEventHandler("playerDropped", function()
    local src = source
    lastFloorByPlayer[src] = nil
end)
