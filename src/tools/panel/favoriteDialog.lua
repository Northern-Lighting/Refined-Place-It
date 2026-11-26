local M = {}

local FAVORITES_KEY = "$refined_place_it_favorites"
local MAX_FAVORITES = 50
local PAGE_SIZE = 10

local function getFavorites()
    local storage = Util.optStorage(TheoTown.getStorage(), FAVORITES_KEY)

    storage.ids = Array(storage.ids or {})

    return storage.ids
end

function M.addFavorite(draftId)
    if draftId == nil or Draft.getDraft(draftId) == nil then
        return false
    end

    local favorites = getFavorites()

    for i = 1, #favorites do
        if favorites[i] == draftId then
            return false
        end
    end

    favorites:add(draftId, 1)

    while #favorites > MAX_FAVORITES do
        favorites:removeAt(MAX_FAVORITES + 1)
    end

    return true
end

function M.removeFavorite(draftId)
    local favorites = getFavorites()

    for i = #favorites, 1, -1 do
        if favorites[i] == draftId then
            favorites:removeAt(i)
            return true
        end
    end

    return false
end

function M.getDraftAndFrame(draftId)
    if draftId == nil then
        return nil
    end

    local draft = Draft.getDraft(draftId)

    if draft == nil then
        return nil
    end

    return draft, draft:getFrame(1)
end

function M.updateDraftPreview(preview, draftId)
    local _, frame = M.getDraftAndFrame(draftId)

    preview:setIcon(frame or Icon.REGION_SHOW)

    return frame
end

function M.applyDraftSelection(textField, preview, draftId)
    local draft, frame = M.getDraftAndFrame(draftId)

    if draft == nil then
        textField:setText("")
        preview:setIcon(Icon.REGION_SHOW)
        return nil
    end

    textField:setText(draft:getId())
    preview:setIcon(frame or Icon.REGION_SHOW)

    return draft, frame
end

function M.createFavoriteDialog(options)
    local favoritesPage = 1
    local favoritesPageItems = Array()
    local selectedFavoriteDraftId
    local refreshFavoritesPage
    local changeFavoritesPage
    local closeAndReturn
    local outputTextField = options and options.outputTextField
    local outputPreview = options and options.outputPreview
    local onDraftSelected = options and options.onDraftSelected

    local favorite_dialog = GUI.createDialog{
        h = 280,
        closeable = true,
        pause = true,
        title = TheoTown.translate("rpi_favorite_title"),
        text = TheoTown.translate("rpi_favorite_text"),
        actions = {
            {
                icon = Icon.CANCEL,
                text = Translation.control_cancel,
                onClick = function ()
                    closeAndReturn()
                end,
                autoClose = false
            }
        }
    }

    closeAndReturn = function ()
        favorite_dialog:close()
    end

    local dialogTextField = favorite_dialog.content:addTextField{
        text = "",
        h = 30,
        w = -41,
        x = 10,
        y = 20,
        onUpdate = function (textField)
            selectedFavoriteDraftId = textField:getText()
        end
    }
    dialogTextField:setText("")

    local dialogListBox = favorite_dialog.content:addListBox{
        w = -10,
        h = 120,
        x = 10,
        y = 52,
        listboxSelectable = true,
    }

    local dialogOkButton = favorite_dialog.content:addButton{
        x = -40,
        y = 20,
        h = 30,
        w = 20,
        icon = Icon.OK,
        onClick = function ()
            local draftId = selectedFavoriteDraftId
            local draft, frame = M.getDraftAndFrame(draftId)

            if draft == nil or frame == nil then
                Debug.toast(TheoTown.translate("rpi_draft_invalid"))
                return
            end

            if outputTextField ~= nil and outputPreview ~= nil then
                M.applyDraftSelection(outputTextField, outputPreview, draft:getId())
            end

            if onDraftSelected ~= nil then
                onDraftSelected(draft:getId())
            end

            closeAndReturn()
        end
    }

    local dialogListBoxPre = favorite_dialog.content:addButton{
        h = 30,
        w = 30,
        y = 173,
        x = 10,
        icon = Icon.PREVIOUS,
        onClick = function ()
            changeFavoritesPage(-1)
        end
    }

    local dialogListBoxNext = favorite_dialog.content:addButton{
        h = 30,
        w = 30,
        y = 173,
        x = -40,
        icon = Icon.NEXT,
        onClick = function ()
            changeFavoritesPage(1)
        end
    }

    refreshFavoritesPage = function ()
        for i = #favoritesPageItems, 1, -1 do
            favoritesPageItems[i]:delete()
        end

        favoritesPageItems:clear()

        local favorites = getFavorites()
        local totalPages = math.max(1, math.ceil(#favorites / PAGE_SIZE))

        if #favorites == 0 then
            selectedFavoriteDraftId = nil
            dialogTextField:setText("")
        elseif selectedFavoriteDraftId == nil then
            selectedFavoriteDraftId = favorites[1]
            dialogTextField:setText(favorites[1])
        end

        favoritesPage = math.max(1, math.min(favoritesPage, totalPages))
        dialogListBoxPre:setEnabled(favoritesPage > 1)
        dialogListBoxNext:setEnabled(favoritesPage < totalPages)
        dialogListBox:setShiftY(0)

        if #favorites == 0 then
            local emptyLabel = dialogListBox:addLabel{
                text = TheoTown.translate("rpi_favorite_empty"),
                h = 30,
                w = -10
            }

            emptyLabel:setAlignment(0.5, 0.5)
            favoritesPageItems:add(emptyLabel)
            return
        end

        local firstIndex = (favoritesPage - 1) * PAGE_SIZE + 1
        local lastIndex = math.min(firstIndex + PAGE_SIZE - 1, #favorites)

        for i = firstIndex, lastIndex do
            local favoriteDraftId = favorites[i]
            local favoriteDraft = Draft.getDraft(favoriteDraftId)
            local item = dialogListBox:addCanvas{
                h = 30,
                listboxSelectable = true,
                onClick = function ()
                    selectedFavoriteDraftId = favoriteDraftId
                    dialogTextField:setText(favoriteDraftId)
                end
            }
            favoritesPageItems:add(item)

            local previewIcon = Icon.REGION_SHOW

            if favoriteDraft ~= nil then
                previewIcon = Draft.getFrame(favoriteDraft, 1)
            end

            local icon = item:addIcon{
                w = 30,
                x = 5,
                icon = previewIcon
            }
            icon:setAlignment(0, 0.5)

            local label = item:addLabel{
                x = 35,
                w = -70,
                text = favoriteDraftId
            }
            label:setAlignment(0, 0.5)

            item:addButton{
                x = -35,
                width = 30,
                icon = Icon.MINUS,
                onClick = function ()
                    M.removeFavorite(favoriteDraftId)

                    if selectedFavoriteDraftId == favoriteDraftId then
                        selectedFavoriteDraftId = nil
                        dialogTextField:setText("")
                    end

                    refreshFavoritesPage()
                end
            }
        end
    end

    changeFavoritesPage = function (offset)
        favoritesPage = favoritesPage + offset
        refreshFavoritesPage()
    end

    refreshFavoritesPage()

end

FavoriteDialog = M
return M
