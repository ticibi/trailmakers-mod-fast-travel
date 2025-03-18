-- Fast Travel Mod for Trailmakers
-- Author: ticibi
-- Description: Create, share, and teleport to saved coordinates and other players

local playerDataTable = {}
local pointsTable = {}
local pointIdIndex = 1

-- Constants
local UI_SPACER = ""
local UI_DIVIDER = "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"

-- Point Management
local Point = {
    new = function(playerId, name, pos)
        local point = {
            id = pointIdIndex,
            name = name,
            pos = pos,
            owner = playerId,
            shared = false
        }
        pointIdIndex = pointIdIndex + 1
        return point
    end
}

-- Utility Functions
local function formatVector(vector)
    return string.format("x: %d, y: %d, z: %d", 
        math.ceil(vector.x), 
        math.ceil(vector.y), 
        math.ceil(vector.z))
end

local function isEmpty(list)
    return #list < 1
end

local function getPlayerPos(playerId)
    return tm.players.GetPlayerTransform(playerId).GetPosition()
end

-- Data Management
local function getPointById(pointId)
    for _, point in ipairs(pointsTable) do
        if point.id == pointId then
            return point
        end
    end
    return nil
end

local function getPlayerPoints(playerId)
    local points = {}
    for _, point in ipairs(pointsTable) do
        if point.owner == playerId then
            table.insert(points, point)
        end
    end
    return points
end

local function getSharedPoints()
    local points = {}
    for _, point in ipairs(pointsTable) do
        if point.shared then
            table.insert(points, point)
        end
    end
    return points
end

-- UI Helper Functions
local UI = {
    clear = function(playerId) tm.playerUI.ClearUI(playerId) end,
    setValue = function(playerId, key, text) tm.playerUI.SetUIValue(playerId, key, text) end,
    spacer = function(playerId) tm.playerUI.AddUILabel(playerId, "spacer", UI_SPACER) end,
    label = function(playerId, key, text) tm.playerUI.AddUILabel(playerId, key, text) end,
    divider = function(playerId) tm.playerUI.AddUILabel(playerId, "divider", UI_DIVIDER) end,
    button = function(playerId, key, text, func) tm.playerUI.AddUIButton(playerId, key, text, func) end,
    text = function(playerId, key, text, func) tm.playerUI.AddUIText(playerId, key, text, func) end
}

-- Player Management
local function initPlayerData(playerId)
    playerDataTable[playerId] = {
        points = {},
        pointName = ""
    }
end

tm.players.OnPlayerJoined.add(function(player)
    initPlayerData(player.playerId)
    HomePage(player.playerId)
end)

-- UI Pages
function HomePage(playerId)
    if type(playerId) ~= "number" then playerId = playerId.playerId end
    
    local playerPoints = getPlayerPoints(playerId)
    local sharedPoints = getSharedPoints()
    
    UI.clear(playerId)
    UI.button(playerId, "players", "Teleport to Player", PlayersPage)
    UI.button(playerId, "add_point", "Add New Point", OnCreateNewPoint)
    
    if not isEmpty(playerPoints) then
        UI.label(playerId, "my_points", "My Points")
        UI.divider(playerId)
        for _, point in ipairs(playerPoints) do
            UI.button(playerId, tostring(point.id), point.name, PointDetailsPage)
        end
    end
    
    if not isEmpty(sharedPoints) then
        UI.label(playerId, "shared_points", "Shared Points")
        UI.divider(playerId)
        for _, point in ipairs(sharedPoints) do
            UI.button(playerId, tostring(point.id), point.name, OnTeleportToSharedPoint)
        end
    end
end

function PlayersPage(callback)
    UI.clear(callback.playerId)
    UI.label(callback.playerId, "players", "Select a Player")
    UI.divider(callback.playerId)
    
    for _, player in ipairs(tm.players.CurrentPlayers()) do
        if player.playerId ~= callback.playerId then -- Don't show self in list
            UI.button(callback.playerId, tostring(player.playerId), 
                tm.players.GetPlayerName(player.playerId), GoToPlayer)
        end
    end
    UI.button(callback.playerId, "back", "Back", HomePage)
end

function PointDetailsPage(callback)
    local pointId = tonumber(callback.id)
    local point = getPointById(pointId)
    if not point then return HomePage(callback.playerId) end
    
    UI.clear(callback.playerId)
    UI.label(callback.playerId, "point_name", point.name)
    UI.label(callback.playerId, "point_pos", formatVector(point.pos))
    UI.divider(callback.playerId)
    UI.button(callback.playerId, "go_"..point.id, "Teleport", GoToPoint)
    UI.button(callback.playerId, "edit_"..point.id, "Update Position", ChangePointPosition)
    UI.button(callback.playerId, "share_"..point.id, 
        point.shared and "Unshare" or "Share", OnToggleSharePoint)
    UI.button(callback.playerId, "delete_"..point.id, "Delete", OnDeletePoint)
    UI.button(callback.playerId, "back", "Back", HomePage)
end

function OnCreateNewPoint(callback)
    UI.clear(callback.playerId)
    UI.label(callback.playerId, "edit_point", "Name Your Point")
    UI.text(callback.playerId, "new_point", "", OnEditPointName)
    UI.button(callback.playerId, "save_point", "Save", OnSavePoint)
end

-- Action Handlers
function OnEditPointName(callback)
    playerDataTable[callback.playerId].pointName = callback.value
end

function OnSavePoint(callback)
    local playerData = playerDataTable[callback.playerId]
    local name = playerData.pointName:match("^%s*(.-)%s*$") -- Trim whitespace
    
    if not name or name == "" then
        UI.setValue(callback.playerId, "save_point", "Name cannot be empty!")
        return
    end
    
    local newPoint = Point.new(callback.playerId, name, getPlayerPos(callback.playerId))
    table.insert(pointsTable, newPoint)
    playerData.pointName = ""
    HomePage(callback.playerId)
end

function GoToPoint(callback)
    local pointId = tonumber(callback.id:match("%d+"))
    local point = getPointById(pointId)
    if point then
        tm.players.GetPlayerTransform(callback.playerId).SetPosition(point.pos)
    end
    HomePage(callback.playerId)
end

function ChangePointPosition(callback)
    local pointId = tonumber(callback.id:match("%d+"))
    local point = getPointById(pointId)
    if point then
        point.pos = getPlayerPos(callback.playerId)
        UI.setValue(callback.playerId, "point_pos", formatVector(point.pos))
    end
end

function OnToggleSharePoint(callback)
    local pointId = tonumber(callback.id:match("%d+"))
    local point = getPointById(pointId)
    if point then
        point.shared = not point.shared
    end
    PointDetailsPage(callback)
end

function OnDeletePoint(callback)
    local pointId = tonumber(callback.id:match("%d+"))
    for i, point in ipairs(pointsTable) do
        if point.id == pointId then
            table.remove(pointsTable, i)
            break
        end
    end
    HomePage(callback.playerId)
end

function OnTeleportToSharedPoint(callback)
    local pointId = tonumber(callback.id)
    local point = getPointById(pointId)
    if point then
        tm.players.GetPlayerTransform(callback.playerId).SetPosition(point.pos)
    end
end

function GoToPlayer(callback)
    local targetId = tonumber(callback.id)
    local pos = getPlayerPos(targetId)
    tm.players.GetPlayerTransform(callback.playerId).SetPosition(pos)
    HomePage(callback.playerId)
end
