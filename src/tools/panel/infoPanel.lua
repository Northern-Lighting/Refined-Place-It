local M = {}

local panel

function M.createInfoPanel()
    local root = GUI.getRoot()

    local ClientH = GUI.getRoot():getClientHeight()
    local ClientW = GUI.getRoot():getClientWidth()

    local InfoPanel_W = 110
    local InfoPanel_H = 50

    local InfoPanel_X = ClientW / 2.0 - (InfoPanel_W / 2.0)
    local InfoPanel_Y = 0

    if root ~= nil then
        panel = root:addPanel{
            x = InfoPanel_X,
            y = InfoPanel_Y,

            w = InfoPanel_W,
            h = InfoPanel_H
        }

        panel:addCanvas{
            onDraw = function (self, x, y, w, h)
                Drawing.drawNinePatch(NinePatch.INDICATOR, InfoPanel_X, InfoPanel_Y, InfoPanel_W, InfoPanel_H)
            end
        }
    end
end

function M.destroyInfoPanel()
    panel:delete()
end

InfoPanel = M
return M