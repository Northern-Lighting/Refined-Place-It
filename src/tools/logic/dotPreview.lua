local M = {}

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

    local restoreScaleX, restoreScaleY = Drawing.getScale()
    local restoreR, restoreG, restoreB = Drawing.getColor()
    local restoreAlpha = Drawing.getAlpha()
    local restoreAdditive = Drawing.getAdditive()

    Drawing.setAdditive(0)

    if hasTarget(targetX, targetY) then
        Drawing.setColor(255, 255, 255)
    else
        Drawing.setColor(255, 0, 0)
    end

    Drawing.setTile(targetX, targetY)
    Drawing.drawTileFrame(Icon.TOOLMARK_BLOB)
    Drawing.setScale(restoreScaleX, restoreScaleY)
    Drawing.setColor(restoreR, restoreG, restoreB)
    Drawing.setAlpha(restoreAlpha)
    Drawing.setAdditive(restoreAdditive)
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
