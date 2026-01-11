local RESOURCE_NAME = GetCurrentResourceName()
local GITHUB_OWNER = "Dndmeee"
local GITHUB_REPO = "bc_elevator"

local CHECK_INTERVAL = 6 * 60 * 60 * 1000

local function normalizeVersion(v)
    if not v then return nil end
    v = tostring(v)
    v = v:gsub("^v", "")
    v = v:gsub("%s+", "")
    return v
end

local function splitVersion(v)
    v = normalizeVersion(v)
    if not v then return nil end
    local major, minor, patch = v:match("^(%d+)%.(%d+)%.(%d+)$")
    if not major then
        major, minor = v:match("^(%d+)%.(%d+)$")
        patch = "0"
    end
    if not major then return nil end
    return tonumber(major), tonumber(minor), tonumber(patch)
end

local function isNewer(remote, localv)
    local r1, r2, r3 = splitVersion(remote)
    local l1, l2, l3 = splitVersion(localv)
    if not r1 or not l1 then return false end

    if r1 ~= l1 then return r1 > l1 end
    if r2 ~= l2 then return r2 > l2 end
    return r3 > l3
end

local function getLocalVersion()
    local v = GetResourceMetadata(RESOURCE_NAME, "version", 0)
    return normalizeVersion(v) or "0.0.0"
end

local function checkVersionOnce()
    local localVersion = getLocalVersion()
    local url = ("https://api.github.com/repos/%s/%s/releases/latest"):format(GITHUB_OWNER, GITHUB_REPO)

    PerformHttpRequest(url, function(status, body, headers)
        if status ~= 200 or not body or body == "" then
            print(("[^3%s^7] Version check failed (HTTP %s)."):format(RESOURCE_NAME, tostring(status)))
            return
        end

        local ok, data = pcall(function()
            return json.decode(body)
        end)

        if not ok or type(data) ~= "table" then
            print(("[^3%s^7] Version check failed (invalid JSON)."):format(RESOURCE_NAME))
            return
        end

        local remoteTag = data.tag_name
        local remoteVersion = normalizeVersion(remoteTag)
        local releaseUrl = data.html_url or ("https://github.com/%s/%s/releases"):format(GITHUB_OWNER, GITHUB_REPO)

        if not remoteVersion then
            print(("[^3%s^7] Version check failed (missing tag_name)."):format(RESOURCE_NAME))
            return
        end

        if isNewer(remoteVersion, localVersion) then
            print(("[^1%s^7] Update available! Current: ^3%s^7 | Latest: ^2%s^7"):format(RESOURCE_NAME, localVersion, remoteVersion))
            print(("[^1%s^7] Download: ^5%s^7"):format(RESOURCE_NAME, releaseUrl))
        else
            print(("[^2%s^7] Up to date. Version: ^3%s^7"):format(RESOURCE_NAME, localVersion))
        end
    end, "GET", "", {
        ["User-Agent"] = ("FiveM/%s"):format(RESOURCE_NAME),
        ["Accept"] = "application/vnd.github+json"
    })
end

CreateThread(function()
    Wait(2500)
    checkVersionOnce()

    while true do
        Wait(CHECK_INTERVAL)
        checkVersionOnce()
    end
end)
