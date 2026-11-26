local M = {}

local pxAdjustPanel
local left, right, up, down
local toTop, toBottom
local lbl_toTheBottom, lbl_toTheTop
local sliderValue = 1

local ShowLabelKey = false -- DEBUG USE

function M.createCtrlAction(options)
    options = options or {}
    local callbacks = options
    local root = GUI.getRoot()

    local ClientH = root:getClientHeight()
    local ClientW = root:getClientWidth()

    local UP_ICON = Draft.getFrame(
        assert(Draft.getDraft("$refined_place_it_icon_up00")), 1)
    local DOWN_ICON = Draft.getFrame(
        assert(Draft.getDraft("$refined_place_it_icon_down00")), 1)
    
    pxAdjustPanel = root:addPanel{
            x = 190,
            y = root:getClientHeight() - 20,
            w = 180,
            h = 20
        }

        pxAdjustPanel:addCanvas{
            onDraw = function (self, x, y, w, h)
                Drawing.drawNinePatch(NinePatch.INDICATOR, 190, ClientH - 20, 180, 20)
            end
        }

        local X_MOVING_PX_4_LEFT = 31
        local X_MOVING_PX_4_RIGHT = ClientW - 90
        local Y_MOVING_PX = ClientH - 131

        left = root:addButton{
            x = 10 + X_MOVING_PX_4_LEFT,
            y = 40 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = Icon.PREVIOUS,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onMove ~= nil then
                    callbacks.onMove(-sliderValue, 0)
                end
            end
        }

        right = root:addButton{
            x = 70 + X_MOVING_PX_4_LEFT,
            y = 40 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = Icon.NEXT,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onMove ~= nil then
                    callbacks.onMove(sliderValue, 0)
                end
            end
        }

        up = root:addButton{
            x = 40 + X_MOVING_PX_4_LEFT,
            y = 10 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = UP_ICON,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onMove ~= nil then
                    callbacks.onMove(0, -sliderValue)
                end
            end
        }

        down = root:addButton{
            x = 40 + X_MOVING_PX_4_LEFT,
            y = 70 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = DOWN_ICON,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onMove ~= nil then
                    callbacks.onMove(0, sliderValue)
                end
            end
        }

        toTop = root:addButton{
            x = X_MOVING_PX_4_RIGHT,
            y = 10 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = Icon.PLUS,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onLayerChange ~= nil then
                    callbacks.onLayerChange(1)
                end
            end
        }

        toBottom = root:addButton{
            x = X_MOVING_PX_4_RIGHT,
            y = 70 + Y_MOVING_PX,
            w = 30,
            h = 30,
            icon = Icon.MINUS,
            frameDefault = NinePatch.BLUE_BUTTON,
            frameDown = NinePatch.BLUE_BUTTON_PRESSED,
            onClick = function ()
                if callbacks.onLayerChange ~= nil then
                    callbacks.onLayerChange(-1)
                end
            end
        }

        if (ShowLabelKey == true) then
            lbl_toTheTop = root:addLabel{
                x = -50 + X_MOVING_PX_4_RIGHT,
                y = 10 + Y_MOVING_PX,
                h = 30,
                w = 60,
                text = TheoTown.translate("rpi_general_toTheTop")
            }

            lbl_toTheTop:setAlignment(0.1, 0.35)
            lbl_toTheTop:setColor(Color.TEXT_SELECTED)

            lbl_toTheBottom = root:addLabel{
                x = -50 + X_MOVING_PX_4_RIGHT,
                y = 70 + Y_MOVING_PX,
                h = 30,
                w = 60,
                text = TheoTown.translate("rpi_general_toTheBottom")
            }

            lbl_toTheBottom:setAlignment(0.1, 0.35)
            lbl_toTheBottom:setColor(Color.TEXT_SELECTED)
        end

        -- Slider: From 1 to 20 px, affect texture's moving distance
        local moveValueLabel

        local function updateMoveValueLabel()
            moveValueLabel:setText(
                TheoTown.translate("rpi_general_move")
                .. " "
                .. sliderValue
                .. " "
                .. "px"
            )
        end

        moveValueLabel = pxAdjustPanel:addLabel {
            x = 124,
            y = 2,
            h = 20,
            text = nil,
        }

        moveValueLabel:setAlignment(0.1, - 0.25)
        moveValueLabel:setColor(Color.TEXT_SELECTED)

        pxAdjustPanel:addSlider {
            x = 2,
            y = 2,
            w = 160,
            h = 16,

            minValue = 1,
            maxValue = 20,

            getValue = function()
                return sliderValue
            end,

            setValue = function(value)
                sliderValue = math.floor(value + 0.5)
                updateMoveValueLabel()
            end,

            getText = function()
                return nil
            end,
        }

    updateMoveValueLabel()
end

function M.destroyCtrlAction()
    if left ~= nil then left:delete() end
    if right ~= nil then right:delete() end
    if up ~= nil then up:delete() end
    if down ~= nil then down:delete() end
    if toTop ~= nil then toTop:delete() end
    if toBottom ~= nil then toBottom:delete() end

    if ShowLabelKey then
        if lbl_toTheBottom ~= nil then lbl_toTheBottom:delete() end
        if lbl_toTheTop ~= nil then lbl_toTheTop:delete() end
    end

    if pxAdjustPanel ~= nil then pxAdjustPanel:delete() end

    left = nil
    right = nil
    up = nil
    down = nil
    toTop = nil
    toBottom = nil
    lbl_toTheBottom = nil
    lbl_toTheTop = nil
    pxAdjustPanel = nil
end

CtrlPanel = M
return M
