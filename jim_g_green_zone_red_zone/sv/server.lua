local Bridge = exports.community_bridge:Bridge()
local cachedZones = nil

-- Sync zones
local function syncZones(player)
    if not cachedZones then
        cachedZones = Config.Zones
    end
    TriggerClientEvent('Jim_G_Green_Red_Zone:SyncZones', player, cachedZones, Config.CustomImage, Config.Debug, Config.UIPosition)
    if Config.Debug then
        Bridge.Prints.Debug("Sent zone data to player " .. player)
    end
    Bridge.Prints.Info("Player " .. player .. " got their zones synced")
end

-- Player joins
RegisterNetEvent('community_bridge:Server:OnPlayerLoaded')
AddEventHandler('community_bridge:Server:OnPlayerLoaded', function(src)
    syncZones(src)
end)

-- Player leaves
RegisterNetEvent('community_bridge:Server:OnPlayerUnload')
AddEventHandler('community_bridge:Server:OnPlayerUnload', function(src)
    if Config.Debug then
        Bridge.Prints.Debug("Player " .. src .. " dropped from zone system")
    end
    Bridge.Prints.Info("Player " .. src .. " unloaded")
end)