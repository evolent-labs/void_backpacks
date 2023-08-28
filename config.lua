local Config = {}

Config.AllowMultipleBags = false
Config.OpenDuration = 4000

Config.Bags = {
    backpack--[[ Item name ]] = {
        clothing = {
            MaleDrawableId = 82,
            MaleTextureId = 0,
            FemaleDrawableId = 82,
            FemaleTextureId = 0,
        },
        slots = 20,
        maxWeight = 50000
    }
}

return Config
