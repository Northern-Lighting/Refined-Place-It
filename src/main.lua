-- Main Menu Content
local function openMainMenu()
    local main_menu = GUI.createDialog{
        icon = Icon.SETTINGS,
        title = TheoTown.translate("rpi_mainMenu_title"), -- zh: Place It! 菜单
        text = TheoTown.translate("rpi_mainMenu_text"), -- zh: 选择你要使用的工具 =w=
        closeable = true,
        pause = true,
        height = 289,
        actions = {
            {
                icon = Icon.WIZARD,
                onClick = function ()
                    -- TODO: 使用向导
                end
            },
            {
                icon = Icon.CANCEL,
                text = Translation.control_cancel,
                autoClose = true
            }
        }
    }

    local function closeMainMenu()
        main_menu:close()
    end

    local mm_listBox = main_menu.content:addListBox{
        x = 10,
        y = 25,
        width = -10,
        height = -10,
    }

    -- ListBox Content
    local mm_listBoxEntry = {}

    for i = 1,6 do 
        mm_listBoxEntry[i] = mm_listBox:addCanvas{
            height = 30
        }

        if (i == 1) then
            local mm_listBoxItem_1 = mm_listBoxEntry[1]:addLabel{
                text = TheoTown.translate("rpi_listCat_edit&placeTool") -- zh: 放置与修改工具
            }
        end

        if (i == 2) then
            local mm_listBoxItem_2_icon = mm_listBoxEntry[2]:addIcon{
                icon = Icon.DECORATION
            }

            mm_listBoxItem_2_icon:setAlignment(0, 0.5)

            local mm_listBoxItem_2_text = mm_listBoxEntry[2]:addLabel{
                text = TheoTown.translate("rpi_placeTool"), -- zh: 纹理放置工具
                x = 35
            }

            local mm_listBoxItem_2_cmd = mm_listBoxEntry[2]:addButton{
                x = -35,
                width = 30,
                icon = Icon.FORWARD,
                onClick = function ()
                    closeMainMenu()
                    City.createDraftDrawer("$refined_place_it_00_placeTool", true).select()
                end
            }
        end

        if (i == 3) then
            local mm_listBoxItem_3_icon = mm_listBoxEntry[3]:addIcon{
                icon = Icon.CENTER
            }

            mm_listBoxItem_3_icon:setAlignment(0, 0.5)

            local mm_listBoxItem_3_text = mm_listBoxEntry[3]:addLabel{
                text = TheoTown.translate("rpi_editTool"), -- zh: 历史调整工具
                x = 35
            }

            local mm_listBoxItem_3_cmd = mm_listBoxEntry[3]:addButton{
                x = -35,
                width = 30,
                icon = Icon.FORWARD,
                onClick = function ()
                    closeMainMenu()
                    City.createDraftDrawer("$refined_place_it_00_editTool", true).select()
                end
            }
        end

        if (i == 4) then
            local mm_listBoxItem_4 = mm_listBoxEntry[4]:addLabel{
                text = TheoTown.translate("rpi_listCat_index&dropperTool") -- zh: 搜索与滴管工具
            }
        end

        if (i == 5) then
            local mm_listBoxItem_5_icon = mm_listBoxEntry[5]:addIcon{
                icon = Icon.EYE
            }

            mm_listBoxItem_5_icon:setAlignment(0, 0.5)

            local mm_listBoxItem_5_text = mm_listBoxEntry[5]:addLabel{
                text = TheoTown.translate("rpi_indexTool"), -- zh: Draft 搜索工具
                x = 35
            }

            local mm_listBoxItem_5_cmd = mm_listBoxEntry[5]:addButton{
                x = -35,
                width = 30,
                icon = Icon.FORWARD,
                onClick = function ()
                    closeMainMenu()
                    City.createDraftDrawer("$refined_place_it_00_indexTool", true).select()
                end
            }
        end

        if (i == 6) then
            local mm_listBoxItem_6_icon = mm_listBoxEntry[6]:addIcon{
                icon = Icon.EYE_DROPPER
            }

            mm_listBoxItem_6_icon:setAlignment(0, 0.5)

            local mm_listBoxItem_6_text = mm_listBoxEntry[6]:addLabel{
                text = TheoTown.translate("rpi_dropperTool"), -- zh: 滴管工具
                x = 35
            }

            local mm_listBoxItem_6_cmd = mm_listBoxEntry[6]:addButton{
                icon = Icon.FORWARD,
                width = 30,
                x = -35,
                onClick = function ()
                    closeMainMenu()
                    City.createDraftDrawer("$refined_place_it_00_dropperTool", true).select()
                end
            }
        end
    end

end

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        GUI.get("cmdCloseTool"):click()
        openMainMenu()
    end
end
