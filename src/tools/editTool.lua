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
        name = TheoTown.translate("rpi_general_remove") + "|" + TheoTown.translate("rpi_general_changeTexture"), -- zh: 移除纹理 和 改变纹理，TODO: 好像写错了，我不想新增翻译键，但是这么写好像报错了
        onClick = function ()
            local removeTextureDialog4EditTool = GUI.createDialog{
                icon = Icon.REMOVE,
                title = TheoTown.translate("rpi_general_remove") + "|" + TheoTown.translate("rpi_general_changeTexture"), -- TODO: 同上
                text = TheoTown.translate("rpi_editTool_remove&change"),
                h = 280,
                closeable = true,
                pause = true,
                actions = {
                    {
                        icon = Icon.CANCEL,
                        autoClose = true,
                        text = Translation.control_cancel
                    },
                    {
                        icon = Icon.OK,
                        autoClose = true,
                        text = Translation.control_ok,
                        onClick = function ()
                            -- TODO: 将保存在缓存区的将要删除的 Frames 删除，将要更改的 Frames 应用更改
                        end
                    }
                }
            }

            local removeTool_listBox = removeTextureDialog4EditTool.content:addListBox{
                x = 10,
                y = 20,
                h = -10,
                w = -10
            }

            local removeTool_listBox_reDo = removeTextureDialog4EditTool.content:addButton{
                h = 30,
                w = 30,
                y = 173,
                x = 10,
                icon = Icon.PREVIOUS,
                onClick = function ()
                    -- TODO: 撤回，将最近一个进入缓存区的项目移出缓存区，重新加入回 ListBox，保持原来的顺序，更改同理，在 CtrlPanel.createCtrlAction() 中，缓存区里面的更改应该实时对应，比如被删除的贴图应该看不到，撤回删除的贴图应该继续显示
                end
            }

            -- TODO: 注意缓存区的要求，要求点击 OK 或者取消后都立刻销毁缓存区，缓存区的建立取决于当前已经放置的 Frames

            --[[ TODO: 这里是 Item 外观示例
            local listBoxItem[1] = removeTool_listBox:addCanvas{
                h = 30
            }
            
            local item1Icon = listBoxItem[1]:addIcon{
                -- TODO: icon = Frames 的贴图
            }
            
            item1Icon:setAlignment(0, 0.5)
            
            local item1BottonDelete = listBoxItem[1]:addButton{
                x = -35,
                width = 30,
                icon = Icon.TRASH,
                onClick = function ()
                    -- TODO: 将 Frames 从列表里面删除，同时进入将要删除的贴图的缓存区
                end
            }
            
            local item1BottonSelect = listBoxItem[1]:addButton{
                x = -66,
                w = 30,
                icon = Icon.COPY,
                onClick = function ()
                    -- TODO: 弹出选择 Draft 菜单
                    -- TODO: 将要被更改的 Frames 移动到缓存区，然后更改对应 Item 的预览贴图
                end
            }
            
            local item1BottonAdjust = listBoxItem[1]:addButton{
                x = -97,
                w = 30,
                icon = Icon.LOCATE,
                onClick = function ()
                    -- TODO: 点击之后才弹出 CtrlPanel.createCtrlAction()，更改完位置将调整的参数调整进缓存区
                end
            }
            
            local item1BottonReset = ........{
                x = -128,
                w = 30,
                icon = Icon.RESET,
                onClick = function ()
                    -- TODO: 重置位置，同样更改进入缓存区
                end
            }
            ]]--
        end
    }
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
        -- TODO: 应该做到点击更改按钮后才弹出，而不是现在这样
        CtrlPanel.createCtrlAction()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        DotPreview.deactivate(TOOL_ID)

        -- TODO:空判断
        CtrlPanel.destroyCtrlAction()
    end
end
