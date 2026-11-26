local M = {}

local STORAGE_KEY = "$refined_place_it_frames_v1"
local ATTACHMENT_KEY = "$refined_place_it_building_attachment"
local CACHE_KEY = "$refined_place_it_frames_cache"
local WORLD_LAYER_TAG = "refined_place_it_frames_layer"
local WORLD_LAYER_NAME = "refined_place_it_frames_world_layer"

local COORD_BASE = 65536
local SCALE_FACTOR = 10000
local MAX_BUILDING_ITEMS = 32
local MIN_LAYER = 1
local MAX_LAYER = 8

local parentScript = script:getParent()
local isWorldLayer = parentScript ~= nil
local ownerDraft = script:getDraft()
local ownerKind

if ownerDraft ~= nil then
    local okBuilding, isBuilding = pcall(ownerDraft.isBuilding, ownerDraft)
    local okRoad, isRoad = pcall(ownerDraft.isRoad, ownerDraft)

    if okBuilding and isBuilding then
        ownerKind = "building"
    elseif okRoad and isRoad then
        ownerKind = "road"
    end
end

local cacheOwner = parentScript or script
local sharedCache = cacheOwner[CACHE_KEY]

if sharedCache == nil then
    sharedCache = {}
    cacheOwner[CACHE_KEY] = sharedCache
end

local function getStorage()
    local storage = Util.optStorage(City.getStorage(), STORAGE_KEY)

    storage.items = storage.items or {}
    storage.nextItemId = math.max(
        1,
        math.floor(tonumber(storage.nextItemId) or 1)
    )
    storage.nextAttachmentId = math.max(
        1,
        math.floor(tonumber(storage.nextAttachmentId) or 1)
    )
    storage.revision = math.max(
        0,
        math.floor(tonumber(storage.revision) or 0)
    )

    return storage
end

local function markChanged(storage)
    storage.revision = storage.revision + 1
    sharedCache.cache = nil
end

local function resolveLiveFrame(draftId, frameIndex)
    local draft = Draft.getDraft(draftId)

    if draft == nil then
        return nil
    end

    frameIndex = math.max(1, math.floor(tonumber(frameIndex) or 1))

    local okCount, count = pcall(function ()
        return draft:getFrameCount()
    end)

    if okCount and count ~= nil and count > 0 then
        if frameIndex > count then
            return nil
        end

        local okFrame, frame = pcall(function ()
            return draft:getFrame(frameIndex)
        end)

        if okFrame and frame ~= nil and frame > 0 then
            return frame
        end

        return nil
    end

    local okPreviewCount, previewCount = pcall(function ()
        return draft:getPreviewFrameCount()
    end)

    if not okPreviewCount or
       previewCount == nil or
       frameIndex > previewCount then
        return nil
    end

    local okPreview, frame = pcall(function ()
        return draft:getPreviewFrame(frameIndex)
    end)

    if okPreview and frame ~= nil and frame > 0 then
        return frame
    end

    return nil
end

local function getBuildingAttachment(x, y, create)
    local buildingStorage = Tile.getBuildingStorage(x, y)

    if buildingStorage == nil then
        return 0
    end

    local attachmentId = math.max(
        0,
        math.floor(tonumber(buildingStorage[ATTACHMENT_KEY]) or 0)
    )

    if attachmentId == 0 and create then
        local storage = getStorage()
        attachmentId = storage.nextAttachmentId
        storage.nextAttachmentId = attachmentId + 1
        buildingStorage[ATTACHMENT_KEY] = attachmentId
        markChanged(storage)
    end

    return attachmentId
end

local function resolveTarget(x, y, level, create)
    if create == nil then
        create = true
    end

    if Tile.isBuilding(x, y) then
        local anchorX, anchorY = Tile.getBuildingXY(x, y)
        local attachmentId = getBuildingAttachment(
            anchorX,
            anchorY,
            create
        )

        if attachmentId > 0 then
            return "building", anchorX, anchorY, attachmentId
        end

        return nil
    end

    if Tile.hasRoad(x, y, level) then
        return "road", x, y, 0
    end

    return nil
end

local function normalizeLayer(value)
    return math.max(
        MIN_LAYER,
        math.min(
            MAX_LAYER,
            math.floor(tonumber(value) or MIN_LAYER)
        )
    )
end

local function countTargetItems(items, targetKind, attachmentId, x, y, level)
    local count = 0

    for _, item in ipairs(items) do
        local matches

        if targetKind == "building" then
            matches = item.targetKind == "building" and
                item.attachmentId == attachmentId
        else
            matches = item.targetKind == "road" and
                item.x == x and
                item.y == y and
                (item.level or 0) == level
        end

        if matches then
            count = count + 1
        end
    end

    return count
end

local function copyOption(options, name, fallback)
    local value = options and options[name]

    if value == nil then
        return fallback
    end

    return value
end

function M.add(draftId, frameIndex, x, y, level, options)
    if draftId == nil or
       resolveLiveFrame(draftId, frameIndex) == nil then
        return nil
    end

    level = math.floor(tonumber(level) or 0)
    local targetKind, anchorX, anchorY, attachmentId =
        resolveTarget(x, y, level, true)

    if targetKind == nil then
        return nil
    end

    local storage = getStorage()

    if targetKind == "building" and
       countTargetItems(
           storage.items,
           targetKind,
           attachmentId,
           anchorX,
           anchorY,
           level
       ) >= MAX_BUILDING_ITEMS then
        return nil, "building_limit"
    end

    local item = {
        id = storage.nextItemId,
        draftId = tostring(draftId),
        frameIndex = math.max(
            1,
            math.floor(tonumber(frameIndex) or 1)
        ),
        x = math.floor(x),
        y = math.floor(y),
        level = level,
        targetKind = targetKind,
        anchorX = anchorX,
        anchorY = anchorY,
        attachmentId = attachmentId,
        offsetX = tonumber(copyOption(options, "offsetX", 0)) or 0,
        offsetY = tonumber(copyOption(options, "offsetY", 0)) or 0,
        scaleX = tonumber(copyOption(options, "scaleX", 1)) or 1,
        scaleY = tonumber(copyOption(options, "scaleY", 1)) or 1,
        alpha = tonumber(copyOption(options, "alpha", 1)) or 1,
        emissive = copyOption(options, "emissive", false) == true,
        tintR = math.floor(tonumber(
            copyOption(options, "tintR", 255)
        ) or 255),
        tintG = math.floor(tonumber(
            copyOption(options, "tintG", 255)
        ) or 255),
        tintB = math.floor(tonumber(
            copyOption(options, "tintB", 255)
        ) or 255),
    }

    item.zOrder = normalizeLayer(copyOption(
        options,
        "layer",
        copyOption(options, "zOrder", MIN_LAYER)
    ))

    storage.nextItemId = item.id + 1
    storage.items[#storage.items + 1] = item
    markChanged(storage)

    return item, #storage.items
end

function M.getTargetInfo(x, y, level, create)
    level = math.floor(tonumber(level) or 0)
    local targetKind, anchorX, anchorY, attachmentId =
        resolveTarget(x, y, level, create == true)

    if targetKind == nil then
        return nil
    end

    return {
        kind = targetKind,
        anchorX = anchorX,
        anchorY = anchorY,
        attachmentId = attachmentId,
        level = level,
    }
end

function M.getTargetItems(x, y, level)
    local target = M.getTargetInfo(x, y, level, false)

    if target == nil then
        return {}
    end

    local result = {}

    for _, item in ipairs(getStorage().items) do
        if target.kind == "building" then
            if item.targetKind == "building" and
               item.attachmentId == target.attachmentId then
                result[#result + 1] = item
            end
        elseif item.targetKind == "road" and
               item.x == target.anchorX and
               item.y == target.anchorY and
               (item.level or 0) == target.level then
            result[#result + 1] = item
        end
    end

    return result
end

function M.getItems()
    return getStorage().items
end

function M.getLast()
    local items = getStorage().items
    return items[#items]
end

function M.remove(itemId)
    if itemId == nil then
        return false
    end

    local storage = getStorage()
    local items = storage.items

    for i = #items, 1, -1 do
        if items[i].id == itemId then
            table.remove(items, i)
            markChanged(storage)
            return true
        end
    end

    return false
end

function M.removeLast()
    local storage = getStorage()
    local items = storage.items

    if #items == 0 then
        return nil
    end

    local item = table.remove(items)
    markChanged(storage)

    return item
end

function M.getItem(itemId)
    for _, item in ipairs(getStorage().items) do
        if item.id == itemId then
            return item
        end
    end

    return nil
end

function M.getFrame(item)
    if item == nil then
        return nil
    end

    return resolveLiveFrame(item.draftId, item.frameIndex)
end

function M.update(itemId, changes)
    local storage = getStorage()
    local item = M.getItem(itemId)

    if item == nil or changes == nil then
        return nil
    end

    if changes.draftId ~= nil or changes.frameIndex ~= nil then
        local draftId = changes.draftId or item.draftId
        local frameIndex = changes.frameIndex or item.frameIndex

        if resolveLiveFrame(draftId, frameIndex) == nil then
            return nil
        end

        item.draftId = tostring(draftId)
        item.frameIndex = math.max(
            1,
            math.floor(tonumber(frameIndex) or 1)
        )
    end

    if changes.offsetX ~= nil then
        item.offsetX = tonumber(changes.offsetX) or item.offsetX or 0
    end
    if changes.offsetY ~= nil then
        item.offsetY = tonumber(changes.offsetY) or item.offsetY or 0
    end
    if changes.scaleX ~= nil then
        item.scaleX = tonumber(changes.scaleX) or item.scaleX or 1
    end
    if changes.scaleY ~= nil then
        item.scaleY = tonumber(changes.scaleY) or item.scaleY or 1
    end
    if changes.alpha ~= nil then
        item.alpha = tonumber(changes.alpha) or item.alpha or 1
    end
    if changes.emissive ~= nil then
        item.emissive = changes.emissive == true
    end
    if changes.tintR ~= nil then
        item.tintR = math.max(
            0,
            math.min(255, math.floor(tonumber(changes.tintR) or 255))
        )
    end
    if changes.tintG ~= nil then
        item.tintG = math.max(
            0,
            math.min(255, math.floor(tonumber(changes.tintG) or 255))
        )
    end
    if changes.tintB ~= nil then
        item.tintB = math.max(
            0,
            math.min(255, math.floor(tonumber(changes.tintB) or 255))
        )
    end
    if changes.layer ~= nil or changes.zOrder ~= nil then
        item.zOrder = normalizeLayer(
            changes.layer or changes.zOrder
        )
    end

    markChanged(storage)
    return item
end

function M.move(itemId, offsetX, offsetY)
    local item = M.getItem(itemId)

    if item == nil then
        return nil
    end

    return M.update(itemId, {
        offsetX = (item.offsetX or 0) + (tonumber(offsetX) or 0),
        offsetY = (item.offsetY or 0) + (tonumber(offsetY) or 0),
    })
end

function M.setLayer(itemId, layer)
    return M.update(itemId, {
        layer = normalizeLayer(layer),
    })
end

function M.shiftLayer(itemId, delta)
    local item = M.getItem(itemId)

    if item == nil then
        return nil
    end

    return M.setLayer(
        itemId,
        normalizeLayer((item.zOrder or MIN_LAYER) + (delta or 0))
    )
end

function M.setColor(itemId, r, g, b)
    return M.update(itemId, {
        tintR = r,
        tintG = g,
        tintB = b,
    })
end

function M.reset(itemId)
    return M.update(itemId, {
        offsetX = 0,
        offsetY = 0,
        scaleX = 1,
        scaleY = 1,
        alpha = 1,
        emissive = false,
        tintR = 255,
        tintG = 255,
        tintB = 255,
        layer = MIN_LAYER,
    })
end

function M.cloneItem(item)
    if item == nil then
        return nil
    end

    return {
        id = item.id,
        draftId = item.draftId,
        frameIndex = item.frameIndex,
        x = item.x,
        y = item.y,
        level = item.level or 0,
        targetKind = item.targetKind,
        anchorX = item.anchorX,
        anchorY = item.anchorY,
        attachmentId = item.attachmentId or 0,
        offsetX = item.offsetX or 0,
        offsetY = item.offsetY or 0,
        scaleX = item.scaleX or 1,
        scaleY = item.scaleY or 1,
        alpha = item.alpha or 1,
        zOrder = normalizeLayer(item.zOrder),
        emissive = item.emissive == true,
        tintR = item.tintR or 255,
        tintG = item.tintG or 255,
        tintB = item.tintB or 255,
    }
end

function M.snapshotTarget(x, y, level)
    local items = M.getTargetItems(x, y, level)
    local snapshot = {}

    for i = 1, #items do
        snapshot[i] = M.cloneItem(items[i])
    end

    return snapshot
end

function M.removeTargetItems(x, y, level)
    local ids = {}

    for _, item in ipairs(M.getTargetItems(x, y, level)) do
        ids[item.id] = true
    end

    local storage = getStorage()
    local removed = 0

    for i = #storage.items, 1, -1 do
        if ids[storage.items[i].id] then
            table.remove(storage.items, i)
            removed = removed + 1
        end
    end

    if removed > 0 then
        markChanged(storage)
    end

    return removed
end

function M.restoreTarget(x, y, level, snapshot)
    M.removeTargetItems(x, y, level)

    local storage = getStorage()

    for _, item in ipairs(snapshot or {}) do
        local restored = M.cloneItem(item)
        storage.items[#storage.items + 1] = restored
        storage.nextItemId = math.max(
            storage.nextItemId,
            (tonumber(restored.id) or 0) + 1
        )
    end

    markChanged(storage)
end

M.MAX_BUILDING_ITEMS = MAX_BUILDING_ITEMS
M.MIN_LAYER = MIN_LAYER
M.MAX_LAYER = MAX_LAYER

function M.removeTargetAt(x, y, level, kind)
    local storage = getStorage()
    local items = storage.items
    local removed = 0

    if kind == nil then
        kind = Tile.isBuilding(x, y) and "building" or "road"
    end

    if kind == "building" then
        local anchorX, anchorY = Tile.getBuildingXY(x, y)
        local attachmentId = getBuildingAttachment(
            anchorX,
            anchorY,
            false
        )

        for i = #items, 1, -1 do
            local item = items[i]
            local sameBuilding = item.targetKind == "building" and (
                (attachmentId > 0 and
                    item.attachmentId == attachmentId) or
                (item.anchorX == anchorX and
                    item.anchorY == anchorY)
            )

            if sameBuilding then
                table.remove(items, i)
                removed = removed + 1
            end
        end
    else
        level = math.floor(tonumber(level) or 0)

        for i = #items, 1, -1 do
            local item = items[i]
            if item.targetKind == "road" and
               item.x == x and
               item.y == y and
               item.level == level then
                table.remove(items, i)
                removed = removed + 1
            end
        end
    end

    if removed > 0 then
        markChanged(storage)
    end

    return removed
end

local function tileKey(x, y, level)
    return (math.floor(x) * COORD_BASE + math.floor(y)) *
        8 + math.floor(level or 0) + 4
end

local function copyDrawItem(item)
    return {
        draftId = item.draftId,
        frameIndex = item.frameIndex,
        x = item.x,
        y = item.y,
        level = item.level or 0,
        targetKind = item.targetKind,
        anchorX = item.anchorX,
        anchorY = item.anchorY,
        attachmentId = item.attachmentId or 0,
        offsetX = item.offsetX or 0,
        offsetY = item.offsetY or 0,
        scaleX = item.scaleX or 1,
        scaleY = item.scaleY or 1,
        alpha = item.alpha or 1,
        zOrder = normalizeLayer(item.zOrder),
        emissive = item.emissive == true,
        tintR = item.tintR or 255,
        tintG = item.tintG or 255,
        tintB = item.tintB or 255,
    }
end

local function addToBucket(cache, item)
    local bucket

    if item.targetKind == "building" then
        bucket = cache.buildings[item.attachmentId]
        if bucket == nil then
            bucket = {}
            cache.buildings[item.attachmentId] = bucket
        end
    else
        local key = tileKey(item.x, item.y, item.level)
        bucket = cache.roads[key]
        if bucket == nil then
            bucket = {}
            cache.roads[key] = bucket
        end
    end

    bucket[#bucket + 1] = item
end

local function getCityId()
    local ok, cityId = pcall(City.getId)
    return ok and tostring(cityId) or ""
end

local function rebuildCache(storage)
    local cache = {
        cityId = getCityId(),
        revision = storage.revision,
        buildings = {},
        roads = {},
    }

    for _, storedItem in ipairs(storage.items) do
        local item = copyDrawItem(storedItem)
        if item ~= nil then
            addToBucket(cache, item)
        end
    end

    for _, bucket in pairs(cache.buildings) do
        table.sort(bucket, function (a, b)
            return (a.zOrder or 0) < (b.zOrder or 0)
        end)
    end
    for _, bucket in pairs(cache.roads) do
        table.sort(bucket, function (a, b)
            return (a.zOrder or 0) < (b.zOrder or 0)
        end)
    end

    sharedCache.cache = cache
    return cache
end

local function ensureCache(storage)
    local cache = sharedCache.cache

    if cache == nil or
       cache.cityId ~= getCityId() or
       cache.revision ~= storage.revision then
        cache = rebuildCache(storage)
    end

    return cache
end

local function getDaytimeMultiplier()
    local shadeR, shadeG, shadeB = Drawing.getDaytimeColor()
    local nightMix = math.max(
        0,
        math.min(1, (255 - shadeB) / 99)
    )

    return
        math.max(0, math.min(255, math.floor(
            shadeR * (1 + 0.064 * nightMix) + 0.5
        ))),
        math.max(0, math.min(255, math.floor(
            shadeG * (1 + 0.038 * nightMix) + 0.5
        ))),
        math.max(0, math.min(255, math.floor(
            shadeB * (1 - 0.077 * nightMix) + 0.5
        )))
end

local function drawBucket(bucket, anchorX, anchorY)
    if bucket == nil or #bucket == 0 then
        return
    end

    local restoreScaleX, restoreScaleY = Drawing.getScale()
    local drawR, drawG, drawB = getDaytimeMultiplier()
    local rotation = math.floor(tonumber(City.getRotation()) or 0) % 4
    local drawn = 0

    for _, item in ipairs(bucket) do
        local frame = resolveLiveFrame(item.draftId, item.frameIndex)
        if frame ~= nil then
            local deltaX = item.x - anchorX
            local deltaY = item.y - anchorY

            if rotation == 1 then
                deltaX, deltaY = deltaY, -deltaX
            elseif rotation == 2 then
                deltaX, deltaY = -deltaX, -deltaY
            elseif rotation == 3 then
                deltaX, deltaY = -deltaY, deltaX
            end

            local scaleX = item.scaleX
            local scaleY = item.scaleY

            if scaleX == 0 then
                scaleX = 1
            end
            if scaleY == 0 then
                scaleY = 1
            end

            Drawing.setTile(
                anchorX,
                anchorY,
                ((deltaX + deltaY) * 16) / scaleX + item.offsetX,
                ((deltaX - deltaY) * 8) / scaleY + item.offsetY,
                scaleX,
                scaleY
            )

            if item.emissive then
                Drawing.setColor(item.tintR, item.tintG, item.tintB)
            else
                Drawing.setColor(
                    math.floor(drawR * item.tintR / 255 + 0.5),
                    math.floor(drawG * item.tintG / 255 + 0.5),
                    math.floor(drawB * item.tintB / 255 + 0.5)
                )
            end

            Drawing.setAlpha(item.alpha)
            Drawing.drawImage(frame, 0, 0)
            drawn = drawn + 1
        end
    end

    Drawing.setScale(restoreScaleX, restoreScaleY)
    Drawing.setColor(255, 255, 255)
    Drawing.setAlpha(1)
    Drawing.setAdditive(0)

    return drawn
end

local function drawOwner(x, y, level)
    if ownerKind == nil then
        return
    end

    local storage = getStorage()
    local cache = ensureCache(storage)

    if ownerKind == "building" then
        if not Tile.isBuilding(x, y) then
            return
        end

        local anchorX, anchorY = Tile.getBuildingXY(x, y)
        if anchorX ~= x or anchorY ~= y then
            return
        end

        local attachmentId = getBuildingAttachment(
            anchorX,
            anchorY,
            false
        )
        if attachmentId == 0 then
            return
        end

        drawBucket(
            cache.buildings[attachmentId],
            anchorX,
            anchorY
        )
        return
    end

    if ownerKind == "road" then
        level = math.floor(tonumber(level) or 0)
        if Tile.isBuilding(x, y) or not Tile.hasRoad(x, y, level) then
            return
        end

        drawBucket(
            cache.roads[tileKey(x, y, level)],
            x,
            y
        )
    end
end

local function draftHasWorldLayer(draft)
    local okScripts, scripts = pcall(function ()
        return draft:getScripts()
    end)

    if not okScripts or scripts == nil then
        return false
    end

    for i = 1, #scripts do
        local okName, name = pcall(function ()
            return scripts[i]:getName()
        end)

        if okName and name == WORLD_LAYER_NAME then
            return true
        end
    end

    return false
end

function M.installWorldLayer()
    local sources = Script.getScripts(WORLD_LAYER_TAG)
    if sources == nil or #sources == 0 then
        return false
    end

    local source = sources[1]
    source.onFramesTargetRemoved = function (x, y, level, kind)
        M.removeTargetAt(x, y, level, kind)
    end
    local drafts = Draft.getDrafts()
    local installed = false

    for i = 1, #drafts do
        local draft = drafts[i]
        if draft ~= nil then
            local okBuilding, isBuilding = pcall(
                draft.isBuilding,
                draft
            )
            local okRoad, isRoad = pcall(draft.isRoad, draft)

            if (okBuilding and isBuilding) or (okRoad and isRoad) then
                if not draftHasWorldLayer(draft) then
                    local okAdd = pcall(function ()
                        source:addScript(WORLD_LAYER_NAME, draft)
                    end)
                    installed = okAdd or installed
                end
            end
        end
    end

    return installed
end

local function injectWorldLayer()
    local drafts = Draft.getDrafts()

    for i = 1, #drafts do
        local draft = drafts[i]
        if draft ~= nil then
            local okBuilding, isBuilding = pcall(
                draft.isBuilding,
                draft
            )
            local okRoad, isRoad = pcall(draft.isRoad, draft)

            if (okBuilding and isBuilding) or (okRoad and isRoad) then
                if not draftHasWorldLayer(draft) then
                    pcall(function ()
                        script:addScript(WORLD_LAYER_NAME, draft)
                    end)
                end
            end
        end
    end
end

function script:draw(x, y, level)
    drawOwner(x, y, level)
end

function script:event(x, y, level, event)
    if not isWorldLayer then
        return
    end

    local removeEvent = Script.EVENT_REMOVE or 6
    if event ~= removeEvent and event ~= 6 then
        return
    end

    local handler = parentScript.onFramesTargetRemoved
    if type(handler) == "function" then
        pcall(handler, x, y, level, ownerKind)
    end
end

function script:lateInit()
    if isWorldLayer then
        return
    end

    script.onFramesTargetRemoved = function (x, y, level, kind)
        M.removeTargetAt(x, y, level, kind)
    end
    M.installWorldLayer()
end

function script:leaveCity()
    if not isWorldLayer then
        sharedCache.cache = nil
    end
end

if not isWorldLayer then
    FramesPlaceAndStorage = M
end

return M
