local TOOL_ID = "$refined_place_it_00_editTool"

local editorDialog
local editorListBox
local editorItems = Array()
local editorTarget
local editorSnapshot
local editorHistory = {}
local editorClosing = false
local selectedItemId
local currentTarget
local StartCapture
local EndCapture

local rebuildEditorList
local openChangeFrameDialog
local openAdjustPanel
local openColorPickerForItem
local hideEditorForAdjust

local function clampLayer(layer)
    return math.max(
        FramesPlaceAndStorage.MIN_LAYER,
        math.min(
            FramesPlaceAndStorage.MAX_LAYER,
            math.floor(tonumber(layer) or 1)
        )
    )
end

local function withCapture(x, y, action)
    if StartCapture ~= nil then
        StartCapture(x, y, x, y, x, y)
    end

    local ok, result = pcall(action)

    if EndCapture ~= nil then
        EndCapture()
    end

    if not ok then
        error(result)
    end

    return result
end

local function snapshotCurrentTarget()
    if editorTarget == nil then
        return {}
    end

    return FramesPlaceAndStorage.snapshotTarget(
        editorTarget.anchorX,
        editorTarget.anchorY,
        editorTarget.level
    )
end

local function pushEditorHistory()
    editorHistory[#editorHistory + 1] = snapshotCurrentTarget()
end

local function restoreSnapshot(snapshot)
    if editorTarget == nil then
        return
    end

    withCapture(editorTarget.anchorX, editorTarget.anchorY, function ()
        FramesPlaceAndStorage.restoreTarget(
            editorTarget.anchorX,
            editorTarget.anchorY,
            editorTarget.level,
            snapshot
        )
    end)
end

local function clearEditorItems()
    for i = #editorItems, 1, -1 do
        editorItems[i]:delete()
    end

    editorItems:clear()
end

local function closeEditor(restore, alreadyClosing)
    if editorClosing then
        return
    end

    if editorDialog == nil and
       editorTarget == nil and
       editorSnapshot == nil then
        return
    end

    editorClosing = true

    if restore and editorSnapshot ~= nil then
        restoreSnapshot(editorSnapshot)
    end

    CtrlPanel.destroyCtrlAction()
    clearEditorItems()

    local dialog = editorDialog
    if dialog ~= nil and not alreadyClosing then
        dialog:close()
    end

    editorDialog = nil
    editorListBox = nil
    editorTarget = nil
    editorSnapshot = nil
    editorHistory = {}
    selectedItemId = nil
    editorClosing = false

    InfoPanel.setCurrentDraft("-")
    InfoPanel.setCurrentLayer(1)
end

hideEditorForAdjust = function ()
    if editorDialog == nil or editorClosing then
        return
    end

    editorClosing = true
    clearEditorItems()

    local dialog = editorDialog
    editorDialog = nil
    editorListBox = nil
    dialog:close()
    editorClosing = false
end

local function undoEditorChange()
    if editorDialog == nil or #editorHistory == 0 then
        return
    end

    local snapshot = table.remove(editorHistory)
    restoreSnapshot(snapshot)
    selectedItemId = nil
    rebuildEditorList()
end

local function selectEditorItem(item)
    if item == nil then
        selectedItemId = nil
        InfoPanel.setCurrentDraft("-")
        InfoPanel.setCurrentLayer(1)
        return
    end

    selectedItemId = item.id
    InfoPanel.setCurrentDraft(item.draftId, item.frameIndex or 1)
    InfoPanel.setCurrentLayer(item.zOrder or 1)
end

local function getSelectedItem()
    return FramesPlaceAndStorage.getItem(selectedItemId)
end

openChangeFrameDialog = function (item)
    if item == nil then
        return
    end

    local selectedDraftId = item.draftId
    local selectedFrameIndex = item.frameIndex or 1
    local loadedDraftId = item.draftId
    local frameItems = Array()
    local changeDialog
    local changeListBox

    local function clearFrames()
        for i = #frameItems, 1, -1 do
            frameItems[i]:delete()
        end
        frameItems:clear()
    end

    local function rebuildFrames()
        clearFrames()

        local draft = Draft.getDraft(selectedDraftId)
        if draft == nil then
            return
        end

        local frameCount = 0
        local usePreviewFrames = false
        local okCount, count = pcall(function ()
            return draft:getFrameCount()
        end)

        if okCount and count ~= nil and count > 0 then
            frameCount = count
        else
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
                local candidate = changeListBox:addCanvas{
                    h = 30,
                    listboxSelectable = true,
                    onClick = function ()
                        selectedFrameIndex = frameIndex
                    end
                }
                frameItems:add(candidate)

                local icon = candidate:addIcon{
                    w = 30,
                    x = 5,
                    icon = frame,
                }
                icon:setAlignment(0, 0.5)

                local label = candidate:addLabel{
                    x = 35,
                    w = -40,
                    text = TheoTown.translate("rpi_frame_label") ..
                        " " .. frameIndex,
                }
                label:setAlignment(0, 0.5)
            end
        end
    end

    changeDialog = GUI.createDialog{
        icon = Icon.COPY,
        title = TheoTown.translate("rpi_general_changeTexture"),
        text = TheoTown.translate("rpi_general_draftPicker_text"),
        h = 280,
        closeable = true,
        pause = true,
        actions = {
            {
                icon = Icon.CANCEL,
                text = Translation.control_cancel,
                onClick = function ()
                    changeDialog:close()
                end,
                autoClose = false,
            },
            {
                icon = Icon.OK,
                text = Translation.control_ok,
                golden = true,
                onClick = function ()
                    local target = FramesPlaceAndStorage.getItem(item.id)
                    if target == nil then
                        changeDialog:close()
                        return
                    end

                    pushEditorHistory()
                    withCapture(target.x, target.y, function ()
                        FramesPlaceAndStorage.update(target.id, {
                            draftId = selectedDraftId,
                            frameIndex = selectedFrameIndex,
                        })
                    end)
                    changeDialog:close()
                    rebuildEditorList()
                end,
                autoClose = false,
            },
        },
    }

    local field = changeDialog.content:addTextField{
        x = 10,
        y = 20,
        h = 30,
        w = -10,
        text = selectedDraftId,
        onUpdate = function (textField)
            local draftId = textField:getText()
            if draftId == loadedDraftId then
                return
            end

            loadedDraftId = draftId
            selectedDraftId = draftId
            selectedFrameIndex = 1
            rebuildFrames()
        end,
    }
    field:setText(selectedDraftId or "")

    changeListBox = changeDialog.content:addListBox{
        x = 10,
        y = 52,
        w = -10,
        h = -10,
        listboxSelectable = true,
    }
    rebuildFrames()
end

openAdjustPanel = function (item)
    if item == nil then
        return
    end

    selectEditorItem(item)
    hideEditorForAdjust()
    CtrlPanel.destroyCtrlAction()
    CtrlPanel.createCtrlAction{
        onMove = function (dx, dy)
            local target = getSelectedItem()
            if target == nil then
                return
            end

            pushEditorHistory()
            withCapture(target.x, target.y, function ()
                FramesPlaceAndStorage.move(target.id, dx, dy)
            end)
        end,
        onLayerChange = function (delta)
            local target = getSelectedItem()
            if target == nil then
                return
            end

            pushEditorHistory()
            local updated = withCapture(target.x, target.y, function ()
                return FramesPlaceAndStorage.shiftLayer(
                    target.id,
                    delta
                )
            end)

            if updated ~= nil then
                InfoPanel.setCurrentLayer(updated.zOrder)
            end
            rebuildEditorList()
        end,
    }
end

openColorPickerForItem = function (item)
    if item == nil then
        return
    end

    selectEditorItem(item)
    GUI.showColorPicker{
        r = item.tintR or 255,
        g = item.tintG or 255,
        b = item.tintB or 255,
        title = TheoTown.translate("rpi_general_adjustColor"),
        onColor = function (r, g, b)
            local target = FramesPlaceAndStorage.getItem(item.id)
            if target == nil then
                return
            end

            pushEditorHistory()
            withCapture(target.x, target.y, function ()
                FramesPlaceAndStorage.setColor(target.id, r, g, b)
            end)
        end,
    }
end

rebuildEditorList = function ()
    if editorDialog == nil or editorListBox == nil or editorTarget == nil then
        return
    end

    clearEditorItems()
    local items = FramesPlaceAndStorage.getTargetItems(
        editorTarget.anchorX,
        editorTarget.anchorY,
        editorTarget.level
    )
    table.sort(items, function (a, b)
        if (a.zOrder or 1) == (b.zOrder or 1) then
            return (a.id or 0) < (b.id or 0)
        end
        return (a.zOrder or 1) < (b.zOrder or 1)
    end)

    if #items == 0 then
        selectEditorItem(nil)
        return
    end

    local selectedExists = false
    for _, item in ipairs(items) do
        if item.id == selectedItemId then
            selectedExists = true
            break
        end
    end

    if not selectedExists then
        selectedItemId = items[1].id
    end
    selectEditorItem(FramesPlaceAndStorage.getItem(selectedItemId))

    for _, item in ipairs(items) do
        local entry = editorListBox:addCanvas{
            h = 30,
            listboxSelectable = true,
            onClick = function ()
                selectEditorItem(item)
            end,
        }
        editorItems:add(entry)

        local frame = FramesPlaceAndStorage.getFrame(item)
        local icon = entry:addIcon{
            w = 30,
            x = 5,
            icon = frame or Icon.REGION_SHOW,
        }
        icon:setAlignment(0, 0.5)

        entry:addButton{
            x = -35,
            width = 30,
            icon = Icon.TRASH,
            onClick = function ()
                selectEditorItem(item)
                pushEditorHistory()
                withCapture(item.x, item.y, function ()
                    FramesPlaceAndStorage.remove(item.id)
                end)
                selectedItemId = nil
                rebuildEditorList()
            end,
        }

        entry:addButton{
            x = -66,
            width = 30,
            icon = Icon.COPY,
            onClick = function ()
                selectEditorItem(item)
                openChangeFrameDialog(item)
            end,
        }

        entry:addButton{
            x = -97,
            width = 30,
            icon = Icon.LOCATE,
            onClick = function ()
                openAdjustPanel(item)
            end,
        }

        entry:addButton{
            x = -128,
            width = 30,
            icon = Icon.RESET,
            onClick = function ()
                selectEditorItem(item)
                pushEditorHistory()
                local updated = withCapture(item.x, item.y, function ()
                    return FramesPlaceAndStorage.reset(item.id)
                end)
                if updated ~= nil then
                    InfoPanel.setCurrentLayer(updated.zOrder)
                end
                rebuildEditorList()
            end,
        }

        entry:addButton{
            x = -159,
            width = 30,
            icon = Icon.COLOR,
            onClick = function ()
                openColorPickerForItem(item)
            end,
        }
    end
end

local function openEditor()
    if currentTarget == nil then
        currentTarget = editorTarget
    end

    if currentTarget == nil then
        Debug.toast(TheoTown.translate("rpi_toast_no_target"))
        return
    end

    if editorDialog ~= nil then
        return
    end

    local items = FramesPlaceAndStorage.getTargetItems(
        currentTarget.anchorX,
        currentTarget.anchorY,
        currentTarget.level
    )
    if #items == 0 then
        Debug.toast(TheoTown.translate("rpi_toast_no_target"))
        return
    end

    local reuseSession = editorTarget ~= nil and
        editorSnapshot ~= nil and
        editorTarget.kind == currentTarget.kind and
        editorTarget.anchorX == currentTarget.anchorX and
        editorTarget.anchorY == currentTarget.anchorY and
        editorTarget.level == currentTarget.level

    if not reuseSession then
        if editorTarget ~= nil then
            closeEditor(true)
        end

        editorTarget = currentTarget
        editorSnapshot = snapshotCurrentTarget()
        editorHistory = {}
        selectedItemId = nil
    else
        editorTarget = currentTarget
    end

    editorDialog = GUI.createDialog{
        icon = Icon.CENTER,
        title = TheoTown.translate("rpi_editTool_remove&change"),
        text = TheoTown.translate("rpi_editToolTitle"),
        h = 280,
        closeable = true,
        pause = true,
        onClose = function ()
            closeEditor(true, true)
        end,
        actions = {
            {
                icon = Icon.CANCEL,
                text = Translation.control_cancel,
                onClick = function ()
                    closeEditor(true)
                end,
                autoClose = false,
            },
            {
                icon = Icon.OK,
                text = Translation.control_ok,
                golden = true,
                onClick = function ()
                    closeEditor(false)
                end,
                autoClose = false,
            },
        },
    }

    editorListBox = editorDialog.content:addListBox{
        x = 10,
        y = 20,
        w = -10,
        h = 120,
        listboxSelectable = true,
    }

    editorDialog.content:addButton{
        x = 10,
        y = 146,
        w = 30,
        h = 30,
        icon = Icon.BACKWARD,
        onClick = undoEditorChange,
    }

    rebuildEditorList()
end

local function displayEditToolAction()
    TheoTown.registerToolAction{
        icon = Icon.SETTINGS,
        name = TheoTown.translate("rpi_mainMenu_title"),
        onClick = function ()
            City.createDraftDrawer("$refined_place_it_00").select()
            GUI.get("cmdCloseTool"):click()
        end,
    }

    TheoTown.registerToolAction{
        icon = Icon.REMOVE,
        name = TheoTown.translate("rpi_editTool_remove&change"),
        onClick = function ()
            openEditor()
        end,
    }

    StartCapture, EndCapture = TheoTown.addUndoButton()
end

function script:lateInit()
    FramesPlaceAndStorage.installWorldLayer()
end

function script:click(x, y)
    if editorDialog == nil and editorTarget ~= nil then
        closeEditor(true)
    end

    local target = FramesPlaceAndStorage.getTargetInfo(
        x,
        y,
        0,
        false
    )

    if target == nil or #FramesPlaceAndStorage.getTargetItems(
        target.anchorX,
        target.anchorY,
        target.level
    ) == 0 then
        Debug.toast(TheoTown.translate("rpi_toast_no_target"))
        return false
    end

    currentTarget = target
    openEditor()
    return false
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

        local draft = assert(Draft.getDraft(
            "$refined_place_it_00_editTool"
        ))
        Draft.setFrame(draft, 1, Icon.CENTER)

        displayEditToolAction()
        InfoPanel.createInfoPanel()
        InfoPanel.setCurrentDraft("-")
        InfoPanel.setCurrentLayer(1)
    end

    if event == Script.EVENT_TOOL_LEAVE then
        DotPreview.deactivate(TOOL_ID)
        closeEditor(true)
        CtrlPanel.destroyCtrlAction()
        InfoPanel.destroyInfoPanel()
        currentTarget = nil
    end
end
