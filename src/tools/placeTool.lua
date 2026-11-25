local draftPickerDialog

local function showDraftPickerDialog()
    draftPickerDialog = GUI.createDialog{
        icon = Icon.COPY,
        title = "rpi_general_draftPicker_title",
        text = "rpi_general_draftPicker_text",
        closeable = true,
        pause = true,
        actions = {
            {
                icon = Icon.OK,
                text = Translation.control_ok,
                golden = true,
                onClick = function ()
                    -- TODO: 返回被选中的 Draft 里面的 
                end,
                autoClose = true
            }
        }
    }
end

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
        name = TheoTown.translate("rpi_general_remove"), -- zh: 移除纹理
        onClick =function()
            -- TODO: 接入函数，移除刚刚放置的纹理
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.RESET,
        name = TheoTown.translate("rpi_general_reset"), -- zh: 重置位置
        onClick = function()
            -- TODO: 接入函数，重置刚刚放置的纹理位置
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.COLOR,
        name = TheoTown.translate("rpi_general_adjustColor"), -- zh: 调整颜色
        onClick = function()
            GUI.showColorPicker{
                r = 0,
                g = 0,
                b = 0,

                -- TODO: onColor = 传出颜色，更改当前纹理的颜色，并记录下参数，下次在 editTool 中打开 colorPicker 时，默认值应该为已保存参数

                title = TheoTown.translate("rpi_general_adjustColor")
            }
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.COPY,
        name = TheoTown.translate("rpi_general_changeTexture"), -- zh: 更改纹理
        onClick = function()
            showDraftPickerDialog()
        end
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

        -- Draft Picker Dialog
        showDraftPickerDialog()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        CtrlPanel.destroyCtrlAction()
        InfoPanel.destroyInfoPanel()
    end
end
