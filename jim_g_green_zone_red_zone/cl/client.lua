local Bridge = exports.community_bridge:Bridge()
local Zones = {}
local UseCustomImage = true
local DebugMode = false
local ActiveZones = {}
local UIPosition = { x = "20px", y = "20%" }
local lastDebug = 0
local inGreenzone = false

-- Throttled debug print
local function debug(msg)
    if DebugMode and GetGameTimer() - lastDebug > 1000 then
        Bridge.Prints.Debug(msg)
        lastDebug = GetGameTimer()
    end
end

-- Update UI for zones
local function updateUI(zoneType)
    if not UseCustomImage then return end
    local msg = zoneType == "Greenzone" and Config.GreenzoneImageURL and { action = "show", image = Config.GreenzoneImageURL }
             or zoneType == "Redzone" and Config.RedzoneImageURL and { action = "show", image = Config.RedzoneImageURL }
             or { action = "hide" }
    SendNUIMessage(msg)
    SendNUIMessage({ action = "setPosition", x = UIPosition.x, y = UIPosition.y })
end

-- Apply zone rules
local function applyRules(zoneType, entering)
    local ped = cache.ped or PlayerPedId()
    local jobData = Bridge.Framework.GetPlayerJob(cache.player or PlayerId())
    local job = type(jobData) == "string" and jobData or (jobData and (jobData[1] or jobData.name or jobData.job)) or "unknown"

    if zoneType == "Greenzone" then
        local restrictions = Zones[zoneType].restrictions or {}
        local exempt = restrictions.jobExceptions and job and restrictions.jobExceptions[job]

        inGreenzone = entering
        if not restrictions.allowGuns and not exempt and cache.weapon then
            SetCurrentPedWeapon(ped, entering and `WEAPON_UNARMED` or cache.weapon, true)
        end
        if restrictions.allowGodMode and not restrictions.allowDeath then
            SetEntityInvincible(ped, entering)
        end
        if cache.vehicle then
            SetVehicleMaxSpeed(cache.vehicle, entering and (Zones[zoneType].maxSpeed or 0.0) or 0.0)
        end
        debug(entering and "Greenzone rules on" or "Greenzone rules off")
        if UseCustomImage then updateUI(entering and "Greenzone" or nil)
        else Bridge.Notify.SendNotify(Zones[zoneType][entering and "enterMessage" or "exitMessage"] or (entering and "In Greenzone!" or "Out of Greenzone!"), entering and "success" or "info", 5000) end
    elseif zoneType == "Redzone" then
        if entering then
            inGreenzone = false
            if cache.weapon then SetCurrentPedWeapon(ped, cache.weapon, true) end
            SetEntityInvincible(ped, false)
            if cache.vehicle then SetVehicleMaxSpeed(cache.vehicle, 0.0) end
            debug("Redzone rules on")
            if UseCustomImage then updateUI("Redzone")
            else Bridge.Notify.SendNotify(Zones[zoneType].enterMessage or "In Redzone!", "error", 5000) end
        else
            inGreenzone = false
            debug("Redzone rules off")
            if UseCustomImage then updateUI(nil)
            else Bridge.Notify.SendNotify(Zones[zoneType].exitMessage or "Out of Redzone!", "info", 5000) end
        end
    end
end

-- Sync zones from server
RegisterNetEvent('Jim_G_Green_Red_Zone:SyncZones', function(zoneData, customImage, debugOn, uiPos)
    Zones = zoneData
    UseCustomImage = customImage
    DebugMode = debugOn
    UIPosition = uiPos

    if DebugMode then
        Bridge.Notify.SendNotify("Zones are up and running!", "info", 5000)
    end

    for name, zone in pairs(ActiveZones) do
        if not Zones[name] or not Zones[name].enabled then
            zone:remove()
            ActiveZones[name] = nil
        end
    end

    for name, data in pairs(Zones) do
        if data.enabled and not ActiveZones[name] then
            ActiveZones[name] = lib.zones.poly({
                points = data.points,
                thickness = data.thickness,
                debug = DebugMode,
                onEnter = function()
                    debug("Entered " .. name .. " (" .. data.type .. ")")
                    applyRules(data.type, true)
                end,
                onExit = function()
                    debug("Exited " .. name .. " (" .. data.type .. ")")
                    applyRules(data.type, false)
                end
            })
        end
    end
end)

-- Player loaded, request zones
RegisterNetEvent('community_bridge:Client:OnPlayerLoaded', function()
    TriggerServerEvent('community_bridge:Server:OnPlayerLoaded', GetPlayerServerId(PlayerId()))
end)

-- React to vehicle changes
lib.onCache('vehicle', function(value, oldValue)
    if not value and oldValue then
        SetVehicleMaxSpeed(oldValue, 0.0)
    end
end)

-- React to weapon changes
lib.onCache('weapon', function(value, oldValue)
    if inGreenzone and Zones["Greenzone"] then
        local restrictions = Zones["Greenzone"].restrictions or {}
        local jobData = Bridge.Framework.GetPlayerJob(cache.player or PlayerId())
        local job = type(jobData) == "string" and jobData or (jobData and (jobData[1] or jobData.name or jobData.job)) or "unknown"
        if not restrictions.allowGuns and not (restrictions.jobExceptions and job and restrictions.jobExceptions[job]) and value then
            SetCurrentPedWeapon(cache.ped or PlayerPedId(), `WEAPON_UNARMED`, true)
        end
    end
end)
