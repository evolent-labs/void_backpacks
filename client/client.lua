local Config = require 'config'

local function progressCircle()
    return lib.progressCircle({
        duration = Config.OpenDuration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
    })
end
lib.callback.register('openingBackpack', progressCircle)

local currentBag
AddStateBagChangeHandler('carryBag', ('player:%s'):format(cache.serverId), function(_, _, value)
    currentBag = value == 'inveh' and currentBag or value

    if not value or value == 'inveh' then
        return SetPedComponentVariation(cache.ped, 5, 0, 0, 0)
    end

    local bagInfo = Config.Bags[value]
    if not bagInfo then return end
    if bagInfo.clothing then
        local gender = IsPedModel(cache.ped, 'mp_f_freemode_01') and 'female' or 'male'
    
        if gender == 'male' then
            SetPedComponentVariation(cache.ped, 5, bagInfo.clothing.MaleDrawableId, bagInfo.clothing.MaleTextureId, 0)
        else
            SetPedComponentVariation(cache.ped, 5, bagInfo.clothing.FemaleDrawableId, bagInfo.clothing.FemaleTextureId, 0)
        end
    end
end)

lib.onCache('vehicle', function(veh)
    if veh then LocalPlayer.state.carryBag = 'inveh' end
    if not veh then LocalPlayer.state.carryBag = currentBag end
end)
