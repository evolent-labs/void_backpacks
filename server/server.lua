local Config = require 'config'

local ox_inventory = exports.ox_inventory

local function newBackpack(payload)
    local backpackName = payload.item?.name or payload.itemName or payload.fromSlot?.name or 'none'
    if not Config.Bags[backpackName] then return end

    local playerId = payload.inventoryId or payload.toInventory
    Player(playerId).state.carryBag = backpackName
end

local function getBackpackCount(data)
    local count = 0
    if type(data) == 'table' then
        for _, amount in pairs(data) do
            count += amount
        end
    else
        count = data
    end

    return count
end

local backpacks, itemFilter = {}, {}
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for bag, _ in pairs(Config.Bags) do
        backpacks[#backpacks + 1] = bag
        itemFilter[bag] = true
    end

    ox_inventory:registerHook('createItem', newBackpack, {
        itemFilter = itemFilter
    })

    ox_inventory:registerHook('buyItem', function(payload)
        if not Config.Bags[payload.itemName] or Config.AllowMultipleBags then return true end

        local bags = ox_inventory:Search(payload.toInventory, 'count', backpacks)
        if getBackpackCount(bags) > 0 then return false end    
    end, {
        itemFilter = itemFilter
    })

    ox_inventory:registerHook('swapItems', function(payload)
        if payload.fromInventory == payload.toInventory then return true end

        if payload.fromType == 'player' then
            local bags = ox_inventory:Search(payload.fromInventory, 'count', backpacks)
            if getBackpackCount(bags) - 1 < 1 then Player(payload.fromInventory).state.carryBag = false end
        end

        if payload.toType == 'player' then
            local bags = ox_inventory:Search(payload.toInventory, 'count', backpacks)
            if not Config.AllowMultipleBags and getBackpackCount(bags) > 0 then return false end

            newBackpack(payload)
        end

        return true
    end, {
        itemFilter = itemFilter
    })

    ox_inventory:registerHook('openInventory', function(payload)
        local backpack = ox_inventory:GetSlot(payload.source, payload.slot)
        if not Config.Bags[backpack.name] then return end

        local progressCircle = lib.callback.await('openingBackpack', payload.source)
        if not progressCircle then return false end

        return true
    end, {
        typeFilter = {
            container = true
        }
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
        -- Wait 2 seconds because the ped reloads when spawning for some reason
        SetTimeout(2000, function()
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
