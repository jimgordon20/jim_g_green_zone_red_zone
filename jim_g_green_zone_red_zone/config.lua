Config = {}
Config.Debug = false -- debug

Config.CustomImage = true                      -- Use custom images (true) or notifications (false)
Config.UIPosition = { x = "20px", y = "20%" }  -- Where the zone icon shows up on screen

Config.GreenzoneImageURL = "https://r2.fivemanage.com/4ZTsDUlMX4ILwiPceeveN/image/greenzone.png" -- greenzone image url
Config.RedzoneImageURL = "https://r2.fivemanage.com/4ZTsDUlMX4ILwiPceeveN/image/redzone.png"     -- redzone image url

-- Define your zones here, each one needs its own settings
Config.Zones = {
    Greenzone = {
        points = {
            vec3(290.35, -551.51, 43.19),
            vec3(267.15, -607.57, 42.63),
            vec3(320.09, -626.62, 29.29),
            vec3(328.12, -612.63, 29.29),
            vec3(361.94, -624.42, 28.94),
            vec3(376.6, -599.06, 28.62),
            vec3(394.23, -571.8, 28.53),
            vec3(420.15, -536.02, 28.67)
        },
        thickness = 20,
        type = "Greenzone",
        maxSpeed = 15.0,
        enterMessage = "You’re in a safe Greenzone now!",
        exitMessage = "Leaving the Greenzone, watch out!",
        restrictions = {
            allowGuns = false,
            allowDeath = false,
            allowGodMode = true,
            jobExceptions = { ["police"] = true, ["sheriff"] = true }
        },
        enabled = true
    },
    Redzone = {
        points = {
            vec3(349.17, -644.42, 29.28),
            vec3(335.43, -678.25, 29.32),
            vec3(363.35, -686.63, 29.27),
            vec3(364.43, -683.52, 29.19),
            vec3(367.31, -681.96, 29.19),
            vec3(372.15, -681.18, 29.18),
            vec3(377.48, -682.06, 29.26),
            vec3(384.31, -668.15, 29.27),
            vec3(380.86, -665.11, 29.18),
            vec3(378.15, -661.03, 29.17),
            vec3(376.89, -656.67, 29.16),
            vec3(376.8, -652.3, 29.23),
            vec3(377.56, -647.17, 29.22),
            vec3(381.52, -637.65, 29.02),
            vec3(388.44, -623.01, 28.97),
            vec3(395.97, -609.73, 28.82),
            vec3(386.15, -604.58, 28.85),
            vec3(380.67, -614.06, 28.98),
            vec3(375.55, -623.68, 29.0),
            vec3(369.62, -637.48, 29.15),
            vec3(356.96, -632.1, 29.08)
        },
        thickness = 10,
        type = "Redzone",
        enterMessage = "Welcome to the wild Redzone!",
        exitMessage = "You made it out of the Redzone!",
        enabled = true
    }
}