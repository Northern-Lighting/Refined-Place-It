local function displayPlaceToolAction()
    TheoTown.registerToolAction{
        icon = Icon.SETTINGS,
        name = TheoTown.translate("rpi_mainMenu_title"),
        onClick = function ()
            City.createDraftDrawer("$refined_place_it_00").select()
            GUI.get("cmdCloseTool"):click()
        end
    }
end

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        displayPlaceToolAction()
    end
end
