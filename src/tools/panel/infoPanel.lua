local M = {}

local info_current_draft, info_current_layer

function M.createInfoPanel()
    local root = GUI.getRoot()

    info_current_draft = root:addLabel{
        x = 22,
        y = 31,

        font = Font.SMALL,

        h = 10,
        w = 100,

        text = TheoTown.translate("rpi_current_draft") -- zh:当前放置： + -- TODO: 显示 Draft 的 ID
    }

    info_current_draft:setColor(Color.TEXT_SELECTED)
    info_current_draft:setAlignment(0.1, 0.5)

    info_current_layer = root:addLabel{
        x = 22,
        y = 42,

        font = Font.SMALL,

        h = 10,
        w = 100,

        text = TheoTown.translate("rpi_current_layer") -- zh:位于第 %d 层 + -- TODO: 显示纹理位于第几层
    }

    info_current_layer:setColor(Color.TEXT_SELECTED)
    info_current_layer:setAlignment(0.1, 0.5)
end

function M.destroyInfoPanel()
    info_current_draft:delete()
    info_current_layer:delete()
end

InfoPanel = M
return M