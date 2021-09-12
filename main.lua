-- Fast Travel teleport mod
-- by dinoman 2021

-- add teleport to players

local playerDataTable = {}

function addPlayerData(playerId)
    playerDataTable[playerId] = {
        name = tm.players.GetPlayerName(playerId),
        savedPoints = {},
        lastPos = nil,
        newPointData = {name=nil, coords=nil, home=false},
        homePoint = {name=nil, coords=nil},
    }
end

function onPlayerJoined(player)
    local playerId = player.playerId
    addPlayerData(playerId)
    createUI(playerId)
end

function update()
    local playerList = tm.players.CurrentPlayers()
    for k, player in pairs(playerList) do
        --
    end
end

function createUI(playerId)
    mainPage(playerId)
    --tm.input.RegisterFunctionToKeyDownCallback(playerId, "teleportToHome", "backspace")
end

function returnMainPage(callbackData)
    mainPage(callbackData.playerId)
end

function spacer(playerId)
    tm.playerUI.AddUILabel(playerId, "spacer", "")
end

function mainPage(playerId)
    local playerData = playerDataTable[playerId]
    tm.playerUI.ClearUI(playerId)
    tm.playerUI.AddUIButton(playerId, "players", "Teleport to Player", playersPage)
    tm.playerUI.AddUIButton(playerId, "add_point", "Create New Point", editPointPage)
    tm.playerUI.AddUILabel(playerId, "my_points", "My Points")
    if #playerData.savedPoints > 0 then
        for i, point in pairs(playerData.savedPoints) do
            if point.home == true then
                tm.playerUI.AddUIButton(playerId, "point_" .. point.name, "★" .. point.name, pointInfoPage)
            else
                tm.playerUI.AddUIButton(playerId, "point_" .. point.name, point.name, pointInfoPage)
            end
        end
    end
end

function playersPage(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    tm.playerUI.ClearUI(playerId)
    tm.playerUI.AddUILabel(playerId, "players_page", "Teleport to Player")
    for _, player in pairs(tm.players.CurrentPlayers()) do
        tm.playerUI.AddUIButton(playerId, player.playerId, tm.players.GetPlayerName(player.playerId), teleportToPlayer)
    end
    tm.playerUI.AddUIButton(playerId, "back", "Back", returnMainPage)
end

function teleportToPlayer(callbackData)
    local playerId = callbackData.playerId
    local otherPlayerId = tonumber(callbackData.id)
    local otherPlayerPos = tm.players.GetPlayerTransform(otherPlayerId).GetPosition()
    tm.players.GetPlayerTransform(playerId).SetPosition(otherPlayerPos)
    returnMainPage(callbackData)
end

function editPointPage(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    editCoords(playerId)
    tm.playerUI.ClearUI(playerId)
    tm.playerUI.AddUILabel(playerId, "edit_point", "Name your point")
    tm.playerUI.AddUIText(playerId, "point_name", "", editName)
    tm.playerUI.AddUIButton(playerId, "save_point", "Save", addSpawnPoint)
end

function pointInfoPage(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    local pointName = callbackData.value
    local coords = getPointCoordsFromName(playerId, pointName)
    tm.playerUI.ClearUI(playerId)
    tm.playerUI.AddUILabel(playerId, "name", pointName)
    tm.playerUI.AddUILabel(playerId, "coords", formatVector(coords))
    tm.playerUI.AddUIButton(playerId, pointName, "Travel to Point", teleportToPoint)
    spacer(playerId)
    tm.playerUI.AddUIButton(playerId, "ovr_" .. pointName, "Overwrite", overwritePoint)
    tm.playerUI.AddUIButton(playerId, "back", "Back", returnMainPage)
end

function overwritePoint(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    local pointName = callbackData.id:sub(5, #callbackData.id)
    local coords = tm.players.GetPlayerTransform(playerId).GetPosition()
    for i, point in pairs(playerData.savedPoints) do
        if point.name == pointName then
            playerData.savedPoints[i].coords = coords
            tm.playerUI.SetUIValue(playerId, "coords", formatVector(coords))
            tm.playerUI.SetUIValue(playerId, "name", " Updated! " .. pointName)
        end
    end
end

function editName(callbackData)
    local playerId = callbackData.playerId
    playerDataTable[playerId].newPointData.name = callbackData.value
    tm.playerUI.SetUIValue(playerId, "save_point", "Save")
end

function editCoords(playerId)
    local pos = tm.players.GetPlayerTransform(playerId).GetPosition()
    playerDataTable[playerId].newPointData.coords = pos
end

function addSpawnPoint(callbackData)
    local playerId = callbackData.playerId
    local playerData = playerDataTable[playerId]
    if playerData.newPointData.name == "" or playerData.newPointData.name == nil then
        tm.playerUI.SetUIValue(playerId, "save_point", "Must name point")
        return
    else
        tm.playerUI.SetUIValue(playerId, "save_point", "Save")
        table.insert(playerData.savedPoints, {name=playerData.newPointData.name, coords=playerData.newPointData.coords})
        mainPage(playerId)
    end
end

function teleportToPoint(callbackData)
    local playerId = callbackData.playerId
    local transform = tm.players.GetPlayerTransform(playerId)
    local coords = getPointCoordsFromName(playerId, callbackData.id)
    transform.SetPosition(coords)
    mainPage(playerId)
end

function deletePoint(callbackData)
    local playerData = playerDataTable[callbackData.playerId]
    for i, point in pairs(playerData.savedPoints) do
        if point.name == callbackData.value:sub(1, #callbackData.value) then
            table.remove(playerData.savedPoints, i)
            pointInfoPage(callbackData)
        end
    end
end

function getPointCoordsFromName(playerId, pointName)
    local playerData = playerDataTable[playerId]
    for i, point in pairs(playerData.savedPoints) do
        if point.name == pointName then
            return point.coords
        end
    end
end

function getClosestPoint()
    local playerData = playerDataTable[callbackData.playerId]
    local pos = tm.players.GetPlayerTransform(callbackData.playerId).GetPosition()
    local positionsData = {}
    for i, point in pairs(playerData.savedPoints) do
        local coords = point.coords
        local distance = math.abs(tm.vector3.op_Subtraction(pos, coords))
        table.insert(positionsData, {distance=distance, coords=coords, name=point.name})
    end
    local smallestDist = nil
    local smallestData = nil
    for i, item in pairs(positionsData) do
        if smallestDist == nil or item.distance < smallestDist then
            smallestData = item
        end
    end
    if smallestData == nil then
        return
    end
    return smallestData
end

function Log(message)
    tm.os.Log(message)
end

function formatVector(v)
    return fmat(v.x) .. ", " .. fmat(v.y) .. ", " .. fmat(v.z)
end

function fmat(number)
    return string.format("%0.2f", number)
end

tm.players.OnPlayerJoined.add(onPlayerJoined)
