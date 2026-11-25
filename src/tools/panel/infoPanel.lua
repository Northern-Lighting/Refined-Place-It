local M = {}

local info

function M.createInfoPanel()
    local root = GUI.getRoot()

    info = root:addLabel{
        x = 22,
        y = 31,

        font = Font.SMALL,
        -- color = Color.WHITE,

        h = 10,

        text = "当前放置："
    }
end

function M.destroyInfoPanel()
    info:delete()
end

InfoPanel = M
return M