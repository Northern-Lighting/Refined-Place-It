local M = {}

local info_current_draft, info_current_layer
local currentDraftId = "-"
local currentFrameIndex = 1
local currentLayer = 1

local function draftText()
    return TheoTown.translate("rpi_current_draft") ..
        " " .. tostring(currentDraftId or "-") ..
        "  " .. TheoTown.translate("rpi_frame_label") ..
        " " .. tostring(currentFrameIndex or 1)
end

local function layerText()
    return TheoTown.translate("rpi_current_layer_number") ..
        " " .. tostring(currentLayer or 1)
end

function M.createInfoPanel()
    local root = GUI.getRoot()

    info_current_draft = root:addLabel{
        x = 22,
        y = 31,

        font = Font.SMALL,

        h = 10,
        w = 100,

        text = draftText()
    }

    info_current_draft:setColor(Color.TEXT_SELECTED)
    info_current_draft:setAlignment(0.1, 0.5)

    info_current_layer = root:addLabel{
        x = 22,
        y = 42,

        font = Font.SMALL,

        h = 10,
        w = 100,

        text = layerText()
    }

    info_current_layer:setColor(Color.TEXT_SELECTED)
    info_current_layer:setAlignment(0.1, 0.5)
end

function M.setCurrentDraft(draftId, frameIndex)
    currentDraftId = draftId or "-"
    currentFrameIndex = math.max(
        1,
        math.floor(tonumber(frameIndex) or 1)
    )

    if info_current_draft ~= nil then
        info_current_draft:setText(draftText())
    end
end

function M.setCurrentLayer(layer)
    currentLayer = math.max(1, math.min(8, math.floor(tonumber(layer) or 1)))

    if info_current_layer ~= nil then
        info_current_layer:setText(layerText())
    end
end

function M.destroyInfoPanel()
    if info_current_draft ~= nil then
        info_current_draft:delete()
    end
    if info_current_layer ~= nil then
        info_current_layer:delete()
    end

    info_current_draft = nil
    info_current_layer = nil
end

InfoPanel = M
return M
