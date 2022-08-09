-- Fast Travel Mod for Trailmakers, ticibi 2022
-- name: Fast Travel
-- author: Thomas Bresee
-- description: create, share, and teleport to saved coordinates and other players


local playerDataTable = {}
local pointsTable = {}
local pointIdIndex = 1

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function AddPoint(playerId, name, pos)
    local pointData = {
        id = pointIdIndex,
        name=name,
        pos=pos,
        owner=playerId,
        shared=false,
    }
    table.insert(pointsTable, pointData)
    pointIdIndex = pointIdIndex + 1
end

function SetPointName(pointId, pointName)
    local point = GetPointById(pointId)
    point.name = pointName
end

function SharePoint(pointId)
    local point = GetPointById(pointId)
    point.shared = true
end

function GetPlayerPoints(playerId)
    local points = {}
    for i, point in ipairs(pointsTable) do
        if point.owner == playerId then
            table.insert(points, point)
        end
    end
    return points
end

function GetPointById(pointId)
    for i, point in ipairs(pointsTable) do
        if point.id == pointId then
            return point
        end
    end
end

function GetSharedPoints()
    local points = {}
    for i, point in ipairs(pointsTable) do
        if point.shared then
            table.insert(points, point)
        end
    end
    return points
end

function AddPlayerData(playerId)
    playerDataTable[playerId] = {
        points = {},
        pointName = "",
    }
end

function onPlayerJoined(player)
    AddPlayerData(player.playerId)
    HomePage(player.playerId)
end

tm.players.OnPlayerJoined.add(onPlayerJoined)

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function SetValue(playerId, key, text)
    tm.playerUI.SetUIValue(playerId, key, text)
end

function Spacer(playerId)
    Label(playerId, "spacer", "")
end

function Clear(playerId)
    tm.playerUI.ClearUI(playerId)
end

function Text(playerId, key, text, func)
    tm.playerUI.AddUIText(playerId, key, text, func)
end

function Label(playerId, key, text)
    tm.playerUI.AddUILabel(playerId, key, text)
end

function Divider(playerId)
    Label(playerId, "divider", "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬")
end

function Button(playerId, key, text, func)
    tm.playerUI.AddUIButton(playerId, key, text, func)
end

function HomePage(playerId)
    if type(playerId) ~= "number" then
        playerId = playerId.playerId
    end
    local playerPoints = GetPlayerPoints(playerId)
    local sharedPoints = GetSharedPoints()
    Clear(playerId)
    Button(playerId, "players", "teleport to player", PlayersPage)
    Button(playerId, "add point", "add new point", OnCreateNewPoint)
    if not isEmpty(playerPoints) then
        Label(playerId, "my points", "my points")
        for i, point in ipairs(playerPoints) do
            Button(playerId, point.id, point.name, PointDetailsPage)
        end
    end
    if not isEmpty(sharedPoints) then
        Label(playerId, "shared points", "shared points")
        for i, point in ipairs(sharedPoints) do
            Button(playerId, point.id, point.name, OnTeleportToSharedPoint)
        end
    end
end

function OnTeleportToSharedPoint(callback)
    local point = GetPointById(tonumber(callback.id))
    SetPlayerPosition(callback.playerId, point.pos)
end

function OnCreateNewPoint(callback)
    Clear(callback.playerId)
    Label(callback.playerId, "edit point", "name your point")
    Text(callback.playerId, "new point", "", OnEditPointName)
    Button(callback.playerId, "save point", "save", OnSavePoint)
end

function OnEditPointName(callback)
    local playerData = playerDataTable[callback.playerId]
    playerData.pointName = callback.value
end

function OnSavePoint(callback)
    local playerData = playerDataTable[callback.playerId]
    if playerData.pointName == "" or playerData.pointName == nil or not playerData.pointName then
        SetValue(callback.playerId, "save point", "you must name the point")
        return
    else
        local playerPos = GetPlayerPos(callback.playerId)
        AddPoint(callback.playerId, playerData.pointName, playerPos)
        playerData.pointName = ""
        HomePage(callback)
    end
end

function PointDetailsPage(callback)
    local pointId = tonumber(callback.id)
    local point = GetPointById(pointId)
    Clear(callback.playerId)
    Label(callback.playerId, "point name", callback.value)
    Label(callback.playerId, "point position", FormatVector(point.pos))
    Button(callback.playerId, "go to "..point.id, "go to point", GoToPoint)
    Button(callback.playerId, "overwrite "..point.id, "overwrite position", ChangePointPosition)
    Button(callback.playerId, "share "..point.id, "share point", OnSharePoint)
    Button(callback.playerId, "back", "back", HomePage)
end

function GoToPoint(callback)
    local pointId = tonumber(string.slice(callback.id, 6))
    local point = GetPointById(pointId)
    SetPlayerPosition(callback.playerId, point.pos)
    HomePage(callback.playerId)
end

function ChangePointPosition(callback)
    local pointId = tonumber(string.slice(callback.id, 10))
    local point = GetPointById(pointId)
    local playerPos = GetPlayerPos(callback.playerId)
    point.pos = playerPos
    SetValue(callback.playerId, "point position", FormatVector(point.pos))
end

function OnSharePoint(callback)
    local pointId = tonumber(string.slice(callback.id, 6))
    SharePoint(pointId)
    HomePage(callback.playerId)
end

function SetPlayerPosition(playerId, pos)
    tm.players.GetPlayerTransform(playerId).SetPosition(pos)
end

function PlayersPage(callback)
    Clear(callback.playerId)
    Label(callback.playerId, "players", "select a player")
    for i, player in ipairs(tm.players.CurrentPlayers()) do
        Button(callback.playerId, player.playerId, tm.players.GetPlayerName(player.playerId), GoToPlayer)
    end
    Button(callback.playerId, "back", "back", HomePage)
end

function GoToPlayer(callback)
    local otherId = tonumber(callback.id)
    local otherPos = GetPlayerPos(otherId)
    SetPlayerPosition(callback.playerId, otherPos)
    HomePage(callback)
end

function OverwritePoint(callback)
    local playerId = callback.playerId
    local playerData = playerDataTable[playerId]
    local pointName = string.slice(callback.id, 10)
    local pos = GetPlayerPos(playerId)
    for i, point in ipairs(playerData.savedPoints) do
        if point.name == pointName then
            playerData.savedPoints[i].pos = pos
            SetValue(playerId, "coords", formatVector(pos))
            SetValue(playerId, "name", " Updated! " .. pointName)
        end
    end
end

function GetPlayerPos(playerId)
    return tm.players.GetPlayerTransform(playerId).GetPosition()
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function FormatVector(vector)
    return 'x: '..math.ceil(vector.x)..', y: '..math.ceil(vector.y)..', z: '..math.ceil(vector.z)
end

function Log(message)
    tm.os.Log(message)
end

function isEmpty(list)
    return #list < 1
end

function string.slice(string, n)
    return string:sub(n, #string)
end
