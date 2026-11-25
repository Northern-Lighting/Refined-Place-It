local function displayPlaceToolAction()
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

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        -- Tool Icon Get
        local draft = assert(Draft.getDraft("$refined_place_it_00_placeTool"))
        Draft.setFrame(draft, 1, Icon.DECORATION)

        -- Tool Actions
        displayPlaceToolAction()

        -- Control Actions
        CtrlPanel.createCtrlAction()

        -- Info Panel
        InfoPanel.createInfoPanel()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        CtrlPanel.destroyCtrlAction()
        InfoPanel.destroyInfoPanel()
    end
end
