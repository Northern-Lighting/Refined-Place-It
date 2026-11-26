local draftPickerDialog
local draftPreview
local draftTextField
local draftListBox
local selectedDraftFrame
local draftFrameOwnerId
local draftFrameItems
local draftFrameListDraftId
local TOOL_ID = "$refined_place_it_00_placeTool"

local function clearDraftFrameItems()
    for i = #draftFrameItems, 1, -1 do
        draftFrameItems[i]:delete()
    end

    draftFrameItems:clear()
end

local function populateDraftFrameList(draftId)
    if draftId == draftFrameListDraftId then
        return
    end

    draftFrameListDraftId = draftId
    clearDraftFrameItems()

    selectedDraftFrame = nil
    draftFrameOwnerId = nil
    draftPreview:setIcon(Icon.REGION_SHOW)

    local draft = Draft.getDraft(draftId)

    if draft == nil then
        return
    end

    local okFrameCount, frameCount = pcall(function ()
        return draft:getFrameCount()
    end)
    local usePreviewFrames = false

    if not okFrameCount or frameCount == nil or frameCount == 0 then
        local okPreviewCount, previewCount = pcall(function ()
            return draft:getPreviewFrameCount()
        end)

        frameCount = okPreviewCount and previewCount or 0
        usePreviewFrames = true
    end

    for frameIndex = 1, frameCount do
        local okFrame, frame

        if usePreviewFrames then
            okFrame, frame = pcall(function ()
                return draft:getPreviewFrame(frameIndex)
            end)
        else
            okFrame, frame = pcall(function ()
                return draft:getFrame(frameIndex)
            end)
        end

        if okFrame and frame ~= nil and frame > 0 then
            local item = draftListBox:addCanvas{
                h = 30,
                listboxSelectable = true,
                onClick = function ()
                    selectedDraftFrame = frame
                    draftFrameOwnerId = draftId
                    draftPreview:setIcon(frame)
                end
            }
            draftFrameItems:add(item)

            local icon = item:addIcon{
                w = 30,
                x = 5,
                icon = frame
            }
            icon:setAlignment(0, 0.5)

            local label = item:addLabel{
                x = 35,
                w = -70,
                text = TheoTown.translate("rpi_frame_label") .. " " .. frameIndex
            }
            label:setAlignment(0, 0.5)

            if selectedDraftFrame == nil then
                selectedDraftFrame = frame
                draftFrameOwnerId = draftId
                draftPreview:setIcon(frame)
            end
        end
    end
end

local function getSelectedDraftFrame()
    local draft, firstFrame = FavoriteDialog.getDraftAndFrame(
        draftTextField:getText()
    )

    if draft == nil then
        return nil
    end

    if draftFrameOwnerId == draft:getId() and selectedDraftFrame ~= nil then
        return selectedDraftFrame
    end

    return firstFrame
end

local function applyExternalDraftSelection(draftId)
    draftFrameListDraftId = false
    populateDraftFrameList(draftId)
end

local function showDraftPickerDialog()
    selectedDraftFrame = nil
    draftFrameOwnerId = nil
    draftFrameItems = Array()
    draftFrameListDraftId = false

    draftPickerDialog = GUI.createDialog{
        icon = Icon.COPY,
        title = TheoTown.translate("rpi_general_draftPicker_title"),
        text = TheoTown.translate("rpi_general_draftPicker_text"),
        pause = true,
        h = 280,
        actions = {
            {
                icon = Icon.STAR,
                text = TheoTown.translate("rpi_favorite_to"),
                onClick = function ()
                    FavoriteDialog.createFavoriteDialog{
                        outputTextField = draftTextField,
                        outputPreview = draftPreview,
                        onDraftSelected = applyExternalDraftSelection
                    }
                end,
                autoClose = false
            },
            {
                icon = Icon.EYE_DROPPER,
                onClick = function ()
                    DropperToolLink.back2DropperRecordDialog{
                        textField = draftTextField,
                        preview = draftPreview,
                        onDraftSelected = applyExternalDraftSelection,
                        returnToolId = "$refined_place_it_00_dropperTool"
                    }
                end,
                autoClose = false
            },
            {
                icon = Icon.CANCEL,
                onClick = function ()
                    City.createDraftDrawer("$refined_place_it_00").select()
                    GUI.get("cmdCloseTool"):click()
                end
            },
            {
                icon = Icon.OK,
                text = Translation.control_ok,
                golden = true,
                onClick = function ()
                    local frame = getSelectedDraftFrame()

                    if frame == nil then
                        Debug.toast(TheoTown.translate("rpi_draft_invalid"))
                        return
                    end

                    selectedDraftFrame = frame
                    draftPreview:setIcon(frame)
                    draftPickerDialog:close()
                end,
                autoClose = false
            }
        }
    }

    draftPreview = draftPickerDialog.content:addIcon{
        x = 10,
        y = 20,
        h = 30,
        w = 30,
        icon = Icon.REGION_SHOW
    }

    draftTextField = draftPickerDialog.content:addTextField{
        x = 41,
        y = 20,
        h = 30,
        w = -10,
        onUpdate = function (textField)
            populateDraftFrameList(textField:getText())
        end
    }

    draftListBox = draftPickerDialog.content:addListBox{
        w = -10,
        h = -10,
        x = 10,
        y = 52,
        listboxSelectable = true,
    }

    FavoriteDialog.applyDraftSelection(
        draftTextField,
        draftPreview,
        DropperToolLink.getLatestDraftId()
    )
    populateDraftFrameList(draftTextField:getText())
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
        DotPreview.deactivate(TOOL_ID)
        CtrlPanel.destroyCtrlAction()
        InfoPanel.destroyInfoPanel()
    end
end
