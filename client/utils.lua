local lib = lib
math = lib.math

local GetPedBoneCoords = GetPedBoneCoords
local DrawLine = DrawLine
local DrawSphere = DrawSphere
local IsControlJustPressed = IsControlJustPressed
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextProportional = SetTextProportional
local SetTextColour = SetTextColour
local SetTextEntry = SetTextEntry
local SetTextCentre = SetTextCentre
local AddTextComponentString = AddTextComponentString
local SetDrawOrigin = SetDrawOrigin
local EndTextCommandDisplayText = EndTextCommandDisplayText
local DrawRect = DrawRect
local ClearDrawOrigin = ClearDrawOrigin


local initialCast = false
local secondCast = false
local initalCoords = nil
local secondCoords = nil

local utils = {}

local function RGB(str)
    local r, g, b = str:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    return { x = tonumber(r), y = tonumber(g), z = tonumber(b) }
end

--- draws a line from the player to the hit position on the raycast
function utils.drawToCoords()
    if initialCast then return end
    initialCast = true

    lib.hideTextUI()
    lib.showTextUI('[E] - Copiar posição inicial', {
        position = "right-center",
    })

    CreateThread(function() 
        while initialCast do
            local hit, _, coords, _, _ = lib.raycast.cam(1, 4, 10)
            
            if hit then
                local playerHeadCoords = GetPedBoneCoords(cache.ped, 31086, 0, 0, 0)
                DrawLine(playerHeadCoords.x, playerHeadCoords.y, playerHeadCoords.z, coords.x, coords.y, coords.z, 29, 21, 237, 255)
                DrawSphere(coords.x, coords.y, coords.z, 0.05, 29, 21, 237, 0.85)

                if IsControlJustPressed(0, 38) then
                    initalCoords = coords
                    lib.hideTextUI()
                    initialCast = false
                    utils.drawFromInitial()
                end
            end
        end
    end)
end

--- draws a line from the initial position to the second position
function utils.drawFromInitial()
    if secondCast then return end
    secondCast = true

    lib.hideTextUI()
    lib.showTextUI('[E] - Copiar segunda opção', {
        position = "right-center",
    })

    CreateThread(function() 
        while secondCast do
            local hit, _, coords, _, _ = lib.raycast.cam(1, 4, 10)
            
            if hit then
                DrawLine(initalCoords.x, initalCoords.y, initalCoords.z, coords.x, coords.y, coords.z, 29, 21, 237, 255)
                DrawSphere(coords.x, coords.y, coords.z, 0.05, 29, 21, 237, 0.85)

                if IsControlJustPressed(0, 38) then
                    secondCoords = coords
                    lib.hideTextUI()
                    secondCast = false
                    
                    local input = lib.inputDialog('Nova Iluminação', {
                        {type = 'color', label = 'Cor', format = 'rgb', required = true},
                        {type = 'number', label = 'Distância', icon = 'hashtag', required = true},
                        {type = 'number', label = 'Brilho', icon = 'hashtag', required = true},
                        {type = 'number', label = 'Dureza', icon = 'hashtag', required = true},
                        {type = 'number', label = 'Raio', icon = 'hashtag', required = true},
                    })

                    if not input then return end
                    
                    local rgb = RGB(input[1])
                    local distance = input[2]
                    local brightness = input[3]
                    local hardness = input[4]
                    local radius = input[5]
                    
                    utils.drawNewSpotlight(rgb, distance, brightness, hardness, radius)
                end
            end
        end
    end)
end

---draws a new spotlight with the given data
---@param rgb table
---@param distance number
---@param brightness number
---@param hardness number
---@param radius number
function utils.drawNewSpotlight(rgb, distance, brightness, hardness, radius)
    local direction = secondCoords - initalCoords
    SpotLightData[#SpotLightData+1] = {
        initalCoords = initalCoords,
        secondCoords = secondCoords,
        direction = direction,
        data = {
            rgb = rgb,
            distance = distance,
            brightness = brightness,
            hardness = hardness,
            radius = radius,
        }
    }

    TriggerServerEvent('qw_spotlights:server:sync', SpotLightData)
    initalCoords = nil
    secondCoords = nil
end

---removes the closest spotlight
---@param coords vector3
function utils.removeClosest(coords)
    for i = 1, #SpotLightData do
        local data = SpotLightData[i]
        local distance = #(coords - data.initalCoords)
        if distance < 0.5 then
            table.remove(SpotLightData, i)
            TriggerServerEvent('qw_spotlights:server:sync', SpotLightData)
            return true
        end
    end

    return false
end

---draws 3D text
---@param text string
---@param x number
---@param y number
---@param z number
function utils.draw3DText(text, x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

---draws 3D text at the closest spotlight
---@param coords vector3
function utils.drawAtClosestPoint(coords) 
    for i = 1, #SpotLightData do
        local data = SpotLightData[i]
        local distance = #(coords - data.initalCoords)
        if distance < 0.5 then
            utils.draw3DText('Spotlight', data.initalCoords.x, data.initalCoords.y, data.initalCoords.z)
        end
    end
end

return utils