local TOOL_ID = "$refined_place_it_00_editTool"

local function displayEditToolAction()
    -- Get Tool Action
    TheoTown.registerToolAction{
        icon = Icon.SETTINGS,
        name = TheoTown.translate("rpi_mainMenu_title"),
        onClick = function ()
            City.createDraftDrawer("$refined_place_it_00").select()
            GUI.get("cmdCloseTool"):click()
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.REMOVE,
        name = TheoTown.translate("rpi_general_remove") -- zh: 移除纹理
    }

    TheoTown.registerToolAction{
        icon = Icon.RESET,
        name = TheoTown.translate("rpi_general_reset") -- zh: 重置位置
    }

    StartCapture, EndCapture = TheoTown.addUndoButton()
end

function script:draw(tileX, tileY, hoverX, hoverY)
    DotPreview.track(TOOL_ID, tileX, tileY, hoverX, hoverY)
end

function script:drawCity()
    DotPreview.drawCity(TOOL_ID)
end

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        DotPreview.activate(TOOL_ID)

        -- Tool Icon Get
        local draft = assert(Draft.getDraft("$refined_place_it_00_editTool"))
        Draft.setFrame(draft, 1, Icon.CENTER)

        -- Tool Actions
        displayEditToolAction()

        -- Tool Control Actions
        CtrlPanel.createCtrlAction()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        DotPreview.deactivate(TOOL_ID)
        CtrlPanel.destroyCtrlAction()
    end
end
