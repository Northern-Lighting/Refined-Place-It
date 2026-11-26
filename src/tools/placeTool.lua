local draftPickerDialog
local draftPreview
local draftTextField
local draftListBox
local selectedDraftFrame
local draftFrameOwnerId
local draftFrameItems
local draftFrameListDraftId
local TOOL_ID = "$refined_place_it_00_placeTool"
local selectedDraftId
local selectedDraftFrameIndex = 1
local selectedLayer = 1
local lastPlacedItem
local StartCapture
local EndCapture

local function beginCapture(x, y)
    if StartCapture ~= nil then
        StartCapture(x, y, x, y, x, y)
    end
end

local function endCapture()
    if EndCapture ~= nil then
        EndCapture()
    end
end

local function clampLayer(layer)
    return math.max(
        FramesPlaceAndStorage.MIN_LAYER,
        math.min(
            FramesPlaceAndStorage.MAX_LAYER,
            math.floor(tonumber(layer) or 1)
        )
    )
end

local function updateInfoPanel()
    InfoPanel.setCurrentDraft(
        selectedDraftId,
        selectedDraftFrameIndex
    )
    InfoPanel.setCurrentLayer(selectedLayer)
end

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
    selectedDraftId = nil
    selectedDraftFrameIndex = 1
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
                    selectedDraftId = draftId
                    selectedDraftFrameIndex = frameIndex
                    draftFrameOwnerId = draftId
                    draftPreview:setIcon(frame)
                    updateInfoPanel()
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
                selectedDraftId = draftId
                selectedDraftFrameIndex = frameIndex
                draftFrameOwnerId = draftId
                draftPreview:setIcon(frame)
                updateInfoPanel()
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
        return
            selectedDraftFrame,
            selectedDraftId or draft:getId(),
            selectedDraftFrameIndex
    end

    return firstFrame, draft:getId(), 1
end

local function applyExternalDraftSelection(draftId)
    draftFrameListDraftId = false
    populateDraftFrameList(draftId)
end

local function showDraftPickerDialog()
    selectedDraftFrame = nil
    selectedDraftId = nil
    selectedDraftFrameIndex = 1
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
                    local frame, draftId, frameIndex =
                        getSelectedDraftFrame()

                    if frame == nil then
                        Debug.toast(TheoTown.translate("rpi_draft_invalid"))
                        return
                    end

                    selectedDraftFrame = frame
                    selectedDraftId = draftId
                    selectedDraftFrameIndex = frameIndex
                    draftPreview:setIcon(frame)
                    updateInfoPanel()
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

local function getOperableItem()
    local item = lastPlacedItem

    if item ~= nil then
        item = FramesPlaceAndStorage.getItem(item.id)
    end

    if item == nil then
        item = FramesPlaceAndStorage.getLast()
    end

    lastPlacedItem = item
    return item
end

local function withCapture(item, action)
    if item == nil then
        return nil
    end

    beginCapture(item.x, item.y)
    local result = action(item)
    endCapture()

    return result
end

local function moveOperableItem(dx, dy)
    local item = getOperableItem()

    if item == nil then
        Debug.toast(TheoTown.translate("rpi_toast_nothing_placed"))
        return
    end

    withCapture(item, function (target)
        FramesPlaceAndStorage.move(target.id, dx, dy)
    end)
end

local function changeOperableLayer(delta)
    local item = getOperableItem()

    if item == nil then
        selectedLayer = clampLayer(selectedLayer + delta)
    else
        local updated = withCapture(item, function (target)
            return FramesPlaceAndStorage.shiftLayer(target.id, delta)
        end)

        if updated ~= nil then
            selectedLayer = updated.zOrder
        end
    end

    updateInfoPanel()
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
            local item = getOperableItem()
            if item == nil then
                Debug.toast(TheoTown.translate("rpi_toast_nothing_placed"))
                return
            end

            withCapture(item, function (target)
                FramesPlaceAndStorage.remove(target.id)
            end)
            lastPlacedItem = nil
            updateInfoPanel()
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.RESET,
        name = TheoTown.translate("rpi_general_reset"), -- zh: 重置位置
        onClick = function()
            local item = getOperableItem()
            if item == nil then
                Debug.toast(TheoTown.translate("rpi_toast_nothing_placed"))
                return
            end

            local updated = withCapture(item, function (target)
                return FramesPlaceAndStorage.reset(target.id)
            end)

            if updated ~= nil then
                selectedLayer = updated.zOrder
                updateInfoPanel()
            end
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.COLOR,
        name = TheoTown.translate("rpi_general_adjustColor"), -- zh: 调整颜色
        onClick = function()
            local item = getOperableItem()
            if item == nil then
                Debug.toast(TheoTown.translate("rpi_toast_nothing_placed"))
                return
            end

            GUI.showColorPicker{
                r = item.tintR or 255,
                g = item.tintG or 255,
                b = item.tintB or 255,
                onColor = function (r, g, b)
                    withCapture(item, function (target)
                        FramesPlaceAndStorage.setColor(target.id, r, g, b)
                    end)
                end,
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

function script:lateInit()
    FramesPlaceAndStorage.installWorldLayer()
end

function script:draw(tileX, tileY, hoverX, hoverY)
    DotPreview.track(TOOL_ID, tileX, tileY, hoverX, hoverY)
end

function script:drawCity()
    DotPreview.drawCity(TOOL_ID)
end

function script:click(x, y)
    local _, draftId, frameIndex = getSelectedDraftFrame()

    if draftId == nil then
        Debug.toast(TheoTown.translate("rpi_draft_invalid"))
        return false
    end

    beginCapture(x, y)
    local item, reason = FramesPlaceAndStorage.add(
        draftId,
        frameIndex,
        x,
        y,
        0,
        {
            layer = selectedLayer,
        }
    )
    endCapture()

    if item == nil then
        if reason == "building_limit" then
            Debug.toast(TheoTown.translate("rpi_toast_building_limit"))
        else
            Debug.toast(TheoTown.translate("rpi_toast_no_target"))
        end
        return false
    end

    lastPlacedItem = item
    selectedLayer = item.zOrder
    updateInfoPanel()

    return false
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
        CtrlPanel.createCtrlAction{
            onMove = moveOperableItem,
            onLayerChange = changeOperableLayer,
        }

        -- Info Panel
        InfoPanel.createInfoPanel()

        -- Draft Picker Dialog
        showDraftPickerDialog()
        updateInfoPanel()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        DotPreview.deactivate(TOOL_ID)
        CtrlPanel.destroyCtrlAction()
        InfoPanel.destroyInfoPanel()
    end
end
