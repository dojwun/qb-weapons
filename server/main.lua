
local QBCore = exports['qb-core']:GetCoreObject()


local WeaponAmmo = {}

QBCore.Functions.CreateCallback("weapons:server:GetConfig", function(source, cb)
    cb(Config.WeaponRepairPoints)
end)

RegisterServerEvent("weapons:server:AddWeaponAmmo")
AddEventHandler('weapons:server:AddWeaponAmmo', function(CurrentWeaponData, amount, weapon)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = tonumber(amount)
    
    local weaponInfo = QBCore.Shared.Weapons[weapon]
    local serieNumber = nil
    if weaponInfo ~= nil then 
        local weaponItem = Player.Functions.GetItemByName(weaponInfo["name"])
        if weaponItem ~= nil then
            if weaponItem.info ~= nil and  weaponItem.info ~= "" then 
                serieNumber = weaponItem.info.serie
            end
        end
    end

    if CurrentWeaponData ~= nil then 
        exports.oxmysql:insert('INSERT INTO playerammo (citizenid, ammo, serial_number) VALUES (?, ?, ?)',{Player.PlayerData.citizenid, amount,serieNumber})
        if Player.PlayerData.items[CurrentWeaponData.slot] ~= nil then
            Player.PlayerData.items[CurrentWeaponData.slot].info.ammo = amount 
        end
        Player.Functions.SetInventory(Player.PlayerData.items, true)
    end
end)


RegisterServerEvent("weapons:server:UpdateWeaponAmmo")
AddEventHandler('weapons:server:UpdateWeaponAmmo', function(CurrentWeaponData, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = tonumber(amount)

    if CurrentWeaponData ~= nil then
        exports.oxmysql:execute('UPDATE playerammo SET ammo = ? WHERE citizenid= ?', {amount, Player.PlayerData.citizenid})
        if Player.PlayerData.items[CurrentWeaponData.slot] ~= nil then
            Player.PlayerData.items[CurrentWeaponData.slot].info.ammo = amount
        end
        Player.Functions.SetInventory(Player.PlayerData.items, true)
    end
end)

-- RegisterServerEvent("weapons:server:AddWeaponAmmo")
-- AddEventHandler('weapons:server:AddWeaponAmmo', function(CurrentWeaponData, amount, weapon)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     local amount = tonumber(amount)

--     if CurrentWeaponData ~= nil then
--         exports.oxmysql:fetch('SELECT * FROM playerammo WHERE serial_number = ?', {Player.PlayerData.items[CurrentWeaponData.slot].info.serie}, function(result)
--             if result[1] == nil then
--                 exports.oxmysql:insert('INSERT INTO playerammo (citizenid, ammo, serial_number) VALUES (?, ?, ?)',{Player.PlayerData.citizenid, amount, Player.PlayerData.items[CurrentWeaponData.slot].info.serie})
--             else
--                 exports.oxmysql:execute('UPDATE playerammo SET ammo = ? WHERE serial_number= ?', {amount, Player.PlayerData.items[CurrentWeaponData.slot].info.serie})
--             end
--         end)

--         if Player.PlayerData.items[CurrentWeaponData.slot] ~= nil then
--             Player.PlayerData.items[CurrentWeaponData.slot].info.ammo = amount 
--         end
--         Player.Functions.SetInventory(Player.PlayerData.items, true)
--     end
-- end)

-- RegisterServerEvent("weapons:server:UpdateWeaponAmmo")
-- AddEventHandler('weapons:server:UpdateWeaponAmmo', function(CurrentWeaponData, amount)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     local amount = tonumber(amount)

--     if CurrentWeaponData ~= nil then

--         exports.oxmysql:fetch('SELECT * FROM playerammo WHERE serial_number = ?', {Player.PlayerData.items[CurrentWeaponData.slot].info.serie}, function(result)
--             if result[1] ~= nil then
--                 exports.oxmysql:execute('UPDATE playerammo SET ammo = ? WHERE serial_number= ?', {amount, Player.PlayerData.items[CurrentWeaponData.slot].info.serie})
--             else
--                 exports.oxmysql:insert('INSERT INTO playerammo (citizenid, ammo, serial_number) VALUES (?, ?, ?)',{Player.PlayerData.citizenid, amount, Player.PlayerData.items[CurrentWeaponData.slot].info.serie})
--             end
--         end)
        
--         if Player.PlayerData.items[CurrentWeaponData.slot] ~= nil then
--             Player.PlayerData.items[CurrentWeaponData.slot].info.ammo = amount
--         end
--         Player.Functions.SetInventory(Player.PlayerData.items, true)
--     end
-- end)

QBCore.Functions.CreateCallback("weapon:server:GetWeaponAmmo", function(source, cb, WeaponData)
    local Player = QBCore.Functions.GetPlayer(source)
    local retval = 0
    if WeaponData ~= nil then
        if Player ~= nil then
            local ItemData = Player.Functions.GetItemBySlot(WeaponData.slot)
            if ItemData ~= nil then
                retval = ItemData.info.ammo ~= nil and ItemData.info.ammo or 0
                print("Retrived "..retval.." Bullets for "..GetPlayerName(source).." CID: "..Player.PlayerData.citizenid)
            end
        end
    end
    cb(retval)
end)

function IsWeaponBlocked(WeaponName)
    local retval = false
    for _, name in pairs(Config.DurabilityBlockedWeapons) do
        if name == WeaponName then
            retval = true
            break
        end 
    end
    return retval
end

RegisterServerEvent('weapons:server:UpdateWeaponQuality')
AddEventHandler('weapons:server:UpdateWeaponQuality', function(data, RepeatAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local WeaponData = QBCore.Shared.Weapons[GetHashKey(data.name)]
    local WeaponSlot = Player.PlayerData.items[data.slot]
    local DecreaseAmount = Config.DurabilityMultiplier[data.name]

    if WeaponSlot ~= nil then
        if not IsWeaponBlocked(WeaponData.name) then
            if WeaponSlot.info.quality ~= nil then
                for i = 1, RepeatAmount, 1 do
                    if WeaponSlot.info.quality - DecreaseAmount > 0 then
                        WeaponSlot.info.quality = WeaponSlot.info.quality - DecreaseAmount
                    else
                        WeaponSlot.info.quality = 0
                        TriggerClientEvent('inventory:client:UseWeapon', src, data)
                        TriggerClientEvent('QBCore:Notify', src, "Your weapon is broken, you need to repair it before you can use it again.", "error")
                        break
                    end
                end
            else
                WeaponSlot.info.quality = 100
                for i = 1, RepeatAmount, 1 do
                    if WeaponSlot.info.quality - DecreaseAmount > 0 then
                        WeaponSlot.info.quality = WeaponSlot.info.quality - DecreaseAmount
                    else
                        WeaponSlot.info.quality = 0
                        TriggerClientEvent('inventory:client:UseWeapon', src, data)
                        TriggerClientEvent('QBCore:Notify', src, "Your weapon is broken, you need to repair it before you can use it again.", "error")
                        break
                    end
                end
            end
        end
    end

    Player.Functions.SetInventory(Player.PlayerData.items, true)
end)

RegisterServerEvent('weapons:server:UpdateItemQuality')
AddEventHandler('weapons:server:UpdateItemQuality', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ItemSlot = Player.PlayerData.items[data.slot]
    local DecreaseAmount = Config.DurabilityMultiplier[data.name]
    local date = os.time(os.date("!*t"))
    print("weapons:server:UpdateItemQuality")

    if Config.DurabilityMultiplier[data.name] ~= nil then
        if ItemSlot.info.quality ~= nil then
            if ItemSlot.info.quality - DecreaseAmount > 0 then
                ItemSlot.info.quality = ItemSlot.info.quality - DecreaseAmount / ItemSlot.amount
            else
                ItemSlot.info.quality = 0
                TriggerClientEvent('inventory:client:UseItem', src, data)
                TriggerClientEvent('QBCore:Notify', src, "Your item is broken and cant be used..", "error")
            end
        end
    end
    Player.Functions.SetInventory(Player.PlayerData.items)
end)


RegisterServerEvent("weapons:server:SetWeaponQuality")
AddEventHandler("weapons:server:SetWeaponQuality", function(data, hp)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local WeaponData = QBCore.Shared.Weapons[GetHashKey(data.name)]
    local WeaponSlot = Player.PlayerData.items[data.slot]
    local DecreaseAmount = Config.DurabilityMultiplier[data.name]
    WeaponSlot.info.quality = hp
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end)

RegisterServerEvent("weapons:server:SetItemQuality")
AddEventHandler("weapons:server:SetItemQuality", function(data, hp)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local itemSlot = Player.Functions.GetItemBySlot(slot)
    local DecreaseAmount = Config.DurabilityMultiplier[data.name]
    itemSlot = slot
    itemSlot.info.quality = hp
    print("weapons:server:SetItemQuality")
    Player.Functions.SetInventory(Player.PlayerData.items)
end)


QBCore.Functions.CreateCallback("weapons:server:RepairWeapon", function(source, cb, RepairPoint, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local minute = 60 * 1000
    local Timeout = math.random(5 * minute, 10 * minute)
    local WeaponData = QBCore.Shared.Weapons[GetHashKey(data.name)]
    local WeaponClass = (QBCore.Shared.SplitStr(WeaponData.ammotype, "_")[2]):lower()

    if Player.PlayerData.items[data.slot] ~= nil then
        if Player.PlayerData.items[data.slot].info.quality ~= nil then
            if Player.PlayerData.items[data.slot].info.quality ~= 100 then
                if Player.Functions.RemoveMoney('cash', Config.WeaponRepairCotsts[WeaponClass]) then
                    Config.WeaponRepairPoints[RepairPoint].IsRepairing = true
                    Config.WeaponRepairPoints[RepairPoint].RepairingData = {
                        CitizenId = Player.PlayerData.citizenid,
                        WeaponData = Player.PlayerData.items[data.slot],
                        Ready = false,
                    }
                    Player.Functions.RemoveItem(data.name, 1, data.slot)
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.name], "remove", 1)
                    TriggerClientEvent("inventory:client:CheckWeapon", src, data.name)
                    TriggerClientEvent('weapons:client:SyncRepairShops', -1, Config.WeaponRepairPoints[RepairPoint], RepairPoint)

                    SetTimeout(Timeout, function()
                        Config.WeaponRepairPoints[RepairPoint].IsRepairing = false
                        Config.WeaponRepairPoints[RepairPoint].RepairingData.Ready = true
                        TriggerClientEvent('weapons:client:SyncRepairShops', -1, Config.WeaponRepairPoints[RepairPoint], RepairPoint)
                        TriggerEvent('qb-phone:server:sendNewMailToOffline', Player.PlayerData.citizenid, {
                            sender = "Tyrone",
                            subject = "Repair",
                            message = "Your "..WeaponData.label.." is repaired u can pick it up at the location. <br><br> Peace out madafaka"
                        })
                        SetTimeout(7 * 60000, function()
                            if Config.WeaponRepairPoints[RepairPoint].RepairingData.Ready then
                                Config.WeaponRepairPoints[RepairPoint].IsRepairing = false
                                Config.WeaponRepairPoints[RepairPoint].RepairingData = {}
                                TriggerClientEvent('weapons:client:SyncRepairShops', -1, Config.WeaponRepairPoints[RepairPoint], RepairPoint)
                            end
                        end)
                    end)
                    cb(true)
                else
                    cb(false)
                end
            else
                TriggerClientEvent("QBCore:Notify", src, "This weapon is not dammaged..", "error")
                cb(false)
            end
        else
            TriggerClientEvent("QBCore:Notify", src, "This weapon is not dammaged..", "error")
            cb(false)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have a weapon in your hands..", "error")
        TriggerClientEvent('weapons:client:SetCurrentWeapon', src, {}, false)
        cb(false)
    end
end)

RegisterServerEvent("weapons:server:TakeBackWeapon")
AddEventHandler("weapons:server:TakeBackWeapon", function(k, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local itemdata = Config.WeaponRepairPoints[k].RepairingData.WeaponData

    itemdata.info.quality = 100
    Player.Functions.AddItem(itemdata.name, 1, false, itemdata.info)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemdata.name], "add")
    Config.WeaponRepairPoints[k].IsRepairing = false
    Config.WeaponRepairPoints[k].RepairingData = {}
    TriggerClientEvent('weapons:client:SyncRepairShops', -1, Config.WeaponRepairPoints[k], k)
end)

function HasAttachment(component, attachments)
    local retval = false
    local key = nil
    for k, v in pairs(attachments) do
        if v.component == component then
            key = k
            retval = true
        end
    end
    return retval, key
end

function GetAttachmentItem(weapon, component)
    local retval = nil
    for k, v in pairs(WeaponAttachments[weapon]) do
        if v.component == component then
            retval = v.item
        end
    end
    return retval
end

function GetAttachmentType(attachments)
    local attype = nil
    for k,v in pairs(attachments) do
        attype = v.type
    end
    return attype
end

RegisterServerEvent("weapons:server:EquipAttachment")
AddEventHandler("weapons:server:EquipAttachment", function(ItemData, CurrentWeaponData, AttachmentData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Inventory = Player.PlayerData.items
    local GiveBackItem = nil
    if Inventory[CurrentWeaponData.slot] ~= nil then
        if Inventory[CurrentWeaponData.slot].info.attachments ~= nil and next(Inventory[CurrentWeaponData.slot].info.attachments) ~= nil then
            local currenttype = GetAttachmentType(Inventory[CurrentWeaponData.slot].info.attachments)
            local HasAttach, key = HasAttachment(AttachmentData.component, Inventory[CurrentWeaponData.slot].info.attachments)
            if not HasAttach then
                if AttachmentData.type ~=nil and currenttype == AttachmentData.type then
                    for k, v in pairs(Inventory[CurrentWeaponData.slot].info.attachments) do
                        if v.type ~= nil and v.type == currenttype then
                            GiveBackItem = tostring(v.item):lower()
                            table.remove(Inventory[CurrentWeaponData.slot].info.attachments, key)
                            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[GiveBackItem], "add")
                        end
                    end
                end
                table.insert(Inventory[CurrentWeaponData.slot].info.attachments, {
                    component = AttachmentData.component,
                    label = AttachmentData.label,
                    item = AttachmentData.item,
                    type = AttachmentData.type,
                })
                TriggerClientEvent("addAttachment", src, AttachmentData.component)
                Player.Functions.SetInventory(Player.PlayerData.items, true)
                Player.Functions.RemoveItem(ItemData.name, 1)
                SetTimeout(1000, function()
                    TriggerClientEvent('inventory:client:ItemBox', src, ItemData, "remove", 1)
                end)
            else
                TriggerClientEvent("QBCore:Notify", src, "You already have a "..AttachmentData.label:lower().." on your weapon.", "error", 3500)
            end
        else
            Inventory[CurrentWeaponData.slot].info.attachments = {}
            table.insert(Inventory[CurrentWeaponData.slot].info.attachments, {
                component = AttachmentData.component,
                label = AttachmentData.label,
                item = AttachmentData.item,
                type = AttachmentData.type,
            })
            TriggerClientEvent("addAttachment", src, AttachmentData.component)
            Player.Functions.SetInventory(Player.PlayerData.items, true)
            Player.Functions.RemoveItem(ItemData.name, 1)
            SetTimeout(1000, function()
                TriggerClientEvent('inventory:client:ItemBox', src, ItemData, "remove", 1)
            end)
        end
    end
    if GiveBackItem ~= nil then
        Player.Functions.AddItem(GiveBackItem, 1, false)
        GiveBackItem = nil
    end
end)

QBCore.Functions.CreateCallback('weapons:server:RemoveAttachment', function(source, cb, AttachmentData, ItemData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Inventory = Player.PlayerData.items
    local AttachmentComponent = WeaponAttachments[ItemData.name:upper()][AttachmentData.attachment]

    if Inventory[ItemData.slot] ~= nil then
        if Inventory[ItemData.slot].info.attachments ~= nil and next(Inventory[ItemData.slot].info.attachments) ~= nil then
            local HasAttach, key = HasAttachment(AttachmentComponent.component, Inventory[ItemData.slot].info.attachments)
            if HasAttach then
                table.remove(Inventory[ItemData.slot].info.attachments, key)
                Player.Functions.SetInventory(Player.PlayerData.items, true)
                Player.Functions.AddItem(AttachmentComponent.item, 1, slot, {["quality"] = 100})
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[AttachmentComponent.item], "add", 1)
                TriggerClientEvent("QBCore:Notify", src, "You removed "..AttachmentComponent.label.." from your weapon!", "error")
                cb(Inventory[ItemData.slot].info.attachments)
            else
                cb(false)
            end
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

