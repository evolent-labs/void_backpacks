local Config = require 'config'
local existingStashes = {}

local ox_inventory = exports.ox_inventory

local function useBackpack(event, _, inventory, slot, _)
    if event ~= 'usingItem' then return end

    local progressBar = lib.callback.await('openingBackpack', inventory.id)
    if not progressBar then return end

    local backpack = ox_inventory:GetSlot(inventory.id, slot)
    if not backpack.metadata.bagId then return end

    if not existingStashes[backpack.metadata.bagId] then
        local bag = Config.Bags[backpack.name]

        ox_inventory:RegisterStash(('backpack_%s'):format(backpack.metadata.bagId), 'Bag', bag.slots, bag.maxWeight)
        existingStashes[backpack.metadata.bagId] = true
    end

    TriggerClientEvent('ox_inventory:openInventory', inventory.id, 'stash', ('backpack_%s'):format(backpack.metadata.bagId))
end
exports('useBackpack', useBackpack)

local backpacks, itemFilter = {}, {}
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for bag, _ in pairs(Config.Bags) do
        backpacks[#backpacks + 1] = bag
        itemFilter[bag] = true
    end
    for item, value in pairs(Config.BlacklistedItems) do
        itemFilter[item] = value
    end

    ox_inventory:registerHook('createItem', function(payload)
        if not Config.Bags[payload.item.name] then return end
        local metadata = payload.metadata

        if tonumber(payload.inventoryId) then
            Player(payload.inventoryId).state.carryBag = payload.item.name
        end

        local uniqueId = GetGameTimer() .. math.random(10000, 99999)
        metadata.bagId = uniqueId

        return metadata
    end, {
        itemFilter = itemFilter
    })

    ox_inventory:registerHook('buyItem', function(payload)
        if not Config.Bags[payload.itemName] or Config.AllowMultipleBags then return true end

        local bagCount = ox_inventory:Search(payload.toInventory, 'count', backpacks)
        if bagCount > 0 then return false end
    end, {
        itemFilter = itemFilter
    })

    ox_inventory:registerHook('swapItems', function(payload)
        local source = payload.fromInventory
        local targetSource = payload.toInventory

        if source == targetSource then return true end

        if payload.action ~= 'move' then return end

        if payload.fromType == 'player' then
            if string.find(payload.toInventory, 'backpack_') then return false end

            local bagCount = ox_inventory:Search(source, 'count', backpacks) - 1
            if bagCount < 1 then Player(source).state.carryBag = false end
        end

        if payload.toType == 'player' then
            if Config.Bags[payload.fromSlot.name] then
                local targetBagCount = ox_inventory:Search(targetSource, 'count', backpacks)
                if not Config.AllowMultipleBags and targetBagCount > 0 then return false end
    
                Player(targetSource).state.carryBag = payload.fromSlot.name
            end
        end

        return true
    end, {
        itemFilter = itemFilter
    })
end)

AddEventHandler('onServerResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ox_inventory:removeHooks()
end)


local framework = GetConvar('inventory:framework', 'ox')

local function initItemCheck(source)
    if not source then return end

    local bags = ox_inventory:Search(source, 'slots', backpacks)
    Player(source).state.carryBag = bags[1]?.name or false
end

local function resetState(source)
    if not source then return end
    Player(source).state.carryBag = false
end

if framework == 'qb' then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
        local _source = source
        -- Wait 1 second because the ped reloads when spawning for some reason
        SetTimeout(1000, function()
            initItemCheck(_source)
        end)
    end)
    RegisterNetEvent('QBCore:Server:OnPlayerUnload', resetState)
end

if framework == 'ox' then
    AddEventHandler('ox:playerLoaded', initItemCheck)
    AddEventHandler('ox:playerLogout', resetState)
end

if framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', initItemCheck)
    RegisterNetEvent('esx:playerDropped', resetState)
end
