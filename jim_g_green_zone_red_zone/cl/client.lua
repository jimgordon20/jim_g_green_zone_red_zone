local Bridge = exports.community_bridge:Bridge()
local Zones = {}
local UseCustomImage = true
local DebugMode = false
local ActiveZones = {}
local UIPosition = { x = "20px", y = "20%" }
local lastDebug = 0

local function debug(msg)
    if DebugMode and GetGameTimer() - lastDebug > 1000 then
        Bridge.Prints.Debug(msg)
        lastDebug = GetGameTimer()
    end
end

local function updateUI(zoneType)
    if not UseCustomImage then return end
    local msg = {}
    if zoneType == "Greenzone" and Config.GreenzoneImageURL then
        msg = { action = "show", image = Config.GreenzoneImageURL }
        debug("Showing Greenzone image")
    elseif zoneType == "Redzone" and Config.RedzoneImageURL then
        msg = { action = "show", image = Config.RedzoneImageURL }
        debug("Showing Redzone image")
    else
        msg = { action = "hide" }
        debug("Hiding zone image")
    end
    SendNUIMessage(msg)
    SendNUIMessage({ action = "setPosition", x = UIPosition.x, y = UIPosition.y })
end

-- Apply zone rules
local function applyRules(zoneType, entering)
    local ped = cache.ped or PlayerPedId()
    local job = Bridge.Framework.GetPlayerJob(cache.player or PlayerId())[1]

    if zoneType == "Greenzone" then
        local restrictions = Zones[zoneType].restrictions or {}
        local exempt = restrictions.jobExceptions and restrictions.jobExceptions[job]

        if entering then
            if not restrictions.allowGuns and not exempt and cache.weapon then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                debug("Disarmed in Greenzone")
            end
            if restrictions.allowGodMode and not restrictions.allowDeath then
                SetEntityInvincible(ped, true)
            end
            if cache.vehicle then
                SetVehicleMaxSpeed(cache.vehicle, Zones[zoneType].maxSpeed or 0.0)
            end
            debug("Greenzone rules on")
            if UseCustomImage then updateUI("Greenzone")
            else Bridge.Notify.SendNotify(Zones[zoneType].enterMessage or "In Greenzone!", "success", 5000) end
        else
            if not restrictions.allowGuns and not exempt and cache.weapon then
                SetCurrentPedWeapon(ped, cache.weapon, true)
                debug("Re-armed leaving Greenzone")
            end
            if restrictions.allowGodMode and not restrictions.allowDeath then
                SetEntityInvincible(ped, false)
            end
            if cache.vehicle then
                SetVehicleMaxSpeed(cache.vehicle, 0.0)
            end
            debug("Greenzone rules off")
            if UseCustomImage then updateUI(nil)
            else Bridge.Notify.SendNotify(Zones[zoneType].exitMessage or "Out of Greenzone!", "info", 5000) end
        end
    elseif zoneType == "Redzone" then
        if entering then
            if cache.weapon then
                SetCurrentPedWeapon(ped, cache.weapon, true)
            end
            SetEntityInvincible(ped, false)
            if cache.vehicle then
                SetVehicleMaxSpeed(cache.vehicle, 0.0)
            end
            debug("Redzone rules on")
            if UseCustomImage then updateUI("Redzone")
            else Bridge.Notify.SendNotify(Zones[zoneType].enterMessage or "In Redzone!", "error", 5000) end
        else
            debug("Redzone rules off")
            if UseCustomImage then updateUI(nil)
            else Bridge.Notify.SendNotify(Zones[zoneType].exitMessage or "Out of Redzone!", "info", 5000) end
        end
    end
end

-- Sync zones from server
RegisterNetEvent('Jim_G_Green_Red_Zone:SyncZones')
AddEventHandler('Jim_G_Green_Red_Zone:SyncZones', function(zoneData, customImage, debugOn, uiPos)
    Zones = zoneData
    UseCustomImage = customImage
    DebugMode = debugOn
    UIPosition = uiPos

    debug("Got zones: " .. json.encode(Zones))
    debug("Custom images: " .. tostring(UseCustomImage))
    debug("Debug: " .. tostring(DebugMode))
    debug("UI at x=" .. uiPos.x .. ", y=" .. uiPos.y)
    if DebugMode then
        Bridge.Notify.SendNotify("Zones are up and running!", "info", 5000)
    end

    for name, zone in pairs(ActiveZones) do
        if not Zones[name] or not Zones[name].enabled then
            zone:remove()
            ActiveZones[name] = nil
            debug("Removed zone: " .. name)
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


RegisterNetEvent('community_bridge:Client:OnPlayerLoaded')
AddEventHandler('community_bridge:Client:OnPlayerLoaded', function()
    TriggerServerEvent('community_bridge:Server:OnPlayerLoaded', GetPlayerServerId(PlayerId()))
end)


lib.onCache('vehicle', function(value, oldValue)
    if not value and oldValue then
        debug("Left vehicle, resetting speed")
        SetVehicleMaxSpeed(oldValue, 0.0)
    end
end)


lib.onCache('weapon', function(value, oldValue)
    if Zones["Greenzone"] and Zones["Greenzone"].restrictions and not Zones["Greenzone"].restrictions.allowGuns then
        local ped = cache.ped or PlayerPedId()
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        debug("Forced unarmed in Greenzone")
    end
end)
