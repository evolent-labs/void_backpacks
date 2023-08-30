-- Add this to ox_inventory/data/items.lua
['backpack'] = {
    label = 'Backpack',
    weight = 5000,
    stack = false,
    consume = 0,
    server = {
        export = 'void_backpacks.useBackpack'
    }
},