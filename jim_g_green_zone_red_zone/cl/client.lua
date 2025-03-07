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

-- Show or hide
local function updateUI(zoneType)
    if not UseCustomImage then return end
    if zoneType == "Greenzone" and Config.GreenzoneImageURL then
        SendNUIMessage({ action = "show", image = Config.GreenzoneImageURL, debug = DebugMode })
        debug("Showing Greenzone image")
    elseif zoneType == "Redzone" and Config.RedzoneImageURL then
        SendNUIMessage({ action = "show", image = Config.RedzoneImageURL, debug = DebugMode })
        debug("Showing Redzone image")
    else
        SendNUIMessage({ action = "hide", debug = DebugMode })
        debug("Hiding zone image")
    end
    SendNUIMessage({ action = "setPosition", x = UIPosition.x, y = UIPosition.y, debug = DebugMode })
end

-- Handle zone rules
local function applyRules(zoneType, entering)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local job = Bridge.Framework.GetPlayerJob(PlayerId())[1]

    if zoneType == "Greenzone" then
        local restrictions = Zones[zoneType].restrictions or {}
        local exempt = restrictions.jobExceptions and restrictions.jobExceptions[job]

        if entering then
            if not restrictions.allowGuns and not exempt then
                DisablePlayerFiring(ped, true)
                SetPlayerCanDoDriveBy(ped, false)
            end
            if restrictions.allowGodMode and not restrictions.allowDeath then
                SetEntityInvincible(ped, true)
            end
            SetVehicleMaxSpeed(vehicle, Zones[zoneType].maxSpeed or 0.0)
            debug("Greenzone rules on")
            if UseCustomImage then
                updateUI("Greenzone")
            else
                Bridge.Notify.SendNotify(Zones[zoneType].enterMessage or "In Greenzone!", "success", 5000)
            end
        else
            if not restrictions.allowGuns and not exempt then
                DisablePlayerFiring(ped, false)
                SetPlayerCanDoDriveBy(ped, true)
            end
            if restrictions.allowGodMode and not restrictions.allowDeath then
                SetEntityInvincible(ped, false)
            end
            SetVehicleMaxSpeed(vehicle, 0.0)
            debug("Greenzone rules off")
            if UseCustomImage then
                updateUI(nil)
            else
                Bridge.Notify.SendNotify(Zones[zoneType].exitMessage or "Out of Greenzone!", "info", 5000)
            end
        end
    elseif zoneType == "Redzone" then
        if entering then
            DisablePlayerFiring(ped, false)
            SetPlayerCanDoDriveBy(ped, true)
            SetEntityInvincible(ped, false)
            SetVehicleMaxSpeed(vehicle, 0.0)
            debug("Redzone rules on")
            if UseCustomImage then
                updateUI("Redzone")
            else
                Bridge.Notify.SendNotify(Zones[zoneType].enterMessage or "In Redzone!", "error", 5000)
            end
        else
            debug("Redzone rules off")
            if UseCustomImage then
                updateUI(nil)
            else
                Bridge.Notify.SendNotify(Zones[zoneType].exitMessage or "Out of Redzone!", "info", 5000)
            end
        end
    end
end

-- Sync zones
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
        zone:remove()
    end
    ActiveZones = {}
    for name, data in pairs(Zones) do
        if data.enabled then
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
        else
            debug("Skipped " .. name .. " (disabled)")
        end
    end
end)

RegisterNetEvent('community_bridge:Client:OnPlayerLoaded')
AddEventHandler('community_bridge:Client:OnPlayerLoaded', function()
    TriggerServerEvent('community_bridge:Server:OnPlayerLoaded', GetPlayerServerId(PlayerId()))
end)
