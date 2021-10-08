# qb-weapons
All Credits to go to the original qbcore-framework repository


## [W.I.P] Adding ammo to database [W.I.P]
<!-- 
- Be sure to also import the playerammo.sql provided

- You can also just add the line of code below to your "weapons:server:AddWeaponAmmo" event in qb-weapons/server/main.lua

    ```
    exports.oxmysql:insert('INSERT INTO playerammo (citizenid, ammo) VALUES (?, ?)',{Player.PlayerData.citizenid,amount})
    ```

- should look like this:

```RegisterServerEvent("weapons:server:AddWeaponAmmo")
AddEventHandler('weapons:server:AddWeaponAmmo', function(CurrentWeaponData, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = tonumber(amount) 
    
    exports.oxmysql:insert('INSERT INTO playerammo (citizenid, ammo) VALUES (?, ?)',{Player.PlayerData.citizenid,amount})
    
    if CurrentWeaponData ~= nil then
        if Player.PlayerData.items[CurrentWeaponData.slot] ~= nil then
            Player.PlayerData.items[CurrentWeaponData.slot].info.ammo = amount 
        end
        Player.Functions.SetInventory(Player.PlayerData.items, true)
    end
end)
``` -->

