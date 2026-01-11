Config = {}

Config.Debug = false
Config.UseDistanceCheck = true
Config.MaxUseDistance = 3.0
Config.CooldownMs = 2500
Config.TravelTimePerFloor = 1200
Config.BaseTravelTime = 1600
Config.UseSounds = true

Config.Elevators = {
    ["pillbox"] = {
        label = "Pillbox Hospital",

        panels = {
            {
                coords = vec3(344.73, -584.73, 29.08),
                size = vec3(1.2, 1.2, 2.2),
                heading = 340.0
            },
            {
                coords = vec3(331.96, -597.20, 43.57),
                size = vec3(1.2, 1.2, 2.2),
                heading = 250.0
            },
            {
                coords = vec3(338.28, -583.71, 74.53),
                size = vec3(1.2, 1.2, 2.2),
                heading = 250.0
            },
        },

        floors = {
            {
                id = "lobby_ground",
                label = "Ground Lobby (Floor 1)",
                order = 1,
                coords = vec4(344.3240, -586.1917, 28.7969, 246.9200),
            },
            {
                id = "lobby_upper",
                label = "UG Lobby (Floor 2)",
                order = 2,
                coords = vec4(332.2609, -595.6669, 43.2841, 66.3077),
            },
            {
                id = "helipad_hospital",
                label = "Helipad",
                order = 3,
                coords = vec4(338.4799, -583.9127, 74.1617, 259.0762),
                allowedJobs = { "ambulance" }
            },
        }
    },
}
