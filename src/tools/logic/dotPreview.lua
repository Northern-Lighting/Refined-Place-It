local M = {}

local WHITE = 255
local RED = 0

local activeToolId
local targetX
local targetY

local function hasTarget(x, y)
    if Tile.isBuilding(x, y) then
        return true
    end

    for level = 0, 3 do
        if Tile.getRoadDraft(x, y, level) ~= nil then
            return true
        end
    end

    return false
end

local function drawTarget()
    if targetX == nil or targetY == nil then
        return
    end

    if hasTarget(targetX, targetY) then
        Drawing.setColor(WHITE, WHITE, WHITE)
    else
        Drawing.setColor(WHITE, RED, RED)
    end

    Drawing.setTile(targetX, targetY)
    Drawing.drawTileFrame(Icon.TOOLMARK_BLOB)
    Drawing.setColor(WHITE, WHITE, WHITE)
end

function M.activate(toolId)
    activeToolId = toolId
    targetX = nil
    targetY = nil
end

function M.deactivate(toolId)
    if activeToolId == toolId then
        activeToolId = nil
        targetX = nil
        targetY = nil
    end
end

function M.track(toolId, tileX, tileY, hoverX, hoverY)
    if activeToolId ~= toolId or tileX ~= hoverX or tileY ~= hoverY then
        return
    end

    targetX = hoverX
    targetY = hoverY
end

function M.drawCity(toolId)
    if activeToolId ~= toolId then
        return
    end

    drawTarget()
    targetX = nil
    targetY = nil
end

DotPreview = M
return M
