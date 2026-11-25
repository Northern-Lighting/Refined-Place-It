local function openIndexMenu()
    GUI.get("cmdCloseTool"):click()
    local indexToolDialog = GUI.createDialog{
    icon = Icon.EYE,
    title = TheoTown.translate("rpi_indexTool"),
    closeable = true,
    height = 200,
    pause = true,
    actions = {
            {
                icon = Icon.CANCEL,
                text = Translation.control_cancel,
                autoClose = true
            }
        }
    }

    -- TODO: 搜索、添加到常用
end

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        openIndexMenu()
    end
end
