local M = {}

local afterClick
local getDropperHistory
local pendingDraftId
local DEFAULT_DROPPER_TOOL_ID = "$refined_place_it_00_dropperTool"
local TOOL_ID = "$refined_place_it_00_dropperTool"

local function displayPlaceToolAction()
    TheoTown.registerToolAction{
        icon = Icon.SETTINGS,
        name = TheoTown.translate("rpi_mainMenu_title"),
        onClick = function ()
            City.createDraftDrawer("$refined_place_it_00").select()
            GUI.get("cmdCloseTool"):click()
        end
    }

    TheoTown.registerToolAction{
        icon = Icon.CLOCK,
        name = TheoTown.translate("rpi_dropperTool_history"), --zh: 选择历史
        onClick = function ()
            pendingDraftId = pendingDraftId or getDropperHistory()[1]
            afterClick()
        end
    }
end

local MAX_DROPPER_HISTORY = 10
local DROPPER_HISTORY_KEY = "$refined_place_it_dropper_history"

getDropperHistory = function()
    local storage = Util.optStorage(City.getStorage(), DROPPER_HISTORY_KEY)

    storage.ids = storage.ids or {}
    
    return storage.ids
end

local function rememberDraft(draftId)
    local history = getDropperHistory()

    for i = #history, 1, -1 do
        if history[i] == draftId then
            table.remove(history, i)
        end
    end

    table.insert(history, 1, draftId)

    while #history > MAX_DROPPER_HISTORY do
        table.remove(history)
    end
end

local function getTopRoadDraft(x, y)
    local topRoadDraft

    for level = 0, 3 do
        local roadDraft = Tile.getRoadDraft(x, y, level)
        if roadDraft ~= nil then
            topRoadDraft = roadDraft
        end
    end

    return topRoadDraft
end

afterClick = function(returnToPlaceTool, parent)
    local actions
    local dropperToolGUI
    local selectionMode = returnToPlaceTool and
        parent ~= nil and
        parent.textField ~= nil and
        parent.preview ~= nil
    local returnToolId = parent and parent.returnToolId or
        DEFAULT_DROPPER_TOOL_ID

    if returnToPlaceTool then
        actions = {
            {
                icon = Icon.BACKWARD,
                text = TheoTown.translate("rpi_toolAction_return"),
                onClick = function ()
                    dropperToolGUI:close()
                    City.createDraftDrawer(returnToolId, true).select()
                end
            }
        }
    else
        actions = {
            {
                icon = Icon.BACKWARD,
                text = TheoTown.translate("rpi_mainMenu_title"),
                onClick = function ()
                    City.createDraftDrawer("$refined_place_it_00").select()
                end
            },
            {
                icon = Icon.OK,
                text = TheoTown.translate("rpi_dropperTool_continuePicker"),
                golden = true,
                autoClose = true
            }
        }
    end

    dropperToolGUI = GUI.createDialog{
        icon = Icon.EYE_DROPPER,
        closeable = true,
        pause = true,
        title = TheoTown.translate("rpi_dropperTool"),
        text = TheoTown.translate("rpi_dropperTool_currentItem"),
        actions = actions,
        h = 280
    }

    local dropperToolGUI_textField = dropperToolGUI.content:addTextField{
        text = "",
        h = 30,
        w = -41,
        x = 10,
        y = 20,
    }

    local dropperToolGUI_listBox = dropperToolGUI.content:addListBox{
        w = -10,
        h = -10,
        x = 10,
        y = 52,
        listboxSelectable = true,
    }
    dropperToolGUI_textField:setText(pendingDraftId or "")

    for _, historyDraftId in ipairs(getDropperHistory()) do
        local historyDraft = Draft.getDraft(historyDraftId)

        if historyDraft ~= nil then
            local item = dropperToolGUI_listBox:addCanvas{
                h = 30,
                listboxSelectable = true,
                onClick = function()
                    dropperToolGUI_textField:setText(historyDraftId)
                end
            }

            local icon = item:addIcon{
                w = 30,
                x = 5,
                icon = Draft.getFrame(historyDraft, 1)
            }
            icon:setAlignment(0, 0.5)

            local label = item:addLabel{
                x = 35,
                w = -70,
                text = historyDraftId
            }
            label:setAlignment(0, 0.5)

            item:addButton{
                x = -35,
                width = 30,
                icon = Icon.STAR,
                onClick = function ()
                    if FavoriteDialog.addFavorite(historyDraftId) then
                        Debug.toast("已添加到收藏")
                    end
                end
            }
        end
    end

    local dropperToolGUI_copy2Clipboard = dropperToolGUI.content:addButton{
        icon = selectionMode and Icon.OK or Icon.COPY,
        x = -40,
        y = 20,
        h = 30,
        w = 20,
        onClick = function()
            if selectionMode then
                local draft = Draft.getDraft(dropperToolGUI_textField:getText())

                if draft == nil then
                    Debug.toast(TheoTown.translate("rpi_draft_invalid"))
                    return
                end

                FavoriteDialog.applyDraftSelection(
                    parent.textField,
                    parent.preview,
                    draft:getId()
                )

                dropperToolGUI:close()

                if parent.onDraftSelected ~= nil then
                    parent.onDraftSelected(draft:getId())
                end

                return
            end

            Runtime.setClipboard(dropperToolGUI_textField:getText())
            Debug.toast(TheoTown.translate("rpi_copy_2_clipboard"))
        end
    }
end

function script:click(x, y)
    local draft = Tile.getBuildingDraft(x, y)
        or getTopRoadDraft(x, y)

    if draft == nil then
        return
    end

    pendingDraftId = draft:getId()
    rememberDraft(pendingDraftId)

    afterClick()
end

function script:draw(tileX, tileY, hoverX, hoverY)
    DotPreview.track(TOOL_ID, tileX, tileY, hoverX, hoverY)
end

function script:drawCity()
    DotPreview.drawCity(TOOL_ID)
end

-- History Storage
function script:leaveCity()
    City.getStorage()[DROPPER_HISTORY_KEY] = nil
    pendingDraftId = nil
end

function script:event(x, y, level, event, source)
    if event == Script.EVENT_TOOL_ENTER then
        DotPreview.activate(TOOL_ID)

        -- Tool Icon Get
        local draft = assert(Draft.getDraft("$refined_place_it_00_dropperTool"))
        Draft.setFrame(draft, 1, Icon.EYE_DROPPER)

        displayPlaceToolAction()
    end

    if event == Script.EVENT_TOOL_LEAVE then
        DotPreview.deactivate(TOOL_ID)
    end
end

function M.back2DropperRecordDialog(parent)
    pendingDraftId = pendingDraftId or getDropperHistory()[1]
    afterClick(true, parent)
end

function M.getLatestDraftId()
    return pendingDraftId or getDropperHistory()[1]
end

DropperToolLink = M
return M
